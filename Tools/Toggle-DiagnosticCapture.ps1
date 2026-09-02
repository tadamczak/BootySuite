[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$captureRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\Screenshots"))
$framesDirectory = Join-Path $captureRoot "recording-frames"
$activePath = Join-Path $captureRoot "recording-active.txt"
$stopPath = Join-Path $captureRoot "recording-stop.flag"
$completePath = Join-Path $captureRoot "recording-complete.txt"
$errorPath = Join-Path $captureRoot "recording-error.txt"

if (-not (Test-Path -LiteralPath $framesDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $framesDirectory -Force | Out-Null
}

if (Test-Path -LiteralPath $activePath -PathType Leaf) {
    Set-Content -LiteralPath $stopPath -Value ([DateTime]::UtcNow.ToString("o")) -Encoding ASCII
    exit 0
}

Get-ChildItem -LiteralPath $framesDirectory -Filter "frame-*.jpg" -File -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item -LiteralPath $stopPath, $completePath, $errorPath -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

try {
    $screen = [System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.Left } -Descending | Select-Object -First 1
    $bounds = $screen.Bounds
    "PID=$PID`r`nBounds=$($bounds.Left),$($bounds.Top),$($bounds.Width),$($bounds.Height)`r`nStarted=$([DateTime]::UtcNow.ToString('o'))" |
        Set-Content -LiteralPath $activePath -Encoding ASCII

    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
    $quality = New-Object System.Drawing.Imaging.EncoderParameters 1
    $quality.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]72)
    $frameIndex = 0

    while (-not (Test-Path -LiteralPath $stopPath -PathType Leaf) -and $frameIndex -lt 900) {
        $frameIndex++
        $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bounds.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
            $framePath = Join-Path $framesDirectory ("frame-{0:D4}.jpg" -f $frameIndex)
            $bitmap.Save($framePath, $jpegCodec, $quality)
        } finally {
            $graphics.Dispose()
            $bitmap.Dispose()
        }
        Start-Sleep -Milliseconds 350
    }

    "Frames=$frameIndex`r`nCompleted=$([DateTime]::UtcNow.ToString('o'))" | Set-Content -LiteralPath $completePath -Encoding ASCII
} catch {
    $_.Exception.ToString() | Set-Content -LiteralPath $errorPath -Encoding UTF8
    exit 1
} finally {
    Remove-Item -LiteralPath $activePath, $stopPath -Force -ErrorAction SilentlyContinue
}
