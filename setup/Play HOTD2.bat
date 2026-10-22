@echo off
rem Launches HOTD2 in the current display mode. In 4:3 mode the bezel is drawn
rem over the side bars from bezels\hotd2_4x3.png.
rem Optional: "Play HOTD2.bat" 4:3   or   "Play HOTD2.bat" stretch   sets the mode first
rem (handy for front-ends: one entry per mode).
setlocal
cd /d "%~dp0"

if not "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\set_aspect.ps1" -Mode "%~1"
    if errorlevel 1 exit /b 1
)

set "ASPECT="
for /f "tokens=1,* delims==" %%a in ('findstr /b /i "aspect=" "hotd2re_settings.ini" 2^>nul') do set "ASPECT=%%b"

rem Use the outputs build (recoil / damage / ammo for Hook of the Reaper) when it is here.
set "EXE=hotd2.exe"
if exist "%~dp0hotd2-outputs.exe" set "EXE=hotd2-outputs.exe"
rem 64-bit build on 64-bit Windows.
if exist "%~dp0hotd2-outputs64.exe" if defined ProgramFiles(x86) set "EXE=hotd2-outputs64.exe"
start "" "%~dp0%EXE%"

rem Your own bezel: bezels\hotd2_4x3.png (1920x1080, art in the outer 240 px each side).
set "BEZEL=%~dp0bezels\placeholder_4x3.png"
if exist "%~dp0bezels\hotd2_4x3.png" set "BEZEL=%~dp0bezels\hotd2_4x3.png"
if "%ASPECT%"=="4:3" if exist "%BEZEL%" (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0tools\bezel_overlay.ps1" -Bezel "%BEZEL%" -ProcessName "%EXE:~0,-4%"
)
endlocal
