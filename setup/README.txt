THE HOUSE OF THE DEAD 2 (HOTD2RE) - LIGHT GUN EDITION
=====================================================
Unofficial build of HOTD2RE (github.com/GitFist/hotd2-re) with light-gun outputs for recoil,
fixed two-player light guns, a bezel launcher and one-click settings. Everything specific to
this edition comes first; the original game notes follow below.

QUICK START
  1. Extract this package into your hotd2re game folder (next to game\ and scenes\).
  2. Plug in your guns and run LightgunSetup.exe once: pull the Player 1 trigger,
     then Player 2, then Save. (Or edit LightgunHID.ini by hand.)
  3. Start Hook of the Reaper (copy "Hook of the Reaper\defaultLG\hod2re.txt" into its defaultLG folder first).
  4. Run "Play HOTD2.exe".  Esc = exit, P = pause. The gun's middle / Start button is off (no accidental pauses).
  Later: run "Update HOTD2.bat" to get the newest version (your settings are kept).

WHICH FILE DOES WHAT
  Play HOTD2.exe            Starts the game. No AutoHotkey needed.
  Play HOTD2.ahk            Same launcher as a script, for AutoHotkey 1.1 users / front-ends.
  Play HOTD2.ini            Launcher settings: Hook of the Reaper path, exit and pause keys.
                            (Made from defaults\ on the first run; updates never replace it.)
  LightgunSetup.exe         Pick the Player 1 / Player 2 guns (writes LightgunHID.ini).
  Update HOTD2.bat          Installs the newest Light Gun Edition release from GitHub.
  Swap 4x3 - 16x9.bat       4:3 with bezel  <->  16:9 stretch.
  Toggle Crosshairs.bat     Crosshairs on <-> off.
  Toggle Cartoon.bat        Cartoon look (comic outlines + flat shading) on <-> off.
  Graphics - Max.bat        Best quality (DLSS on NVIDIA RTX, FSR 3 otherwise).
  Graphics - Low.bat        For older graphics cards.
  Toggle 2x Graphics.bat    Downloads (first time) and switches the official 2x texture pack.
  hotd2-outputs64.exe       The game, 64-bit (used automatically on 64-bit Windows).
  hotd2-outputs.exe         The game, 32-bit (for 32-bit Windows).
  You never need to run the hotd2-outputs exes directly - use Play HOTD2.

UPDATING
  Run "Update HOTD2.bat" (close the game first). It downloads the newest Light Gun Edition
  release from github.com/burtmacklin00/hotd2-re/releases, checks it, and copies it over this
  folder. It never replaces your own files:
    LightgunHID.ini, Play HOTD2.ini, hotd2re_settings.ini, saves / records (hotd2re_*),
    4x3\bezel.png and installed texture packs.
  If you edited one of the shipped files (e.g. "Graphics Max\settings.ini" or a .bat), the old
  copy is saved in backup\<date>\ before the new one goes in.
  "Update HOTD2.bat" check   only tells you whether an update is available.
  No internet on the game PC? Download hotd2re-outputs-package.zip elsewhere and drag it onto
  "Update HOTD2.bat".
  VERSION.txt shows which release this folder has. New official HOTD2RE releases are merged into
  the Light Gun Edition automatically, usually within a day.
  Manual install still works too: extracting the zip over the folder is safe, because the zip
  doesn't contain any of your own files (their defaults are in defaults\).

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
  (set HotrExe in Play HOTD2.ini), and exits when the game closes. HotrCloseAfter=1 closes
  Hook of the Reaper when the game exits, even if you started it yourself.
  Esc = exit the game. P = pause (it sends the game its own Esc, so P also goes back in menus
  and cancels setup screens). Change either key in Play HOTD2.ini. Backspace / right click
  also go back in menus. Optional argument: 4x3 or 16x9.
  First launch on a new install (no Play HOTD2.ini yet) starts from the Graphics Low preset in
  borderless fullscreen (the official package starts windowed; the bezel needs fullscreen).
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

