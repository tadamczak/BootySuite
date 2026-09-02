[CmdletBinding()]
param(
    [string]$SourcePath = "C:\Users\tadam\Desktop\SoM web\374808.jpg",
    [string]$DestinationPath = (Join-Path $PSScriptRoot "..\MuklaOfficerSuite\Textures\DashboardBackground.tga")
)

Add-Type -AssemblyName System.Drawing

$textureSize = 512
$contentHeight = 320
$source = [System.Drawing.Image]::FromFile($SourcePath)
$bitmap = New-Object System.Drawing.Bitmap $textureSize, $textureSize, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$graphics.DrawImage($source, 0, 0, $textureSize, $contentHeight)

$destinationDirectory = Split-Path -Parent $DestinationPath
if (-not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}

$rectangle = New-Object System.Drawing.Rectangle 0, 0, $textureSize, $textureSize
$data = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$pixelBytes = New-Object byte[] ($data.Stride * $data.Height)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $pixelBytes, 0, $pixelBytes.Length)
$bitmap.UnlockBits($data)

$stream = [System.IO.File]::Open($DestinationPath, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter $stream
$writer.Write([byte]0)
$writer.Write([byte]0)
$writer.Write([byte]2)
$writer.Write([byte[]](0, 0, 0, 0, 0))
$writer.Write([uint16]0)
$writer.Write([uint16]0)
$writer.Write([uint16]$textureSize)
$writer.Write([uint16]$textureSize)
$writer.Write([byte]32)
$writer.Write([byte]40)
$writer.Write($pixelBytes)
$writer.Dispose()
$stream.Dispose()
$graphics.Dispose()
$bitmap.Dispose()
$source.Dispose()

Write-Host "WoW texture created at:"
Write-Host $DestinationPath
