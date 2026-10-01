local ADDON_NAME = "MuklaOfficerSuite"
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version") or "0.5.0-dev.91"
local RELEASE_VERSION = GetAddOnMetadata(ADDON_NAME, "X-Release-Version") or "0.4.0"
local PREFIX = "|cff33ff99MOS|r"

local function Print(message)
    if MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.chatActionLogs then DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message)) end
end

local MOS = MuklaOfficerSuite
MOS.version = VERSION
-- Transient presentation modes never survive a UI reload. Their geometry is
-- stored separately and is restored only when the user enters the mode again.
MOS.lootMasterMode = false
MOS.lootMasterMinimized = false

local CompletePendingGuildScan
local HandleGuildScanFailure
local scanProgress
local raidScanProgress
local RefreshCurrentPageLayout
local ApplyNavigationLayout
local RefreshRosterPage
local RefreshStatisticsPage
local RefreshRaidPage
local RequestGuildAction
local RequestRosterScan
local StartSharedGuildScan
local ToggleLootMasterMode
local ToggleLootMasterMinimize
local ToggleSidebar
local UIState = {}
local function SetStatus(message, kind)
    MOS.UI.Components.Dashboard.SetStatus(UIState.statusBar, message, kind)
end

MOS.Core.Dialogs.RegisterPersistencePrompts(Print)

local EnsureDatabase = MOS.Database.Ensure
local GuildKey = MOS.Database.GetGuildIdentity
local CountSavedMembers = MOS.Database.CountRosterMembers

local function SaveGuildRoster()
    local snapshot, failure = MOS.Services.Roster.BuildSnapshot(MOS.Core.GuildScanController.GetStartedAt(MOS.guildScanController))
    if failure == "not-in-guild" then
        Print("This character is not in a guild.")
        return false
    end
    if not snapshot then return false end
    MOS.Services.Roster.StoreSnapshot(snapshot)
    MOS.Core.GuildScanController.Finish(MOS.guildScanController)
    MOS.UI.Components.ProgressBar.Complete(scanProgress)
    SetStatus("Guild roster updated", "success")
    return true
end

SaveGuildRoster = MOS.Diagnostics.Wrap("Guild roster scan", SaveGuildRoster)

local SaveRaidRoster = MOS.Diagnostics.Wrap("Raid roster scan", MOS.Services.Raid.SaveRoster)
local RecordRaidLoot = MOS.Diagnostics.Wrap("Loot message", MOS.Services.Raid.RecordLoot)

MOS.Database.Ensure()
MOS.UI.Components.SetSkinPersistence(function(value) MOS.Database.SetSetting("uiSkin", value) end)
MOS.UI.Components.SetSkin(MOS.Database.GetSetting("uiSkin"), false)
local dashboardView = MOS.UI.Components.Dashboard.CreateWindow(VERSION)
MOS.UI.Components.KeepTooltipAboveWindows(ItemRefTooltip)
local dashboard = dashboardView.frame
local titleBar, closeButton, sidebarToggleButton = dashboardView.titleBar, dashboardView.closeButton, dashboardView.sidebarToggle
local versionText, sidebar, contentPanel = dashboardView.versionText, dashboardView.sidebar, dashboardView.contentPanel
local contentShade = dashboardView.contentShade
local function SaveDashboardGeometry()
    if not MuklaOfficerSuiteDB or MOS.lootMasterMode or dashboardView.minimized then return end
    MuklaOfficerSuiteDB.windowWidth = dashboard:GetWidth(); MuklaOfficerSuiteDB.windowHeight = dashboard:GetHeight()
    local left, bottom = dashboard:GetLeft(), dashboard:GetBottom()
    if left and bottom then MuklaOfficerSuiteDB.windowLeft = left; MuklaOfficerSuiteDB.windowBottom = bottom end
end
sidebarToggleButton:SetScript("OnClick", function() if ToggleSidebar then ToggleSidebar() end end)

UIState.statusBar = MOS.UI.Components.Dashboard.CreateStatusBar(dashboard)
SetStatus("Ready")
local navigation
MOS.UI.Components.Dashboard.BindWindow(dashboardView, {
    statusBar = UIState.statusBar,
    saveGeometry = SaveDashboardGeometry,
    saveLootGeometry = function()
        if MuklaOfficerSuiteDB then
            MuklaOfficerSuiteDB.lootMasterWidth = dashboard:GetWidth()
            MuklaOfficerSuiteDB.lootMasterHeight = dashboard:GetHeight()
            local left, bottom = dashboard:GetLeft(), dashboard:GetBottom()
            if left and bottom then MuklaOfficerSuiteDB.lootMasterLeft = left; MuklaOfficerSuiteDB.lootMasterBottom = bottom end
        end
    end,
    isLootMasterMode = function() return MOS.lootMasterMode end,
    isTabLayout = function() return MuklaOfficerSuiteDB and (MuklaOfficerSuiteDB.menuStyle == "tabs" or MuklaOfficerSuiteDB.menuStyle == "bottomTabs") end,
    applyLayout = function() if ApplyNavigationLayout then ApplyNavigationLayout() end end,
    refreshLayout = function() if RefreshCurrentPageLayout then RefreshCurrentPageLayout() end end,
    applyOrRefreshLayout = function()
        if ApplyNavigationLayout then ApplyNavigationLayout() elseif RefreshCurrentPageLayout then RefreshCurrentPageLayout() end
    end,
    setNavigationVisible = function(visible)
        if not navigation then return end
        local _, button
        for _, button in pairs(navigation.buttons) do if visible then button:Show() else button:Hide() end end
    end,
})

local dashboardPages = MOS.UI.Components.Dashboard.CreatePages(contentPanel, {
    { key = "roster" },
    { key = "statistics", anchor = "roster", hidden = true },
    { key = "raidStatistics", anchor = "roster", hidden = true },
    { key = "csr", anchor = "roster", hidden = true },
    -- Raid stays anchored to content when Loot Master moves the roster page.
    { key = "raid", hidden = true },
    { key = "about", anchor = "roster", hidden = true },
})
local rosterPage, statisticsPage, raidPage = dashboardPages.roster, dashboardPages.statistics, dashboardPages.raid
local aboutPage = dashboardPages.about

