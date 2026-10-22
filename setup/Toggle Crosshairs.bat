@echo off
rem Switches between the "Crosshairs On" and "Crosshairs Off" folders.
rem   "Toggle Crosshairs.bat" on   or   "Toggle Crosshairs.bat" off   to pick one.
setlocal
set "TO="
if /i "%~1"=="on" set "TO=Crosshairs On"
if /i "%~1"=="off" set "TO=Crosshairs Off"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apply_profile.ps1" -Profiles "Crosshairs Off,Crosshairs On" -To "%TO%"
if "%~1"=="" timeout /t 3 >nul
endlocal
