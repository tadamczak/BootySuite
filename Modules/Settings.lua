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

function Settings.CreateShell(parent, anchorPage, onNavigationLayout, options)
    options = options or {}
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
    MOS.UI.Settings.CreateSection(page, "UI", -10)
    local generalHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -38)
    generalHeading:SetText("General")
    local skinControl = Settings.CreateSkinControl(page, 40, -66)
    local loginMessageCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteDisableLoginMessage", 240, -66, "Turn off addon login message", "suppressLoginMessage")
    local minimapCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteHideMinimapIcon", 500, -66, "Hide minimap icon", "hideMinimapIcon", nil, nil, options.minimapVisibilityChanged)
    local layoutHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    layoutHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -94)
    layoutHeading:SetText("Layout")
    local menuStyleControl = Settings.CreateMenuStyleControl(page, 40, -122, onNavigationLayout)
    page.skinControl = skinControl
    page.menuStyleControl = menuStyleControl
    page.RefreshGeneralSettings = function()
        MOS.Database.Ensure()
        skinControl:SetText(MOS.UI.IsClassicSkin() and "Classic" or "Default")
        menuStyleControl:SetText(MuklaOfficerSuiteDB.menuStyle == "tabs" and "Tab view" or "Button view")
        loginMessageCheck:SetChecked(MuklaOfficerSuiteDB.suppressLoginMessage and 1 or nil)
        minimapCheck:SetChecked(MuklaOfficerSuiteDB.hideMinimapIcon and 1 or nil)
    end
    return { viewport = viewport, page = page, scrollBar = scrollBar }
end

function Settings.CreateSkinControl(parent, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); label:SetText("Skin")
    local dropdown = MOS.UI.CreateDropdownButton(parent, nil, "Default", 126)
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    local panel = MOS.UI.CreateDropdownPanel(parent, dropdown, 126, 51, 20)
    dropdown.panel = panel
    local function AddChoice(text, value, offsetY)
        local button = MOS.UI.CreateButton(panel, nil, text, 112, 18)
        MOS.UI.StyleDropdownChoice(button)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, offsetY - 5)
        button:SetScript("OnClick", function()
            MOS.UI.SetSkin(value, true); dropdown:SetText(text); panel:Hide()
        end)
        table.insert(panel.options, button)
    end
    AddChoice("Default", "default", -2); AddChoice("Classic", "classic", -21)
    dropdown:SetScript("OnClick", function() if panel:IsVisible() then panel:Hide() else panel:Show() end end)
    dropdown:SetScript("OnShow", function() this:SetText(MOS.UI.IsClassicSkin() and "Classic" or "Default") end)
    return dropdown
end

function Settings.CreatePrimarySections(page)
    local rosterHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rosterHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -150)
    rosterHeading:SetText("Roster management")
    local rosterGeneral = MOS.UI.Settings.CreateAccordion(page, "General", -178)
    page.rosterLiveTrackingCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRosterLiveTracking", 40, -206, "Live tracking", "rosterLiveTrackingEnabled", "Roster live tracking", "Keeps the guild roster current while Roster Management is open. This may have a small performance impact in large guilds.")
    local rosterLayout = MOS.UI.Settings.CreateAccordion(page, "Layout", -206)
    page.rosterClassColorsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteClassColors", 40, -234, "Use class colors", "rosterClassColors")
    local raidHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    raidHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -206)
    raidHeading:SetText("Raid management")
    local debugHeading = MOS.UI.Settings.CreateSection(page, "Debug", -645)
    return { rosterHeading = rosterHeading, rosterGeneral = rosterGeneral, rosterLayout = rosterLayout, raidHeading = raidHeading, debugHeading = debugHeading }
end

