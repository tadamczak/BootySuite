local MOS = MuklaOfficerSuite

MOS.Modules.Settings = MOS.Modules.Settings or {}
local Settings = MOS.Modules.Settings
local controls = MOS.UI.Components.Settings.CreateFactory({
    ensure = MOS.Database.Ensure,
    get = MOS.Database.GetSetting,
    set = MOS.Database.SetSetting,
})

local rosterLayoutOptions = {
    { "Show section header", "rosterHideSectionHeader" },
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
local function RosterTrackingChanged()
    if MOS.Modules.RosterManagement and MOS.Modules.RosterManagement.TrackingChanged then MOS.Modules.RosterManagement.TrackingChanged() end
end

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

local function AlignReset(heading)
    if not heading.resetButton then return end
    local _, owner, _, _, y = heading:GetPoint(1)
    heading.resetButton:ClearAllPoints()
    heading.resetButton:SetPoint("TOPRIGHT", owner, "TOPRIGHT", -12, y)
end

local function FeatureOpen(page, key)
    return (not page.topSectionState or page.topSectionState.ui) and (not page.uiFeatureState or page.uiFeatureState[key])
end

local function PlaceSection(heading, page, y, inset)
    heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", page, "TOPLEFT", inset or 0, y)
    if heading.SetExpanded then heading:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, y) end
end

-- Empty feature groups reserve a body inset when opened. Expansion state stays
-- in this page instance rather than profile SavedVariables.
function Settings.LayoutFollowingSections(page, y)
    local uiVisible = not page.topSectionState or page.topSectionState.ui
    for _, section in ipairs(page.uiEmptySections or {}) do
        PlaceSection(section.heading, page, y, 12)
        section.heading.label:SetText((section.expanded and "-  " or "+  ") .. section.heading.baseText)
        section.heading:SetExpanded(section.expanded)
        if uiVisible then section.heading:Show() else section.heading:Hide() end
        local childrenVisible = uiVisible and section.expanded
        if childrenVisible then
            y = y - 28
            PlaceSection(section.general, page, y, 24)
            section.general.label:SetText((section.generalOpen and "-  " or "+  ") .. "General")
            section.general:Show(); y = y - 28 - (section.generalOpen and 12 or 0)
            PlaceSection(section.layout, page, y, 24)
            section.layout.label:SetText((section.layoutOpen and "-  " or "+  ") .. "Layout")
            section.layout:Show(); y = y - (section.layoutOpen and 12 or 0)
        else section.general:Hide(); section.layout:Hide() end
        if uiVisible then y = y - 28 end
    end
    if Settings.LayoutGameUI then y = Settings.LayoutGameUI(page, y) end
    local keys, state = page.keybindings, page.topSectionState
    if keys and state then
        PlaceSection(keys.heading, page, y)
        keys.heading.label:SetText((state.keybindings and "-  " or "+  ") .. "Keybindings")
        keys.heading:SetExpanded(state.keybindings); keys.heading:Show(); y = y - 28
        if state.keybindings then
            PlaceSection(keys.general, page, y, 24)
            keys.general.label:SetText((state.keybindingsGeneral and "-  " or "+  ") .. "General")
            keys.general:Show(); y = y - 28
            if state.keybindingsGeneral then y = y - 12 end
        else keys.general:Hide() end
    end
    return y
end

function Settings.LayoutGeneral(page)
    if not page.generalGrid then return 0 end
    local state = page.uiSectionState
    local generalOpen, layoutOpen = state.general, state.layout
    page.uiGeneralHeading:Show(); page.uiLayoutHeading:Show()
    page.uiGeneralHeading.label:SetText((state.general and "-  " or "+  ") .. "General")
    page.uiLayoutHeading.label:SetText((state.layout and "-  " or "+  ") .. "Layout")
    local index
    for index = 1, table.getn(page.generalGrid) do
        if generalOpen then page.generalGrid[index]:Show() else page.generalGrid[index]:Hide() end
    end
    if generalOpen then page.skinControl:Show(); page.skinControl.fieldLabel:Show()
    else page.skinControl:Hide(); page.skinControl.fieldLabel:Hide(); page.skinControl.panel:Hide() end
    page.skinControl.fieldLabel:ClearAllPoints(); page.skinControl.fieldLabel:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", 20, -66)
    local height = MOS.UI.Components.Settings.LayoutGrid(page.uiContent, page.generalGrid, 20, -94, page:GetWidth() - 56, 28)
    local headingY = generalOpen and (-94 - height - 8) or -66
    page.uiLayoutHeading:ClearAllPoints(); page.uiLayoutHeading:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", 12, headingY)
    local menu = page.menuStyleControl
    local method = layoutOpen and "Show" or "Hide"
    if page.uiLayoutDisplayHeading.resetButton then page.uiLayoutDisplayHeading.resetButton[method](page.uiLayoutDisplayHeading.resetButton) end
    page.uiLayoutGeneralHeading[method](page.uiLayoutGeneralHeading); page.uiLayoutDisplayHeading[method](page.uiLayoutDisplayHeading)
    page.uiLayoutGeneralHeading:ClearAllPoints(); page.uiLayoutGeneralHeading:SetPoint("TOPLEFT",page.uiContent,"TOPLEFT",24,headingY-28)
    menu.fieldLabel:ClearAllPoints(); menu.fieldLabel:SetPoint("TOPLEFT", page.uiContent, "TOPLEFT", 28, headingY - 54)
    local check = page.iconTabsCheck
    local iconVisible = layoutOpen and (MuklaOfficerSuiteDB.menuStyle == "tabs" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs")
    check:ClearAllPoints(); check:SetPoint("LEFT",menu,"RIGHT",12,0)
    if iconVisible then check:Show() else check:Hide() end
    if layoutOpen then menu:Show(); menu.fieldLabel:Show()
    else menu:Hide(); menu.fieldLabel:Hide(); menu.panel:Hide() end
    local displayY = headingY - 90
    page.uiLayoutDisplayHeading:ClearAllPoints();page.uiLayoutDisplayHeading:SetPoint("TOPLEFT",page.uiContent,"TOPLEFT",24,displayY)
    for index = 1, table.getn(page.chromeChecks) do page.chromeChecks[index][method](page.chromeChecks[index]) end
    MOS.UI.Components.Settings.LayoutGrid(page.uiContent, page.chromeChecks, 20, displayY - 26, page:GetWidth() - 56, 28)
    local extent = -headingY + page.uiLayoutHeading:GetHeight() + 12
    if layoutOpen then
        local bottom = 0
        for index = 1, table.getn(page.chromeChecks) do
            local control = page.chromeChecks[index]
            local _, _, _, _, y = control:GetPoint(1)
            bottom = math.max(bottom, -y + math.max(control:GetHeight(), MOS.UI.Components.MeasureTextHeight(control.label) + 3))
        end
        extent = bottom + 12
    end
    page.uiContent:SetHeight(extent)
    AlignReset(page.uiLayoutDisplayHeading)
    return extent - 224
end

function Settings.LayoutGroupControls(page, group, heading, y, width)
    local C = MOS.UI.Components.Settings
    local function At(control, x, y)
        control:ClearAllPoints(); control:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
        AlignReset(control)
    end
    At(heading, 36, y); y = y - 38
    At(group.displayHeading, 40, y); y = y - 26
    group.displayChecks.mosMaxColumns = 3
    y = y - C.LayoutGrid(page, group.displayChecks, 40, y, width, 26) - 8
    At(group.sizeHeading, 40, y); y = y - 24
    if group.columnsButton then
        At(group.columnsButton.fieldLabel, 40, y); y = y - 28
    end
    y = y - C.LayoutGrid(page, group.autoChecks, 40, y, width, 26) - 22
    y = y - C.LayoutGrid(page, group.sliders, 40, y, width, 56, true)
    At(group.colorHeading, 40, y); y = y - 24
    y = y - C.LayoutGrid(page, group.colorChecks, 40, y, width, 26)
    y = y - C.LayoutGrid(page, group.colors, 40, y, width, 28) - 16
    At(group.lightnessLabel,40,y); y=y-34
    if not group.lightnessField.mosEditing then group.lightnessField:SetText(MOS.Database.GetSetting(group.lightnessField.settingKey) or 5) end
    At(group.tileColorHeading, 40, y); y = y - 26
    y = y - C.LayoutGrid(page, group.tileColors, 40, y, width, 28) - 24
    return y
end

function Settings.LayoutRaidGrid(page, offset)
    local data, C = page.responsiveRaid, MOS.UI.Components.Settings
    local group, list, shell = data.group, data.list, data.shell
    local width = math.max(1, page:GetWidth() - 52)
    local y = Settings.LayoutGroupControls(page, group, shell.groupHeading, -318 + offset, width)
    local function At(control, x, y)
        control:ClearAllPoints(); control:SetPoint("TOPLEFT", page, "TOPLEFT", x, y); AlignReset(control)
    end
    At(shell.listHeading, 36, y); At(shell.listDivider, 36, y - 20); shell.listDivider:SetWidth(math.max(1, page:GetWidth() - 48)); y = y - 44
    At(list.displayHeading,40,y);y=y-26
    y = y - C.LayoutGrid(page, list.checks, 40, y, width, 26) - 24
    At(list.sizeHeading,40,y);y=y-38
    y = y - C.LayoutGrid(page, list.sliders, 40, y, width, 56, true)
    At(list.colorHeading,40,y);y=y-26
    y = y - C.LayoutGrid(page, list.colors, 40, y, width, 28) - 16
    At(list.lightnessLabel,40,y);y=y-34
    if not list.lightnessField.mosEditing then list.lightnessField:SetText(MOS.Database.GetSetting("raidListOddLightness") or 5) end
    shell.panel:ClearAllPoints(); shell.panel:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -306 + offset); shell.panel:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", page:GetWidth() - 12, y + 8)
    return y - (-1126 + offset)
