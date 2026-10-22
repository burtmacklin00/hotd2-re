; The House of the Dead 2 (HOTD2RE) launcher - AutoHotkey 1.1. Also shipped compiled as Play HOTD2.exe (no AutoHotkey needed).
;
; Put it in the hotd2re folder (next to hotd2-outputs64.exe) and run it.
;   Play HOTD2.ahk / .exe    launches in the current display mode
;   Play HOTD2.ahk 4x3       switches to the 4x3 folder's settings first (4:3 with bezel)
;   Play HOTD2.ahk 16x9      switches to the 16x9 folder's settings first (16:9 stretch)
; In 4:3 mode the bezel is 4x3\bezel.png (your own) or 4x3\bezel-placeholder.png. It is drawn over the whole
; screen with its transparency, so art may reach into the game picture.
; Esc quits the game. P pauses (it sends the game its own Esc: pause / back / cancel). Both keys can be
; changed in Play HOTD2.ini. The gun's Start / middle button is off in the game (StartButton in LightgunHID.ini).

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On

; ---------------- Settings ----------------
; Set these in "Play HOTD2.ini" next to this file (works for Play HOTD2.exe too, which can't be edited):
;   [Launcher]
;   HotrExe=C:\Lightgun\Hook Of The Reaper\HookOfTheReaper.exe   (empty = don't start it)
;   HotrCloseAfter=0      (1 = close Hook of the Reaper when the game exits, also when you started it yourself)
;   ExitKey=Esc           (quits the game; empty = no exit key)
;   PauseKey=P            (does what Esc normally does in the game: pause / back / cancel)
LAUNCHER_INI := A_ScriptDir . "\Play HOTD2.ini"
; Your own settings files are never in the package (so updates can't overwrite them): the first run copies
; the defaults\ versions into place.
for i, name in ["Play HOTD2.ini", "LightgunHID.ini"]
    if (!FileExist(A_ScriptDir . "\" . name) && FileExist(A_ScriptDir . "\defaults\" . name))
        FileCopy, %A_ScriptDir%\defaults\%name%, %A_ScriptDir%\%name%
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

; The game reads the keyboard once per frame, so an instant Esc tap (down + up together) is missed: hold Esc for
; at least 80 ms, and for as long as the pause key is held.
SendGameEsc:
    Send, {Esc down}
    Sleep, 80
    KeyWait, %PAUSE_KEY%
    Send, {Esc up}
return

; Close with the game; keep the bezel above it.
WatchGame:
    Process, Exist, %GamePid%
    if !ErrorLevel
        Goto, Finish
    if BezelShown {
        WinSet, AlwaysOnTop, On, ahk_id %BezelHwnd%
        WinSet, Top, , ahk_id %BezelHwnd%
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
    Gui, Bezel: Destroy
    if HOTR_CLOSE_AFTER
        CloseHotr(HOTR_EXE)
    ExitApp
return

; The bezel: one borderless, click-through, always-on-top window covering the game's monitor, showing the whole
; PNG scaled to the screen with its own transparency. Transparent pixels show the game, so art that reaches into the
; game area (a character's arm, a gun) is drawn over the picture. Guns and the mouse click straight through it.
ShowBezel(image, pid) {
    global BezelShown, BezelHwnd
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
    if (sw - Round(sh * 4 / 3) <= 0)   ; no side bars (a 4:3 screen): no bezel
        return

    ; Draw the PNG, scaled to the monitor, into a 32-bit bitmap with GDI+ (built into Windows).
    hGdip := DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), NumPut(1, si, 0, "UInt")
    token := 0, pBmp := 0, G := 0, bits := 0
    if (DllCall("gdiplus\GdiplusStartup", "Ptr*", token, "Ptr", &si, "Ptr", 0) != 0)
        return
    DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", image, "Ptr*", pBmp)
    if !pBmp {
        DllCall("gdiplus\GdiplusShutdown", "Ptr", token)
        return
    }
    hdc := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    VarSetCapacity(bi, 40, 0)
    NumPut(40, bi, 0, "UInt"), NumPut(sw, bi, 4, "Int"), NumPut(-sh, bi, 8, "Int")
    NumPut(1, bi, 12, "UShort"), NumPut(32, bi, 14, "UShort")
    hbm := DllCall("CreateDIBSection", "Ptr", hdc, "Ptr", &bi, "UInt", 0, "Ptr*", bits, "Ptr", 0, "UInt", 0, "Ptr")
    obm := DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm, "Ptr")
    DllCall("gdiplus\GdipCreateFromHDC", "Ptr", hdc, "Ptr*", G)
    DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", G, "Int", 7)   ; high-quality bicubic
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", G, "Int", 4)     ; half-pixel: no edge shift
    DllCall("gdiplus\GdipDrawImageRectI", "Ptr", G, "Ptr", pBmp, "Int", 0, "Int", 0, "Int", sw, "Int", sh)

    ; Layered (0x80000) + click-through (0x20) + never takes focus (0x8000000).
    Gui, Bezel: New, +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x8080020 +HwndBezelHwnd
    Gui, Bezel: Show, x%sx% y%sy% w%sw% h%sh% NA
    VarSetCapacity(pt, 8, 0), NumPut(sx, pt, 0, "Int"), NumPut(sy, pt, 4, "Int")
    VarSetCapacity(sz, 8, 0), NumPut(sw, sz, 0, "Int"), NumPut(sh, sz, 4, "Int")
    VarSetCapacity(src, 8, 0)
    ; BLENDFUNCTION: AC_SRC_OVER, full opacity, per-pixel alpha (AC_SRC_ALPHA); ULW_ALPHA = 2
    DllCall("UpdateLayeredWindow", "Ptr", BezelHwnd, "Ptr", 0, "Ptr", &pt, "Ptr", &sz, "Ptr", hdc, "Ptr", &src
          , "UInt", 0, "UInt*", 0x01FF0000, "UInt", 2)

    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", G)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBmp)
    DllCall("SelectObject", "Ptr", hdc, "Ptr", obm)
    DllCall("DeleteObject", "Ptr", hbm)
    DllCall("DeleteDC", "Ptr", hdc)
    DllCall("gdiplus\GdiplusShutdown", "Ptr", token)
    BezelShown := true
}

; Closes Hook of the Reaper however it was started: the HotrExe file name, or any process named like
; "Hook...Reaper...exe". Asks its windows to close first, then ends whatever is still running after 3 seconds.
CloseHotr(hotrExe) {
    names := {}
    if (hotrExe != "") {
        SplitPath, hotrExe, n
        names[n] := true
    }
    pids := []
    for p in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, Name FROM Win32_Process")
        if (names.HasKey(p.Name) || RegExMatch(p.Name, "i)^hook.*reaper.*\.exe$"))
            pids.Push(p.ProcessId)
    if !pids.Length()
        return
    DetectHiddenWindows, Off
    for i, pid in pids
        WinClose, ahk_pid %pid%
    for i, pid in pids {
        Process, WaitClose, %pid%, 3
        if ErrorLevel
            Process, Close, %pid%
    }
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
