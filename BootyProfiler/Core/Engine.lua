local P = BootyProfiler
local sources, listener = {}, nil
local state = { enabled = false, recording = false, session = nil }
local HISTORY_LIMIT, SAMPLE_LIMIT, OPERATION_LIMIT = 64, 600, 128
P.limits = { history = HISTORY_LIMIT, samples = SAMPLE_LIMIT, operations = OPERATION_LIMIT }

local function Notify()
    if listener then
        local ok, failure = pcall(listener)
        if not ok then state.listenerError = tostring(failure); listener = nil end
    end
end

local function Now()
    if type(GetTime) ~= "function" then return nil end
    local ok, value = pcall(GetTime)
    if not ok or type(value) ~= "number" or value ~= value or value > 1e300 or value < -1e300 then return nil end
    return value
end

local function Push(buffer, limit)
    local index = math.mod(buffer.total, limit) + 1
    local entry = buffer[index]
    if not entry then entry = {}; table.insert(buffer, entry) end
    buffer.total = buffer.total + 1
    buffer.count = math.min(buffer.total, limit)
    return entry
end

local function Record(name, elapsed, heapChange)
    local session = state.recording and state.session
    if not session or elapsed < session.slowThreshold then return end
    local entry = Push(session.history, HISTORY_LIMIT)
    entry.name, entry.elapsed, entry.heapChange = name, elapsed, heapChange
    entry.at = math.max(0, (Now() or session.startedAt) - session.startedAt)
    entry.event = type(event) == "string" and event or nil
end

function P.GetState() return state end
function P.SetListener(callback) listener = callback end
function P.RegisterSource(name, source)
    if state.recording then return false, "Stop recording before changing the source." end
    if type(source) ~= "table" or type(source.start) ~= "function" or type(source.stop) ~= "function" then return false, "Invalid profiling source." end
    sources[name] = source
    return true
end

function P.Sample()
    local session = state.recording and state.session
    if not session then return end
    local now = Now()
    if not now then state.error = "Client clock is unavailable."; P.Stop(); return end
    session.elapsed = math.max(0, now - session.startedAt)
    local entry = Push(session.samples, SAMPLE_LIMIT)
    entry.at = session.elapsed
    if type(gcinfo) == "function" then
        entry.heap, session.gcThreshold = gcinfo()
        session.heap = entry.heap
        if not session.startHeap then session.startHeap = entry.heap end
    end
    if type(GetFramerate) == "function" then
        local fps = tonumber(GetFramerate())
        if fps and fps > 0 then
            entry.fps = fps; session.fps = fps
            if not session.minFps or fps < session.minFps then session.minFps = fps end
            if not session.maxFps or fps > session.maxFps then session.maxFps = fps end
        else entry.fps = nil end
    end
    if type(GetNetStats) == "function" then
        local _, _, latency = GetNetStats()
        entry.latency = tonumber(latency); session.latency = entry.latency
    end
    Notify()
end

