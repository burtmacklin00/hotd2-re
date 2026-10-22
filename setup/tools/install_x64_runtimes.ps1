# Installs the vendor runtimes hotd2-outputs64.exe uses for its 64-bit graphics features, taken from the
# official HOTD2RE Build A 64-bit download (checked against its SHA-256):
#   AMD FidelityFX (FSR upscaling + frame generation), Intel XeSS, Microsoft DXC (ray shadows), with licenses.
# Nothing else from that package is copied; your hotd2.exe, settings and saves are not touched.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$url  = 'https://github.com/GitFist/hotd2-re/releases/download/v2026.10.21-a/hotd2re-win-x64.zip'
$sha  = 'AF7F67E123352E12B428AE94C2BF8EABCA9AA425D15536B557CF2642803A41C3'
$want = @('amd_fidelityfx_upscaler_dx12.dll', 'amd_fidelityfx_framegeneration_dx12.dll', 'libxess.dll',
          'dxcompiler.dll', 'dxil.dll', 'THIRD_PARTY_NOTICES.txt')
$dirs = @('vendor-licenses', 'dxc-licenses')

if (-not [Environment]::Is64BitOperatingSystem) { Write-Host 'This PC runs 32-bit Windows; use hotd2-outputs.exe.' -ForegroundColor Yellow; exit 1 }
if (Get-Process -Name 'hotd2', 'hotd2-outputs', 'hotd2-outputs64' -ErrorAction SilentlyContinue) {
    Write-Host 'HOTD2 is running. Close the game first.' -ForegroundColor Yellow; exit 2
}
if (-not ($want | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })) {
    Write-Host '64-bit runtimes are already installed.' -ForegroundColor Green; exit 0
}

$zip = Join-Path $env:TEMP 'hotd2re-win-x64.zip'
Write-Host 'Downloading the official HOTD2RE 64-bit runtimes (about 150 MB)...'
& curl.exe -L --fail --retry 3 -o $zip $url
if ($LASTEXITCODE -ne 0) { Write-Host 'Download failed. Check your internet connection.' -ForegroundColor Red; exit 1 }
if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha) {
    Remove-Item -LiteralPath $zip -Force
    Write-Host 'The download did not match the official package. Nothing was installed.' -ForegroundColor Red; exit 1
}
$tmp = Join-Path $env:TEMP 'hotd2re-win-x64'
if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null
& tar.exe -xf $zip -C $tmp
if ($LASTEXITCODE -ne 0) { Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force }
$src = Join-Path $tmp 'hotd2re'
foreach ($f in $want) { Copy-Item -LiteralPath (Join-Path $src $f) -Destination $root -Force }
foreach ($d in $dirs) { Copy-Item -LiteralPath (Join-Path $src $d) -Destination $root -Recurse -Force }
Remove-Item -LiteralPath $tmp -Recurse -Force; Remove-Item -LiteralPath $zip -Force
Write-Host '64-bit runtimes installed. Turn on FSR / XeSS / ray shadows in Options > Graphics.' -ForegroundColor Green
exit 0