function Settings.CreateRaidColumnControl(page, x, y, onChanged, labelOwner)
    local label = (labelOwner or page):CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", page, "TOPLEFT", x, y - 6)
    label:SetText("Columns")
    label:SetTextColor(1, 1, 1)
    label:SetAlpha(1)

    local button = MOS.UI.CreateDropdownButton(page, nil, "2", 52)
    button:SetPoint("TOPLEFT", page, "TOPLEFT", x + 52, y)
    local panel = MOS.UI.CreateDropdownPanel(page, button, 52, 86, 20)
    local columnNumber
    for columnNumber = 1, 4 do
        local choice = MOS.UI.CreateButton(panel, nil, tostring(columnNumber), 38, 18)
        MOS.UI.StyleDropdownChoice(choice)
        choice:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -5 - ((columnNumber - 1) * 20))
        choice.columnCount = columnNumber
        choice:SetScript("OnClick", function()
            MOS.Database.Ensure()
            MOS.Database.SetSetting("raidGroupColumns", this.columnCount)
            button.label:SetText(tostring(this.columnCount))
            panel:Hide()
            if onChanged then onChanged() end
        end)
        table.insert(panel.options, choice)
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
    panel:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", -12, -1110)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    panel:SetBackdropColor(0.025, 0.025, 0.025, 0.48)
    panel:SetBackdropBorderColor(0, 0, 0, 0)

    local groupHeading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -318)
    groupHeading:SetText("Group View")
    groupHeading:SetTextColor(1, 0.82, 0)
    local groupReset = MOS.UI.CreateButton(page, nil, "Reset to default", 112, 20)
    groupReset:SetPoint("LEFT", groupHeading, "RIGHT", 12, 0)
    local groupDivider = page:CreateTexture(nil, "ARTWORK")
    groupDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -336)
    groupDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -336)
    groupDivider:SetHeight(1)
    groupDivider:SetTexture(0.75, 0.75, 0.75, 0.55)

    local listDivider = page:CreateTexture(nil, "ARTWORK")
    listDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -866)
    listDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -866)
    listDivider:SetHeight(1)
    listDivider:SetTexture(0.75, 0.75, 0.75, 0.55)
    local listHeading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -846)
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
    local function Heading(text, y)
        local heading = shell.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        heading:SetPoint("TOPLEFT", page, "TOPLEFT", 40, y)
        heading:SetText(text)
        heading:SetTextColor(1, 0.82, 0)
        heading:SetAlpha(1)
        return heading
    end
    local displayHeading = Heading("Display", -356)
    local columnsLabel, columnsButton, columnsPanel = Settings.CreateRaidColumnControl(page, 40, -382, onColumnsChanged, shell.panel)
    columnsLabel:SetTextColor(1, 1, 1)
    local showClass = factory.Checkbox(40, -410, "Show class", "raidGroupShowClass")
    local showLevel = factory.Checkbox(300, -410, "Show lvl", "raidGroupShowLevel")
    local showHeader = factory.Checkbox(40, -434, "Show group header", "raidGroupShowHeader")
    local showLootMaster = factory.Checkbox(300, -434, "Show LM icon", "raidGroupShowLootMaster")
    local showRole = factory.Checkbox(40, -458, "Show role icon", "raidGroupShowRoleIcon")
    local sizeHeading = Heading("Size", -492)
    local autoWidth = factory.Checkbox(40, -514, "Adjust tile width to window", "raidGroupAutoTileWidth")
    local width = factory.Slider("MuklaOfficerSuiteGroupTileWidth", 40, -566, "Member tile width (default: 280)", "raidGroupTileWidth", 160, 340)
    local height = factory.Slider("MuklaOfficerSuiteGroupTileHeight", 300, -566, "Member tile height (default: 20)", "raidGroupTileHeight", 14, 28)
    local headerHeight = factory.Slider("MuklaOfficerSuiteGroupHeaderHeight", 40, -622, "Group header height (default: 22)", "raidGroupHeaderHeight", 14, 40)
    local margin = factory.Slider("MuklaOfficerSuiteGroupMargin", 300, -622, "Margin between groups (default: 8)", "raidGroupMargin", 0, 32)
    local tileTextSize = factory.Slider("MuklaOfficerSuiteGroupTileTextSize", 40, -678, "Tile text size (default: 10)", "raidGroupTileTextSize", 8, 16)
    local headerTextSize = factory.Slider("MuklaOfficerSuiteGroupHeaderTextSize", 300, -678, "Tile header text size (default: 10)", "raidGroupHeaderTextSize", 8, 16)
    AlignSliderLabel("MuklaOfficerSuiteGroupTileWidth", width)
    AlignSliderLabel("MuklaOfficerSuiteGroupTileHeight", height)
    AlignSliderLabel("MuklaOfficerSuiteGroupHeaderHeight", headerHeight)
    AlignSliderLabel("MuklaOfficerSuiteGroupMargin", margin)
    AlignSliderLabel("MuklaOfficerSuiteGroupTileTextSize", tileTextSize)
    AlignSliderLabel("MuklaOfficerSuiteGroupHeaderTextSize", headerTextSize)
    local originalAutoWidthSave = autoWidth.SaveSetting
    autoWidth.SaveSetting = function(owner)
        originalAutoWidthSave(owner)
        MOS.UI.Settings.SetSliderEnabled(width, not owner:GetChecked())
    end
    local colorHeading = Heading("Member tile colors", -724)
    local classColors = factory.Checkbox(40, -746, "Use class colors", "raidGroupClassColors")
    local background = factory.Color(40, -774, "Background color", "raidGroupBackgroundColor")
    local text = factory.Color(230, -774, "Main text color", "raidGroupTextColor")
    local hover = factory.Color(40, -802, "Hover color", "raidGroupHoverColor")
    local pressed = factory.Color(230, -802, "On press color", "raidGroupPressedColor")
    return {
        columnsLabel = columnsLabel, columnsButton = columnsButton, columnsPanel = columnsPanel,
        checks = { showClass, showLevel, showHeader, showLootMaster, showRole, autoWidth, classColors },
        width = width, height = height, headerHeight = headerHeight, margin = margin, tileTextSize = tileTextSize, headerTextSize = headerTextSize, autoWidth = autoWidth, colors = { background, text, hover, pressed },
        layoutControls = { shell.panel, shell.groupHeading, shell.groupReset, shell.groupDivider, displayHeading, columnsLabel, columnsButton, showClass, showLevel, showHeader, showLootMaster, showRole, sizeHeading, autoWidth, width, height, headerHeight, margin, tileTextSize, headerTextSize, colorHeading, classColors, background, text, hover, pressed },
    }
