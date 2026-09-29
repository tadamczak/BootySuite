local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
MOS.Modules.Performance = MOS.Modules.Performance or {}
local Performance = MOS.Modules.Performance

local function Memory(value)
    value = tonumber(value)
    if not value then return "Unavailable" end
    if value >= 1024 then return string.format("%.2f MB", value / 1024) end
    return string.format("%.1f KB", value)
end

local function Duration(value)
    value = tonumber(value) or 0
    if value >= 1 then return string.format("%.2f s", value) end
    return string.format("%.2f ms", value * 1000)
end

local function LootCount()
    local attendance = MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.raidAttendance
    if not attendance or not attendance.members then return 0 end
    local count, index = 0, 1
    for index = 1, table.getn(attendance.members) do
        local loot = attendance.members[index].loot
        if loot then count = count + table.getn(loot) end
    end
    return count
end

local function CompareOperationTime(a, b)
    return (a.time or 0) > (b.time or 0)
end

local function CompareAddonMemory(a, b)
    return (a.memory or 0) > (b.memory or 0)
end

function Performance.Create(parent)
    local page = MOS.UI.Components.CreateContainer(nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3); page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 3); page:Hide()
    page.title = MOS.UI.Components.CreateHeading(page, "", 1, "gold")
    page.title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10); page.title:SetText("Performance")
    page.description = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlightSmall")
    page.description:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -48)
    page.description:SetText("Lightweight diagnostics sampled only while Performance or Live Monitor is visible.")

    local function Section(title, y)
        local heading = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
        heading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, y); heading:SetText(title)
        local rule = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
        rule:SetPoint("LEFT", heading, "RIGHT", 10, 0); rule:SetPoint("RIGHT", page, "RIGHT", -12, 0)
        rule:SetHeight(1); rule:SetTexture(0.55, 0.42, 0.16, 0.75)
        return heading, rule
    end
    page.addonHeading, page.addonRule = Section("Mukla Officer Suite", -76)
    page.globalHeading, page.globalRule = Section("Game and all addons", -286)

    local names = { "Tracked allocations", "Measured calls", "Measured runtime", "Average call time", "Largest allocation", "Slowest operation", "MOS events / sec", "UI refreshes / sec", "Scans this session", "Last roster scan", "Saved roster members", "Raid members / loot", "Current Lua memory", "GC threshold", "Memory rate", "Last allocation peak", "Last cleanup", "Current FPS / frame", "Network latency" }
    local tips = {
        "Temporary memory allocated during the Mukla Officer Suite operations measured by this profiler. This does not include other addons.",
        "Calls measured inside selected Mukla Officer Suite operations. Click to open the operation profiler.",
        "Total execution time of measured Mukla Officer Suite operations.",
        "Average execution time of one measured Mukla Officer Suite operation.",
        "Largest positive allocation observed during one measured operation.",
        "Measured Mukla Officer Suite operation with the longest single execution.",
        "Average number of game events handled by Mukla Officer Suite per second.",
        "Average number of major Mukla Officer Suite page redraws per second.",
        "Guild and raid scans performed since login or reload.",
        "Time required to create the latest saved guild roster snapshot.",
        "Roster records retained in SavedVariables.", "Raid members and loot entries retained in the attendance snapshot.",
        "Memory used by the complete Lua interface, including every addon.", "Lua garbage collector threshold reported by this client.",
        "Change in total Lua memory during the last second.", "Largest short allocation increase observed since reset.",
        "Time since the sampler observed garbage collection reducing Lua memory.", "Frames per second and approximate duration of one frame.",
        "Round-trip network delay reported by the client."
    }
    page.labels, page.values, page.targets = {}, {}, {}
    local index
    for index = 1, table.getn(names) do
        local x, y
        if index <= 12 then
            local column = index > 6 and 1 or 0; local row = column == 1 and index - 7 or index - 1
            x, y = 12 + column * 300, -102 - row * 28
        else
            local localIndex = index - 13; local column = localIndex > 3 and 1 or 0; local row = column == 1 and localIndex - 4 or localIndex
            x, y = 12 + column * 300, -312 - row * 28
        end
        local label = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", page, "TOPLEFT", x, y); label:SetWidth(166); label:SetJustifyH("LEFT"); label:SetText(names[index]); label:SetTextColor(0.82, 0.82, 0.78)
        if label.SetWordWrap then label:SetWordWrap(false) end
        local value = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlight")
        value:SetPoint("TOPLEFT", page, "TOPLEFT", x + 170, y); value:SetWidth(120); value:SetJustifyH("LEFT"); value:SetText("-")
        if value.SetWordWrap then value:SetWordWrap(false) end
        local target = MOS.UI.Components.CreateControl(nil, page)
        target:SetPoint("TOPLEFT", page, "TOPLEFT", x, y + 4); target:SetWidth(286); target:SetHeight(22); UI.AttachTooltip(target, names[index], tips[index])
        page.labels[index], page.values[index], page.targets[index] = label, value, target
    end
    page.labels[2]:SetText("Measured calls  <>")
    page.labels[13]:SetText("Current Lua memory  <>")

    page.resetButton = UI.CreateButton(page, nil, "Reset measurements", 145, 22)
    page.resetButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -10)
    UI.AttachTooltip(page.resetButton, "Reset measurements", "Clear memory peaks, cleanup history, and measured Mukla Officer Suite operations.")
    page.monitorButton = UI.CreateButton(page, nil, "Open Live Monitor", 145, 22)
    page.monitorButton:SetPoint("RIGHT", page.resetButton, "LEFT", -8, 0)
    UI.AttachTooltip(page.monitorButton, "Live Monitor", "Toggle a compact movable window with the most useful live values.")
    page.diagnosticButton = UI.CreateButton(page, nil, "Start diagnosis", 130, 22)
    page.diagnosticButton:SetPoint("RIGHT", page.monitorButton, "LEFT", -8, 0)
    UI.AttachTooltip(page.diagnosticButton, "Performance diagnosis", "Record performance while you reproduce a problem, then stop to see potential issues and recommendations.")

    local module = { frame = page, sampler = {}, estimatedBaseline = MOS.Diagnostics.initialMemoryEstimate, estimatedAtLoad = MOS.Diagnostics.totalMemoryAfterLoad }
    local sampler = module.sampler
    sampler.frame = MOS.UI.Components.CreateContainer(nil, UIParent); sampler.frame:Hide()

    local detail = MOS.UI.Components.CreateContainer(nil, UIParent)
    detail:SetPoint("CENTER", UIParent, "CENTER", 220, 80); detail:SetWidth(410); detail:SetHeight(286)
    detail:SetFrameStrata("FULLSCREEN_DIALOG"); detail:SetFrameLevel(210); detail:SetMovable(true); detail:EnableMouse(true); detail:RegisterForDrag("LeftButton")
    if detail.SetClampedToScreen then detail:SetClampedToScreen(true) end
    detail:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } }); detail:SetBackdropColor(0.025, 0.025, 0.022, 1); MOS.UI.Components.RegisterDialogSurface(detail, "panel")
    detail.title = MOS.UI.Components.CreateLabel(detail, nil, "OVERLAY", "GameFontNormal"); detail.title:SetPoint("TOPLEFT", detail, "TOPLEFT", 14, -13); detail.title:SetText("MOS operation profiler")
    detail:SetScript("OnDragStart", function() this:StartMoving() end); detail:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    detail.close = MOS.UI.Components.CreateWindowButton(detail, nil, "close"); detail.close:SetPoint("TOPRIGHT", detail, "TOPRIGHT", -5, -5); detail.close:SetScript("OnClick", function() detail:Hide() end)
    detail.rows = {}
    for index = 1, 11 do
        detail.rows[index] = MOS.UI.Components.CreateLabel(detail, nil, "OVERLAY", "GameFontHighlightSmall")
        detail.rows[index]:SetPoint("TOPLEFT", detail, "TOPLEFT", 14, -42 - ((index - 1) * 20)); detail.rows[index]:SetWidth(360); detail.rows[index]:SetJustifyH("LEFT")
        if detail.rows[index].SetWordWrap then detail.rows[index]:SetWordWrap(false) end
    end
    detail:Hide()
    function module:RefreshDetail()
        if not detail:IsVisible() then return end
        local _, _, _, _, _, entries = module:GetSessionOperations()
        for index = 1, table.getn(detail.rows) do
            local entry = entries[index]
            if entry then detail.rows[index]:SetText(string.format("%s | %dx | %s | +%s", entry.name, entry.count or 0, Duration(entry.time), Memory(entry.memory))); detail.rows[index]:Show()
            else detail.rows[index]:SetText(index == 1 and "No measured operations yet." or ""); if index == 1 then detail.rows[index]:Show() else detail.rows[index]:Hide() end end
        end
    end
    page.targets[2]:SetScript("OnClick", function() if detail:IsVisible() then detail:Hide() else detail:Show(); module:RefreshDetail() end end)

    local addons = MOS.UI.Components.CreateContainer(nil, UIParent)
    addons:SetPoint("CENTER", UIParent, "CENTER", 250, 70); addons:SetWidth(390); addons:SetHeight(300)
    addons:SetFrameStrata("FULLSCREEN_DIALOG"); addons:SetFrameLevel(210); addons:SetMovable(true); addons:EnableMouse(true); addons:RegisterForDrag("LeftButton")
    if addons.SetClampedToScreen then addons:SetClampedToScreen(true) end
    addons:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } }); addons:SetBackdropColor(0.025, 0.025, 0.022, 1); MOS.UI.Components.RegisterDialogSurface(addons, "panel")
    addons:SetScript("OnDragStart", function() this:StartMoving() end); addons:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    addons.title = MOS.UI.Components.CreateLabel(addons, nil, "OVERLAY", "GameFontNormal"); addons.title:SetPoint("TOPLEFT", addons, "TOPLEFT", 14, -13); addons.title:SetText("Memory by addon")
    addons.close = MOS.UI.Components.CreateWindowButton(addons, nil, "close"); addons.close:SetPoint("TOPRIGHT", addons, "TOPRIGHT", -5, -5); addons.close:SetScript("OnClick", function() addons:Hide() end)
    addons.rows = {}
    for index = 1, 12 do addons.rows[index] = MOS.UI.Components.CreateLabel(addons, nil, "OVERLAY", "GameFontHighlightSmall"); addons.rows[index]:SetPoint("TOPLEFT", addons, "TOPLEFT", 16, -44 - ((index - 1) * 20)); addons.rows[index]:SetWidth(350); addons.rows[index]:SetJustifyH("LEFT") end
    addons:Hide(); module.addons = addons
    function module:RefreshAddons()
        if not addons:IsVisible() then return end
        local entries = self.addonEntries
        if not entries then entries = {}; self.addonEntries = entries end
        local entryCount = 0
        local apiAvailable = type(UpdateAddOnMemoryUsage) == "function" and type(GetAddOnMemoryUsage) == "function" and type(GetNumAddOns) == "function" and type(GetAddOnInfo) == "function"
        if apiAvailable then
            UpdateAddOnMemoryUsage()
            for index = 1, GetNumAddOns() do
                local name, title = GetAddOnInfo(index); local amount = tonumber(GetAddOnMemoryUsage(index))
                if amount and amount >= 0 then
                    entryCount = entryCount + 1
                    local entry = entries[entryCount]
                    if not entry then entry = {}; entries[entryCount] = entry end
                    entry.name = title or name or ("Addon " .. index)
                    entry.memory = amount
                    entry.unsupported = nil
                end
            end
        end
        local staleIndex
        for staleIndex = table.getn(entries), entryCount + 1, -1 do entries[staleIndex] = nil end
        if entryCount == 0 then
            local entry = entries[1]
            if not entry then entry = {}; entries[1] = entry end
            entry.name = nil; entry.memory = nil; entry.unsupported = true
            entryCount = 1
        else
            table.sort(entries, CompareAddonMemory)
        end
        for index = 1, table.getn(addons.rows) do
            local entry = entries[index]
            if entry then
                if entry.unsupported then
                    addons.rows[index]:SetText("Exact memory by addon is unavailable in this client.")
                else
                    addons.rows[index]:SetText(entry.name .. "  -  " .. Memory(entry.memory))
                end
                addons.rows[index]:Show()
            else
                addons.rows[index]:SetText("")
                addons.rows[index]:Hide()
            end
        end
    end
    page.targets[13]:SetScript("OnClick", function() if addons:IsVisible() then addons:Hide() else addons:Show(); module:RefreshAddons() end end)

    local report = MOS.UI.Components.CreateContainer(nil, UIParent)
    report:SetPoint("CENTER", UIParent, "CENTER", 0, 20); report:SetWidth(470); report:SetHeight(260); report:SetFrameStrata("FULLSCREEN_DIALOG"); report:SetFrameLevel(220)
    report:SetMovable(true); report:EnableMouse(true); report:RegisterForDrag("LeftButton")
    if report.SetClampedToScreen then report:SetClampedToScreen(true) end
    report:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } }); report:SetBackdropColor(0.025, 0.025, 0.022, 1); MOS.UI.Components.RegisterDialogSurface(report, "panel")
    report.title = MOS.UI.Components.CreateLabel(report, nil, "OVERLAY", "GameFontNormal"); report.title:SetPoint("TOPLEFT", report, "TOPLEFT", 14, -14); report.title:SetText("Performance diagnosis")
    report:SetScript("OnDragStart", function() this:StartMoving() end); report:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    report.close = MOS.UI.Components.CreateWindowButton(report, nil, "close"); report.close:SetPoint("TOPRIGHT", report, "TOPRIGHT", -5, -5); report.close:SetScript("OnClick", function() report:Hide() end)
    report.lines = {}
    for index = 1, 9 do report.lines[index] = MOS.UI.Components.CreateLabel(report, nil, "OVERLAY", "GameFontHighlightSmall"); report.lines[index]:SetPoint("TOPLEFT", report, "TOPLEFT", 16, -44 - ((index - 1) * 22)); report.lines[index]:SetWidth(435); report.lines[index]:SetJustifyH("LEFT") end
    report:Hide(); module.report = report

    local monitor = MOS.UI.Components.CreateContainer("MuklaOfficerSuiteLiveMonitor", UIParent)
    monitor:SetWidth(250); monitor:SetHeight(134); monitor:SetPoint("CENTER", UIParent, "CENTER", 300, 160); monitor:SetFrameStrata("FULLSCREEN_DIALOG"); monitor:SetFrameLevel(200); monitor:SetMovable(true); monitor:EnableMouse(true); monitor:RegisterForDrag("LeftButton")
    if monitor.SetClampedToScreen then monitor:SetClampedToScreen(true) end
    monitor:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } }); monitor:SetBackdropColor(0.02, 0.02, 0.018, 1); MOS.UI.Components.RegisterDialogSurface(monitor, "panel", { 0.02, 0.02, 0.018, 1 })
    monitor:SetScript("OnDragStart", function() this:StartMoving() end); monitor:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    monitor.title = MOS.UI.Components.CreateLabel(monitor, nil, "OVERLAY", "GameFontNormalSmall"); monitor.title:SetPoint("TOPLEFT", monitor, "TOPLEFT", 12, -11); monitor.title:SetText("Mukla Live Monitor")
    monitor.close = MOS.UI.Components.CreateWindowButton(monitor, nil, "close"); monitor.close:SetPoint("TOPRIGHT", monitor, "TOPRIGHT", -5, -5); monitor.close:SetScript("OnClick", function() monitor:Hide() end)
    monitor.minimize = UI.CreateButton(monitor, nil, "-", 22, 18); monitor.minimize:SetPoint("RIGHT", monitor.close, "LEFT", -2, 0)
    monitor.lines = {}
    for index = 1, 5 do monitor.lines[index] = MOS.UI.Components.CreateLabel(monitor, nil, "OVERLAY", "GameFontHighlightSmall"); monitor.lines[index]:SetPoint("TOPLEFT", monitor, "TOPLEFT", 12, -34 - ((index - 1) * 18)); monitor.lines[index]:SetWidth(225); monitor.lines[index]:SetJustifyH("LEFT") end
    local monitorTips = {
        { "Lua memory / GC threshold", "Current memory used by all Lua addons, followed by the level at which the client expects garbage collection." },
        { "Memory rate / allocation peak", "Memory change during the last second and the largest short allocation increase observed since reset." },
        { "FPS / frame time", "Frames rendered per second and the approximate duration of one frame. Higher FPS and lower frame time are better." },
        { "Network latency", "Round-trip network delay. It affects responsiveness but does not directly measure addon CPU cost." },
        { "Mukla Officer Suite operations", "Measured calls per second, followed by cumulative calls and total execution time since reset." },
    }
    monitor.targets = {}
    for index = 1, 5 do
        monitor.targets[index] = MOS.UI.Components.CreateControl(nil, monitor); monitor.targets[index]:SetPoint("TOPLEFT", monitor, "TOPLEFT", 9, -30 - ((index - 1) * 18)); monitor.targets[index]:SetWidth(230); monitor.targets[index]:SetHeight(18)
        UI.AttachTooltip(monitor.targets[index], monitorTips[index][1], monitorTips[index][2])
    end
    monitor.minimized = false; monitor:Hide(); module.monitor = monitor

    function module:ResetOperationBaseline()
        local calls, runtime, allocated, largest, slowest = MOS.Diagnostics.GetOperationTotals()
        self.operationBaseline = {
            totals = {
                calls = calls or 0,
                runtime = runtime or 0,
                allocated = allocated or 0,
            },
            entries = {},
            largest = largest or 0,
            slowest = slowest,
        }
        local operations = MOS.Diagnostics.operations or {}
        local name, operation = nil, nil
        for name, operation in pairs(operations) do
            self.operationBaseline.entries[name] = {
                count = operation.count or 0,
                time = operation.time or 0,
                memory = operation.memory or 0,
            }
        end
    end

    function module:GetSessionOperations()
        local calls, runtime, allocated = MOS.Diagnostics.GetOperationTotals()
        local baseline = self.operationBaseline or { totals = { calls = 0, runtime = 0, allocated = 0 }, entries = {} }
        local baselineTotals = baseline.totals
        local deltaCalls = math.max(0, (calls or 0) - (baselineTotals.calls or 0))
        local deltaRuntime = math.max(0, (runtime or 0) - (baselineTotals.runtime or 0))
        local deltaAllocated = math.max(0, (allocated or 0) - (baselineTotals.allocated or 0))
        local entries = self.sessionEntries
        if not entries then entries = {}; self.sessionEntries = entries end
        local entryCount = 0
        local largestDelta, slowestTime, slowestName = 0, 0, nil
        local operations = MOS.Diagnostics.operations or {}
        local name, operation, base = nil, nil, nil
        for name, operation in pairs(operations) do
            base = baseline.entries[name]
            local deltaCount = math.max(0, (operation.count or 0) - (base and base.count or 0))
            if deltaCount > 0 then
                entryCount = entryCount + 1
                local delta = entries[entryCount]
                if not delta then delta = {}; entries[entryCount] = delta end
                delta.name = name
                delta.count = deltaCount
                delta.time = math.max(0, (operation.time or 0) - (base and base.time or 0))
                delta.memory = math.max(0, (operation.memory or 0) - (base and base.memory or 0))
                if delta.memory > largestDelta then largestDelta = delta.memory end
                if delta.time > slowestTime then slowestTime = delta.time; slowestName = name end
            end
        end
        local staleIndex
        for staleIndex = table.getn(entries), entryCount + 1, -1 do entries[staleIndex] = nil end
        table.sort(entries, CompareOperationTime)
        return deltaCalls, deltaRuntime, deltaAllocated, largestDelta, slowestName, entries
    end

    local function UpdateSampler()
        local active = page:IsVisible() or monitor:IsVisible() or module.diagnosis
        if active then sampler.frame:Show() else sampler.frame:Hide() end
        page.monitorButton:SetText(monitor:IsVisible() and "Close Live Monitor" or "Open Live Monitor")
        if MOS.Diagnostics and type(MOS.Diagnostics.SetTracking) == "function" then
            MOS.Diagnostics.SetTracking(active)
        end
    end
    monitor.minimize:SetScript("OnClick", function()
        monitor.minimized = not monitor.minimized
        for index = 1, table.getn(monitor.lines) do if monitor.minimized then monitor.lines[index]:Hide() else monitor.lines[index]:Show() end end
        monitor:SetHeight(monitor.minimized and 34 or 134); monitor.minimize:SetText(monitor.minimized and "+" or "-")
    end)
    monitor:SetScript("OnShow", UpdateSampler); monitor:SetScript("OnHide", UpdateSampler)
    page.monitorButton:SetScript("OnClick", function() if monitor:IsVisible() then monitor:Hide() else monitor:Show() end end)

    function module:Reset()
        local current, threshold = gcinfo()
        sampler.current, sampler.threshold, sampler.lastFast, sampler.lastSlow = current, threshold, current, current
        sampler.fastElapsed, sampler.slowElapsed, sampler.rate, sampler.peak, sampler.lastCleanupAt = 0, 0, 0, 0, nil
        MOS.Diagnostics.operations = {}; self.estimatedBaseline = MOS.Diagnostics.initialMemoryEstimate; self.estimatedAtLoad = current
    end

    function module:StartDiagnosis()
        local calls, runtime = MOS.Diagnostics.GetOperationTotals()
        self.diagnosis = { startedAt = GetTime(), startMemory = sampler.current or gcinfo(), startCalls = calls, startRuntime = runtime, minFps = nil, maxLatency = 0 }
        page.diagnosticButton:SetText("Stop diagnosis")
        report:Hide(); UpdateSampler()
    end

    function module:StopDiagnosis(showReport)
        local session = self.diagnosis
        if not session then return end
        self.diagnosis = nil; page.diagnosticButton:SetText("Start diagnosis"); UpdateSampler()
        if not showReport then return end
        local seconds = math.max(1, GetTime() - session.startedAt); local calls, runtime, _, _, slowest = MOS.Diagnostics.GetOperationTotals()
        local growth = (sampler.current or gcinfo()) - session.startMemory; local callsMade = calls - session.startCalls; local perSecond = callsMade / seconds; local runtimeDuringSession = runtime - session.startRuntime
        local results = {
            string.format("Recorded %.0f seconds and %d measured MOS calls (%.2f/sec).", seconds, callsMade, perSecond),
            string.format("Lua memory changed by %s (%+.1f KB/min).", Memory(math.abs(growth)), growth * 60 / seconds),
            string.format("Lowest FPS: %.0f. Highest latency: %d ms.", session.minFps or 0, session.maxLatency or 0),
        }
        if session.minFps and session.minFps < 30 then table.insert(results, "Warning: FPS dropped below 30 during the diagnosis.") elseif session.minFps and session.minFps < 50 then table.insert(results, "Notice: FPS dropped below 50 during the diagnosis.") else table.insert(results, "FPS remained stable during the recorded period.") end
        if session.maxLatency > 300 then table.insert(results, "Warning: high network latency was observed; this is not necessarily caused by addons.") end
        if growth * 60 / seconds > 1024 then table.insert(results, "Notice: Lua memory grew by more than 1 MB/min; repeat a longer test to confirm a trend.") end
        if perSecond > 5 then table.insert(results, "Notice: MOS performed many measured operations; open Measured calls to identify the busiest one.") else table.insert(results, "No excessive measured MOS operation rate was detected.") end
        table.insert(results, "Measured MOS runtime during diagnosis: " .. Duration(runtimeDuringSession) .. ".")
        if slowest then table.insert(results, "Most expensive observed operation: " .. slowest .. ".") end
        for index = 1, table.getn(report.lines) do report.lines[index]:SetText(results[index] or "") end
        report:Show()
    end

    function module:Refresh()
        local calls, runtime, allocated, largest, slowest = module:GetSessionOperations()
        local current = sampler.current or gcinfo()
        local fps = type(GetFramerate) == "function" and GetFramerate() or 0; local latency = 0
        if type(GetNetStats) == "function" then local _, _, measured = GetNetStats(); latency = tonumber(measured) or 0 end
        if self.diagnosis then
            if not self.diagnosis.minFps or fps < self.diagnosis.minFps then self.diagnosis.minFps = fps end
            if latency > self.diagnosis.maxLatency then self.diagnosis.maxLatency = latency end
        end
        local elapsed = math.max(1, GetTime() - (MOS.Diagnostics.startedAt or GetTime())); local roster = MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.rosterData; local attendance = MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.raidAttendance
        local values = self.valueScratch
        if not values then values = {}; self.valueScratch = values end
        values[1] = Memory(allocated)
        values[2] = tostring(calls)
        values[3] = Duration(runtime)
        values[4] = Duration(calls > 0 and runtime / calls or 0)
        values[5] = Memory(largest)
        values[6] = slowest or "-"
        values[7] = string.format("%.2f", (MOS.Diagnostics.events or 0) / elapsed)
        values[8] = string.format("%.2f", (MOS.Diagnostics.uiRefreshes or 0) / elapsed)
        values[9] = tostring(MOS.Diagnostics.scans or 0)
        values[10] = roster and string.format("%.2f s", tonumber(roster.scanDurationSeconds) or 0) or "-"
        values[11] = tostring(roster and roster.members and table.getn(roster.members) or 0)
        values[12] = string.format("%d / %d", attendance and attendance.members and table.getn(attendance.members) or 0, LootCount())
        values[13] = Memory(current)
        values[14] = Memory(sampler.threshold)
        values[15] = string.format("%+.1f KB/s", sampler.rate or 0)
        values[16] = Memory(sampler.peak or 0)
        values[17] = sampler.lastCleanupAt and string.format("%.0f s ago", GetTime() - sampler.lastCleanupAt) or "Not observed"
        values[18] = fps > 0 and string.format("%.0f / %.1f ms", fps, 1000 / fps) or "-"
        values[19] = tostring(latency) .. " ms"
        for index = 1, table.getn(values) do page.values[index]:SetText(values[index]) end
        monitor.lines[1]:SetText("Lua: " .. Memory(current) .. " / " .. Memory(sampler.threshold)); monitor.lines[2]:SetText(string.format("Rate: %+.1f KB/s  Peak: %s", sampler.rate or 0, Memory(sampler.peak or 0))); monitor.lines[3]:SetText("FPS: " .. string.format("%.0f", fps) .. "  Frame: " .. (fps > 0 and string.format("%.1f ms", 1000 / fps) or "-")); monitor.lines[4]:SetText("Latency: " .. tostring(latency) .. " ms"); monitor.lines[5]:SetText(string.format("MOS: %.2f/s  %d total / %s", calls / elapsed, calls, Duration(runtime))); self:RefreshDetail(); self:RefreshAddons()
    end

    sampler.frame:SetScript("OnUpdate", function()
        sampler.fastElapsed = (sampler.fastElapsed or 0) + arg1; sampler.slowElapsed = (sampler.slowElapsed or 0) + arg1
        if sampler.fastElapsed >= 0.1 then
            sampler.fastElapsed = 0; local current, threshold = gcinfo(); local delta = current - (sampler.lastFast or current)
            if delta < 0 then sampler.lastCleanupAt = GetTime() elseif delta > (sampler.peak or 0) then sampler.peak = delta end
            sampler.current, sampler.threshold, sampler.lastFast = current, threshold, current
        end
        if sampler.slowElapsed >= 1 then sampler.slowElapsed = 0; sampler.rate = (sampler.current or 0) - (sampler.lastSlow or sampler.current or 0); sampler.lastSlow = sampler.current; module:Refresh() end
    end)
    function module:Layout()
        local width, height = page:GetWidth(), page:GetHeight()
        local columns = width >= 510 and 3 or 2
        if width < 360 then columns = 1 end
        local rowGap = height < 430 and 20 or 28
        local columnWidth = math.floor((width - 24) / columns); local labelWidth = math.max(120, math.floor(columnWidth * 0.58)); local valueWidth = math.max(70, columnWidth - labelWidth - 8)
        local addonRows = math.ceil(12 / columns); local globalY = -102 - addonRows * rowGap - (height < 430 and 8 or 12)
        page.globalHeading:ClearAllPoints(); page.globalHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, globalY)
        page.globalRule:ClearAllPoints(); page.globalRule:SetPoint("LEFT", page.globalHeading, "RIGHT", 10, 0); page.globalRule:SetPoint("RIGHT", page, "RIGHT", -12, 0)
        for index = 1, 19 do
            local localIndex, startY
            if index <= 12 then localIndex, startY = index - 1, -102 else localIndex, startY = index - 13, globalY - 26 end
            local column = math.mod(localIndex, columns); local row = math.floor(localIndex / columns); local x, y = 12 + column * columnWidth, startY - row * rowGap
            page.labels[index]:ClearAllPoints(); page.labels[index]:SetPoint("TOPLEFT", page, "TOPLEFT", x, y); page.labels[index]:SetWidth(labelWidth)
            page.values[index]:ClearAllPoints(); page.values[index]:SetPoint("TOPLEFT", page, "TOPLEFT", x + labelWidth + 4, y); page.values[index]:SetWidth(valueWidth)
            page.targets[index]:ClearAllPoints(); page.targets[index]:SetPoint("TOPLEFT", page, "TOPLEFT", x, y + 4); page.targets[index]:SetWidth(columnWidth - 6)
        end
        page.resetButton:ClearAllPoints(); page.resetButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -10)
        page.monitorButton:ClearAllPoints(); page.monitorButton:SetPoint("RIGHT", page.resetButton, "LEFT", -8, 0)
        page.diagnosticButton:ClearAllPoints(); page.diagnosticButton:SetPoint("RIGHT", page.monitorButton, "LEFT", -8, 0)
    end
    function module:Show() self:ResetOperationBaseline(); page:Show(); self:Layout(); UpdateSampler(); self:Refresh() end
    function module:Hide() page:Hide(); detail:Hide(); addons:Hide(); UpdateSampler() end
    function module:OnResize() self:Layout() end
    page.resetButton:SetScript("OnClick", function() module:Reset(); module:ResetOperationBaseline(); module:Refresh() end)
    page.diagnosticButton:SetScript("OnClick", function() if module.diagnosis then module:StopDiagnosis(true) else module:StartDiagnosis() end end)
    module:Reset(); module:Layout(); return module
end


