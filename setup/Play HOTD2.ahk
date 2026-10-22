; The House of the Dead 2 (HOTD2RE) launcher - AutoHotkey 1.1
;
; Put this script in the hotd2re folder (next to hotd2-outputs64.exe) and run it.
;   Play HOTD2.ahk            launches in the current display mode
;   Play HOTD2.ahk 4:3        switches to 4:3 with bezel first
;   Play HOTD2.ahk stretch    switches to 16:9 stretch first
; Tap Esc to pause (the game's own pause). HOLD Esc for 1.5 seconds to quit.

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On

; ---------------- Settings ----------------
; Hook of the Reaper: full path to its exe, or leave empty to not start it.
; Example: HOTR_EXE := "C:\Lightgun\Hook Of The Reaper\HookOfTheReaper.exe"
HOTR_EXE := ""
HOTR_CLOSE_AFTER := false   ; true = close Hook of the Reaper when the game exits
HOLD_TO_QUIT_MS := 1500     ; how long to hold Esc to quit
; ------------------------------------------

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

; Optional display mode from the command line (4:3 or stretch).
Mode = %1%
if (Mode != "") {
    RunWait, powershell -NoProfile -ExecutionPolicy Bypass -File "%A_ScriptDir%\tools\set_aspect.ps1" -Mode "%Mode%", %A_ScriptDir%, Hide
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

; 4:3 mode: bezel over the side bars (your bezels\hotd2_4x3.png, else the placeholder).
Aspect := ReadSetting("hotd2re_settings.ini", "aspect")
Bezel := A_ScriptDir . "\bezels\placeholder_4x3.png"
if FileExist(A_ScriptDir . "\bezels\hotd2_4x3.png")
    Bezel := A_ScriptDir . "\bezels\hotd2_4x3.png"
SplitPath, GameExe, , , , GameName
if (Aspect = "4:3" && FileExist(Bezel)) {
    Run, powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%A_ScriptDir%\tools\bezel_overlay.ps1" -Bezel "%Bezel%" -ProcessName "%GameName%", %A_ScriptDir%, Hide
}

; Wait for the game to close, then clean up.
SetTimer, WatchGame, 1000
return

WatchGame:
    Process, Exist, %GamePid%
    if !ErrorLevel
        Goto, Finish
return

; Tap Esc: passes through to the game (pause). Hold Esc: quit.
~Esc::
    KeyWait, Esc, % "T" . (HOLD_TO_QUIT_MS / 1000)
    if ErrorLevel
        Goto, Finish
return

Finish:
    SetTimer, WatchGame, Off
    Process, Exist, %GamePid%
    if ErrorLevel {
        WinClose, ahk_pid %GamePid%
        Process, WaitClose, %GamePid%, 5
        Process, Close, %GamePid%
    }
    if (StartedHotr && HOTR_CLOSE_AFTER)
        Process, Close, %HotrPid%
    ExitApp
return

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
