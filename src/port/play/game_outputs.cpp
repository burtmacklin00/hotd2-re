#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
using socket_t = SOCKET;
static void CloseSock(uintptr_t s) { closesocket(static_cast<SOCKET>(s)); }
static bool WouldBlock() { return WSAGetLastError() == WSAEWOULDBLOCK; }
#else
#include <arpa/inet.h>
#include <cerrno>
#include <fcntl.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <sys/socket.h>
#include <unistd.h>
using socket_t = int;
static void CloseSock(uintptr_t s) { close(static_cast<int>(s)); }
static bool WouldBlock() { return errno == EWOULDBLOCK || errno == EAGAIN; }
#endif

#include "game_outputs.h"

#include "game/world.h"

#include <cstdio>

namespace play {

namespace {
constexpr uintptr_t kNoSocket = ~uintptr_t(0);
constexpr const char* kRomName = "hod2re";  // the name tools key their game profile on
constexpr uint64_t kLampBlinkMs = 500;
constexpr int kStatePlaying = 5, kStateContinue = 4, kStateOut = 6;
constexpr int kGameModePlaying = 6;

void SetNonBlocking(uintptr_t s) {
#ifdef _WIN32
    u_long on = 1;
    ioctlsocket(static_cast<SOCKET>(s), FIONBIO, &on);
#else
    fcntl(static_cast<int>(s), F_SETFL, fcntl(static_cast<int>(s), F_GETFL, 0) | O_NONBLOCK);
#endif
}
}  // namespace

GameOutputs::~GameOutputs() { Stop(); }

int GameOutputs::Add(const char* name) {
    outputs_.push_back({name, 0});
    return static_cast<int>(outputs_.size()) - 1;
}

bool GameOutputs::Start(const GameOutputsConfig& config, std::string* error) {
    Stop();
    config_ = config;
#ifdef _WIN32
    WSADATA data;
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) {
        if (error) *error = "WSAStartup failed";
        return false;
    }
    wsa_ = true;
#endif
    socket_t s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
#ifdef _WIN32
    if (s == INVALID_SOCKET) {
#else
    if (s < 0) {
#endif
        if (error) *error = "socket() failed";
        Stop();
        return false;
    }
    // Loopback only: tools run on this PC, and nothing on the network can reach the port.
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_port = htons(static_cast<uint16_t>(config_.port));
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(s, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0 || listen(s, 4) != 0) {
        if (error) *error = "port " + std::to_string(config_.port) + " is in use (is DemulShooter or MAME running?)";
        CloseSock(static_cast<uintptr_t>(s));
        Stop();
        return false;
    }
    listener_ = static_cast<uintptr_t>(s);
    SetNonBlocking(listener_);

    outputs_.clear();
    const char* p[2] = {"P1_", "P2_"};
    for (int i = 0; i < 2; ++i) {
        const std::string pre = p[i];
        lamp_[i] = Add((pre + "CtmLmpStart").c_str());
        ammo_[i] = Add((pre + "Ammo").c_str());
        clip_[i] = Add((pre + "Clip").c_str());
        recoil_[i] = Add((pre + "CtmRecoil").c_str());
        life_[i] = Add((pre + "Life").c_str());
        damaged_[i] = Add((pre + "Damaged").c_str());
        dead_[i] = Add((pre + "Dead").c_str());
        recoilPulse_[i] = Pulse{recoil_[i], 0, false, 0, config_.recoilOnMs, config_.recoilOffMs};
        damagedPulse_[i] = Pulse{damaged_[i], 0, false, 0, config_.damagedMs, 0};
        track_[i] = PlayerTrack{};
    }
    credits_ = Add("Credits");
    return true;
}

void GameOutputs::Stop() {
    for (uintptr_t c : clients_) {
        SendTo(c, Line("mame_stop", 1));
        CloseSock(c);
    }
    clients_.clear();
    if (listener_ != kNoSocket) CloseSock(listener_);
    listener_ = kNoSocket;
#ifdef _WIN32
    if (wsa_) WSACleanup();
#endif
    wsa_ = false;
}

std::string GameOutputs::Line(const std::string& name, int value) { return name + " = " + std::to_string(value) + "\r"; }

bool GameOutputs::SendTo(uintptr_t client, const std::string& line) {
    const char* data = line.data();
    int left = static_cast<int>(line.size());
    int stalls = 0;
    while (left > 0) {
        const int n = static_cast<int>(send(static_cast<socket_t>(client), data, left, 0));
        if (n > 0) {
            data += n;
            left -= n;
            continue;
        }
        // Tiny messages: a full buffer means the tool stopped reading. Drop it rather than stall the game.
        if (n < 0 && WouldBlock() && ++stalls < 64) continue;
        return false;
    }
    return true;
}

void GameOutputs::SendAll(const std::string& line) {
    for (size_t i = 0; i < clients_.size();) {
        if (SendTo(clients_[i], line)) {
            ++i;
        } else {
            CloseSock(clients_[i]);
            clients_.erase(clients_.begin() + static_cast<std::ptrdiff_t>(i));
        }
    }
}

void GameOutputs::Set(int output, int value) {
    if (output < 0) return;
    Output& o = outputs_[static_cast<size_t>(output)];
    if (o.value == value) return;
    o.value = value;
    SendAll(Line(o.name, value));
}

void GameOutputs::AcceptClients() {
    for (;;) {
        const socket_t c = accept(static_cast<socket_t>(listener_), nullptr, nullptr);
#ifdef _WIN32
        if (c == INVALID_SOCKET) break;
#else
        if (c < 0) break;
#endif
        const uintptr_t client = static_cast<uintptr_t>(c);
        SetNonBlocking(client);
        int one = 1;
        setsockopt(c, IPPROTO_TCP, TCP_NODELAY, reinterpret_cast<const char*>(&one), sizeof(one));
        std::string hello = Line("mame_stop", 1) + "mame_start = " + kRomName + "\r";
        for (const Output& o : outputs_) hello += Line(o.name, o.value);
        if (SendTo(client, hello)) clients_.push_back(client);
        else CloseSock(client);
    }
    // Drain anything the tools send (MAMEHooker-style requests are not needed) and notice closed connections.
    for (size_t i = 0; i < clients_.size();) {
        char buf[256];
        const int n = static_cast<int>(recv(static_cast<socket_t>(clients_[i]), buf, sizeof(buf), 0));
        if (n == 0 || (n < 0 && !WouldBlock())) {
            CloseSock(clients_[i]);
            clients_.erase(clients_.begin() + static_cast<std::ptrdiff_t>(i));
        } else {
            ++i;
        }
    }
}

void GameOutputs::Fire(Pulse& pulse, uint64_t nowMs) {
    if (pulse.on || pulse.until > nowMs) {
        if (pulse.queued < 3) ++pulse.queued;  // rapid fire: keep the pulses separate instead of merging them
        return;
    }
    pulse.on = true;
    pulse.until = nowMs + static_cast<uint64_t>(pulse.onMs);
    Set(pulse.output, 1);
}

void GameOutputs::RunPulse(Pulse& pulse, uint64_t nowMs) {
    if (pulse.until > nowMs) return;
    if (pulse.on) {
        pulse.on = false;
        pulse.until = nowMs + static_cast<uint64_t>(pulse.offMs);
        Set(pulse.output, 0);
    } else if (pulse.queued > 0) {
        --pulse.queued;
        pulse.on = true;
        pulse.until = nowMs + static_cast<uint64_t>(pulse.onMs);
        Set(pulse.output, 1);
    }
}

void GameOutputs::OnFrame(const game::WorldHud& hud, int slotForP1, bool live, uint64_t nowMs) {
    if (!Running()) return;
    const bool inGame = hud.gameMode == kGameModePlaying;
    for (int out = 0; out < 2; ++out) {
        const int slot = (slotForP1 == 1) ? 1 - out : out;
        const auto& p = hud.player[slot];
        PlayerTrack& t = track_[out];
        const bool playing = inGame && p.state == kStatePlaying;
        // (The F8 prototype has no continue: a player who runs out of lives goes straight to state 9.)
        const bool dead = inGame && t.wasPlaying &&
                          (p.state == kStateContinue || p.state == kStateOut || (hud.prototype && p.state == 9));

        if (live && playing) {
            // A shot left the gun this frame; the ammo drop also counts, for any path that does not raise `fired`.
            if (p.fired || (t.lastAmmo >= 0 && p.ammo < t.lastAmmo)) Fire(recoilPulse_[out], nowMs);
        }
        // A life lost while playing. Not on the hit that takes the last life: that one is the player's death, which
        // Hook of the Reaper's Death_* light commands show from P_Life reaching 0; a Damaged effect on the same lights
        // at the same moment would block it.
        if (live && inGame && t.wasPlaying && t.lastLives >= 0 && p.lives < t.lastLives && p.lives > 0)
            Fire(damagedPulse_[out], nowMs);

        Set(ammo_[out], playing ? p.ammo : 0);
        Set(clip_[out], playing && p.ammo > 0 ? 1 : 0);
        Set(life_[out], playing ? p.lives : 0);
        Set(dead_[out], dead ? 1 : 0);
        lampBlink_[out] = !playing;

        if (t.wasPlaying && !inGame) refreshAt_ = nowMs + 500;  // back to the menus (Light Gun Edition)
        if (playing) t.wasPlaying = true;
        else if (!inGame || (p.state == 9 && !hud.prototype)) t.wasPlaying = false;  // back to attract / title / not joined
        t.lastLives = inGame ? p.lives : -1;
        t.lastAmmo = playing ? p.ammo : -1;
        t.lastState = p.state;
    }
    Set(credits_, hud.credits < 0 ? 0 : hud.credits);
}

void GameOutputs::Tick(uint64_t nowMs) {
    if (!Running()) return;
    AcceptClients();
    if (refreshAt_ && nowMs >= refreshAt_) {
        refreshAt_ = 0;
        std::string reset = Line("mame_stop", 1) + "mame_start = " + kRomName + "\r";
        for (const Output& o : outputs_)
            if (o.value >= 0) reset += Line(o.name, o.value);
        SendAll(reset);
    }
    for (int i = 0; i < 2; ++i) {
        RunPulse(recoilPulse_[i], nowMs);
        RunPulse(damagedPulse_[i], nowMs);
        Set(lamp_[i], lampBlink_[i] ? static_cast<int>((nowMs / kLampBlinkMs) & 1) : 0);
    }
}

}  // namespace play
