@echo off
rem One-time setup for hotd2-outputs64.exe: downloads the official FSR / XeSS / DXC runtimes.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\install_x64_runtimes.ps1"
pause
