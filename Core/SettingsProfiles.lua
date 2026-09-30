local MOS = MuklaOfficerSuite
MOS.Core.SettingsProfiles = {}
local Profiles = MOS.Core.SettingsProfiles

-- Explicit allowlist excludes roster, raid history, loot and derived UI state.
local keys = {
    "rosterHideSectionHeader", "raidHideSectionHeader",
    "rosterShowClass", "rosterShowLevel", "rosterShowZone", "rosterShowRank", "rosterShowPublicNote", "rosterShowOfficerNote", "rosterShowLastOnline", "rosterShowClassFilter", "rosterShowRankFilter", "rosterShowSearch", "rosterShowOffline", "rosterShowColumnHeaders",
    "hideHeaderBar", "hideMinimapIcon", "hideStatusVersionBar", "hideHeaderLogo", "hideHeaderName", "suppressLoginMessage", "lootMasterOpacity", "lmAutoLoot", "lmAutoLootMode", "lmAutoLootRarities", "lmAutoLootExceptions", "lmAutoLootPresets", "outOfFocusOpacity", "chatActionLogs",
    "playerDetailsStyle", "raidClassColors", "rosterClassColors", "rosterLiveTrackingEnabled", "raidLiveTrackingEnabled", "showOfflineMembers", "menuStyle", "useIconTabs", "uiSkin",
    "raidGroupColumns", "raidGroupShowClass", "raidGroupShowLevel", "raidGroupShowHeader", "raidGroupShowLootMaster", "raidGroupShowRoleIcon",
    "raidGroupClassColors", "raidGroupAutoTileWidth", "raidGroupTileWidth", "raidGroupTileHeight", "raidGroupHeaderHeight", "raidGroupMargin",
    "raidGroupTileTextSize", "raidGroupHeaderTextSize", "raidGroupBackgroundColor", "raidGroupTextColor", "raidGroupHoverColor", "raidGroupPressedColor",
    "raidListShowName", "raidListShowLevel", "raidListShowStatus", "raidListShowGroup", "raidListShowClass", "raidListShowGuildRank", "raidListShowSR",
    "raidListShowLootMaster", "raidListShowRoleIcon", "raidListShowFilters", "raidListShowSearch", "raidListRowWidth", "raidListRowHeight",
    "raidListBackgroundColor", "raidListTextColor", "raidListHoverColor", "raidListPressedColor",
}
table.sort(keys)

local function Store()
    MOS.Database.Ensure()
    if type(MuklaOfficerSuiteDB.settingsProfiles) ~= "table" then MuklaOfficerSuiteDB.settingsProfiles = {} end
    return MuklaOfficerSuiteDB.settingsProfiles
end

local function Name(value)
    local name = string.gsub(string.gsub(tostring(value or ""), "^%s+", ""), "%s+$", "")
    if name == "" or string.len(name) > 64 or string.find(name, "[%c]") then return nil end
    return name
end

local function Copy(value)
    if type(value) == "table" then return { value[1], value[2], value[3] } end
    return value
end

function Profiles.List()
    local names, name = {}, nil
    for name in pairs(Store()) do table.insert(names, name) end
    table.sort(names)
    return names
end

local function Write(name, add)
    name = Name(name)
    if not name then return false, "Enter a profile name (1-64 characters)." end
    local profiles = Store()
    if add and profiles[name] then return false, "This profile already exists. Use Save to update it." end
    if not add and not profiles[name] then return false, "Profile not found. Use Add first." end
    local settings, index = {}, nil
    for index = 1, table.getn(keys) do settings[keys[index]] = Copy(MuklaOfficerSuiteDB[keys[index]]) end
    profiles[name] = { version = 1, settings = settings }
    return true, "Saved profile: " .. name
end

function Profiles.CanAdd(name)
    name = Name(name)
    if not name then return false, "Enter a profile name (1-64 characters)." end
    if Store()[name] then return false, "This profile already exists." end
    return true
end

function Profiles.Add(name)
    local ok, message = Write(name, true)
    if ok then Profiles.Load(name) end
    return ok, message
end
function Profiles.Save(name) return Write(name, false) end

function Profiles.GetCurrent()
    local profiles = Store()
    if not MuklaOfficerSuiteDB.currentSettingsProfile then
        local name, index = "Default", 1
        while profiles[name] do index = index + 1; name = "Default " .. index end
        Write(name, true)
        MuklaOfficerSuiteDB.currentSettingsProfile = name
    end
    return MuklaOfficerSuiteDB.currentSettingsProfile
end

function Profiles.Exists(name) return Store()[Name(name) or ""] ~= nil end

function Profiles.IsDirty()
    local profile = Store()[Profiles.GetCurrent()]
    if not profile then return true end
    local index
    for index = 1, table.getn(keys) do
        local saved, live = profile.settings[keys[index]], MuklaOfficerSuiteDB[keys[index]]
        if type(saved) == "table" and type(live) == "table" then
            if saved[1] ~= live[1] or saved[2] ~= live[2] or saved[3] ~= live[3] then return true end
        elseif saved ~= live then return true end
    end
    return false
end

function Profiles.SaveCurrent()
    local name = Profiles.GetCurrent()
    return Write(name, not Profiles.Exists(name))
end

function Profiles.Delete(name)
    name = Name(name)
    if not name or not Store()[name] then return false, "Profile not found." end
    Store()[name] = nil
    -- Keep live settings and identity; explicit Save can recreate a deleted current profile.
    return true, "Deleted profile: " .. name
end

function Profiles.Load(name)
    local profile = Store()[Name(name) or ""]
    if not profile or profile.version ~= 1 or type(profile.settings) ~= "table" then return false, "Profile not found or unsupported." end
    local index
    for index = 1, table.getn(keys) do
        local key = keys[index]
        if profile.settings[key] ~= nil then MuklaOfficerSuiteDB[key] = Copy(profile.settings[key]) end
    end
    if profile.settings.lmAutoLootMode == nil then MuklaOfficerSuiteDB.lmAutoLootMode = profile.settings.lmAutoLoot and "auto" or "off" end
    if profile.settings.lmAutoLootRarities == nil then MuklaOfficerSuiteDB.lmAutoLootRarities = 7 end
    if profile.settings.lmAutoLootPresets == nil then MuklaOfficerSuiteDB.lmAutoLootPresets = 0 end
    if profile.settings.lmAutoLootExceptions == nil then MuklaOfficerSuiteDB.lmAutoLootExceptions = "" end
    MOS.Database.Ensure()
    MuklaOfficerSuiteDB.currentSettingsProfile = Name(name)
    return true, "Loaded profile: " .. Name(name)
end

local function Encode(value)
    if type(value) == "string" then return string.format("%q", value) end
    if type(value) == "table" then return "[" .. tostring(value[1]) .. "," .. tostring(value[2]) .. "," .. tostring(value[3]) .. "]" end
    return tostring(value)
end

function Profiles.Export(name)
    name = Name(name)
    local profile = Store()[name or ""]
    if not profile or profile.version ~= 1 or type(profile.settings) ~= "table" then return nil, "Profile not found or unsupported. Save or Add it first." end
    local lines, index = { "MOS_SETTINGS_PROFILE_V1", "name=" .. Encode(name) }, nil
    for index = 1, table.getn(keys) do
        local key = keys[index]
        if profile.settings[key] ~= nil then table.insert(lines, key .. "=" .. Encode(profile.settings[key])) end
    end
    return table.concat(lines, "\n")
end
