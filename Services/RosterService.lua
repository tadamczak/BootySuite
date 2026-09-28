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
