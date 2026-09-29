local MOS = MuklaOfficerSuite

MOS.Services.Roster = MOS.Services.Roster or {}
local RosterService = MOS.Services.Roster

local function SortByName(a, b)
    return string.lower(a.name or "") < string.lower(b.name or "")
end

local function SortText(a, b)
    return string.lower(a) < string.lower(b)
end

function RosterService.BuildSnapshot(scanStartedAt)
    MOS.Diagnostics.Count("scans")
    MOS.Database.Ensure()
    local key, guildName, realmName = MOS.Database.GetGuildIdentity()
    if not key then return nil, "not-in-guild" end

    local total = GetNumGuildMembers(true)
    if not total or total < 1 then return nil, "not-ready" end
    local members = {}
    local index
    for index = 1, total do
        local name, rank, rankIndex, level, class, zone, publicNote, officerNote, online, status = GetGuildRosterInfo(index)
        if name then
            local years, months, days, hours = 0, 0, 0, 0
            if not online and type(GetGuildRosterLastOnline) == "function" then
                years, months, days, hours = GetGuildRosterLastOnline(index)
            end
            table.insert(members, {
                name = name,
                level = level or 0,
                class = class or "",
                rank = rank or "",
                rankIndex = rankIndex,
                publicNote = publicNote or "",
                officerNote = officerNote or "",
                online = online and true or false,
                zone = zone or "",
                status = status,
                lastOnlineYears = tonumber(years) or 0,
                lastOnlineMonths = tonumber(months) or 0,
                lastOnlineDays = tonumber(days) or 0,
                lastOnlineHours = tonumber(hours) or 0,
            })
        end
    end
    if table.getn(members) < total then return nil, "not-ready" end
    table.sort(members, SortByName)

    local scanTimestamp = time()
    local scanDuration = 0
    if scanStartedAt then scanDuration = GetTime() - scanStartedAt end
    return {
        guildName = guildName,
        realmName = realmName,
        addonVersion = MOS.version,
        scannedAt = scanTimestamp,
        scannedAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp),
        scanDurationSeconds = scanDuration,
        updatedAt = scanTimestamp,
        updatedBy = UnitName("player"),
        members = members,
    }
end

function RosterService.StoreSnapshot(snapshot)
    MOS.Database.StoreRosterSnapshot(snapshot)
end

function RosterService.GetUniqueMemberValues(data, field)
    local values = {}
    local found = {}
    if data and data.members then
        local memberIndex
        for memberIndex = 1, table.getn(data.members) do
            local value = tostring(data.members[memberIndex][field] or "Unknown")
            if value == "" then value = "Unknown" end
            if not found[value] then
                found[value] = true
                table.insert(values, value)
            end
        end
    end
    table.sort(values, SortText)
    return values
end

function RosterService.FindMember(data, name)
    if not name or not data or not data.members then return nil end
    local memberIndex
    for memberIndex = 1, table.getn(data.members) do
        if data.members[memberIndex].name == name then return data.members[memberIndex] end
    end
    return nil
end

function RosterService.FindRankName(data, rankIndex)
    if not data or not data.members then return nil end
    local memberIndex
    for memberIndex = 1, table.getn(data.members) do
        if data.members[memberIndex].rankIndex == rankIndex then return data.members[memberIndex].rank end
    end
    return nil
end

function RosterService.GetLowestRankIndex(data)
    local lowest = 0
    if data and data.members then
        local memberIndex
        for memberIndex = 1, table.getn(data.members) do
            local rankIndex = tonumber(data.members[memberIndex].rankIndex) or 0
            if rankIndex > lowest then lowest = rankIndex end
        end
    end
    return lowest
end
local function Allowed(api)
    if type(api) ~= "function" then return false end
    local value = api()
    return value ~= nil and value ~= false and value ~= 0
end

function RosterService.CanManage(action, member)
    if action == "control" then return Allowed(IsGuildLeader) end
    if action == "invite" then return Allowed(CanGuildInvite) end
    if action == "publicNote" then return Allowed(CanEditPublicNote) end
    if action == "officerNote" then return Allowed(CanEditOfficerNote) end
    if action == "viewOfficerNote" then return Allowed(CanViewOfficerNote) or Allowed(CanEditOfficerNote) end
    if not member or not member.name then return false end
    if action == "whisper" or action == "group" then return member.online and member.name ~= UnitName("player") end
    local _, _, playerRank = GetGuildInfo("player")
    local rank = tonumber(member.rankIndex)
    if not rank or not playerRank or rank <= playerRank or member.name == UnitName("player") then return false end
    if action == "promote" then return Allowed(CanGuildPromote) and rank > playerRank + 1 end
    if action == "demote" then return Allowed(CanGuildDemote) and type(GuildControlGetNumRanks) == "function" and rank < GuildControlGetNumRanks() - 1 end
    if action == "remove" then return Allowed(CanGuildRemove) end
    return false
end

function RosterService.FindLiveMember(name)
    if type(GetNumGuildMembers) ~= "function" then return nil end
    local index
    for index = 1, GetNumGuildMembers(true) do
        local current, rank, rankIndex, level, class, zone, publicNote, officerNote, online = GetGuildRosterInfo(index)
        if current == name then return index, { name = current, rankIndex = rankIndex, online = online and true or false } end
    end
end

function RosterService.PerformMemberAction(action, name, value)
    local index, member = RosterService.FindLiveMember(name)
    if not index or not RosterService.CanManage(action, member) then return false end
    if action == "publicNote" and type(GuildRosterSetPublicNote) == "function" then GuildRosterSetPublicNote(index, string.sub(value or "", 1, 31))
    elseif action == "officerNote" and type(GuildRosterSetOfficerNote) == "function" then GuildRosterSetOfficerNote(index, string.sub(value or "", 1, 31))
    elseif action == "promote" and type(GuildPromoteByName) == "function" then GuildPromoteByName(name)
    elseif action == "demote" and type(GuildDemoteByName) == "function" then GuildDemoteByName(name)
    elseif action == "remove" and type(GuildUninvite) == "function" then GuildUninvite(name)
    elseif action == "group" and type(InviteByName) == "function" then InviteByName(name)
    elseif action == "whisper" and type(ChatFrame_SendTell) == "function" then ChatFrame_SendTell(name)
    else return false end
    return true
end

function RosterService.PerformSocialAction(action, name, reason)
    if not name or name == "" or (name == UnitName("player") and action ~= "target") then return false end
    if action == "whisper" and type(ChatFrame_SendTell) == "function" then ChatFrame_SendTell(name)
    elseif action == "group" and type(InviteByName) == "function" then InviteByName(name)
    elseif action == "target" and type(TargetByName) == "function" then TargetByName(name, true)
    elseif action == "ignore" and type(AddIgnore) == "function" then AddIgnore(name)
    elseif action == "report" and reason and string.find(reason, "%S") and type(NewGMTicket) == "function" then
        NewGMTicket("Player report: " .. name .. "\n" .. reason)
    else return false end
    return true
end