end

function Settings.CreateGameUI(page, options)
    local C = MOS.UI.Components.Settings
    local game = {
        heading = C.CreateSectionAccordion(page, "Game UI", -38, nil, nil, "monitor"),
        interface = C.CreateAccordion(page, "Interface", -66, "link"),
        layout = C.CreateAccordion(page, "Layout", -94, "resize"),
        raid = C.CreateSectionAccordion(page, "Raid", -122, 24, 3, "raids"),
        state = { interface = false, layout = false, raid = false },
        onLayoutChanged = options.nativeRaidLayoutChanged,
    }
    page.gameUI = game
    page.interfaceCheck = Settings.CreateSavedCheckbox(page, nil, 24, -94, "Use MOS as default Raid tab", "useMOSRaidTab", "Default Raid tab", "Opens MOS Raid Management from the Raid tab in the social window.", options.useMOSRaidTabChanged)
    local function Bind(button, key)
        button:SetScript("OnClick", function() game.state[key] = not game.state[key]; Settings.ApplyTopSections(page) end)
    end
    Bind(game.interface, "interface"); Bind(game.layout, "layout"); Bind(game.raid, "raid")
end

function Settings.EnsureGameRaidControls(page)
    local game = page.gameUI
    if game.group then return end
    local shell = Settings.CreateRaidViewShell(page, true)
    local factory = Settings.CreateRaidControlFactory(page, {refreshGroup = game.onLayoutChanged}, {
        keyPrefix = "nativeRaidGroup", namePrefix = "MuklaOfficerSuiteNativeRaidGroup",
        defaults = {TileWidth = 160, TileHeight = 13, HeaderHeight = 14, Margin = 4},
        minimums = {TileHeight = 13},
    })
    local group = Settings.CreateRaidGroupViewControls(page, shell, factory, game.onLayoutChanged)
    local _, columns = Settings.CreateRaidColumnControl(page, 40, 0, game.onLayoutChanged, page, "nativeRaidGroupColumns")
    columns.settingKey = "nativeRaidGroupColumns"
    columns:ClearAllPoints(); columns:SetPoint("LEFT", columns.fieldLabel, "RIGHT", 10, 0)
    group.columnsButton = columns
    table.insert(group.layoutControls, columns); table.insert(group.layoutControls, columns.fieldLabel)
    game.shell, game.group = shell, group
    local function Reset(heading, groups, button)
        local reset = Settings.CreateSectionReset(page, heading, groups, game.onLayoutChanged, button)
        table.insert(group.layoutControls, reset)
    end
    Reset(shell.groupHeading, {group.checks, group.sliders, group.colors, group.tileColors, {group.lightnessField, columns}}, shell.groupReset)
    Reset(group.displayHeading, {group.displayChecks})
    Reset(group.sizeHeading, {group.autoChecks, group.sliders, {columns}})
    Reset(group.colorHeading, {group.colorChecks, group.colors, {group.lightnessField}})
    Reset(group.tileColorHeading, {group.tileColors})
    Settings.RefreshGameRaidControls(page)
end

function Settings.RefreshGameRaidControls(page)
    local group = page.gameUI and page.gameUI.group
    if not group then return end
    local index
    for index = 1, table.getn(group.checks) do
        local check = group.checks[index]; check:SetChecked(MOS.Database.GetSetting(check.settingKey) and 1 or nil)
    end
    for index = 1, table.getn(group.sliders) do
        local slider = group.sliders[index]
        MOS.UI.Components.Settings.SynchronizeSlider(slider, MOS.Database.GetSetting(slider.settingKey))
    end
    MOS.UI.Components.Settings.SetSliderEnabled(group.width, not MOS.Database.GetSetting(group.autoWidth.settingKey))
    group.columnsButton:SetText(tostring(MOS.Database.GetSetting(group.columnsButton.settingKey) or 2))
    for _, colors in ipairs({group.colors, group.tileColors}) do
        for index = 1, table.getn(colors) do
            local control = colors[index]; local color = MOS.Database.GetSetting(control.settingKey)
            control.swatch:SetTexture(color[1], color[2], color[3], 1)
        end
    end
    if not group.lightnessField.mosEditing then group.lightnessField:SetText(MOS.Database.GetSetting(group.lightnessField.settingKey) or 5) end
end

