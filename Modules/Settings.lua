local MOS = MuklaOfficerSuite

MOS.Modules.Settings = MOS.Modules.Settings or {}
local Settings = MOS.Modules.Settings
local controls = MOS.UI.Components.Settings.CreateFactory({
    ensure = MOS.Database.Ensure,
    get = MOS.Database.GetSetting,
    set = MOS.Database.SetSetting,
})

local rosterLayoutOptions = {
    { "Hide section header", "rosterHideSectionHeader" },
    { "Show class", "rosterShowClass" },
    { "Show lvl", "rosterShowLevel" },
    { "Show zone", "rosterShowZone" },
    { "Show rank", "rosterShowRank" },
    { "Show public note", "rosterShowPublicNote" },
    { "Show officer note", "rosterShowOfficerNote" },
    { "Show last online", "rosterShowLastOnline" },
    { "Show class filter", "rosterShowClassFilter" },
    { "Show rank filter", "rosterShowRankFilter" },
    { "Show search", "rosterShowSearch" },
    { "Show offline", "rosterShowOffline" },
    { "Show column headers", "rosterShowColumnHeaders" },
}
local function RefreshRosterLayout()
    if MOS.Modules.RosterManagement and MOS.Modules.RosterManagement.RefreshLayout then MOS.Modules.RosterManagement.RefreshLayout() end
end

local function OnSettingsMouseWheel()
    local page = this.settingsPage
    local maximum = math.max(0, page:GetHeight() - this:GetHeight())
    local value = math.max(0, math.min(maximum, this:GetVerticalScroll() - (arg1 * 46)))
    local scrollBar = getglobal("MuklaOfficerSuiteSettingsScrollScrollBar")
    if scrollBar then scrollBar:SetValue(value) else this:SetVerticalScroll(value) end
end

function Settings.LayoutGeneral(page)
    if not page.generalGrid then return 0 end
    local state = page.uiSectionState
    page.uiGeneralHeading.label:SetText((state.general and "-  " or "+  ") .. "General")
    page.uiLayoutHeading.label:SetText((state.layout and "-  " or "+  ") .. "Layout")
    local index
    for index = 1, table.getn(page.generalGrid) do
        if state.general then page.generalGrid[index]:Show() else page.generalGrid[index]:Hide() end
    end
    if state.general then page.skinControl:Show(); page.skinControl.fieldLabel:Show()
    else page.skinControl:Hide(); page.skinControl.fieldLabel:Hide(); page.skinControl.panel:Hide() end
    local height = MOS.UI.Components.Settings.LayoutGrid(page.uiContent, page.generalGrid, 20, -94, page:GetWidth() - 56, 28)
    local headingY = state.general and (-94 - height - 8) or -66
    page.uiLayoutHeading:ClearAllPoints(); page.uiLayoutHeading:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", 12, headingY)
    local menu = page.menuStyleControl
    menu.fieldLabel:ClearAllPoints(); menu.fieldLabel:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", 24, headingY - 28)
    local menuWidth = menu.fieldLabel:GetStringWidth() + 10 + menu:GetWidth()
    local check = page.iconTabsCheck
    local iconVisible = state.layout and (MuklaOfficerSuiteDB.menuStyle == "tabs" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs")
    if iconVisible then check:Show() else check:Hide() end
    if state.layout then menu:Show(); menu.fieldLabel:Show()
    else menu:Hide(); menu.fieldLabel:Hide(); menu.panel:Hide() end
    local checkWidth = check:GetWidth() + 4 + check.label:GetStringWidth()
    local wrap = (menuWidth + 14 + checkWidth > page:GetWidth() - 60) and check:IsVisible()
    check:ClearAllPoints(); check:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", wrap and 20 or 24 + menuWidth + 14, headingY - 28 - (wrap and 28 or 0))
    local extent = -headingY + (state.layout and (56 + (wrap and 28 or 0)) or 28)
    page.uiContent:SetHeight(extent)
    return extent - 224
end

function Settings.LayoutRaidGrid(page, offset)
    local data, C = page.responsiveRaid, MOS.UI.Components.Settings
    local group, list, shell = data.group, data.list, data.shell
    local width = math.max(1, page:GetWidth() - 64)
    local function At(control, x, y)
        control:ClearAllPoints(); control:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
    end
    local y = -318 + offset
    At(shell.groupHeading, 48, y); y = y - 38
    At(group.displayHeading, 52, y); y = y - 26
    At(group.columnsLabel, 52, y - 6); At(group.columnsButton, 104, y); y = y - 28
    y = y - C.LayoutGrid(page, group.displayChecks, 52, y, width, 26) - 8
    At(group.sizeHeading, 52, y); y = y - 24
    y = y - C.LayoutGrid(page, group.autoChecks, 52, y, width, 26) - 22
    y = y - C.LayoutGrid(page, group.sliders, 52, y, width, 56, true)
    At(group.colorHeading, 52, y); y = y - 24
    y = y - C.LayoutGrid(page, group.colorChecks, 52, y, width, 26)
    y = y - C.LayoutGrid(page, group.colors, 52, y, width, 28) - 16
    At(shell.listHeading, 48, y); At(shell.listDivider, 48, y - 20); shell.listDivider:SetWidth(math.max(1, page:GetWidth() - 84)); y = y - 44
    y = y - C.LayoutGrid(page, list.checks, 52, y, width, 26) - 24
    y = y - C.LayoutGrid(page, list.sliders, 52, y, width, 56, true)
    y = y - C.LayoutGrid(page, list.colors, 52, y, width, 28) - 16
    shell.panel:ClearAllPoints(); shell.panel:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -306 + offset); shell.panel:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", page:GetWidth() - 12, y + 8)
    return y - (-1126 + offset)
