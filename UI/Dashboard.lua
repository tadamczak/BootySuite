local MOS = MuklaOfficerSuite

MOS.UI.Dashboard = MOS.UI.Dashboard or {}
local Dashboard = MOS.UI.Dashboard

function Dashboard.CreateWindow(version)
    local view = {}
    view.frame = CreateFrame("Frame", "MuklaOfficerSuiteDashboard", UIParent)
    local frame = view.frame
    frame:SetWidth(840); frame:SetHeight(540)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true); frame:SetResizable(true)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetMinResize(760, 420); frame:SetMaxResize(1100, 760)
    frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.98); frame:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
    view.lootBorder = CreateFrame("Frame", nil, frame)
    view.lootBorder:SetAllPoints(frame); view.lootBorder:EnableMouse(false)
    view.lootBorder:SetFrameLevel(frame:GetFrameLevel() + 80)
    view.lootBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    view.lootBorder:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)
    view.lootBorder:Hide()
    frame.mosLootBorder = view.lootBorder
    frame:Hide()

    view.resizeGrip = CreateFrame("Button", nil, frame)
    frame.mosResizeGrip = view.resizeGrip
    view.resizeGrip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)
    view.resizeGrip:SetWidth(18); view.resizeGrip:SetHeight(18)
    view.resizeGrip:SetFrameLevel(frame:GetFrameLevel() + 100)
    view.resizeGrip.texture = view.resizeGrip:CreateTexture(nil, "OVERLAY")
    view.resizeGrip.texture:SetAllPoints(view.resizeGrip)
    view.resizeGrip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    view.titleBar = CreateFrame("Frame", nil, frame)
    view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
    view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -14)
    view.titleBar:SetHeight(32)
    view.titleBar:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    view.titleBar:SetBackdropColor(0.025, 0.022, 0.018, 0.98); view.titleBar:SetBackdropBorderColor(0.42, 0.42, 0.40, 1)
    MOS.UI.RegisterSkinnedSurface(view.titleBar, "title", { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }, { 0.025, 0.022, 0.018, 0.98 }, { 0.42, 0.42, 0.40, 1 })
    view.title = view.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.title:SetPoint("CENTER", view.titleBar, "CENTER", 0, 2); view.title:SetText("Mukla Officer Suite")
    view.classicTitle = view.titleBar:CreateTexture(nil, "ARTWORK")
    view.classicTitle:SetTexture(MOS.UI.ClassicAsset("Decor\\title-wordmark.tga")); view.classicTitle:SetTexCoord(0.181640625, 0.818359375, 0.28125, 0.71875)
    view.classicTitle:SetWidth(220); view.classicTitle:SetHeight(19); view.classicTitle:SetPoint("CENTER", view.titleBar, "CENTER", 0, 1); view.classicTitle:Hide()
    view.classicLogo = view.titleBar:CreateTexture(nil, "ARTWORK")
    view.classicLogo:SetTexture(MOS.UI.ClassicAsset("logo.tga")); view.classicLogo:SetTexCoord(0, 1, 0.08203125, 0.9140625)
    view.classicLogo:SetWidth(126); view.classicLogo:SetHeight(52); view.classicLogo:SetPoint("LEFT", view.titleBar, "LEFT", 18, 0); view.classicLogo:Hide()
    view.classicTitleLeft = view.titleBar:CreateTexture(nil, "ARTWORK"); view.classicTitleLeft:SetTexture(MOS.UI.ClassicAsset("Decor\\title-left.tga")); view.classicTitleLeft:SetWidth(65); view.classicTitleLeft:SetHeight(8); view.classicTitleLeft:SetPoint("RIGHT", view.classicTitle, "LEFT", -12, 0); view.classicTitleLeft:Hide()
    view.classicTitleRight = view.titleBar:CreateTexture(nil, "ARTWORK"); view.classicTitleRight:SetTexture(MOS.UI.ClassicAsset("Decor\\title-right.tga")); view.classicTitleRight:SetWidth(65); view.classicTitleRight:SetHeight(8); view.classicTitleRight:SetPoint("LEFT", view.classicTitle, "RIGHT", 12, 0); view.classicTitleRight:Hide()
    view.closeButton = MOS.UI.CreateButton(view.titleBar, nil, "X", 18, 18)
    MOS.UI.SetClassicButtonCompact(view.closeButton, true)
    MOS.UI.AttachGoldHoverBorder(view.closeButton, 0.35, 0.35, 0.35, 1)
    view.closeButton.label:SetTextColor(1, 0.82, 0.18)
    view.closeButton:SetPoint("RIGHT", view.titleBar, "RIGHT", -6, 0)
    view.closeButton:SetScript("OnClick", function() frame:Hide() end)
    view.minimizeButton = MOS.UI.CreateButton(view.titleBar, nil, "_", 18, 18)
    MOS.UI.SetClassicButtonCompact(view.minimizeButton, true)
    view.minimizeButton.label:SetTextColor(1, 0.82, 0.18)
    view.minimizeButton:SetPoint("RIGHT", view.closeButton, "LEFT", -4, 0)
    view.settingsButton = MOS.UI.CreateButton(view.titleBar, nil, "", 18, 18)
    MOS.UI.SetClassicButtonCompact(view.settingsButton, true)
    view.settingsButton:SetPoint("RIGHT", view.minimizeButton, "LEFT", -4, 0)
    view.settingsButton.icon = view.settingsButton:CreateTexture(nil, "OVERLAY")
    view.settingsButton.icon:SetPoint("CENTER", view.settingsButton, "CENTER", 0, 0)
    view.settingsButton.icon:SetWidth(15); view.settingsButton.icon:SetHeight(15)
    view.settingsButton.icon:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Assets\\SettingsGear")
    MOS.UI.AttachTooltip(view.settingsButton, "Settings", "Open Settings in a separate movable window.")
    MOS.UI.AttachGoldHoverBorder(view.settingsButton, 0.35, 0.35, 0.35, 1)
    local minimizeTooltipEnter = view.minimizeButton:GetScript("OnEnter")
    local minimizeTooltipLeave = view.minimizeButton:GetScript("OnLeave")
    MOS.UI.AttachGoldHoverBorder(view.minimizeButton, 0.35, 0.35, 0.35, 1)
    local minimizeBorderEnter = view.minimizeButton:GetScript("OnEnter")
    local minimizeBorderLeave = view.minimizeButton:GetScript("OnLeave")
    view.minimizeButton:SetScript("OnEnter", function()
        if minimizeTooltipEnter then minimizeTooltipEnter() end
        if minimizeBorderEnter then minimizeBorderEnter() end
    end)
    view.minimizeButton:SetScript("OnLeave", function()
        if minimizeTooltipLeave then minimizeTooltipLeave() end
        if minimizeBorderLeave then minimizeBorderLeave() end
    end)
    view.sidebarToggle = MOS.UI.CreateButton(view.titleBar, nil, "<<", 28, 20)
    MOS.UI.SetClassicButtonCompact(view.sidebarToggle, true)
    view.sidebarToggle:SetPoint("LEFT", view.titleBar, "LEFT", 5, 0)
    MOS.UI.AttachTooltip(view.sidebarToggle, "Navigation", "Collapse or restore the left navigation menu.")
    local navigationTooltipEnter = view.sidebarToggle:GetScript("OnEnter")
    local navigationTooltipLeave = view.sidebarToggle:GetScript("OnLeave")
    MOS.UI.AttachGoldHoverBorder(view.sidebarToggle, 0.35, 0.35, 0.35, 1)
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
    MOS.UI.RegisterSkinnedSurface(view.sidebar, "sidebar", { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }, { 0.05, 0.04, 0.02, 0.92 }, { 0.36, 0.36, 0.34, 1 })
    view.sidebarToggleClassicIcon = view.sidebarToggle:CreateTexture(nil, "OVERLAY")
    view.sidebarToggleClassicIcon:SetWidth(11); view.sidebarToggleClassicIcon:SetHeight(11); view.sidebarToggleClassicIcon:SetPoint("CENTER", view.sidebarToggle, "CENTER", 0, 0); view.sidebarToggleClassicIcon:Hide()
    view.classicMenuTitle = view.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.classicMenuTitle:SetPoint("TOPLEFT", view.sidebar, "TOPLEFT", 10, -9); view.classicMenuTitle:SetText("Menu"); view.classicMenuTitle:Hide()
    view.sidebar.classicMenuTitle = view.classicMenuTitle
    view.contentPanel = CreateFrame("Frame", nil, frame)
    view.contentPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 204, -68); view.contentPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 46)
    view.contentPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    view.contentPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.90); view.contentPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
    MOS.UI.RegisterSkinnedSurface(view.contentPanel, "content", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }, { 0.02, 0.02, 0.02, 0.90 }, { 0.36, 0.36, 0.34, 1 })
    local background = view.sidebar:CreateTexture(nil, "BACKGROUND")
    background:SetPoint("TOPLEFT", view.sidebar, "TOPLEFT", 5, -5); background:SetPoint("BOTTOMRIGHT", view.sidebar, "BOTTOMRIGHT", -5, 5)
    background:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\DashboardBackground"); background:SetTexCoord(0.22, 0.58, 0, 1); background:SetAlpha(0.72)
    local backgroundShade = view.sidebar:CreateTexture(nil, "BORDER")
    backgroundShade:SetAllPoints(view.sidebar); backgroundShade:SetTexture(0, 0, 0, 0.40)
    view.contentShade = view.contentPanel:CreateTexture(nil, "BACKGROUND")
    view.contentShade:SetPoint("TOPLEFT", view.contentPanel, "TOPLEFT", 5, -5); view.contentShade:SetPoint("BOTTOMRIGHT", view.contentPanel, "BOTTOMRIGHT", -5, 5)
    view.contentShade:SetTexture(0.025, 0.022, 0.018, 0.96)
    MOS.UI.RegisterSkinCallback(function(skin)
        local classic = skin == "classic"
        if classic and not view.minimized then view.title:Hide(); view.classicTitle:Show() else view.classicTitle:Hide(); view.title:Show() end
        if classic and not view.minimized then view.classicLogo:Show(); view.classicTitleLeft:Show(); view.classicTitleRight:Show(); view.classicMenuTitle:Show()
        else view.classicLogo:Hide(); view.classicTitleLeft:Hide(); view.classicTitleRight:Hide(); view.classicMenuTitle:Hide() end
        view.titleBar:ClearAllPoints()
        if classic then view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8); view.titleBar:SetHeight(44)
        else view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -14); view.titleBar:SetHeight(32) end
        local margin = classic and 8 or 18
        local sectionGap = classic and 4 or 6
        local sectionTop = -(classic and 52 or 46) - sectionGap
        local footerBottom = margin
        local sectionBottom = footerBottom + 22 + sectionGap
        view.sidebar:ClearAllPoints()
        view.sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", margin, sectionTop)
        view.sidebar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", margin, sectionBottom)
        view.contentPanel:ClearAllPoints()
        view.contentPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", classic and 157 or 193, sectionTop)
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
            view.resizeGrip.texture:SetTexture(MOS.UI.ClassicAsset("Icons\\resize.tga")); view.resizeGrip.texture:SetVertexColor(1, 0.78, 0.24)
            view.resizeGrip.texture:ClearAllPoints(); view.resizeGrip.texture:SetPoint("CENTER", view.resizeGrip, "CENTER", 0, 0); view.resizeGrip.texture:SetWidth(13); view.resizeGrip.texture:SetHeight(13)
        else
            view.sidebarToggle:SetParent(view.titleBar); view.sidebarToggle:ClearAllPoints(); view.sidebarToggle:SetPoint("LEFT", view.titleBar, "LEFT", 5, 0); view.sidebarToggle:SetWidth(28); view.sidebarToggle:SetHeight(20)
            view.sidebarToggleClassicIcon:Hide()
            view.resizeGrip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"); view.resizeGrip.texture:SetVertexColor(1, 1, 1)
            view.resizeGrip.texture:ClearAllPoints(); view.resizeGrip.texture:SetAllPoints(view.resizeGrip)
        end
    end)
    return view
