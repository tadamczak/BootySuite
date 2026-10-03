-- External script interception is installed only for an explicit recording.
-- Lua 5.0 creates implicit arg tables for the generic protected-call path;
-- retaining arbitrary nil arguments/results takes precedence over fixed arity.
local P = BootyProfiler
local C = {}
P.Callbacks = C

local FRAME_LIMIT, WRAPPER_LIMIT, ADDON_LIMIT, OPERATION_LIMIT = 4096, 4096, 256, 4096
local SCAN_BUDGET, STACK_LIMIT, HISTORY_LIMIT, RESCAN_INTERVAL = 24, 64, 64, 5
local SCAN_SECONDS, SCAN_LIMIT = 0.0005, 20000
local scripts = { "OnEvent", "OnUpdate" }
local active, restorationBlocked
C.limits = { frames = FRAME_LIMIT, wrappers = WRAPPER_LIMIT, addons = ADDON_LIMIT,
    operations = OPERATION_LIMIT, perStep = SCAN_BUDGET, depth = STACK_LIMIT, history = HISTORY_LIMIT }

local function Finite(value)
    return type(value) == "number" and value == value and value < 1e300 and value > -1e300
end

local function ReadClock(run)
    local ok, value = pcall(run.clock)
    if ok and Finite(value) then
        value = value * run.clockScale
        local delta = run.lastClock and value - run.lastClock
        if delta and delta > 0 and (not run.metrics.clockMinPositiveDelta or delta < run.metrics.clockMinPositiveDelta) then run.metrics.clockMinPositiveDelta = delta end
        run.lastClock = value
        return value
    end
    run.metrics.clockReadFailures = run.metrics.clockReadFailures + 1
    return nil
end

local function ReadScript(frame, script) return frame:GetScript(script) end
local function WriteScript(frame, script, callback) frame:SetScript(script, callback) end
local function ReadName(frame) return frame:GetName() end

local function SourceOwner(run, callback)
    local cached = run.functionSources[callback]
    if cached then return cached.owner, cached.source end
    if run.sourceBudget <= 0 then return nil, nil, true end
    if run.sourceCount >= WRAPPER_LIMIT then run.metrics.truncated = true; return nil, nil end
    run.sourceBudget = run.sourceBudget - 1
    local source, method, reason
    if P.FunctionSource and type(P.FunctionSource.Get) == "function" then
        local ok, value, backend, failure = pcall(P.FunctionSource.Get, callback)
        if ok then source, method, reason = value, backend, failure else run.metrics.sourceFailures = run.metrics.sourceFailures + 1 end
    elseif run.getinfo then
        local ok, info = pcall(run.getinfo, callback, "S")
        if ok and type(info) == "table" then source, method = info.source, "debug.getinfo" end
    end
    run.sourceCount = run.sourceCount + 1
    if method then run.metrics.sourceMethod = method end
    if method == "debug.getinfo" then run.metrics.sourceDebug = run.metrics.sourceDebug + 1
    elseif method == "Lua5.0 dump" then run.metrics.sourceDump = run.metrics.sourceDump + 1
    else run.metrics.sourceUnavailable = run.metrics.sourceUnavailable + 1 end
    if reason == "dump-rejected" then run.metrics.sourceDumpRejected = run.metrics.sourceDumpRejected + 1
    elseif reason == "unsupported-dump" then run.metrics.sourceUnsupportedDump = run.metrics.sourceUnsupportedDump + 1
    elseif reason == "no-source-api" then run.metrics.sourceApiUnavailable = run.metrics.sourceApiUnavailable + 1 end
    local owner = "Unknown owner"
    if type(source) ~= "string" or string.len(source) > 1024 then source = nil end
    if source then source = string.gsub(source, "\\", "/") end
    if not source or string.sub(source, 1, 1) ~= "@" then
        if source then run.metrics.sourceNonFile = run.metrics.sourceNonFile + 1 end
        run.functionSources[callback] = { owner = owner, source = source }
        return owner, source
    end
    local lower = string.lower(source)
    local _, last = string.find(lower, "[/@]interface/addons/")
    if last then
        local slash = string.find(source, "/", last + 1, true)
        if slash and slash > last + 1 then
            local folder = string.sub(source, last + 1, slash - 1)
            if string.lower(folder) == "bootyprofiler" then owner = nil
            else
                owner = run.inventoryMap[string.lower(folder)] or "Unknown owner"
                if owner == "Unknown owner" then run.metrics.sourceUnmatchedFolder = run.metrics.sourceUnmatchedFolder + 1 end
            end
        end
    end
    if string.find(lower, "[/@]interface/framexml/") or string.find(lower, "[/@]interface/sharedxml/") then owner = nil end
    run.functionSources[callback] = { owner = owner, source = source }
    return owner, source