CARTOON LOOK
  Options > Graphics, top of the list ("COMIC LOOK"):
    Cartoon         Off / Low / Medium / High: dark comic outlines and flat shading bands during
                    play (menus, pause and the HUD stay clean). Left / right changes the level.
    Comic Pop-ups   On / Off: comic words (POW! BAM! ZAP!) burst out where your shots hit.
                    Only while Cartoon is on.
  "Toggle Cartoon.bat" switches both on / off. The level used for On is in
  "Cartoon On\settings.ini" (cartoon=1, 2 or 3; comic_popups=1 or 0).
  Looks best with the 2x texture pack. Gameplay and aiming are unchanged.

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
  - StartButton = 1 turns the guns' / mouse's Start button (middle) back on. Default: off.
  - Each launch writes lightgunHID_devices.txt listing connected devices and their IDs.
  - Two identical guns: give both the same ID; Player 2 gets the second one.
  - Remove the file to use the in-game Options > Light Guns assignment instead.
  Buttons and calibration are still set per player in Options > Light Guns.

GUN CONTROLS (defaults; change them per player in Options > Light Guns)
  Trigger (left button)      shoot; also joins a game and continues on the CONTINUE countdown
  Shoot off screen           reload (anywhere outside the game picture, including the bezel)
  Reload (right button)      reload
  Start / Pause (middle)     OFF in this edition, so nobody pauses by accident: the trigger joins
                             and continues, P on the keyboard pauses. To turn it back on, add
                             StartButton = 1 to LightgunHID.ini (then it starts, continues and pauses).
  Confirm (4th button)       Enter in menus
  Keyboard (Play HOTD2):     Esc = quit the game, P = pause
  Hidden prototype (HOTD4-style bonus chapter): press 1 (or F8) on the title screen or the Home /
  Play / Practice menu. In it: hold the trigger for the SMG, middle button = grenade, reload
  button or a shot off screen = reload. It is local play only and has no leaderboard.
  Which physical button on your gun sends left / right / middle / 4th depends on the gun's own
  software; Options > Light Guns > button capture lets you assign them in game.

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
  This edition has its own version number (the official one plus "LG", shown on the Network
  screen): online, both players need the same Light Gun Edition release. It does not see rooms
  made by the official hotd2.exe. Run "Update HOTD2.bat" on both PCs to match versions.

COMMAND-LINE OPTIONS
  --no-outputs        turn outputs off
  --outputs-port N    use a different TCP port

NOTES
  - No update check or update pop-up at all when the game loads (safe for LaunchBox and other
    front ends). Updating is only ever done by running "Update HOTD2.bat" yourself.
  - Source: github.com/burtmacklin00/hotd2-re (branch hotd2re-outputs-lightgunhid).
    The native port code is MIT licensed; see LICENSE-native-code.txt.

==============================================================================
ORIGINAL GAME NOTES (HOTD2RE)
==============================================================================

THE HOUSE OF THE DEAD 2 - NIGHT SHIFT NATIVE PORT

START PLAYING
1. Extract the entire ZIP into a normal, writable folder. Do not run inside the ZIP.
2. Open the hotd2re folder and double-click "Play HOTD2.exe" (see LIGHT GUN EDITION above).

Build 2026 10 21 A + Light Gun Edition (Windows x64 and x86).
This complete package includes the required game data. No separate installation or disc is needed.
Keep the game and scenes folders next to the game exes. Launch with "Play HOTD2.exe".
Requires Windows 10/11 with Direct3D 11 support. Optional graphics features have additional
GPU/backend requirements. Settings and saves are kept in this folder. No personal saves
or device profiles are included. Sound is enabled on normal hotd2.exe launches, including
launches with a custom game-folder path or command-line options.

NIGHT SHIFT MENUS
Home uses the game's moving standby preview. Play contains Arcade, Original, Boss Mode
(time attack), Horde and Randomizer. Practice contains Training and Scene Select.
Home also offers Leaderboard, Online, Options and Exit. Host Online, Browse Lobby and
Peer to Peer are directly accessible beside the waiting-room preview.
Options > Game Options contains game rules, sound controls and Wii Remote / Light Gun setup.
The graphics menu's Display > Menu Style selects Night Shift or Classic for the next launch.
Classic changes menu appearance while retaining the same supported graphics settings.

