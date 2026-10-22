# Switches between setting folders (e.g. "4x3" / "16x9", "Crosshairs On" / "Crosshairs Off").
# Each folder's settings.ini holds key=value lines; switching copies those lines into hotd2re_settings.ini
# (replacing the same keys, adding missing ones). Everything else in hotd2re_settings.ini is left alone.
#   -Profiles "A,B"      the two folders to flip between (the one not currently active is applied)
#   -To A                apply that folder instead of flipping
param(
    [Parameter(Mandatory = $true)][string]$Profiles,   # "A,B" (one string: -File passes arrays as text)
    [string]$To = ''
)
$ErrorActionPreference = 'Stop'
$Names = @($Profiles -split ',' | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ })
if ($Names.Count -ne 2) { Write-Host 'Give exactly two folders, e.g. -Profiles "4x3,16x9"' -ForegroundColor Red; exit 1 }
$root = Split-Path $PSScriptRoot -Parent
$ini  = Join-Path $root 'hotd2re_settings.ini'

if (Get-Process -Name 'hotd2', 'hotd2-outputs', 'hotd2-outputs64' -ErrorAction SilentlyContinue) {
    Write-Host 'HOTD2 is running. Close the game first, then switch.' -ForegroundColor Yellow; exit 2
}

function Read-Pairs([string]$file) {
    $pairs = [ordered]@{}
    if (Test-Path -LiteralPath $file) {
        foreach ($l in Get-Content -LiteralPath $file) {
            $t = $l.Trim()
            if ($t -eq '' -or $t.StartsWith(';') -or $t.StartsWith('#') -or $t.StartsWith('[')) { continue }
            $eq = $t.IndexOf('=')
            if ($eq -gt 0) { $pairs[$t.Substring(0, $eq).Trim()] = $t.Substring($eq + 1).Trim() }
        }
    }
    return $pairs
}

$live = Read-Pairs $ini
$sets = @{}
foreach ($p in $Names) {
    $f = Join-Path (Join-Path $root $p) 'settings.ini'
    if (-not (Test-Path -LiteralPath $f)) { Write-Host "Missing $p\settings.ini" -ForegroundColor Red; exit 1 }
    $sets[$p] = Read-Pairs $f
}

# Which folder is active now: every one of its lines matches the game's settings.
$active = $null
foreach ($p in $Names) {
    $match = $true
    foreach ($k in $sets[$p].Keys) { if ($live[$k] -ne $sets[$p][$k]) { $match = $false; break } }
    if ($match) { $active = $p; break }
}
if ($To) { $target = $To } elseif ($active -eq $Names[0]) { $target = $Names[1] } else { $target = $Names[0] }
if (-not $sets.ContainsKey($target)) { Write-Host "Unknown folder '$target'" -ForegroundColor Red; exit 1 }

$lines = @(); if (Test-Path -LiteralPath $ini) { $lines = @(Get-Content -LiteralPath $ini) }
$want = $sets[$target]
$done = @{}
$out = foreach ($l in $lines) {
    $eq = $l.IndexOf('=')
    $k = if ($eq -gt 0) { $l.Substring(0, $eq).Trim() } else { '' }
    if ($k -and $want.Contains($k)) { "$k=$($want[$k])"; $done[$k] = $true } else { $l }
}
foreach ($k in $want.Keys) { if (-not $done[$k]) { $out = @($out) + "$k=$($want[$k])" } }
[System.IO.File]::WriteAllLines($ini, [string[]]$out)

Write-Host "Switched to: $target" -ForegroundColor Green
exit 0
