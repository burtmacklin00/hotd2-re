@echo off
rem Switches between the "Cartoon On" and "Cartoon Off" folders (comic outlines + flat shading).
rem   "Toggle Cartoon.bat" on   or   "Toggle Cartoon.bat" off   to pick one.
rem   The strength for On is in "Cartoon On\settings.ini" (cartoon=1 Low, 2 Medium, 3 High).
setlocal
set "TO="
if /i "%~1"=="on" set "TO=Cartoon On"
if /i "%~1"=="off" set "TO=Cartoon Off"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apply_profile.ps1" -Profiles "Cartoon On,Cartoon Off" -To "%TO%"
if "%~1"=="" timeout /t 3 >nul
endlocal
