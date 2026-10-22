HOTD2RE - GAME OUTPUTS BUILD (hotd2-outputs.exe)
=================================================

hotd2-outputs.exe is HOTD2RE built from the official source (2026 10 21 A) with game
outputs added for recoil / force-feedback tools, and lightgunHID.ini support. Your original hotd2.exe is untouched.
"Play HOTD2.bat" uses hotd2-outputs.exe automatically when it is in this folder.

64-BIT VERSION (hotd2-outputs64.exe) - recommended on 64-bit Windows
  Same game + outputs + lightgunHID, plus the 64-bit graphics features: native Direct3D 12,
  AMD FSR upscaling and frame generation (works on NVIDIA / AMD / Intel), Intel XeSS and
  experimental ray shadows, and NVIDIA DLSS (upscaling + frame generation, RTX cards) in
  the GitHub-built package. The vendor DLLs are included in that package; turn the
  features on in Options > Graphics (off by default). "Install 64-bit Runtimes.bat" is only
  needed for a copy without them.
  "Play HOTD2.bat" picks the 64-bit exe automatically. 32-bit and 64-bit builds have
  different version numbers, so online both players must use the same one.

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
  Player 1 and Player 2 guns by hardware ID (VID/PID):
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
  Copy hotr\hod2re.txt into the defaultLG folder where Hook of the Reaper is installed.
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