function Settings.LayoutGameUI(page, y)
    local game = page.gameUI
    if not game then return y end
    local visible, index = page.topSectionState.gameUI, nil
    PlaceSection(game.heading, page, y)
    game.heading.label:SetText((visible and "-  " or "+  ") .. "Game UI"); game.heading:SetExpanded(visible); game.heading:Show()
    y = y - 28
    local function Accordion(button, key, inset, shown)
        PlaceSection(button, page, y, inset)
        button.label:SetText((game.state[key] and "-  " or "+  ") .. button.baseText)
        if button.SetExpanded then button:SetExpanded(game.state[key]) end
        if shown then button:Show() else button:Hide() end
    end
    Accordion(game.interface, "interface", 12, visible)
    if visible then y = y - 28 end
    local interfaceVisible = visible and game.state.interface
    if interfaceVisible then
        page.interfaceCheck:ClearAllPoints(); page.interfaceCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 24, y)
        page.interfaceCheck:Show(); y = y - 40
    else page.interfaceCheck:Hide() end
    Accordion(game.layout, "layout", 12, visible)
    if visible then y = y - 28 end
    local raidVisible = visible and game.state.layout
    Accordion(game.raid, "raid", 24, raidVisible)
    if raidVisible then y = y - 28 end
    local bodyVisible = raidVisible and game.state.raid
    if bodyVisible then Settings.EnsureGameRaidControls(page) end
    if game.group then
        local method = bodyVisible and "Show" or "Hide"
        for index = 1, table.getn(game.group.layoutControls) do game.group.layoutControls[index][method](game.group.layoutControls[index]) end
        if not bodyVisible then game.group.columnsButton.panel:Hide() end
        if bodyVisible then
            local startY = y
            y = Settings.LayoutGroupControls(page, game.group, game.shell.groupHeading, y, math.max(1, page:GetWidth() - 52))
            game.shell.groupDivider:Hide()
            game.shell.panel:ClearAllPoints(); game.shell.panel:SetPoint("TOPLEFT", page, "TOPLEFT", 24, startY + 12)
            game.shell.panel:SetPoint("BOTTOMRIGHT", page, "TOPLEFT", page:GetWidth() - 12, y + 8)
        end
    end
    return y
end

function Settings.CreateShell(parent, anchorPage, onNavigationLayout, options)
    options = options or {}
    local viewport = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteSettingsScroll", parent, "UIPanelScrollFrameTemplate")
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteSettingsScrollScrollBar"))
    viewport:SetPoint("TOPLEFT", anchorPage, "TOPLEFT", 4, -4)
    viewport:SetPoint("BOTTOMRIGHT", anchorPage, "BOTTOMRIGHT", -4, 4)
    viewport.mosScrollAnchor = anchorPage
    viewport:EnableMouseWheel(true)
    local page = MOS.UI.Components.CreateContainer(nil, viewport)
    page.mosTextSizeDelta = -2
    page:SetWidth(1000); page:SetHeight(960)
    viewport:SetScrollChild(page)
    viewport.settingsPage = page
    page.settingsViewport = viewport
    viewport:SetScript("OnMouseWheel", OnSettingsMouseWheel)
    viewport:SetScript("OnSizeChanged", MOS.UI.Components.Settings.OnViewportSizeChanged)
    local scrollBar = getglobal("MuklaOfficerSuiteSettingsScrollScrollBar")
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPRIGHT", anchorPage, "TOPRIGHT", -4, -24)
        scrollBar:SetPoint("BOTTOMRIGHT", anchorPage, "BOTTOMRIGHT", -4, 20)
    end
    viewport:Hide()
    page.uiHeading = MOS.UI.Components.Settings.CreateSectionAccordion(page, "Addon UI", -10, nil, nil, "list")
    page.keybindings = {
        heading = MOS.UI.Components.Settings.CreateSectionAccordion(page, "Keybindings", -38, nil, nil, "rules"),
        general = MOS.UI.Components.Settings.CreateAccordion(page, "General", -66, "rules"),
    }
    local uiContent = MOS.UI.Components.CreateContainer(nil, page)
    uiContent:SetHeight(224); page.uiContent = uiContent
    local generalHeading = MOS.UI.Components.Settings.CreateAccordion(uiContent, "General", -38, "info")
    generalHeading:ClearAllPoints(); generalHeading:SetPoint("TOPLEFT", uiContent, "TOPLEFT", 12, -38)
    page.uiGeneralHeading = generalHeading; page.uiSectionState = { general = false, layout = false }
    generalHeading:SetScript("OnClick", function() page.uiSectionState.general = not page.uiSectionState.general; Settings.ApplyTopSections(page) end)
    local skinControl = Settings.CreateSkinControl(uiContent, 40, -94)
    local loginMessageCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteDisableLoginMessage", 224, -94, "Turn off addon login message", "suppressLoginMessage")
    local minimapCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideMinimapIcon", 20, -94, "Hide minimap icon", "hideMinimapIcon", nil, nil, options.minimapVisibilityChanged)
    page.chromeChecks = {
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideHeaderBar", 20, -122, "Hide header bar", "hideHeaderBar", nil, nil, onNavigationLayout),
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideStatusBar", 20, -122, "Hide status and version bar", "hideStatusVersionBar", nil, nil, onNavigationLayout),
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideHeaderLogo", 20, -150, "Hide header logo", "hideHeaderLogo", nil, nil, onNavigationLayout),
        Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteHideHeaderName", 224, -150, "Hide header name", "hideHeaderName", nil, nil, onNavigationLayout),
    }
    local layoutHeading = MOS.UI.Components.Settings.CreateAccordion(uiContent, "Layout", -66, "resize")
    layoutHeading:SetPoint("TOPLEFT", uiContent, "TOPLEFT", 12, -66)
    layoutHeading:SetScript("OnClick", function() page.uiSectionState.layout = not page.uiSectionState.layout; Settings.ApplyTopSections(page) end)
    local menuStyleControl = Settings.CreateMenuStyleControl(uiContent, 24, -206, function()
        page.RefreshGeneralSettings()
        if onNavigationLayout then onNavigationLayout() end
    end)
    local iconTabsCheck = Settings.CreateSavedCheckbox(uiContent, "MuklaOfficerSuiteUseIconTabs", 330, -204, "Use Icon Tabs", "useIconTabs", nil, nil, onNavigationLayout)
    local _, detailsControl = MOS.UI.Components.CreateChoiceField({
        parent = page, x = 56, y = -234, label = "Player details style:", width = 110, height = 51,
        initialText = "Collapsible", firstY = -7, step = 19,
        choices = { { text = "Collapsible", value = "collapsible" }, { text = "Window", value = "window" } },
        getValue = function() return MOS.Database.GetSetting("playerDetailsStyle") or "collapsible" end,
        onSelect = function(value) MOS.Database.SetSetting("playerDetailsStyle", value); RefreshRosterLayout() end,
    })
    page.playerDetailsControl = detailsControl
    detailsControl:Hide(); detailsControl.fieldLabel:Hide()
    Settings.CreateGameUI(page, options)
    page.generalGrid = { minimapCheck, loginMessageCheck }
    page.layoutGeneralChecks = {}
    page.layoutGrid = { page.chromeChecks[1], page.chromeChecks[2], page.chromeChecks[3], page.chromeChecks[4], iconTabsCheck }
    page.uiLayoutHeading = layoutHeading
    page.uiLayoutGeneralHeading = MOS.UI.Components.CreateHeading(uiContent, "", 3, "orange", "info"); page.uiLayoutGeneralHeading:SetText("General")
    page.uiLayoutDisplayHeading = MOS.UI.Components.CreateHeading(uiContent, "", 3, "orange", "list"); page.uiLayoutDisplayHeading:SetText("Display")
    page.iconTabsCheck = iconTabsCheck
    page.skinControl = skinControl
    page.menuStyleControl = menuStyleControl
    page.RefreshGeneralSettings = function()
        MOS.Database.Ensure()
        detailsControl:SetText(MOS.Database.GetSetting("playerDetailsStyle") == "window" and "Window" or "Collapsible")
        skinControl:SetText(MOS.UI.Components.IsClassicSkin() and "Default" or "Classic WIP")
        menuStyleControl:SetText(MuklaOfficerSuiteDB.menuStyle == "tabs" and "Top tab view" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs" and "Bottom tab view" or "Right side view")
        iconTabsCheck:SetChecked(MuklaOfficerSuiteDB.useIconTabs and 1 or nil)
        if MuklaOfficerSuiteDB.menuStyle == "tabs" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs" then iconTabsCheck:Show() else iconTabsCheck:Hide() end
        local index
        for index = 1, table.getn(page.chromeChecks) do local check = page.chromeChecks[index]; check:SetChecked(MOS.Database.GetSetting(check.settingKey) and 1 or nil) end
        loginMessageCheck:SetChecked(MuklaOfficerSuiteDB.suppressLoginMessage and 1 or nil)
        minimapCheck:SetChecked(MuklaOfficerSuiteDB.hideMinimapIcon and 1 or nil)
        page.interfaceCheck:SetChecked(MOS.Database.GetSetting("useMOSRaidTab") and 1 or nil)
        Settings.RefreshGameRaidControls(page)
        if page.topSectionState then Settings.ApplyTopSections(page) end
    end
    page.ApplySavedSettings = function()
        MOS.UI.Components.SetSkin(MOS.Database.GetSetting("uiSkin"), false)
        if options.minimapVisibilityChanged then options.minimapVisibilityChanged() end
        if onNavigationLayout then onNavigationLayout() end
        if page.RefreshAllSettings then page.RefreshAllSettings() else page.RefreshGeneralSettings() end
        if options.profileLoaded then options.profileLoaded() end
    end
    Settings.BindTopSections(page, page.ApplySavedSettings)
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
        choices = { { text = "Default", value = "classic" }, { text = "Classic WIP", value = "default" } },
        getValue = function() return MOS.UI.Components.IsClassicSkin() and "classic" or "default" end,
        onSelect = function(value) MOS.UI.Components.SetSkin(value, true) end,
    })
    return button