end

local function NewMetric(name)
    return { name = name, calls = 0, timedCalls = 0, time = 0, selfTime = 0, peak = 0, failures = 0 }
end

local function AddonMetric(run, owner)
    local metric = run.addonMap[owner]
    if metric then return metric end
    -- Reserve the final row for aggregation instead of retaining unbounded keys.
    if table.getn(run.metrics.addons) >= ADDON_LIMIT - 1 then
        run.metrics.truncated = true
        owner = "Other owners (limit reached)"
        metric = run.addonMap[owner]
        if metric then return metric end
    end
    metric = NewMetric(owner)
    run.addonMap[owner] = metric
    table.insert(run.metrics.addons, metric)
    return metric
end

local function AddMetric(metric, elapsed, own, failed)
    metric.calls = metric.calls + 1
    if failed then metric.failures = metric.failures + 1 end
    if not elapsed then return end
    metric.timedCalls = metric.timedCalls + 1
    metric.time = metric.time + elapsed
    metric.selfTime = metric.selfTime + own
    if elapsed > metric.peak then metric.peak = elapsed end
end

local function PushSlow(run, record, elapsed, own, callbackEvent, failed)
    if elapsed < run.session.slowThreshold then return end
    local buffer = run.metrics.history
    local index = math.mod(buffer.total, HISTORY_LIMIT) + 1
    local entry = buffer[index]
    if not entry then entry = {}; table.insert(buffer, entry) end
    buffer.total = buffer.total + 1
    buffer.count = math.min(buffer.total, HISTORY_LIMIT)
    entry.name, entry.owner, entry.script = record.name, record.owner, record.script
    entry.elapsed, entry.selfTime, entry.event, entry.failed = elapsed, own, callbackEvent, failed and true or false
    -- Session timestamps use GetTime; callback durations may use a finer clock.
    local timed, now = false, nil
    if type(GetTime) == "function" then timed, now = pcall(GetTime) end
    entry.at = timed and Finite(now) and math.max(0, now - run.session.startedAt) or math.max(0, run.session.elapsed or 0)
end

local function FinishRecord(run, record, slot, failed)
    if not run.active then
        run.depth = run.depth - 1
        slot.started, slot.event, slot.children = nil, nil, 0
        return
    end
    local ended = ReadClock(run)
    local elapsed, own
    if slot.started and ended and ended >= slot.started then
        elapsed = ended - slot.started
        own = math.max(0, elapsed - slot.children)
    elseif run.active then run.metrics.timingFailures = run.metrics.timingFailures + 1 end
    run.depth = run.depth - 1
    local parent = run.stack[run.depth]
    if parent and elapsed then parent.children = parent.children + elapsed end
    if run.active and record.enabled then
        local metrics = run.metrics
        metrics.totalCalls = metrics.totalCalls + 1
        if failed then metrics.failures = metrics.failures + 1 end
        AddMetric(record.addon, elapsed, own, failed)
        if record.operation then AddMetric(record.operation, elapsed, own, failed) end
        if elapsed then
            metrics.totalTimedCalls = metrics.totalTimedCalls + 1
            metrics.totalInclusiveTime = metrics.totalInclusiveTime + elapsed
            metrics.totalSelfTime = metrics.totalSelfTime + own
            if elapsed == 0 then metrics.zeroDurations = metrics.zeroDurations + 1 end
            PushSlow(run, record, elapsed, own, slot.event, failed)
        end
    end
    slot.started, slot.event, slot.children = nil, nil, 0
end

local function FinishCall(run, record, slot, ...)
    -- Measurement failures must not alter callback return values or its error.
    local ok = pcall(FinishRecord, run, record, slot, not arg[1])
    if not ok then
        run.depth = math.max(0, slot.depth - 1)
        slot.started, slot.event, slot.children = nil, nil, 0
        run.metrics.metricFailures = run.metrics.metricFailures + 1
    end
    if not arg[1] then
        error(arg[2], 0)
        -- Some modified clients print error() without throwing; preserve failure.
        assert(false, tostring(arg[2])); return
    end
    local index
    for index = 1, arg.n - 1 do arg[index] = arg[index + 1] end
    arg[arg.n] = nil; arg.n = arg.n - 1
    return unpack(arg)
end

