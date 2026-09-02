[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$captureRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\Screenshots"))
$framesDirectory = Join-Path $captureRoot "recording-frames"
$startPath = Join-Path $captureRoot "capture-start.flag"
$stopPath = Join-Path $captureRoot "capture-stop.flag"
$exitPath = Join-Path $captureRoot "capture-service-exit.flag"
$readyPath = Join-Path $captureRoot "capture-service-ready.txt"
$activePath = Join-Path $captureRoot "recording-active.txt"
$completePath = Join-Path $captureRoot "recording-complete.txt"
$errorPath = Join-Path $captureRoot "recording-error.txt"

New-Item -ItemType Directory -Path $framesDirectory -Force | Out-Null
Remove-Item -LiteralPath $startPath, $stopPath, $exitPath, $activePath, $errorPath -Force -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" } | Select-Object -First 1
$quality = New-Object System.Drawing.Imaging.EncoderParameters 1
$quality.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), ([long]72)
$recording = $false
$frameIndex = 0
$bounds = $null
"PID=$PID`r`nReady=$([DateTime]::UtcNow.ToString('o'))" | Set-Content -LiteralPath $readyPath -Encoding ASCII

try {
    while (-not (Test-Path -LiteralPath $exitPath -PathType Leaf)) {
        if (-not $recording -and (Test-Path -LiteralPath $startPath -PathType Leaf)) {
            Get-ChildItem -LiteralPath $framesDirectory -Filter "frame-*.jpg" -File -ErrorAction SilentlyContinue | Remove-Item -Force
            Remove-Item -LiteralPath $startPath, $stopPath, $completePath, $errorPath -Force -ErrorAction SilentlyContinue
            $screen = [System.Windows.Forms.Screen]::AllScreens | Sort-Object { $_.Bounds.Left } -Descending | Select-Object -First 1
            $bounds = $screen.Bounds
            $frameIndex = 0
            $recording = $true
            "Bounds=$($bounds.Left),$($bounds.Top),$($bounds.Width),$($bounds.Height)`r`nStarted=$([DateTime]::UtcNow.ToString('o'))" | Set-Content -LiteralPath $activePath -Encoding ASCII
        }

        if ($recording -and ((Test-Path -LiteralPath $stopPath -PathType Leaf) -or $frameIndex -ge 900)) {
            $recording = $false
            Remove-Item -LiteralPath $activePath, $stopPath -Force -ErrorAction SilentlyContinue
            "Frames=$frameIndex`r`nCompleted=$([DateTime]::UtcNow.ToString('o'))" | Set-Content -LiteralPath $completePath -Encoding ASCII
        }

        if ($recording) {
            $frameIndex++
            $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bounds.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
                $framePath = Join-Path $framesDirectory ("frame-{0:D4}.jpg" -f $frameIndex)
                $bitmap.Save($framePath, $jpegCodec, $quality)
            } finally {
                $graphics.Dispose(); $bitmap.Dispose()
            }
            Start-Sleep -Milliseconds 350
        } else {
            Start-Sleep -Milliseconds 200
        }
    }
} catch {
    $_.Exception.ToString() | Set-Content -LiteralPath $errorPath -Encoding UTF8
} finally {
    Remove-Item -LiteralPath $readyPath, $activePath, $startPath, $stopPath, $exitPath -Force -ErrorAction SilentlyContinue
}
