[CmdletBinding()]
param(
    [string]$InputPath,
    [string]$OutputPath
)

if (-not $OutputPath) {
    $exportDirectory = Join-Path $PSScriptRoot "exports"
    if (-not (Test-Path -LiteralPath $exportDirectory)) {
        New-Item -ItemType Directory -Path $exportDirectory | Out-Null
    }
    $OutputPath = Join-Path $exportDirectory ("MuklaOfficerSuiteAttendance-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
}

$arguments = @{ OutputPath = $OutputPath }
if ($InputPath) { $arguments.InputPath = $InputPath }
& (Join-Path $PSScriptRoot "Export-CSR.ps1") @arguments