end

function Dashboard.CreateStatusBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    parent.mosStatusBar = bar
    local margin = MOS.UI.IsClassicSkin() and 8 or 18
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", margin, margin)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -126, margin)
    bar:SetHeight(22)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    bar:SetBackdropColor(0.025, 0.022, 0.018, 0.94)
    bar:SetBackdropBorderColor(0.30, 0.30, 0.28, 1)
    MOS.UI.RegisterSkinnedSurface(bar, "status", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }, { 0.025, 0.022, 0.018, 0.94 }, { 0.30, 0.30, 0.28, 1 })
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

function Dashboard.CreatePages(contentPanel)
    local pages = {}
    pages.roster = CreateFrame("Frame", nil, contentPanel)
    pages.roster:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 3, -3)
    pages.roster:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -3, 3)
    pages.statistics = CreateFrame("Frame", nil, contentPanel)
    pages.statistics:SetAllPoints(pages.roster); pages.statistics:Hide()
    pages.raidStatistics = CreateFrame("Frame", nil, contentPanel)
    pages.raidStatistics:SetAllPoints(pages.roster); pages.raidStatistics:Hide()
    pages.csr = CreateFrame("Frame", nil, contentPanel)
    pages.csr:SetAllPoints(pages.roster); pages.csr:Hide()
    pages.raid = CreateFrame("Frame", nil, contentPanel)
    -- The roster frame is moved independently when Loot Master mode changes.
    -- Raid layout must follow the content panel itself, not that mutable frame.
    pages.raid:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 3, -3)
    pages.raid:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -3, 3)
    pages.raid:Hide()
    pages.about = CreateFrame("Frame", nil, contentPanel)
    pages.about:SetAllPoints(pages.roster); pages.about:Hide()
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
        if options.isLootMasterMode() then options.saveLootGeometry() else options.saveGeometry() end
    end)
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
        this.layoutElapsed = 0
        this:SetScript("OnUpdate", this.UpdateLayout)
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing(); this:SetScript("OnUpdate", nil)
        if options.isLootMasterMode() then options.saveLootGeometry() else options.saveGeometry() end
        if options.isLootMasterMode() then options.refreshLayout() else options.applyOrRefreshLayout() end
    end)
    grip:SetScript("OnHide", function() frame:StopMovingOrSizing(); this:SetScript("OnUpdate", nil) end)

    view.ToggleMinimize = function()
        if options.isLootMasterMode() then return end
        if view.minimized then
            view.minimized = false
            frame:SetMinResize(760, 420); frame:SetMaxResize(1100, 760)
            frame:SetWidth(view.widthBeforeMinimize or 840); frame:SetHeight(view.heightBeforeMinimize or 540)
            frame:ClearAllPoints()
            if view.leftBeforeMinimize and view.bottomBeforeMinimize then frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", view.leftBeforeMinimize, view.bottomBeforeMinimize) else frame:SetPoint("CENTER", UIParent, "CENTER", 0, 10) end
            view.title:ClearAllPoints(); view.title:SetPoint("CENTER", view.titleBar, "CENTER", 0, 2)
            view.title:SetFontObject(GameFontNormalLarge)
            view.minimizeButton:SetText("-"); view.title:SetText("Mukla Officer Suite")
            view.classicTitle:ClearAllPoints(); view.classicTitle:SetPoint("CENTER", view.titleBar, "CENTER", 0, 1); view.classicTitle:SetWidth(220); view.classicTitle:SetHeight(19)
            if MOS.UI.IsClassicSkin() then
                view.title:Hide(); view.classicTitle:Show(); view.classicLogo:Show(); view.classicTitleLeft:Show(); view.classicTitleRight:Show()
                view.titleBar:ClearAllPoints(); view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8); view.titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8); view.titleBar:SetHeight(44)
            end
            view.sidebar:Show(); view.contentPanel:Show(); options.statusBar:Show(); view.versionText:Show(); view.resizeGrip:Show(); view.sidebarToggle:Show()
            if options.setNavigationVisible then options.setNavigationVisible(true) end
            options.applyOrRefreshLayout()
        else
            view.widthBeforeMinimize = frame:GetWidth(); view.heightBeforeMinimize = frame:GetHeight(); view.leftBeforeMinimize = frame:GetLeft(); view.bottomBeforeMinimize = frame:GetBottom()
            options.saveGeometry()
            view.minimized = true
            view.sidebar:Hide(); view.contentPanel:Hide(); options.statusBar:Hide(); view.versionText:Hide(); view.resizeGrip:Hide(); view.sidebarToggle:Hide()
            if options.setNavigationVisible then options.setNavigationVisible(false) end
            frame:SetMinResize(250, 40); frame:SetMaxResize(250, 40); frame:SetWidth(250); frame:SetHeight(40)
            view.titleBar:ClearAllPoints(); view.titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5); view.titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
            view.title:ClearAllPoints(); view.title:SetPoint("LEFT", view.titleBar, "LEFT", 9, 1); view.title:SetFontObject(GameFontNormal)
            view.title:SetText("Mukla Officer Suite"); view.minimizeButton:SetText("[]")
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
        MOS.UI.AnchorTooltipRightOfCursor(this)
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