ONLINE TWO-PLAYER
Both players should use this same package.
1. Use Home > Host Online to host, or Online to open all network choices.
   With Classic menus, choose Network from mode select.
2. The host chooses Unlimited Continues and Private Room, then Start.
3. The other player selects BROWSE LOBBY and picks the host's room.
4. Public rooms need no code. Private rooms appear in the list but require the host's 5-digit code.
5. Both players enter the shared lobby. The creator (player 1) chooses ARCADE, ORIGINAL,
   SCENE SELECTION, BOSS MODE, HORDE MODE, or RANDOMIZER. Chapter and boss selections are controlled by the host.
6. Pause > Return to Lobby brings BOTH players back to that room to choose another mode.
   The room and player slots stay connected. Leave Room (or Esc in the lobby) ends the room.

PEER TO PEER provides unlisted rooms: choose Host to get a 5-digit code, or Join to enter the
host's code. Only the joining player enters a code. This option also needs the lobby service.
Unlimited Continues OFF gives three continues. Backspace or right click goes back/closes a room.
The lobby address is already configured. Both players' versions on the Network screen must match.
Backing out cancels a room you were creating. Stale joins end with a connection error.

All three room options try a direct connection first and automatically use the online
server relay when needed. You do not need to set up router port forwarding. If the active
connection stops responding, the game tries the other path; a brief pause may occur.
Input delay is chosen from the connection's measured round trip before the game starts.
The lobby service is needed to find a player, and the relay must be available when it is
carrying gameplay or providing a backup path. Networks that block outgoing UDP can still
prevent online play. If Windows asks about network access, allow this app on your network.
If a player disconnects, the other player keeps playing in their original player slot.
After reopening the SAME game folder, choose Network > REJOIN GAME. No new code is needed.
The returning player catches up to the current match and keeps their original P1/P2 slot.
Temporary network interruptions recover automatically when possible. A brief initial stall
detects the lost connection. Rejoining uses the server relay and needs the other client to
remain in the room; it cannot restore a room after both clients close or someone leaves it.
Rejoin works across returns to the lobby and subsequent games in the same room.
Longer sessions take longer to catch up (up to four hours of history).
If both clients keep running during a network outage, P1's timeline is used on recovery.
Keep hotd2re_rejoin.bin in your game folder; it is your private rejoin ticket, not a room code.
Do not copy that file to your friend. Pausing pauses the shared game.
Switching to another window does not pause it automatically.

LEADERBOARD
Home > Leaderboard contains Arcade, Original, Horde and individual Boss Mode tables.
Source: Local shows your own records. Source: Online queries the shared service.
Shared records are unverified, client-reported results, not anti-cheat rankings.
Publishing is manual: finish an eligible new run, choose Publish New Run, enter initials
and confirm. Opening the page does not automatically publish existing saves.
The public rankings service update is pending deployment; shared queries and publishing
may remain unavailable until the matching service is installed. Local records work offline.

UPDATES AND EXISTING SAVES
Normal launches check the official GitHub release page once in the background. A newer
build is offered at the local title/main menu: Open download page or Later. Downloading
and installation are manual. Offline/failed checks stay silent. Pass --no-update-check
to disable this check. Scripted/headless/direct gameplay launches skip it.

When updating, close the game and extract the ENTIRE new ZIP into a separate writable
folder. Keep its new executable, all accompanying DLLs, licenses and scenes together.
Replacing only hotd2.exe can leave older, incompatible graphics runtimes installed.
To retain your progress and preferences, copy these files from your old hotd2re folder
into the new hotd2re folder before starting it, replacing the supplied default settings:
  hotd2re_settings.ini       display, audio, menu and input preferences
  hotd2re_save.bin           game progress, records, inventory and unlocks
  hotd2re_horde_records.txt  local Horde records, if present
  hotd2re_lightguns.ini      light-gun assignments, calibration and bindings, if present
  hotd2re_wii.ini            Wii Remote calibration and controls, if present
