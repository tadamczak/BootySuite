local MOS = MuklaOfficerSuite

MOS.UI.Components.Navigation = MOS.UI.Components.Navigation or {}
local Navigation = MOS.UI.Components.Navigation

function Navigation.SetActive(buttons, activeName)
    local name, button
    for name, button in pairs(buttons) do
        local selected = name == activeName
        button.navigationSelected = selected
        if button.navigationMode == "tabs" then
            button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", tile = true, tileSize = 8, edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
            button:SetBackdropColor(0, 0, 0, 0); button:SetBackdropBorderColor(0, 0, 0, 0)
            if button.mosHighlight then button.mosHighlight:Hide() end
            button.label:SetTextColor(selected and 1 or 0.82, selected and 0.82 or 0.70, selected and 0.18 or 0.43)
            button.SetTabBorderVisible(selected)
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
        local button = MOS.UI.Components.CreateControl(nil, options.sidebar)
        button:SetPoint("TOPLEFT", options.sidebar, "TOPLEFT", 10, y)
        button:SetWidth(154)
        button:SetHeight(40)
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        local icon = MOS.UI.Components.CreateTexture(button, nil, "ARTWORK")
        icon:SetWidth(28); icon:SetHeight(28); icon:SetPoint("LEFT", button, "LEFT", 9, 0); icon:SetTexture(iconPath)
        button.icon = icon
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
        button:SetScript("OnEnter", function() if this.navigationMode == "tabs" then this.SetTabBorderVisible(true) end end)
        button:SetScript("OnLeave", function() if this.navigationMode == "tabs" then this.SetTabBorderVisible(this.navigationSelected) end end)
        MOS.UI.Components.RegisterSkinnedNavigation(button, name, iconPath)
        controller.buttons[name] = button
    end

    local itemIndex
    for itemIndex = 1, table.getn(options.items) do
        local item = options.items[itemIndex]
        CreateButton(item.key, item.text, ys[itemIndex], item.icon)
    end

    function controller.Toggle(forceState)
        if options.get("menuStyle") == "tabs" then return end
        local collapse = forceState
        if collapse == nil then collapse = not options.get("sidebarCollapsed") end
        if collapse == options.get("sidebarCollapsed") then return end
        options.set("sidebarCollapsed", collapse)
        controller.Apply()
    end

    function controller.Apply()
        options.ensure()
        local tabs = options.get("menuStyle") == "tabs"
        if tabs then
            options.sidebar:Hide(); options.toggleButton:Hide()
            local margin = MOS.UI.Components.IsClassicSkin() and 8 or 18
            options.contentPanel:ClearAllPoints(); options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", margin, -98); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -margin, margin + 28)
            local width = math.floor((options.dashboard:GetWidth() - 40) / table.getn(order))
            local index, name
            for index, name in ipairs(order) do
                local button = controller.buttons[name]
                button.navigationMode = "tabs"
                button:SetParent(options.dashboard); button:ClearAllPoints(); button:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", 20 + ((index - 1) * width), -70)
                button:SetFrameStrata("DIALOG"); button:SetFrameLevel(options.dashboard:GetFrameLevel() + 20); button:SetWidth(width); button:SetHeight(30)
                button.icon:Hide(); button.iconBorder:Hide(); button:Show(); button.label:Show(); button.label:ClearAllPoints(); button.label:SetAllPoints(button); button.label:SetWidth(width); button.label:SetJustifyH("CENTER")
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
                options.sidebar:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", 8, -56); options.sidebar:SetPoint("BOTTOMLEFT", options.dashboard, "BOTTOMLEFT", 8, 34); options.sidebar:SetWidth(collapsed and 44 or 148)
            else
                options.sidebar:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", 18, -52); options.sidebar:SetPoint("BOTTOMLEFT", options.dashboard, "BOTTOMLEFT", 18, 42); options.sidebar:SetWidth(collapsed and 54 or 174)
            end
            options.contentPanel:ClearAllPoints()
            if classic then options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", collapsed and 53 or 157, -56); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -8, 34)
            else options.contentPanel:SetPoint("TOPLEFT", options.dashboard, "TOPLEFT", collapsed and 73 or 193, -52); options.contentPanel:SetPoint("BOTTOMRIGHT", options.dashboard, "BOTTOMRIGHT", -18, 42) end
            local index, name
            for index, name in ipairs(order) do
                local button = controller.buttons[name]
                button.navigationMode = "buttons"; button.SetTabBorderVisible(false)
                button:SetParent(options.sidebar); button:ClearAllPoints(); button:SetPoint("TOPLEFT", options.sidebar, "TOPLEFT", classic and 3 or 10, classic and (-34 - ((index - 1) * 37)) or ys[index])
                button:SetFrameStrata("DIALOG"); button:SetFrameLevel(options.sidebar:GetFrameLevel() + 2); button:Show(); button:SetWidth(classic and ((collapsed and 44 or 148) - 6) or (collapsed and 38 or 154)); button:SetHeight(classic and 37 or 40)
                button.icon:Show(); if classic then button.iconBorder:Hide() else button.iconBorder:Show() end; button.icon:ClearAllPoints(); button.icon:SetPoint(collapsed and "CENTER" or "LEFT", button, collapsed and "CENTER" or "LEFT", collapsed and 0 or (classic and 11 or 9), 0)
                button.icon:SetWidth(classic and 20 or 28); button.icon:SetHeight(classic and 20 or 28)
                button.label:ClearAllPoints(); button.label:SetPoint("LEFT", button, "LEFT", classic and 35 or 44, 0); button.label:SetWidth(classic and 108 or 108); button.label:SetHeight(14); button.label:SetJustifyH("LEFT")
                if collapsed then button.label:Hide() else button.label:Show() end
            end
            if classic and options.toggleButtonClassicIcon then
                options.toggleButton:SetText("")
                options.toggleButtonClassicIcon:SetTexture(MOS.UI.Components.ClassicAsset("Icons\\chevron_" .. (collapsed and "right" or "left") .. ".tga"))
                options.toggleButtonClassicIcon:Show()
            else options.toggleButton:SetText(collapsed and ">>" or "<<") end
        end
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
