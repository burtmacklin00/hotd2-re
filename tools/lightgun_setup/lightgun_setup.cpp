// LightgunSetup.exe - picks the Player 1 / Player 2 light guns and writes LightgunHID.ini:
//
//   [Lightguns]
//   P1_Lightgun_HID = VID_1209&PID_0001
//   P2_Lightgun_HID = VID_1209&PID_0002
//
// Pull the trigger on each gun when asked (Raw Input tells the guns apart), or pick from the device list. A desk mouse
// clicking inside this window operates the app; clicking elsewhere on screen picks that mouse.
// Writes LightgunHID.ini next to the exe, or the file given with --ini "path". Other lines in an existing file
// (MouseFallback, comments) are kept.
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <commctrl.h>
#include <shellapi.h>
#if defined(__MINGW32__)
extern "C" {
#include <hidsdi.h>
}
#else
#include <hidsdi.h>
#endif

#include <algorithm>
#include <set>
#include <cwctype>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

namespace {

struct Device {
    HANDLE handle = nullptr;
    std::wstring id;     // upper-case Raw Input device name
    std::wstring vidPid; // VID_xxxx&PID_xxxx (empty if the name has none)
    std::wstring name;   // product string
};

struct Pick {
    bool set = false;
    std::wstring vidPid, name, id;
    int index = 1;  // Nth connected device with this VID/PID (sorted by ID), for identical guns
};

enum { kStepP1, kStepP2, kStepDone };

HWND gWnd, gTitle, gText, gList, gP1, gP2, gRedo1, gRedo2, gSkip, gUse, gSave, gCancel, gNoGuns;
HFONT gBig, gNormal;
std::vector<Device> gDevices;
Pick gPick[2];
int gStep = kStepP1;
DWORD gArmAfter = 0;  // ignore trigger pulls until this tick (the click that started a step)
std::wstring gIniPath;
std::set<HANDLE> gAbsolute;  // devices that have reported absolute positions (light guns do; desk mice do not)

std::wstring Upper(std::wstring s) {
    for (auto& c : s) c = static_cast<wchar_t>(towupper(c));
    return s;
}

std::wstring DeviceName(HANDLE h) {
    UINT chars = 0;
    if (GetRawInputDeviceInfoW(h, RIDI_DEVICENAME, nullptr, &chars) == UINT(-1) || !chars) return {};
    std::wstring name(chars + 1, L'\0');
    if (GetRawInputDeviceInfoW(h, RIDI_DEVICENAME, name.data(), &chars) == UINT(-1)) return {};
    name.resize(wcslen(name.c_str()));
    return name;
}

std::wstring ProductName(const std::wstring& path) {
    HANDLE f = CreateFileW(path.c_str(), 0, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    if (f == INVALID_HANDLE_VALUE) return {};
    wchar_t product[127] = {};
    std::wstring out;
    if (HidD_GetProductString(f, product, sizeof(product))) out = product;
    CloseHandle(f);
    return out;
}

void RefreshDevices() {
    gDevices.clear();
    UINT count = 0;
    GetRawInputDeviceList(nullptr, &count, sizeof(RAWINPUTDEVICELIST));
    std::vector<RAWINPUTDEVICELIST> list(count);
    const UINT got = count ? GetRawInputDeviceList(list.data(), &count, sizeof(RAWINPUTDEVICELIST)) : 0;
    if (got == UINT(-1)) return;
    static const std::wregex ids(LR"(VID_[0-9A-F]{4}&PID_[0-9A-F]{4})");
    for (UINT i = 0; i < got; ++i) {
        if (list[i].dwType != RIM_TYPEMOUSE) continue;
        Device d;
        d.handle = list[i].hDevice;
        const std::wstring raw = DeviceName(d.handle);
        if (raw.empty()) continue;
        d.id = Upper(raw);
        std::wsmatch m;
        if (std::regex_search(d.id, m, ids)) d.vidPid = m.str();
        d.name = ProductName(raw);
        if (d.name.empty()) d.name = d.vidPid.empty() ? L"(unnamed pointing device)" : L"(no product name)";
        gDevices.push_back(d);
    }
    // Same order the game uses to number identical guns.
    std::sort(gDevices.begin(), gDevices.end(), [](const Device& a, const Device& b) { return a.id < b.id; });
}

const Device* FindByHandle(HANDLE h) {
    for (const auto& d : gDevices)
        if (d.handle == h) return &d;
    return nullptr;
}

std::wstring Describe(const Pick& p) {
    if (!p.set) return L"not set";
    std::wstring s = p.vidPid + L"   " + p.name;
    if (p.index > 1) s += L"   (#" + std::to_wstring(p.index) + L" of this model)";
    return s;
}

void RefreshList() {
    SendMessageW(gList, LB_RESETCONTENT, 0, 0);
    for (const auto& d : gDevices) {
        std::wstring line = (d.vidPid.empty() ? L"(no VID/PID)" : d.vidPid) + L"    " + d.name;
        for (int p = 0; p < 2; ++p)
            if (gPick[p].set && gPick[p].id == d.id) line += p == 0 ? L"    <- Player 1" : L"    <- Player 2";
        SendMessageW(gList, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(line.c_str()));
    }
}

void UpdateUi() {
    const wchar_t* prompt = gStep == kStepP1   ? L"Pull the trigger on the PLAYER 1 gun"
                            : gStep == kStepP2 ? L"Pull the trigger on the PLAYER 2 gun"
                                               : L"Done - click Save";
    SetWindowTextW(gText, prompt);
    SetWindowTextW(gP1, (L"Player 1:  " + Describe(gPick[0])).c_str());
    SetWindowTextW(gP2, (L"Player 2:  " + Describe(gPick[1])).c_str());
    EnableWindow(gSkip, gStep == kStepP2);
    EnableWindow(gUse, gStep != kStepDone);
    EnableWindow(gRedo1, gPick[0].set);
    EnableWindow(gRedo2, gPick[0].set && gStep != kStepP1);
    EnableWindow(gSave, gPick[0].set && gStep == kStepDone);
    RefreshList();
}

void Choose(const Device& d) {
    if (d.vidPid.empty()) {
        MessageBeep(MB_ICONWARNING);
        SetWindowTextW(gText, L"That device has no VID/PID - try the gun's trigger again");
        return;
    }
    const int p = gStep == kStepP1 ? 0 : 1;
    if (p == 1 && gPick[0].set && gPick[0].id == d.id) return;  // the Player 1 gun again: keep waiting
    Pick pick;
    pick.set = true;
    pick.vidPid = d.vidPid;
    pick.name = d.name;
    pick.id = d.id;
    int n = 0;
    for (const auto& o : gDevices) {
        if (o.vidPid != d.vidPid) continue;
        ++n;
        if (o.id == d.id) break;
    }
    pick.index = std::max(1, n);
    gPick[p] = pick;
    MessageBeep(MB_OK);
    gStep = p == 0 ? kStepP2 : kStepDone;
    gArmAfter = GetTickCount() + 400;
    UpdateUi();
}

// The ini, keeping other lines; [Lightguns] gets the P1 / P2 keys (index lines only for identical guns).
// noGuns: "No light guns" (mouse play): clears both players and writes NoGuns = 1, so Play HOTD2 stops offering
// this setup. Saving picked guns removes NoGuns again.
bool SaveIni(bool noGuns = false) {
    std::vector<std::wstring> lines;
    {
        HANDLE f = CreateFileW(gIniPath.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, 0, nullptr);
        if (f != INVALID_HANDLE_VALUE) {
            std::string data;
            char buf[4096];
            DWORD n = 0;
            while (ReadFile(f, buf, sizeof(buf), &n, nullptr) && n) data.append(buf, n);
            CloseHandle(f);
            std::wstring l;
            for (char c : data) {
                if (c == '\n') {
                    if (!l.empty() && l.back() == L'\r') l.pop_back();
                    lines.push_back(l);
                    l.clear();
                } else {
                    l += static_cast<wchar_t>(static_cast<unsigned char>(c));
                }
            }
            if (!l.empty()) lines.push_back(l);
        }
    }
    auto keyOf = [](const std::wstring& l) {
        const auto eq = l.find(L'=');
        if (eq == std::wstring::npos) return std::wstring();
        std::wstring k = l.substr(0, eq);
        k.erase(0, k.find_first_not_of(L" \t"));
        k.erase(k.find_last_not_of(L" \t") + 1);
        return Upper(k);
    };
    std::vector<std::wstring> out;
    bool inSection = false, haveSection = false;
    std::vector<std::wstring> ours;
    if (noGuns) ours.push_back(L"NoGuns = 1");
    for (int p = 0; p < 2 && !noGuns; ++p) {
        if (!gPick[p].set) continue;
        const std::wstring pre = p == 0 ? L"P1_" : L"P2_";
        ours.push_back(pre + L"Lightgun_HID = " + gPick[p].vidPid);
        const bool shared = gPick[0].set && gPick[1].set && gPick[0].vidPid == gPick[1].vidPid;
        if (gPick[p].index > 1 || shared) ours.push_back(pre + L"Lightgun_Index = " + std::to_wstring(gPick[p].index));
    }
    for (const auto& l : lines) {
        std::wstring t = l;
        t.erase(0, t.find_first_not_of(L" \t"));
        if (!t.empty() && t[0] == L'[') {
            inSection = Upper(t).rfind(L"[LIGHTGUNS]", 0) == 0;
            out.push_back(l);
            if (inSection) {
                haveSection = true;
                out.insert(out.end(), ours.begin(), ours.end());
            }
            continue;
        }
        const std::wstring k = keyOf(l);
        // Old per-player sections and our own keys are replaced.
        if (inSection && (k == L"P1_LIGHTGUN_HID" || k == L"P2_LIGHTGUN_HID" || k == L"P1_LIGHTGUN_INDEX" || k == L"P2_LIGHTGUN_INDEX" ||
                          k == L"NOGUNS"))
            continue;
        out.push_back(l);
    }
    if (!haveSection) {
        std::vector<std::wstring> head{L"[Lightguns]"};
        head.insert(head.end(), ours.begin(), ours.end());
        if (!out.empty()) head.push_back(L"");
        out.insert(out.begin(), head.begin(), head.end());
    }
    // Plain ASCII / CRLF like the hand-written file.
    std::string data;
    for (const auto& l : out) {
        for (wchar_t c : l) data += c < 128 ? static_cast<char>(c) : '?';
        data += "\r\n";
    }
    HANDLE f = CreateFileW(gIniPath.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD written = 0;
    const BOOL ok = WriteFile(f, data.data(), static_cast<DWORD>(data.size()), &written, nullptr);
    CloseHandle(f);
    return ok && written == data.size();
}

HWND Make(const wchar_t* cls, const wchar_t* text, DWORD style, int id, HFONT font) {
    HWND h = CreateWindowExW(0, cls, text, WS_CHILD | WS_VISIBLE | style, 0, 0, 10, 10, gWnd,
                             reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandleW(nullptr), nullptr);
    SendMessageW(h, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
    return h;
}

enum { kIdList = 100, kIdRedo1, kIdRedo2, kIdSkip, kIdUse, kIdSave, kIdCancel, kIdNoGuns };

void Layout(int w, int h) {
    const int m = 16, bh = 32;
    MoveWindow(gTitle, m, m, w - 2 * m - 190, 24, TRUE);
    MoveWindow(gNoGuns, w - m - 180, m - 2, 180, 28, TRUE);
    MoveWindow(gText, m, m + 30, w - 2 * m, 40, TRUE);
    MoveWindow(gP1, m, m + 80, w - 2 * m - 130, 24, TRUE);
    MoveWindow(gRedo1, w - m - 120, m + 76, 120, 28, TRUE);
    MoveWindow(gP2, m, m + 112, w - 2 * m - 130, 24, TRUE);
    MoveWindow(gRedo2, w - m - 120, m + 108, 120, 28, TRUE);
    const int listTop = m + 150, listBottom = h - m - bh - 12;
    MoveWindow(gList, m, listTop, w - 2 * m, std::max(60, listBottom - listTop), TRUE);
    const int by = h - m - bh;
    MoveWindow(gUse, m, by, 170, bh, TRUE);
    MoveWindow(gSkip, m + 180, by, 150, bh, TRUE);
    MoveWindow(gCancel, w - m - 100, by, 100, bh, TRUE);
    MoveWindow(gSave, w - m - 210, by, 100, bh, TRUE);
}

LRESULT CALLBACK WndProc(HWND h, UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
    case WM_INPUT: {
        UINT size = 0;
        GetRawInputData(reinterpret_cast<HRAWINPUT>(lp), RID_INPUT, nullptr, &size, sizeof(RAWINPUTHEADER));
        std::vector<BYTE> buf(size);
        if (size && GetRawInputData(reinterpret_cast<HRAWINPUT>(lp), RID_INPUT, buf.data(), &size, sizeof(RAWINPUTHEADER)) == size) {
            const auto* ri = reinterpret_cast<const RAWINPUT*>(buf.data());
            if (ri->header.dwType == RIM_TYPEMOUSE && ri->header.hDevice && (ri->data.mouse.usFlags & MOUSE_MOVE_ABSOLUTE))
                gAbsolute.insert(ri->header.hDevice);
            if (ri->header.dwType == RIM_TYPEMOUSE && ri->header.hDevice && gStep != kStepDone &&
                (ri->data.mouse.usButtonFlags & RI_MOUSE_LEFT_BUTTON_DOWN) && GetTickCount() >= gArmAfter) {
                const Device* d = FindByHandle(ri->header.hDevice);
                if (!d) {
                    RefreshDevices();
                    d = FindByHandle(ri->header.hDevice);
                }
                // A relative (desk) mouse clicking inside this window is operating the app, not choosing a gun.
                // Light guns report absolute positions, so their trigger counts wherever they aim.
                POINT pt;
                GetCursorPos(&pt);
                HWND under = WindowFromPoint(pt);
                const bool onApp = under && (under == gWnd || GetParent(under) == gWnd);
                const bool uiClick = onApp && !gAbsolute.count(ri->header.hDevice);
                if (d && !uiClick) Choose(*d);
            }
        }
        return DefWindowProcW(h, msg, wp, lp);
    }
    case WM_INPUT_DEVICE_CHANGE:
        RefreshDevices();
        UpdateUi();
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wp)) {
        case kIdRedo1:
            gPick[0] = {};
            gPick[1] = {};
            gStep = kStepP1;
            gArmAfter = GetTickCount() + 400;
            UpdateUi();
            break;
        case kIdRedo2:
            gPick[1] = {};
            gStep = kStepP2;
            gArmAfter = GetTickCount() + 400;
            UpdateUi();
            break;
        case kIdSkip:
            gPick[1] = {};
            gStep = kStepDone;
            UpdateUi();
            break;
        case kIdUse: {
            const LRESULT sel = SendMessageW(gList, LB_GETCURSEL, 0, 0);
            if (sel >= 0 && sel < static_cast<LRESULT>(gDevices.size())) Choose(gDevices[static_cast<size_t>(sel)]);
            else MessageBoxW(h, L"Select a device in the list first.", L"Light Gun Setup", MB_ICONINFORMATION);
            break;
        }
        case kIdSave:
            if (SaveIni()) {
                MessageBoxW(h, (L"Saved " + gIniPath).c_str(), L"Light Gun Setup", MB_ICONINFORMATION);
                DestroyWindow(h);
            } else {
                MessageBoxW(h, (L"Could not write " + gIniPath + L"\nIs the folder writable?").c_str(), L"Light Gun Setup", MB_ICONERROR);
            }
            break;
        case kIdNoGuns:
            if (SaveIni(true)) {
                MessageBoxW(h, L"Saved: no light guns. The game will use the mouse (1 player).\n"
                               L"Run this setup again any time to pick guns.", L"Light Gun Setup", MB_ICONINFORMATION);
                DestroyWindow(h);
            } else {
                MessageBoxW(h, (L"Could not write " + gIniPath + L"\nIs the folder writable?").c_str(), L"Light Gun Setup", MB_ICONERROR);
            }
            break;
        case kIdCancel:
            DestroyWindow(h);
            break;
        }
        return 0;
    case WM_SIZE:
        Layout(LOWORD(lp), HIWORD(lp));
        return 0;
    case WM_GETMINMAXINFO:
        reinterpret_cast<MINMAXINFO*>(lp)->ptMinTrackSize = {560, 420};
        return 0;
    case WM_KEYDOWN:
        if (wp == VK_ESCAPE) DestroyWindow(h);
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(h, msg, wp, lp);
}

std::wstring DefaultIniPath() {
    wchar_t exe[MAX_PATH] = {};
    GetModuleFileNameW(nullptr, exe, MAX_PATH);
    std::wstring dir = exe;
    dir = dir.substr(0, dir.find_last_of(L"\\/") + 1);
    return dir + L"LightgunHID.ini";
}

}  // namespace

int WINAPI wWinMain(HINSTANCE inst, HINSTANCE, PWSTR, int show) {
    SetProcessDPIAware();
    gIniPath = DefaultIniPath();
    int argc = 0;
    if (wchar_t** argv = CommandLineToArgvW(GetCommandLineW(), &argc)) {
        for (int i = 1; i + 1 < argc; ++i)
            if (_wcsicmp(argv[i], L"--ini") == 0) gIniPath = argv[i + 1];
        LocalFree(argv);
    }

    INITCOMMONCONTROLSEX icc{sizeof(icc), ICC_STANDARD_CLASSES};
    InitCommonControlsEx(&icc);
    WNDCLASSW wc{};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = inst;
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
    wc.lpszClassName = L"LightgunSetupWnd";
    wc.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    RegisterClassW(&wc);

    const int dpi = GetDeviceCaps(GetDC(nullptr), LOGPIXELSY);
    gBig = CreateFontW(-MulDiv(16, dpi, 72), 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    gNormal = CreateFontW(-MulDiv(10, dpi, 72), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");

    gWnd = CreateWindowExW(0, wc.lpszClassName, L"Light Gun Setup", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT,
                           MulDiv(760, dpi, 96), MulDiv(520, dpi, 96), nullptr, nullptr, inst, nullptr);
    gTitle = Make(L"STATIC", (L"Writes: " + gIniPath).c_str(), SS_LEFT | SS_NOPREFIX | SS_PATHELLIPSIS, 0, gNormal);
    gText = Make(L"STATIC", L"", SS_LEFT | SS_NOPREFIX, 0, gBig);
    gP1 = Make(L"STATIC", L"", SS_LEFT | SS_NOPREFIX, 0, gNormal);
    gP2 = Make(L"STATIC", L"", SS_LEFT | SS_NOPREFIX, 0, gNormal);
    gRedo1 = Make(L"BUTTON", L"Redo Player 1", BS_PUSHBUTTON, kIdRedo1, gNormal);
    gRedo2 = Make(L"BUTTON", L"Redo Player 2", BS_PUSHBUTTON, kIdRedo2, gNormal);
    gList = Make(L"LISTBOX", L"", WS_BORDER | WS_VSCROLL | LBS_NOTIFY | LBS_NOINTEGRALHEIGHT, kIdList, gNormal);
    gUse = Make(L"BUTTON", L"Use selected device", BS_PUSHBUTTON, kIdUse, gNormal);
    gSkip = Make(L"BUTTON", L"No Player 2 gun", BS_PUSHBUTTON, kIdSkip, gNormal);
    gSave = Make(L"BUTTON", L"Save", BS_DEFPUSHBUTTON, kIdSave, gNormal);
    gCancel = Make(L"BUTTON", L"Cancel", BS_PUSHBUTTON, kIdCancel, gNormal);
    gNoGuns = Make(L"BUTTON", L"No light guns (mouse)", BS_PUSHBUTTON, kIdNoGuns, gNormal);

    RAWINPUTDEVICE rid{0x01, 0x02, RIDEV_INPUTSINK | RIDEV_DEVNOTIFY, gWnd};
    RegisterRawInputDevices(&rid, 1, sizeof(rid));
    RefreshDevices();
    gArmAfter = GetTickCount() + 600;
    UpdateUi();
    RECT rc;
    GetClientRect(gWnd, &rc);
    Layout(rc.right, rc.bottom);
    ShowWindow(gWnd, show);
    UpdateWindow(gWnd);

    MSG m;
    while (GetMessageW(&m, nullptr, 0, 0) > 0) {
        if (!IsDialogMessageW(gWnd, &m)) {
            TranslateMessage(&m);
            DispatchMessageW(&m);
        }
    }
    return 0;
}
