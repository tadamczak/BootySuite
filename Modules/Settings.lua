local MOS = MuklaOfficerSuite

MOS.Modules.Settings = MOS.Modules.Settings or {}
local Settings = MOS.Modules.Settings

local function OnSettingsMouseWheel()
    local page = this.settingsPage
    local maximum = math.max(0, page:GetHeight() - this:GetHeight())
    local value = math.max(0, math.min(maximum, this:GetVerticalScroll() - (arg1 * 46)))
    local scrollBar = getglobal("MuklaOfficerSuiteSettingsScrollScrollBar")
    if scrollBar then scrollBar:SetValue(value) else this:SetVerticalScroll(value) end
end

function Settings.CreateShell(parent, anchorPage, onNavigationLayout)
    local viewport = CreateFrame("ScrollFrame", "MuklaOfficerSuiteSettingsScroll", parent, "UIPanelScrollFrameTemplate")
    MOS.UI.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteSettingsScrollScrollBar"))
    viewport:SetPoint("TOPLEFT", anchorPage, "TOPLEFT", 8, -8)
    viewport:SetPoint("BOTTOMRIGHT", anchorPage, "BOTTOMRIGHT", -36, 8)
    viewport:EnableMouseWheel(true)
    local page = CreateFrame("Frame", nil, viewport)
    page:SetWidth(1000); page:SetHeight(960)
    viewport:SetScrollChild(page)
    viewport.settingsPage = page
    page.settingsViewport = viewport
    viewport:SetScript("OnMouseWheel", OnSettingsMouseWheel)
    local scrollBar = getglobal("MuklaOfficerSuiteSettingsScrollScrollBar")
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", anchorPage, "TOPRIGHT", -8, -24)
        scrollBar:SetPoint("BOTTOMRIGHT", anchorPage, "BOTTOMRIGHT", -8, 24)
    end
    viewport:Hide()
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    title:SetText("Settings")
    MOS.UI.Settings.CreateSection(page, "UI", -48)
    local generalHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -80)
    generalHeading:SetText("General")
    Settings.CreateSkinControl(page, 92, -80)
    local layoutHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    layoutHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 330, -80)
    layoutHeading:SetText("Layout")
    Settings.CreateMenuStyleControl(page, 330, -110, onNavigationLayout)
    return { viewport = viewport, page = page }
end

function Settings.CreateSkinControl(parent, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); label:SetText("Skin")
    local dropdown = MOS.UI.CreateDropdownButton(parent, nil, "Default", 126)
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    local panel = MOS.UI.CreateDropdownPanel(parent, dropdown, 126, 44, 20)
    panel:SetFrameLevel(parent:GetFrameLevel() + 20)
    local function AddChoice(text, value, offsetY)
        local button = MOS.UI.CreateButton(panel, nil, text, 112, 18)
          button:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, offsetY - 5)
          button:SetScript("OnClick", function()
              MOS.UI.SetSkin(value, true); dropdown:SetText(text); panel:Hide()
          end)
    end
    AddChoice("Default", "default", -2); AddChoice("Classic", "classic", -21)
    dropdown:SetScript("OnClick", function() if panel:IsVisible() then panel:Hide() else panel:Show() end end)
    dropdown:SetScript("OnShow", function() this:SetText(MOS.UI.IsClassicSkin() and "Classic" or "Default") end)
    return dropdown
end

function Settings.CreatePrimarySections(page)
    local rosterHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rosterHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -144)
    rosterHeading:SetText("Roster management")
    Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteClassColors", 10, -168, "Use class colors", "rosterClassColors")
    page.rosterLiveTrackingCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRosterLiveTracking", 190, -168, "Live tracking", "rosterLiveTrackingEnabled", "Roster live tracking", "Keeps the guild roster current while Roster Management is open. This may have a small performance impact in large guilds.")
    local raidHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    raidHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -204)
    raidHeading:SetText("Raid management")
    local debugHeading = MOS.UI.Settings.CreateSection(page, "Debug", -645)
    return { rosterHeading = rosterHeading, raidHeading = raidHeading, debugHeading = debugHeading }
end