function P.Start(options)
    if not state.enabled then return false, "Enable BootyProfiler first." end
    if state.recording then return false, "A recording is already running." end
    local source, now = sources.MOS, Now()
    if not source then return false, "MOS profiling source is unavailable." end
    if not now then return false, "Client clock is unavailable." end
    local ok, handle, failure = pcall(source.start, Record)
    if not ok or not handle then state.error = tostring(ok and failure or handle); Notify(); return false, state.error end
    if type(handle) ~= "table" or type(handle.operations) ~= "table" then
        pcall(source.stop, handle)
        state.error = "Profiling source returned an invalid handle."; Notify(); return false, state.error
    end
    local callbacksRequested = type(options) == "table" and options.callbacks and true or false
    local session = { startedAt = now, elapsed = 0, history = { count = 0, total = 0 }, samples = { count = 0, total = 0 },
        slowThreshold = 0.005, source = source, handle = handle, operations = handle.operations,
        clock = "GetTime", clockResolution = "not verified in this client", coverage = "Selected MOS entry points; nested calls counted once.",
        callbacksRequested = callbacksRequested,
        allAddonsCoverage = callbacksRequested and "Intercepted frame OnEvent/OnUpdate callbacks, global Lua heap and sampled FPS/latency. This is not total addon CPU or causal FPS attribution."
            or "Global Lua heap and sampled FPS/latency. Start from All Addons to also intercept frame callbacks." }
    state.session, state.recording, state.error, state.listenerError = session, true, nil, nil
    if source.capabilities then
        local captured, capabilities = pcall(source.capabilities)
        if not captured then P.Stop(); state.error = tostring(capabilities); Notify(); return false, state.error end
        session.capabilities = capabilities
    end
    local sampled, sampleError = pcall(P.Sample)
    if not sampled then P.Stop(); state.error = tostring(sampleError); Notify(); return false, state.error end
    if not state.recording then return false, state.error end
    if callbacksRequested and P.Callbacks then
        local activated, callbackError = pcall(P.Callbacks.Start, session)
        if not activated then P.Stop(); state.error = tostring(callbackError); Notify(); return false, state.error end
    elseif callbacksRequested then
        session.allAddonsCoverage = "Frame callback profiling is unavailable in this BootyProfiler version. Global Lua heap and sampled FPS/latency only."
    end
    local running, runtimeError = pcall(P.Runtime.SetRunning, true)
    if not running then P.Stop(); state.error = tostring(runtimeError); Notify(); return false, state.error end
    Notify()
    return true
end

function P.Stop()
    if not state.recording then return false end
    local session = state.session
    -- One cleanup failure must not prevent the other measurement sources from
    -- releasing their wrappers/scopes. Freeze the capture before teardown.
    state.recording = false
    local runtimeStopped, runtimeError = pcall(P.Runtime.SetRunning, false)
    local callbacksStopped, callbackError = true, nil
    if session.callbacksRequested and P.Callbacks then
        callbacksStopped, callbackError = pcall(P.Callbacks.Stop, session)
        if callbacksStopped and callbackError == false then
            callbacksStopped, callbackError = false, "Some callback wrappers could not be restored; retained wrappers are disabled."
        end
    end
    local ok, failure = pcall(session.source.stop, session.handle)
    session.elapsed = math.max(session.elapsed, (Now() or session.startedAt) - session.startedAt)
    if type(gcinfo) == "function" then
        local measured, heap = pcall(gcinfo)
        if measured and type(heap) == "number" then session.heap = heap end
    end
    session.stopped = true
    if not ok then state.error = tostring(failure) end
    if not callbacksStopped then state.error = tostring(callbackError) end
    if not runtimeStopped then state.error = tostring(runtimeError) end
    Notify()
    return ok and callbacksStopped and runtimeStopped
end

function P.Fail(message)
    P.Stop(); state.error = tostring(message); Notify()
end

function P.Enable(enabled)
    if not enabled then P.Stop() end
    state.enabled = enabled and true or false
    Notify()
end

function P.Reset()
    local restart = state.recording
    local callbacks = state.session and state.session.callbacksRequested
    P.Stop(); state.session, state.error = nil, nil
    if restart then return P.Start({ callbacks = callbacks }) end
    Notify(); return true
end

function P.HistoryEntry(buffer, index)
    if not buffer or index < 1 or index > buffer.count then return nil end
    local oldest = buffer.total > buffer.count and math.mod(buffer.total, buffer.count) + 1 or 1
    return buffer[math.mod(oldest + index - 2, buffer.count) + 1]
end

local function CopyFields(value)
    local result, key, field = {}, nil, nil
    for key, field in pairs(value) do if type(field) ~= "table" and type(field) ~= "function" and type(field) ~= "userdata" then result[key] = field end end
    return result
end
local function CompareTime(left, right) return left.time > right.time end
local function CompareMemory(left,right) return left.memory > right.memory end
local function CompareSelfTime(left,right) return left.selfTime > right.selfTime end

