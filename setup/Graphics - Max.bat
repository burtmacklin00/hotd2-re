@echo off
rem Applies the "Graphics Max" folder's settings to the game (renderer, upscaling, lighting, effects).
rem Edit "Graphics Max\settings.ini" to change what this preset sets.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\apply_profile.ps1" -Profiles "Graphics Max,Graphics Low" -To "Graphics Max"
timeout /t 4 >nul
