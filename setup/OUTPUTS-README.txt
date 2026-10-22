HOTD2RE - LIGHT GUN EDITION (outputs, 2-player light guns, bezel, presets)
===========================================================================

QUICK START
  1. Extract this package into your hotd2re game folder (next to game\ and scenes\).
  2. Plug in your guns and run LightgunSetup.exe once: pull the Player 1 trigger,
     then Player 2, then Save. (Or edit LightgunHID.ini by hand.)
  3. Start Hook of the Reaper (copy "Hook of the Reaper\defaultLG\hod2re.txt" into its defaultLG folder first).
  4. Run "Play HOTD2.exe".  Tap Esc = pause, HOLD Esc = quit.

WHICH FILE DOES WHAT
  Play HOTD2.exe            Starts the game. No AutoHotkey needed.
  Play HOTD2.ahk            Same launcher as a script, for AutoHotkey 1.1 users / front-ends.
  Play HOTD2.ini            Launcher settings: Hook of the Reaper path, hold-Esc time.
  LightgunSetup.exe         Pick the Player 1 / Player 2 guns (writes LightgunHID.ini).
  Swap 4x3 - 16x9.bat       4:3 with bezel  <->  16:9 stretch.
  Toggle Crosshairs.bat     Crosshairs on <-> off.
  Graphics - Max.bat        Best quality (DLSS on NVIDIA RTX, FSR 3 otherwise).
  Graphics - Low.bat        For older graphics cards.
  Toggle 2x Graphics.bat    Downloads (first time) and switches the official 2x texture pack.
  hotd2-outputs64.exe       The game, 64-bit (used automatically on 64-bit Windows).
  hotd2-outputs.exe         The game, 32-bit (for 32-bit Windows).
  You never need to run the hotd2-outputs exes directly - use Play HOTD2.

TEXTURE PACKS
  The only released pack is the official 2x pack (Toggle 2x Graphics.bat). Options > Graphics >
  Packs also shows Material Detail / Model Smoothing: those need a pack with material maps or
  model rules, and none has been released yet - "Needs pack" there is normal.

64-BIT VERSION (hotd2-outputs64.exe) - recommended on 64-bit Windows
  Same game + outputs + lightgunHID, plus the 64-bit graphics features: native Direct3D 12,
  AMD FSR upscaling and frame generation (works on NVIDIA / AMD / Intel), Intel XeSS and
  experimental ray shadows, and NVIDIA DLSS (upscaling + frame generation, RTX cards).
  The vendor DLLs are included; "Graphics - Max.bat" turns the features on.
  "Play HOTD2.ahk" picks the 64-bit exe automatically. 32-bit and 64-bit builds have
  different version numbers, so online both players must use the same one.

LAUNCHING (Play HOTD2.exe, or Play HOTD2.ahk with AutoHotkey 1.1)
  Starts the game, draws the bezel in 4:3, optionally starts Hook of the Reaper
  (set HotrExe in Play HOTD2.ini), and exits when the game closes.
  Tap Esc = pause, HOLD Esc 1.5 s = quit. Optional argument: 4x3 or 16x9.
  Windows may warn about the unsigned exes the first time: More info > Run anyway.

SWITCH FOLDERS
  4x3\  16x9\  "Crosshairs On"\  "Crosshairs Off"\ each hold a settings.ini with only the
  lines for that mode (aspect=4:3 / aspect=stretch / crosshairs=1 / crosshairs=0).
  Switching copies those lines into hotd2re_settings.ini; your other settings stay.
  Add more lines to a folder (e.g. render=4) to change them only in that mode.
  "Swap 4x3 - 16x9.bat"   flips the display folder   (or: ... 4x3 / ... 16x9)
  "Toggle Crosshairs.bat" flips the crosshair folder (or: ... on / ... off)
  Bezel: 4x3\bezel.png (your own, 1920x1080 with art in the outer 240 px each side);
  4x3\bezel-placeholder.png is used if there is none.

