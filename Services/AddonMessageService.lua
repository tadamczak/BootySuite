local MOS = MuklaOfficerSuite

MOS.Services.AddonMessage = MOS.Services.AddonMessage or {}
local AddonMessage = MOS.Services.AddonMessage

AddonMessage.PREFIX = "MOS"

local function CleanPart(value)
    return string.gsub(tostring(value or ""), "|", "")
end

function AddonMessage.Encode(topic, action, payload)
    return CleanPart(topic) .. "|" .. CleanPart(action) .. "|" .. CleanPart(payload)
end

function AddonMessage.Decode(prefix, message)
    if prefix ~= AddonMessage.PREFIX or type(message) ~= "string" then return nil end
    local topic, action, payload = string.match(message, "^([^|]+)|([^|]+)|(.*)$")
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
    local count = 0
    if type(IsInGuild) == "function" and IsInGuild() then
        count = count + 1; channels[count] = "GUILD"
    elseif type(GetGuildInfo) == "function" and GetGuildInfo("player") then
        count = count + 1; channels[count] = "GUILD"
    end
    if type(GetNumRaidMembers) == "function" and GetNumRaidMembers() > 0 then
        count = count + 1; channels[count] = "RAID"
    elseif type(GetNumPartyMembers) == "function" and GetNumPartyMembers() > 0 then
        count = count + 1; channels[count] = "PARTY"
    end
    local index
    for index = count + 1, table.getn(channels) do channels[index] = nil end
    return channels
end