local detachedSettingsWindow = MOS.Modules.Settings.CreateDetachedWindow()
local settingsView = MOS.Modules.Settings.CreateShell(detachedSettingsWindow.content, detachedSettingsWindow.content, function()
    if ApplyNavigationLayout then ApplyNavigationLayout() end
end, {
    profileLoaded = function()
        if rosterPage.dataController then
            if rosterPage:IsVisible() then MOS.Modules.RosterManagement.ActivateDataController(rosterPage.dataController, false)
            else MOS.Modules.RosterManagement.DeactivateDataController(rosterPage.dataController) end
        end
        if raidPage.lifecycle and raidPage.lifecycle.SyncTrackingSetting then raidPage.lifecycle:SyncTrackingSetting() end
        if RefreshRosterPage and rosterPage:IsVisible() then RefreshRosterPage() end
        if RefreshRaidPage and raidPage:IsVisible() then RefreshRaidPage() end
    end,
    minimapVisibilityChanged = function()
        if not MOS.minimapButton then return end
        MuklaOfficerSuiteDB.minimap.hidden = MuklaOfficerSuiteDB.hideMinimapIcon
        if MuklaOfficerSuiteDB.hideMinimapIcon then MOS.minimapButton:Hide() else MOS.minimapButton:Show() end
    end,
})
local configurationViewport = settingsView.viewport
local configurationPage = settingsView.page
MOS.Modules.Settings.CreateRaidSettings(configurationPage, {
    refreshGroup = function() if MOS.RefreshRaidGroupView then MOS.RefreshRaidGroupView() end end,
    refreshList = function() if RefreshRaidPage then RefreshRaidPage() end end,
    trackingChanged = function()
        if raidPage.lifecycle and raidPage.lifecycle.SyncTrackingSetting then raidPage.lifecycle:SyncTrackingSetting() end
    end,
})
detachedSettingsWindow.AttachView(settingsView)
dashboardView.settingsButton:SetScript("OnClick", function() detachedSettingsWindow.Toggle() end)

local performanceModule = MOS.Modules.Performance.Create(contentPanel.mosPageHost or contentPanel)

scanProgress = MOS.UI.Components.ProgressBar.Create(UIState.statusBar, 280, 16)
scanProgress:SetPoint("LEFT", UIState.statusBar, "LEFT", 4, 0)
scanProgress:SetFrameLevel(UIState.statusBar:GetFrameLevel() + 2)
raidScanProgress = MOS.UI.Components.ProgressBar.Create(raidPage, 320, 18)
raidScanProgress:SetPoint("CENTER", raidPage, "CENTER", 0, 0)
raidScanProgress:SetFrameLevel(raidPage:GetFrameLevel() + 20)

local rosterView = MOS.Modules.RosterManagement.CreateShell(rosterPage, contentPanel)
local searchBox = rosterView.searchBox
local rosterStatusText, rosterLastScan = rosterView.status, rosterView.lastScan

local rosterGuildControls = MOS.Modules.RosterManagement.CreateGuildControls(rosterPage)
local rosterScanButton, rosterRefreshButton = rosterGuildControls.scanButton, rosterGuildControls.refreshButton
local scanSaveButton = rosterGuildControls.exportButton

local rosterFilterView = MOS.Modules.RosterManagement.CreateFilterView(rosterPage)
local rosterSortHint = rosterFilterView.sortHint

local rowHeight = 20
local visibleMembers = {}
local sortKey = "rank"
local sortAscending = true
local selectedMemberName = nil
local selectedClasses = {}
local selectedRanks = {}
local menuButtons = {}
local currentPage = "roster"

local rosterListController = MOS.Modules.RosterManagement.MountList(rosterPage, rosterFilterView, {
    selectedClasses = selectedClasses,
    selectedRanks = selectedRanks,
    getUniqueValues = MOS.Services.Roster.GetUniqueMemberValues,
    refreshFilters = function() RefreshRosterPage(false) end,
    rowHeight = rowHeight,
    onSort = function(key)
        if sortKey ~= key then sortKey = key; sortAscending = true
        elseif sortAscending then sortAscending = false
        else sortKey = nil; sortAscending = true end
        MuklaOfficerSuiteDB.rosterSortKey = sortKey or "none"
        MuklaOfficerSuiteDB.rosterSortAscending = sortAscending
        RefreshRosterPage(true)
    end,
    onAction = function(action, member) RequestGuildAction(action, member) end,
    onSelect = function(member)
        if selectedMemberName == member.name then selectedMemberName = nil else selectedMemberName = member.name end
        RefreshRosterPage(false)
    end,
    isSelected = function(member) return selectedMemberName == member.name end,
})
local rows = rosterListController.rows
local rosterScrollFrame = rosterListController.scrollFrame

local statisticsView = MOS.Modules.GuildStatistics.CreateView(statisticsPage, MOS.UI.Components.StyleButton, function() RefreshStatisticsPage() end)
MOS.Modules.GuildStatistics.AttachExport(statisticsView, scanSaveButton)
dashboardPages.raidStatistics.module = MOS.Modules.RaidStatistics.Create(dashboardPages.raidStatistics, MOS.Database.GetRaidStatistics, MOS.Database.DeleteRaidStatistic, MOS.Database.UpdateRaidStatistic)
dashboardPages.csr.module = MOS.Modules.CSR.Create(dashboardPages.csr, MOS.Database.GetRaidStatistics, MOS.Database.GetLootRules, MOS.Database.GetRosterData, function(raidId)
    if MOS.OpenRaidStatistics then MOS.OpenRaidStatistics(raidId) end
end)