GRAPHICS PRESETS
  "Graphics - Max.bat"  Direct3D 12, DLSS (NVIDIA RTX) or FSR 3 at Native AA, ray shadows,
                        4096 shadows, contact shading, reflections, light fog, pose smoothing.
                        No frame generation (it adds aim delay with light guns).
  "Graphics - Low.bat"  For older cards: Direct3D 11, 2x resolution, FXAA, extra effects off.
  Each sets only the lines in "Graphics Max\settings.ini" / "Graphics Low\settings.ini";
  edit those to taste. Aspect, crosshairs, 2x textures and volume are not touched.

HOW TOOLS CONNECT
  Protocol : MAME network outputs (same as MAME / DemulShooter)
  Address  : 127.0.0.1, TCP port 8000 (this PC only; not reachable from the network)
  Game name: hod2re   (name your Hook of the Reaper / MAMEHooker profile hod2re)
  Works with Hook of the Reaper, MAMEHooker, QMamehook, OutputHooker.
  Do not run DemulShooter's outputs at the same time: both want port 8000.

OUTPUTS (P1_ and P2_ versions of each)
  P1_CtmRecoil    1 = short pulse on every shot (40 ms on / 40 ms off), then 0
  P1_Damaged      1 = 200 ms pulse when the player loses a life
  P1_Dead         1 while the player is dead (continue countdown / out), else 0
  P1_Ammo         bullets in the gun (0 when not playing)
  P1_Clip         1 while the gun has ammo, 0 when empty
  P1_Life         lives left (0 when not playing)
  P1_CtmLmpStart  start-button lamp: blinks while the player can join, off while playing
  Credits         shared credits

LIGHT GUNS (LightgunHID.ini)
  Easiest: run LightgunSetup.exe, pull the trigger on the Player 1 gun, then the Player 2
  gun (or "No Player 2 gun"), and click Save. It writes LightgunHID.ini for you.
  (A desk mouse clicking inside the setup window just operates the app.)
  Or edit LightgunHID.ini by hand - Player 1 and Player 2 guns by hardware ID (VID/PID):
    [Lightguns]
    P1_Lightgun_HID = VID_1209&PID_0001
    P2_Lightgun_HID = VID_1209&PID_0002
  - Guns connected: 2-player light-gun mode (Raw Input, each gun its own player).
  - No configured gun connected: 1 player with the mouse (add MouseFallback = 0 to turn off).
  - Each launch writes lightgunHID_devices.txt listing connected devices and their IDs.
  - Two identical guns: give both the same ID; Player 2 gets the second one.
  - Remove the file to use the in-game Options > Light Guns assignment instead.
  Buttons and calibration are still set per player in Options > Light Guns.

HOOK OF THE REAPER
  Copy "Hook of the Reaper\defaultLG\hod2re.txt" into the defaultLG folder where Hook of
  the Reaper is installed (or merge this "Hook of the Reaper" folder into that install).
  Recoil: P1_CtmRecoil (Recoil or Recoil_Value) or ammo-based (Ammo_Value).
  Damage -> Damage (rumble), Life -> Death_Value + Display_Life, Ammo -> Display_Ammo.

2X GRAPHICS
  "Toggle 2x Graphics.bat" downloads the official 2x pack the first time (about 720 MB,
  checked against its SHA-256), then switches it on / off with the assets= setting.

ONLINE PLAY
  Your own gun is always P1 outputs, even when you joined someone else's room as
  Player 2 (matches the game's advice to assign your local gun to Player 1).
  This build has its own version number: online, both players must use this same
  hotd2-outputs.exe. It will not see rooms made by the official hotd2.exe.

COMMAND-LINE OPTIONS
  --no-outputs        turn outputs off
  --outputs-port N    use a different TCP port

NOTES
  - No update notices are shown by this build (they would point to official builds
    without outputs).
  - Source changes are in source\hotd2re-outputs.patch (applies to GitFist/hotd2-re
    commit 60f608d). The native port code is MIT licensed; see LICENSE-native-code.txt.
