local MOS = BootySuite
local Match = MOS.Core and MOS.Core.Compatibility and MOS.Core.Compatibility.Match or string.match

MOS.Services.AddonMessage = MOS.Services.AddonMessage or {}
local AddonMessage = MOS.Services.AddonMessage

AddonMessage.PREFIX = "BOOTYSUITE"

local function CleanPart(value)
    return string.gsub(tostring(value or ""), ":", "")
end

function AddonMessage.Encode(topic, action, payload)
    return CleanPart(topic) .. ":" .. CleanPart(action) .. ":" .. tostring(payload or "")
end

function AddonMessage.Decode(prefix, message)
    if prefix ~= AddonMessage.PREFIX or type(message) ~= "string" then return nil end
    local topic, action, payload = Match(message, "^([^:]+):([^:]+):(.*)$")
    if not topic or not action then return nil end
    return topic, action, payload
end

function AddonMessage.Send(topic, action, payload, channel)
    if type(SendAddonMessage) ~= "function" or not channel then return false end
    SendAddonMessage(AddonMessage.PREFIX, AddonMessage.Encode(topic, action, payload), channel)
    return true
end

function AddonMessage.GetAvailableChannels(target)
    local channels = target or {}
    local previousCount = table.getn(channels)
    local count = 0
    if type(IsInGuild) == "function" and IsInGuild() then
        count = count + 1; if count > previousCount then table.insert(channels, "GUILD") else channels[count] = "GUILD" end
    elseif type(GetGuildInfo) == "function" and GetGuildInfo("player") then
        count = count + 1; if count > previousCount then table.insert(channels, "GUILD") else channels[count] = "GUILD" end
    end
    if type(GetNumRaidMembers) == "function" and GetNumRaidMembers() > 0 then
        count = count + 1; if count > previousCount then table.insert(channels, "RAID") else channels[count] = "RAID" end
    elseif type(GetNumPartyMembers) == "function" and GetNumPartyMembers() > 0 then
        count = count + 1; if count > previousCount then table.insert(channels, "PARTY") else channels[count] = "PARTY" end
    end
    local index
    for index = previousCount, count + 1, -1 do table.remove(channels, index) end
    return channels
end
