[CmdletBinding()]
param()

$sourceDirectory = Join-Path $PSScriptRoot "MuklaOfficerSuite"
$gameDirectory = "C:\Gry\OctoWoWPvP"
$addonRoot = Join-Path $gameDirectory "Interface\AddOns"
$targetDirectory = Join-Path $addonRoot "MuklaOfficerSuite"
$addonFiles = @(
    "MuklaOfficerSuite.toc",
    "MuklaOfficerSuite.lua"
)
$textureFiles = @(
    "DashboardBackground.tga"
)

if (-not (Test-Path -LiteralPath $gameDirectory -PathType Container)) {
    throw "Game directory not found: $gameDirectory"
}

if (-not (Test-Path -LiteralPath $addonRoot -PathType Container)) {
    throw "WoW addon directory not found: $addonRoot"
}

if (-not (Test-Path -LiteralPath $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory | Out-Null
}

foreach ($file in $addonFiles) {
    $sourcePath = Join-Path $sourceDirectory $file
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required addon file not found: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetDirectory -Force
}

$sourceTextureDirectory = Join-Path $sourceDirectory "Textures"
$targetTextureDirectory = Join-Path $targetDirectory "Textures"
if (-not (Test-Path -LiteralPath $targetTextureDirectory)) {
    New-Item -ItemType Directory -Path $targetTextureDirectory | Out-Null
}

foreach ($file in $textureFiles) {
    $sourcePath = Join-Path $sourceTextureDirectory $file
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Required addon texture not found: $sourcePath"
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetTextureDirectory -Force
}

Write-Host "Mukla Officer Suite deployed to:"
Write-Host $targetDirectory