end

function Settings.CreateRosterAppearance(page)
    local C = MOS.UI.Components
    page.rosterDisplayHeading = C.CreateHeading(page, "", 3, "orange", "list"); page.rosterDisplayHeading:SetText("Display")
    page.rosterColorHeading = C.CreateHeading(page, "", 3, "orange", "roster"); page.rosterColorHeading:SetText("Member tile color:")
    page.rosterColors = {
        controls.CreateColor(page, 52, 0, "Background color", "rosterBackgroundColor", RefreshRosterLayout),
        controls.CreateColor(page, 52, 0, "Main text color", "rosterTextColor", RefreshRosterLayout),
        controls.CreateColor(page, 52, 0, "Hover color", "rosterHoverColor", RefreshRosterLayout),
    }
    page.rosterLightnessLabel, page.rosterLightnessField = controls.CreatePercentageField(page, "MuklaOfficerSuiteRosterLightness", "Odd record lightness (%)", 56, 0, "rosterOddLightness", 5)
    page.rosterLightnessField.onChanged = RefreshRosterLayout
end

function Settings.CreatePrimarySections(page)
    local C = MOS.UI.Components
    page.uiFeatureState = { roster = false, raid = false }
    local rosterHeading = C.Settings.CreateSectionAccordion(page, "Guild", -150, 12, 3)
    if C.SetHeadingIcon then C.SetHeadingIcon(rosterHeading.label, "roster") end
    local rosterGeneral = MOS.UI.Components.Settings.CreateAccordion(page, "General", -178, "roster")
    page.rosterLiveTrackingCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRosterLiveTracking", 52, -206, "Live tracking", "rosterLiveTrackingEnabled", "Guild live tracking", "Keeps the guild roster current while Guild is open. Work stops when this screen is closed.", RosterTrackingChanged)
    page.rosterLayoutChecks = {}
    local index
    for index = 1, table.getn(rosterLayoutOptions) do
        local option = rosterLayoutOptions[index]
        page.rosterLayoutChecks[index] = Settings.CreateSavedCheckbox(page, nil, 52, -234, option[1], option[2], nil, nil, RefreshRosterLayout)
        page.rosterLayoutChecks[index].invertSetting = option[2] == "rosterHideSectionHeader"
    end
    local rosterLayout = MOS.UI.Components.Settings.CreateAccordion(page, "Layout", -206, "resize")
    page.rosterClassColorsCheck = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteClassColors", 52, -234, "Use class colors", "rosterClassColors", nil, nil, RefreshRosterLayout)
    Settings.CreateRosterAppearance(page)
    local raidHeading = C.Settings.CreateSectionAccordion(page, "Raid", -206, 12, 3)
    if C.SetHeadingIcon then C.SetHeadingIcon(raidHeading.label, "raids") end
    local function ToggleFeature(key)
        page.uiFeatureState[key] = not page.uiFeatureState[key]
        Settings.ApplyTopSections(page)
    end
    rosterHeading:SetScript("OnClick", function() ToggleFeature("roster") end)
    raidHeading:SetScript("OnClick", function() ToggleFeature("raid") end)
    page.uiEmptySections = {}
    local featureIcons = { "guild_stats", "raid_stats", "csr", "performance" }
    for featureIndex, title in ipairs({ "Guild Statistics", "Raid Statistics", "CSR", "Profiler" }) do
        local section = {
            heading = C.Settings.CreateSectionAccordion(page, title, -234, 12, 3),
            general = C.Settings.CreateAccordion(page, "General", -262, featureIcons[featureIndex]),
            layout = C.Settings.CreateAccordion(page, "Layout", -290, "resize"),
            expanded = false, generalOpen = false, layoutOpen = false,
        }
        if C.SetHeadingIcon then C.SetHeadingIcon(section.heading.label, featureIcons[featureIndex]) end
        section.heading:SetScript("OnClick", function() section.expanded = not section.expanded; Settings.ApplyTopSections(page) end)
        section.general:SetScript("OnClick", function() section.generalOpen = not section.generalOpen; Settings.ApplyTopSections(page) end)
        section.layout:SetScript("OnClick", function() section.layoutOpen = not section.layoutOpen; Settings.ApplyTopSections(page) end)
        table.insert(page.uiEmptySections, section)
    end
    local debugHeading = MOS.UI.Components.Settings.CreateSectionAccordion(page, "Debug", -645, nil, nil, "analyze")
    debugHeading:SetScript("OnClick", function()
        page.topSectionState.debug = not page.topSectionState.debug
        Settings.ApplyRaidAccordions(page.raidAccordionControls)
    end)
    return { rosterHeading = rosterHeading, rosterGeneral = rosterGeneral, rosterLayout = rosterLayout, raidHeading = raidHeading, debugHeading = debugHeading }
end

function Settings.CreateRaidColumnControl(page, x, y, onChanged, labelOwner, settingKey)
    settingKey = settingKey or "raidGroupColumns"
    return MOS.UI.Components.CreateChoiceField({
        parent = page, labelOwner = labelOwner, x = x + 12, y = y, label = "Columns",
        font = "GameFontHighlightSmall", color = { 1, 1, 1 }, labelOffset = -6, buttonOffset = 52,
        width = 52, height = 86, initialText = "2", firstY = -5, step = 20, labelValue = true,
        choices = { { text = "1", value = 1 }, { text = "2", value = 2 }, { text = "3", value = 3 }, { text = "4", value = 4 } },
        getValue = function() MOS.Database.Ensure(); return MOS.Database.GetSetting(settingKey) end,
        onSelect = function(value) MOS.Database.Ensure(); MOS.Database.SetSetting(settingKey, value) end,
        onChanged = onChanged,
    })
