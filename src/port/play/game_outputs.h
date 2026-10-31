#pragma once
// Game outputs for force-feedback tools (Hook of the Reaper, MAMEHooker, QMamehook, OutputHooker).
//
// Serves the MAME network output protocol on TCP 127.0.0.1:8000, the same one DemulShooter uses:
//   on connect   "mame_stop = 1\r" then "mame_start = hod2re\r", then every current value
//   on change    "<name> = <value>\r"
//   on exit      "mame_stop = 1\r"
// The output names match DemulShooter's HOTD2 PC target (same meanings), plus P1_Dead / P2_Dead.
//
//   P1_CtmRecoil / P2_CtmRecoil     1 for a short pulse on every shot (then 0)
//   P1_Damaged   / P2_Damaged       1 for a short pulse when the player loses a life (not the last one: that is death)
//   P1_Dead      / P2_Dead          1 while the player is dead (continue countdown / out), else 0
//   P1_Ammo      / P2_Ammo          bullets in the gun (0 when not playing)
//   P1_Clip      / P2_Clip          1 while the gun has ammo, 0 when empty / not playing
//   P1_Life      / P2_Life          lives (torches) left (0 when not playing)
//   P1_CtmLmpStart / P2_CtmLmpStart start lamp: blinks while the player can join, off while playing
//   Credits                         shared credits
#include <cstdint>
#include <string>
#include <vector>

namespace game { struct WorldHud; }

namespace play {

struct GameOutputsConfig {
    int port = 8000;
    int recoilOnMs = 40, recoilOffMs = 40;  // pulse shape of one recoil (DemulShooter's custom recoil defaults)
    int damagedMs = 200;                    // length of the Damaged pulse
};

class GameOutputs {
public:
    GameOutputs() = default;
    ~GameOutputs();
    GameOutputs(const GameOutputs&) = delete;
    GameOutputs& operator=(const GameOutputs&) = delete;

    // Opens the listening socket. Returns false (and leaves outputs off) if the port can't be opened.
    bool Start(const GameOutputsConfig& config, std::string* error = nullptr);
    void Stop();
    bool Running() const { return listener_ != ~uintptr_t(0); }

    // Call once per game frame after World::Step. `slotForP1` maps a world player slot to the P1 outputs
    // (online, the local player's slot, so a local gun set up as Player 1 always gets its own recoil).
    // `live` = false (catch-up replay, headless runs) updates values without firing pulses.
    void OnFrame(const game::WorldHud& hud, int slotForP1, bool live, uint64_t nowMs);
    // Call every rendered frame (also while paused) to finish timed pulses and lamp blinking.
    void Tick(uint64_t nowMs);

private:
    struct Output { std::string name; int value = -1; };
    struct Pulse { int output = -1; int queued = 0; bool on = false; uint64_t until = 0; int onMs = 0, offMs = 0; };
    struct PlayerTrack { int lastLives = -1, lastAmmo = -1, lastState = -1; bool wasPlaying = false; };

    int Add(const char* name);
    void Set(int output, int value);
    void Fire(Pulse& pulse, uint64_t nowMs);
    void RunPulse(Pulse& pulse, uint64_t nowMs);
    void AcceptClients();
    void SendAll(const std::string& line);
    bool SendTo(uintptr_t client, const std::string& line);
    static std::string Line(const std::string& name, int value);

    GameOutputsConfig config_;
    uintptr_t listener_ = ~uintptr_t(0);
    std::vector<uintptr_t> clients_;
    std::vector<Output> outputs_;
    bool wsa_ = false;

    int recoil_[2] = {-1, -1}, damaged_[2] = {-1, -1}, dead_[2] = {-1, -1}, ammo_[2] = {-1, -1}, clip_[2] = {-1, -1},
        life_[2] = {-1, -1}, lamp_[2] = {-1, -1}, credits_ = -1;
    Pulse recoilPulse_[2], damagedPulse_[2];
    PlayerTrack track_[2];
    bool lampBlink_[2] = {};
    // Light Gun Edition: leaving a game for the menus sends Life 0, which starts Hook of the Reaper's death light effect;
    // its lights can come back on afterwards. Re-send the zeroed values once the effect is over.
    uint64_t refreshAt_ = 0;
    void Resend(int output);
};

}  // namespace play