Copy your installed visual-pack folders too if your settings select them. Keep the old
folder as a backup until you have checked the new version. Both online players should
update together and create a new room. Never give your private rejoin ticket to another player.

HORDE MODE
Choose Play > Horde Mode, or let the host choose it in the shared online lobby.
Defend the barrels against timed enemy waves. Between rounds, use the 4 x 4 store to buy
weapons, upgrade each weapon's damage and ammunition, repair or reinforce barrels,
buy lives, or recruit CPU agents. Shoot an owned weapon's icon to equip it.
Select READY when finished shopping. Every tenth round includes the Zeal / Kuarl boss pair.
Use the same updated executable on both PCs.

RANDOMIZER
Choose Play > Randomizer or the shared online lobby. It plays the Original
campaign with randomized ordinary zombie types and group sizes (one to three, with a
crowd limit). Bosses, rescues, vehicles and special scripted enemies retain their encounters.
Each chapter rolls a different weapon and a compatible bonus item for each player.
Spoken dialogue is randomized with matching subtitles. Scene characters can look like
other civilians, agents or zombies, while retaining their original actions and rescue roles.
Costumes and dialogue choices stay consistent within a run and change with the run seed.
Randomized pickups equip immediately for the receiving player. A rescue reward goes to P1
when both players are active. The weapon and bonus are shown briefly after a roll or pickup.
Both PCs use the same run seed; reconnecting replays those same decisions. Randomizer
does not spend or save Original-mode inventory, unlocks or high scores.

CONTROLS AND DISPLAY
Prototype (local play): press F8 on the title or main menu. This hidden HOTD4 chapter-one
adaptation uses HOTD2 assets, simplified rooms/encounters, two routes and a four-armed boss.
Hold the trigger for its SMG, right-click to reload, and press G to throw a grenade.
Shoot a route choice or use Left/Right. ESC pauses; results unlock after three seconds.
Left mouse button: shoot. Right mouse button: reload.
Esc: pause / resume during gameplay, back in selection screens. It never closes the app.
(With "Play HOTD2.exe": Esc EXITS the game and P does everything Esc does in this file.)
Enter: confirm menus, start / continue an inactive player. (Middle mouse button: off in the Light Gun Edition.)
Menus: arrow keys, Enter, Esc / Backspace, or aim and click. Either player can resume a pause.
The game and sound continue when you switch to another window. Use manual Pause before
switching if you want the game stopped. Background keyboard/device input cannot fire or
operate menus. Gun, mouse and Wii Remote buttons held across a focus change must be
released before use again.
Original item select: shoot a stock item to equip it, an equipped item to put it back,
and your END button when ready. Both players choose their own items and confirm separately.
Shoot the inventory arrows to scroll. BACK returns to the main menu or shared lobby.
Boss, Training and Scene Select: shoot a side arrow/card to browse, then the centre card
or START to play. LEVEL arrows change unlocked difficulty; BACK returns to the menu/lobby.
Training instructions and Retry/Back, ranking-page arrows and BACK are clickable too.
Online menus have clickable rows, a room-code number pad, DELETE, BACK and cancel buttons.
At the end of a chapter, the results show each player's stage totals and the team summary.
After three seconds, click, shoot, or press Enter to continue. Either online player can advance both games.
Click, shoot, or press Enter to skip the ending credits. Qualifying scores still reach name entry;
online players return to their shared lobby. Either player can skip.
Native Wii Remotes: Options > Game Options > Wii Remotes, or Pause > Wii Remotes.
Classic menus retain Options > Wii Remotes.
Select Connect remotes and press red SYNC (or 1 + 2). A powered sensor bar and compatible
Bluetooth adapter are required; for DolphinBar, use Mode 4 and sync with the bar first.
Choose Player 1/2 setup to calibrate aim and change buttons. Defaults: B fires, A reloads,
+ confirms, HOME pauses. D-pad navigates. Aim at each calibration cross and press B.
Automatic reconnect keeps searching; Swap players also swaps their saved profiles.
Native Wii support has automated coverage; real-hardware pairing and aiming are not yet verified.

