# The House of the Dead 2 (HOTD2RE) – Light Gun Edition

An unofficial add-on for [HOTD2RE](https://github.com/GitFist/hotd2-re), the native PC port of The House of the Dead 2, set up for light guns and arcade cabinets:

- **Two-player light guns** (Raw Input) with fixed Player 1 / Player 2 guns, and a one-click gun picker
- **Recoil and outputs** for Hook of the Reaper / MAMEHooker (ammo, life, damage, death, recoil, start lamps)
- **Launcher** with a 4:3 bezel, Esc to quit and 1 (a light gun's Start key) to pause, and no pop-ups (works in LaunchBox and other front ends)
- **One-click switches** for 4:3 or 16:9, crosshairs on or off, Cartoon look, and max or low graphics (DLSS / FSR / XeSS on the 64-bit build)
- **Menus for arcade cabinets:** Player 1's gun drives the menus with its crosshair (no Windows pointer); Player 2 joins Arcade, Original, Horde, Boss Mode and Challenges by pulling the trigger
- **House of the Dead 2 bezel and "Rebuild" title logo** included
- **Updater** that keeps your settings, gun setup, saves and bezel

<!-- release -->**Current release: 2.3 LG** (`outputs-v2026.11.11-a`)<!-- /release -->

All the game code and data come from the official HOTD2RE project. This edition adds the light-gun features on top. New official releases are merged in automatically and published after testing.

---

## Install (new users)

1. **Get the official game.** Download the official Windows x64 zip (named like **`HOTD2RE-2.3-Windows-x64.zip`**) from the official releases:
   👉 https://github.com/GitFist/hotd2-re/releases/latest
   Extract it into a normal, writable folder (for example `C:\Games\HOTD2`, not inside *Program Files*). You get a `hotd2re` folder.

2. **Add the Light Gun Edition.** Download **`hotd2re-outputs-package.zip`**:
   👉 https://github.com/burtmacklin00/hotd2-re/releases/latest
   Extract it **into the same `hotd2re` folder**, next to the `game` and `scenes` folders, and choose *Replace* if asked.

3. **Pick your guns.** Plug in your guns, run **`1 - Light Gun Setup.exe`** (it also opens by itself the first time you start the game with no guns set), pull the Player 1 trigger, then the Player 2 trigger (or click *No Player 2 gun*), and click **Save**.
   No guns? Click **No light guns (mouse)** in the setup and it won't ask again. With no guns connected, the game runs as one player with the mouse.

4. **Hook of the Reaper (recoil)** *(optional)*. Copy `Hook of the Reaper\defaultLG\hod2re.txt` into the `defaultLG` folder of your Hook of the Reaper install. This game file is from the Hook of the Reaper author.
   To have the launcher close Hook of the Reaper when the game exits, set `HotrCloseAfter=1` in `Play HOTD2.ini`. Set `HotrExe=` to its full path if you also want the launcher to start it.

5. **Play.** Run **`Play HOTD2.exe`**.
   Windows may warn the first time because the exes are unsigned: click *More info → Run anyway*.

### Optional

| File | What it does |
|---|---|
| `Swap 4x3 - 16x9.bat` | 4:3 with bezel ↔ 16:9 stretched |
| `Toggle Crosshairs.bat` | Crosshairs on ↔ off |
| `Toggle Cartoon.bat` | Cartoon look (comic outlines + flat shading) on ↔ off. Also in *Options → Graphics → Cartoon* |
| `Graphics - Max.bat` | Best quality (DLSS on NVIDIA RTX, FSR 3 on other cards) |
| `Graphics - Low.bat` | For older graphics cards (the default on first run) |

**Graphics:** the official Naomi arcade graphics and audio are the default (official 2.0+); *Options → Graphics → Graphics Mode* switches to the PC graphics.

**Bezel and logo:** the edition comes with a House of the Dead 2 bezel (4:3 mode) and a "Rebuild" title logo (`logo.png`, shown on the title screen and menus).
- **Your own bezel:** save a 1920×1080 PNG as `4x3\bezel.png`. Transparent areas show the game, and art may overlap the game picture. Shots on the bezel outside the game picture count as off-screen (reload).
- **Your own logo:** replace `logo.png` with your own PNG (transparent background). Delete it for the original logo.

### LaunchBox / front ends

Point the game entry at **`Play HOTD2.exe`** in the `hotd2re` folder. It shows the bezel and loads straight into the game with no update checks or prompts. When the game exits it returns to the front end, closing Hook of the Reaper too if that's turned on.

---

## Controls

| Input | Does |
|---|---|
| Trigger | Shoot. Also joins a game and continues on the CONTINUE countdown |
| Shoot off screen / bezel | Reload |
| Reload button (right) | Reload |
| Middle / Start button | Off, so nobody pauses by accident (`StartButton = 1` in `LightgunHID.ini` turns it back on) |
| **Esc** | Quit the game |
| **1** | Pause, during gameplay only (the usual Start key on light guns). Shoot *Resume* to carry on |
| Menus | Player 1's gun only (Player 2's gun is ignored there) |

**Hidden prototype** (a short HOTD4-style bonus chapter): press **1** (or F8) on the title screen or the Home / Play / Practice menu. Hold the trigger for its SMG, **middle button = grenade**, reload button or a shot off screen = reload.

**Typing of the Dead** (official 1.6, keyboard only): switch to it with the logo card on the main menu. Use **F10** to pause there, since Esc quits the game through the launcher. The guns aren't used in Typing mode.

Guns are picked in `LightgunHID.ini` (with `1 - Light Gun Setup.exe`) and calibrated in their own software, so the game has no in-game Light Guns page.

---

## Updating

Close the game and run **`Update HOTD2.bat`**. It downloads the newest release, checks it, and installs it. Your `LightgunHID.ini`, `Play HOTD2.ini`, settings, saves, records, `bezel.png`, `logo.png` and `Play HOTD2.ahk` are never replaced (`logo.png` and `Play HOTD2.ahk` are only added if they're missing, so a customized launcher script stays as it is).
No internet on the game PC? Download `hotd2re-outputs-package.zip` on another PC and drag it onto `Update HOTD2.bat`.
The package also carries the game's data files (Typing of the Dead, Naomi arcade graphics and arcade audio), so updates are about 530 MB, and the game itself never downloads anything at startup.
Texture packs are no longer used (official 2.0+), so the updater also deletes the old `remaster-2x` pack folder (about 700 MB).

**Online leaderboards:** there's no username screen at startup. To send your scores to the online leaderboards, set a name in *Options → Gameplay → Username*.

**Online play:** both players need the same Light Gun Edition release, so update together. This edition can't join rooms made by the official build.

---

## Outputs (for Hook of the Reaper / MAMEHooker)

MAME network outputs on `127.0.0.1:8000`, game name **`hod2re`**:
`P1_/P2_CtmRecoil`, `P1_/P2_Damaged`, `P1_/P2_Dead`, `P1_/P2_Ammo`, `P1_/P2_Clip`, `P1_/P2_Life`, `P1_/P2_CtmLmpStart`, `Credits`.
Don't run DemulShooter's outputs at the same time, because both use port 8000.

**Built-in recoil (official 1.9, off by default):** *Options → Devices → Feedback* can send recoil straight to OpenFIRE, GUN4IR, Blamcon or Sinden guns without Hook of the Reaper. Use it **or** Hook of the Reaper for a gun, not both: both drive the same gun, so recoil may fail or fire twice. The page warns about this when a gun is chosen, and **Reset to Light Gun Edition defaults** on that page turns it back off for both players.

---

Unofficial and not affiliated with SEGA or the HOTD2RE authors. Source for this edition: branch [`hotd2re-outputs-lightgunhid`](https://github.com/burtmacklin00/hotd2-re/tree/hotd2re-outputs-lightgunhid). Full details are in `README.txt` in the package.