end

function Settings.CreateShell(parent, anchorPage, onNavigationLayout, options)
    options = options or {}
    local viewport = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteSettingsScroll", parent, "UIPanelScrollFrameTemplate")
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteSettingsScrollScrollBar"))
    viewport:SetPoint("TOPLEFT", anchorPage, "TOPLEFT", 8, -8)
    viewport:SetPoint("BOTTOMRIGHT", anchorPage, "BOTTOMRIGHT", -36, 8)
    viewport:EnableMouseWheel(true)
    local page = MOS.UI.Components.CreateContainer(nil, viewport)
    page.mosTextSizeDelta = -2
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
    page.uiHeading = MOS.UI.Components.Settings.CreateSectionAccordion(page, "UI", -10)
    local uiContent = MOS.UI.Components.CreateContainer(nil, page)
    uiContent:SetHeight(224); page.uiContent = uiContent
    local generalHeading = MOS.UI.Components.Settings.CreateAccordion(uiContent, "General", -38)
    generalHeading:SetPoint("TOPLEFT", uiContent, "TOPLEFT", 12, -38)
    page.uiGeneralHeading = generalHeading; page.uiSectionState = { general = true, layout = true }
    generalHeading:SetScript("OnClick", function() page.uiSectionState.general = not page.uiSectionState.general; Settings.ApplyTopSections(page) end)
    local skinControl = Settings.CreateSkinControl(uiContent, 24, -66)
    local loginMessageCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteDisableLoginMessage", 224, -94, "Turn off addon login message", "suppressLoginMessage")
    local minimapCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideMinimapIcon", 20, -94, "Hide minimap icon", "hideMinimapIcon", nil, nil, options.minimapVisibilityChanged)
    page.chromeChecks = {
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideStatusBar", 20, -122, "Hide status and version bar", "hideStatusVersionBar", nil, nil, onNavigationLayout),
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideHeaderLogo", 20, -150, "Hide header logo", "hideHeaderLogo", nil, nil, onNavigationLayout),
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideHeaderName", 224, -150, "Hide header name", "hideHeaderName", nil, nil, onNavigationLayout),
    }
    local layoutHeading = MOS.UI.Components.Settings.CreateAccordion(uiContent, "Layout", -178)
    layoutHeading:SetPoint("TOPLEFT", uiContent, "TOPLEFT", 12, -178)
    layoutHeading:SetScript("OnClick", function() page.uiSectionState.layout = not page.uiSectionState.layout; Settings.ApplyTopSections(page) end)
    local menuStyleControl = Settings.CreateMenuStyleControl(uiContent, 24, -206, function()
        page.RefreshGeneralSettings()
        if onNavigationLayout then onNavigationLayout() end
    end)
    local iconTabsCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteUseIconTabs", 330, -204, "Use Icon Tabs", "useIconTabs", nil, nil, onNavigationLayout)
    page.generalGrid = { minimapCheck, loginMessageCheck, page.chromeChecks[1], page.chromeChecks[2], page.chromeChecks[3] }
    page.uiLayoutHeading = layoutHeading
    page.iconTabsCheck = iconTabsCheck
    page.skinControl = skinControl
    page.menuStyleControl = menuStyleControl
    page.RefreshGeneralSettings = function()
        MOS.Database.Ensure()
        skinControl:SetText(MOS.UI.Components.IsClassicSkin() and "Classic" or "Default")
        menuStyleControl:SetText(MuklaOfficerSuiteDB.menuStyle == "tabs" and "Tab view" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs" and "Bottom Tab view" or "Button view")
        iconTabsCheck:SetChecked(MuklaOfficerSuiteDB.useIconTabs and 1 or nil)
        if MuklaOfficerSuiteDB.menuStyle == "tabs" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs" then iconTabsCheck:Show() else iconTabsCheck:Hide() end
        local index
        for index = 1, table.getn(page.chromeChecks) do local check = page.chromeChecks[index]; check:SetChecked(MOS.Database.GetSetting(check.settingKey) and 1 or nil) end
        loginMessageCheck:SetChecked(MuklaOfficerSuiteDB.suppressLoginMessage and 1 or nil)
        minimapCheck:SetChecked(MuklaOfficerSuiteDB.hideMinimapIcon and 1 or nil)
        if page.topSectionState then Settings.ApplyTopSections(page) end
    end
    Settings.BindTopSections(page, function()
        MOS.UI.Components.SetSkin(MOS.Database.GetSetting("uiSkin"), false)
        if options.minimapVisibilityChanged then options.minimapVisibilityChanged() end
        if onNavigationLayout then onNavigationLayout() end
        if page.RefreshAllSettings then page.RefreshAllSettings() else page.RefreshGeneralSettings() end
        if options.profileLoaded then options.profileLoaded() end
    end)
    page.ReflowSettings = function() Settings.ApplyTopSections(page) end
    page:SetScript("OnShow", function() page:RegisterEvent("GUILD_ROSTER_UPDATE") end)
    page:SetScript("OnHide", function() page:UnregisterEvent("GUILD_ROSTER_UPDATE") end)
    page:SetScript("OnEvent", function()
        if page:IsVisible() and page.primarySections and page.canShowOfficerOption ~= Settings.CanShowOfficerOption() then Settings.ApplyTopSections(page) end
    end)
    page.RefreshGeneralSettings()
    return { viewport = viewport, page = page, scrollBar = scrollBar }
end

function Settings.CreateSkinControl(parent, x, y)
    local _, button = MOS.UI.Components.CreateChoiceField({
        parent = parent, x = x, y = y, label = "Skin", width = 126, height = 51,
        initialText = "Default", firstY = -7, step = 19,
        choices = { { text = "Default", value = "default" }, { text = "Classic", value = "classic" } },
        getValue = function() return MOS.UI.Components.IsClassicSkin() and "classic" or "default" end,
        onSelect = function(value) MOS.UI.Components.SetSkin(value, true) end,
    })
    return button
end

function Settings.CreatePrimarySections(page)
    local rosterHeading = MOS.UI.Components.CreateHeading(page, "", 3, "gold")
    rosterHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -150)
    rosterHeading:SetText("Roster")
    local rosterGeneral = MOS.UI.Components.Settings.CreateAccordion(page, "General", -178)
    page.rosterLiveTrackingCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRosterLiveTracking", 52, -206, "Live tracking", "rosterLiveTrackingEnabled", "Roster live tracking", "Keeps the guild roster current while Roster is open. This may have a small performance impact in large guilds.")
    page.rosterLayoutChecks = {}
    local index
    for index = 1, table.getn(rosterLayoutOptions) do
        local option = rosterLayoutOptions[index]
        page.rosterLayoutChecks[index] = Settings.CreateSavedCheckbox(page, nil, 52, -234, option[1], option[2], nil, nil, RefreshRosterLayout)
    end
    local rosterLayout = MOS.UI.Components.Settings.CreateAccordion(page, "Layout", -206)
    page.rosterClassColorsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteClassColors", 52, -234, "Use class colors", "rosterClassColors")
    local raidHeading = MOS.UI.Components.CreateHeading(page, "", 3, "gold")
    raidHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -206)
    raidHeading:SetText("Raid management")
    local debugHeading = MOS.UI.Components.Settings.CreateSectionAccordion(page, "Debug", -645)
    debugHeading:SetScript("OnClick", function()
        page.topSectionState.debug = not page.topSectionState.debug
        Settings.ApplyRaidAccordions(page.raidAccordionControls)
    end)
    return { rosterHeading = rosterHeading, rosterGeneral = rosterGeneral, rosterLayout = rosterLayout, raidHeading = raidHeading, debugHeading = debugHeading }
