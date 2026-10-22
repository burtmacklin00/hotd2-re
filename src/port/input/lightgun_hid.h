#pragma once
// lightgunHID.ini: fixed Player 1 / Player 2 light guns by hardware ID, so a setup can be copied to another PC.
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

bool WriteHidDeviceList(const std::string& file, const std::vector<HidMouseDevice>& mice, const LightgunHidConfig& config);

}  // namespace input
