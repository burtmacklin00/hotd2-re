# The House of the Dead 2 (HOTD2RE) – Light Gun Edition

An unofficial add-on for [HOTD2RE](https://github.com/GitFist/hotd2-re), the native PC port of The House of the Dead 2, set up for light guns and arcade cabinets:

- **Two-player light guns** (Raw Input) with fixed Player 1 / Player 2 guns, and a one-click gun picker
- **Recoil and outputs** for Hook of the Reaper / MAMEHooker (ammo, life, damage, death, recoil, start lamps)
- **Launcher** with a 4:3 bezel, Esc to quit and 1 (a light gun's Start key) to pause, and no pop-ups (works in LaunchBox and other front ends)
- **One-click switches** for 4:3 or 16:9, crosshairs on or off, and max or low graphics (DLSS / FSR / XeSS on the 64-bit build)
- **Updater** that keeps your settings, gun setup, saves and bezel

All the game code and data come from the official HOTD2RE project. This edition adds the light-gun features on top. New official releases are merged in automatically.

---

## Install (new users)

1. **Get the official game.** Download the official Windows x64 zip (named like **`HOTD2RE-1.1-Windows-x64.zip`**) from the official releases:
   👉 https://github.com/GitFist/hotd2-re/releases/latest
   Extract it into a normal, writable folder (for example `C:\Games\HOTD2`, not inside *Program Files*). You get a `hotd2re` folder.

2. **Add the Light Gun Edition.** Download **`hotd2re-outputs-package.zip`**:
   👉 https://github.com/burtmacklin00/hotd2-re/releases/latest
   Extract it **into the same `hotd2re` folder**, next to the `game` and `scenes` folders, and choose *Replace* if asked.

3. **Pick your guns.** Plug in your guns, run **`1 - Light Gun Setup.exe`** (it also opens by itself the first time you start the game with no guns set), pull the Player 1 trigger, then the Player 2 trigger (or click *No Player 2 gun*), and click **Save**.
   No guns? Click **No light guns (mouse)** in the setup and it won't ask again. With no guns connected, the game runs as one player with the mouse.

4. **Hook of the Reaper (recoil)** *(optional)*. Copy `Hook of the Reaper\defaultLG\hod2re.txt` into the `defaultLG` folder of your Hook of the Reaper install. This game file is from the Hook of the Reaper author; `hod2re - notes.txt` next to it has recoil timing tips and how to switch guns to 4:3 automatically.
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
| `Toggle 2x Graphics.bat` | Downloads (first time, about 720 MB) and turns on the official 2× texture pack |

**House of the Dead 2 bezel (optional):** download **`bezel.png`** from the same release page (https://github.com/burtmacklin00/hotd2-re/releases/latest) and put it in the `hotd2re\4x3` folder, choosing *Replace* if asked. It shows in 4:3 mode and updates never overwrite it.

**Your own bezel:** save a 1920×1080 PNG as `4x3\bezel.png`. Transparent areas show the game, and art may overlap the game picture. Shots on the bezel outside the game picture count as off-screen (reload).

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

**Hidden prototype** (a short HOTD4-style bonus chapter): press **1** (or F8) on the title screen or the Home / Play / Practice menu. Hold the trigger for its SMG, **middle button = grenade**, reload button or a shot off screen = reload.

Buttons and calibration can be changed per player in *Options → Light Guns*. Guns calibrated in their own software work without in-game calibration.

---

## Updating

Close the game and run **`Update HOTD2.bat`**. It downloads the newest release, checks it, and installs it. Your `LightgunHID.ini`, `Play HOTD2.ini`, settings, saves, records, texture packs and `bezel.png` are never replaced.
No internet on the game PC? Download `hotd2re-outputs-package.zip` on another PC and drag it onto `Update HOTD2.bat`.

**Online leaderboards:** there's no username screen at startup. To send your scores to the online leaderboards, set a name in *Settings → Gameplay → Username*.

**Online play:** both players need the same Light Gun Edition release, so update together. This edition can't join rooms made by the official build.

---

## Outputs (for Hook of the Reaper / MAMEHooker)

MAME network outputs on `127.0.0.1:8000`, game name **`hod2re`**:
`P1_/P2_CtmRecoil`, `P1_/P2_Damaged`, `P1_/P2_Dead`, `P1_/P2_Ammo`, `P1_/P2_Clip`, `P1_/P2_Life`, `P1_/P2_CtmLmpStart`, `Credits`.
Don't run DemulShooter's outputs at the same time, because both use port 8000.

---

Unofficial and not affiliated with SEGA or the HOTD2RE authors. Source for this edition: branch [`hotd2re-outputs-lightgunhid`](https://github.com/burtmacklin00/hotd2-re/tree/hotd2re-outputs-lightgunhid). Full details are in `README.txt` in the package.
