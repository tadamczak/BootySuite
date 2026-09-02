[CmdletBinding()]
param(
    [string]$InputPath,
    [string]$OutputPath
)

$gameDirectory = "C:\Gry\OctoWoWPvP"
$savedVariablesRoot = Join-Path $gameDirectory "WTF\Account"

function ConvertFrom-LuaString {
    param([string]$Value)
    $content = $Value.Trim()
    if ($content.Length -lt 2 -or $content[0] -ne '"') { return $content }
    $content = $content.Substring(1, $content.Length - 2)
    $result = New-Object System.Text.StringBuilder
    for ($index = 0; $index -lt $content.Length; $index++) {
        if ($content[$index] -ne '\') {
            [void]$result.Append($content[$index])
            continue
        }
        $index++
        if ($index -ge $content.Length) { break }
        $escaped = $content[$index]
        if ($escaped -eq 'n') { [void]$result.Append("`n") }
        elseif ($escaped -eq 'r') { [void]$result.Append("`r") }
        elseif ($escaped -eq 't') { [void]$result.Append("`t") }
        else { [void]$result.Append($escaped) }
    }
    return $result.ToString()
}

function ConvertFrom-LuaValue {
    param([string]$Value)
    $value = $Value.Trim()
    if ($value.StartsWith('"')) { return ConvertFrom-LuaString $value }
    if ($value -eq 'true') { return $true }
    if ($value -eq 'false') { return $false }
    if ($value -match '^-?\d+$') { return [int]$value }
    return $value
}

if (-not $InputPath) {
    $latest = Get-ChildItem -LiteralPath $savedVariablesRoot -Filter "MuklaOfficerSuite.lua" -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $latest) { throw "MuklaOfficerSuite.lua was not found under: $savedVariablesRoot" }
    $InputPath = $latest.FullName
}

$InputPath = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path
$records = New-Object System.Collections.Generic.List[object]
$inAttendance = $false
$attendanceIndent = -1
$inRaidMembers = $false
$arrayIndent = -1
$recordIndent = -1
$current = $null

foreach ($line in (Get-Content -LiteralPath $InputPath)) {
    if (-not $inAttendance -and $line -match '^(\s*)\["raidAttendance"\]\s*=\s*\{$') {
        $inAttendance = $true
        $attendanceIndent = $matches[1].Length
        continue
    }
    if (-not $inAttendance) { continue }
    if (-not $inRaidMembers -and $line -match '^(\s*)\},?\s*$' -and $matches[1].Length -eq $attendanceIndent) {
        $inAttendance = $false
        $attendanceIndent = -1
        continue
    }
    if (-not $inRaidMembers -and $line -match '^(\s*)\["members"\]\s*=\s*\{$') {
        $inRaidMembers = $true
        $arrayIndent = $matches[1].Length
        continue
    }
    if (-not $inRaidMembers) { continue }
    if (-not $current -and $line -match '^(\s*)\[\d+\]\s*=\s*\{$') {
        $recordIndent = $matches[1].Length
        $current = @{}
        continue
    }
    if ($current -and $line -match '^\s*\["([^"]+)"\]\s*=\s*(.*),$') {
        $current[$matches[1]] = ConvertFrom-LuaValue $matches[2]
        continue
    }
    if ($line -match '^(\s*)\},?\s*$') {
        $closingIndent = $matches[1].Length
        if ($current -and $closingIndent -eq $recordIndent) {
            $records.Add([pscustomobject][ordered]@{
                Name = $current.name
                RaidGroup = $current.subgroup
                Class = $current.class
                GuildMember = $current.guildMember
                GuildRank = $current.guildRank
                PublicNote = $current.publicNote
                OfficerNote = $current.officerNote
                SR = $current.sr
            })
            $current = $null
            $recordIndent = -1
        } elseif (-not $current -and $closingIndent -eq $arrayIndent) {
            $inRaidMembers = $false
        }
    }
}

if ($records.Count -eq 0) { throw "No raid attendance members were found in: $InputPath" }
if (-not $OutputPath) {
    $exportDirectory = Join-Path $PSScriptRoot "exports"
    if (-not (Test-Path -LiteralPath $exportDirectory)) { New-Item -ItemType Directory -Path $exportDirectory | Out-Null }
    $OutputPath = Join-Path $exportDirectory ("MuklaOfficerSuiteAttendance-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
}
$records | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Exported $($records.Count) raid attendance members to:"
Write-Host $OutputPath
