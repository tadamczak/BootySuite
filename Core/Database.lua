local MOS = MuklaOfficerSuite

MOS.Database = MOS.Database or {}
local Database = MOS.Database

-- Native Raid settings use their own durable keys; they never inherit the main
-- addon layout. Compact defaults fit all eight groups in the stock raid panel.
local nativeRaidGroupFields = {
    { "Columns", 2, 1, 4, true },
    { "ShowClass", true }, { "ShowLevel", true }, { "ShowHeader", true }, { "ShowBorder", true },
    { "HeaderTextColor", { 1, 0.82, 0 } }, { "HeaderBackgroundColor", { 0.025, 0.025, 0.025 } },
    { "BorderColor", { 0.48, 0.38, 0.20 } },
    { "ShowLootMaster", true }, { "ShowRoleIcon", true }, { "ClassColors", true }, { "AutoTileWidth", true },
    { "TileWidth", 160, 160, 340 }, { "TileHeight", 15, 13, 28 }, { "HeaderHeight", 12, 12, 40 },
    { "Margin", 0, 0, 32 }, { "TileTextSize", 10, 8, 16 }, { "HeaderTextSize", 9, 8, 16 },
    { "HideEmptyGroups", false }, { "AutoAdjustVertically", false }, { "AutoAdjustHorizontally", false },
    { "BackgroundColor", { 0.025, 0.025, 0.025 } }, { "TextColor", { 1, 1, 1 } },
    { "HoverColor", { 0.12, 0.09, 0.025 } }, { "PressedColor", { 0.20, 0.14, 0.03 } },
    { "OddLightness", 5, 0, 100 },
}
Database.NativeRaidGroupKeys, Database.NativeRaidGroupSuffixes = {}, {}
local nativeIndex
for nativeIndex = 1, table.getn(nativeRaidGroupFields) do
    local suffix = nativeRaidGroupFields[nativeIndex][1]
    Database.NativeRaidGroupKeys[nativeIndex] = "nativeRaidGroup" .. suffix
    Database.NativeRaidGroupSuffixes[nativeIndex] = suffix
end

local function EnsureNativeRaidGroupSettings()
    local index
    for index = 1, table.getn(nativeRaidGroupFields) do
        local field = nativeRaidGroupFields[index]
        local key = Database.NativeRaidGroupKeys[index]
        local value, default = MuklaOfficerSuiteDB[key], field[2]
        if field[3] then
            value = tonumber(value)
            if not value or value ~= value then value = default end
            if field[5] then value = math.floor(value) end
            MuklaOfficerSuiteDB[key] = math.max(field[3], math.min(field[4], value))
        elseif type(default) == "table" then
            if type(value) ~= "table" then
                MuklaOfficerSuiteDB[key] = { default[1], default[2], default[3] }
            end
        elseif value == nil then MuklaOfficerSuiteDB[key] = default end
    end
end