end

function Settings.CreateRaidListViewControls(page, shell, factory)
    local showName = factory.Checkbox(40, -890, "Show name", "raidListShowName")
    local showLevel = factory.Checkbox(300, -890, "Show lvl", "raidListShowLevel")
    local showStatus = factory.Checkbox(560, -890, "Show status", "raidListShowStatus")
    local showGroup = factory.Checkbox(40, -914, "Show group", "raidListShowGroup")
    local showClass = factory.Checkbox(300, -914, "Show class", "raidListShowClass")
    local showRank = factory.Checkbox(560, -914, "Show guild rank", "raidListShowGuildRank")
    local showSoftReserve = factory.Checkbox(40, -938, "Show SR", "raidListShowSR")
    local showLootMaster = factory.Checkbox(300, -938, "Show LM icon", "raidListShowLootMaster")
    local showRole = factory.Checkbox(560, -938, "Show role icon", "raidListShowRoleIcon")
    local showFilters = factory.Checkbox(40, -962, "Show filters", "raidListShowFilters")
    local showSearch = factory.Checkbox(300, -962, "Show search", "raidListShowSearch")
    local width = factory.Slider("MuklaOfficerSuiteListRowWidth", 40, -1014, "Member row width (default: 1000)", "raidListRowWidth", 400, 1200)
    local height = factory.Slider("MuklaOfficerSuiteListRowHeight", 300, -1014, "Member row height (default: 20)", "raidListRowHeight", 16, 30)
    AlignSliderLabel("MuklaOfficerSuiteListRowWidth", width)
    AlignSliderLabel("MuklaOfficerSuiteListRowHeight", height)
    local background = factory.Color(40, -1050, "Background color", "raidListBackgroundColor")
    local text = factory.Color(230, -1050, "Main text color", "raidListTextColor")
    local hover = factory.Color(40, -1078, "Hover color", "raidListHoverColor")
    local pressed = factory.Color(230, -1078, "On press color", "raidListPressedColor")
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
    page.raidLiveTrackingCheck = liveTracking
    local layout = MOS.UI.Settings.CreateAccordion(page, "Layout", -280)
    local shell = Settings.CreateRaidViewShell(page)
    local factory = Settings.CreateRaidControlFactory(page, callbacks)
    local groupControls = Settings.CreateRaidGroupViewControls(page, shell, factory, callbacks.refreshGroup)
    local listControls = Settings.CreateRaidListViewControls(page, shell, factory)
    local leader = MOS.UI.Settings.CreateAccordion(page, "Raid Leader Mode", -1126)
    local loot = MOS.UI.Settings.CreateAccordion(page, "Loot Master Mode", -1154)
    local layoutControls = Settings.MergeControls(groupControls.layoutControls, listControls.layoutControls)
    local viewControls = {
        columnsButton = groupControls.columnsButton,
        checks = Settings.MergeControls(groupControls.checks, listControls.checks),
        groupWidth = groupControls.width,
        groupHeight = groupControls.height,
        groupHeaderHeight = groupControls.headerHeight,
        groupMargin = groupControls.margin,
        groupTileTextSize = groupControls.tileTextSize,
        groupHeaderTextSize = groupControls.headerTextSize,
        groupAutoWidth = groupControls.autoWidth,
        listWidth = listControls.width,
        listHeight = listControls.height,
        colors = Settings.MergeControls(groupControls.colors, listControls.colors),
    }
    Settings.BindRaidViewControls(page, viewControls, shell.groupReset, shell.listReset, callbacks)
    Settings.BindRaidAccordions(page, { page = page, layout = layout, general = general, generalControls = { liveTracking }, leader = leader, loot = loot, debugHeading = primarySections.debugHeading, layoutControls = layoutControls, columnsPanel = groupControls.columnsPanel })
    Settings.BindRosterAccordions(page, primarySections, page.raidAccordionControls)
    page.chatLogsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteChatLogs", 10, -675, "Chat action logs", "chatActionLogs", "Chat action logs", "Show routine Mukla Officer Suite action messages in chat. Disabled by default.")
    page.raidAccordionControls.chatLogsCheck = page.chatLogsCheck
    page.RefreshAllSettings = function()
        MOS.Database.Ensure()
        if page.RefreshGeneralSettings then page.RefreshGeneralSettings() end
        page.rosterClassColorsCheck:SetChecked(MuklaOfficerSuiteDB.rosterClassColors and 1 or nil)
        page.rosterLiveTrackingCheck:SetChecked(MuklaOfficerSuiteDB.rosterLiveTrackingEnabled and 1 or nil)
        page.raidLiveTrackingCheck:SetChecked(MuklaOfficerSuiteDB.raidLiveTrackingEnabled and 1 or nil)
        if page.RefreshRaidViewSettings then page.RefreshRaidViewSettings() end
        Settings.SyncSavedControls(page.chatLogsCheck, page.raidAccordionControls.opacityField, page.raidAccordionControls.focusField)
        page.ApplyRaidLayoutAccordion()
    end
    page.ApplyRaidLayoutAccordion()
