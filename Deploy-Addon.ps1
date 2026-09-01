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

Write-Host "Mukla Officer Suite deployed to:"
Write-Host $targetDirectory
