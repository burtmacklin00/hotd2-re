; The House of the Dead 2 (HOTD2RE) launcher - AutoHotkey 1.1. Also shipped compiled as Play HOTD2.exe (no AutoHotkey needed).
;
; Put it in the hotd2re folder (next to hotd2-outputs64.exe) and run it.
;   Play HOTD2.ahk / .exe    launches in the current display mode
;   Play HOTD2.ahk 4x3       switches to the 4x3 folder's settings first (4:3 with bezel)
;   Play HOTD2.ahk 16x9      switches to the 16x9 folder's settings first (16:9 stretch)
; In 4:3 mode the bezel is 4x3\bezel.png (your own) or 4x3\bezel-placeholder.png.
; Esc quits the game. P pauses (it sends the game its own Esc: pause / back / cancel). Both keys can be
; changed in Play HOTD2.ini. The gun's pause button and the middle mouse button also pause.

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On

; ---------------- Settings ----------------
; Set these in "Play HOTD2.ini" next to this file (works for Play HOTD2.exe too, which can't be edited):
;   [Launcher]
;   HotrExe=C:\Lightgun\Hook Of The Reaper\HookOfTheReaper.exe   (empty = don't start it)
;   HotrCloseAfter=0      (1 = close Hook of the Reaper when the game exits)
;   ExitKey=Esc           (quits the game; empty = no exit key)
;   PauseKey=P            (does what Esc normally does in the game: pause / back / cancel)
LAUNCHER_INI := A_ScriptDir . "\Play HOTD2.ini"
IniRead, HOTR_EXE, %LAUNCHER_INI%, Launcher, HotrExe, %A_Space%
IniRead, HOTR_CLOSE_AFTER, %LAUNCHER_INI%, Launcher, HotrCloseAfter, 0
IniRead, EXIT_KEY, %LAUNCHER_INI%, Launcher, ExitKey, Esc
IniRead, PAUSE_KEY, %LAUNCHER_INI%, Launcher, PauseKey, P
HOTR_EXE := Trim(HOTR_EXE, " `t""")
HOTR_CLOSE_AFTER := (HOTR_CLOSE_AFTER = "1" || HOTR_CLOSE_AFTER = "true")
EXIT_KEY := Trim(EXIT_KEY), PAUSE_KEY := Trim(PAUSE_KEY)
; ------------------------------------------

SETTINGS := A_ScriptDir . "\hotd2re_settings.ini"

; Game exe: 64-bit build on 64-bit Windows, else 32-bit, else the original.
GameExe := "hotd2.exe"
if FileExist("hotd2-outputs.exe")
    GameExe := "hotd2-outputs.exe"
if (A_Is64bitOS && FileExist("hotd2-outputs64.exe"))
    GameExe := "hotd2-outputs64.exe"
if !FileExist(GameExe) {
    MsgBox, 16, HOTD2, Can't find %GameExe% in %A_ScriptDir%.`nPut this script in the hotd2re folder.
    ExitApp
}

; First run (no settings file yet): start from the light "Graphics Low" preset so any PC can run it.
if (!FileExist(SETTINGS) && FileExist(A_ScriptDir . "\Graphics Low\settings.ini"))
    ApplyFolder(A_ScriptDir . "\Graphics Low", SETTINGS)

; Optional display folder from the command line (4x3 or 16x9).
Mode = %1%
if (Mode != "") {
    if !ApplyFolder(A_ScriptDir . "\" . Mode, SETTINGS) {
        MsgBox, 16, HOTD2, No %Mode%\settings.ini in %A_ScriptDir%.
        ExitApp
    }
}

; Hook of the Reaper first, so it is listening when the game opens its outputs.
StartedHotr := false
if (HOTR_EXE != "" && FileExist(HOTR_EXE)) {
    SplitPath, HOTR_EXE, HotrName, HotrDir
    Process, Exist, %HotrName%
    if !ErrorLevel {
        Run, "%HOTR_EXE%", %HotrDir%, , HotrPid
        StartedHotr := true
        Sleep, 2000
    }
}

; Launch the game.
Run, "%A_ScriptDir%\%GameExe%", %A_ScriptDir%, , GamePid
WinWait, ahk_pid %GamePid%, , 30
WinActivate, ahk_pid %GamePid%

; 4:3 + fullscreen: bezel art over the black side bars.
if (ReadSetting(SETTINGS, "aspect") = "4:3" && ReadSetting(SETTINGS, "fullscreen") != "0") {
    Bezel := A_ScriptDir . "\4x3\bezel.png"
    if !FileExist(Bezel)
        Bezel := A_ScriptDir . "\4x3\bezel-placeholder.png"
    if FileExist(Bezel) {
        Sleep, 1500   ; let the game finish going fullscreen
        ShowBezel(Bezel, GamePid)
    }
}

; Exit / pause keys, only while the game window is active. The game never sees the exit key.
Hotkey, If, WinActive("ahk_pid " . GamePid)
if (EXIT_KEY != "")
    Hotkey, $%EXIT_KEY%, Finish, UseErrorLevel
if (PAUSE_KEY != "")
    Hotkey, $%PAUSE_KEY%, SendGameEsc, UseErrorLevel
Hotkey, If

SetTimer, WatchGame, 1000
return

#If WinActive("ahk_pid " . GamePid)
#If

SendGameEsc:
    Send, {Esc}
return

; Close with the game; keep the bezel above it.
WatchGame:
    Process, Exist, %GamePid%
    if !ErrorLevel
        Goto, Finish
    if BezelShown {
        WinSet, AlwaysOnTop, On, ahk_id %BezelHwndL%
        WinSet, AlwaysOnTop, On, ahk_id %BezelHwndR%
        WinSet, Top, , ahk_id %BezelHwndL%
        WinSet, Top, , ahk_id %BezelHwndR%
    }
return

Finish:
    Critical            ; held-Esc key repeats must not interrupt the shutdown
    if Finishing
        return
    Finishing := true
    SetTimer, WatchGame, Off
    Process, Exist, %GamePid%
    if ErrorLevel {
        DetectHiddenWindows, Off   ; ask the visible game window to close
        WinClose, ahk_pid %GamePid%
        Process, WaitClose, %GamePid%, 3
        if ErrorLevel
            Process, Close, %GamePid%
    }
    Gui, BezelL: Destroy
    Gui, BezelR: Destroy
    if (StartedHotr && HOTR_CLOSE_AFTER)
        Process, Close, %HotrPid%
    ExitApp
return

; Two borderless, click-through, always-on-top windows over the side bars of the game's monitor. Each shows the
; whole bezel image scaled to the screen, offset so only its own edge strip is visible.
ShowBezel(image, pid) {
    global BezelShown, BezelHwndL, BezelHwndR, PicBezelL, PicBezelR
    ; The monitor the game window is on (the game runs fullscreen there).
    WinGetPos, wx, wy, ww, wh, ahk_pid %pid%
    cx := wx + ww // 2, cy := wy + wh // 2
    sx := 0, sy := 0, sw := A_ScreenWidth, sh := A_ScreenHeight
    SysGet, monCount, MonitorCount
    Loop, %monCount% {
        SysGet, m, Monitor, %A_Index%
        if (cx >= mLeft && cx < mRight && cy >= mTop && cy < mBottom) {
            sx := mLeft, sy := mTop, sw := mRight - mLeft, sh := mBottom - mTop
            break
        }
    }
    bar := Floor((sw - Round(sh * 4 / 3)) / 2)
    if (bar <= 0)
        return
    rightX := sx + sw - bar
    offset := bar - sw
    for i, side in ["BezelL", "BezelR"] {
        Gui, %side%: New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000020 +LastFound +Hwnd%side%Hwnd
        Gui, %side%: Margin, 0, 0
        Gui, %side%: Color, 000000
        Gui, %side%: Add, Picture, x0 y0 w%sw% h%sh% vPic%side%, %image%
        WinSet, Transparent, 255   ; layered + E0x20 = mouse / gun clicks pass through
    }
    GuiControl, BezelR: Move, PicBezelR, x%offset% y0 w%sw% h%sh%
    Gui, BezelL: Show, x%sx% y%sy% w%bar% h%sh% NA
    Gui, BezelR: Show, x%rightX% y%sy% w%bar% h%sh% NA
    BezelHwndL := BezelLHwnd, BezelHwndR := BezelRHwnd
    BezelShown := true
}

; Copies the key=value lines of <folder>\settings.ini into the game's settings file (same keys replaced, others kept).
ApplyFolder(folder, settingsFile) {
    src := folder . "\settings.ini"
    if !FileExist(src)
        return false
    want := {}, order := []
    Loop, Read, %src%
    {
        line := Trim(A_LoopReadLine)
        if (line = "" || InStr(";#[", SubStr(line, 1, 1)))
            continue
        eq := InStr(line, "=")
        if (eq > 1) {
            k := Trim(SubStr(line, 1, eq - 1))
            want[k] := Trim(SubStr(line, eq + 1)), order.Push(k)
        }
    }
    out := "", done := {}
    Loop, Read, %settingsFile%
    {
        line := A_LoopReadLine
        eq := InStr(line, "=")
        k := eq > 1 ? Trim(SubStr(line, 1, eq - 1)) : ""
        if (k != "" && want.HasKey(k)) {
            out .= k . "=" . want[k] . "`r`n", done[k] := true
        } else {
            out .= line . "`r`n"
        }
    }
    for i, k in order
        if !done.HasKey(k)
            out .= k . "=" . want[k] . "`r`n"
    f := FileOpen(settingsFile, "w", "CP0")   ; overwrite in one go
    if !IsObject(f) {
        MsgBox, 16, HOTD2, Can't write %settingsFile%.`nIs it read-only?
        ExitApp
    }
    f.Write(out), f.Close()
    return true
}

; Reads "key=value" from the game's settings file (it has no [sections]).
ReadSetting(file, key) {
    Loop, Read, %file%
    {
        line := Trim(A_LoopReadLine)
        if (SubStr(line, 1, StrLen(key) + 1) = key . "=")
            return Trim(SubStr(line, StrLen(key) + 2))
    }
    return ""
}