end

function Settings.CreateRaidViewShell(page, groupOnly)
    local panel = MOS.UI.Components.CreateContainer(nil, page)
    panel:SetPoint("TOPLEFT", page, "TOPLEFT", 36, -306)
    panel:SetPoint("BOTTOMRIGHT", page, "TOPRIGHT", -6, -1110)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    panel:SetBackdropColor(0.025, 0.025, 0.025, 0.48)
    panel:SetBackdropBorderColor(0, 0, 0, 0)

    local groupHeading = MOS.UI.Components.CreateHeading(panel, "", 3, "orange", "groups")
    groupHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -318)
    groupHeading:SetText("Group View")
    groupHeading:SetTextColor(1, 0.82, 0)
    local groupReset = MOS.UI.Components.CreateButton(page, nil, "Reset to default", 112, 20)
    MOS.UI.Components.SizeClassicButton(groupReset, 100, 18, 0.8)
    groupHeading.resetButton = groupReset; AlignReset(groupHeading)
    local groupDivider = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    groupDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -336)
    groupDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -336)
    groupDivider:SetHeight(1)
    groupDivider:SetTexture(0.75, 0.75, 0.75, 0.55)
    if groupOnly then return { panel = panel, groupHeading = groupHeading, groupReset = groupReset, groupDivider = groupDivider } end

    local listDivider = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    listDivider:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -866)
    listDivider:SetPoint("TOPRIGHT", page, "TOPRIGHT", -36, -866)
    listDivider:SetHeight(1)
    listDivider:SetTexture(0.75, 0.75, 0.75, 0.55)
    local listHeading = MOS.UI.Components.CreateHeading(panel, "", 3, "orange", "list")
    listHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 48, -846)
    listHeading:SetText("List View")
    listHeading:SetTextColor(1, 0.82, 0)
    local listReset = MOS.UI.Components.CreateButton(page, nil, "Reset to default", 112, 20)
    MOS.UI.Components.SizeClassicButton(listReset, 100, 18, 0.8)
    listHeading.resetButton = listReset; AlignReset(listHeading)

    return { panel = panel, groupHeading = groupHeading, groupReset = groupReset, groupDivider = groupDivider, listDivider = listDivider, listHeading = listHeading, listReset = listReset }
end

function Settings.CreateRaidControlFactory(page, callbacks, options)
    options = options or {}
    local function Key(key) return options.keyPrefix and string.gsub(key, "^raidGroup", options.keyPrefix) or key end
    local function Name(name) return options.namePrefix and string.gsub(name, "^MuklaOfficerSuiteGroup", options.namePrefix) or name end
    local function Refresh(settingKey)
        if string.find(settingKey, "raidList", 1, true) then
            if callbacks.refreshList then callbacks.refreshList() end
        elseif callbacks.refreshGroup then
            callbacks.refreshGroup()
        end
    end
    return {
        Key = Key, Name = Name,
        Checkbox = function(x, y, text, key)
            return controls.CreateCheckbox(page, x + 12, y, text, Key(key), Refresh)
        end,
        Slider = function(name, x, y, label, key, minimum, maximum)
            local suffix = string.gsub(key, "^raidGroup", "")
            if options.defaults and options.defaults[suffix] then label = string.gsub(label, "default: %d+", "default: " .. options.defaults[suffix]) end
            if options.minimums and options.minimums[suffix] then minimum = options.minimums[suffix] end
            return controls.CreateSlider(page, Name(name), x + 12, y, label, Key(key), minimum, maximum, Refresh)
        end,
        Percentage = function(name, key, parent)
            local label, field = controls.CreatePercentageField(parent or page, Name(name), "Odd record lightness (%)", 52, 0, Key(key), 5)
            field.onChanged = Refresh
            return label, field
        end,
        Color = function(x, y, label, key)
            return controls.CreateColor(page, x + 12, y, label, Key(key), Refresh)
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
    local function Name(name) return factory.Name and factory.Name(name) or name end
    local function Heading(text, y, iconKey)
        local heading = MOS.UI.Components.CreateHeading(shell.panel, "", 3, "orange", iconKey)
        heading:SetPoint("TOPLEFT", page, "TOPLEFT", 52, y)
        heading:SetText(text)
        heading:SetTextColor(1, 0.82, 0)
        heading:SetAlpha(1)
        return heading
    end
    local displayHeading = Heading("Display", -356, "list")
    local showClass = factory.Checkbox(40, -410, "Show class", "raidGroupShowClass")
    local showLevel = factory.Checkbox(300, -410, "Show lvl", "raidGroupShowLevel")
    local showHeader = factory.Checkbox(40, -434, "Show group header", "raidGroupShowHeader")
    local showBorder = factory.Checkbox(40, -460, "Show group border", "raidGroupShowBorder")
    local showLootMaster = factory.Checkbox(300, -434, "Show LM icon", "raidGroupShowLootMaster")
    local showRole = factory.Checkbox(40, -458, "Show role icon", "raidGroupShowRoleIcon")
    local sizeHeading = Heading("Size", -492, "resize")
    local autoWidth = factory.Checkbox(40, -514, "Adjust tile width to window", "raidGroupAutoTileWidth")
    local width = factory.Slider("MuklaOfficerSuiteGroupTileWidth", 40, -566, "Member tile width (default: 280)", "raidGroupTileWidth", 160, 340)
    local height = factory.Slider("MuklaOfficerSuiteGroupTileHeight", 300, -566, "Member tile height (default: 20)", "raidGroupTileHeight", 14, 28)
    local headerHeight = factory.Slider("MuklaOfficerSuiteGroupHeaderHeight", 40, -622, "Group header height (default: 22)", "raidGroupHeaderHeight", 14, 40)
    local margin = factory.Slider("MuklaOfficerSuiteGroupMargin", 300, -622, "Margin between groups (default: 8)", "raidGroupMargin", 0, 32)
    local tileTextSize = factory.Slider("MuklaOfficerSuiteGroupTileTextSize", 40, -678, "Tile text size (default: 10)", "raidGroupTileTextSize", 8, 16)
    local headerTextSize = factory.Slider("MuklaOfficerSuiteGroupHeaderTextSize", 300, -678, "Tile header text size (default: 10)", "raidGroupHeaderTextSize", 8, 16)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupTileWidth"), width)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupTileHeight"), height)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupHeaderHeight"), headerHeight)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupMargin"), margin)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupTileTextSize"), tileTextSize)
    AlignSliderLabel(Name("MuklaOfficerSuiteGroupHeaderTextSize"), headerTextSize)
    local originalAutoWidthSave = autoWidth.SaveSetting
    autoWidth.SaveSetting = function(owner)
        originalAutoWidthSave(owner)
        MOS.UI.Components.Settings.SetSliderEnabled(width, not owner:GetChecked())
    end
    local colorHeading = Heading("Member tile color", -724, "roster")
    local classColors = factory.Checkbox(40, -746, "Use class colors", "raidGroupClassColors")
    local background = factory.Color(40, -774, "Background color", "raidGroupBackgroundColor")
    local text = factory.Color(230, -774, "Main text color", "raidGroupTextColor")
    local hover = factory.Color(40, -802, "Hover color", "raidGroupHoverColor")
    local tileColorHeading = Heading("Group tile color", -860, "groups")
    local headerText = factory.Color(40, -886, "Header text color", "raidGroupHeaderTextColor")
    local headerBackground = factory.Color(230, -886, "Header background color", "raidGroupHeaderBackgroundColor")
    local border = factory.Color(40, -914, "Border color", "raidGroupBorderColor")
    local lightnessLabel, lightnessField = factory.Percentage("MuklaOfficerSuiteGroupLightness", "raidGroupOddLightness", shell.panel)
    return {
        lightnessLabel = lightnessLabel, lightnessField = lightnessField,
        displayHeading = displayHeading, sizeHeading = sizeHeading, colorHeading = colorHeading,
        displayChecks = { showClass, showLevel, showHeader, showLootMaster, showRole, showBorder },
        memberDisplayChecks = {showClass, showLevel, showLootMaster, showRole}, showHeader = showHeader, showBorder = showBorder,
        autoChecks = {autoWidth}, colorChecks = {classColors}, sliders = {width, height, headerHeight, margin, tileTextSize, headerTextSize},
        checks = { showClass, showLevel, showHeader, showLootMaster, showBorder, showRole, autoWidth, classColors },
        width = width, height = height, headerHeight = headerHeight, margin = margin, tileTextSize = tileTextSize, headerTextSize = headerTextSize, autoWidth = autoWidth, colors = { background, text, hover },
        tileColorHeading = tileColorHeading, tileColors = {headerText, headerBackground, border},
        layoutControls = { shell.panel, shell.groupHeading, shell.groupReset, shell.groupDivider, displayHeading, showClass, showLevel, showHeader, showLootMaster, showBorder, showRole, sizeHeading, autoWidth, width, height, headerHeight, margin, tileTextSize, headerTextSize, colorHeading, classColors, background, text, hover, lightnessLabel, lightnessField, tileColorHeading, headerText, headerBackground, border },
    }
