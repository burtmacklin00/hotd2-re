@echo off
rem Updates this folder to the newest Light Gun Edition release on GitHub. Your settings, gun setup, saves and
rem bezel.png are kept. "Update HOTD2.bat" check  only says whether an update is available.
rem Drag a downloaded hotd2re-outputs-package.zip onto this file to install that zip instead (no internet needed).
if /i "%~1"=="check" (powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\update.ps1" -Check & exit /b)
if /i "%~x1"==".zip" (powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\update.ps1" -FromZip "%~f1" & pause & exit /b)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\update.ps1" & pause & exit /b
