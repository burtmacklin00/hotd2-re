# Optional 2x graphics pack (official HOTD2RE release asset).
#   -Mode toggle  installs the pack if it is missing, then switches it on / off (default)
#   -Mode on      installs if missing and turns it on
#   -Mode off     turns it off (the files stay; delete remaster-2x to remove them)
# On / off is the assets= line in hotd2re_settings.ini; both hotd2.exe and hotd2-outputs.exe read it.
param([ValidateSet('toggle', 'on', 'off')][string]$Mode = 'toggle')

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$ini  = Join-Path $root 'hotd2re_settings.ini'
$pack = Join-Path $root 'remaster-2x'
$url  = 'https://github.com/GitFist/hotd2-re/releases/download/v2026.10.16-r/hotd2re-graphics-2x.zip'
$sha  = '17260FAFADB806C1F6C198B7EDB516F813D3C679C15C7E2D56C0E7176AEE0FBD'

if (Get-Process -Name 'hotd2', 'hotd2-outputs', 'hotd2-outputs64' -ErrorAction SilentlyContinue) {
    Write-Host 'HOTD2 is running. Close the game first.' -ForegroundColor Yellow; exit 2
}

$lines = @(); if (Test-Path -LiteralPath $ini) { $lines = @(Get-Content -LiteralPath $ini) }
$isOn = [bool]($lines | Where-Object { $_ -match '^\s*assets\s*=\s*remaster-2x\s*$' })
$turnOn = switch ($Mode) { 'on' { $true } 'off' { $false } default { -not $isOn } }

if ($turnOn -and -not (Test-Path -LiteralPath (Join-Path $pack 'tex\common\0.png'))) {
    $zip = Join-Path $env:TEMP 'hotd2re-graphics-2x.zip'
    Write-Host 'Downloading the 2x graphics pack (about 720 MB)...'
    & curl.exe -L --fail --retry 3 -o $zip $url
    if ($LASTEXITCODE -ne 0) { Write-Host 'Download failed. Check your internet connection.' -ForegroundColor Red; exit 1 }
    Write-Host 'Checking the download...'
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha) {
        Remove-Item -LiteralPath $zip -Force
        Write-Host 'The download did not match the official pack. Nothing was installed.' -ForegroundColor Red; exit 1
    }
    Write-Host 'Extracting (10,000+ files, this takes a minute)...'
    $tmp = Join-Path $env:TEMP 'hotd2re-graphics-2x'
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    New-Item -ItemType Directory -Path $tmp | Out-Null
    & tar.exe -xf $zip -C $tmp
    if ($LASTEXITCODE -ne 0) { Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force }
    Move-Item -LiteralPath (Join-Path $tmp 'remaster-2x') -Destination $pack
    Copy-Item -LiteralPath (Join-Path $tmp 'INSTALL-2X-GRAPHICS.txt') -Destination $root -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp -Recurse -Force; Remove-Item -LiteralPath $zip -Force
}

$out = @($lines | Where-Object { $_ -notmatch '^\s*assets\s*=' })
if ($turnOn) { $out += 'assets=remaster-2x' }
[System.IO.File]::WriteAllLines($ini, [string[]]$out)

if ($turnOn) { Write-Host '2x graphics: ON' -ForegroundColor Green } else { Write-Host '2x graphics: OFF (original graphics)' -ForegroundColor Green }
exit 0
