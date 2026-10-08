local Suite, Lib, UI = BootySuite, BootyLib, BootyLib.UI.Components
local Shell = {id = "suite", name = "BootySuite", apiVersion = 1, hosts = {}, entries = {}, views = {}, controllers = {}, order = {}, providers = {}}
Suite.Shell = Shell
local preferredOrder = {"roster", "raid", "statistics", "raidStatistics", "csr", "profiler", "plugins", "about"}
local preferredMenuProducts = {"guild", "raider", "profiler"}
function Shell.IsInMenu(productId)
    local choices = Suite.GetDatabase().menuProducts
    return not choices or choices[productId] ~= false
end
local function Available(id)
    local entry = Shell.entries[id]
    return entry and not entry.product.stopped and not entry.product.failure and (not entry.view.IsAvailable or entry.view.IsAvailable()) or false
end
local function InMenu(id)
    local entry = Shell.entries[id]
    return entry and Shell.IsInMenu(entry.product.id) and Available(id) or false
end
local function Mount(id)
    if Shell.views[id] then return Shell.views[id] end
    local parent = UI.CreateContainer(nil, Shell.dashboard.pageHost)
    Shell.views[id] = parent
    parent.mosContentPanel = Shell.dashboard.contentPanel
    parent:SetPoint("TOPLEFT", Shell.dashboard.pageHost, "TOPLEFT", 1.5, -3)
    parent:SetPoint("BOTTOMRIGHT", Shell.dashboard.pageHost, "BOTTOMRIGHT", -1.5, 1.5)
    parent:Hide()
    return parent
end
local function Dock(id)
    local parent = Shell.views[id]
    if not parent then return end
    parent:SetParent(Shell.dashboard.pageHost); parent:ClearAllPoints()
    parent.mosWidthOwner, parent.mosWidthInset, parent.mosHeightOwner, parent.mosHeightInset = nil, nil, nil, nil
    parent.mosContentPanel = Shell.dashboard.contentPanel
    parent:SetPoint("TOPLEFT", Shell.dashboard.pageHost, "TOPLEFT", 1.5, -3)
    parent:SetPoint("BOTTOMRIGHT", Shell.dashboard.pageHost, "BOTTOMRIGHT", -1.5, 1.5)
    if UI.WindowStack then UI.WindowStack.Sync(parent) end
end
function Shell.GetView(id)
    local entry = Shell.entries[id]
    if not entry then return nil end
    local controller = Shell.controllers[id]
    if controller then return controller end
    local host = Shell.hosts[entry.product.id]
    local parent = Mount(id)
    Dock(id)
    if host.GetView then controller = host.GetView(id)
    else controller = entry.view.create(parent, host) end
    if controller then Shell.controllers[id] = controller end
    return controller
end
function Shell.OpenView(id)
    if not Available(id) then Lib.Print("This section is unavailable. Guild sections require guild membership."); return false end
    local controller = Shell.GetView(id)
    if not controller then return false end
    local entry, host = Shell.entries[id], Shell.hosts[Shell.entries[id].product.id]
    if not Shell.IsInMenu(entry.product.id) then return host.OpenDetachedView(id) end
    if Shell.active and Shell.active ~= id then
        local previous = Shell.controllers[Shell.active]
        if previous and previous.Hide then
            local ready, reason = previous:Hide()
            if ready == false then return false, reason end
        end
        if Shell.views[Shell.active] then Shell.views[Shell.active]:Hide() end
    end
    Shell.active = id; UI.Dashboard.OpenWindow(Shell.dashboard)
    host.window = Shell.dashboard.frame
    Shell.views[id]:Show(); if controller.Show then controller:Show() end
    if Shell.navigation then Shell.navigation.SetActive(id) end
    Suite.RefreshLayout(); return controller
end
function Shell.OpenSettings(owner)
    -- UI handlers pass no explicit owner; detached product cogs do.
    if not owner or not owner.GetFrameLevel then owner = Shell.dashboard and Shell.dashboard.frame end
    return Lib.Core.SettingsHost.Open(Shell, {integrated = true, window = owner}, Shell.providers)