Close the window or use Exit on the main menu to quit.
Pause also offers separate music, gunshot, and sound-effect volumes.
Mouse/touchpad input is enabled by default. Open Options > Game Options > Light Guns,
or Pause > Light Guns. Classic menus retain Options > Light Guns.
Choose LIGHT GUNS, then Assign Player 1 and pull that gun's trigger. Repeat for Player 2.
Player settings offer button capture, four-target aim calibration, and Test both guns.
ESC cancels setup or leaves the test. Assignments and settings save automatically.
Choose MOUSE to use a mouse or touchpad again. Input changes release native Wii Remote
control; it can be enabled again in Wii Remotes. Sinden users must keep their border enabled.
Online players should assign their local gun to Player 1. Light-gun hardware testing is pending.

GRAPHICS AND DISPLAY
Open a graphics shortcut in Options, or Pause > Graphics Options. The full menu has nine
categories: Display, Image, Lighting, Performance, Packs, Color, Resolution, CRT and Advanced.
Keyboard: Up/Down selects a row, Left/Right changes a setting, Enter selects/changes it,
and Esc/Backspace returns. Click a category tab, or use Left/Right on Back to change category.

Display: windowed, borderless or exclusive Fullscreen; monitor, window size, aspect ratio,
Fit/Stretch, integer scaling and menu theme. Night Shift's Menu Opacity changes background
strength while text remains readable; Classic labels this option Night Shift only.
Display > Reset All Graphics asks for confirmation, saves defaults and preserves your
pack, menu theme, game rules, audio and controls. Some renderer changes need a restart.

Image: image presets, MSAA/post AA/TAA, texture filtering, anisotropy, Sharp HUD,
sharpening and Gameplay Crosshairs. Setting Gameplay Crosshairs Off hides both players'
gameplay sights locally; menu, shop and calibration pointers remain visible. Aiming and
shooting are unchanged. The system '+' pointer is also hidden automatically during play
and returns for menus, pause, calibration and desktop use.
Image Preset > Original changes image options and downsampling only; it is not Reset All Graphics.

Lighting: pixel lighting, supported smoke blending/contact shading, raster/ray shadows,
bloom, volumetric fog, reflections and cutscene blur. These are optional effects.
Performance: VSync, frame limit, supported tearing/latency controls and statistics.
Packs: installed visual-pack choice, material detail and model smoothing. Material maps
and smoothing require a compatible authored pack. Pack changes apply on the next launch.
Color: brightness, gamma, contrast, saturation, color grading, Blood Color, HDR and test
patterns. Blood Color switches Green/Red immediately and saves locally; online players
choose independently.
HDR uses scRGB and needs Windows HDR enabled; the original art remains SDR.
Resolution: internal render scale, output matching/SSAA, dynamic resolution, downsampling
and FSR 1 spatial upscaling. Render Scale 2x/3x/4x renders more pixels at runtime and
needs no texture-pack download. A separate optional 2x texture pack replaces artwork.
CRT: scanlines, phosphor masks, curvature and glow. Curvature is disabled for raw light
guns and active frame generation so their input/display requirements remain intact.
Advanced: renderer, supported vendor upscaling, upscale quality, frame generation and
pose interpolation. Renderer/vendor changes require restart. Pose interpolation above
60 FPS adds up to one simulation tick of visual delay; game logic stays at 60 Hz.

Direct3D 11 and SDL GPU provide the broad optional raster-effects paths. Native Direct3D 12
on Windows x64 enables supported vendor reconstruction/frame generation and experimental
directional DXR shadows. Each backend/GPU supports different features; an unavailable
option explains its dependency or reports a fallback. Advanced effects, HDR, ray shadows
and frame generation are optional and Off by default.

While changing graphics during a paused game, select Hide UI or press H to see the actual
scene without resuming. H, Show UI, Back/Reload, Enter or Start restores the menu. The
fullscreen test patterns provide black, white, gamma and geometry references.

BUILD.txt and PACKAGE-MANIFEST.json identify the executable and source label.
SHA256SUMS.txt lists the payload and manifest hashes.
