local MOS = MuklaOfficerSuite

MOS.UI.Components.Dashboard = MOS.UI.Components.Dashboard or {}
local Dashboard = MOS.UI.Components.Dashboard

function Dashboard.GetChromeLayout(get, classic)
    local compact = get("hideHeaderLogo") and get("hideHeaderName")
    local normalHeight = classic and 44 or 32
    local topTabs = get("menuStyle") == "tabs"
    local headerHeight = topTabs and 20 or (compact and 30 or normalHeight)
    local bottom = get("hideStatusVersionBar") and (classic and 4 or 9) or (classic and 26 or 31)
    if get("hideHeaderBar") then return 0, -1, bottom, -1 end
    local top = -(topTabs and 1 or (classic and 8 or 14)) - headerHeight
    return headerHeight, top, bottom, top
end

local function SetChromeVisible(region, shown) if shown then region:Show() else region:Hide() end end

function Dashboard.SetTabBody(view, protruding)
    local frame = view.frame
    if protruding then
        if not view.tabBody then
            local body = MOS.UI.Components.CreateContainer(nil, frame)
            body:EnableMouse(false); body:SetFrameLevel(frame:GetFrameLevel())
            body:SetBackdrop(frame.mosWindowBackdrop)
            body:SetBackdropColor(0.02, 0.02, 0.02, 0.98); body:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
            body:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0); body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 30)
            view.tabBody = body
        end
        frame:SetBackdropColor(0, 0, 0, 0); frame:SetBackdropBorderColor(0, 0, 0, 0)
        view.tabBody:Show()
    elseif view.tabBody then
        view.tabBody:Hide()
        frame:SetBackdropColor(0.02, 0.02, 0.02, 0.98); frame:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
    end
    view.tabsProtruding = protruding
end

function Dashboard.PlaceWindowControls(view, inContent)
    local controls = view.windowControls
    controls:ClearAllPoints()
    if inContent then controls:SetPoint("TOPRIGHT", view.contentPanel, "TOPRIGHT", -1, -1)
    else controls:SetPoint("RIGHT", view.titleBar, "RIGHT", -6, 0) end
    controls:Show()
end

function Dashboard.ApplyChrome(view, get)
    if view.minimized then return end
    local classic = MOS.UI.Components.IsClassicSkin()
    local height = Dashboard.GetChromeLayout(get, classic)
    view.titleBar:ClearAllPoints()
    view.titleBar:SetPoint("TOPLEFT", view.frame, "TOPLEFT", classic and 4 or 9, get("menuStyle") == "tabs" and -1 or (classic and -8 or -14))
    view.titleBar:SetPoint("TOPRIGHT", view.frame, "TOPRIGHT", 0, get("menuStyle") == "tabs" and -1 or (classic and -8 or -14))
    view.titleBar:SetHeight(height)
    SetChromeVisible(view.title, not classic and not get("hideHeaderName") and get("menuStyle") ~= "tabs")
    SetChromeVisible(view.classicTitle, classic and not get("hideHeaderName") and get("menuStyle") ~= "tabs")
    SetChromeVisible(view.classicTitleLeft, classic and not get("hideHeaderName") and get("menuStyle") ~= "tabs")
    SetChromeVisible(view.classicTitleRight, classic and not get("hideHeaderName") and get("menuStyle") ~= "tabs")
    SetChromeVisible(view.classicLogo, classic and not get("hideHeaderLogo") and get("menuStyle") ~= "tabs")
    local hiddenHeader = get("hideHeaderBar")
    SetChromeVisible(view.titleBar, not hiddenHeader)
    Dashboard.PlaceWindowControls(view, hiddenHeader)
    if view.pageHost then
        view.pageHost:ClearAllPoints(); view.pageHost:SetPoint("TOPLEFT", view.contentPanel, "TOPLEFT", 0, hiddenHeader and -20 or 0)
        view.pageHost:SetPoint("BOTTOMRIGHT", view.contentPanel, "BOTTOMRIGHT", 0, 0)
    end
    if not classic then
        view.sidebarToggle:SetParent(hiddenHeader and view.sidebar or view.titleBar); view.sidebarToggle:ClearAllPoints()
        if hiddenHeader then view.sidebarToggle:SetPoint("TOPRIGHT", view.sidebar, "TOPRIGHT", -6, -6)
        else view.sidebarToggle:SetPoint("LEFT", view.titleBar, "LEFT", 5, 0) end
    end
    local footer = not get("hideStatusVersionBar")
    Dashboard.SetTabBody(view, get("menuStyle") == "bottomTabs" and not footer and not (view.lootBorder and view.lootBorder:IsVisible()))
    if view.frame.mosStatusBar then SetChromeVisible(view.frame.mosStatusBar, footer) end
    SetChromeVisible(view.versionText, footer)
    SetChromeVisible(view.resizeGrip.texture, footer)
    view.resizeGrip:ClearAllPoints()
    view.resizeGrip:SetPoint("BOTTOMRIGHT", view.tabsProtruding and view.tabBody or view.frame, "BOTTOMRIGHT", footer and -7 or 0, footer and 7 or 0)