function Settings.CreateRaidColumnControl(page, x, y, onChanged)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", page, "TOPLEFT", x, y - 6)
    label:SetText("Columns")
    label:SetTextColor(1, 1, 1)

    local button = MOS.UI.CreateDropdownButton(page, nil, "2", 52)
    button:SetPoint("TOPLEFT", page, "TOPLEFT", x + 52, y)
    local panel = MOS.UI.CreateDropdownPanel(page, button, 52, 86, 20)
    local columnNumber
    for columnNumber = 1, 4 do
        local choice = MOS.UI.CreateButton(panel, nil, tostring(columnNumber), 38, 18)
        choice:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -5 - ((columnNumber - 1) * 20))
        choice.columnCount = columnNumber
        choice:SetScript("OnClick", function()
            MOS.Database.Ensure()
            MOS.Database.SetSetting("raidGroupColumns", this.columnCount)
            button.label:SetText(tostring(this.columnCount))
            panel:Hide()
            if onChanged then onChanged() end
        end)
    end
    button:SetScript("OnClick", function() if panel:IsVisible() then panel:Hide() else panel:Show() end end)
    button:SetScript("OnShow", function()
        MOS.Database.Ensure()
        this.label:SetText(tostring(MuklaOfficerSuiteDB.raidGroupColumns))
    end)
    return label, button, panel
end

function Settings.CreateRaidViewShell(page)
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -306)
    panel:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", -12, -980)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    panel:SetBackdropColor(0.025, 0.025, 0.025, 0.48)
    panel:SetBackdropBorderColor(0.62, 0.62, 0.62, 0.8)

    local groupHeading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -318)
    groupHeading:SetText("Group View")
    groupHeading:SetTextColor(1, 0.82, 0)
    local groupReset = MOS.UI.CreateButton(page, nil, "Reset to default", 112, 20)
    groupReset:SetPoint("LEFT", groupHeading, "RIGHT", 12, 0)
    local groupDivider = panel:CreateTexture(nil, "ARTWORK")
    groupDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -336)
    groupDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -336)
    groupDivider:SetHeight(1)
    groupDivider:SetTexture(0.75, 0.75, 0.75, 0.55)

    local listDivider = panel:CreateTexture(nil, "ARTWORK")
    listDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -740)
    listDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -740)
    listDivider:SetHeight(1)
    listDivider:SetTexture(0.75, 0.75, 0.75, 0.55)
    local listHeading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -722)
    listHeading:SetText("List View")
    listHeading:SetTextColor(1, 0.82, 0)
    local listReset = MOS.UI.CreateButton(page, nil, "Reset to default", 112, 20)
    listReset:SetPoint("LEFT", listHeading, "RIGHT", 12, 0)

    return { panel = panel, groupHeading = groupHeading, groupReset = groupReset, groupDivider = groupDivider, listDivider = listDivider, listHeading = listHeading, listReset = listReset }
end

function Settings.CreateRaidControlFactory(page, callbacks)
    local function Refresh(settingKey)
        if string.find(settingKey, "raidList", 1, true) then
            if callbacks.refreshList then callbacks.refreshList() end
        elseif callbacks.refreshGroup then
            callbacks.refreshGroup()
        end
    end
    return {
        Checkbox = function(x, y, text, key)
            return MOS.UI.Settings.CreateCheckbox(page, x, y, text, key, Refresh)
        end,
        Slider = function(name, x, y, label, key, minimum, maximum)
            return MOS.UI.Settings.CreateSlider(page, name, x, y, label, key, minimum, maximum, Refresh)
        end,
        Color = function(x, y, label, key)
            return MOS.UI.Settings.CreateColor(page, x, y, label, key, Refresh)
        end,
    }
end

local function AlignSliderLabel(name, slider)
    local label = getglobal(name .. "Text")
    label:ClearAllPoints()
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 3)
    label:SetJustifyH("LEFT")
end

