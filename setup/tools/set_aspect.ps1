# Sets the aspect mode in hotd2re_settings.ini.
#   -Mode toggle   flips between 4:3 and stretch (default)
#   -Mode 4:3      4:3 with side bars (bezel overlay is drawn there by the launcher)
#   -Mode stretch  stretch to fill a 16:9 screen
# All other settings in the file (volume, input, lobby, etc.) are left alone.
param(
    [ValidateSet('toggle', '4:3', '4x3', 'stretch', '16:9', '16x9')]
    [string]$Mode = 'toggle'
)

$root = Split-Path $PSScriptRoot -Parent
$ini  = Join-Path $root 'hotd2re_settings.ini'

# The game saves its settings itself, so do not edit while it is running.
if (Get-Process -Name 'hotd2', 'hotd2-outputs', 'hotd2-outputs64' -ErrorAction SilentlyContinue) {
    Write-Host 'HOTD2 is running. Close the game first, then switch modes.' -ForegroundColor Yellow
    exit 2
}

$lines = @()
if (Test-Path -LiteralPath $ini) { $lines = @(Get-Content -LiteralPath $ini) }

$current = ''
foreach ($l in $lines) { if ($l -match '^\s*aspect\s*=\s*(.*)$') { $current = $Matches[1].Trim(); break } }

switch ($Mode) {
    'toggle' { $new = if ($current -eq '4:3') { 'stretch' } else { '4:3' } }
    { $_ -in '4:3', '4x3' } { $new = '4:3' }
    default { $new = 'stretch' }
}

$found = $false
$out = foreach ($l in $lines) {
    if (-not $found -and $l -match '^\s*aspect\s*=') { $found = $true; "aspect=$new" } else { $l }
}
if (-not $found) { $out = @($out) + "aspect=$new" }

[System.IO.File]::WriteAllLines($ini, [string[]]$out)

$label = if ($new -eq '4:3') { '4:3 with bezel' } else { '16:9 stretch' }
Write-Host "HOTD2 display mode is now: $label" -ForegroundColor Green
exit 0
