#include "lightgun_hid.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cwchar>
#include <fstream>
#include <regex>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#if defined(__MINGW32__)
extern "C" {
#include <hidsdi.h>
}
#else
#include <hidsdi.h>
#endif
#include "raw_input.h"
#endif

namespace input {

namespace {
std::string Trim(std::string s) {
    const auto b = s.find_first_not_of(" \t\r\n");
    if (b == std::string::npos) return {};
    const auto e = s.find_last_not_of(" \t\r\n");
    return s.substr(b, e - b + 1);
}
std::string Upper(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return s;
}
// "16C0:0F01" / "0x16c0:0x0f01" -> "VID_16C0&PID_0F01"; anything else is used as given.
std::string NormaliseDevice(std::string v) {
    v = Upper(Trim(v));
    static const std::regex pair(R"(^(?:0X)?([0-9A-F]{4})\s*[:,/]\s*(?:0X)?([0-9A-F]{4})$)");
    std::smatch m;
    if (std::regex_match(v, m, pair)) return "VID_" + m[1].str() + "&PID_" + m[2].str();
    return v;
}
}  // namespace

bool LightgunHidConfig::Load(const std::string& file) {
    std::ifstream f(file);
    if (!f) return false;
    LightgunHidConfig c;
    std::string section;
    for (std::string line; std::getline(f, line);) {
        line = Trim(line);
        if (line.empty() || line[0] == ';' || line[0] == '#') continue;
        if (line.front() == '[') {
            section = Upper(Trim(line.substr(1, line.find(']') == std::string::npos ? std::string::npos : line.find(']') - 1)));
            continue;
        }
        const auto eq = line.find('=');
        if (eq == std::string::npos) continue;
        const std::string key = Upper(Trim(line.substr(0, eq)));
        std::string value = line.substr(eq + 1);
        if (const auto sc = value.find(';'); sc != std::string::npos) value = value.substr(0, sc);  // trailing comment
        value = Trim(value);
        int p = section == "PLAYER1" || section == "P1" ? 0 : section == "PLAYER2" || section == "P2" ? 1 : -1;
        if (p >= 0 && key == "DEVICE") c.device[p] = NormaliseDevice(value);
        if (p >= 0 && key == "INDEX") c.index[p] = std::max(1, std::atoi(value.c_str()));
        if (section == "OPTIONS" && key == "MOUSEFALLBACK") c.mouseFallback = std::atoi(value.c_str()) != 0;
        // [Lightguns] layout: P1_Lightgun_HID = VID_1209&PID_0001 (optional P1_Lightgun_Index, MouseFallback).
        if (section == "LIGHTGUNS") {
            for (int q = 0; q < 2; ++q) {
                const std::string pre = q == 0 ? "P1_" : "P2_";
                if (key == pre + "LIGHTGUN_HID") c.device[q] = NormaliseDevice(value);
                if (key == pre + "LIGHTGUN_INDEX") c.index[q] = std::max(1, std::atoi(value.c_str()));
            }
            if (key == "MOUSEFALLBACK") c.mouseFallback = std::atoi(value.c_str()) != 0;
        }
    }
    *this = c;
    return true;
}

std::vector<HidMouseDevice> ListHidMice(bool withNames) {
    std::vector<HidMouseDevice> out;
#ifdef _WIN32
    UINT count = 0;
    if (GetRawInputDeviceList(nullptr, &count, sizeof(RAWINPUTDEVICELIST)) != 0 || count == 0) return out;
    std::vector<RAWINPUTDEVICELIST> list(count);
    const UINT got = GetRawInputDeviceList(list.data(), &count, sizeof(RAWINPUTDEVICELIST));
    if (got == UINT(-1)) return out;
    list.resize(got);
    for (const auto& d : list) {
        if (d.dwType != RIM_TYPEMOUSE) continue;
        UINT chars = 0;
        if (GetRawInputDeviceInfoW(d.hDevice, RIDI_DEVICENAME, nullptr, &chars) == UINT(-1) || chars == 0) continue;
        std::wstring name(chars + 1, L'\0');
        if (GetRawInputDeviceInfoW(d.hDevice, RIDI_DEVICENAME, name.data(), &chars) == UINT(-1)) continue;
        name.resize(wcslen(name.c_str()));
        HidMouseDevice m;
        m.key = RawDeviceKey(d.hDevice);
        if (m.key.empty()) continue;
        for (wchar_t ch : name) m.id += ch < 128 ? static_cast<char>(std::toupper(static_cast<int>(ch))) : '?';
        // Label: VID/PID/MI part of the ID plus the product name the device reports.
        std::smatch mm;
        static const std::regex ids(R"(VID_[0-9A-F]{4}&PID_[0-9A-F]{4}(&MI_[0-9A-F]{2})?)");
        m.label = std::regex_search(m.id, mm, ids) ? mm.str() : std::string("(no VID/PID: ") + m.id.substr(0, 40) + ")";
        HANDLE h = withNames ? CreateFileW(name.c_str(), 0, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr)
                             : INVALID_HANDLE_VALUE;
        if (h != INVALID_HANDLE_VALUE) {
            wchar_t product[127] = {};
            if (HidD_GetProductString(h, product, sizeof(product))) {
                std::string p;
                for (wchar_t ch : product) {
                    if (!ch) break;
                    p += ch < 128 ? static_cast<char>(ch) : '?';
                }
                if (!p.empty()) m.label += "  " + p;
            }
            CloseHandle(h);
        }
        out.push_back(std::move(m));
    }
    // Stable order (by ID) so Index= picks the same gun every launch.
    std::sort(out.begin(), out.end(), [](const HidMouseDevice& a, const HidMouseDevice& b) { return a.id < b.id; });
#endif
    return out;
}

int ApplyLightgunHid(const LightgunHidConfig& config, const std::vector<HidMouseDevice>& mice, LightgunSettings& settings,
                     bool slots[2]) {
    slots[0] = slots[1] = false;
    std::string chosen[2];
    for (int p = 0; p < 2; ++p) {
        if (config.device[p].empty()) continue;
        // Same Device= for both players without Index=: Player 2 takes the second match.
        int want = config.index[p];
        if (p == 1 && config.device[1] == config.device[0] && config.index[1] == config.index[0]) want = config.index[0] + 1;
        int seen = 0;
        for (const auto& m : mice) {
            if (m.id.find(config.device[p]) == std::string::npos) continue;
            if (p == 1 && m.key == chosen[0] && config.device[1] != config.device[0]) continue;  // never share a gun
            if (++seen != want) continue;
            if (p == 1 && m.key == chosen[0]) continue;
            chosen[p] = m.key;
            break;
        }
    }
    int found = 0;
    for (int p = 0; p < 2; ++p) {
        if (config.device[p].empty()) continue;
        // Keep the slot's buttons / calibration; only the device changes. A configured gun that is not connected
        // leaves its slot empty, so no other device (an earlier menu assignment, the desk mouse) can play it.
        settings.player[p].device = chosen[p];
        if (!chosen[p].empty()) {
            slots[p] = true;
            ++found;
        }
    }
    settings.manual = true;  // never let an unconfigured device (the desk mouse) take a player slot
    return found;
}

bool WriteHidDeviceList(const std::string& file, const std::vector<HidMouseDevice>& mice, const LightgunHidConfig& config) {
    std::ofstream f(file, std::ios::trunc);
    if (!f) return false;
    f << "Mouse-type devices connected when HOTD2RE started (light guns appear here).\r\n"
         "Copy the VID_xxxx&PID_xxxx part (add &MI_xx if one gun lists several) into lightgunHID.ini.\r\n\r\n";
    for (const auto& m : mice) {
        std::string tag;
        for (int p = 0; p < 2; ++p)
            if (!config.device[p].empty() && m.id.find(config.device[p]) != std::string::npos)
                tag += p == 0 ? "  <- matches Player1" : "  <- matches Player2";
        f << m.label << tag << "\r\n";
    }
    if (mice.empty()) f << "(none found)\r\n";
    f.flush();
    return bool(f);
}

}  // namespace input
