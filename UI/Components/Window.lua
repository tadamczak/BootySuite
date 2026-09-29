local MOS = MuklaOfficerSuite
local Window = {}
MOS.UI.Components.Window = Window

function Window.Create(options)
    local view
    local window = MOS.UI.Components.CreateContainer(options.name, UIParent)
    window:SetWidth(780); window:SetHeight(620)
    window:SetPoint("CENTER", UIParent, "CENTER", 40, 10)
    window:SetFrameStrata("FULLSCREEN_DIALOG"); window:SetFrameLevel(200); window:SetMovable(true); window:SetResizable(true)
    if window.SetClampedToScreen then window:SetClampedToScreen(true) end
    window:SetMinResize(350, 420); window:SetMaxResize(1100, 760)
    window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function() this:StartMoving() end)
    window:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    local windowBackdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } }
    window:SetBackdrop(windowBackdrop)
    window:SetBackdropColor(0.015, 0.015, 0.015, 1); window:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)

    local titleBar = MOS.UI.Components.CreateContainer(nil, window)
    titleBar:SetFrameLevel(window:GetFrameLevel() + 1)
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", 4, -8); titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -8); titleBar:SetHeight(options.compact and 28 or 36)
    if not options.plainHeader then
        MOS.UI.Components.RegisterSkinnedSurface(titleBar, "title", { bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }, { 0.025, 0.022, 0.018, 0.98 }, { 0.42, 0.42, 0.40, 1 })
    end
    local title = MOS.UI.Components.CreateHeading(titleBar, "", options.compact and 3 or 1, "gold")
    if options.compact then local font, size, flags = title:GetFont(); title:SetFont(font, size - 1, flags) end
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0); title:SetText(options.title)
    local close = MOS.UI.Components.CreateWindowButton(titleBar, nil, "close")
    close:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
    local minimize = MOS.UI.Components.CreateWindowButton(titleBar, nil, "minimize")
    minimize:SetPoint("RIGHT", close, "LEFT", -4, 0)
    local content = MOS.UI.Components.CreateContainer(nil, window)
    content:SetFrameLevel(window:GetFrameLevel() + 1)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, options.plainHeader and -8 or 0); content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -4, options.compact and 4 or 14)
    content.mosUseNativeSurface = options.plainHeader
    MOS.UI.Components.RegisterSkinnedSurface(content, "content", options.plainHeader and windowBackdrop or { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } }, { 0.02, 0.02, 0.02, 1 }, options.plainHeader and {0.68,0.54,0.27,1} or { 0.36, 0.36, 0.34, 1 })
    local resize = MOS.UI.Components.CreateResizeGrip(window)
    if options.compact then
        resize.texture:Hide(); resize:ClearAllPoints(); resize:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 0, 0)
    end
    resize:SetFrameStrata("FULLSCREEN_DIALOG"); resize:SetFrameLevel(window:GetFrameLevel() + 250); resize:EnableMouse(true)
    MOS.UI.Components.AttachTooltip(resize, "Resize Settings", "Drag to change the window size.")
    resize:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() window:StopMovingOrSizing(); if view then options.update(view) end end)

    resize:SetScript("OnHide", function() window:StopMovingOrSizing() end)

    local function ApplyResizeBounds()
        local screenWidth = (UIParent.GetWidth and UIParent:GetWidth()) or 1100
        local screenHeight = (UIParent.GetHeight and UIParent:GetHeight()) or 760
        local maximumWidth = math.max(320, math.min(1100, screenWidth - 32))
        local maximumHeight = math.max(260, math.min(760, screenHeight - 32))
        local minimumWidth = math.min(350, maximumWidth)
        local minimumHeight = math.min(420, maximumHeight)
        window:SetMinResize(minimumWidth, minimumHeight); window:SetMaxResize(maximumWidth, maximumHeight)
        if window:GetWidth() > maximumWidth then window:SetWidth(maximumWidth) end
        if window:GetHeight() > maximumHeight then window:SetHeight(maximumHeight) end
        if window:GetWidth() < minimumWidth then window:SetWidth(minimumWidth) end
        if window:GetHeight() < minimumHeight then window:SetHeight(minimumHeight) end
    end
    window:SetScript("OnSizeChanged", function() if view then options.update(view) end end)

    local function CloseWindow() window:Hide() end
    close:SetScript("OnClick", CloseWindow)
    minimize:SetScript("OnClick", function()
        if not view then return end
        if window.minimized then
            window.minimized = false; window:SetHeight(window.expandedHeight or 620); content:Show(); resize:Show(); view.viewport:Show(); MOS.UI.Components.SetWindowButtonAction(minimize, "minimize")
        else
            window.minimized = true; window.expandedHeight = window:GetHeight(); view.viewport:Hide(); content:Hide(); resize:Hide(); window:SetHeight(options.compact and 44 or 50); MOS.UI.Components.SetWindowButtonAction(minimize, "maximize")
        end
    end)
    local function FinishOpen()
        window:SetScript("OnUpdate", nil)
        if not window:IsVisible() or not view then return end
        view.viewport:SetScrollChild(view.page)
        view.page:Show()
        options.update(view)
        if view.viewport.UpdateScrollChildRect then view.viewport:UpdateScrollChildRect() end
    end
    window:SetScript("OnHide", function() window:SetScript("OnUpdate", nil) end)
    window.Open = function()
        if window:IsVisible() or not view then return end
        ApplyResizeBounds()
        window.minimized = false; content:Show(); resize:Show(); MOS.UI.Components.SetWindowButtonAction(minimize, "minimize")
        window:Show(); view.viewport:SetVerticalScroll(0); view.viewport:Show()
        if view.scrollBar then view.scrollBar:SetValue(0) end
        if options.refresh then options.refresh(view) end
        options.update(view)
        window:SetScript("OnUpdate", FinishOpen)
    end
    window.Toggle = function() if window:IsVisible() then CloseWindow() else window.Open() end end
    window.AttachView = function(settingsView)
        view = settingsView
        options.attach(view, content)
        view.viewport:Hide()
    end
    window.titleBar = titleBar
    window.content = content
    window.resizeGrip = resize
    window.ApplyResizeBounds = ApplyResizeBounds
    window:Hide()
    return window
end
