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
    window:SetMinResize(760, 480); window:SetMaxResize(1100, 760)
    window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function() this:StartMoving() end)
    window:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    window:SetBackdropColor(0.015, 0.015, 0.015, 1); window:SetBackdropBorderColor(0.68, 0.54, 0.27, 1)

    local titleBar = MOS.UI.Components.CreateContainer(nil, window)
    titleBar:SetFrameLevel(window:GetFrameLevel() + 1)
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -10); titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10); titleBar:SetHeight(30)
    local title = MOS.UI.Components.CreateLabel(titleBar, nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0); title:SetText(options.title)
    local close = MOS.UI.Components.CreateButton(titleBar, nil, "X", 18, 18)
    close:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0); MOS.UI.Components.SetClassicButtonCompact(close, true); MOS.UI.Components.AttachGoldHoverBorder(close, 0.35, 0.35, 0.35, 1)
    close.label:SetTextColor(1, 0.82, 0.18)
    local minimize = MOS.UI.Components.CreateButton(titleBar, nil, "_", 18, 18)
    minimize:SetPoint("RIGHT", close, "LEFT", -4, 0); MOS.UI.Components.SetClassicButtonCompact(minimize, true); MOS.UI.Components.AttachGoldHoverBorder(minimize, 0.35, 0.35, 0.35, 1)
    minimize.label:SetTextColor(1, 0.82, 0.18)
    local content = MOS.UI.Components.CreateContainer(nil, window)
    content:SetFrameLevel(window:GetFrameLevel() + 1)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -42); content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -8, 8)
    local resize = MOS.UI.Components.CreateControl(nil, window)
    resize:SetFrameStrata("FULLSCREEN_DIALOG"); resize:SetFrameLevel(window:GetFrameLevel() + 250); resize:EnableMouse(true)
    resize:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -7, 7); resize:SetWidth(18); resize:SetHeight(18)
    local resizeTexture = MOS.UI.Components.CreateTexture(resize, nil, "OVERLAY"); resizeTexture:SetAllPoints(resize); resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() window:StopMovingOrSizing(); options.update(view) end)

    local function ApplyResizeBounds()
        local screenWidth = (UIParent.GetWidth and UIParent:GetWidth()) or 1100
        local screenHeight = (UIParent.GetHeight and UIParent:GetHeight()) or 760
        local maximumWidth = math.max(320, math.min(1100, screenWidth - 32))
        local maximumHeight = math.max(260, math.min(760, screenHeight - 32))
        local minimumWidth = math.min(760, maximumWidth)
        local minimumHeight = math.min(480, maximumHeight)
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
            window.minimized = false; window:SetHeight(window.expandedHeight or 620); content:Show(); resize:Show(); view.viewport:Show(); minimize:SetText("_")
        else
            window.minimized = true; window.expandedHeight = window:GetHeight(); view.viewport:Hide(); content:Hide(); resize:Hide(); window:SetHeight(50); minimize:SetText("[]")
        end
    end)
    window.Open = function()
        if window:IsVisible() or not view then return end
        ApplyResizeBounds()
        window.minimized = false; content:Show(); resize:Show(); minimize:SetText("_")
        window:Show(); view.viewport:SetVerticalScroll(0); view.viewport:Show()
        if view.scrollBar then view.scrollBar:SetValue(0) end
        if options.refresh then options.refresh(view) end
        options.update(view)
    end
    window.Toggle = function() if window:IsVisible() then CloseWindow() else window.Open() end end
    window.AttachView = function(settingsView)
        view = settingsView
        options.attach(view, content)
        view.viewport:Hide()
    end
    window.content = content
    window.resizeGrip = resize
    window.ApplyResizeBounds = ApplyResizeBounds
    window:Hide()
    return window
end
