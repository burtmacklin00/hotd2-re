@echo off
rem Switches the official 2x graphics pack on / off. The first time, it downloads and installs it.
rem   "Toggle 2x Graphics.bat" on    or    "Toggle 2x Graphics.bat" off   to force one.
setlocal
set "MODE=%~1"
if "%MODE%"=="" set "MODE=toggle"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\graphics_2x.ps1" -Mode "%MODE%"
if "%~1"=="" pause
endlocal