end

function Dashboard.CreateWindow(version)
    local view = {}
    view.frame = CreateFrame("Frame", "MuklaOfficerSuiteDashboard", UIParent)
    local frame = view.frame
    frame:SetWidth(840); frame:SetHeight(540)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true); frame:SetResizable(true)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetMinResize(350, 380); frame:SetMaxResize(1100, 760)
    frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame.mosWindowBackdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
    frame:SetBackdrop(frame.mosWindowBackdrop)
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.98); frame:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
    view.lootBorder = CreateFrame("Frame", nil, frame)
    view.lootBorder:SetAllPoints(frame); view.lootBorder:EnableMouse(false)
    view.lootBorder:SetFrameLevel(frame:GetFrameLevel() + 80)
    view.lootBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    view.lootBorder:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
    view.lootBorder:Hide()
    frame.mosLootBorder = view.lootBorder
    frame:Hide()

    view.resizeGrip = MOS.UI.Components.CreateResizeGrip(frame)
    frame.mosResizeGrip = view.resizeGrip

    view.titleBar = CreateFrame("Frame", nil, frame)
    view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -14)
    view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -14)
    view.titleBar:SetHeight(32)
    view.titleBar:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    view.titleBar:SetBackdropColor(0.025, 0.022, 0.018, 0.98); view.titleBar:SetBackdropBorderColor(0.42, 0.42, 0.40, 1)
    MOS.UI.Components.RegisterSkinnedSurface(view.titleBar, "title", { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }, { 0.025, 0.022, 0.018, 0.98 }, { 0.42, 0.42, 0.40, 1 })
    view.title = view.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.title:SetPoint("CENTER", view.titleBar, "CENTER", 0, 2); view.title:SetText("Mukla Officer Suite")
    view.title:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    view.classicTitle = view.titleBar:CreateTexture(nil, "ARTWORK")
    view.classicTitle:SetTexture(MOS.UI.Components.ClassicAsset("Decor\\title-wordmark.tga")); view.classicTitle:SetTexCoord(0.181640625, 0.818359375, 0.28125, 0.71875)
    view.classicTitle:SetWidth(220); view.classicTitle:SetHeight(19); view.classicTitle:SetPoint("CENTER", view.titleBar, "CENTER", 0, 1); view.classicTitle:Hide()
    view.classicLogo = view.titleBar:CreateTexture(nil, "ARTWORK")
    view.classicLogo:SetTexture(MOS.UI.Components.ClassicAsset("logo.tga")); view.classicLogo:SetTexCoord(0, 1, 0.08203125, 0.9140625)
    view.classicLogo:SetWidth(100); view.classicLogo:SetHeight(40); view.classicLogo:SetPoint("LEFT", view.titleBar, "LEFT", 18, 0); view.classicLogo:Hide()
    view.classicTitleLeft = view.titleBar:CreateTexture(nil, "ARTWORK"); view.classicTitleLeft:SetTexture(MOS.UI.Components.ClassicAsset("Decor\\title-left.tga")); view.classicTitleLeft:SetWidth(65); view.classicTitleLeft:SetHeight(8); view.classicTitleLeft:SetPoint("RIGHT", view.classicTitle, "LEFT", -12, 0); view.classicTitleLeft:Hide()
    view.classicTitleRight = view.titleBar:CreateTexture(nil, "ARTWORK"); view.classicTitleRight:SetTexture(MOS.UI.Components.ClassicAsset("Decor\\title-right.tga")); view.classicTitleRight:SetWidth(65); view.classicTitleRight:SetHeight(8); view.classicTitleRight:SetPoint("LEFT", view.classicTitle, "RIGHT", 12, 0); view.classicTitleRight:Hide()
    view.windowControls = MOS.UI.Components.CreateContainer(nil, frame)
    view.windowControls:SetWidth(62); view.windowControls:SetHeight(18); view.windowControls:SetFrameLevel(frame:GetFrameLevel() + 60)
    frame.mosWindowControls = view.windowControls
    view.windowControls:SetPoint("RIGHT", view.titleBar, "RIGHT", -6, 0)
    view.closeButton = MOS.UI.Components.CreateWindowButton(view.windowControls, nil, "close")
    view.closeButton:SetPoint("RIGHT", view.windowControls, "RIGHT", 0, 0)
    view.closeButton:SetScript("OnClick", function() frame:Hide() end)
    view.minimizeButton = MOS.UI.Components.CreateWindowButton(view.windowControls, nil, "minimize")
    view.minimizeButton:SetPoint("RIGHT", view.closeButton, "LEFT", -4, 0)
    view.settingsButton = MOS.UI.Components.CreateButton(view.windowControls, nil, "", 18, 18)
    MOS.UI.Components.SetClassicButtonCompact(view.settingsButton, true)
    view.settingsButton:SetPoint("RIGHT", view.minimizeButton, "LEFT", -4, 0)
    view.settingsButton.icon = view.settingsButton:CreateTexture(nil, "OVERLAY")
    view.settingsButton.icon:SetPoint("CENTER", view.settingsButton, "CENTER", 0, 0)
    view.settingsButton.icon:SetWidth(13); view.settingsButton.icon:SetHeight(13)
    -- Crop the asymmetric transparent padding of the 64x64 gear asset.
    view.settingsButton.icon:SetTexCoord(8 / 64, 47 / 64, 11 / 64, 50 / 64)
    view.settingsButton.icon:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Assets\\SettingsGear")
    MOS.UI.Components.AttachTooltip(view.settingsButton, "Settings", "Open Settings in a separate movable window.")
    MOS.UI.Components.AttachGoldHoverBorder(view.settingsButton, 0.35, 0.35, 0.35, 1)
    view.sidebarToggle = MOS.UI.Components.CreateButton(view.titleBar, nil, "<<", 28, 20)
    MOS.UI.Components.SetClassicButtonCompact(view.sidebarToggle, true)
    view.sidebarToggle:SetPoint("LEFT", view.titleBar, "LEFT", 5, 0)
    MOS.UI.Components.AttachTooltip(view.sidebarToggle, "Navigation", "Collapse or restore the left navigation menu.")
    local navigationTooltipEnter = view.sidebarToggle:GetScript("OnEnter")
    local navigationTooltipLeave = view.sidebarToggle:GetScript("OnLeave")
    MOS.UI.Components.AttachGoldHoverBorder(view.sidebarToggle, 0.35, 0.35, 0.35, 1)
    local navigationBorderEnter = view.sidebarToggle:GetScript("OnEnter")
    local navigationBorderLeave = view.sidebarToggle:GetScript("OnLeave")
    view.sidebarToggle:SetScript("OnEnter", function()
        if navigationTooltipEnter then navigationTooltipEnter() end
        if navigationBorderEnter then navigationBorderEnter() end
    end)
    view.sidebarToggle:SetScript("OnLeave", function()
        if navigationTooltipLeave then navigationTooltipLeave() end
        if navigationBorderLeave then navigationBorderLeave() end
    end)
    view.versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    view.versionText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 17); view.versionText:SetText("v" .. version)

    view.sidebar = CreateFrame("Frame", nil, frame)
    view.sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -68); view.sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 42); view.sidebar:SetWidth(174)
    view.sidebar:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    view.sidebar:SetBackdropColor(0.05, 0.04, 0.02, 0.92); view.sidebar:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
    MOS.UI.Components.RegisterSkinnedSurface(view.sidebar, "sidebar", { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }, { 0.05, 0.04, 0.02, 0.92 }, { 0.36, 0.36, 0.34, 1 })
    view.sidebarToggleClassicIcon = view.sidebarToggle:CreateTexture(nil, "OVERLAY")
    view.sidebarToggleClassicIcon:SetWidth(11); view.sidebarToggleClassicIcon:SetHeight(11); view.sidebarToggleClassicIcon:SetPoint("CENTER", view.sidebarToggle, "CENTER", 0, 0); view.sidebarToggleClassicIcon:Hide()
    view.classicMenuTitle = view.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.classicMenuTitle:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    view.sidebarToggleClassicIcon:SetVertexColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    view.classicMenuTitle:SetPoint("TOPLEFT", view.sidebar, "TOPLEFT", 10, -9); view.classicMenuTitle:SetText("Menu"); view.classicMenuTitle:Hide()
    view.sidebar.classicMenuTitle = view.classicMenuTitle
    view.contentPanel = CreateFrame("Frame", nil, frame)
    view.contentPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 204, -68); view.contentPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 46)
    view.contentPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    view.contentPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.90); view.contentPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
    MOS.UI.Components.RegisterSkinnedSurface(view.contentPanel, "content", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }, { 0.02, 0.02, 0.02, 0.90 }, { 0.36, 0.36, 0.34, 1 })
    view.pageHost = MOS.UI.Components.CreateContainer(nil, view.contentPanel)
    view.pageHost:SetAllPoints(view.contentPanel); view.contentPanel.mosPageHost = view.pageHost
    local background = view.sidebar:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", view.sidebar, "TOPLEFT", 5, -5); background:SetPoint("BOTTOMRIGHT", view.sidebar, "BOTTOMRIGHT", -5, 5)
    background:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\DashboardBackground"); background:SetTexCoord(0.22, 0.58, 0, 1); background:SetAlpha(0.72)
    local backgroundShade = view.sidebar:CreateTexture(nil, "BORDER")
    backgroundShade:SetAllPoints(view.sidebar); backgroundShade:SetTexture(0, 0, 0, 0.40)
    view.contentShade = view.contentPanel:CreateTexture(nil, "BACKGROUND")
    view.contentShade:SetPoint("TOPLEFT", view.contentPanel, "TOPLEFT", 5, -5); view.contentShade:SetPoint("BOTTOMRIGHT", view.contentPanel, "BOTTOMRIGHT", -5, 5)
    view.contentShade:SetTexture(0.025, 0.022, 0.018, 0.96)
    MOS.UI.Components.RegisterSkinCallback(function(skin)
        local classic = skin == "classic"
        if classic and not view.minimized then view.title:Hide(); view.classicTitle:Show() else view.classicTitle:Hide(); view.title:Show() end
        if classic and not view.minimized then view.classicLogo:Show(); view.classicTitleLeft:Show(); view.classicTitleRight:Show(); view.classicMenuTitle:Show()
        else view.classicLogo:Hide(); view.classicTitleLeft:Hide(); view.classicTitleRight:Hide(); view.classicMenuTitle:Hide() end
        view.titleBar:ClearAllPoints()
        if classic then view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -8); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -8); view.titleBar:SetHeight(44)
        else view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 9, -14); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -14); view.titleBar:SetHeight(32) end
        local margin = classic and 4 or 9
        local sectionGap = classic and 4 or 6
        local sectionTop = -(classic and 52 or 46) - sectionGap
        local footerBottom = margin
        local sectionBottom = footerBottom + 22 + sectionGap
        view.sidebar:ClearAllPoints()
        view.sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, sectionTop)
        view.sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", margin, sectionBottom)
        view.contentPanel:ClearAllPoints()
        view.contentPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", classic and 153 or 184, sectionTop)
        view.contentPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -margin, sectionBottom)
        view.versionText:ClearAllPoints()
        view.versionText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, footerBottom + 5)
        if frame.mosStatusBar then
            frame.mosStatusBar:ClearAllPoints()
            frame.mosStatusBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", margin, footerBottom)
            frame.mosStatusBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -126, footerBottom)
        end
        background:SetAlpha(classic and 0 or 0.72); backgroundShade:SetAlpha(classic and 0 or 1); view.contentShade:SetAlpha(classic and 0 or 1)
        if classic then
            view.sidebarToggle:SetParent(view.sidebar); view.sidebarToggle:ClearAllPoints(); view.sidebarToggle:SetPoint("TOPRIGHT", view.sidebar, "TOPRIGHT", -7, -7); view.sidebarToggle:SetWidth(18); view.sidebarToggle:SetHeight(18)
            view.sidebarToggle.label:SetText(""); view.sidebarToggleClassicIcon:Show()
        else
            view.sidebarToggle:SetParent(view.titleBar); view.sidebarToggle:ClearAllPoints(); view.sidebarToggle:SetPoint("LEFT", view.titleBar, "LEFT", 5, 0); view.sidebarToggle:SetWidth(28); view.sidebarToggle:SetHeight(20)
            view.sidebarToggleClassicIcon:Hide()
        end
    end)
    return view