function Settings.CreateRaidGroupViewControls(page, shell, factory, onColumnsChanged)
    local columnsLabel, columnsButton, columnsPanel = Settings.CreateRaidColumnControl(page, 40, -350, onColumnsChanged)
    local function Heading(text, y)
        local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        heading:SetPoint("TOPLEFT", page, "TOPLEFT", 40, y)
        heading:SetText(text)
        heading:SetTextColor(1, 0.82, 0)
        return heading
    end
    local displayHeading = Heading("Display", -380)
    local showClass = factory.Checkbox(40, -398, "Show class", "raidGroupShowClass")
    local showLevel = factory.Checkbox(300, -398, "Show lvl", "raidGroupShowLevel")
    local showHeader = factory.Checkbox(40, -422, "Show group header", "raidGroupShowHeader")
    local showLootMaster = factory.Checkbox(300, -422, "Show LM icon", "raidGroupShowLootMaster")
    local showRole = factory.Checkbox(40, -446, "Show role icon", "raidGroupShowRoleIcon")
    local sizeHeading = Heading("Size", -480)
    local autoWidth = factory.Checkbox(40, -498, "Adjust tile width to window", "raidGroupAutoTileWidth")
    local width = factory.Slider("MuklaOfficerSuiteGroupTileWidth", 40, -548, "Member tile width (default: 280)", "raidGroupTileWidth", 160, 340)
    local height = factory.Slider("MuklaOfficerSuiteGroupTileHeight", 300, -548, "Member tile height (default: 20)", "raidGroupTileHeight", 14, 28)
    local headerHeight = factory.Slider("MuklaOfficerSuiteGroupHeaderHeight", 40, -600, "Group header height (default: 22)", "raidGroupHeaderHeight", 14, 40)
    local margin = factory.Slider("MuklaOfficerSuiteGroupMargin", 300, -600, "Margin between groups (default: 8)", "raidGroupMargin", 0, 32)
    AlignSliderLabel("MuklaOfficerSuiteGroupTileWidth", width)
    AlignSliderLabel("MuklaOfficerSuiteGroupTileHeight", height)
    AlignSliderLabel("MuklaOfficerSuiteGroupHeaderHeight", headerHeight)
    AlignSliderLabel("MuklaOfficerSuiteGroupMargin", margin)
    local originalAutoWidthSave = autoWidth.SaveSetting
    autoWidth.SaveSetting = function(owner)
        originalAutoWidthSave(owner)
        if owner:GetChecked() then width:Disable() else width:Enable() end
    end
    local colorHeading = Heading("Member tile color", -644)
    local classColors = factory.Checkbox(40, -662, "Use class colors", "raidGroupClassColors")
    local background = factory.Color(40, -690, "Background color", "raidGroupBackgroundColor")
    local text = factory.Color(230, -690, "Main text color", "raidGroupTextColor")
    local hover = factory.Color(40, -716, "Hover color", "raidGroupHoverColor")
    local pressed = factory.Color(230, -716, "On press color", "raidGroupPressedColor")
    return {
        columnsLabel = columnsLabel, columnsButton = columnsButton, columnsPanel = columnsPanel,
        checks = { showClass, showLevel, showHeader, showLootMaster, showRole, autoWidth, classColors },
        width = width, height = height, headerHeight = headerHeight, margin = margin, autoWidth = autoWidth, colors = { background, text, hover, pressed },
        layoutControls = { shell.panel, shell.groupHeading, shell.groupReset, shell.groupDivider, columnsLabel, columnsButton, displayHeading, showClass, showLevel, showHeader, showLootMaster, showRole, sizeHeading, autoWidth, width, height, headerHeight, margin, colorHeading, classColors, background, text, hover, pressed },
    }
end