local function MakeWrapper(record)
    return function(...)
        local run = record.run
        if not run or not run.active or not record.enabled then return record.original(unpack(arg)) end
        if run.depth >= STACK_LIMIT then
            run.metrics.depthSkipped = run.metrics.depthSkipped + 1
            return record.original(unpack(arg))
        end
        run.depth = run.depth + 1
        local slot = run.stack[run.depth]
        slot.depth, slot.children = run.depth, 0
        slot.event = record.script == "OnEvent" and type(event) == "string" and event or nil
        slot.started = ReadClock(run)
        return FinishCall(run, record, slot, pcall(record.original, unpack(arg)))
    end
end

local function ReleaseRecord(run, record, restore)
    if not record or not record.enabled then return end
    record.enabled = false
    run.metrics.hooked = math.max(0, run.metrics.hooked - 1)
    if record.owner == "Unknown owner" then run.metrics.unknown = math.max(0, run.metrics.unknown - 1) end
    if restore and record.frame then
        local read, current = pcall(ReadScript, record.frame, record.script)
        if not read then run.metrics.restoreFailures = run.metrics.restoreFailures + 1; restorationBlocked = true
        elseif current == record.wrapper then
            local restored = pcall(WriteScript, record.frame, record.script, record.original)
            if not restored then run.metrics.restoreFailures = run.metrics.restoreFailures + 1; restorationBlocked = true end
        end
    end
    -- A third-party replacement can retain an old wrapper. It remains an inert
    -- delegate, without retaining the frame, capture or metric containers.
    record.run, record.frame, record.addon, record.operation = nil, nil, nil, nil
end

local function Attach(run, frameRecord, script, callback)
    if type(callback) ~= "function" then return end
    local owner, source, pending = SourceOwner(run, callback)
    if pending then return false end
    if not owner then run.metrics.skippedKnown = run.metrics.skippedKnown + 1; return end
    if table.getn(run.records) >= WRAPPER_LIMIT then run.metrics.truncated = true; return end
    local record = { frame = frameRecord.frame, script = script, original = callback, owner = owner,
        name = frameRecord.name .. " / " .. script, source = source, run = run, enabled = true }
    record.addon = AddonMetric(run, owner)
    if table.getn(run.metrics.operations) < OPERATION_LIMIT then
        local operation = NewMetric(record.name)
        operation.owner, operation.script, operation.source = owner, script, source
        table.insert(run.metrics.operations, operation)
        record.operation = operation
    else run.metrics.operationsTruncated = true end
    record.wrapper = MakeWrapper(record)
    run.wrapperMap[record.wrapper] = record
    -- Retain before SetScript: a modified API can install then throw. Stop must
    -- still be able to restore that exact wrapper during failed activation.
    table.insert(run.records, record)
    run.metrics.hooked = run.metrics.hooked + 1
    if owner == "Unknown owner" then run.metrics.unknown = run.metrics.unknown + 1 end
    local installed = pcall(WriteScript, record.frame, script, record.wrapper)
    if not installed then
        run.metrics.inspectionFailures = run.metrics.inspectionFailures + 1
        ReleaseRecord(run, record, true)
        frameRecord[script] = record
        return
    end
    run.metrics.everHooked = run.metrics.everHooked + 1
    if owner == "Unknown owner" then run.metrics.everUnknownHooked = run.metrics.everUnknownHooked + 1 end
    frameRecord[script] = record
    return true
end

local function InspectFrame(run, frame)
    if P.Runtime and frame == P.Runtime.driver then return end
    local entry = run.frameMap[frame]
    -- Enumeration includes every inert UI frame. Read supported scripts before
    -- retaining a frame so that inert frames cannot exhaust callback capacity.
    local eventRead, onEvent = pcall(ReadScript, frame, "OnEvent")
    local updateRead, onUpdate = pcall(ReadScript, frame, "OnUpdate")
    if not eventRead then run.metrics.inspectionFailures = run.metrics.inspectionFailures + 1 end
    if not updateRead then run.metrics.inspectionFailures = run.metrics.inspectionFailures + 1 end
    if not entry then
        if not (eventRead and type(onEvent) == "function") and not (updateRead and type(onUpdate) == "function") then
            if eventRead and updateRead then run.metrics.inertSkipped = run.metrics.inertSkipped + 1 end
            return true
        end
        if run.metrics.discovered >= FRAME_LIMIT then run.metrics.truncated = true; return end
        local named, name = pcall(ReadName, frame)
        run.metrics.discovered = run.metrics.discovered + 1
        run.frameSerial = run.frameSerial + 1
        if not named or type(name) ~= "string" or name == "" then name = "Unnamed frame " .. run.frameSerial end
        entry = { frame = frame, name = name }
        run.frameMap[frame] = entry
    end
    local index, recordsBefore = nil, table.getn(run.records)
    for index = 1, table.getn(scripts) do
        local script = scripts[index]
        local read, current
        if index == 1 then read, current = eventRead, onEvent
        else
            -- A modified OnEvent setter may also replace OnUpdate. Re-read only
            -- after an attempted install so a stale snapshot cannot overwrite it.
            if table.getn(run.records) > recordsBefore then
                updateRead, onUpdate = pcall(ReadScript, frame, "OnUpdate")
                if not updateRead then run.metrics.inspectionFailures = run.metrics.inspectionFailures + 1 end
            end
            read, current = updateRead, onUpdate
        end
        if read then
            local old = entry[script]
            if not old or current ~= old.wrapper then
                if old then
                    run.metrics.replacements = run.metrics.replacements + 1
                    ReleaseRecord(run, old, false); entry[script] = nil
                end
                local existingWrapper = run.wrapperMap[current]
                if existingWrapper then
                    -- Do not profile the profiler when a modified installer
                    -- retained a failed or third-party-retained own wrapper.
                    entry[script] = existingWrapper
                elseif Attach(run, entry, script, current) == false then return false end
            end
        end
    end
    if eventRead and updateRead and type(onEvent) ~= "function" and type(onUpdate) ~= "function" then
        run.frameMap[frame] = nil
        run.metrics.discovered = run.metrics.discovered - 1
        run.metrics.inertSkipped = run.metrics.inertSkipped + 1
    end
    return true