end

function Settings.CreateMenuStyleControl(parent, x, y, onChanged)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText("Menu type")

    local dropdown = MOS.UI.CreateDropdownButton(parent, nil, "Button view", 126)
    dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
    local panel = MOS.UI.CreateDropdownPanel(parent, dropdown, 126, 51, 20)
    dropdown.panel = panel
    local function AddChoice(text, value, offsetY)
        local button = MOS.UI.CreateButton(panel, nil, text, 112, 18)
        MOS.UI.StyleDropdownChoice(button)
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, offsetY - 5)
        button:SetScript("OnClick", function()
            MOS.Database.Ensure()
            MOS.Database.SetSetting("menuStyle", value)
            dropdown:SetText(text)
            panel:Hide()
            if onChanged then onChanged(value) end
        end)
        table.insert(panel.options, button)
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
    if viewport.UpdateScrollChildRect then viewport:UpdateScrollChildRect() end
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
    controls.groupTileTextSize:SetValue(MuklaOfficerSuiteDB.raidGroupTileTextSize)
    controls.groupHeaderTextSize:SetValue(MuklaOfficerSuiteDB.raidGroupHeaderTextSize)
    MOS.UI.Settings.SetSliderEnabled(controls.groupWidth, not MuklaOfficerSuiteDB.raidGroupAutoTileWidth)
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
    local state = controls.state
    local expanded = state.layout
    controls.layout.label:SetText((expanded and "-  " or "+  ") .. "Layout")
    controls.general.label:SetText((state.general and "-  " or "+  ") .. controls.general.baseText)
    controls.leader.label:SetText((state.leader and "-  " or "+  ") .. controls.leader.baseText)
    controls.loot.label:SetText((state.loot and "-  " or "+  ") .. controls.loot.baseText)
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
    if state.general then controls.general:LockHighlight() else controls.general:UnlockHighlight() end
    if state.leader then controls.leader:LockHighlight() else controls.leader:UnlockHighlight() end
    if state.loot then controls.loot:LockHighlight() else controls.loot:UnlockHighlight() end

    local controlIndex
    for controlIndex = 1, table.getn(controls.layoutControls) do
        if expanded then controls.layoutControls[controlIndex]:Show() else controls.layoutControls[controlIndex]:Hide() end
    end
    for controlIndex = 1, table.getn(controls.generalControls or {}) do
        if state.general then controls.generalControls[controlIndex]:Show() else controls.generalControls[controlIndex]:Hide() end
    end
    controls.columnsPanel:Hide()

    local offset = controls.raidOffset or 0
    controls.general:ClearAllPoints(); controls.general:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, -230 + offset)
    if controls.generalControls and controls.generalControls[1] then
        controls.generalControls[1]:ClearAllPoints(); controls.generalControls[1]:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 40, -252 + offset)
    end
    local layoutY = ((state.general or expanded) and -280 or -258) + offset
    controls.layout:ClearAllPoints()
    controls.layout:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, layoutY)

    local leaderY, lootY, opacityY, debugY, chatY
    if expanded then
        leaderY, lootY = -1126 + offset, -1154 + offset
        if state.loot then
            opacityY, debugY, chatY = -1182 + offset, -1214 + offset, -1244 + offset
        else
            opacityY, debugY, chatY = -1182 + offset, -1194 + offset, -1224 + offset
        end
    else
        leaderY, lootY = layoutY - 30, layoutY - 58
        if state.loot then
            opacityY, debugY, chatY = layoutY - 86, layoutY - 122, layoutY - 152
        else
            opacityY, debugY, chatY = layoutY - 86, layoutY - 102, layoutY - 132
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
        if state.loot then
            controls.opacityLabel:Show(); controls.opacityField:Show(); controls.focusLabel:Show(); controls.focusField:Show()
        else
            controls.opacityLabel:Hide(); controls.opacityField:Hide(); controls.focusLabel:Hide(); controls.focusField:Hide()
        end
    end
    if controls.chatLogsCheck then
        controls.chatLogsCheck:ClearAllPoints()
        controls.chatLogsCheck:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 10, chatY)
    end
    controls.page.settingsContentHeight = (expanded and 1280 or 460) - offset
    Settings.UpdateScroll(controls.page.settingsViewport, controls.page, controls.page.settingsContentHeight)
    controls.layout.rule:Hide()