function Settings.CreateRaidListViewControls(page, shell, factory)
    local showName = factory.Checkbox(40, -762, "Show name", "raidListShowName")
    local showLevel = factory.Checkbox(300, -762, "Show lvl", "raidListShowLevel")
    local showStatus = factory.Checkbox(560, -762, "Show status", "raidListShowStatus")
    local showGroup = factory.Checkbox(40, -786, "Show group", "raidListShowGroup")
    local showClass = factory.Checkbox(300, -786, "Show class", "raidListShowClass")
    local showRank = factory.Checkbox(560, -786, "Show guild rank", "raidListShowGuildRank")
    local showSoftReserve = factory.Checkbox(40, -810, "Show SR", "raidListShowSR")
    local showLootMaster = factory.Checkbox(300, -810, "Show LM icon", "raidListShowLootMaster")
    local showRole = factory.Checkbox(560, -810, "Show role icon", "raidListShowRoleIcon")
    local showFilters = factory.Checkbox(40, -834, "Show filters", "raidListShowFilters")
    local showSearch = factory.Checkbox(300, -834, "Show search", "raidListShowSearch")
    local width = factory.Slider("MuklaOfficerSuiteListRowWidth", 40, -886, "Member row width (default: 1000)", "raidListRowWidth", 400, 1200)
    local height = factory.Slider("MuklaOfficerSuiteListRowHeight", 300, -886, "Member row height (default: 20)", "raidListRowHeight", 16, 30)
    AlignSliderLabel("MuklaOfficerSuiteListRowWidth", width)
    AlignSliderLabel("MuklaOfficerSuiteListRowHeight", height)
    local background = factory.Color(40, -922, "Background color", "raidListBackgroundColor")
    local text = factory.Color(230, -922, "Main text color", "raidListTextColor")
    local hover = factory.Color(40, -948, "Hover color", "raidListHoverColor")
    local pressed = factory.Color(230, -948, "On press color", "raidListPressedColor")
    return {
        checks = { showName, showLevel, showStatus, showGroup, showClass, showRank, showSoftReserve, showLootMaster, showRole, showFilters, showSearch },
        width = width, height = height, colors = { background, text, hover, pressed },
        layoutControls = { shell.listDivider, shell.listHeading, shell.listReset, showName, showLevel, showStatus, showGroup, showClass, showRank, showSoftReserve, showLootMaster, showRole, showFilters, showSearch, width, height, background, text, hover, pressed },
    }
end

function Settings.MergeControls(target, source)
    local index
    for index = 1, table.getn(source) do table.insert(target, source[index]) end
    return target
end

function Settings.CreateRaidSettings(page, callbacks)
    local primarySections = Settings.CreatePrimarySections(page)
    local general = MOS.UI.Settings.CreateAccordion(page, "General", -230)
    local liveTracking = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRaidLiveTracking", 40, -252, "Live tracking", "raidLiveTrackingEnabled", "Raid live tracking", "Keeps raid membership and loot current while Raid Management is open. This may have a small performance impact during raids.", callbacks.trackingChanged)
    local layout = MOS.UI.Settings.CreateAccordion(page, "Layout", -280)
    local shell = Settings.CreateRaidViewShell(page)
    local factory = Settings.CreateRaidControlFactory(page, callbacks)
    local groupControls = Settings.CreateRaidGroupViewControls(page, shell, factory, callbacks.refreshGroup)
    local listControls = Settings.CreateRaidListViewControls(page, shell, factory)
    local leader = MOS.UI.Settings.CreateAccordion(page, "Raid Leader Mode", -980)
    local loot = MOS.UI.Settings.CreateAccordion(page, "Loot Master Mode", -1008)
    local layoutControls = Settings.MergeControls(groupControls.layoutControls, listControls.layoutControls)
    local viewControls = {
        columnsButton = groupControls.columnsButton,
        checks = Settings.MergeControls(groupControls.checks, listControls.checks),
        groupWidth = groupControls.width,
        groupHeight = groupControls.height,
        groupHeaderHeight = groupControls.headerHeight,
        groupMargin = groupControls.margin,
        groupAutoWidth = groupControls.autoWidth,
        listWidth = listControls.width,
        listHeight = listControls.height,
        colors = Settings.MergeControls(groupControls.colors, listControls.colors),
    }
    Settings.BindRaidViewControls(page, viewControls, shell.groupReset, shell.listReset, callbacks)
    Settings.BindRaidAccordions(page, { page = page, layout = layout, general = general, generalControls = { liveTracking }, leader = leader, loot = loot, debugHeading = primarySections.debugHeading, layoutControls = layoutControls, columnsPanel = groupControls.columnsPanel })
    page.chatLogsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteChatLogs", 10, -675, "Chat action logs", "chatActionLogs", "Chat action logs", "Show routine Mukla Officer Suite action messages in chat. Disabled by default.")
    page.raidAccordionControls.chatLogsCheck = page.chatLogsCheck
    page.ApplyRaidLayoutAccordion()
end