function P.ReadAddonMemory()
    if not state.enabled then return false,"Enable BootyProfiler first." end
    if type(UpdateAddOnMemoryUsage)~="function" or type(GetAddOnMemoryUsage)~="function"
        or type(GetNumAddOns)~="function" or type(GetAddOnInfo)~="function" then return false,"Native addon memory statistics are unavailable in this client." end
    local ok,failure=pcall(UpdateAddOnMemoryUsage)
    if not ok then return false,tostring(failure) end
    local counted,number=pcall(GetNumAddOns)
    if not counted or type(number)~="number" then return false,"Addon inventory is unavailable." end
    local entries=state.addonEntries
    if not entries then entries={};state.addonEntries=entries end
    local count=0
    for index=1,math.min(256,math.max(0,math.floor(number))) do
        local measured,amount=pcall(GetAddOnMemoryUsage,index)
        local named,name,title=pcall(GetAddOnInfo,index)
        if measured and named and type(amount)=="number" and amount>=0 then
            count=count+1
            local entry=entries[count]
            if not entry then entry={};table.insert(entries,entry) end
            entry.name,entry.memory=title or name or ("Addon "..index),amount
        end
    end
    for index=table.getn(entries),count+1,-1 do table.remove(entries,index) end
    table.sort(entries,CompareMemory);state.addonMemoryTruncated=number>256
    return true
end

function P.Export()
    if state.recording then return nil, "Stop recording before exporting." end
    local session = state.session
    if not session then return nil, "No recording to export." end
    local result = { schema = 1, profilerVersion = P.version, elapsed = session.elapsed, clock = session.clock,
        clockResolution = session.clockResolution, coverage = session.coverage, allAddonsCoverage = session.allAddonsCoverage,
        callbacksRequested = session.callbacksRequested,
        startHeap = session.startHeap, endHeap = session.heap, minFps = session.minFps, maxFps = session.maxFps,
        slowThreshold = session.slowThreshold, history = {}, samples = {}, operations = {} }
    local name, operation, index
    for name, operation in pairs(session.operations) do
        if table.getn(result.operations) < OPERATION_LIMIT then local copy = CopyFields(operation); copy.name = name; table.insert(result.operations, copy)
        else result.operationsTruncated = true end
    end
    table.sort(result.operations, CompareTime)
    for index = 1, session.history.count do table.insert(result.history, CopyFields(P.HistoryEntry(session.history, index))) end
    for index = 1, session.samples.count do table.insert(result.samples, CopyFields(P.HistoryEntry(session.samples, index))) end
    if session.capabilities then result.capabilities = CopyFields(session.capabilities) end
    if session.callbacks then
        local callbacks = session.callbacks
        result.callbacks = CopyFields(callbacks)
        result.callbacks.addons, result.callbacks.operations, result.callbacks.history = {}, {}, {}
        result.callbacks.sourceExamples = {}
        for index = 1, math.min(8, table.getn(callbacks.sourceExamples or {})) do
            table.insert(result.callbacks.sourceExamples, CopyFields(callbacks.sourceExamples[index]))
        end
        for index = 1, math.min(256, table.getn(callbacks.addons or {})) do
            table.insert(result.callbacks.addons, CopyFields(callbacks.addons[index]))
        end
        table.sort(result.callbacks.addons, CompareSelfTime)
        -- Export is explicit and stopped. Select the actual highest-cost
        -- callbacks across the bounded capture, rather than its first entries.
        local ordered = {}
        for index = 1, table.getn(callbacks.operations or {}) do table.insert(ordered, callbacks.operations[index]) end
        table.sort(ordered, CompareSelfTime)
        for index = 1, math.min(OPERATION_LIMIT, table.getn(ordered)) do
            table.insert(result.callbacks.operations, CopyFields(ordered[index]))
        end
        result.callbacks.operationsTruncated = table.getn(ordered) > OPERATION_LIMIT
        local history = callbacks.history
        if history then
            for index = 1, history.count do table.insert(result.callbacks.history, CopyFields(P.HistoryEntry(history,index))) end
        end
    end
    if state.addonEntries then
        result.addonMemory={}
        for index=1,table.getn(state.addonEntries) do table.insert(result.addonMemory,CopyFields(state.addonEntries[index])) end
        result.addonMemoryTruncated=state.addonMemoryTruncated
    end
    BootyProfilerDB = { schema = 1, lastSession = result }
    return result
end
