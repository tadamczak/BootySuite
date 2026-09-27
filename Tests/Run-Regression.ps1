$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cases = @(
    @{ File = 'Tests/LootRulesRegression.lua'; Marker = 'Loot rules regression scenarios passed' },
    @{ File = 'Tests/ReyCoinRegression.lua'; Marker = 'ReyCoin service regression scenarios passed' },
    @{ File = 'Tests/LootEventsRegression.lua'; Marker = 'Loot event service regression scenarios passed' },
    @{ File = 'Tests/MasterLootWindowRegression.lua'; Marker = 'Master Loot window regression scenarios passed' }
    @{ File = 'Tests/SoftReserveWarningsRegression.lua'; Marker = 'Soft Reserve warning regression scenarios passed' }
)

Push-Location $root
try {
    foreach ($case in $cases) {
        $output = & npm exec --yes --package=fengari-node-cli -- fengari -e 'table.getn = function(t) return #t end; string.gfind = string.gmatch' $case.File 2>&1
        $text = ($output | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $text -notmatch [regex]::Escape($case.Marker) -or $text -match 'stack traceback') {
            throw "Regression failed: $($case.File)`n$text"
        }
        Write-Output $case.Marker
    }
} finally {
    Pop-Location
}
