local MOS = MuklaOfficerSuite

MOS.UI.Components.Navigation = MOS.UI.Components.Navigation or {}
local Navigation = MOS.UI.Components.Navigation

function Navigation.FitTabCaption(button, available)
    local label = button.label
    label:ClearAllPoints(); label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(button.navigationText); label:SetWidth(0); label:SetHeight(28)
    if label:GetStringWidth() > available and button.navigationShortText then label:SetText(button.navigationShortText) end
    label:SetWidth(math.max(1, available))
end

function Navigation.SetActive(buttons, activeName)
    local name, button
    for name, button in pairs(buttons) do
        local selected = name == activeName
        button.navigationSelected = selected
        button.selectedFill:Hide(); button.hoverFill:Show()
        if button.navigationMode == "tabs" then
            button:SetBackdrop({ bgFile = MOS.UI.Components.IsClassicSkin() and MOS.UI.Components.ClassicAsset("Surfaces\\sidebar.tga") or "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16, edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
            if MOS.UI.Components.IsClassicSkin() then button:SetBackdropColor(1, 1, 1, 1)
            else button:SetBackdropColor(0.04, 0.03, 0.02, 0.98) end; button:SetBackdropBorderColor(0, 0, 0, 0)
            button:SetHeight(selected and 30 or 26)
            button:ClearAllPoints()
            button:SetPoint(button.navigationBottom and "TOPLEFT" or "BOTTOMLEFT", button.navigationContent, button.navigationBottom and "BOTTOMLEFT" or "TOPLEFT", button.navigationX, selected and (button.navigationBottom and 2 or -2) or 0)
            if selected then button.selectedFill:Show(); button.hoverFill:Hide() end
            if button.icon then button.icon:SetVertexColor(selected and 1 or 0.82, selected and 0.82 or 0.70, selected and 0.28 or 0.43) end
            button:SetFrameLevel(button:GetParent():GetFrameLevel() + (selected and 24 or 20))
            if button.mosHighlight then button.mosHighlight:Hide() end
            button.label:SetTextColor(selected and 1 or 0.82, selected and 0.82 or 0.70, selected and 0.18 or 0.43)
            button.SetTabBorderVisible(true)
        elseif MOS.UI.Components.IsClassicSkin() then
            button:SetBackdrop({ bgFile = MOS.UI.Components.ClassicAsset("Surfaces\\nav-" .. (selected and "selected" or "normal") .. ".tga"), tile = false, tileSize = 0, edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
            button:SetBackdropColor(1, 1, 1, 1)
            button.label:SetTextColor(selected and 1 or 0.82, selected and 0.82 or 0.70, selected and 0.28 or 0.43)
            if button.icon then button.icon:SetVertexColor(selected and 1 or 0.82, selected and 0.82 or 0.70, selected and 0.28 or 0.43) end
        elseif name == activeName then
            button:SetBackdropColor(0.32, 0.19, 0.02, 0.96)
            button:SetBackdropBorderColor(1, 0.72, 0.08, 1)
            button.label:SetTextColor(1, 0.82, 0.18)
            if button.icon and MOS.UI.Components.IsClassicSkin() then button.icon:SetVertexColor(1, 0.82, 0.28) end
        else
            button:SetBackdropColor(0.12, 0.07, 0.02, 0.92)
            button:SetBackdropBorderColor(0.52, 0.31, 0.07, 1)
            button.label:SetTextColor(0.95, 0.72, 0.18)
            if button.icon and MOS.UI.Components.IsClassicSkin() then button.icon:SetVertexColor(0.82, 0.70, 0.43) end
        end
    end
end

function Navigation.Create(options)
    local controller = { buttons = {} }
    local order = options.order
    local ys = { -10, -53, -96, -139, -182, -225, -268 }

    local function CreateButton(name, text, y, iconPath)
        local button = MOS.UI.Components.CreateControl(nil, options.dashboard)
        button:SetPoint("TOPLEFT", options.sidebar, "TOPLEFT", 10, y)
        button:SetWidth(154)
        button:SetHeight(40)
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        local icon = MOS.UI.Components.CreateTexture(button, nil, "ARTWORK")
        icon:SetWidth(28); icon:SetHeight(28); icon:SetPoint("LEFT", button, "LEFT", 9, 0); icon:SetTexture(iconPath)
        button.icon = icon; button.navigationText = text
        local iconBorder = MOS.UI.Components.CreateTexture(button, nil, "OVERLAY")
        iconBorder:SetWidth(36); iconBorder:SetHeight(36); iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0); iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        button.iconBorder = iconBorder
        button.label = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontNormalSmall")
        button.label:SetPoint("LEFT", button, "LEFT", 44, 0); button.label:SetWidth(108); button.label:SetHeight(14); button.label:SetJustifyH("LEFT"); button.label:SetText(text)
        local font, size, flags = button.label:GetFont()
        if font then button.label:SetFont(font, math.min(10, size or 10), flags) end
        button:SetScript("OnClick", function() options.showPage(name) end)
        button.tabBorderLeft = MOS.UI.Components.CreateTexture(button, nil, "OVERLAY"); button.tabBorderLeft:SetTexture("Interface\\Buttons\\WHITE8X8"); button.tabBorderLeft:SetVertexColor(1, 0.72, 0.08, 1); button.tabBorderLeft:SetWidth(1); button.tabBorderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0); button.tabBorderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
        button.tabBorderRight = MOS.UI.Components.CreateTexture(button, nil, "OVERLAY"); button.tabBorderRight:SetTexture("Interface\\Buttons\\WHITE8X8"); button.tabBorderRight:SetVertexColor(1, 0.72, 0.08, 1); button.tabBorderRight:SetWidth(1); button.tabBorderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0); button.tabBorderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        button.tabBorderTop = MOS.UI.Components.CreateTexture(button, nil, "OVERLAY"); button.tabBorderTop:SetTexture("Interface\\Buttons\\WHITE8X8"); button.tabBorderTop:SetVertexColor(1, 0.72, 0.08, 1); button.tabBorderTop:SetHeight(1); button.tabBorderTop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0); button.tabBorderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
        button.SetTabBorderVisible = function(visible)
            MOS.UI.Components.SetNavigationTabBorder(button, visible)
        end
        button.SetTabBorderVisible(false)
        button.selectedFill = MOS.UI.Components.CreateTexture(button, nil, "BORDER")
        button.selectedFill:SetAllPoints(button); button.selectedFill:SetTexture("Interface\\Buttons\\WHITE8X8"); button.selectedFill:SetVertexColor(0.82, 0.70, 0.43, 0.14); button.selectedFill:Hide()
        button.hoverFill = MOS.UI.Components.CreateTexture(button, nil, "HIGHLIGHT")
        button.hoverFill:SetAllPoints(button); button.hoverFill:SetTexture("Interface\\Buttons\\WHITE8X8"); button.hoverFill:SetVertexColor(0.82, 0.70, 0.43, 0.14)
        button:SetScript("OnEnter", function() if this.navigationMode == "tabs" then this.SetTabBorderVisible(true) end end)
        button:SetScript("OnLeave", function() if this.navigationMode == "tabs" then this.SetTabBorderVisible(true) end end)
        MOS.UI.Components.RegisterSkinnedNavigation(button, name, iconPath)
        controller.buttons[name] = button
    end

    local itemIndex
    for itemIndex = 1, table.getn(options.items) do
        local item = options.items[itemIndex]
        CreateButton(item.key, item.text, ys[itemIndex], item.icon)
        controller.buttons[item.key].navigationShortText = item.shortText
    end

    function controller.Toggle(forceState)
        if options.get("menuStyle") == "tabs" or options.get("menuStyle") == "bottomTabs" then return end
        local collapse = forceState
        if collapse == nil then collapse = not options.get("sidebarCollapsed") end
        if collapse == options.get("sidebarCollapsed") then return end
        options.set("sidebarCollapsed", collapse)
        controller.Apply()
    end

    function controller.Apply()
        options.ensure()
        local bottomTabs = options.get("menuStyle") == "bottomTabs"
        local tabs = options.get("menuStyle") == "tabs" or bottomTabs
        local _, sectionTop, sectionBottom, tabTop = MOS.UI.Components.Dashboard.GetChromeLayout(options.get, MOS.UI.Components.IsClassicSkin())
        if tabs then
            options.sidebar:Hide(); options.toggleButton:Hide()
            local margin = MOS.UI.Components.IsClassicSkin() and 8 or 18
            local bottom = options.get("hideStatusVersionBar") and margin or margin + 28
            options.contentPanel:ClearAllPoints(); options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", margin, bottomTabs and sectionTop or tabTop - 28); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -margin, bottomTabs and bottom + 30 or bottom)
            local iconTabs = options.get("useIconTabs")
            local classic = MOS.UI.Components.IsClassicSkin()
            local width = iconTabs and 38 or math.floor((options.dashboard:GetWidth() - 2 * margin - 24) / table.getn(order))
            local index, name
            for index, name in ipairs(order) do
                local button = controller.buttons[name]
                button.navigationBottom = bottomTabs
                button.navigationMode = "tabs"
                button.navigationContent = options.contentPanel
                button.navigationX = 12 + ((index - 1) * width)
                button.SetTabBorderVisible(false)
                button:SetScale(1); button:ClearAllPoints(); button:SetPoint(bottomTabs and "BOTTOMLEFT" or "TOPLEFT", options.dashboard, bottomTabs and "BOTTOMLEFT" or "TOPLEFT", 20 + ((index - 1) * width), bottomTabs and bottom or tabTop)
                button:SetFrameStrata(options.dashboard:GetFrameStrata()); button:SetFrameLevel(options.dashboard:GetFrameLevel() + 20); button:SetWidth(width - (iconTabs and 0 or 4)); button:SetHeight(30)
                button.iconBorder:Hide(); button:Show()
                if iconTabs then
                    button.label:Hide(); button.icon:Show(); button.icon:ClearAllPoints()
                    button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
                    button.icon:SetWidth(classic and 20 or 28); button.icon:SetHeight(classic and 20 or 28)
                    button.iconBorder:Hide()
                else
                    button.icon:Hide(); button.label:Show(); button.label:ClearAllPoints(); button.label:SetAllPoints(button); button.label:SetWidth(width - 12); button.label:SetJustifyH("CENTER")
                    Navigation.FitTabCaption(button, width - 12)
                end
            end
        else
            options.sidebar:Show(); options.toggleButton:Show()
            local collapsed = options.get("sidebarCollapsed")
            local classic = MOS.UI.Components.IsClassicSkin()
            if options.sidebar.classicMenuTitle then
                if classic and not collapsed then options.sidebar.classicMenuTitle:Show() else options.sidebar.classicMenuTitle:Hide() end
            end
            options.sidebar:ClearAllPoints()
            if classic then
                options.sidebar:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", 8, sectionTop); options.sidebar:SetPoint("BOTTOMLEFT", options.dashboard, "BOTTOMLEFT", 8, sectionBottom); options.sidebar:SetWidth(collapsed and 44 or 148)
            else
                options.sidebar:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", 18, sectionTop); options.sidebar:SetPoint("BOTTOMLEFT", options.dashboard, "BOTTOMLEFT", 18, sectionBottom); options.sidebar:SetWidth(collapsed and 54 or 174)
            end
            options.contentPanel:ClearAllPoints()
            if classic then options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", collapsed and 53 or 157, sectionTop); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -8, sectionBottom)
            else options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", collapsed and 73 or 193, sectionTop); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -18, sectionBottom) end
            local index, name
            for index, name in ipairs(order) do
                local button = controller.buttons[name]
                button.navigationMode = "buttons"; button.SetTabBorderVisible(false)
                button:SetScale(1); button:ClearAllPoints(); button:SetPoint("TOPLEFT", options.sidebar, "TOPLEFT", classic and 3 or 10, classic and (-34 - ((index - 1) * 37)) or ys[index])
                button:SetFrameStrata(options.dashboard:GetFrameStrata()); button:SetFrameLevel(options.sidebar:GetFrameLevel() + 2); button:Show(); button:SetWidth(classic and ((collapsed and 44 or 148) - 6) or (collapsed and 38 or 154)); button:SetHeight(classic and 37 or 40)
                button.icon:Show(); if classic then button.iconBorder:Hide() else button.iconBorder:Show() end; button.icon:ClearAllPoints(); button.icon:SetPoint(collapsed and "CENTER" or "LEFT", button, collapsed and "CENTER" or "LEFT", collapsed and 0 or (classic and 11 or 9), 0)
                button.icon:SetWidth(classic and 20 or 28); button.icon:SetHeight(classic and 20 or 28)
                button.label:ClearAllPoints(); button.label:SetPoint("LEFT", button, "LEFT", classic and 35 or 44, 0); button.label:SetWidth(classic and 108 or 108); button.label:SetHeight(14); button.label:SetJustifyH("LEFT")
                button.label:SetText(button.navigationText)
                if collapsed then button.label:Hide() else button.label:Show() end
            end
            if classic and options.toggleButtonClassicIcon then
                options.toggleButton:SetText("")
                options.toggleButtonClassicIcon:SetTexture(MOS.UI.Components.ClassicAsset("Icons\\chevron_" .. (collapsed and "right" or "left") .. ".tga"))
                options.toggleButtonClassicIcon:Show()
            else options.toggleButton:SetText(collapsed and ">>" or "<<") end
        end
        if options.applyChrome then options.applyChrome() end
        Navigation.SetActive(controller.buttons, controller.activeName or options.order[1])
        if options.refreshLayout then options.refreshLayout() end
    end

    function controller.SetActive(name)
        controller.activeName = name
        Navigation.SetActive(controller.buttons, name)
    end

    MOS.UI.Components.RegisterSkinCallback(function()
        controller.Apply()
        Navigation.SetActive(controller.buttons, controller.activeName or options.order[1])
    end)

    return controller
end