end

function C.Start(session)
    if active then C.Stop(active.session) end
    local metrics = { addons = {}, operations = {}, history = { count = 0, total = 0 }, totalCalls = 0, totalTimedCalls = 0,
        totalInclusiveTime = 0, totalSelfTime = 0, failures = 0, discovered = 0, hooked = 0, unknown = 0,
        pending = true, truncated = false, status = "Discovering frame callbacks", inspectionFailures = 0,
        restoreFailures = 0, timingFailures = 0, metricFailures = 0, zeroDurations = 0, depthSkipped = 0, sourceFailures = 0,
        everHooked = 0, everUnknownHooked = 0, replacements = 0, skippedKnown = 0, clockReadFailures = 0,
        sourceDebug = 0, sourceDump = 0, sourceUnavailable = 0, inventoryReadFailures = 0,
        sourceDumpRejected = 0, sourceUnsupportedDump = 0, sourceApiUnavailable = 0, sourceNonFile = 0, sourceUnmatchedFolder = 0,
        scans = 0, scanned = 0, inertSkipped = 0, discoveryTime = 0,
        coverage = "Intercepted OnEvent and OnUpdate frame scripts only; not total addon CPU. Self time subtracts nested intercepted callbacks; unknown source owners are not guessed." }
    session.callbacks = metrics
    if restorationBlocked then
        metrics.pending, metrics.available = false, false
        metrics.status = "Callback capture is blocked after a restoration failure. Reload the UI before recording callbacks again."
        metrics.restorationBlocked = true
        return true
    end
    if type(EnumerateFrames) ~= "function" then
        metrics.pending, metrics.status, metrics.available = false, "Frame enumeration is unavailable in this client", false
        return true
    end
    local clock, scale = GetTime, 1
    if type(debugprofilestop) == "function" then
        local ok, value = pcall(debugprofilestop)
        if ok and Finite(value) then clock, scale = debugprofilestop, 0.001 end
    end
    if type(clock) ~= "function" then
        metrics.pending, metrics.status, metrics.available = false, "Callback clock is unavailable in this client", false
        return true
    end
    metrics.clock = scale == 0.001 and "debugprofilestop (differences; milliseconds)" or "GetTime"
    metrics.clockResolution = "Not verified in this client; zero and invalid durations are reported"
    local run = { session = session, metrics = metrics, clock = clock, clockScale = scale, active = true,
        enumerate = EnumerateFrames, frameMap = {}, records = {}, wrapperMap = {}, addonMap = {}, stack = {}, depth = 0,
        functionSources = {}, sourceCount = 0, sourceBudget = 0, inventoryMap = {}, inventoryNext = 1,
        getinfo = type(debug) == "table" and type(debug.getinfo) == "function" and debug.getinfo or nil,
        cursor = nil, scanning = true, cycleCount = 0, wait = 0, frameSerial = 0 }
    local inventoried, count = false, nil
    if type(GetNumAddOns) == "function" and type(GetAddOnInfo) == "function" then inventoried, count = pcall(GetNumAddOns) end
    if inventoried and Finite(count) and count >= 0 then
        count = math.floor(count)
        run.inventoryCount, run.inventoryGetter = math.min(ADDON_LIMIT, count), GetAddOnInfo
        metrics.inventoryAvailable, metrics.inventoryCount, metrics.inventoryTruncated = true, run.inventoryCount, count > ADDON_LIMIT
        if count > ADDON_LIMIT then metrics.truncated = true end
        if run.inventoryCount > 0 then metrics.status = "Reading installed addon inventory" end
    else run.inventoryCount, metrics.inventoryAvailable, metrics.inventoryCount = 0, false, 0 end
    metrics.ownerSupport = metrics.inventoryAvailable and "Function source matched to installed addon folders; missing sources are Unknown owner"
        or "Installed addon inventory unavailable; callbacks are grouped as Unknown owner"
    local index
    for index = 1, STACK_LIMIT do run.stack[index] = { children = 0 } end
    active = run; metrics.available = true
    return true