end

function Settings.CreateRaidListViewControls(page, shell, factory)
    local function Heading(text, iconKey)
        local heading = MOS.UI.Components.CreateHeading(shell.panel, "", 3, "orange", iconKey); heading:SetText(text); return heading
    end
    local displayHeading, sizeHeading, colorHeading = Heading("Display", "list"), Heading("Size", "resize"), Heading("Member tile color", "roster")
    local lightnessLabel, lightnessField = factory.Percentage("MuklaOfficerSuiteListLightness", "raidListOddLightness", shell.panel)
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
    local pressed = factory.Color(230, -1078, "Collapsed color", "raidListPressedColor")
    return {
        displayHeading=displayHeading, sizeHeading=sizeHeading, colorHeading=colorHeading, lightnessLabel=lightnessLabel, lightnessField=lightnessField,
        sliders = {width, height},
        checks = { showName, showLevel, showStatus, showGroup, showClass, showRank, showSoftReserve, showLootMaster, showRole, showFilters, showSearch },
        width = width, height = height, colors = { background, text, hover, pressed },
        layoutControls = { shell.listDivider, shell.listHeading, shell.listReset, showName, showLevel, showStatus, showGroup, showClass, showRank, showSoftReserve, showLootMaster, showRole, showFilters, showSearch, width, height, background, text, hover, pressed, displayHeading, sizeHeading, colorHeading, lightnessLabel, lightnessField },
    }
end

function Settings.MergeControls(target, source)
    local index
    for index = 1, table.getn(source) do table.insert(target, source[index]) end
    return target
end