end

function Settings.CreateRaidColumnControl(page, x, y, onChanged, labelOwner)
    return MOS.UI.Components.CreateChoiceField({
        parent = page, labelOwner = labelOwner, x = x + 12, y = y, label = "Columns",
        font = "GameFontHighlightSmall", color = { 1, 1, 1 }, labelOffset = -6, buttonOffset = 52,
        width = 52, height = 86, initialText = "2", firstY = -5, step = 20, labelValue = true,
        choices = { { text = "1", value = 1 }, { text = "2", value = 2 }, { text = "3", value = 3 }, { text = "4", value = 4 } },
        getValue = function() MOS.Database.Ensure(); return MOS.Database.GetSetting("raidGroupColumns") end,
        onSelect = function(value) MOS.Database.Ensure(); MOS.Database.SetSetting("raidGroupColumns", value) end,
        onChanged = onChanged,
    })
end

function Settings.CreateRaidViewShell(page)
    local panel = MOS.UI.Components.CreateContainer(nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -306)
    panel:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", -12, -1110)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    panel:SetBackdropColor(0.025, 0.025, 0.025, 0.48)
    panel:SetBackdropBorderColor(0, 0, 0, 0)

    local groupHeading = MOS.UI.Components.CreateHeading(panel, "", 3, "orange")
    groupHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -318)
    groupHeading:SetText("Group View")
    groupHeading:SetTextColor(1, 0.82, 0)
    local groupReset = MOS.UI.Components.CreateButton(page, nil, "Reset to default", 112, 20)
    MOS.UI.Components.SizeClassicButton(groupReset, 100, 18, 0.8)
    groupReset:SetPoint("LEFT", groupHeading, "RIGHT", 12, 0)
    local groupDivider = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    groupDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -336)
    groupDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -336)
    groupDivider:SetHeight(1)
    groupDivider:SetTexture(0.75, 0.75, 0.75, 0.55)

    local listDivider = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    listDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -866)
    listDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -866)
    listDivider:SetHeight(1)
    listDivider:SetTexture(0.75, 0.75, 0.75, 0.55)
    local listHeading = MOS.UI.Components.CreateHeading(panel, "", 3, "orange")
    listHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -846)
    listHeading:SetText("List View")
    listHeading:SetTextColor(1, 0.82, 0)
    local listReset = MOS.UI.Components.CreateButton(page, nil, "Reset to default", 112, 20)
    MOS.UI.Components.SizeClassicButton(listReset, 100, 18, 0.8)
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
            return controls.CreateCheckbox(page, x + 12, y, text, key, Refresh)
        end,
        Slider = function(name, x, y, label, key, minimum, maximum)
            return controls.CreateSlider(page, name, x + 12, y, label, key, minimum, maximum, Refresh)
        end,
        Color = function(x, y, label, key)
            return controls.CreateColor(page, x + 12, y, label, key, Refresh)
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
        local heading = MOS.UI.Components.CreateHeading(shell.panel, "", 3, "orange")
        heading:SetPoint("TOPLEFT", page, "TOPLEFT", 52, y)
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
        MOS.UI.Components.Settings.SetSliderEnabled(width, not owner:GetChecked())
    end
    local colorHeading = Heading("Member tile colors", -724)
    local classColors = factory.Checkbox(40, -746, "Use class colors", "raidGroupClassColors")
    local background = factory.Color(40, -774, "Background color", "raidGroupBackgroundColor")
    local text = factory.Color(230, -774, "Main text color", "raidGroupTextColor")
    local hover = factory.Color(40, -802, "Hover color", "raidGroupHoverColor")
    local pressed = factory.Color(230, -802, "On press color", "raidGroupPressedColor")
    return {
        displayHeading = displayHeading, sizeHeading = sizeHeading, colorHeading = colorHeading,
        displayChecks = { showClass, showLevel, showHeader, showLootMaster, showRole },
        autoChecks = {autoWidth}, colorChecks = {classColors}, sliders = {width, height, headerHeight, margin, tileTextSize, headerTextSize},
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
        sliders = {width, height},
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
    page.primarySections = primarySections
    local general = MOS.UI.Components.Settings.CreateAccordion(page, "General", -230)
    local liveTracking = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRaidLiveTracking", 52, -252, "Live tracking", "raidLiveTrackingEnabled", "Raid live tracking", "Keeps raid membership and loot current while Raid Management is open. This may have a small performance impact during raids.", callbacks.trackingChanged)
    page.raidLiveTrackingCheck = liveTracking
    local layout = MOS.UI.Components.Settings.CreateAccordion(page, "Layout", -280)
    local shell = Settings.CreateRaidViewShell(page)
    local factory = Settings.CreateRaidControlFactory(page, callbacks)
    local groupControls = Settings.CreateRaidGroupViewControls(page, shell, factory, callbacks.refreshGroup)
    page.raidHideHeaderCheck = Settings.CreateSavedCheckbox(page, nil, 52, -318, "Hide section header", "raidHideSectionHeader", nil, nil, callbacks.refreshList)
    table.insert(groupControls.checks, page.raidHideHeaderCheck)
    local listControls = Settings.CreateRaidListViewControls(page, shell, factory)
    local leader = MOS.UI.Components.Settings.CreateAccordion(page, "Raid Leader Mode", -1126)
    local loot = MOS.UI.Components.Settings.CreateAccordion(page, "Loot Master Mode", -1154)
    page.responsiveRaid = { shell = shell, group = groupControls, list = listControls }
    local layoutControls = Settings.MergeControls(groupControls.layoutControls, listControls.layoutControls)
    local viewControls = {
        columnsButton = groupControls.columnsButton,
        checks = Settings.MergeControls(Settings.MergeControls({}, groupControls.checks), listControls.checks),
        groupWidth = groupControls.width,
        groupHeight = groupControls.height,
        groupHeaderHeight = groupControls.headerHeight,
        groupMargin = groupControls.margin,
        groupTileTextSize = groupControls.tileTextSize,
        groupHeaderTextSize = groupControls.headerTextSize,
        groupAutoWidth = groupControls.autoWidth,
        listWidth = listControls.width,
        listHeight = listControls.height,
        colors = Settings.MergeControls(Settings.MergeControls({}, groupControls.colors), listControls.colors),
    }
    Settings.BindRaidViewControls(page, viewControls, shell.groupReset, shell.listReset, callbacks)
    Settings.BindRaidAccordions(page, { page = page, layout = layout, general = general, generalControls = { liveTracking, page.raidHideHeaderCheck }, leader = leader, loot = loot, debugHeading = primarySections.debugHeading, layoutControls = layoutControls, columnsPanel = groupControls.columnsPanel })
    Settings.BindRosterAccordions(page, primarySections, page.raidAccordionControls)
    page.chatLogsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteChatLogs", 22, -675, "Chat action logs", "chatActionLogs", "Chat action logs", "Show routine Mukla Officer Suite action messages in chat. Disabled by default.")
    page.raidAccordionControls.chatLogsCheck = page.chatLogsCheck
    page.RefreshAllSettings = function()
        MOS.Database.Ensure()
        if page.profiles then page.profiles.RefreshState() end
        if page.RefreshGeneralSettings then page.RefreshGeneralSettings() end
        page.rosterClassColorsCheck:SetChecked(MuklaOfficerSuiteDB.rosterClassColors and 1 or nil)
        page.rosterLiveTrackingCheck:SetChecked(MuklaOfficerSuiteDB.rosterLiveTrackingEnabled and 1 or nil)
        page.raidLiveTrackingCheck:SetChecked(MuklaOfficerSuiteDB.raidLiveTrackingEnabled and 1 or nil)
        local index
        for index = 1, table.getn(page.rosterLayoutChecks or {}) do
            local check = page.rosterLayoutChecks[index]; check:SetChecked(MuklaOfficerSuiteDB[check.settingKey] and 1 or nil)
        end
        if page.RefreshRaidViewSettings then page.RefreshRaidViewSettings() end
        Settings.SyncSavedControls(page.chatLogsCheck, page.raidAccordionControls.opacityField, page.raidAccordionControls.focusField)
        page.ApplyRaidLayoutAccordion()
    end
    page.ApplyRaidLayoutAccordion()
end

function Settings.CreateMenuStyleControl(parent, x, y, onChanged)
    local _, button = MOS.UI.Components.CreateChoiceField({
        parent = parent, x = x, y = y, label = "Menu type", width = 126, height = 72,
        initialText = "Button view", firstY = -7, step = 19,
        choices = { { text = "Tab view", value = "tabs" }, { text = "Button view", value = "buttons" }, { text = "Bottom Tab view", value = "bottomTabs" } },
        getValue = function() MOS.Database.Ensure(); return MOS.Database.GetSetting("menuStyle") end,
        onSelect = function(value) MOS.Database.Ensure(); MOS.Database.SetSetting("menuStyle", value) end,
        onChanged = onChanged,
    })
    return button
end





function Settings.SyncSavedControls(chatLogsCheck, opacityField, focusField)
    MOS.Database.Ensure()
    if chatLogsCheck then chatLogsCheck:SetChecked(MuklaOfficerSuiteDB.chatActionLogs and 1 or nil) end
    if opacityField then opacityField:SetText(MuklaOfficerSuiteDB.lootMasterOpacity) end
    if focusField then focusField:SetText(MuklaOfficerSuiteDB.outOfFocusOpacity) end
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
    MOS.UI.Components.Settings.SetSliderEnabled(controls.groupWidth, not MuklaOfficerSuiteDB.raidGroupAutoTileWidth)
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
    groupReset:SetScript("OnClick", function() MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_GROUP_VIEW") end)
    listReset:SetScript("OnClick", function() MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_LIST_VIEW") end)
end

function Settings.ApplyRaidAccordions(controls)
    if not controls then return end
    local state = controls.state
    local uiVisible = not controls.page.topSectionState or controls.page.topSectionState.ui
    local expanded = state.layout and uiVisible
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
    if expanded then controls.layout:UnlockHighlight() else controls.layout:UnlockHighlight() end
    if state.general then controls.general:UnlockHighlight() else controls.general:UnlockHighlight() end
    if state.leader then controls.leader:UnlockHighlight() else controls.leader:UnlockHighlight() end
    if state.loot then controls.loot:UnlockHighlight() else controls.loot:UnlockHighlight() end

    local controlIndex
    for controlIndex = 1, table.getn(controls.layoutControls) do
        if expanded then controls.layoutControls[controlIndex]:Show() else controls.layoutControls[controlIndex]:Hide() end
    end
    for controlIndex = 1, table.getn(controls.generalControls or {}) do
        if state.general and uiVisible then controls.generalControls[controlIndex]:Show() else controls.generalControls[controlIndex]:Hide() end
    end
    controls.columnsPanel:Hide()

    local offset = controls.raidOffset or 0
    controls.general:ClearAllPoints(); controls.general:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 36, -230 + offset)
    if controls.generalControls and controls.generalControls[1] then
        controls.generalControls[1]:ClearAllPoints(); controls.generalControls[1]:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 52, -252 + offset)
    end
    local generalHeight = 26
    if controls.generalControls and table.getn(controls.generalControls) > 1 then
        generalHeight = MOS.UI.Components.Settings.LayoutGrid(controls.page, controls.generalControls, 52, -252 + offset, controls.page:GetWidth() - 64, 26)
    end
    local generalExtra = state.general and math.max(0, generalHeight - 26) or 0
    local layoutY = (state.general and -280 or -258) + offset - generalExtra
    controls.layout:ClearAllPoints()
    controls.layout:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 36, layoutY)

    local layoutOffset = offset + (state.general and 0 or 22) - generalExtra
    Settings.OffsetRaidLayoutControls(controls, layoutOffset)
    if expanded and controls.page.responsiveRaid then layoutOffset = layoutOffset + Settings.LayoutRaidGrid(controls.page, layoutOffset) end
    local leaderY, lootY, opacityY, debugY, chatY
    if expanded then
        leaderY, lootY = -1126 + layoutOffset, -1154 + layoutOffset
        if state.loot then
            opacityY, debugY, chatY = -1182 + layoutOffset, -1214 + layoutOffset, -1244 + layoutOffset
        else
            opacityY, debugY, chatY = -1182 + layoutOffset, -1194 + layoutOffset, -1224 + layoutOffset
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
    controls.leader:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 36, leaderY)
    controls.loot:ClearAllPoints()
    controls.loot:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 36, lootY)
    if controls.page.topSectionState and not controls.page.topSectionState.ui then
        debugY = (controls.page.uiHeadingY or -38) - 28
        chatY = debugY - 30
    end
    controls.debugHeading:ClearAllPoints()
    controls.debugHeading:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 12, debugY)
    controls.debugHeading:SetPoint("TOPRIGHT", controls.page, "TOPRIGHT", -12, debugY)

    if controls.opacityLabel then
        controls.opacityLabel:ClearAllPoints()
        controls.opacityLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 52, opacityY)
        controls.opacityField:ClearAllPoints()
        controls.opacityField:SetPoint("LEFT", controls.opacityLabel, "RIGHT", 8, 0)
        controls.focusLabel:ClearAllPoints()
        controls.focusLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 222, opacityY)
        controls.focusField:ClearAllPoints()
        controls.focusField:SetPoint("LEFT", controls.focusLabel, "RIGHT", 8, 0)
        if state.loot and uiVisible then
            controls.opacityLabel:Show(); controls.opacityField:Show(); controls.focusLabel:Show(); controls.focusField:Show()
        else
            controls.opacityLabel:Hide(); controls.opacityField:Hide(); controls.focusLabel:Hide(); controls.focusField:Hide()
        end
    end
    if controls.chatLogsCheck then
        controls.chatLogsCheck:ClearAllPoints()
        controls.chatLogsCheck:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 22, chatY)
        if controls.page.topSectionState then
            local debugExpanded = controls.page.topSectionState.debug
            controls.debugHeading.label:SetText((debugExpanded and "-  " or "+  ") .. "Debug")
            if controls.debugHeading.SetExpanded then controls.debugHeading:SetExpanded(debugExpanded) end
            if debugExpanded then controls.chatLogsCheck:Show() else controls.chatLogsCheck:Hide() end
        end
    end
    controls.page.settingsContentHeight = (expanded and 1280 or 460) - offset
    if controls.page.topSectionState then
        controls.page.settingsContentHeight = -debugY + (controls.page.topSectionState.debug and 66 or 32)
        Settings.ApplyUIVisibility(controls)
    end
    Settings.UpdateScroll(controls.page.settingsViewport, controls.page, controls.page.settingsContentHeight)
    controls.layout.rule:Hide()
