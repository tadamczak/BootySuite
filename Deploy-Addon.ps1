[CmdletBinding()]
param()

$sourceDirectory = Join-Path $PSScriptRoot "MuklaOfficerSuite"
$gameDirectory = "C:\Gry\OctoWoWPvP"
$addonRoot = Join-Path $gameDirectory "Interface\AddOns"
$targetDirectory = Join-Path $addonRoot "MuklaOfficerSuite"

if (-not (Test-Path -LiteralPath $gameDirectory -PathType Container)) {
    throw "Game directory not found: $gameDirectory"
}

if (-not (Test-Path -LiteralPath $addonRoot -PathType Container)) {
    throw "WoW addon directory not found: $addonRoot"
}

if (-not (Test-Path -LiteralPath $targetDirectory)) {
    New-Item -ItemType Directory -Path $targetDirectory | Out-Null
}

foreach ($sourceFile in Get-ChildItem -LiteralPath $sourceDirectory -Recurse -File) {
    $relativePath = $sourceFile.FullName.Substring($sourceDirectory.Length).TrimStart('\')
    $targetPath = Join-Path $targetDirectory $relativePath
    $targetParent = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent | Out-Null
    }
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force
}

Write-Host "Mukla Officer Suite deployed to:"
Write-Host $targetDirectory