end
function Shell.Initialize()
    local db = Suite.GetDatabase()
    Shell.dashboard = UI.Dashboard.CreateWindow(Suite.version, {name = "BootySuiteDashboard", title = "Booty Suite"})
    local view = Shell.dashboard
    Shell.versionCheck = Suite.Modules.VersionCheck.Create({addonVersion = Suite.version, releaseVersion = Suite.version, printMessage = Lib.Print, owner = view.frame,
        onStatusChanged = function(value, stamp) local about = Shell.controllers.about; if about and about.SetUpdateStatus then about:SetUpdateStatus(value, stamp) end end})
    view.statusBar = UI.Dashboard.CreateStatusBar(view.frame)
    view.frame.mosStatusBar = view.statusBar
    UI.Dashboard.RestoreGeometry(view.frame, db)
    view.frame:Hide()
    view.settingsButton:SetScript("OnClick", Shell.OpenSettings)
    local function SaveGeometry()
        db.windowWidth, db.windowHeight = view.frame:GetWidth(), view.frame:GetHeight()
        db.windowLeft, db.windowBottom = view.frame:GetLeft(), view.frame:GetBottom()
    end
    UI.Dashboard.BindWindow(view, {isLootMasterMode = function() return false end, isTabLayout = function() return db.menuStyle ~= "buttons" end,
        statusBar = view.statusBar,
        saveGeometry = SaveGeometry, saveLootGeometry = SaveGeometry, refreshLayout = function() Suite.RefreshLayout() end,
        applyLayout = function() Suite.RefreshLayout() end, applyOrRefreshLayout = function() Suite.RefreshLayout() end,
        setNavigationVisible = function(shown)
            if Shell.navigation then for _, button in pairs(Shell.navigation.buttons) do if shown and button.navigationIncluded ~= false then button:Show() else button:Hide() end end end
            local controller = Shell.active and Shell.controllers[Shell.active]
            if controller then if shown and controller.Show then controller:Show() elseif not shown and controller.Hide then controller:Hide() end end
        end})
    local hide = view.frame:GetScript("OnHide")
    view.frame:SetScript("OnHide", function()
        if hide then hide() end
        if Shell.active and Shell.controllers[Shell.active] and Shell.controllers[Shell.active].Hide then Shell.controllers[Shell.active]:Hide() end
    end)
    Shell.minimap = UI.Dashboard.CreateMinimapButton({name = "BootySuiteMinimapButton", title = "Booty Suite", ensureDatabase = Suite.GetDatabase,
        getAngle = function() return db.minimap.angle end, getPosition = function() return db.minimap.x, db.minimap.y end,
        setPosition = function(x, y) db.minimap.x, db.minimap.y = x, y end,
        onOpen = function()
            if view.frame:IsVisible() and not view.minimized then view.frame:Hide()
            else Shell.OpenView(Shell.active or Shell.order[1]) end
        end,
        onContextMenu = function(button)
            if not Shell.menu then Shell.menu = UI.CreateCascadingMenu(function(action) if type(action) == "function" then action() end end) end
            Shell.menu:Open(button, Shell.GetQuickMenu())
        end})
    Shell.minimap.Position()
    if db.hideMinimapIcon then Shell.minimap:Hide() end
end
function Shell.Attach(product)
    if Shell.hosts[product.id] then return Shell.hosts[product.id] end
    for _, view in ipairs(product.views) do
        if view.id == "plugins" or view.id == "about" then error("This view identifier is reserved by Booty Suite: " .. view.id) end
    end
    local host = Lib.Core.ProductHost.Create(product, {integrated = true, window = Shell.dashboard.frame,
        GetParent = Mount, OpenView = Shell.OpenView, OpenSettings = Shell.OpenSettings, Print = Lib.Print,
        GetPresentationSetting = Suite.GetSetting})
    host.IsIntegrated = function() return true end
    local close = host.Close
    host.Hide = function()
        local ready, reason = close()
        if ready == false then return false, reason end
        for _, item in ipairs(product.views) do if Shell.active == item.id then Shell.dashboard.frame:Hide() end end
        return true
    end
    Shell.hosts[product.id] = host; table.insert(Shell.providers, product)
    for _, item in ipairs(product.views) do Shell.entries[item.id] = {product = product, view = item} end
    return host
end
function Shell.CanSetInMenu(productId)
    local product = Lib.GetProduct(productId)
    if not product or not Shell.hosts[productId] then return false, "Addon is not loaded." end
    if product.failure then return false, product.failure end
    if not product.initialized then return false, "Addon has not finished loading." end
    if product.stopped then return false, "Resume this addon before opening it." end
    local first = product.views and product.views[1]
    if not first then return false, "This addon has no feature window." end
    return true
end
function Shell.CanOpenProduct(productId)
    local ready, reason = Shell.CanSetInMenu(productId)
    if not ready then return false, reason end
    local first = Lib.GetProduct(productId).views[1]
    if not Available(first.id) then return false, "This section is unavailable. Guild sections require guild membership." end
    return true
end
function Shell.OpenProduct(productId)
    local ready, reason = Shell.CanOpenProduct(productId)
    if not ready then return false, reason end
    return Shell.OpenView(Lib.GetProduct(productId).views[1].id)