local raidChrome = MOS.Modules.RaidManagement.CreateChrome(raidPage, {
    toggleLootMaster = function() ToggleLootMasterMode() end,
    toggleMinimize = function() ToggleLootMasterMinimize() end,
})
local raidTitle = raidChrome.title
local raidModeButton = raidChrome.modeButton
local raidSearchBox = raidChrome.searchBox
local selectedRaidClasses, selectedRaidRanks = {}, {}
local raidSortKey, raidSortAscending = nil, true
local visibleRaidMembers = {}
local selectedRaidMemberName = nil
local raidHistoricalLoaded = false
local raidActions = MOS.Modules.RaidManagement.CreateActionControls(raidPage)

local function IsTestRaid() return MOS.Services.TestRaid.IsActive() end
local function GetRaidAttendance() return IsTestRaid() and MOS.Services.TestRaid.GetAttendance() or MOS.Database.GetRaidAttendance() end
local function IsActiveRaid() return IsTestRaid() or MOS.Services.Raid.IsInRaid() end
local function SaveActiveRaidRoster()
    if IsTestRaid() then return MOS.Services.TestRaid.GetRaidMemberCount() end
    local previousAttendance = MOS.Database.GetRaidAttendance()
    local count = SaveRaidRoster()
    local attendance = MOS.Database.GetRaidAttendance()
    MOS.Services.RaidRes.Reconcile(previousAttendance, attendance)
    if attendance and MOS.raidSessionDraft then attendance._sessionDraft = true end
    return count
end
local function RunActiveRaidAction(member, action) return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).RunMemberAction(member, action) end
local function GetActiveGroupCounts() return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).GetGroupCounts() end
local function MoveActiveMember(member, group) return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).MoveMemberToGroup(member, group) end
local function MoveActiveMemberToSlot(member, target, group) return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).MoveMemberToSlot(member, target, group) end
local function GetActiveLootMasterInfo() return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).GetLootMasterInfo() end
local function GetActiveRaidMemberCount() return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).GetRaidMemberCount() end
local function GetActiveRaidMemberInfo(index) return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).GetRaidMemberInfo(index) end
local function IsActivePlayerIgnored(name) return (IsTestRaid() and MOS.Services.TestRaid or MOS.Services.Raid).IsPlayerIgnored(name) end

configurationPage.raidAccordionControls.opacityLabel, configurationPage.raidAccordionControls.opacityField = MOS.Modules.Settings.CreatePercentageField(configurationPage, "MuklaOfficerSuiteLmOpacity", "LM Opacity %", 40, -612, "lootMasterOpacity", 100)
configurationPage.raidAccordionControls.focusLabel, configurationPage.raidAccordionControls.focusField = MOS.Modules.Settings.CreatePercentageField(configurationPage, "MuklaOfficerSuiteFocusOpacity", "Out of Focus Opacity %", 210, -612, "outOfFocusOpacity", 30)
if configurationPage.ApplyRaidLayoutAccordion then configurationPage.ApplyRaidLayoutAccordion() end

local raidListView = MOS.Modules.RaidManagement.MountList(raidPage, raidChrome, {
    selectedClasses = selectedRaidClasses,
    selectedRanks = selectedRaidRanks,
    getData = GetRaidAttendance,
    getFilterValues = MOS.Services.Raid.GetFilterValues,
    runMemberAction = RunActiveRaidAction,
    isSelected = function(member) return selectedRaidMemberName == member.name end,
    refresh = function() RefreshRaidPage() end,
    onReset = function()
        raidSortKey = nil; raidSortAscending = true; selectedRaidMemberName = nil
        RefreshRaidPage()
    end,
    onSort = function(key, defaultAscending)
        if raidSortKey ~= key then raidSortKey = key; raidSortAscending = defaultAscending
        elseif raidSortAscending then raidSortAscending = false
        else raidSortKey = nil; raidSortAscending = true end
        RefreshRaidPage()
    end,
    onSelect = function(row)
        if selectedRaidMemberName == row.displayedMember.name then
            selectedRaidMemberName = nil
        else
            selectedRaidMemberName = row.displayedMember.name
        end
        RefreshRaidPage()
    end,
    applySoftReserveAssignments = MOS.Services.RaidRes.ApplyAssignments,
    clearUnmatchedSoftReserves = MOS.Services.RaidRes.ClearUnmatched,
    removeSoftReserve = function(memberName) return MOS.Services.RaidRes.RemoveMemberReservation(GetRaidAttendance(), memberName) end,
    rowCount = 25,
})
local raidRows, raidScrollFrame = raidListView.rows, raidListView.scrollFrame
MOS.Modules.RaidManagement.MountGroupView(raidPage, {
    getGroupCounts = GetActiveGroupCounts,
    moveMemberToGroup = MoveActiveMember,
    moveMemberToSlot = MoveActiveMemberToSlot,
    isTestRaid = IsTestRaid,
    isPlayerIgnored = IsActivePlayerIgnored,
    runMemberAction = RunActiveRaidAction,
    ensureDatabase = EnsureDatabase,
    getLootMasterInfo = GetActiveLootMasterInfo,
    getRaidMemberCount = GetActiveRaidMemberCount,
    getRaidMemberInfo = GetActiveRaidMemberInfo,
    refresh = function() RefreshRaidPage() end,
    onViewChanged = function()
        selectedRaidMemberName = nil
        RefreshRaidPage()
    end,
})
MOS.OpenRaidGroupSelector = raidPage.openGroupSelector
MOS.UpdateRaidDragGhost = raidPage.updateDragGhost
MOS.ShowRaidMemberMenu = raidPage.showMemberMenu
MOS.RefreshRaidGroupView = raidPage.refreshGroupView

