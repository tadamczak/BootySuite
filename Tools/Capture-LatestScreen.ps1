[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$captureDirectory = Join-Path $PSScriptRoot "..\Screenshots"
$captureDirectory = [System.IO.Path]::GetFullPath($captureDirectory)
$outputPath = Join-Path $captureDirectory "latest-screen.png"
$temporaryPath = Join-Path $captureDirectory "latest-screen.tmp.png"
$errorPath = Join-Path $captureDirectory "capture-error.txt"

if (-not (Test-Path -LiteralPath $captureDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $captureDirectory | Out-Null
}

try {
    $cursorPosition = [System.Windows.Forms.Cursor]::Position
    $screen = [System.Windows.Forms.Screen]::FromPoint($cursorPosition)
    $bounds = $screen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    try {
        $graphics.CopyFromScreen($bounds.Left, $bounds.Top, 0, 0, $bounds.Size, [System.Drawing.CopyPixelOperation]::SourceCopy)
        $bitmap.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    Move-Item -LiteralPath $temporaryPath -Destination $outputPath -Force
    Remove-Item -LiteralPath $errorPath -Force -ErrorAction SilentlyContinue
} catch {
    $details = "{0}`r`n{1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_.Exception.ToString()
    Set-Content -LiteralPath $errorPath -Value $details -Encoding UTF8
    exit 1
}