end

function C.Step(delta)
    local run = active
    if not run or not run.active then return end
    local amount = tonumber(delta) or 0
    if not Finite(amount) or amount < 0 then amount = 0 end
    if not run.scanning then
        run.wait = run.wait + amount
        if run.wait < RESCAN_INTERVAL then return end
        run.scanning, run.cursor, run.cycleCount, run.wait = true, nil, 0, 0
        run.metrics.pending, run.metrics.status = true, "Reconciling frame callbacks"
    end
    local began = ReadClock(run)
    if run.inventoryNext <= run.inventoryCount then
        local ok, name = pcall(run.inventoryGetter, run.inventoryNext)
        if ok and type(name) == "string" and string.len(name) > 0 and string.len(name) <= 128 then
            run.inventoryMap[string.lower(name)] = name
        else run.metrics.inventoryReadFailures = run.metrics.inventoryReadFailures + 1 end
        run.inventoryNext = run.inventoryNext + 1
        if run.inventoryNext > run.inventoryCount then run.metrics.status = "Discovering frame callbacks" end
        local ended = ReadClock(run)
        if began and ended and ended >= began then run.metrics.discoveryTime = run.metrics.discoveryTime + ended - began end
        return
    end
    run.sourceBudget = 1
    local pending = run.pendingFrame
    local incomplete = pending and InspectFrame(run, pending) == false
    if pending and not incomplete then run.pendingFrame = nil end
    local index
    for index = pending and 2 or 1, SCAN_BUDGET do
        if incomplete then break end
        local ok, frame = pcall(run.enumerate, run.cursor)
        if not ok then
            run.metrics.inspectionFailures = run.metrics.inspectionFailures + 1
            run.metrics.status = "Frame enumeration failed; recording existing callbacks"
            run.metrics.pending, run.scanning, run.wait = false, false, 0
            break
        end
        if not frame then
            run.metrics.pending, run.scanning, run.wait = false, false, 0
            run.metrics.scans = run.metrics.scans + 1
            run.metrics.firstScanComplete = true
            run.metrics.status = "Recording frame callbacks"
            break
        end
        run.cursor = frame
        run.cycleCount, run.metrics.scanned = run.cycleCount + 1, run.metrics.scanned + 1
        if InspectFrame(run, frame) == false then run.pendingFrame = frame; break end
        if run.cycleCount >= SCAN_LIMIT then
            run.metrics.truncated, run.metrics.pending, run.scanning, run.wait = true, false, false, 0
            run.metrics.status = "Frame discovery reached its scan limit"
            break
        end
        if math.mod(index, 4) == 0 and began then
            local current = ReadClock(run)
            if current and current >= began and current - began >= SCAN_SECONDS then break end
        end
    end
    local ended = ReadClock(run)
    if began and ended and ended >= began then run.metrics.discoveryTime = run.metrics.discoveryTime + ended - began end
end

function C.Stop(session)
    local run = active
    if not run or (session and run.session ~= session) then return true end
    active, run.active = nil, false
    run.metrics.wasPendingAtStop, run.metrics.activeHookedAtStop, run.metrics.unknownAtStop = run.metrics.pending, run.metrics.hooked, run.metrics.unknown
    local index
    for index = 1, table.getn(run.records) do ReleaseRecord(run, run.records[index], true) end
    run.cursor, run.pendingFrame, run.frameMap, run.records, run.wrapperMap, run.addonMap, run.functionSources, run.inventoryMap = nil, nil, nil, nil, nil, nil, nil, nil
    run.metrics.pending = false
    if run.metrics.restoreFailures > 0 then run.metrics.status = "Stopped; restoration failures: " .. run.metrics.restoreFailures
    elseif run.metrics.wasPendingAtStop then run.metrics.status = "Stopped during discovery; callback wrappers removed"
    else run.metrics.status = "Stopped; callback wrappers removed" end
    return run.metrics.restoreFailures == 0
end
