# Draws a bezel image over the black side bars while HOTD2 runs in 4:3 mode.
# Two borderless, click-through, always-on-top windows cover only the left and right bars,
# so nothing is drawn over the game picture and gun/mouse clicks pass straight through.
# Closes itself when hotd2.exe exits. Needs nothing installed beyond Windows PowerShell.
param(
    [Parameter(Mandatory = $true)][string]$Bezel,
    [string]$ProcessName = 'hotd2',
    [int]$WaitSeconds = 60
)

$ErrorActionPreference = 'Stop'

Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public static class Native {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool SetLayeredWindowAttributes(IntPtr h, uint key, byte alpha, uint flags);
    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public const uint SWP_NOSIZE = 0x1, SWP_NOMOVE = 0x2, SWP_NOACTIVATE = 0x10;
}

public class BezelForm : Form {
    public BezelForm(Rectangle bounds, Image img) {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        Bounds = bounds;
        BackColor = Color.Black;
        BackgroundImage = img;
        BackgroundImageLayout = ImageLayout.Stretch;
        TopMost = true;
    }
    // Never take focus away from the game.
    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            // LAYERED | TRANSPARENT = click-through, TOOLWINDOW = hidden from Alt-Tab, NOACTIVATE
            cp.ExStyle |= 0x80000 | 0x20 | 0x80 | 0x08000000 | 0x8;
            return cp;
        }
    }
    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        Native.SetLayeredWindowAttributes(Handle, 0, 255, 0x2);
    }
    public void KeepOnTop() {
        Native.SetWindowPos(Handle, Native.HWND_TOPMOST, 0, 0, 0, 0,
            Native.SWP_NOSIZE | Native.SWP_NOMOVE | Native.SWP_NOACTIVATE);
    }
}
"@

# Real pixel coordinates on scaled (125%/150%) displays.
[Native]::SetProcessDPIAware() | Out-Null

if (-not (Test-Path -LiteralPath $Bezel)) { exit 0 }

# Wait for the game and its window.
$proc = $null
$deadline = (Get-Date).AddSeconds($WaitSeconds)
while ((Get-Date) -lt $deadline) {
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
    if ($proc) { break }
    Start-Sleep -Milliseconds 250
}
if (-not $proc) { exit 0 }
Start-Sleep -Milliseconds 1500   # let the game finish switching to fullscreen

# Monitor the game is on, and where the 4:3 picture sits on it.
$screen = [System.Windows.Forms.Screen]::FromHandle($proc.MainWindowHandle).Bounds
$gameW  = [int][Math]::Round($screen.Height * 4.0 / 3.0)
$barW   = [int][Math]::Floor(($screen.Width - $gameW) / 2.0)
if ($barW -le 0) { exit 0 }   # screen is 4:3 or narrower: no bars to fill

# Scale the bezel to the full screen, then cut out the two side strips.
$src  = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $Bezel).Path)
$full = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
$g = [System.Drawing.Graphics]::FromImage($full)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.Clear([System.Drawing.Color]::Black)
$g.DrawImage($src, 0, 0, $screen.Width, $screen.Height)
$g.Dispose(); $src.Dispose()

$leftRect  = New-Object System.Drawing.Rectangle 0, 0, $barW, $screen.Height
$rightRect = New-Object System.Drawing.Rectangle ($screen.Width - $barW), 0, $barW, $screen.Height
$leftImg   = $full.Clone($leftRect,  $full.PixelFormat)
$rightImg  = $full.Clone($rightRect, $full.PixelFormat)
$full.Dispose()

$left  = [BezelForm]::new([System.Drawing.Rectangle]::new($screen.X, $screen.Y, $barW, $screen.Height), $leftImg)
$right = [BezelForm]::new([System.Drawing.Rectangle]::new($screen.X + $screen.Width - $barW, $screen.Y, $barW, $screen.Height), $rightImg)
$left.Show(); $right.Show()

# Stay above the game; quit when the game closes.
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $proc.Refresh()
    if ($proc.HasExited) {
        $timer.Stop(); $left.Close(); $right.Close()
        [System.Windows.Forms.Application]::ExitThread()
        return
    }
    $left.KeepOnTop(); $right.KeepOnTop()
})
$timer.Start()
$left.KeepOnTop(); $right.KeepOnTop()

[System.Windows.Forms.Application]::Run()
