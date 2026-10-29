# Updates this Light Gun Edition folder to the newest release on GitHub.
#   Downloads the release zip, checks it, and copies it over this folder.
#   Never touches your own files: LightgunHID.ini, Play HOTD2.ini, hotd2re_settings.ini, saves, records,
#   4x3\bezel.png, texture packs. Any other file that you changed (a preset settings.ini, a .bat) is copied
#   to "backup\<date>" first.
#   -Check   only say whether an update is available
#   -Force   reinstall the newest release even if this folder already has it
#   -FromZip "path\hotd2re-outputs-package.zip"   install a zip you already downloaded (no internet needed;
#            or drag the zip onto "Update HOTD2.bat")
param(
    [string]$Repo = 'burtmacklin00/hotd2-re',
    [switch]$Check,
    [switch]$Force,
    [string]$FromZip = ''
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar on PowerShell 5
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$root = Split-Path $PSScriptRoot -Parent
$asset = 'hotd2re-outputs-package.zip'

# Files that are yours: never replaced (the package doesn't contain them either; this is a second guard).
$keep = @('LightgunHID.ini', 'Play HOTD2.ini', 'hotd2re_settings.ini', '4x3\bezel.png', 'hotd2re_rejoin.bin')
function Is-Kept([string]$rel) {
    if ($keep -contains $rel) { return $true }
    if ($rel -notmatch '\\' -and $rel -match '^hotd2re_') { return $true }   # saves, records, lightgun / Wii setup
    return $false
}

$current = ''
$verFile = Join-Path $root 'VERSION.txt'
if (Test-Path -LiteralPath $verFile) { $current = (Get-Content -LiteralPath $verFile -TotalCount 1).Trim() }

if ($FromZip) {
    if (-not (Test-Path -LiteralPath $FromZip)) { Write-Host "No file $FromZip" -ForegroundColor Red; exit 1 }
    $latest = 'from ' + (Split-Path $FromZip -Leaf); $zipInfo = $null
} else {
Write-Host 'Checking GitHub for the newest Light Gun Edition release...'
try {
    $rel = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'hotd2re-updater' } `
        -Uri "https://api.github.com/repos/$Repo/releases/latest"
} catch {
    if ("$($_.Exception.Message)" -match '404') { Write-Host "No release has been published yet at github.com/$Repo/releases." -ForegroundColor Yellow; exit 1 }
    Write-Host "Couldn't reach GitHub: $($_.Exception.Message)" -ForegroundColor Red; exit 1
}
$latest = $rel.tag_name
$zipInfo = $rel.assets | Where-Object { $_.name -eq $asset } | Select-Object -First 1
if (-not $zipInfo) { Write-Host "The newest release ($latest) has no $asset." -ForegroundColor Red; exit 1 }

$shownCurrent = if ($current) { $current } else { 'unknown' }
Write-Host "This folder: $shownCurrent    Newest: $latest"
if ($current -eq $latest -and -not $Force) { Write-Host 'Already up to date.' -ForegroundColor Green; exit 0 }
if ($Check) { Write-Host 'An update is available. Run "Update HOTD2.bat" to install it.' -ForegroundColor Yellow; exit 0 }
}

if (Get-Process -Name 'hotd2', 'hotd2-outputs', 'hotd2-outputs64', 'Play HOTD2', 'LightgunSetup', '1 - Light Gun Setup' -ErrorAction SilentlyContinue) {
    Write-Host 'Close the game (and Light Gun Setup) first, then run the update again.' -ForegroundColor Yellow; exit 2
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("hotd2re-update-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $zip = Join-Path $tmp $asset
    if ($FromZip) { Copy-Item -LiteralPath $FromZip -Destination $zip } else {
    Write-Host ("Downloading {0} ({1:N0} MB)..." -f $latest, ($zipInfo.size / 1MB))
    Invoke-WebRequest -UseBasicParsing -Headers @{ 'User-Agent' = 'hotd2re-updater' } -Uri $zipInfo.browser_download_url -OutFile $zip
    if ((Get-Item $zip).Length -ne $zipInfo.size) { throw 'The download is incomplete. Try again.' }
    if ($zipInfo.digest -and $zipInfo.digest -match '^sha256:([0-9a-f]{64})$') {
        $hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($hash -ne $Matches[1]) { throw 'The download does not match GitHub''s checksum. Try again.' }
        Write-Host 'Checksum OK.'
    }
    }
    Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp 'x')
    $src = Join-Path $tmp 'x\hotd2re'
    if (-not (Test-Path -LiteralPath (Join-Path $src 'hotd2-outputs64.exe'))) { throw 'The zip does not look like a Light Gun Edition package.' }

    $backup = Join-Path $root ('backup\' + (Get-Date -Format 'yyyy-MM-dd_HHmm'))
    $copied = 0; $backedUp = 0; $skipped = 0
    foreach ($f in Get-ChildItem -LiteralPath $src -Recurse -File) {
        $rel = $f.FullName.Substring($src.Length + 1)
        $dst = Join-Path $root $rel
        $rel = $rel -replace '/', '\'
        if (Is-Kept $rel) { $skipped++; continue }
        if (Test-Path -LiteralPath $dst) {
            if ((Get-FileHash -LiteralPath $dst).Hash -eq (Get-FileHash -LiteralPath $f.FullName).Hash) { continue }
            # A text/config file that differs may be your edit: keep a copy (exes and DLLs are just replaced).
            if ($rel -match '\.(ini|txt|bat|ahk|ps1|png)$' -and $rel -ne 'VERSION.txt' -and $rel -ne 'BUILD-OUTPUTS.txt') {
                $b = Join-Path $backup $rel
                New-Item -ItemType Directory -Force -Path (Split-Path $b) | Out-Null
                Copy-Item -LiteralPath $dst -Destination $b -Force; $backedUp++
            }
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        }
        Copy-Item -LiteralPath $f.FullName -Destination $dst -Force; $copied++
    }
    # Files earlier releases had that are now gone or moved.
    foreach ($old in 'Hook of the Reaper\defaultLG\hod2re - notes.txt', 'Hook of the Reaper\hod2re - notes.txt') {
        $o = Join-Path $root $old
        if (Test-Path -LiteralPath $o) { Remove-Item -LiteralPath $o -Force -ErrorAction SilentlyContinue }
    }
    # Fill in any of your own files that don't exist yet from defaults\.
    foreach ($n in 'LightgunHID.ini', 'Play HOTD2.ini') {
        $d = Join-Path $root "defaults\$n"
        if (-not (Test-Path -LiteralPath (Join-Path $root $n)) -and (Test-Path -LiteralPath $d)) { Copy-Item -LiteralPath $d -Destination (Join-Path $root $n) }
    }
    $ver = Join-Path $src 'VERSION.txt'
    $now = if (Test-Path -LiteralPath $ver) { (Get-Content -LiteralPath $ver -TotalCount 1).Trim() } else { $latest }
    Write-Host "Updated to $now ($copied files replaced, your settings kept)." -ForegroundColor Green
    if ($backedUp) { Write-Host "$backedUp changed file(s) were saved to $backup first." -ForegroundColor Yellow }
} catch {
    Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Nothing was changed if the download or the check failed.'
    exit 1
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