end
function Shell.SetInMenu(productId, enabled)
    if type(enabled) ~= "boolean" then return false, "Choose whether to add this addon to the menu." end
    local ready, failure = Shell.CanSetInMenu(productId)
    if not ready then return false, failure end
    local product, host = Lib.GetProduct(productId), Shell.hosts[productId]
    if Shell.IsInMenu(productId) == enabled then return true end
    -- A view may refuse Hide while its editor still owns transient resources.
    -- Do not change the durable preference until presentation cleanup succeeds.
    local wasActive = false
    for _, view in ipairs(product.views) do
        local controller = Shell.controllers[view.id]
        if Shell.active == view.id then
            wasActive = true
        end
        if Shell.active == view.id and controller and controller.Hide then
            local ok, result, reason = pcall(controller.Hide, controller)
            if not ok or result == false then
                local message = reason or tostring(result)
                if Shell.dashboard.frame:IsVisible() and controller.Show then
                    local restored, value, detail = pcall(controller.Show, controller)
                    if not restored or value == false then message = message .. " Restore failed: " .. tostring(detail or value) end
                end
                return false, message
            end
        end
    end
    local ok, result, reason = pcall(host.CloseDetachedViews)
    if not ok or result == false then return false, reason or tostring(result) end
    for _, view in ipairs(product.views) do
        if Shell.views[view.id] then Shell.views[view.id]:Hide(); Dock(view.id) end
    end
    local db = Suite.GetDatabase()
    if type(db.menuProducts) ~= "table" then db.menuProducts = {} end
    db.menuProducts[productId] = enabled
    if wasActive and not enabled then Shell.active = nil end
    Shell.Ready()
    if wasActive and not enabled and Shell.active ~= "plugins" then Shell.OpenView("plugins") end
    if Shell.menu then Shell.menu:Close() end
    return true
end
function Shell.GetQuickMenu()
    local items, seen = {}, {}
    local function AddProduct(id)
        if seen[id] then return end
        seen[id] = true
        local product = Lib.GetProduct(id)
        local host = Shell.hosts[id]
        if product and host and Shell.IsInMenu(id) and not product.stopped and not product.failure and product.GetQuickMenu then
            local contributions = product.GetQuickMenu(host)
            if id == "profiler" then table.insert(items, {text = "Profiler", icon = "performance", action = function() Shell.OpenView("profiler") end, children = contributions})
            else for _, entry in ipairs(contributions) do table.insert(items, entry) end end
        end
    end
    for _, id in ipairs(preferredMenuProducts) do AddProduct(id) end
    for _, id in ipairs(Lib.GetProducts()) do AddProduct(id) end
    table.insert(items, {text = "Settings", icon = "settings", action = Shell.OpenSettings})
    table.insert(items, {text = "About", icon = "about", action = function() Shell.OpenView("about") end})
    return items
end
function Suite.RefreshLayout()
    local view = Shell.dashboard
    if not view then return end
    if Shell.navigation then Shell.navigation.Apply() else UI.Dashboard.ApplyChrome(view, Suite.GetSetting) end
    if Shell.active and Shell.controllers[Shell.active] and view.frame:IsVisible() and not view.minimized then
        local controller = Shell.controllers[Shell.active]
        if controller.OnResize then controller:OnResize() elseif controller.RefreshLayout then controller:RefreshLayout() end
    end
end
function Suite.RefreshProductAvailability()
    if Shell.navigation then Shell.navigation.RefreshAvailability() end
    Suite.RefreshLayout()