function Settings.CreateMenuStyleControl(parent, x, y, onChanged)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText("Menu type")

    local dropdown = MOS.UI.CreateDropdownButton(parent, nil, "Button view", 126)
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    local panel = MOS.UI.CreateDropdownPanel(parent, dropdown, 126, 44, 20)
    panel:SetFrameLevel(parent:GetFrameLevel() + 20)

    local function AddChoice(text, value, offsetY)
        local button = MOS.UI.CreateButton(panel, nil, text, 112, 18)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, offsetY - 5)
        button:SetScript("OnClick", function()
            MOS.Database.Ensure()
            MOS.Database.SetSetting("menuStyle", value)
            dropdown:SetText(text)
            panel:Hide()
            if onChanged then onChanged(value) end
        end)
    end

    AddChoice("Tab view", "tabs", -2)
    AddChoice("Button view", "buttons", -21)
    dropdown:SetScript("OnClick", function() if panel:IsVisible() then panel:Hide() else panel:Show() end end)
    dropdown:SetScript("OnShow", function()
        MOS.Database.Ensure()
        this:SetText(MuklaOfficerSuiteDB.menuStyle == "tabs" and "Tab view" or "Button view")
    end)
    return dropdown
end

function Settings.CreateSavedCheckbox(parent, name, x, y, text, settingKey, tooltipTitle, tooltipText, onChanged)
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetWidth(24)
    check:SetHeight(24)
    check.settingKey = settingKey
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.label:SetText(text)
    check:SetScript("OnShow", function()
        MOS.Database.Ensure()
        this:SetChecked(MuklaOfficerSuiteDB[this.settingKey] and 1 or nil)
    end)
    check.SaveSetting = function(owner)
        MOS.Database.Ensure()
        MOS.Database.SetSetting(owner.settingKey, owner:GetChecked() and true or false)
        if onChanged then onChanged(owner.settingKey) end
    end
    check:SetScript("OnClick", function() this:SaveSetting() end)
    check.labelHit = CreateFrame("Button", nil, check)
    check.labelHit:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.labelHit:SetWidth(math.max(18, check.label:GetStringWidth() + 8))
    check.labelHit:SetHeight(24)
    check.labelHit.owner = check
    check.labelHit:SetScript("OnClick", function()
        local owner = this.owner
        owner:SetChecked(not owner:GetChecked())
        owner:SaveSetting()
    end)
    if tooltipTitle then
        MOS.UI.AttachTooltip(check, tooltipTitle, tooltipText)
        MOS.UI.AttachTooltip(check.labelHit, tooltipTitle, tooltipText)
    end
    return check
end