MOS.Modules.RaidManagement.MountChrome(raidPage, raidChrome, raidActions)
MOS.Modules.RaidManagement.SetListRenderer(raidPage, {
    updateScrollFrame = MOS.UI.Components.UpdateScrollFrame,
    getLootMasterInfo = GetActiveLootMasterInfo,
    getData = GetRaidAttendance,
    shorten = MOS.UI.Components.ShortenText,
    sortMembers = function(a, b)
        return MOS.Modules.RaidManagement.CompareMembers(a, b, raidSortKey, raidSortAscending)
    end,
    onSelectionMissing = function()
        selectedRaidMemberName = nil
    end,
})
local raidRenderer = MOS.Modules.RaidManagement.CreateRenderer({
    page = raidPage,
    isTestRaid = IsTestRaid,
    rows = raidRows,
    unavailable = raidChrome.unavailable,
    searchBox = raidSearchBox,
    visibleMembers = visibleRaidMembers,
    selectedClasses = selectedRaidClasses,
    selectedRanks = selectedRaidRanks,
    countRefresh = function() MOS.Diagnostics.Count("uiRefreshes") end,
    isLootMasterMode = function() return MOS.lootMasterMode end,
    isLootMasterMinimized = function() return MOS.lootMasterMinimized end,
    isInRaid = IsActiveRaid,
    isHistoricalLoaded = function() return raidHistoricalLoaded end,
    isScanReady = function() return MOS.raidScanReady end,
    setScanReady = function(value) MOS.raidScanReady = value end,
    getData = GetRaidAttendance,
    getSelectedName = function() return selectedRaidMemberName end,
    getSortKey = function() return raidSortKey end,
    getSettings = function() return MuklaOfficerSuiteDB end,
})
local function GetCurrentGuildData()
    EnsureDatabase()
    local key, guildName = GuildKey()
    if not MuklaOfficerSuiteDB.rosterData and key and type(MuklaOfficerSuiteDB.guilds) == "table" then
        MuklaOfficerSuiteDB.rosterData = MuklaOfficerSuiteDB.guilds[key]
    end
    MuklaOfficerSuiteDB.guilds = nil
    return MuklaOfficerSuiteDB.rosterData, guildName
end

local function SortMembers(a, b)
    return MOS.Modules.RosterManagement.CompareMembers(a, b, sortKey, sortAscending)
end

MOS.Modules.RosterManagement.BuildLayoutControls(rosterPage, rosterView, rosterFilterView, rosterGuildControls)

MOS.Modules.RosterManagement.MountControllers(rosterPage, {
    guildControls = rosterGuildControls,
    contentPanel = contentPanel,
    contentShade = contentShade,
    sortHint = rosterSortHint,
    startSharedScan = function(origin) StartSharedGuildScan(origin) end,
    requestScan = function(mode) return RequestRosterScan(mode) end,
    printMessage = Print,
    buildSnapshot = MOS.Services.Roster.BuildSnapshot,
    storeSnapshot = MOS.Services.Roster.StoreSnapshot,
    refresh = function(resetScroll) RefreshRosterPage(resetScroll) end,
})

local rosterRenderer = MOS.Modules.RosterManagement.CreateRenderer({
    page = rosterPage,
    scanButton = rosterScanButton,
    statusText = rosterStatusText,
    summaryText = rosterLastScan,
    searchBox = searchBox,
    visibleMembers = visibleMembers,
    selectedClasses = selectedClasses,
    selectedRanks = selectedRanks,
    sortMembers = SortMembers,
    getLowestRankIndex = MOS.Services.Roster.GetLowestRankIndex,
    getMotd = function() return type(GetGuildRosterMOTD) == "function" and GetGuildRosterMOTD() or "Guild Message of the Day" end,
})

RefreshRosterPage = function(resetScroll)
    MOS.Diagnostics.Count("uiRefreshes")
    local data, guildName = GetCurrentGuildData()
    if not rosterPage.sortLoaded then
        sortKey = MuklaOfficerSuiteDB.rosterSortKey or "rank"
        if sortKey == "none" then sortKey = nil end
        sortAscending = MuklaOfficerSuiteDB.rosterSortAscending ~= false
        rosterPage.sortLoaded = true
    end
    MOS.Modules.RosterManagement.RefreshView(rosterRenderer, data, guildName, resetScroll, sortKey, selectedMemberName)
end

MOS.Modules.GuildStatistics.CreateController({
    page = statisticsPage,
    view = statisticsView,
    getData = GetCurrentGuildData,
    startScan = function(origin) StartSharedGuildScan(origin) end,
})

RefreshStatisticsPage = function()
    MOS.Modules.GuildStatistics.Refresh(statisticsPage.statisticsController)
end

RefreshRaidPage = function()
    if raidPage:IsVisible() then MOS.Modules.RaidManagement.RefreshPage(raidRenderer) end
    if raidPage.lootMasterController then raidPage.lootMasterController.Refresh() end
end

RefreshRosterPage = MOS.Diagnostics.Wrap("Roster refresh", RefreshRosterPage)
RefreshStatisticsPage = MOS.Diagnostics.Wrap("Statistics refresh", RefreshStatisticsPage)
RefreshRaidPage = MOS.Diagnostics.Wrap("Raid refresh", RefreshRaidPage)

local function ShowPage(pageName)
    currentPage = pageName
    MOS.ModuleRegistry.Show(pageName)
    if navigation then navigation.SetActive(pageName) else MOS.Modules.Navigation.SetActive(menuButtons, pageName) end
end

MOS.OpenRaidStatistics = function(raidId)
    ShowPage("raidStatistics")
    if dashboardPages.raidStatistics.module.SelectRaid then dashboardPages.raidStatistics.module:SelectRaid(raidId) end
end

RefreshCurrentPageLayout = function()
    MOS.ModuleRegistry.Resize(currentPage)
end