end

function Dashboard.CreateStatusBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    parent.mosStatusBar = bar
    local margin = MOS.UI.Components.IsClassicSkin() and 4 or 9
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", margin, margin)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -126, margin)
    bar:SetHeight(22)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    bar:SetBackdropColor(0.025, 0.022, 0.018, 0.94)
    bar:SetBackdropBorderColor(0.30, 0.30, 0.28, 1)
    MOS.UI.Components.RegisterSkinnedSurface(bar, "status", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }, { 0.025, 0.022, 0.018, 0.94 }, { 0.30, 0.30, 0.28, 1 })
    bar.message = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    bar.message:SetPoint("LEFT", bar, "LEFT", 8, 0)
    bar.message:SetWidth(270)
    bar.message:SetJustifyH("LEFT")
    return bar
end

function Dashboard.SetStatus(bar, message, kind)
    if not bar or not bar.message then return end
    bar.message:SetText(message or "Ready")
    if kind == "error" then bar.message:SetTextColor(1, 0.35, 0.25)
    elseif kind == "success" then bar.message:SetTextColor(0.45, 1, 0.45)
    else bar.message:SetTextColor(0.72, 0.72, 0.68) end
end

function Dashboard.CreatePages(contentPanel, definitions)
    contentPanel = contentPanel.mosPageHost or contentPanel
    local pages = {}
    local index
    for index = 1, table.getn(definitions) do
        local definition = definitions[index]
        local page = CreateFrame("Frame", nil, contentPanel)
        if definition.anchor then page:SetAllPoints(pages[definition.anchor])

        else
            page:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 1.5, -3)
            page:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -1.5, 1.5)
        end
        if definition.hidden then page:Hide() end
        pages[definition.key] = page
    end
    return pages
