local memoryBeforeLoad = type(gcinfo) == "function" and gcinfo() or nil
MuklaOfficerSuite = MuklaOfficerSuite or CreateFrame("Frame", "MuklaOfficerSuiteEventFrame")

local MOS = MuklaOfficerSuite
MOS.Core = MOS.Core or {}
MOS.UI = MOS.UI or {}
MOS.UI.Components = MOS.UI.Components or {}
MOS.Modules = MOS.Modules or {}
MOS.Services = MOS.Services or {}
MOS.Diagnostics = MOS.Diagnostics or { startedAt = GetTime(), events = 0, uiRefreshes = 0, scans = 0 }
MOS.Diagnostics.memoryBeforeLoad = memoryBeforeLoad

function MOS.Diagnostics.Count(metric)
    MOS.Diagnostics[metric] = (tonumber(MOS.Diagnostics[metric]) or 0) + 1
end
