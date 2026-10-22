@echo off
rem Applies the "Graphics Low" folder's settings to the game (renderer, upscaling, lighting, effects).
rem Edit "Graphics Low\settings.ini" to change what this preset sets.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apply_profile.ps1" -Profiles "Graphics Max,Graphics Low" -To "Graphics Low"
timeout /t 4 >nul