end

function Dashboard.BindWindow(view, options)
    local frame, grip = view.frame, view.resizeGrip
    grip.UpdateLayout = function()
        this.layoutElapsed = this.layoutElapsed + arg1
        if this.layoutElapsed >= 0.08 then
            this.layoutElapsed = 0
            if options.isLootMasterMode() then options.refreshLayout()
            elseif options.isTabLayout() then options.applyLayout()
            else options.refreshLayout() end
        end
    end
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        if view.minimized then
            view.minimizedLeft, view.minimizedBottom = frame:GetLeft(), frame:GetBottom()
        elseif options.isLootMasterMode() then options.saveLootGeometry() else options.saveGeometry() end
    end)
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
        this.layoutElapsed = 0
        this:SetScript("OnUpdate", this.UpdateLayout)
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing(); this:SetScript("OnUpdate", nil)
        if view.minimized then
            view.minimizedLeft, view.minimizedBottom = frame:GetLeft(), frame:GetBottom()
        elseif options.isLootMasterMode() then options.saveLootGeometry() else options.saveGeometry() end
        if options.isLootMasterMode() then options.refreshLayout() else options.applyOrRefreshLayout() end
    end)
    grip:SetScript("OnHide", function() frame:StopMovingOrSizing(); this:SetScript("OnUpdate", nil) end)

    view.ToggleMinimize = function()
        if options.isLootMasterMode() then return end
        if view.minimized then
            view.minimizedLeft, view.minimizedBottom = frame:GetLeft(), frame:GetBottom()
            view.minimized = false
            frame:SetMinResize(350, 380); frame:SetMaxResize(1100, 760)
            frame:SetWidth(view.widthBeforeMinimize or 840); frame:SetHeight(view.heightBeforeMinimize or 540)
            frame:ClearAllPoints()
            if view.leftBeforeMinimize and view.bottomBeforeMinimize then frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", view.leftBeforeMinimize, view.bottomBeforeMinimize) else frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10) end
            view.title:ClearAllPoints(); view.title:SetPoint("CENTER", view.titleBar, "CENTER", 0, 2)
            view.title:SetFontObject(GameFontNormalLarge)
            view.title:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
            MOS.UI.Components.SetWindowButtonAction(view.minimizeButton, "minimize"); view.title:SetText("Mukla Officer Suite")
            view.classicTitle:ClearAllPoints(); view.classicTitle:SetPoint("CENTER", view.titleBar, "CENTER", 0, 1); view.classicTitle:SetWidth(220); view.classicTitle:SetHeight(19)
            if MOS.UI.Components.IsClassicSkin() then
                view.title:Hide(); view.classicTitle:Show(); view.classicLogo:Show(); view.classicTitleLeft:Show(); view.classicTitleRight:Show()
                view.titleBar:ClearAllPoints(); view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8); view.titleBar:SetHeight(44)
            end
            view.sidebar:Show(); view.contentPanel:Show(); options.statusBar:Show(); view.versionText:Show(); view.resizeGrip:Show(); view.sidebarToggle:Show()
            if options.setNavigationVisible then options.setNavigationVisible(true) end
            options.applyOrRefreshLayout()
        else
            view.widthBeforeMinimize = frame:GetWidth(); view.heightBeforeMinimize = frame:GetHeight(); view.leftBeforeMinimize = frame:GetLeft(); view.bottomBeforeMinimize = frame:GetBottom()
            options.saveGeometry()
            Dashboard.SetTabBody(view, false)
            view.titleBar:Show(); Dashboard.PlaceWindowControls(view, false)
            view.minimized = true
            view.sidebar:Hide(); view.contentPanel:Hide(); options.statusBar:Hide(); view.versionText:Hide(); view.resizeGrip:Hide(); view.sidebarToggle:Hide()
            if options.setNavigationVisible then options.setNavigationVisible(false) end
            frame:SetMinResize(250, 40); frame:SetMaxResize(250, 40); frame:SetWidth(250); frame:SetHeight(40)
            frame:ClearAllPoints()
            frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", view.minimizedLeft or view.leftBeforeMinimize or 0, view.minimizedBottom or ((view.bottomBeforeMinimize or 0) + view.heightBeforeMinimize - 40))
            view.titleBar:ClearAllPoints(); view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5); view.titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
            view.title:ClearAllPoints(); view.title:SetPoint("LEFT", view.titleBar, "LEFT", 9, 1); view.title:SetFontObject(GameFontNormal)
            view.title:SetText("Mukla Officer Suite"); view.title:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
            MOS.UI.Components.SetWindowButtonAction(view.minimizeButton, "maximize")
            view.classicTitle:Hide(); view.classicLogo:Hide(); view.classicTitleLeft:Hide(); view.classicTitleRight:Hide(); view.title:Show()
        end
    end
    view.minimizeButton:SetScript("OnClick", view.ToggleMinimize)
end

function Dashboard.CreateMinimapButton(options)
    local button = CreateFrame("Button", "MuklaOfficerSuiteMinimapButton", Minimap)
    button:SetWidth(32); button:SetHeight(32); button:SetFrameStrata("MEDIUM"); button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:RegisterForDrag("LeftButton")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20); icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(52); border:SetHeight(52); border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button.Position = function()
        options.ensureDatabase()
        local angle = options.getAngle()
        local radians = math.rad(angle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(radians), 80 * math.sin(radians))
    end
    button.UpdateDragPosition = function()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local minimapX, minimapY = Minimap:GetCenter()
        options.setAngle(math.deg(math.atan2((y / scale) - minimapY, (x / scale) - minimapX)))
        button.Position()
    end
    button:SetScript("OnClick", options.onClick)
    button:SetScript("OnEnter", function()
        MOS.UI.Components.AnchorTooltipRightOfCursor(this)
        GameTooltip:AddLine("Mukla Officer Suite")
        GameTooltip:AddLine("Click to open the dashboard", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", this.UpdateDragPosition)
    end)
    button:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)
    return button
end