end

function Settings.ApplyUIVisibility(controls)
    local page, visible = controls.page, controls.page.topSectionState.ui
    local function Root(control)
        if not control then return end
        if visible then control:Show() else control:Hide() end
    end
    local sections = page.primarySections
    if sections then
        Root(sections.rosterHeading); Root(sections.rosterGeneral); Root(sections.rosterLayout); Root(sections.raidHeading)
    end
    Root(controls.general); Root(controls.layout); Root(controls.leader); Root(controls.loot)
    if not visible then
        page.rosterLiveTrackingCheck:Hide(); page.rosterClassColorsCheck:Hide()
        local index
        for index = 1, table.getn(page.rosterLayoutChecks or {}) do page.rosterLayoutChecks[index]:Hide() end
        for index = 1, table.getn(controls.layoutControls) do controls.layoutControls[index]:Hide() end
        for index = 1, table.getn(controls.generalControls or {}) do controls.generalControls[index]:Hide() end
        if controls.columnsPanel then controls.columnsPanel:Hide() end
        if controls.opacityLabel then controls.opacityLabel:Hide(); controls.opacityField:Hide(); controls.focusLabel:Hide(); controls.focusField:Hide() end
    end
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

function Settings.CanShowOfficerOption()
    return MOS.Services and MOS.Services.Roster and MOS.Services.Roster.CanManage("viewOfficerNote") and true or false