MOS.ModuleRegistry.Register("roster", MOS.Modules.RosterManagement.CreateLifecycle(rosterPage, rosterPage.dataController, RefreshRosterPage))
MOS.ModuleRegistry.Register("statistics", MOS.Modules.GuildStatistics.CreateLifecycle(statisticsPage.statisticsController))
MOS.ModuleRegistry.Register("raidStatistics", dashboardPages.raidStatistics.module)
MOS.ModuleRegistry.Register("csr", dashboardPages.csr.module)
MOS.ModuleRegistry.Register("raid", MOS.Modules.RaidManagement.CreateLifecycle({
    page = raidPage,
    isInRaid = IsActiveRaid,
    getTrackingEnabled = function() return MuklaOfficerSuiteDB.raidLiveTrackingEnabled and not MOS.raidSessionPaused end,
    getScanReady = function() return MOS.raidScanReady end,
    isHistoricalLoaded = function() return raidHistoricalLoaded end,
    isPresentationActive = function()
        return (raidPage:IsVisible() and not dashboardView.minimized) or (raidPage.lootMasterController and raidPage.lootMasterController.IsVisible())
    end,
    isDetachedActive = function() return raidPage.lootMasterController and raidPage.lootMasterController.IsVisible() end,
    saveRaidRoster = SaveActiveRaidRoster,
    setLiveTracking = function(value) MOS.raidLiveTracking = value end,
    setScanReady = function(value) MOS.raidScanReady = value end,
    refresh = function() RefreshRaidPage() end,
    onWorldContextChanged = function()
        MOS.Modules.RaidManagement.HandleWorldContext({
            getAttendance = MOS.Database.GetRaidAttendance,
            getZone = function() return GetRealZoneText() or "" end,
            getInstanceState = IsInInstance,
            hasSession = MOS.Services.RaidRes.HasSession,
            isSessionDraft = function() return MOS.raidSessionDraft end,
            isTestRaid = IsTestRaid,
            isInRaid = MOS.Services.Raid.IsInRaid,
            getReminderContext = function() return MOS.raidStartReminderContext end,
            setReminderContext = function(value) MOS.raidStartReminderContext = value end,
            getReminderShownContext = function() return MOS.raidStartReminderShownContext end,
            setReminderShownContext = function(value) MOS.raidStartReminderShownContext = value end,
            getContinuedContext = function() return MOS.raidSessionContinuedContext end,
            setContinuedContext = function(value) MOS.raidSessionContinuedContext = value end,
            showRaidStartReminder = function(value) if raidPage.ShowRaidStartReminder then raidPage.ShowRaidStartReminder(value) end end,
            hideRaidStartReminder = function() if raidPage.HideRaidStartReminder then raidPage.HideRaidStartReminder() end end,
            showSessionTransitionPrompt = function(value) if raidPage.ShowSessionTransitionPrompt then raidPage.ShowSessionTransitionPrompt(value) end end,
            hideSessionTransitionPrompt = function() if raidPage.HideSessionTransitionPrompt then raidPage.HideSessionTransitionPrompt() end end,
        })
    end,
}))
local aboutModule
aboutModule = MOS.Modules.About.Create(aboutPage, VERSION, {
    checkVersion = function() if MOS.versionCheck then MOS.versionCheck.CheckNow() end end,
    getVersionStatus = function() return MOS.versionCheck and MOS.versionCheck.GetStatus() or "Failed to check for update. Check GitHub for latest version." end,
    getLastSuccessfulCheck = function() return MOS.versionCheck and MOS.versionCheck.GetLastSuccessfulCheck() end,
})
MOS.ModuleRegistry.Register("about", aboutModule)
MOS.ModuleRegistry.Register("configuration", MOS.Modules.Settings.CreateLifecycle({
    viewport = configurationViewport,
    page = configurationPage,
    chatLogsCheck = configurationPage.chatLogsCheck,
    opacityField = configurationPage.raidAccordionControls.opacityField,
    focusField = configurationPage.raidAccordionControls.focusField,
    bottomPadding = 960,
}))
MOS.ModuleRegistry.Register("performance", performanceModule)

navigation = MOS.Modules.Navigation.Create({
    applyChrome = function() if not MOS.lootMasterMode then MOS.UI.Components.Dashboard.ApplyChrome(dashboardView, MOS.Database.GetSetting) end end,
    dashboard = dashboard,
    sidebar = sidebar,
    toggleButton = sidebarToggleButton,
    toggleButtonClassicIcon = dashboardView.sidebarToggleClassicIcon,
    contentPanel = contentPanel,
    showPage = ShowPage,
    refreshLayout = function() if RefreshCurrentPageLayout then RefreshCurrentPageLayout() end end,
})
menuButtons = navigation.buttons
ToggleSidebar = function(forceState) navigation.Toggle(forceState) end
ApplyNavigationLayout = function() navigation.Apply() end

MOS.Modules.RaidManagement.CreateLootMasterController({
    page = raidPage,
    dashboard = dashboard,
    sidebar = sidebar,
    titleBar = titleBar,
    closeButton = closeButton,
    versionText = versionText,
    statusBar = UIState.statusBar,
    raidTitle = raidTitle,
    contentPanel = contentPanel,
    rosterPage = rosterPage,
    modeButton = raidModeButton,
    getSettings = function() return MuklaOfficerSuiteDB end,
    saveDashboardGeometry = SaveDashboardGeometry,
    applyNavigationLayout = ApplyNavigationLayout,
    refresh = function() RefreshRaidPage() end,
})
ToggleLootMasterMode = raidPage.lootMasterController.toggle
ToggleLootMasterMinimize = raidPage.lootMasterController.toggleMinimize

MOS.Core.GuildScanController.Create({
    isInGuild = IsInGuild,
    requestRoster = GuildRoster,
    printMessage = Print,
    tryComplete = function() return CompletePendingGuildScan and CompletePendingGuildScan() end,
    onStart = function(scanMode, controller)
        if scanMode == "raid" then controller.progressLabel = "Scanning raid"
        elseif scanMode == "reload" then controller.progressLabel = "Preparing roster export"
        elseif scanMode == "quiet" then controller.progressLabel = "Refreshing guild data"
        else controller.progressLabel = "Scanning guild data" end
        if scanMode == "raid" then
            MOS.UI.Components.ProgressBar.Stop(scanProgress)
            MOS.Modules.RaidManagement.ShowScanningState(raidPage, raidRows)
            MOS.UI.Components.ProgressBar.Start(raidScanProgress, controller.progressLabel, controller.startedAt, 7, 94)
        else
            MOS.UI.Components.ProgressBar.Stop(raidScanProgress)
            MOS.UI.Components.ProgressBar.Start(scanProgress, controller.progressLabel, controller.startedAt, 7, 94)
        end
        SetStatus(controller.progressLabel)
    end,
    onFailure = function()
        MOS.UI.Components.ProgressBar.Stop(scanProgress)
        MOS.UI.Components.ProgressBar.Stop(raidScanProgress)
        SetStatus("Guild roster scan failed", "error")
        Print("Guild roster could not be loaded after 15 seconds. Please try again.")
        if HandleGuildScanFailure then HandleGuildScanFailure() end
    end,
})