end

function Settings.OffsetRaidLayoutControls(controls, offset)
    local index
    for index = 1, table.getn(controls.layoutControls or {}) do
        local control = controls.layoutControls[index]
        if control and control.GetPoint and control.SetPoint then
            if not control.mosSettingsBasePoints then
                local points, valid = {}, true
                local pointIndex
                for pointIndex = 1, control:GetNumPoints() do
                    local point, relative, relativePoint, x, y = control:GetPoint(pointIndex)
                    if point and relative == controls.page then
                        table.insert(points, { point, relativePoint, x, y })
                    else
                        valid = false
                    end
                end
                if valid and table.getn(points) > 0 then control.mosSettingsBasePoints = points end
            end
            local points = control.mosSettingsBasePoints
            if points then
                control:ClearAllPoints()
                local pointIndex
                for pointIndex = 1, table.getn(points) do
                    local base = points[pointIndex]
                    control:SetPoint(base[1], controls.page, base[2], base[3], base[4] + offset)
                end
            end
        end
    end
end

function Settings.ApplyRosterAccordions(page, sections, raidControls)
    local state = page.rosterAccordionState
    sections.rosterGeneral.label:SetText((state.general and "-  " or "+  ") .. sections.rosterGeneral.baseText)
    sections.rosterLayout.label:SetText((state.layout and "-  " or "+  ") .. sections.rosterLayout.baseText)
    if state.general then sections.rosterGeneral:LockHighlight(); page.rosterLiveTrackingCheck:Show()
    else sections.rosterGeneral:UnlockHighlight(); page.rosterLiveTrackingCheck:Hide() end
    local layoutY = state.general and -234 or -206
    sections.rosterLayout:ClearAllPoints(); sections.rosterLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 24, layoutY)
    if state.layout then sections.rosterLayout:LockHighlight(); page.rosterClassColorsCheck:Show()
    else sections.rosterLayout:UnlockHighlight(); page.rosterClassColorsCheck:Hide() end
    page.rosterClassColorsCheck:ClearAllPoints(); page.rosterClassColorsCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 40, layoutY - 28)
    local raidHeadingY = layoutY - (state.layout and 66 or 38)
    sections.raidHeading:ClearAllPoints(); sections.raidHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, raidHeadingY)
    raidControls.raidOffset = raidHeadingY - (-206)
    Settings.OffsetRaidLayoutControls(raidControls, raidControls.raidOffset)
    Settings.ApplyRaidAccordions(raidControls)
