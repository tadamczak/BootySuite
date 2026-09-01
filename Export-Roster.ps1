[CmdletBinding()]
param(
    [string]$InputPath,
    [string]$OutputPath
)

$gameDirectory = "C:\Gry\OctoWoWPvP"
$savedVariablesRoot = Join-Path $gameDirectory "WTF\Account"

function ConvertFrom-LuaString {
    param([string]$Value)

    if ($Value.Length -lt 2 -or $Value[0] -ne '"' -or $Value[$Value.Length - 1] -ne '"') {
        return $Value
    }

    $content = $Value.Substring(1, $Value.Length - 2)
    $result = New-Object System.Text.StringBuilder
    $index = 0

    while ($index -lt $content.Length) {
        $character = $content[$index]
        if ($character -ne '\') {
            [void]$result.Append($character)
            $index++
            continue
        }

        $index++
        if ($index -ge $content.Length) {
            [void]$result.Append('\')
            break
        }

        $escaped = $content[$index]
        if ($escaped -eq 'n') {
            [void]$result.Append("`n")
        } elseif ($escaped -eq 'r') {
            [void]$result.Append("`r")
        } elseif ($escaped -eq 't') {
            [void]$result.Append("`t")
        } elseif ($escaped -eq '"') {
            [void]$result.Append('"')
        } elseif ($escaped -eq '\') {
            [void]$result.Append('\')
        } elseif ([char]::IsDigit($escaped)) {
            $digits = [string]$escaped
            $digitCount = 1
            while ($digitCount -lt 3 -and $index + 1 -lt $content.Length -and [char]::IsDigit($content[$index + 1])) {
                $index++
                $digits += $content[$index]
                $digitCount++
            }
            [void]$result.Append([char][int]$digits)
        } else {
            [void]$result.Append($escaped)
        }
        $index++
    }

    return $result.ToString()
}

function ConvertFrom-LuaValue {
    param([string]$Value)

    $trimmed = $Value.Trim()
    if ($trimmed.StartsWith('"')) {
        return ConvertFrom-LuaString $trimmed
    }
    if ($trimmed -eq "true") {
        return $true
    }
    if ($trimmed -eq "false") {
        return $false
    }
    if ($trimmed -match "^-?\d+$") {
        return [int]$trimmed
    }
    return $trimmed
}

if (-not $InputPath) {
    if (-not (Test-Path -LiteralPath $savedVariablesRoot -PathType Container)) {
        throw "SavedVariables root not found: $savedVariablesRoot"
    }

    $latestSavedVariables = Get-ChildItem -LiteralPath $savedVariablesRoot -Filter "MuklaOfficerSuite.lua" -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latestSavedVariables) {
        throw "MuklaOfficerSuite.lua was not found under: $savedVariablesRoot"
    }
    $InputPath = $latestSavedVariables.FullName
}

$InputPath = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path
$lines = Get-Content -LiteralPath $InputPath
$records = New-Object System.Collections.Generic.List[object]
$inMembers = $false
$membersIndent = -1
$memberIndent = -1
$currentGuild = ""
$currentMember = $null

for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
    $line = $lines[$lineIndex]

    if (-not $inMembers -and $line -match '^(\s*)\["members"\]\s*=\s*\{$') {
        $inMembers = $true
        $membersIndent = $matches[1].Length
        $currentGuild = ""

        for ($searchIndex = $lineIndex - 1; $searchIndex -ge 0; $searchIndex--) {
            if ($lines[$searchIndex] -match '^(\s*)\["((?:\\.|[^"])*)"\]\s*=\s*\{$') {
                if ($matches[1].Length -lt $membersIndent -and $matches[2] -ne "guilds") {
                    $currentGuild = ConvertFrom-LuaString ('"' + $matches[2] + '"')
                    break
                }
            }
        }
        continue
    }

    if (-not $inMembers) {
        continue
    }

    if (-not $currentMember -and $line -match '^(\s*)\[\d+\]\s*=\s*\{$') {
        $memberIndent = $matches[1].Length
        $currentMember = @{}
        continue
    }

    if ($currentMember -and $line -match '^\s*\["([^"]+)"\]\s*=\s*(.*),$') {
        $currentMember[$matches[1]] = ConvertFrom-LuaValue $matches[2]
        continue
    }

    if ($line -match '^(\s*)\},?\s*$') {
        $closingIndent = $matches[1].Length
        if ($currentMember -and $closingIndent -eq $memberIndent) {
            $records.Add([pscustomobject][ordered]@{
                Guild       = $currentGuild
                Name        = $currentMember.name
                Level       = $currentMember.level
                Class       = $currentMember.class
                Rank        = $currentMember.rank
                RankIndex   = $currentMember.rankIndex
                PublicNote  = $currentMember.publicNote
                OfficerNote = $currentMember.officerNote
                Online      = $currentMember.online
                Zone        = $currentMember.zone
                Status      = $currentMember.status
            })
            $currentMember = $null
            $memberIndent = -1
        } elseif (-not $currentMember -and $closingIndent -eq $membersIndent) {
            $inMembers = $false
            $membersIndent = -1
            $currentGuild = ""
        }
    }
}

if ($records.Count -eq 0) {
    throw "No guild members were found in: $InputPath"
}

if (-not $OutputPath) {
    $exportDirectory = Join-Path $PSScriptRoot "exports"
    if (-not (Test-Path -LiteralPath $exportDirectory)) {
        New-Item -ItemType Directory -Path $exportDirectory | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $exportDirectory "MuklaOfficerSuiteRoster-$timestamp.csv"
} else {
    $outputDirectory = Split-Path -Parent $OutputPath
    if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }
}

$records | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported $($records.Count) guild members to:"
Write-Host $OutputPath