RequestRosterScan = function(scanMode)
    EnsureDatabase()
    return MOS.Core.GuildScanController.Request(MOS.guildScanController, scanMode)
end

StartSharedGuildScan = function(origin)
    EnsureDatabase()
    if not MOS.Core.GuildScanController.RequestShared(MOS.guildScanController, origin) then return false end
    if origin == "statistics" then
        MOS.Modules.GuildStatistics.BeginScan(statisticsPage.statisticsController)
    else
        rosterScanButton:Hide()
        MOS.Modules.RosterManagement.SetRefreshPending(rosterPage.dataController, true)
        rosterStatusText:SetText("Scanning guild data...")
    end
    return true
end

local function QueueRosterRefresh()
    MOS.Core.GuildScanController.Queue(MOS.guildScanController)
end

MOS.Modules.RaidManagement.RegisterResetLootDialog({
    getAttendance = GetRaidAttendance,
    clearSelection = function() selectedRaidMemberName = nil end,
    refresh = RefreshRaidPage,
    printMessage = Print,
})

RequestGuildAction = MOS.Modules.RosterManagement.CreateGuildActionHandler({
    getData = GetCurrentGuildData,
    getSelectedName = function() return selectedMemberName end,
    findMember = MOS.Services.Roster.FindMember,
    findRankName = MOS.Services.Roster.FindRankName,
    queueRefresh = QueueRosterRefresh,
    printMessage = Print,
})

MOS.CompleteRaidSession = function(saveOptions)
    if type(saveOptions) ~= "table" then
        local enabled = saveOptions and true or false
        saveOptions = { saveRaidStatistics = enabled, saveAttendance = enabled, saveCSR = enabled }
    end
    if IsTestRaid() then
        MOS.Services.TestRaid.Stop()
    else
        local attendance = MOS.Database.GetRaidAttendance()
        if attendance then
            local savedAt = time()
            local requestedRaidId=string.gsub(tostring(saveOptions.raidId or attendance.snapshotId or ""),"^%s+","");requestedRaidId=string.gsub(requestedRaidId,"%s+$","")
            if requestedRaidId=="" or MOS.Database.HasSoftReserveSnapshot(requestedRaidId) or MOS.Database.HasRaidStatistic(requestedRaidId) then return false end
            attendance.snapshotId=requestedRaidId;attendance._loadedSnapshotId=nil
            attendance.lastSavedAt = savedAt; attendance._sessionDraft = nil
            MOS.Services.RaidRes.SyncHistory(attendance)
            if saveOptions.saveRaidStatistics or saveOptions.saveCSR then
                local entry = MOS.Services.RaidStatistics.BuildEntry(attendance, saveOptions)
                if entry then MOS.Database.StoreRaidStatistic(entry) end
            end
        end
        -- The durable snapshot/statistics entry is complete. Do not leave the
        -- same attendance object as the active session or VARIABLES_LOADED will
        -- restore the raid immediately after the requested reload.
        MOS.Database.StoreRaidAttendance(nil)
    end
    MOS.raidSessionDraft = false; MOS.raidSessionPaused = true; MOS.raidLiveTracking = false
    MOS.raidScanReady = false; MOS.raidSessionContinuedContext = nil
    raidHistoricalLoaded = false; selectedRaidMemberName = nil
    MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_ATTENDANCE_RELOAD")
    return true
end

MOS.Modules.RaidManagement.AttachActionHandlers({
    page = raidPage,
    isTestRaid = IsTestRaid,
    importData = function(value, srUrl) return MOS.Services.RaidRes.Import(value, GetRaidAttendance(), srUrl) end,
    getSrUrl = function() return MOS.Services.RaidRes.GetUrl(GetRaidAttendance()) end,
    getRollForExport = function() return MOS.Services.RaidRes.GetRollForExport(GetRaidAttendance()) end,
    setSrUrl = function(value) return MOS.Services.RaidRes.SetUrl(GetRaidAttendance(), value) end,
    shareSrUrl = function(value) return MOS.Services.Raid.SendRaidWarning("Please put your SR: " .. tostring(value or "")) end,
    shareMissingSrNames = MOS.Services.Raid.SendRaidWarningList,
    getAttendance = GetRaidAttendance,
    getRaidHistory = MOS.Database.GetSoftReserveHistory,
    raidIdExists = function(raidId) return MOS.Database.HasSoftReserveSnapshot(raidId) or MOS.Database.HasRaidStatistic(raidId) end,
    deleteRaidSnapshot = MOS.Database.DeleteSoftReserveSnapshot,
    loadRaidSnapshot = function(snapshotId)
        local snapshots = MOS.Database.GetSoftReserveHistory()
        local index
        for index = 1, table.getn(snapshots) do
            if snapshots[index].id == snapshotId then
                local attendance = MOS.Services.RaidRes.RestoreSnapshot(snapshots[index])
                MOS.Services.RaidRes.Reconcile(attendance, attendance)
                return attendance
            end
        end
        return nil
    end,
    setHistoricalLoaded = function(value) raidHistoricalLoaded = value and true or false end,
    getRules = function()
        local rules = MOS.Database.GetLootRules()
        return IsTestRaid() and MOS.Services.TestRaid.GetLootRules(rules) or rules
    end,
    saveRules = function(rules)
        if IsTestRaid() then MOS.Services.TestRaid.SaveLootRules(rules) else MOS.Database.SaveLootRules(rules) end
    end,
    getHighlyContestedItems = function()
        local items = MOS.Database.GetHighlyContestedItems()
        return IsTestRaid() and MOS.Services.TestRaid.GetHighlyContestedItems(items) or items
    end,
    saveHighlyContestedItems = function(items)
        if IsTestRaid() then return MOS.Services.TestRaid.SaveHighlyContestedItems(items) end
        return MOS.Database.SaveHighlyContestedItems(items)
    end,
    isInRaid = IsActiveRaid,
    requestRosterScan = RequestRosterScan,
    saveRaidRoster = SaveActiveRaidRoster,
    beginRaidSession = function()
        MOS.raidSessionPaused = false; MOS.raidSessionDraft = true
        MOS.raidSessionContinuedContext = nil
        local attendance = GetRaidAttendance(); if attendance then attendance._sessionDraft = true end
    end,
    startNewRaid = function(raidId, raidName)
        MOS.pendingRaidSessionId = raidId
        MOS.pendingRaidName = raidName
        MOS.Database.StoreRaidAttendance(nil)
        raidHistoricalLoaded = false
        MOS.raidSessionPaused = false; MOS.raidSessionDraft = true
    end,
    saveRaidSession = function(saveOptions) return MOS.CompleteRaidSession(saveOptions) end,
    quitRaidSession = function()
        local wasTestRaid = IsTestRaid()
        MOS.Services.TestRaid.Stop()
        if not wasTestRaid then MOS.Database.StoreRaidAttendance(nil) end
        MOS.raidSessionPaused = true; MOS.raidSessionDraft = false; MOS.raidLiveTracking = false
        raidHistoricalLoaded = false; MOS.raidScanReady = false; selectedRaidMemberName = nil
        MOS.raidSessionContinuedContext = nil
    end,
    continueRaidSession = function(contextKey)
        MOS.raidSessionContinuedContext = contextKey
        MOS.raidSessionPaused = false
    end,
    dismissRaidStartReminder = function(contextKey) MOS.raidStartReminderContext = contextKey end,
    openRaidManagement = function()
        if not dashboard:IsVisible() then dashboard:Show() end
        ShowPage("raid")
    end,
    startTestRaid = function() MOS.Services.TestRaid.Start(); MOS.raidLiveTracking = false; selectedRaidMemberName = nil end,
    refresh = function() RefreshRaidPage() end,
    printMessage = Print,
    showPopup = MOS.UI.Components.ShowOpaquePopup,
    getLiveTracking = function() return MOS.raidLiveTracking end,
    setLiveTracking = function(value) MOS.raidLiveTracking = value end,
    setScanReady = function(value) MOS.raidScanReady = value end,
})

