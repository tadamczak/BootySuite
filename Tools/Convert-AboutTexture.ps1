[CmdletBinding()]
param(
    [string]$SourcePath = "C:\Users\tadam\Desktop\SoM web\dh.png",
    [string]$DestinationPath = (Join-Path $PSScriptRoot "..\MuklaOfficerSuite\Textures\AboutArtwork.tga")
)

Add-Type -AssemblyName System.Drawing
$size = 512
$source = [System.Drawing.Image]::FromFile($SourcePath)
$bitmap = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$scaledWidth = [int](($source.Width / $source.Height) * $size)
$x = [int](($size - $scaledWidth) / 2)
$graphics.DrawImage($source, $x, 0, $scaledWidth, $size)
$rectangle = New-Object System.Drawing.Rectangle 0, 0, $size, $size
$data = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb))
$bytes = New-Object byte[] ($data.Stride * $data.Height)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$bitmap.UnlockBits($data)
$stream = [System.IO.File]::Open($DestinationPath, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter $stream
$writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]2)
$writer.Write([byte[]](0, 0, 0, 0, 0)); $writer.Write([uint16]0); $writer.Write([uint16]0)
$writer.Write([uint16]$size); $writer.Write([uint16]$size); $writer.Write([byte]32); $writer.Write([byte]40)
$writer.Write($bytes)
$writer.Dispose(); $stream.Dispose(); $graphics.Dispose(); $bitmap.Dispose(); $source.Dispose()
Write-Host "WoW about texture created at: $DestinationPath"
