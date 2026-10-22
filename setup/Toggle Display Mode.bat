@echo off
rem Switches HOTD2 between 4:3-with-bezel and 16:9 stretch.
rem   Toggle Display Mode.bat           flips to the other mode
rem   Toggle Display Mode.bat 4:3       forces 4:3 with bezel
rem   Toggle Display Mode.bat stretch   forces 16:9 stretch
setlocal
set "MODE=%~1"
if "%MODE%"=="" set "MODE=toggle"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\set_aspect.ps1" -Mode "%MODE%"
if "%~1"=="" timeout /t 3 >nul
endlocal