MOS.Modules.RaidManagement.AttachResizeHandler(raidPage, RefreshRaidPage)
MOS.Modules.RaidManagement.AttachListScroll(raidPage, RefreshRaidPage)

MOS.Modules.RosterManagement.AttachInteractions({
    page = rosterPage,
    exportButton = scanSaveButton,
    searchBox = searchBox,
    listController = rosterListController,
    contentPanel = contentPanel,
    contentShade = contentShade,
    ensureDatabase = EnsureDatabase,
    requestScan = RequestRosterScan,
    clearSelection = function() selectedMemberName = nil end,
    refresh = RefreshRosterPage,
})

dashboard:SetScript("OnShow", function() ShowPage(currentPage) end)
navigation.SetActive("roster")

local function ToggleDashboard()
    if dashboard:IsVisible() then
        dashboard:Hide()
    else
        -- Main-window chrome is independent of the detached Loot Master window.
        if not MOS.lootMasterMode and not dashboardView.minimized and raidPage.lootMasterController then
            raidPage.lootMasterController.resetOnLoad()
            ApplyNavigationLayout()
        end
        dashboard:Show()
    end
end

MOS.minimapButton = MOS.UI.Components.Dashboard.CreateMinimapButton({
    ensureDatabase = EnsureDatabase,
    getAngle = function() return MuklaOfficerSuiteDB.minimap.angle or 220 end,
    setAngle = function(value) MuklaOfficerSuiteDB.minimap.angle = value end,
    onClick = ToggleDashboard,
})
MOS.PositionMinimapButton = MOS.minimapButton.Position

MOS.versionCheck = MOS.Modules.VersionCheck.Create({
    releaseVersion = RELEASE_VERSION,
    addonVersion = VERSION,
    printMessage = Print,
    onStatusChanged = function(value, timestamp) aboutModule:SetUpdateStatus(value, timestamp) end,
})

MOS.Core.Commands.Attach({
    dashboard = dashboard,
    minimapButton = MOS.minimapButton,
    showPage = ShowPage,
    toggleDashboard = ToggleDashboard,
    printMessage = Print,
    countSavedMembers = CountSavedMembers,
    startLinkedItemRoll = function(itemLink)
        local window = MOS.Modules.MasterLootWindow
        if window and window.OpenLinkedItemRoll then window.OpenLinkedItemRoll(itemLink) end
    end,
    printLayoutDiagnostics = function()
        DEFAULT_CHAT_FRAME:AddMessage("MOS layout diagnostics: current=" .. tostring(currentPage) .. " raidVisible=" .. tostring(raidPage:IsVisible()))
        MOS.Modules.RaidManagement.PrintListLayoutDiagnostics(raidPage, visibleRaidMembers, selectedRaidMemberName)
        if currentPage == "raid" or raidPage:IsVisible() then return end
        DEFAULT_CHAT_FRAME:AddMessage(string.format("MOS roster: height=%.1f row=%d capacity=%d shown=%d filtered=%d offset=%d", rosterPage.measuredHeight or 0, rowHeight, rosterPage.measuredCapacity or 0, rosterPage.measuredShown or 0, rosterPage.measuredCount or 0, rosterPage.measuredOffset or 0))
        local lastRow = rows[rosterPage.measuredShown or 0]
        if lastRow and lastRow:GetBottom() and rosterLastScan:GetTop() then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("MOS geometry: viewport=%.1f gap=%.1f", rosterPage.tableViewport:GetHeight(), lastRow:GetBottom() - rosterLastScan:GetTop()))
        end
    end,
})

HandleGuildScanFailure = function()
    local origin = MOS.Core.GuildScanController.GetOrigin(MOS.guildScanController)
    if origin == "roster" then
        MOS.Modules.RosterManagement.SetRefreshPending(rosterPage.dataController, false)
        RefreshRosterPage(false)
    elseif origin == "statistics" then
        MOS.Modules.GuildStatistics.HandleScanFailure(statisticsPage.statisticsController)
    elseif currentPage == "raid" then
        RefreshRaidPage()
    end
    MOS.Core.GuildScanController.ClearOrigin(MOS.guildScanController)
