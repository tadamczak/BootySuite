local Suite, Lib, UI = BootySuite, BootyLib, BootyLib.UI.Components
local Shell = {id = "suite", name = "BootySuite", apiVersion = 1, hosts = {}, entries = {}, views = {}, controllers = {}, order = {}, providers = {}}
Suite.Shell = Shell
local Geometry = Suite.Core.ShellGeometry
Shell.ReadGeometry = Geometry.ReadGeometry
Shell.BeginGeometryPreview = Geometry.BeginGeometryPreview
Shell.PreviewGeometry = Geometry.PreviewGeometry
Shell.ApplyGeometry = Geometry.ApplyGeometry
Shell.CancelGeometry = Geometry.CancelGeometry
Shell.ResetGeometry = Geometry.ResetGeometry
Shell.GetGeometryReference = Geometry.GetGeometryReference
Shell.WatchGeometry = Geometry.WatchGeometry
Shell.UnwatchGeometry = Geometry.UnwatchGeometry
local preferredOrder = {"roster", "raid", "statistics", "raidStatistics", "csr", "profiler", "plugins", "about"}
local preferredMenuProducts = {"guild", "raider", "profiler"}
local function Available(id)
    local entry = Shell.entries[id]
    return entry and not entry.product.stopped and not entry.product.failure and (not entry.view.IsAvailable or entry.view.IsAvailable()) or false
end
function Shell.GetView(id)
    local entry = Shell.entries[id]
    if not entry then return nil end
    local controller = Shell.controllers[id]
    if controller then return controller end
    local parent = UI.CreateContainer(nil, Shell.dashboard.pageHost)
    parent.mosContentPanel = Shell.dashboard.contentPanel
    parent:SetPoint("TOPLEFT", Shell.dashboard.pageHost, "TOPLEFT", 1.5, -3)
    parent:SetPoint("BOTTOMRIGHT", Shell.dashboard.pageHost, "BOTTOMRIGHT", -1.5, 1.5); parent:Hide()
    Shell.views[id] = parent
    controller = entry.view.create(parent, Shell.hosts[entry.product.id])
    if controller then Shell.controllers[id] = controller end
    return controller
end
function Shell.OpenView(id)
    if not Available(id) then Lib.Print("This section is unavailable. Guild sections require guild membership."); return false end
    local controller = Shell.GetView(id)
    if not controller then return false end
    if Shell.active and Shell.active ~= id then
        local previous = Shell.controllers[Shell.active]
        if previous and previous.Hide then previous:Hide() end
        if Shell.views[Shell.active] then Shell.views[Shell.active]:Hide() end
    end
    Shell.active = id; UI.Dashboard.OpenWindow(Shell.dashboard)
    Shell.views[id]:Show(); if controller.Show then controller:Show() end
    if Shell.navigation then Shell.navigation.SetActive(id) end
    Suite.RefreshLayout(); return controller
end
function Shell.OpenSettings()
    return Lib.Core.SettingsHost.Open(Shell, {integrated = true, window = Shell.dashboard and Shell.dashboard.frame}, Shell.providers)
end
function Shell.OpenGeometryWindow()
    return Shell.OpenView(Shell.active or Shell.order[1] or "plugins")
end
function Shell.Stop()
    local ok, failure = Geometry.EndPreview("stopped")
    if not ok then return false, failure end
    if Shell.dashboard then Shell.dashboard.frame:Hide() end
    return true
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
        if Geometry.IsApplying() then return end
        if Geometry.HasPreview() then return Geometry.CaptureManual() end
        if Lib.Core.WindowPose then return Geometry.SaveManual() end
        db.windowWidth, db.windowHeight = view.frame:GetWidth(), view.frame:GetHeight()
        db.windowLeft, db.windowBottom = view.frame:GetLeft(), view.frame:GetBottom()
    end
    UI.Dashboard.BindWindow(view, {isLootMasterMode = function() return false end, isTabLayout = function() return db.menuStyle ~= "buttons" end,
        statusBar = view.statusBar,
        saveGeometry = SaveGeometry, saveLootGeometry = SaveGeometry, refreshLayout = function() Suite.RefreshLayout() end,
        restoreGeometry = Lib.Core.WindowPose and Geometry.RestoreCommitted or nil,
        beforeMinimize = function()
            local preview = Geometry.HasPreview()
            local ok, failure = Geometry.EndPreview("minimized")
            if not ok then return false, failure end
            -- The cancel restores the last committed rectangle before the
            -- shared shell snapshots its expanded dimensions.
            return true, preview
        end,
        applyLayout = function() Suite.RefreshLayout() end, applyOrRefreshLayout = function() Suite.RefreshLayout() end,
        setNavigationVisible = function(shown)
            if Shell.navigation then for _, button in pairs(Shell.navigation.buttons) do if shown then button:Show() else button:Hide() end end end
            local controller = Shell.active and Shell.controllers[Shell.active]
            if controller then if shown and controller.Show then controller:Show() elseif not shown and controller.Hide then controller:Hide() end end
        end})
    local hide = view.frame:GetScript("OnHide")
    view.frame:SetScript("OnHide", function()
        local ok, failure = Geometry.EndPreview("hidden")
        if not ok then Lib.Print(type(failure) == "table" and failure.message or tostring(failure)) end
        if hide then hide() end
        Geometry.SetVisible(false)
        if Shell.active and Shell.controllers[Shell.active] and Shell.controllers[Shell.active].Hide then Shell.controllers[Shell.active]:Hide() end
    end)
    local shown=view.frame:GetScript("OnShow")
    view.frame:SetScript("OnShow",function()
        if shown then shown() end
        local ok,failure=Geometry.SetVisible(true)
        if not ok then Lib.Print(failure.message) end
        if Lib.Core.WindowPose and not view.minimized and not Geometry.HasPreview() then
            ok,failure=Geometry.RestoreCommitted();if not ok then Lib.Print(failure.message) end
        end
    end)
    if Lib.Core.WindowPose then Geometry.RestoreCommitted() end
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
    local host = {standalone = false, integrated = true, window = Shell.dashboard.frame, previewOwner = Shell.dashboard.pageHost, product = product,
        GetView = Shell.GetView, OpenView = Shell.OpenView, OpenSettings = Shell.OpenSettings, Print = Lib.Print,
        GetPresentationSetting = Suite.GetSetting, IsIntegrated = function() return true end}
    host.Hide = function() for _, item in ipairs(product.views) do if Shell.active == item.id then Shell.dashboard.frame:Hide() end end end
    Shell.hosts[product.id] = host; table.insert(Shell.providers, product)
    for _, item in ipairs(product.views) do Shell.entries[item.id] = {product = product, view = item} end
    return host
end
function Shell.GetQuickMenu()
    local items, seen = {}, {}
    local function AddProduct(id)
        if seen[id] then return end
        seen[id] = true
        local product = Lib.GetProduct(id)
        local host = Shell.hosts[id]
        if product and host and not product.stopped and not product.failure and product.GetQuickMenu then
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
        if controller.OnResize then return controller:OnResize() elseif controller.RefreshLayout then return controller:RefreshLayout() end
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
        if entry and not seen[id] then
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
        isAvailable = Available, fallbackPage = "plugins", applyChrome = function() UI.Dashboard.ApplyChrome(Shell.dashboard, Suite.GetSetting) end})
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
        {key = "uiSkin", label = "Interface skin", type = "choice", default = "classic", path = {"Addon UI", "General"},
            choices = {{value = "classic", text = "Classic"}, {value = "default", text = "Classic WIP"}},
            set = function(value) return Lib.SetSharedSkin(value) end},
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