end
function Shell.Ready()
    local builtins = {id = "suite", name = "BootySuite", views = {
        {id = "plugins", label = "Plugins", icon = "groups", create = Suite.Modules.Plugins.Create},
        {id = "about", label = "About", icon = "about", create = function(parent)
            local controller = Suite.Modules.About.Create(parent, Suite.version, {
                checkVersion = Shell.versionCheck.CheckNow, getVersionStatus = Shell.versionCheck.GetStatus,
                getLastSuccessfulCheck = Shell.versionCheck.GetLastSuccessfulCheck})
            controller.frame = parent
            return controller
        end}}}
    for _, item in ipairs(builtins.views) do Shell.entries[item.id] = {product = builtins, view = item} end
    Shell.hosts.suite = {standalone = false, integrated = true, window = Shell.dashboard.frame, OpenSettings = Shell.OpenSettings, Print = Lib.Print}
    local order, items, seen = {}, {}, {}
    local function AddView(id)
        local entry = Shell.entries[id]
        if entry and Shell.IsInMenu(entry.product.id) and not seen[id] then
            seen[id] = true
            table.insert(order, id)
            table.insert(items, {key = id, text = entry.view.label,
                icon = UI.ClassicAsset("Icons\\" .. (entry.view.icon or "groups") .. ".tga")})
        end
    end
    for _, id in ipairs(preferredOrder) do
        if id ~= "plugins" and id ~= "about" then AddView(id) end
    end
    for _, productId in ipairs(Lib.GetProducts()) do
        local product = Lib.GetProduct(productId)
        for _, view in ipairs(product.views) do AddView(view.id) end
    end
    AddView("plugins"); AddView("about")
    Shell.order = order
    if Shell.navigation then
        Shell.navigation.SetItems(items, order)
        Shell.navigation.RefreshAvailability()
        Suite.RefreshLayout()
        return
    end
    Shell.navigation = UI.Navigation.Create({dashboard = Shell.dashboard.frame, sidebar = Shell.dashboard.sidebar,
        contentPanel = Shell.dashboard.contentPanel, toggleButton = Shell.dashboard.sidebarToggle,
        toggleButtonClassicIcon = Shell.dashboard.sidebarToggleClassicIcon, order = order, items = items,
        ensure = Suite.GetDatabase, get = Suite.GetSetting, set = Suite.SetSetting, showPage = Shell.OpenView,
        isAvailable = InMenu, fallbackPage = "plugins", applyChrome = function() UI.Dashboard.ApplyChrome(Shell.dashboard, Suite.GetSetting) end})
    Shell.dashboard.sidebarToggle:SetScript("OnClick", function() Shell.navigation.Toggle() end)
    Lib.Subscribe("PLAYER_GUILD_UPDATE", Shell, function() Shell.navigation.RefreshAvailability() end)
    Lib.Subscribe("GUILD_ROSTER_UPDATE", Shell, function() Shell.navigation.RefreshAvailability() end)
    Suite.RefreshLayout()
end
function Shell.GetSettings()
    return {db = Suite.GetDatabase(), fields = {
        {key = "menuStyle", label = "Menu style", type = "choice", path = {"Addon UI", "General"}, choices = {{value = "buttons", text = "Sidebar"}, {value = "tabs", text = "Top tabs"}, {value = "bottomTabs", text = "Bottom tabs"}}, onChange = Suite.RefreshLayout},
        {key = "useIconTabs", label = "Use icons in tabs", type = "checkbox", path = {"Addon UI", "General"}, onChange = Suite.RefreshLayout},
        {key = "hideHeaderBar", label = "Hide header bar", type = "checkbox", path = {"Addon UI", "Layout"}, onChange = Suite.RefreshLayout},
        {key = "hideHeaderLogo", label = "Hide header logo", type = "checkbox", path = {"Addon UI", "Layout"}, onChange = Suite.RefreshLayout},
        {key = "hideHeaderName", label = "Hide header name", type = "checkbox", path = {"Addon UI", "Layout"}, onChange = Suite.RefreshLayout},
        {key = "hideStatusVersionBar", label = "Hide status/version bar", type = "checkbox", path = {"Addon UI", "Layout"}, onChange = Suite.RefreshLayout},
        {key = "hideMinimapIcon", label = "Hide minimap icon", type = "checkbox", path = {"Addon UI", "General"}, onChange = function(value) if value then Shell.minimap:Hide() else Shell.minimap:Show() end end},
    }}
end
table.insert(Shell.providers, Shell)
table.insert(Shell.providers, {id = "lib", name = "BootyLib", GetSettings = function()
    return {db = Lib.Data.Ensure("lib"), fields = {
        {key = "uiSkin", label = "Interface skin", type = "choice", path = {"Addon UI", "General"},
            choices = {{value = "classic", text = "Classic"}, {value = "default", text = "Classic WIP"}}, onChange = function(value) UI.SetSkin(value) end},
        {key = "chatActionLogs", label = "Chat action logs", type = "checkbox", path = {"Addon UI", "General"}},
        {key = "suppressLoginMessage", label = "Suppress login message", type = "checkbox", path = {"Addon UI", "General"}},
    }}
end})
Lib.RegisterSuite(Shell)
SlashCmdList = SlashCmdList or {}
SLASH_BOOTYRAIDERMOS1 = nil; SlashCmdList.BOOTYRAIDERMOS = nil
SLASH_BOOTYSUITE1 = "/bs"; SLASH_BOOTYSUITE2 = "/booty"; SLASH_BOOTYSUITE3 = "/mos"
SlashCmdList.BOOTYSUITE = function(message)
    local _, _, command = string.find(tostring(message or ""), "^%s*(%S*)")
    command = string.lower(command or "")
    if command == "settings" then Shell.OpenSettings()
    elseif command == "roll" then local raider = Lib.GetProduct("raider"); if raider and raider.Command then raider.Command(message) else Lib.Print("BootyRaider is not loaded.") end
    elseif command == "plugins" then Shell.OpenView("plugins")
    else Shell.OpenView(Shell.active or Shell.order[1]) end
end