function Settings.CreatePercentageField(parent, name, labelText, x, y, settingKey, fallback)
    local label = parent:CreateFontString(name .. "Label", "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    local field = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    field:SetWidth(34)
    field:SetHeight(18)
    field:SetPoint("LEFT", label, "RIGHT", 8, 0)
    field:SetAutoFocus(false)
    field:SetMaxLetters(3)
    field.settingKey = settingKey
    field.fallback = fallback
    field:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    field:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    field:SetScript("OnEditFocusLost", function()
        MOS.Database.Ensure()
        local value = math.max(0, math.min(100, tonumber(this:GetText()) or this.fallback))
        MOS.Database.SetSetting(this.settingKey, value)
        this:SetText(value)
    end)
    return label, field
end

function Settings.SyncSavedControls(chatLogsCheck, opacityField, focusField)
    MOS.Database.Ensure()
    if chatLogsCheck then chatLogsCheck:SetChecked(MuklaOfficerSuiteDB.chatActionLogs and 1 or nil) end
    if opacityField then opacityField:SetText(MuklaOfficerSuiteDB.lootMasterOpacity) end
    if focusField then focusField:SetText(MuklaOfficerSuiteDB.outOfFocusOpacity) end
end

function Settings.UpdateScroll(viewport, page, pageHeight)
    if not viewport or not page then return end
    page:SetWidth(math.max(640, viewport:GetWidth() - 4))
    page:SetHeight(pageHeight or 960)
    local scrollBar = getglobal(viewport:GetName() .. "ScrollBar")
    local maximum = math.max(0, page:GetHeight() - viewport:GetHeight())
    if scrollBar then
        scrollBar:SetMinMaxValues(0, maximum)
        scrollBar:SetValue(math.max(0, math.min(maximum, viewport:GetVerticalScroll())))
        if maximum > 0 then scrollBar:Show() else scrollBar:Hide() end
    end
end

function Settings.RefreshRaidViewControls(controls)
    if not controls then return end
    MOS.Database.Ensure()
    controls.columnsButton.label:SetText(tostring(MuklaOfficerSuiteDB.raidGroupColumns))

    local checkIndex
    for checkIndex = 1, table.getn(controls.checks) do
        local check = controls.checks[checkIndex]
        check:SetChecked(MuklaOfficerSuiteDB[check.settingKey] and 1 or nil)
    end

    controls.groupWidth:SetValue(MuklaOfficerSuiteDB.raidGroupTileWidth)
    controls.groupHeight:SetValue(MuklaOfficerSuiteDB.raidGroupTileHeight)
    controls.groupHeaderHeight:SetValue(MuklaOfficerSuiteDB.raidGroupHeaderHeight)
    controls.groupMargin:SetValue(MuklaOfficerSuiteDB.raidGroupMargin)
    if MuklaOfficerSuiteDB.raidGroupAutoTileWidth then controls.groupWidth:Disable() else controls.groupWidth:Enable() end
    controls.listWidth:SetValue(MuklaOfficerSuiteDB.raidListRowWidth)
    controls.listHeight:SetValue(MuklaOfficerSuiteDB.raidListRowHeight)

    local colorIndex
    for colorIndex = 1, table.getn(controls.colors) do
        local colorControl = controls.colors[colorIndex]
        local color = MuklaOfficerSuiteDB[colorControl.settingKey]
        colorControl.swatch:SetTexture(color[1], color[2], color[3], 1)
    end
end

function Settings.ResetRaidGroupView(controls, refreshView)
    MOS.Database.ResetRaidGroupView()
    Settings.RefreshRaidViewControls(controls)
    if refreshView then refreshView() end
end

function Settings.ResetRaidListView(controls, refreshView)
    MOS.Database.ResetRaidListView()
    Settings.RefreshRaidViewControls(controls)
    if refreshView then refreshView() end
end

function Settings.BindRaidViewControls(page, controls, groupReset, listReset, callbacks)
    page.RefreshRaidViewSettings = function()
        Settings.RefreshRaidViewControls(controls)
    end
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_RESET_GROUP_VIEW"] = {
        text = "Reset all Group View settings to their default values?",
        button1 = "Accept", button2 = "Cancel",
        OnAccept = function() Settings.ResetRaidGroupView(controls, callbacks.refreshGroup) end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_RESET_LIST_VIEW"] = {
        text = "Reset all List View settings to their default values?",
        button1 = "Accept", button2 = "Cancel",
        OnAccept = function() Settings.ResetRaidListView(controls, callbacks.refreshList) end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    groupReset:SetScript("OnClick", function() MOS.UI.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_GROUP_VIEW") end)
    listReset:SetScript("OnClick", function() MOS.UI.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_LIST_VIEW") end)
end

function Settings.ApplyRaidAccordions(controls)
    if not controls then return end
    MOS.Database.Ensure()
    local expanded = MuklaOfficerSuiteDB.raidLayoutExpanded
    controls.layout.label:SetText((expanded and "-  " or "+  ") .. "Layout")
    controls.general.label:SetText((MuklaOfficerSuiteDB.raidGeneralExpanded and "-  " or "+  ") .. controls.general.baseText)
    controls.leader.label:SetText((MuklaOfficerSuiteDB.raidLeaderExpanded and "-  " or "+  ") .. controls.leader.baseText)
    controls.loot.label:SetText((MuklaOfficerSuiteDB.raidLootExpanded and "-  " or "+  ") .. controls.loot.baseText)
    controls.layout:SetBackdropColor(0, 0, 0, 0)
    controls.layout:SetBackdropBorderColor(0, 0, 0, 0)
    controls.general:SetBackdropColor(0, 0, 0, 0)
    controls.general:SetBackdropBorderColor(0, 0, 0, 0)
    controls.leader:SetBackdropColor(0, 0, 0, 0)
    controls.leader:SetBackdropBorderColor(0, 0, 0, 0)
    controls.loot:SetBackdropColor(0, 0, 0, 0)
    controls.loot:SetBackdropBorderColor(0, 0, 0, 0)
    controls.layout.label:SetTextColor(1, 0.82, 0)
    controls.general.label:SetTextColor(1, 0.82, 0)
    controls.leader.label:SetTextColor(1, 0.82, 0)
    controls.loot.label:SetTextColor(1, 0.82, 0)
    if expanded then controls.layout:LockHighlight() else controls.layout:UnlockHighlight() end
    if MuklaOfficerSuiteDB.raidGeneralExpanded then controls.general:LockHighlight() else controls.general:UnlockHighlight() end
    if MuklaOfficerSuiteDB.raidLeaderExpanded then controls.leader:LockHighlight() else controls.leader:UnlockHighlight() end
    if MuklaOfficerSuiteDB.raidLootExpanded then controls.loot:LockHighlight() else controls.loot:UnlockHighlight() end

    local controlIndex
    for controlIndex = 1, table.getn(controls.layoutControls) do
        if expanded then controls.layoutControls[controlIndex]:Show() else controls.layoutControls[controlIndex]:Hide() end
    end
    for controlIndex = 1, table.getn(controls.generalControls or {}) do
        if MuklaOfficerSuiteDB.raidGeneralExpanded then controls.generalControls[controlIndex]:Show() else controls.generalControls[controlIndex]:Hide() end
    end
    controls.columnsPanel:Hide()

    local leaderY, lootY, opacityY, debugY, chatY
    if expanded then
        leaderY, lootY = -988, -1012
        if MuklaOfficerSuiteDB.raidLootExpanded then
            opacityY, debugY, chatY = -1038, -1070, -1100
        else
            opacityY, debugY, chatY = -1038, -1050, -1080
        end
    else
        leaderY, lootY = -272, -296
        if MuklaOfficerSuiteDB.raidLootExpanded then
            opacityY, debugY, chatY = -322, -354, -384
        else
            opacityY, debugY, chatY = -322, -334, -364
        end
    end
    controls.leader:ClearAllPoints()
    controls.leader:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, leaderY)
    controls.loot:ClearAllPoints()
    controls.loot:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, lootY)
    controls.debugHeading:ClearAllPoints()
    controls.debugHeading:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 12, debugY)

    if controls.opacityLabel then
        controls.opacityLabel:ClearAllPoints()
        controls.opacityLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 40, opacityY)
        controls.opacityField:ClearAllPoints()
        controls.opacityField:SetPoint("LEFT", controls.opacityLabel, "RIGHT", 8, 0)
        controls.focusLabel:ClearAllPoints()
        controls.focusLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 210, opacityY)
        controls.focusField:ClearAllPoints()
        controls.focusField:SetPoint("LEFT", controls.focusLabel, "RIGHT", 8, 0)
        if MuklaOfficerSuiteDB.raidLootExpanded then
            controls.opacityLabel:Show(); controls.opacityField:Show(); controls.focusLabel:Show(); controls.focusField:Show()
        else
            controls.opacityLabel:Hide(); controls.opacityField:Hide(); controls.focusLabel:Hide(); controls.focusField:Hide()
        end
    end
    if controls.chatLogsCheck then
        controls.chatLogsCheck:ClearAllPoints()
        controls.chatLogsCheck:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 10, chatY)
    end
    controls.page.settingsContentHeight = expanded and 1140 or 410
    Settings.UpdateScroll(controls.page.settingsViewport, controls.page, controls.page.settingsContentHeight)
    controls.layout.rule:Hide()
