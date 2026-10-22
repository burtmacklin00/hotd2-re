#pragma once
// lightgunHID.ini: fixed Player 1 / Player 2 light guns by hardware ID, so a setup can be copied to another PC.
//
//   [Lightguns]
//   P1_Lightgun_HID = VID_1209&PID_0001
//   P2_Lightgun_HID = VID_1209&PID_0002
//   MouseFallback = 1             ; optional (default 1)
//   StartButton = 0               ; optional (default 0): 1 = the guns' / mouse's Start button (middle by default)
//                                 ; works; 0 = it does nothing, so nobody pauses by accident (the trigger joins and
//                                 ; continues; P pauses through Play HOTD2)
//
// The older per-player layout is also accepted:
//
//   [Player1]
//   Device=VID_16C0&PID_0F01      ; any part of the gun's Windows device ID (case-insensitive);
//                                 ; "16C0:0F01" is accepted too
//   Index=1                       ; optional: the Nth matching device (two identical guns)
//   [Player2]
//   Device=VID_16C0&PID_0F02
//   [Options]
//   MouseFallback=1               ; no configured gun connected: one player with the mouse
//
// Each launch writes lightgunHID_devices.txt listing every connected mouse-type device.
#include "lightguns.h"

#include <string>
#include <vector>

namespace input {

struct LightgunHidConfig {
    std::string device[2];  // normalised to upper case; empty = slot not configured
    int index[2] = {1, 1};
    bool mouseFallback = true;
    bool startButton = false;  // StartButton=1: device Start (pause / join / continue) works
    bool Load(const std::string& file);
    bool Configured() const { return !device[0].empty() || !device[1].empty(); }
};

struct HidMouseDevice {
    std::string key;    // Lightguns' opaque device key
    std::string id;     // upper-case Raw Input device name, used for matching
    std::string label;  // "VID_xxxx&PID_xxxx&MI_xx  Product name" for the device list
};

// Connected mouse-type Raw Input devices (light guns report as mice). Empty off Windows.
std::vector<HidMouseDevice> ListHidMice(bool withNames = true);

// Puts the configured guns into `settings` (keeping each slot's buttons / calibration). Returns the number of
// configured guns that are connected; `slots` gets which player slots have a connected gun.
int ApplyLightgunHid(const LightgunHidConfig& config, const std::vector<HidMouseDevice>& mice, LightgunSettings& settings,
                     bool slots[2]);

// Wraps the game's gun source and removes the Start button (kStart) from every player's buttons, so a gun's or
// mouse's Start (middle button by default) can't pause the game. The trigger still joins and continues
// (play::DeviceWorldInput).
class NoStartGuns final : public GunSource {
   public:
    explicit NoStartGuns(GunSource& source) : source_(source) {}
    bool enabled = true;
    const char* Name() const override { return source_.Name(); }
    PlayerState Player(int player) const override {
        PlayerState s = source_.Player(player);
        if (enabled) {
            s.held &= static_cast<uint8_t>(~kStart);
            s.pressed &= static_cast<uint8_t>(~kStart);
            s.released &= static_cast<uint8_t>(~kStart);
        }
        return s;
    }
    void BeginFrame() override { source_.BeginFrame(); }

   private:
    GunSource& source_;
};

bool WriteHidDeviceList(const std::string& file, const std::vector<HidMouseDevice>& mice, const LightgunHidConfig& config);

}  // namespace input