end

function Settings.BindRosterAccordions(page, sections, raidControls)
    page.rosterAccordionState = { general = false, layout = false }
    sections.rosterGeneral:SetScript("OnClick", function()
        page.rosterAccordionState.general = not page.rosterAccordionState.general
        Settings.ApplyRosterAccordions(page, sections, raidControls)
    end)
    sections.rosterLayout:SetScript("OnClick", function()
        page.rosterAccordionState.layout = not page.rosterAccordionState.layout
        Settings.ApplyRosterAccordions(page, sections, raidControls)
    end)
    Settings.ApplyRosterAccordions(page, sections, raidControls)
end

function Settings.ToggleRaidAccordion(controls, stateKey)
    controls.state[stateKey] = not controls.state[stateKey]
    Settings.ApplyRaidAccordions(controls)
end

function Settings.BindRaidAccordions(page, controls)
    controls.state = { general = false, layout = false, leader = false, loot = false }
    page.raidAccordionControls = controls
    page.ApplyRaidLayoutAccordion = function()
        Settings.ApplyRaidAccordions(page.raidAccordionControls)
    end
    controls.layout:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "layout") end)
    controls.layout:SetScript("OnShow", function() page.ApplyRaidLayoutAccordion() end)
    controls.general:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "general") end)
    controls.leader:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "leader") end)
    controls.loot:SetScript("OnClick", function() Settings.ToggleRaidAccordion(page.raidAccordionControls, "loot") end)