function Database.Ensure()
    if type(MuklaOfficerSuiteDB) ~= "table" then
        MuklaOfficerSuiteDB = {}
    end
    if MOS.Services and MOS.Services.LootMessages then MOS.Services.LootMessages.EnsureDefaults(MuklaOfficerSuiteDB) end
    if MuklaOfficerSuiteDB.groupLayoutVersion ~= 2 then
        MuklaOfficerSuiteDB.raidGroupMargin = 0; MuklaOfficerSuiteDB.nativeRaidGroupMargin = 0
        if MuklaOfficerSuiteDB.raidGroupTileHeight == 20 then MuklaOfficerSuiteDB.raidGroupTileHeight = 22 end
        if MuklaOfficerSuiteDB.raidGroupHeaderHeight == 22 then MuklaOfficerSuiteDB.raidGroupHeaderHeight = 18 end
        if MuklaOfficerSuiteDB.raidGroupHeaderTextSize == 10 then MuklaOfficerSuiteDB.raidGroupHeaderTextSize = 9 end
        if MuklaOfficerSuiteDB.nativeRaidGroupTileHeight == 13 then MuklaOfficerSuiteDB.nativeRaidGroupTileHeight = 15 end
        if MuklaOfficerSuiteDB.nativeRaidGroupHeaderHeight == 14 then MuklaOfficerSuiteDB.nativeRaidGroupHeaderHeight = 12 end
        if MuklaOfficerSuiteDB.nativeRaidGroupHeaderTextSize == 10 then MuklaOfficerSuiteDB.nativeRaidGroupHeaderTextSize = 9 end
        MuklaOfficerSuiteDB.groupLayoutVersion = 2
    end
    if type(MuklaOfficerSuiteDB.minimap) ~= "table" then
        MuklaOfficerSuiteDB.minimap = { angle = 220, hidden = false }
    end
    if MuklaOfficerSuiteDB.hideMinimapIcon == nil then MuklaOfficerSuiteDB.hideMinimapIcon = MuklaOfficerSuiteDB.minimap.hidden and true or false end
    if MuklaOfficerSuiteDB.hideStatusVersionBar == nil then MuklaOfficerSuiteDB.hideStatusVersionBar = false end
    if MuklaOfficerSuiteDB.hideHeaderLogo == nil then MuklaOfficerSuiteDB.hideHeaderLogo = false end
    if MuklaOfficerSuiteDB.hideHeaderBar == nil then MuklaOfficerSuiteDB.hideHeaderBar = false end
    if MuklaOfficerSuiteDB.playerDetailsStyle ~= "window" then MuklaOfficerSuiteDB.playerDetailsStyle = "collapsible" end
    if MuklaOfficerSuiteDB.hideHeaderName == nil then MuklaOfficerSuiteDB.hideHeaderName = false end
    if MuklaOfficerSuiteDB.suppressLoginMessage == nil then MuklaOfficerSuiteDB.suppressLoginMessage = false end
    MuklaOfficerSuiteDB.minimap.hidden = MuklaOfficerSuiteDB.hideMinimapIcon
    if tonumber(MuklaOfficerSuiteDB.lootMasterOpacity) == nil then MuklaOfficerSuiteDB.lootMasterOpacity = 100 end
    if MuklaOfficerSuiteDB.lmAutoLootMode ~= "auto" and MuklaOfficerSuiteDB.lmAutoLootMode ~= "shift" and MuklaOfficerSuiteDB.lmAutoLootMode ~= "off" then
        MuklaOfficerSuiteDB.lmAutoLootMode = MuklaOfficerSuiteDB.lmAutoLoot and "auto" or "off"
    end
    if MuklaOfficerSuiteDB.lmAutoLoot == nil then MuklaOfficerSuiteDB.lmAutoLoot = false end
    if type(MuklaOfficerSuiteDB.lmAutoLootRarities) ~= "number" or MuklaOfficerSuiteDB.lmAutoLootRarities < 0 or MuklaOfficerSuiteDB.lmAutoLootRarities > 31 then MuklaOfficerSuiteDB.lmAutoLootRarities = 7 end
    if type(MuklaOfficerSuiteDB.lmAutoLootPresets) ~= "number" then MuklaOfficerSuiteDB.lmAutoLootPresets = 0 end
    if type(MuklaOfficerSuiteDB.lmAutoLootExceptions) ~= "string" then MuklaOfficerSuiteDB.lmAutoLootExceptions = "" end
    if type(MuklaOfficerSuiteDB.lmAutoLootInclusions) ~= "string" then MuklaOfficerSuiteDB.lmAutoLootInclusions = "" end
    if tonumber(MuklaOfficerSuiteDB.outOfFocusOpacity) == nil then MuklaOfficerSuiteDB.outOfFocusOpacity = 100 end
    if MuklaOfficerSuiteDB.chatActionLogs == nil then MuklaOfficerSuiteDB.chatActionLogs = false end
    if MuklaOfficerSuiteDB.raidClassColors == nil then MuklaOfficerSuiteDB.raidClassColors = true end
    MuklaOfficerSuiteDB.raidGroupOddLightness = math.max(0,math.min(100,tonumber(MuklaOfficerSuiteDB.raidGroupOddLightness) or 5))
    MuklaOfficerSuiteDB.raidListOddLightness = math.max(0,math.min(100,tonumber(MuklaOfficerSuiteDB.raidListOddLightness) or 5))
    if type(MuklaOfficerSuiteDB.rosterBackgroundColor) ~= "table" then MuklaOfficerSuiteDB.rosterBackgroundColor = {0.025,0.025,0.025} end
    if type(MuklaOfficerSuiteDB.rosterTextColor) ~= "table" then MuklaOfficerSuiteDB.rosterTextColor = {1,1,1} end
    if type(MuklaOfficerSuiteDB.rosterHoverColor) ~= "table" then MuklaOfficerSuiteDB.rosterHoverColor = {0.13,0.13,0.13} end
    MuklaOfficerSuiteDB.rosterOddLightness = math.max(0,math.min(100,tonumber(MuklaOfficerSuiteDB.rosterOddLightness) or 5))
    if MuklaOfficerSuiteDB.rosterClassColors == nil then MuklaOfficerSuiteDB.rosterClassColors = true end
    if MuklaOfficerSuiteDB.rosterHideSectionHeader == nil then MuklaOfficerSuiteDB.rosterHideSectionHeader = false end
    if MuklaOfficerSuiteDB.raidHideSectionHeader == nil then MuklaOfficerSuiteDB.raidHideSectionHeader = false end
    if MuklaOfficerSuiteDB.useMOSRaidTab == nil then MuklaOfficerSuiteDB.useMOSRaidTab = false end
    EnsureNativeRaidGroupSettings()
    local monitorWidth = tonumber(MuklaOfficerSuiteDB.performanceMonitorWidth)
    local monitorHeight = tonumber(MuklaOfficerSuiteDB.performanceMonitorHeight)
    if not monitorWidth or monitorWidth ~= monitorWidth or monitorWidth >= 1e300 or monitorWidth <= -1e300 then monitorWidth = 360 end
    if not monitorHeight or monitorHeight ~= monitorHeight or monitorHeight >= 1e300 or monitorHeight <= -1e300 then monitorHeight = 360 * 572 / 1024 end
    MuklaOfficerSuiteDB.performanceMonitorWidth = math.max(300, math.min(720, monitorWidth))
    MuklaOfficerSuiteDB.performanceMonitorHeight = math.max(148, math.min(460, monitorHeight))
    if MuklaOfficerSuiteDB.rosterShowClass == nil then MuklaOfficerSuiteDB.rosterShowClass = true end
    if MuklaOfficerSuiteDB.rosterShowLevel == nil then MuklaOfficerSuiteDB.rosterShowLevel = true end
    if MuklaOfficerSuiteDB.rosterShowZone == nil then MuklaOfficerSuiteDB.rosterShowZone = true end
    if MuklaOfficerSuiteDB.rosterShowRank == nil then MuklaOfficerSuiteDB.rosterShowRank = false end
    if MuklaOfficerSuiteDB.rosterShowPublicNote == nil then MuklaOfficerSuiteDB.rosterShowPublicNote = false end
    if MuklaOfficerSuiteDB.rosterShowOfficerNote == nil then MuklaOfficerSuiteDB.rosterShowOfficerNote = false end
    if MuklaOfficerSuiteDB.rosterShowLastOnline == nil then MuklaOfficerSuiteDB.rosterShowLastOnline = false end
    if MuklaOfficerSuiteDB.rosterShowClassFilter == nil then MuklaOfficerSuiteDB.rosterShowClassFilter = true end
    if MuklaOfficerSuiteDB.rosterShowRankFilter == nil then MuklaOfficerSuiteDB.rosterShowRankFilter = true end
    if MuklaOfficerSuiteDB.rosterShowSearch == nil then MuklaOfficerSuiteDB.rosterShowSearch = true end
    if MuklaOfficerSuiteDB.rosterShowOffline == nil then MuklaOfficerSuiteDB.rosterShowOffline = true end
    if MuklaOfficerSuiteDB.rosterShowColumnHeaders == nil then MuklaOfficerSuiteDB.rosterShowColumnHeaders = true end
    if MuklaOfficerSuiteDB.rosterLiveTrackingEnabled == nil then MuklaOfficerSuiteDB.rosterLiveTrackingEnabled = false end
    if MuklaOfficerSuiteDB.raidLiveTrackingEnabled == nil then MuklaOfficerSuiteDB.raidLiveTrackingEnabled = false end
    if MuklaOfficerSuiteDB.showOfflineMembers == nil then MuklaOfficerSuiteDB.showOfflineMembers = true end
    if MuklaOfficerSuiteDB.menuStyle ~= "tabs" and MuklaOfficerSuiteDB.menuStyle ~= "bottomTabs" and MuklaOfficerSuiteDB.menuStyle ~= "buttons" then MuklaOfficerSuiteDB.menuStyle = "buttons" end
    if MuklaOfficerSuiteDB.uiSkin ~= "classic" and MuklaOfficerSuiteDB.uiSkin ~= "default" then MuklaOfficerSuiteDB.uiSkin = "classic" end
    if MuklaOfficerSuiteDB.useIconTabs == nil then MuklaOfficerSuiteDB.useIconTabs = false end
    if MuklaOfficerSuiteDB.sidebarCollapsed == nil then MuklaOfficerSuiteDB.sidebarCollapsed = false end
    local raidGroupColumns = tonumber(MuklaOfficerSuiteDB.raidGroupColumns) or 2
    MuklaOfficerSuiteDB.raidGroupColumns = math.max(1, math.min(4, math.floor(raidGroupColumns)))
    if MuklaOfficerSuiteDB.raidGroupShowClass == nil then MuklaOfficerSuiteDB.raidGroupShowClass = true end
    if MuklaOfficerSuiteDB.raidGroupShowLevel == nil then MuklaOfficerSuiteDB.raidGroupShowLevel = true end
    if MuklaOfficerSuiteDB.raidGroupShowHeader == nil then MuklaOfficerSuiteDB.raidGroupShowHeader = true end
    if MuklaOfficerSuiteDB.raidGroupHideEmptyGroups == nil then MuklaOfficerSuiteDB.raidGroupHideEmptyGroups = false end
    if MuklaOfficerSuiteDB.raidGroupAutoAdjustVertically == nil then MuklaOfficerSuiteDB.raidGroupAutoAdjustVertically = false end
    if MuklaOfficerSuiteDB.raidGroupAutoAdjustHorizontally == nil then MuklaOfficerSuiteDB.raidGroupAutoAdjustHorizontally = false end
    if MuklaOfficerSuiteDB.raidGroupShowBorder == nil then MuklaOfficerSuiteDB.raidGroupShowBorder = true end
    if type(MuklaOfficerSuiteDB.raidGroupHeaderTextColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupHeaderTextColor = { 1, 0.82, 0 } end
    if type(MuklaOfficerSuiteDB.raidGroupHeaderBackgroundColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupHeaderBackgroundColor = { 0.025, 0.025, 0.025 } end
    if type(MuklaOfficerSuiteDB.raidGroupBorderColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupBorderColor = { 0.48, 0.38, 0.20 } end
    if MuklaOfficerSuiteDB.raidGroupShowLootMaster == nil then MuklaOfficerSuiteDB.raidGroupShowLootMaster = true end
    if MuklaOfficerSuiteDB.raidGroupShowRoleIcon == nil then MuklaOfficerSuiteDB.raidGroupShowRoleIcon = true end
    if MuklaOfficerSuiteDB.raidGroupClassColors == nil then MuklaOfficerSuiteDB.raidGroupClassColors = true end
    if MuklaOfficerSuiteDB.raidGroupAutoTileWidth == nil then MuklaOfficerSuiteDB.raidGroupAutoTileWidth = true end
    MuklaOfficerSuiteDB.raidGroupTileWidth = math.max(160, math.min(340, tonumber(MuklaOfficerSuiteDB.raidGroupTileWidth) or 280))
    MuklaOfficerSuiteDB.raidGroupTileHeight = math.max(14, math.min(28, tonumber(MuklaOfficerSuiteDB.raidGroupTileHeight) or 22))
    MuklaOfficerSuiteDB.raidGroupHeaderHeight = math.max(12, math.min(40, tonumber(MuklaOfficerSuiteDB.raidGroupHeaderHeight) or 18))
    MuklaOfficerSuiteDB.raidGroupMargin = math.max(0, math.min(32, tonumber(MuklaOfficerSuiteDB.raidGroupMargin) or 0))
    MuklaOfficerSuiteDB.raidGroupTileTextSize = math.max(8, math.min(16, tonumber(MuklaOfficerSuiteDB.raidGroupTileTextSize) or 10))
    MuklaOfficerSuiteDB.raidGroupHeaderTextSize = math.max(8, math.min(16, tonumber(MuklaOfficerSuiteDB.raidGroupHeaderTextSize) or 9))
    if type(MuklaOfficerSuiteDB.raidGroupBackgroundColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupBackgroundColor = { 0.025, 0.025, 0.025 } end
    if type(MuklaOfficerSuiteDB.raidGroupTextColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupTextColor = { 1, 1, 1 } end
    if type(MuklaOfficerSuiteDB.raidGroupHoverColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupHoverColor = { 0.12, 0.09, 0.025 } end
    if type(MuklaOfficerSuiteDB.raidGroupPressedColor) ~= "table" then MuklaOfficerSuiteDB.raidGroupPressedColor = { 0.20, 0.14, 0.03 } end
    if MuklaOfficerSuiteDB.raidListShowName == nil then MuklaOfficerSuiteDB.raidListShowName = true end
    if MuklaOfficerSuiteDB.raidListShowLevel == nil then MuklaOfficerSuiteDB.raidListShowLevel = true end
    if MuklaOfficerSuiteDB.raidListShowStatus == nil then MuklaOfficerSuiteDB.raidListShowStatus = true end
    if MuklaOfficerSuiteDB.raidListShowGroup == nil then MuklaOfficerSuiteDB.raidListShowGroup = true end
    if MuklaOfficerSuiteDB.raidListShowClass == nil then MuklaOfficerSuiteDB.raidListShowClass = true end
    if MuklaOfficerSuiteDB.raidListShowGuildRank == nil then MuklaOfficerSuiteDB.raidListShowGuildRank = true end
    if MuklaOfficerSuiteDB.raidListShowSR == nil then MuklaOfficerSuiteDB.raidListShowSR = true end
    if MuklaOfficerSuiteDB.raidListShowLootMaster == nil then MuklaOfficerSuiteDB.raidListShowLootMaster = true end
    if MuklaOfficerSuiteDB.raidListShowRoleIcon == nil then MuklaOfficerSuiteDB.raidListShowRoleIcon = true end
    if MuklaOfficerSuiteDB.raidListShowFilters == nil then MuklaOfficerSuiteDB.raidListShowFilters = true end
    if MuklaOfficerSuiteDB.raidListShowSearch == nil then MuklaOfficerSuiteDB.raidListShowSearch = true end
    MuklaOfficerSuiteDB.raidListRowWidth = math.max(400, math.min(1200, tonumber(MuklaOfficerSuiteDB.raidListRowWidth) or 1000))
    MuklaOfficerSuiteDB.raidListRowHeight = math.max(16, math.min(30, tonumber(MuklaOfficerSuiteDB.raidListRowHeight) or 20))
    if type(MuklaOfficerSuiteDB.raidListBackgroundColor) ~= "table" then MuklaOfficerSuiteDB.raidListBackgroundColor = { 0.025, 0.025, 0.025 } end
    if type(MuklaOfficerSuiteDB.raidListTextColor) ~= "table" then MuklaOfficerSuiteDB.raidListTextColor = { 1, 1, 1 } end
    if type(MuklaOfficerSuiteDB.raidListHoverColor) ~= "table" then MuklaOfficerSuiteDB.raidListHoverColor = { 0.12, 0.09, 0.025 } end
    if type(MuklaOfficerSuiteDB.raidListPressedColor) ~= "table" then MuklaOfficerSuiteDB.raidListPressedColor = { 0.20, 0.14, 0.03 } end
    MuklaOfficerSuiteDB.addonVersion = MOS.version
end

function Database.GetGuildIdentity()
    local guildName = GetGuildInfo("player")
    if not guildName then return nil end
    local realmName = GetRealmName() or "UnknownRealm"
    return realmName .. " - " .. guildName, guildName, realmName
end

function Database.GetSetting(key)
    Database.Ensure()
    return MuklaOfficerSuiteDB[key]
end

function Database.SetSetting(key, value)
    Database.Ensure()
    MuklaOfficerSuiteDB[key] = value
    return value
end

function Database.CountRosterMembers()
    if not MuklaOfficerSuiteDB or not MuklaOfficerSuiteDB.rosterData then return 0 end
    return table.getn(MuklaOfficerSuiteDB.rosterData.members or {})
end

function Database.GetRosterData()
    Database.Ensure()
    return MuklaOfficerSuiteDB.rosterData
end

function Database.StoreRosterSnapshot(snapshot)
    Database.Ensure()
    MuklaOfficerSuiteDB.rosterData = snapshot
    MuklaOfficerSuiteDB.guilds = nil
    MuklaOfficerSuiteDB.lastScanAt = snapshot and snapshot.scannedAt
    MuklaOfficerSuiteDB.lastScanAtText = snapshot and snapshot.scannedAtText
    MuklaOfficerSuiteDB.lastScanDurationSeconds = snapshot and snapshot.scanDurationSeconds
end

function Database.GetRaidAttendance()
    Database.Ensure()
    return MuklaOfficerSuiteDB.raidAttendance
end

function Database.StoreRaidAttendance(attendance)
    Database.Ensure()
    local previous = MuklaOfficerSuiteDB.raidAttendance
    MuklaOfficerSuiteDB.raidAttendance = attendance
    if Database.onRaidAttendanceChanged then Database.onRaidAttendanceChanged(previous, attendance) end
    return attendance
end

function Database.GetLootRules()
    Database.Ensure()
    if type(MuklaOfficerSuiteDB.lootRulesByRank) ~= "table" then MuklaOfficerSuiteDB.lootRulesByRank = {} end
    return MuklaOfficerSuiteDB.lootRulesByRank
end

function Database.SaveLootRules(rules)
    Database.Ensure()
    local saved = {}
    local rankIndex, rule
    for rankIndex, rule in pairs(rules or {}) do
        saved[rankIndex] = {
            sr = rule.sr and true or false,
            reyCoin = rule.reyCoin and true or false,
            csr = rule.csr and true or false,
            highlyContested = rule.highlyContested and true or false,
        }
    end
    MuklaOfficerSuiteDB.lootRulesByRank = saved
end

local defaultHighlyContestedItems = {
    "Heavy Dark Iron Ring", "Lost Dark Iron Chain", "Fireguard Shoulders", "Runed Wardstone",
    "Talisman of Ephemeral Power", "Wild Growth Spaulders", "Molten Emberstone",
    "Sigil of Ancient Accord", "Onslaught Girdle", "Band of Accuria",
    "Yoxtez, Black Breath of the Dragonflight", "Broodwarden's Bulwarkblade",
}

function Database.GetHighlyContestedItems()
    Database.Ensure()
    if type(MuklaOfficerSuiteDB.highlyContestedItems) ~= "table"
        or (table.getn(MuklaOfficerSuiteDB.highlyContestedItems) == 0 and not MuklaOfficerSuiteDB.highlyContestedItemsCustomized) then
        local items = {}
        local index
        for index = 1, table.getn(defaultHighlyContestedItems) do items[index] = defaultHighlyContestedItems[index] end
        MuklaOfficerSuiteDB.highlyContestedItems = items
    end
    return MuklaOfficerSuiteDB.highlyContestedItems
end

function Database.SaveHighlyContestedItems(items)
    Database.Ensure()
    local saved, seen, count = {}, {}, 0
    local index
    for index = 1, table.getn(items or {}) do
        local name = string.gsub(tostring(items[index] or ""), "^%s+", "")
        name = string.gsub(name, "%s+$", "")
        local key = string.lower(name)
        if name ~= "" and not seen[key] then count = count + 1; saved[count] = name; seen[key] = true end
    end
    MuklaOfficerSuiteDB.highlyContestedItems = saved
    MuklaOfficerSuiteDB.highlyContestedItemsCustomized = true
    return count
end

function Database.StoreSoftReserveSnapshot(snapshot)
    Database.Ensure()
    if not snapshot or not snapshot.id then return false end
    if type(MuklaOfficerSuiteDB.softReserveHistory) ~= "table" then MuklaOfficerSuiteDB.softReserveHistory = { order = {}, raids = {} } end
    local history = MuklaOfficerSuiteDB.softReserveHistory
    if type(history.order) ~= "table" then history.order = {} end
    if type(history.raids) ~= "table" then history.raids = {} end
    local index
    for index = table.getn(history.order), 1, -1 do if history.order[index] == snapshot.id then table.remove(history.order, index) end end
    table.insert(history.order, 1, snapshot.id); history.raids[snapshot.id] = snapshot
    while table.getn(history.order) > 10 do
        local expiredId = table.remove(history.order); history.raids[expiredId] = nil
    end
    return true
end

function Database.GetSoftReserveHistory()
    Database.Ensure()
    local history = MuklaOfficerSuiteDB.softReserveHistory
    local snapshots = {}
    if not history or not history.order or not history.raids then return snapshots end
    local index
    for index = 1, math.min(10, table.getn(history.order)) do
        local snapshot = history.raids[history.order[index]]
        if snapshot then table.insert(snapshots, snapshot) end
    end
    return snapshots
end

function Database.HasSoftReserveSnapshot(snapshotId)
    Database.Ensure()
    local wanted = string.lower(tostring(snapshotId or ""))
    local history = MuklaOfficerSuiteDB.softReserveHistory
    if wanted == "" or not history or type(history.raids) ~= "table" then return false end
    local id
    for id in pairs(history.raids) do if string.lower(tostring(id)) == wanted then return true end end
    return false
end

function Database.DeleteSoftReserveSnapshot(snapshotId)
    Database.Ensure()
    local history = MuklaOfficerSuiteDB.softReserveHistory
    if not snapshotId or not history or type(history.order) ~= "table" or type(history.raids) ~= "table" or not history.raids[snapshotId] then return false end
    history.raids[snapshotId] = nil
    local index
    for index = table.getn(history.order), 1, -1 do if history.order[index] == snapshotId then table.remove(history.order, index) end end
    return true
end

function Database.StoreRaidStatistic(entry)
    Database.Ensure()
    if not entry or not entry.id then return false end
    if type(MuklaOfficerSuiteDB.raidStatistics) ~= "table" then MuklaOfficerSuiteDB.raidStatistics = { order = {}, raids = {} } end
    local history = MuklaOfficerSuiteDB.raidStatistics
    if type(history.order) ~= "table" then history.order = {} end
    if type(history.raids) ~= "table" then history.raids = {} end
    local index
    for index = table.getn(history.order), 1, -1 do if history.order[index] == entry.id then table.remove(history.order, index) end end
    table.insert(history.order, 1, entry.id); history.raids[entry.id] = entry
    while table.getn(history.order) > 50 do local expired = table.remove(history.order); history.raids[expired] = nil end
    return true
end

function Database.GetRaidStatistics()
    Database.Ensure()
    local result = {}
    local history = MuklaOfficerSuiteDB.raidStatistics
    if not history or type(history.order) ~= "table" or type(history.raids) ~= "table" then return result end
    local index
    for index = 1, table.getn(history.order) do
        local entry = history.raids[history.order[index]]
        if entry then result[table.getn(result) + 1] = entry end
    end
    return result
end

function Database.DeleteRaidStatistic(raidId)
    Database.Ensure()
    local history = MuklaOfficerSuiteDB.raidStatistics
    if not raidId or not history or type(history.order) ~= "table" or type(history.raids) ~= "table" or not history.raids[raidId] then return false end
    history.raids[raidId] = nil
    local index
    for index = table.getn(history.order), 1, -1 do
        if history.order[index] == raidId then table.remove(history.order, index) end
    end
    return true
end

function Database.HasRaidStatistic(raidId)
    Database.Ensure()
    local history=MuklaOfficerSuiteDB.raidStatistics
    local wanted=string.lower(tostring(raidId or ""))
    if wanted=="" or not history or type(history.raids)~="table" then return false end
    local id
    for id in pairs(history.raids) do if string.lower(tostring(id))==wanted then return true end end
    return false
end

function Database.UpdateRaidStatisticFlags(raidId, attendanceEnabled, csrEnabled)
    Database.Ensure()
    local history = MuklaOfficerSuiteDB.raidStatistics
    local entry = history and history.raids and history.raids[raidId]
    if not entry then return false end
    entry.attendanceEnabled = attendanceEnabled and true or false
    entry.csrEnabled = csrEnabled and true or false
    return true
end

function Database.UpdateRaidStatistic(raidId,members,attendanceEnabled,csrEnabled)
    Database.Ensure()
    local history=MuklaOfficerSuiteDB.raidStatistics
    local entry=history and history.raids and history.raids[raidId]
    if not entry or type(members)~="table" then return false end
    entry.members=members;entry.attendanceEnabled=attendanceEnabled and true or false;entry.csrEnabled=csrEnabled and true or false
    return true
end

function Database.ResetRaidGroupView()
    Database.Ensure()
    MuklaOfficerSuiteDB.raidGroupOddLightness = 5
    MuklaOfficerSuiteDB.raidGroupColumns = 2
    MuklaOfficerSuiteDB.raidGroupHideEmptyGroups = false
    MuklaOfficerSuiteDB.raidGroupAutoAdjustVertically = false
    MuklaOfficerSuiteDB.raidGroupAutoAdjustHorizontally = false
    MuklaOfficerSuiteDB.raidGroupShowClass = true
    MuklaOfficerSuiteDB.raidGroupShowLevel = true
    MuklaOfficerSuiteDB.raidGroupShowHeader = true
    MuklaOfficerSuiteDB.raidGroupShowBorder = true
    MuklaOfficerSuiteDB.raidGroupHeaderTextColor = { 1, 0.82, 0 }
    MuklaOfficerSuiteDB.raidGroupHeaderBackgroundColor = { 0.025, 0.025, 0.025 }
    MuklaOfficerSuiteDB.raidGroupBorderColor = { 0.48, 0.38, 0.20 }
    MuklaOfficerSuiteDB.raidGroupClassColors = true
    MuklaOfficerSuiteDB.raidGroupShowLootMaster = true
    MuklaOfficerSuiteDB.raidGroupShowRoleIcon = true
    MuklaOfficerSuiteDB.raidGroupAutoTileWidth = true
    MuklaOfficerSuiteDB.raidGroupTileWidth = 280
    MuklaOfficerSuiteDB.raidGroupTileHeight = 22
    MuklaOfficerSuiteDB.raidGroupHeaderHeight = 18
    MuklaOfficerSuiteDB.raidGroupMargin = 0
    MuklaOfficerSuiteDB.raidGroupTileTextSize = 10
    MuklaOfficerSuiteDB.raidGroupHeaderTextSize = 9
    MuklaOfficerSuiteDB.raidGroupBackgroundColor = { 0.025, 0.025, 0.025 }
    MuklaOfficerSuiteDB.raidGroupTextColor = { 1, 1, 1 }
    MuklaOfficerSuiteDB.raidGroupHoverColor = { 0.12, 0.09, 0.025 }
    MuklaOfficerSuiteDB.raidGroupPressedColor = { 0.20, 0.14, 0.03 }
end

function Database.ResetNativeRaidGroupView()
    Database.Ensure()
    local index
    for index = 1, table.getn(Database.NativeRaidGroupKeys) do
        MuklaOfficerSuiteDB[Database.NativeRaidGroupKeys[index]] = nil
    end
    EnsureNativeRaidGroupSettings()
end

function Database.ResetRaidListView()
    Database.Ensure()
    MuklaOfficerSuiteDB.raidListOddLightness = 5
    MuklaOfficerSuiteDB.raidListShowName = true
    MuklaOfficerSuiteDB.raidListShowLevel = true
    MuklaOfficerSuiteDB.raidListShowStatus = true
    MuklaOfficerSuiteDB.raidListShowGroup = true
    MuklaOfficerSuiteDB.raidListShowClass = true
    MuklaOfficerSuiteDB.raidListShowGuildRank = true
    MuklaOfficerSuiteDB.raidListShowSR = true
    MuklaOfficerSuiteDB.raidListShowLootMaster = true
    MuklaOfficerSuiteDB.raidListShowRoleIcon = true
    MuklaOfficerSuiteDB.raidListShowFilters = true
    MuklaOfficerSuiteDB.raidListShowSearch = true
    MuklaOfficerSuiteDB.raidListRowWidth = 1000
    MuklaOfficerSuiteDB.raidListRowHeight = 20
    MuklaOfficerSuiteDB.raidListBackgroundColor = { 0.025, 0.025, 0.025 }
    MuklaOfficerSuiteDB.raidListTextColor = { 1, 1, 1 }
    MuklaOfficerSuiteDB.raidListHoverColor = { 0.12, 0.09, 0.025 }
    MuklaOfficerSuiteDB.raidListPressedColor = { 0.20, 0.14, 0.03 }
end