end

CompletePendingGuildScan = function()
    if not MOS.Core.GuildScanController.IsPending(MOS.guildScanController) then return false end
    local scanMode = MOS.Core.GuildScanController.GetMode(MOS.guildScanController)
    if not SaveGuildRoster() then return false end
    MOS.Modules.RosterManagement.SetRefreshPending(rosterPage.dataController, false)

    RefreshRosterPage(scanMode ~= "quiet")
    if scanMode == "shared" then
        MOS.Modules.RosterManagement.SetReady(rosterPage.dataController, true)
        MOS.Modules.GuildStatistics.SetReady(statisticsPage.statisticsController, true)
        RefreshRosterPage(true)
        RefreshStatisticsPage()
        MOS.Core.GuildScanController.ClearOrigin(MOS.guildScanController)
        SetStatus("Guild data refreshed", "success")
        Print("Guild data loaded successfully. Members: " .. CountSavedMembers() .. ".")
    elseif scanMode == "raid" then
        MOS.UI.Components.ProgressBar.Complete(raidScanProgress)
        local raidCount = SaveRaidRoster()
        local attendance = MOS.Database.GetRaidAttendance()
        if attendance and MOS.pendingRaidSessionId then
            attendance.snapshotId = MOS.pendingRaidSessionId
            attendance.raidName = MOS.pendingRaidName or attendance.raidName
            attendance.sessionStartedAt = time()
            attendance.softReserveImport = { id = MOS.pendingRaidSessionId, origin = "mos", importedAt = time(), unmatchedNames = {}, unmatchedReservations = {}, missingNames = {} }
            attendance._sessionDraft = true
        end
        MOS.pendingRaidSessionId = nil
        MOS.pendingRaidName = nil
        MOS.raidScanReady = true
        MOS.raidLiveTracking = currentPage == "raid" and MuklaOfficerSuiteDB.raidLiveTrackingEnabled and true or false
        RefreshRaidPage()
        SetStatus("Raid roster updated", "success")
        Print("Raid scanned. Members: " .. raidCount)
    elseif scanMode == "reload" then
        Print("Roster scanned. Confirm the reload to save it to disk.")
        MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_RELOAD")
        SetStatus("Roster ready to export", "success")
    elseif scanMode ~= "quiet" then
        SetStatus("Guild roster updated", "success")
        Print("Roster scanned. Members: " .. CountSavedMembers())
    end
    return true
end

MOS.Core.EventDispatcher.Attach(MOS, {
    VARIABLES_LOADED = function()
        EnsureDatabase()
        local restoredAttendance = MOS.Database.GetRaidAttendance()
        local restoredImport = restoredAttendance and restoredAttendance.softReserveImport
        local restoredRaidId = restoredAttendance and (restoredAttendance.snapshotId or (restoredImport and restoredImport.id))
        local hasRestorableRaid = restoredRaidId and restoredAttendance.sessionStartedAt and type(restoredAttendance.members) == "table"
        MOS.raidScanReady = hasRestorableRaid and true or false
        MOS.raidSessionDraft = hasRestorableRaid and restoredAttendance._sessionDraft and true or false
        MOS.raidSessionPaused = false
        raidHistoricalLoaded = false
        if hasRestorableRaid then MOS.Services.RaidRes.Reconcile(restoredAttendance, restoredAttendance) end
        MOS.Modules.Settings.SyncSavedControls(configurationPage.chatLogsCheck, configurationPage.raidAccordionControls.opacityField, configurationPage.raidAccordionControls.focusField)
        MOS.UI.Components.Dashboard.RestoreGeometry(dashboard, MuklaOfficerSuiteDB)
        MuklaOfficerSuiteDB.uiScale = nil
        MOS.PositionMinimapButton()
        if MuklaOfficerSuiteDB.hideMinimapIcon then MOS.minimapButton:Hide() end
        MOS.sidebarCollapsed = MuklaOfficerSuiteDB.sidebarCollapsed and true or false
        raidPage.lootMasterController.resetOnLoad()
        ApplyNavigationLayout()
    end,
    GUILD_ROSTER_UPDATE = function()
        local completed = CompletePendingGuildScan()
        MOS.Modules.RosterManagement.HandleGuildRosterUpdate(rosterPage.dataController, completed, MOS.Core.GuildScanController.IsPending(MOS.guildScanController))
    end,
    RAID_ROSTER_UPDATE = function()
        raidPage.lifecycle:OnWorldContextChanged()
        if currentPage == "raid" or raidPage.lootMasterController.IsVisible() then
            raidPage.lifecycle:OnRosterUpdate()
        end
    end,
    PLAYER_ENTERING_WORLD = function() raidPage.lifecycle:OnWorldContextChanged() end,
    ZONE_CHANGED_NEW_AREA = function() raidPage.lifecycle:OnWorldContextChanged() end,
    CHAT_MSG_LOOT = function(message)
        local attendance = MOS.Database.GetRaidAttendance()
        local trackingLoot = MuklaOfficerSuiteDB.raidLiveTrackingEnabled and not MOS.raidSessionPaused
            and not IsTestRaid() and MOS.Services.Raid.IsInRaid() and MOS.Services.RaidRes.HasSession(attendance)
        if trackingLoot and RecordRaidLoot(message) and (raidPage:IsVisible() or raidPage.lootMasterController.IsVisible()) then RefreshRaidPage() end
    end,
})

if type(gcinfo) == "function" and MOS.Diagnostics.memoryBeforeLoad then
    MOS.Diagnostics.totalMemoryAfterLoad = gcinfo()
    MOS.Diagnostics.initialMemoryEstimate = math.max(0, MOS.Diagnostics.totalMemoryAfterLoad - MOS.Diagnostics.memoryBeforeLoad)
end
Print("v" .. VERSION .. " loaded. Type /mos")