end

function Settings.ToggleRaidAccordion(controls, settingKey)
    MOS.Database.Ensure()
    MOS.Database.SetSetting(settingKey, not MOS.Database.GetSetting(settingKey))
    Settings.ApplyRaidAccordions(controls)
end

function Settings.BindRaidAccordions(page, controls)
    page.raidAccordionControls = controls
    page.ApplyRaidLayoutAccordion = function()
        Settings.ApplyRaidAccordions(page.raidAccordionControls)
    end
    controls.layout:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "raidLayoutExpanded") end)
    controls.layout:SetScript("OnShow", function() page.ApplyRaidLayoutAccordion() end)
    controls.general:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "raidGeneralExpanded") end)
    controls.leader:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "raidLeaderExpanded") end)
    controls.loot:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "raidLootExpanded") end)
end

function Settings.CreateLifecycle(options)
    local function UpdateScroll()
        Settings.UpdateScroll(options.viewport, options.page, options.page.settingsContentHeight or options.bottomPadding)
    end
    return {
        Hide = function(self) options.viewport:Hide() end,
        Show = function(self)
            Settings.SyncSavedControls(options.chatLogsCheck, options.opacityField, options.focusField)
            UpdateScroll()
            options.page:Show()
            options.viewport:Show()
        end,
        OnResize = function(self) UpdateScroll() end,
    }
end