end

function Settings.AttachShell(view, parent, anchor, detached)
    view.viewport:SetParent(parent)
    view.viewport:ClearAllPoints()
    view.viewport:SetPoint("TOPLEFT", anchor, "TOPLEFT", 8, -8)
    view.viewport:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -36, 8)
    if view.scrollBar then
        view.scrollBar:ClearAllPoints()
        view.scrollBar:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -8, -24)
        view.scrollBar:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -8, 24)
    end
    view.viewport.settingsDetached = detached and true or false
    Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960)
end

function Settings.CreateDetachedWindow()
    local view
    local window = CreateFrame("Frame", "MuklaOfficerSuiteSettingsWindow", UIParent)
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

    local titleBar = CreateFrame("Frame", nil, window)
    titleBar:SetFrameLevel(window:GetFrameLevel() + 1)
    titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", 10, -10); titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -10); titleBar:SetHeight(30)
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0); title:SetText("Settings")
    local close = MOS.UI.CreateButton(titleBar, nil, "X", 18, 18)
    close:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0); MOS.UI.SetClassicButtonCompact(close, true); MOS.UI.AttachGoldHoverBorder(close, 0.35, 0.35, 0.35, 1)
    close.label:SetTextColor(1, 0.82, 0.18)
    local minimize = MOS.UI.CreateButton(titleBar, nil, "_", 18, 18)
    minimize:SetPoint("RIGHT", close, "LEFT", -4, 0); MOS.UI.SetClassicButtonCompact(minimize, true); MOS.UI.AttachGoldHoverBorder(minimize, 0.35, 0.35, 0.35, 1)
    minimize.label:SetTextColor(1, 0.82, 0.18)
    local content = CreateFrame("Frame", nil, window)
    content:SetFrameLevel(window:GetFrameLevel() + 1)
    content:SetPoint("TOPLEFT", window, "TOPLEFT", 8, -42); content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -8, 8)
    local resize = CreateFrame("Button", nil, window)
    resize:SetFrameStrata("FULLSCREEN_DIALOG"); resize:SetFrameLevel(window:GetFrameLevel() + 250); resize:EnableMouse(true)
    resize:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -7, 7); resize:SetWidth(18); resize:SetHeight(18)
    local resizeTexture = resize:CreateTexture(nil, "OVERLAY"); resizeTexture:SetAllPoints(resize); resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() window:StopMovingOrSizing(); Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960) end)

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
    window:SetScript("OnSizeChanged", function() if view then Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960) end end)

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
        if view.page.RefreshAllSettings then view.page.RefreshAllSettings() end
        Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960)
    end
    window.Toggle = function() if window:IsVisible() then CloseWindow() else window.Open() end end
    window.AttachView = function(settingsView)
        view = settingsView
        Settings.AttachShell(view, content, content, true)
        view.viewport:Hide()
    end
    window.content = content
    window.resizeGrip = resize
    window.ApplyResizeBounds = ApplyResizeBounds
    window:Hide()
    return window
end

function Settings.CreateLifecycle(options)
    local function UpdateScroll()
        Settings.UpdateScroll(options.viewport, options.page, options.page.settingsContentHeight or options.bottomPadding)
    end
    return {
        Hide = function(self) if not options.viewport.settingsDetached then options.viewport:Hide() end end,
        Show = function(self)
            Settings.SyncSavedControls(options.chatLogsCheck, options.opacityField, options.focusField)
            UpdateScroll()
            options.page:Show()
            options.viewport:Show()
        end,
        OnResize = function(self) UpdateScroll() end,
    }
end
