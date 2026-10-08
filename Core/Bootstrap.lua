BootySuite = {version = "1.0.0-dev.12", Core = {}, Modules = {}, Services = {}, Database = {}}
local Suite, Lib = BootySuite, BootyLib
Suite.UI = Lib.UI
Suite.Core.Compatibility = Lib.Core.Compatibility
Suite.Services.Version = Lib.Services.Version
local defaults = {menuStyle = "buttons", useIconTabs = false, sidebarCollapsed = false, hideHeaderBar = false,
    hideHeaderLogo = false, hideHeaderName = false, hideStatusVersionBar = false, hideMinimapIcon = false}
Lib.Data.RegisterOwner("suite", "BootySuiteDB", function(key)
    return string.sub(key, 1, 6) == "window" or defaults[key] ~= nil or key == "minimap" or key == "menuProducts"
end, function(db)
    for key, value in pairs(defaults) do if db[key] == nil then db[key] = value end end
    if type(db.minimap) ~= "table" then db.minimap = {angle = 220} end
    if type(db.menuProducts) ~= "table" then db.menuProducts = {} end
end)
function Suite.GetDatabase() return Lib.Data.Ensure("suite") end
Suite.Database.Ensure = Suite.GetDatabase
function Suite.GetSetting(key)
    local owner = Lib.Data.GetOwner("lib")
    if owner and owner.OwnsField(key) then return Lib.Data.Ensure("lib")[key] end
    return Suite.GetDatabase()[key]
end
function Suite.SetSetting(key, value)
    local owner = Lib.Data.GetOwner("lib")
    if owner and owner.OwnsField(key) then Lib.Data.Ensure("lib")[key] = value else Suite.GetDatabase()[key] = value end
    if Suite.RefreshLayout then Suite.RefreshLayout() end
end
