@echo off
rem Switches between the 4x3 folder (4:3 with bezel) and the 16x9 folder (16:9 stretch).
rem   "Swap 4x3 - 16x9.bat" 4x3   or   "Swap 4x3 - 16x9.bat" 16x9   to pick one.
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apply_profile.ps1" -Profiles "4x3,16x9" -To "%~1"
if "%~1"=="" timeout /t 3 >nul
endlocal
