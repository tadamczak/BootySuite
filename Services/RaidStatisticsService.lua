local MOS = MuklaOfficerSuite

MOS.Services = MOS.Services or {}
local RaidStatistics = {}
MOS.Services.RaidStatistics = RaidStatistics

local LOOT_RANKS = { macaque = true, guest = true, alt = true, baboon = true, chimp = true, silverback = true }
local RAID_NAMES = { "Blackwing Lair", "Molten Core", "Onyxia's Lair", "Karazhan10", "Zul'Gurub", "Other" }

function RaidStatistics.GetRaidNames() return RAID_NAMES end

local function FindLootRank(value)
    local note = string.lower(tostring(value or ""))
    local word
    for word in string.gfind(note, "%a+") do if LOOT_RANKS[word] then return word end end
    return nil
end

local function ResolveLootRank(member)
    local guildRank = string.lower(tostring(member and member.guildRank or ""))
    if guildRank ~= "officer wukong" then return member and member.guildRank or "Guest" end
    return "chimp"
end

function RaidStatistics.BuildEntry(attendance, saveOptions)
    if not attendance or type(attendance.members) ~= "table" then return nil end
    local importInfo = attendance.softReserveImport
    local raidId = attendance.snapshotId or (importInfo and importInfo.id)
    if not raidId then return nil end
    saveOptions = saveOptions or {}
    local entry = {
        id = raidId, raidName = attendance.raidName or "Unknown zone", savedAt = time(), members = {},
        statisticsEnabled = saveOptions.saveRaidStatistics ~= false,
        attendanceEnabled = saveOptions.saveAttendance ~= false,
        csrEnabled = saveOptions.saveCSR ~= false,
    }
    local memberIndex, lootIndex, itemIndex
    for memberIndex = 1, table.getn(attendance.members) do
        local member = attendance.members[memberIndex]
        local lootCount = 0
        for lootIndex = 1, table.getn(member.loot or {}) do lootCount = lootCount + (tonumber(member.loot[lootIndex].count) or 1) end
        local savedMember = {
            name = member.name, class = member.class or "", guildRank = member.guildRank ~= "" and member.guildRank or "Guest",
            lootRank = ResolveLootRank(member),
            srCount = table.getn(member.srItemIds or {}), lootCount = lootCount, srItems = {}, lootItems = {},
        }
        for itemIndex = 1, table.getn(member.srItemIds or {}) do savedMember.srItems[itemIndex] = { itemId = tonumber(member.srItemIds[itemIndex]), count = 1 } end
        for lootIndex = 1, table.getn(member.loot or {}) do
            local loot = member.loot[lootIndex]
            savedMember.lootItems[lootIndex] = { itemId = tonumber(loot.itemId), name = loot.name, count = tonumber(loot.count) or 1 }
        end
        entry.members[memberIndex] = savedMember
    end
    return entry
end

local function AppendItems(target, source, raid)
    local index
    for index = 1, table.getn(source or {}) do
        local item = source[index]
        local itemId = tonumber(item.itemId)
        if itemId then
            target[table.getn(target) + 1] = {
                itemId = itemId, name = item.name, count = tonumber(item.count) or 1,
                raidId = raid.id, savedAt = raid.savedAt,
                context = tostring(raid.id or "-") .. " | " .. date("%Y-%m-%d", tonumber(raid.savedAt) or 0),
            }
        end
    end
end

local function AppendMissingReserve(target, raid)
    target[table.getn(target) + 1] = {
        missing = true, raidId = raid.id, savedAt = raid.savedAt,
        context = tostring(raid.id or "-") .. " | " .. date("%Y-%m-%d", tonumber(raid.savedAt) or 0),
    }
end

function RaidStatistics.BuildSummary(entries, selectedId)
    local summary = { raids = 0, participations = 0, uniquePlayers = 0, sr = 0, loot = 0, players = {} }
    local byName = {}
    local raidIndex, memberIndex
    for raidIndex = 1, table.getn(entries or {}) do
        local raid = entries[raidIndex]
        if not selectedId or raid.id == selectedId then
            summary.raids = summary.raids + 1
            for memberIndex = 1, table.getn(raid.members or {}) do
                local member = raid.members[memberIndex]
                local key = string.lower(member.name or "")
                local player = byName[key]
                if not player then
                    player = { name = member.name, class = member.class, guildRank = string.lower(member.guildRank or "") == "officer wukong" and "Officer (Chimp)" or member.guildRank, raids = 0, sr = 0, loot = 0, srItems = {}, lootItems = {} }
                    byName[key] = player; summary.players[table.getn(summary.players) + 1] = player
                end
                if raid.attendanceEnabled ~= false then player.raids = player.raids + 1
                elseif selectedId then player.attendanceOff = true end
                player.sr = player.sr + (tonumber(member.srCount) or 0); player.loot = player.loot + (tonumber(member.lootCount) or 0)
                if table.getn(member.srItems or {}) > 0 then AppendItems(player.srItems, member.srItems, raid) else AppendMissingReserve(player.srItems, raid) end
                AppendItems(player.lootItems, member.lootItems, raid)
                if raid.attendanceEnabled ~= false then summary.participations = summary.participations + 1 end
                summary.sr = summary.sr + (tonumber(member.srCount) or 0); summary.loot = summary.loot + (tonumber(member.lootCount) or 0)
            end
        end
    end
    summary.uniquePlayers = table.getn(summary.players)
    table.sort(summary.players, function(a, b) return string.lower(a.name or "") < string.lower(b.name or "") end)
    return summary
end

local function ParseDate(value, endOfDay)
    value = tostring(value or "")
    if value == "" then return nil end
    local _, _, year, month, day = string.find(value, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if not year then return false end
    local stamp = time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = endOfDay and 23 or 0, min = endOfDay and 59 or 0, sec = endOfDay and 59 or 0 })
    if not stamp or date("%Y-%m-%d", stamp) ~= value then return false end
    return stamp
end

function RaidStatistics.FilterEntries(entries, fromText, toText, target, selectedRaids, searchText)
    local fromStamp, toStamp = ParseDate(fromText, false), ParseDate(toText, true)
    if fromStamp == false or toStamp == false then return nil, "Use date format YYYY-MM-DD." end
    if fromStamp and toStamp and fromStamp > toStamp then return nil, "The From date must be before the To date." end
    local index
    for index = table.getn(target), 1, -1 do target[index] = nil end
    for index = 1, table.getn(entries or {}) do
        local savedAt = tonumber(entries[index].savedAt) or 0
        local raidName = tostring(entries[index].raidName or "Other")
        local known = false
        local raidIndex
        for raidIndex = 1, table.getn(RAID_NAMES) do if RAID_NAMES[raidIndex] == raidName then known = true; break end end
        local filterName = known and raidName or "Other"
        local query = string.lower(tostring(searchText or ""))
        local matchesSearch = query == "" or string.find(string.lower(tostring(entries[index].id or "")), query, 1, true)
            or string.find(string.lower(raidName), query, 1, true)
        if not matchesSearch then
            local memberIndex
            for memberIndex = 1, table.getn(entries[index].members or {}) do
                if string.find(string.lower(tostring(entries[index].members[memberIndex].name or "")), query, 1, true) then matchesSearch = true; break end
            end
        end
        if entries[index].statisticsEnabled ~= false and (not selectedRaids or selectedRaids[filterName]) and matchesSearch
            and (not fromStamp or savedAt >= fromStamp) and (not toStamp or savedAt <= toStamp) then target[table.getn(target) + 1] = entries[index] end
    end
    return target
end
