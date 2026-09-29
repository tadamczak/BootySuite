local MOS = MuklaOfficerSuite
MOS.Services.AutoLoot = {}
local AutoLoot = MOS.Services.AutoLoot
local cachedText, exceptions = nil, {}

local function Normalize(name)
    return string.lower(string.gsub(string.gsub(tostring(name or ""), "%s+", " "), "^%s*(.-)%s*$", "%1"))
end

function AutoLoot.IsEnabled(mode, shiftAtOpen)
    return mode == "auto" or (mode == "shift" and shiftAtOpen == true)
end

function AutoLoot.Allows(name, quality, rarities, text)
    if type(quality) ~= "number" or quality < 0 or quality > 4 or quality ~= math.floor(quality) or not name or name == "" then return false end
    if math.mod(math.floor((tonumber(rarities) or 0) / (2 ^ quality)), 2) ~= 1 then return false end
    text = tostring(text or "")
    if cachedText ~= text then
        local key
        for key in pairs(exceptions) do exceptions[key] = nil end
        for key in string.gfind(text, "[^,]+") do
            local normalized = Normalize(key)
            if normalized ~= "" then exceptions[normalized] = true end
        end
        cachedText = text
    end
    return not exceptions[Normalize(name)]
end