function Settings.CreateSectionReset(page, heading, groups, refresh, existingButton)
    local keys = {}
    for _, group in ipairs(groups) do
        for _, control in ipairs(group) do if control.settingKey then keys[control.settingKey] = true end end
    end
    local button = existingButton or MOS.UI.Components.CreateButton(heading:GetParent(), nil, "Reset to default", 100, 18)
    MOS.UI.Components.SizeClassicButton(button, 100, 18, 0.8)
    heading.resetButton = button; AlignReset(heading)
    button.ResetConfirmed = function()
        MOS.Core.SettingsProfiles.ResetDefaults(keys)
        if page.RefreshAllSettings then page.RefreshAllSettings() end
        if refresh then refresh() end
    end
    if not StaticPopupDialogs.MUKLA_OFFICER_SUITE_RESET_SUBSECTION then
        StaticPopupDialogs.MUKLA_OFFICER_SUITE_RESET_SUBSECTION = {
            text="Reset this subsection to default settings?", button1="Reset", button2="Cancel",
            timeout=0, whileDead=1, hideOnEscape=1,
            OnAccept=function() local pending=Settings.pendingReset; Settings.pendingReset=nil; if pending then pending.ResetConfirmed() end end,
            OnCancel=function() Settings.pendingReset=nil end,
        }
    end
    button:SetScript("OnClick", function() Settings.pendingReset=this; MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_SUBSECTION") end)
    heading.resetButton = button
    return button
end

function Settings.AttachSectionResets(page, callbacks)
    local C = Settings.CreateSectionReset
    C(page, page.uiLayoutDisplayHeading, {page.chromeChecks}, page.ApplySavedSettings)
    C(page, page.rosterDisplayHeading, {page.rosterLayoutChecks}, RefreshRosterLayout)
    C(page, page.rosterColorHeading, {{page.rosterClassColorsCheck, page.rosterLightnessField}, page.rosterColors}, RefreshRosterLayout)
    local group, list = page.responsiveRaid.group, page.responsiveRaid.list
    local function Add(view, heading, groups, refresh)
        local button = C(page, heading, groups, refresh)
        table.insert(page.raidAccordionControls.layoutControls, button)
    end
    Add(group, group.displayHeading, {group.displayChecks}, callbacks.refreshGroup)
    Add(group, group.sizeHeading, {group.autoChecks, group.sliders}, callbacks.refreshGroup)
    Add(group, group.colorHeading, {group.colorChecks, group.colors, {group.lightnessField}}, callbacks.refreshGroup)
    Add(group, group.tileColorHeading, {group.tileColors}, callbacks.refreshGroup)
    Add(list, list.displayHeading, {list.checks}, callbacks.refreshList)
    Add(list, list.sizeHeading, {list.sliders}, callbacks.refreshList)
    Add(list, list.colorHeading, {list.colors, {list.lightnessField}}, callbacks.refreshList)
    local reset = MOS.UI.Components.CreateButton(page, nil, "Reset to defaults", 130, 20)
    page.globalReset = reset
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_RESET_ALL_SETTINGS"] = {
        text = "Reset all settings to defaults? Saved profiles, guild data and raid history will be kept.",
        button1 = "Reset", button2 = "Cancel", timeout = 0, whileDead = 1, hideOnEscape = 1,
        OnAccept = function()
            MOS.Core.SettingsProfiles.ResetDefaults()
            page.ApplySavedSettings()
            if callbacks.trackingChanged then callbacks.trackingChanged() end
            RosterTrackingChanged()
            if callbacks.refreshGroup then callbacks.refreshGroup() end
            if callbacks.refreshList then callbacks.refreshList() end
        end,
    }
    reset:SetScript("OnClick", function() MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RESET_ALL_SETTINGS") end)
end

function Settings.CreateRaidSettings(page, callbacks)
    local primarySections = Settings.CreatePrimarySections(page)
    page.primarySections = primarySections
    local general = MOS.UI.Components.Settings.CreateAccordion(page, "General", -230, "raids")
    local liveTracking = Settings.CreateSavedCheckbox(page, "MuklaOfficerSuiteRaidLiveTracking", 52, -252, "Live tracking", "raidLiveTrackingEnabled", "Raid live tracking", "Keeps raid membership and loot current while Raid is open. This may have a small performance impact only while the Raid window is open, not while it is closed.", callbacks.trackingChanged)
    page.raidLiveTrackingCheck = liveTracking
    local layout = MOS.UI.Components.Settings.CreateAccordion(page, "Layout", -280, "resize")
    local shell = Settings.CreateRaidViewShell(page)
    local factory = Settings.CreateRaidControlFactory(page, callbacks)
    local groupControls = Settings.CreateRaidGroupViewControls(page, shell, factory, callbacks.refreshGroup)
    page.raidHideHeaderCheck = Settings.CreateSavedCheckbox(page, nil, 52, -318, "Hide section header", "raidHideSectionHeader", nil, nil, callbacks.refreshList)
    table.insert(groupControls.checks, page.raidHideHeaderCheck)
    local listControls = Settings.CreateRaidListViewControls(page, shell, factory)
    local leader = MOS.UI.Components.Settings.CreateAccordion(page, "Raid Leader Mode", -1126, "leader")
    local loot = MOS.UI.Components.Settings.CreateAccordion(page, "Loot Master Mode", -1154, "lootmaster")
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
        percentages = {groupControls.lightnessField, listControls.lightnessField},
        colors = Settings.MergeControls(Settings.MergeControls(Settings.MergeControls({}, groupControls.colors), groupControls.tileColors), listControls.colors),
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
            local check = page.rosterLayoutChecks[index]; check:SetChecked((check.invertSetting and not MuklaOfficerSuiteDB[check.settingKey] or not check.invertSetting and MuklaOfficerSuiteDB[check.settingKey]) and 1 or nil)
        end
        page.rosterLightnessField:SetText(MuklaOfficerSuiteDB.rosterOddLightness or 5)
        for index = 1, table.getn(page.rosterColors) do local control = page.rosterColors[index]; local color = MOS.Database.GetSetting(control.settingKey); if color then control.swatch:SetTexture(color[1],color[2],color[3],1) end end
        if page.RefreshRaidViewSettings then page.RefreshRaidViewSettings() end
        Settings.SyncSavedControls(page.chatLogsCheck, page.raidAccordionControls.opacityField, page.raidAccordionControls.focusField)
        page.ApplyRaidLayoutAccordion()
    end
    Settings.AttachSectionResets(page, callbacks)
    page.RefreshGeneralSettings()
    page.ApplyRaidLayoutAccordion()
end

function Settings.CreateMenuStyleControl(parent, x, y, onChanged)
    local _, button = MOS.UI.Components.CreateChoiceField({
        parent = parent, x = x, y = y, label = "Menu type", width = 126, height = 72,
        initialText = "Right side view", firstY = -7, step = 19,
        choices = { { text = "Right side view", value = "buttons" }, { text = "Top tab view", value = "tabs" }, { text = "Bottom tab view", value = "bottomTabs" } },
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

    local checkIndex
    for checkIndex = 1, table.getn(controls.checks) do
        local check = controls.checks[checkIndex]
        check:SetChecked((check.invertSetting and not MuklaOfficerSuiteDB[check.settingKey] or not check.invertSetting and MuklaOfficerSuiteDB[check.settingKey]) and 1 or nil)
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

    for _, field in ipairs(controls.percentages or {}) do if not field.mosEditing then field:SetText(MOS.Database.GetSetting(field.settingKey) or 5) end end
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
    local raidVisible = FeatureOpen(controls.page, "raid")
    local expanded = state.layout and raidVisible
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
        if state.general and raidVisible then controls.generalControls[controlIndex]:Show() else controls.generalControls[controlIndex]:Hide() end
    end
    if controls.columnsPanel then controls.columnsPanel:Hide() end

    local offset = controls.raidOffset or 0
    controls.general:ClearAllPoints(); controls.general:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, -230 + offset)
    if controls.generalControls and controls.generalControls[1] then
        controls.generalControls[1]:ClearAllPoints(); controls.generalControls[1]:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 40, -252 + offset)
    end
    local generalHeight = 26
    if controls.generalControls and table.getn(controls.generalControls) > 1 then
        generalHeight = MOS.UI.Components.Settings.LayoutGrid(controls.page, controls.generalControls, 40, -252 + offset, controls.page:GetWidth() - 52, 26)
    end
    local generalExtra = state.general and math.max(0, generalHeight - 26) or 0
    local layoutY = (state.general and -280 or -258) + offset - generalExtra
    controls.layout:ClearAllPoints()
    controls.layout:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, layoutY)

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
    controls.leader:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, leaderY)
    controls.loot:ClearAllPoints()
    controls.loot:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 24, lootY)
    if controls.page.topSectionState and not controls.page.topSectionState.ui then
        debugY = (controls.page.uiHeadingY or -38) - 28
        chatY = debugY - 30
    elseif not raidVisible then
        debugY = -206 + offset - 28
    end
    debugY = Settings.LayoutFollowingSections(controls.page, debugY)
    chatY = debugY - 30
    controls.debugHeading:ClearAllPoints()
    controls.debugHeading:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 0, debugY)
    controls.debugHeading:SetPoint("TOPRIGHT", controls.page, "TOPRIGHT", 0, debugY)

    if controls.opacityLabel then
        controls.opacityLabel:ClearAllPoints()
        controls.opacityLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 40, opacityY)
        controls.opacityField:ClearAllPoints()
        controls.opacityField:SetPoint("LEFT", controls.opacityLabel, "RIGHT", 8, 0)
        controls.focusLabel:ClearAllPoints()
        controls.focusLabel:SetPoint("TOPLEFT", controls.page, "TOPLEFT", 210, opacityY)
        controls.focusField:ClearAllPoints()
        controls.focusField:SetPoint("LEFT", controls.focusLabel, "RIGHT", 8, 0)
        if state.loot and raidVisible then
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
    if controls.page.globalReset then
        controls.page.globalReset:ClearAllPoints(); controls.page.globalReset:SetPoint("TOPRIGHT", controls.page, "TOPRIGHT", -12, -controls.page.settingsContentHeight - 8)
        controls.page.settingsContentHeight = controls.page.settingsContentHeight + 40
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
    local function RaidRoot(control) if FeatureOpen(page, "raid") then control:Show() else control:Hide() end end
    RaidRoot(controls.general); RaidRoot(controls.layout); RaidRoot(controls.leader); RaidRoot(controls.loot)
    if sections then
        if FeatureOpen(page, "roster") then sections.rosterGeneral:Show(); sections.rosterLayout:Show()
        else sections.rosterGeneral:Hide(); sections.rosterLayout:Hide() end
    end
    if not visible then
        page.rosterLiveTrackingCheck:Hide(); page.rosterClassColorsCheck:Hide()
        page.playerDetailsControl:Hide(); page.playerDetailsControl.fieldLabel:Hide(); page.playerDetailsControl.panel:Hide()
        if page.rosterDisplayHeading.resetButton then page.rosterDisplayHeading.resetButton:Hide(); page.rosterColorHeading.resetButton:Hide(); page.uiLayoutDisplayHeading.resetButton:Hide() end
        page.rosterDisplayHeading:Hide(); page.rosterColorHeading:Hide(); page.rosterLightnessLabel:Hide(); page.rosterLightnessField:Hide()
        for colorIndex = 1, table.getn(page.rosterColors) do page.rosterColors[colorIndex]:Hide() end
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
    local uiVisible = FeatureOpen(page, "roster")
    local topOffset = page.settingsTopOffset or 0
    PlaceSection(sections.rosterHeading, page, -150 + topOffset, 12)
    if sections.rosterHeading.label then
        sections.rosterHeading.label:SetText((uiVisible and "-  " or "+  ") .. "Guild")
        sections.rosterHeading:SetExpanded(uiVisible)
    end
    sections.rosterGeneral:ClearAllPoints(); sections.rosterGeneral:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -178 + topOffset)
    page.rosterLiveTrackingCheck:ClearAllPoints(); page.rosterLiveTrackingCheck:SetPoint("LEFT", page.playerDetailsControl, "RIGHT", 12, 0)
    sections.rosterGeneral.label:SetText((state.general and "-  " or "+  ") .. sections.rosterGeneral.baseText)
    sections.rosterLayout.label:SetText((state.layout and "-  " or "+  ") .. sections.rosterLayout.baseText)
    if state.general and uiVisible then sections.rosterGeneral:UnlockHighlight(); page.rosterLiveTrackingCheck:Show()
    else sections.rosterGeneral:UnlockHighlight(); page.rosterLiveTrackingCheck:Hide() end
    local details = page.playerDetailsControl
    details.fieldLabel:ClearAllPoints(); details.fieldLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 44, -206 + topOffset)
    local live = page.rosterLiveTrackingCheck
    if live.label then
        live.label:SetText("Live tracking")
        if page:GetWidth() < 440 then live.label:SetText("Live") end
        if live.labelHit then live.labelHit:SetWidth(math.max(18, live.label:GetStringWidth() + 8)) end
    end
    local liveWidth = live:GetWidth() + (live.label and live.label:GetStringWidth() or 76) + 12
    local detailsWidth = math.max(1, page:GetWidth() - 56 - liveWidth - 12)
    local choiceWidth = math.min(110, math.max(70, detailsWidth / 2))
    details:SetWidth(choiceWidth)
    local labelWidth = math.max(1, detailsWidth - choiceWidth - 10)
    local path, size, flags = details.fieldLabel:GetFont()
    details.fieldLabel:SetFont(path, details.fieldLabel.mosFitFontSize or size, flags)
    details.fieldLabel:SetWidth(0); details.fieldLabel:SetText("Player details style:")
    if details.fieldLabel:GetStringWidth() > labelWidth then details.fieldLabel:SetText("Details style:") end
    MOS.UI.Components.FitButtonLabel(details.fieldLabel, labelWidth)
    details.fieldLabel:SetWidth(math.min(labelWidth, math.ceil(details.fieldLabel:GetStringWidth() + 2)))
    MOS.UI.Components.FitButtonLabel(details, math.max(1, choiceWidth - 16))
    if state.general and uiVisible then details:Show(); details.fieldLabel:Show()
    else details:Hide(); details.fieldLabel:Hide(); details.panel:Hide() end
    local layoutY = (state.general and -234 or -206) + topOffset
    sections.rosterLayout:ClearAllPoints(); sections.rosterLayout:SetPoint("TOPLEFT", page, "TOPLEFT", 24, layoutY)
    if state.layout and uiVisible then sections.rosterLayout:UnlockHighlight(); page.rosterClassColorsCheck:Show()
    else sections.rosterLayout:UnlockHighlight(); page.rosterClassColorsCheck:Hide() end
    page.rosterClassColorsCheck:ClearAllPoints(); page.rosterClassColorsCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 40, layoutY - 28)
    local index
    page.canShowOfficerOption = Settings.CanShowOfficerOption()
    for index = 1, table.getn(page.rosterLayoutChecks or {}) do
        local check = page.rosterLayoutChecks[index]
        check:ClearAllPoints(); check:SetPoint("TOPLEFT", page, "TOPLEFT", 40 + math.mod(index - 1, 2) * 260, layoutY - 56 - math.floor((index - 1) / 2) * 26)
        if state.layout and uiVisible and (check.settingKey ~= "rosterShowOfficerNote" or page.canShowOfficerOption) then check:Show() else check:Hide() end
    end
    local gridHeight = 0
    if page.rosterLayoutChecks then
        page.rosterGrid = page.rosterGrid or {}
        for index = table.getn(page.rosterGrid), 1, -1 do table.remove(page.rosterGrid, index) end
        for index = 1, table.getn(page.rosterLayoutChecks) do
            local check = page.rosterLayoutChecks[index]
            if check.settingKey ~= "rosterShowOfficerNote" or page.canShowOfficerOption then table.insert(page.rosterGrid, check) end
        end
        gridHeight = MOS.UI.Components.Settings.LayoutGrid(page, page.rosterGrid, 40, layoutY - 56, page:GetWidth() - 52, 26)
    end
    local colorY = layoutY - 68 - gridHeight
    page.rosterDisplayHeading:ClearAllPoints(); page.rosterDisplayHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 44, layoutY - 28)
    page.rosterColorHeading:ClearAllPoints(); page.rosterColorHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 44, colorY)
    AlignReset(page.rosterDisplayHeading); AlignReset(page.rosterColorHeading)
    page.rosterClassColorsCheck:ClearAllPoints(); page.rosterClassColorsCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 40, colorY - 26)
    local colorHeight = MOS.UI.Components.Settings.LayoutGrid(page, page.rosterColors, 44, colorY - 54, page:GetWidth() - 56, 28)
    page.rosterLightnessLabel:ClearAllPoints(); page.rosterLightnessLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 44, colorY - 54 - colorHeight)
    if not page.rosterLightnessField.mosEditing then page.rosterLightnessField:SetText(MOS.Database.GetSetting("rosterOddLightness") or 5) end
    local method = state.layout and uiVisible and "Show" or "Hide"
    if page.rosterDisplayHeading.resetButton then page.rosterDisplayHeading.resetButton[method](page.rosterDisplayHeading.resetButton); page.rosterColorHeading.resetButton[method](page.rosterColorHeading.resetButton) end
    page.rosterDisplayHeading[method](page.rosterDisplayHeading); page.rosterColorHeading[method](page.rosterColorHeading)
    page.rosterLightnessLabel[method](page.rosterLightnessLabel); page.rosterLightnessField[method](page.rosterLightnessField)
    for index = 1, table.getn(page.rosterColors) do page.rosterColors[index][method](page.rosterColors[index]) end
    local raidHeadingY = uiVisible and (state.layout and (colorY - 90 - colorHeight) or layoutY - 38) or -178 + topOffset
    PlaceSection(sections.raidHeading, page, raidHeadingY, 12)
    if sections.raidHeading.label then
        local open = FeatureOpen(page, "raid")
        sections.raidHeading.label:SetText((open and "-  " or "+  ") .. "Raid"); sections.raidHeading:SetExpanded(open)
    end
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
    view.viewport:SetPoint("TOPLEFT", anchor, "TOPLEFT", 4, -4)
    view.viewport:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -4, 4)
    view.viewport.mosScrollAnchor = anchor
    if view.scrollBar then
        view.scrollBar:ClearAllPoints()
        view.scrollBar:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -4, -20)
        view.scrollBar:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -4, 20)
    end
    view.viewport.settingsDetached = detached and true or false
    Settings.UpdateScroll(view.viewport, view.page, view.page.settingsContentHeight or 960)
end

function Settings.CreateDetachedWindow()
    return MOS.UI.Components.Window.Create({
        name = "MuklaOfficerSuiteSettingsWindow", title = "Settings", compact = true, plainHeader = true, minimizedWidth = 250, viewportWidthInset = 16, viewportHeightInset = 42,
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
