-- Discovery-only provenance; no function is executed to inspect its source.
local P = BootyProfiler
local Source = {}
P.FunctionSource = Source

local MAX_DUMP_BYTES, MAX_SOURCE_BYTES = 262144, 1024
local function UsableSource(value)
    return type(value) == "string" and string.len(value) > 0
        and string.len(value) <= MAX_SOURCE_BYTES and not string.find(value, "\000", 1, true)
end

local function ReadSize(value, first, count, endian, limit)
    local result = 0
    for index = 1, count do
        local at = endian == 1 and first + count - index or first + index - 1
        local byte = string.byte(value, at)
        if not byte then return nil end
        result = result * 256 + byte
        if result > limit then return nil end
    end
    return result
end

-- Official Lua5.0 ldump.c header followed by the root Proto source string.
-- Never search arbitrary bytecode constants for something resembling a path.
local function DumpSource(value)
    if type(value) ~= "string" or string.len(value) > MAX_DUMP_BYTES then return nil end
    if string.sub(value, 1, 4) ~= "\027Lua" or string.byte(value, 5) ~= 80 then return nil end
    local endian, sizeT = string.byte(value, 6), string.byte(value, 8)
    if endian ~= 0 and endian ~= 1 then return nil end
    if sizeT ~= 4 and sizeT ~= 8 then return nil end
    if string.byte(value, 7) ~= 4 or string.byte(value, 9) ~= 4
        or string.byte(value, 10) ~= 6 or string.byte(value, 11) ~= 8
        or string.byte(value, 12) ~= 9 or string.byte(value, 13) ~= 9
        or string.byte(value, 14) ~= 8 then return nil end
    local first = 23
    local length = ReadSize(value, first, sizeT, endian, MAX_SOURCE_BYTES + 1)
    if not length or length < 2 then return nil end
    first = first + sizeT
    local last = first + length - 1
    -- Source terminator, lineDefined, four root fields and six vector counts.
    if last + 32 > string.len(value) or string.byte(value, last) ~= 0 then return nil end
    local source = string.sub(value, first, last - 1)
    if not UsableSource(source) then return nil end
    if not ReadSize(value, last + 1, 4, endian, 2147483647) then return nil end
    local parameters = string.byte(value, last + 6)
    local isVararg, maxStack = string.byte(value, last + 7), string.byte(value, last + 8)
    if (isVararg ~= 0 and isVararg ~= 1) or not maxStack or maxStack < 1
        or parameters > maxStack then return nil end
    return source
end

function Source.Get(callback)
    if type(callback) ~= "function" then return nil, "unavailable", "invalid-function" end
    local inspect = type(debug) == "table" and rawget(debug, "getinfo")
    if type(inspect) == "function" then
        local ok, info = pcall(inspect, callback, "S")
        local source = ok and type(info) == "table" and rawget(info, "source")
        if UsableSource(source) then
            return source, "debug.getinfo"
        end
    end
    if type(string.dump) == "function" then
        -- Stock Lua5.0 rejects C functions and closures with captured upvalues.
        -- string.dump allocates a complete accepted function before the size
        -- check. The caller must budget/cache discovery; never call this hot.
        local ok, value = pcall(string.dump, callback)
        if not ok then return nil, "unavailable", "dump-rejected" end
        local source = DumpSource(value)
        if source then return source, "Lua5.0 dump" end
        return nil, "unavailable", "unsupported-dump"
    end
    return nil, "unavailable", "no-source-api"
end