end

function Settings.ApplyRosterAccordions(page, sections, raidControls)
    local state = page.rosterAccordionState
    local uiVisible = not page.topSectionState or page.topSectionState.ui
    local topOffset = page.settingsTopOffset or 0
    sections.rosterHeading:ClearAllPoints(); sections.rosterHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -150 + topOffset)
    sections.rosterGeneral:ClearAllPoints(); sections.rosterGeneral:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -178 + topOffset)
    page.rosterLiveTrackingCheck:ClearAllPoints(); page.rosterLiveTrackingCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 52, -206 + topOffset)
    sections.rosterGeneral.label:SetText((state.general and "-  " or "+  ") .. sections.rosterGeneral.baseText)
    sections.rosterLayout.label:SetText((state.layout and "-  " or "+  ") .. sections.rosterLayout.baseText)
    if state.general and uiVisible then sections.rosterGeneral:UnlockHighlight(); page.rosterLiveTrackingCheck:Show()
    else sections.rosterGeneral:UnlockHighlight(); page.rosterLiveTrackingCheck:Hide() end
    local layoutY = (state.general and -234 or -206) + topOffset
    sections.rosterLayout:ClearAllPoints(); sections.rosterLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 36, layoutY)
    if state.layout and uiVisible then sections.rosterLayout:UnlockHighlight(); page.rosterClassColorsCheck:Show()
    else sections.rosterLayout:UnlockHighlight(); page.rosterClassColorsCheck:Hide() end
    page.rosterClassColorsCheck:ClearAllPoints(); page.rosterClassColorsCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 52, layoutY - 28)
    local index
    page.canShowOfficerOption = Settings.CanShowOfficerOption()
    for index = 1, table.getn(page.rosterLayoutChecks or {}) do
        local check = page.rosterLayoutChecks[index]
        check:ClearAllPoints(); check:SetPoint("TOPLEFT", page, "TOPLEFT", 52 + math.mod(index - 1, 2) * 260, layoutY - 56 - math.floor((index - 1) / 2) * 26)
        if state.layout and uiVisible and (check.settingKey ~= "rosterShowOfficerNote" or page.canShowOfficerOption) then check:Show() else check:Hide() end
    end
    local gridHeight = 0
    if page.rosterLayoutChecks then
        page.rosterGrid = page.rosterGrid or {}
        for index = table.getn(page.rosterGrid), 1, -1 do page.rosterGrid[index] = nil end
        table.insert(page.rosterGrid, page.rosterClassColorsCheck)
        for index = 1, table.getn(page.rosterLayoutChecks) do
            local check = page.rosterLayoutChecks[index]
            if check.settingKey ~= "rosterShowOfficerNote" or page.canShowOfficerOption then table.insert(page.rosterGrid, check) end
        end
        gridHeight = MOS.UI.Components.Settings.LayoutGrid(page, page.rosterGrid, 52, layoutY - 28, page:GetWidth() - 64, 26)
    end
    local raidHeadingY = layoutY - (state.layout and (40 + gridHeight) or 38)
    sections.raidHeading:ClearAllPoints(); sections.raidHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 24, raidHeadingY)
    raidControls.raidOffset = raidHeadingY - (-206)
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
    if view.viewport:GetParent() ~= parent then view.viewport:SetParent(parent) end
    view.viewport:SetFrameStrata(parent:GetFrameStrata()); view.viewport:SetFrameLevel(parent:GetFrameLevel() + 2)
    view.page:SetFrameStrata(parent:GetFrameStrata()); view.page:SetFrameLevel(view.viewport:GetFrameLevel() + 2)
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
    return MOS.UI.Components.Window.Create({
        name = "MuklaOfficerSuiteSettingsWindow", title = "Settings", compact = true,
        update = function(view) Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960) end,
        refresh = function(view) if view.page.RefreshAllSettings then view.page.RefreshAllSettings() end end,
        attach = function(view, content) Settings.AttachShell(view, content, content, true) end,
    })
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

Settings.CreateSavedCheckbox = controls.CreateSavedCheckbox

Settings.CreatePercentageField = controls.CreatePercentageField

Settings.UpdateScroll = MOS.UI.Components.Settings.UpdateScroll
