local MOS = MuklaOfficerSuite
local Diagnostics = MOS.Diagnostics

Diagnostics.operations = Diagnostics.operations or {}
Diagnostics.trackOperations = false

function Diagnostics.Record(name, elapsed, allocated)
    if not Diagnostics.trackOperations then
        return
    end
    local entry = Diagnostics.operations[name]
    if not entry then
        entry = { count = 0, time = 0, memory = 0, maxTime = 0, maxMemory = 0 }
        Diagnostics.operations[name] = entry
    end
    elapsed = math.max(0, tonumber(elapsed) or 0)
    allocated = math.max(0, tonumber(allocated) or 0)
    entry.count = entry.count + 1
    entry.time = entry.time + elapsed
    entry.memory = entry.memory + allocated
    if elapsed > entry.maxTime then entry.maxTime = elapsed end
    if allocated > entry.maxMemory then entry.maxMemory = allocated end
end

function Diagnostics.SetTracking(enabled)
    Diagnostics.trackOperations = enabled and true or false
end

function Diagnostics.Wrap(name, callback)
    return function(...)
        local memoryBefore = type(gcinfo) == "function" and gcinfo() or 0
        local timeBefore = GetTime()
        local result = callback(unpack(arg))
        Diagnostics.Record(name, GetTime() - timeBefore, (type(gcinfo) == "function" and gcinfo() or memoryBefore) - memoryBefore)
        return result
    end
end

function Diagnostics.GetOperationTotals()
    local calls, elapsed, allocated, largestAllocation, slowestTime, slowestName = 0, 0, 0, 0, 0, nil
    local name, entry
    for name, entry in pairs(Diagnostics.operations) do
        calls = calls + entry.count
        elapsed = elapsed + entry.time
        allocated = allocated + entry.memory
        if entry.maxMemory > largestAllocation then largestAllocation = entry.maxMemory end
        if entry.maxTime > slowestTime then slowestTime = entry.maxTime; slowestName = name end
    end
    return calls, elapsed, allocated, largestAllocation, slowestName
end
