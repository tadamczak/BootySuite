local ADDON_NAME = "MuklaOfficerSuite"
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version") or "0.10.0"
local PREFIX = "|cff33ff99MOS|r"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message))
end

local MOS = CreateFrame("Frame", "MuklaOfficerSuiteEventFrame")
MOS.pendingScan = nil
MOS.lastRosterEvent = 0
MOS.scanStartedAt = nil
MOS.scanAttempts = 0

local rosterRequestFrame = CreateFrame("Frame", "MuklaOfficerSuiteRosterRequestFrame", UIParent)
rosterRequestFrame.delay = nil
rosterRequestFrame:Hide()
rosterRequestFrame:SetScript("OnUpdate", function()
    if not MOS.pendingScan then
        rosterRequestFrame.delay = nil
        rosterRequestFrame:Hide()
        return
    end

    rosterRequestFrame.delay = rosterRequestFrame.delay - arg1
    if rosterRequestFrame.delay > 0 then
        return
    end

    if MOS.scanAttempts < 3 then
        MOS.scanAttempts = MOS.scanAttempts + 1
        rosterRequestFrame.delay = 1
        Print("Guild roster is not ready. Retrying scan (" .. MOS.scanAttempts .. "/3)...")
        GuildRoster()
        return
    end

    rosterRequestFrame.delay = nil
    rosterRequestFrame:Hide()
    MOS.pendingScan = nil
    MOS.scanStartedAt = nil
    MOS.scanAttempts = 0
    Print("Guild roster could not be loaded. Please try again.")
end)

StaticPopupDialogs["MUKLA_OFFICER_SUITE_RELOAD"] = {
    text = "The guild roster scan is complete. Reload the UI now to write it to disk?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function()
        if type(ReloadUI) == "function" then
            ReloadUI()
        elseif type(ConsoleExec) == "function" then
            ConsoleExec("reloadui")
        end
    end,
    OnCancel = function()
        Print("Roster remains in memory. Use /reload before closing the game to save it.")
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["MUKLA_OFFICER_SUITE_CSR_RELOAD"] = {
    text = "The raid and guild data scan is complete. Reload the UI now to write the CSR snapshot to disk?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function()
        if type(ReloadUI) == "function" then ReloadUI() elseif type(ConsoleExec) == "function" then ConsoleExec("reloadui") end
    end,
    OnCancel = function() Print("CSR remains in memory. Use /reload before closing the game to save it.") end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["MUKLA_OFFICER_SUITE_ATTENDANCE_RELOAD"] = {
    text = "Attendance snapshot is ready. Reload the UI now to write it to disk?",
    button1 = "Reload now",
    button2 = "Later",
    OnAccept = function()
        if type(ReloadUI) == "function" then ReloadUI() elseif type(ConsoleExec) == "function" then ConsoleExec("reloadui") end
    end,
    OnCancel = function() Print("Attendance remains in memory. Use /reload before running Export-Attendance.ps1.") end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function EnsureDatabase()
    if type(MuklaOfficerSuiteDB) ~= "table" then
        MuklaOfficerSuiteDB = {}
    end
    if type(MuklaOfficerSuiteDB.guilds) ~= "table" then
        MuklaOfficerSuiteDB.guilds = {}
    end
    if type(MuklaOfficerSuiteDB.minimap) ~= "table" then
        MuklaOfficerSuiteDB.minimap = { angle = 220, hidden = false }
    end
    MuklaOfficerSuiteDB.addonVersion = VERSION
end

local function GuildKey()
    local guildName = GetGuildInfo("player")
    if not guildName then
        return nil
    end
    local realmName = GetRealmName() or "UnknownRealm"
    return realmName .. " - " .. guildName, guildName, realmName
end

local function CountSavedMembers()
    local key = GuildKey()
    if not key or not MuklaOfficerSuiteDB.guilds[key] then
        return 0
    end
    return table.getn(MuklaOfficerSuiteDB.guilds[key].members or {})
end

local function SaveGuildRoster()
    EnsureDatabase()
    local key, guildName, realmName = GuildKey()
    if not key then
        Print("This character is not in a guild.")
        return false
    end

    local total = GetNumGuildMembers(true)
    if not total or total < 1 then
        return false
    end

    local members = {}
    local i
    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, publicNote, officerNote, online, status = GetGuildRosterInfo(i)
        if name then
            table.insert(members, {
                name = name,
                level = level or 0,
                class = class or "",
                rank = rank or "",
                rankIndex = rankIndex,
                publicNote = publicNote or "",
                officerNote = officerNote or "",
                online = online and true or false,
                zone = zone or "",
                status = status,
            })
        end
    end

    table.sort(members, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    local scanTimestamp = time()
    local scanDuration = 0
    if MOS.scanStartedAt then
        scanDuration = GetTime() - MOS.scanStartedAt
    end
    MuklaOfficerSuiteDB.guilds[key] = {
        guildName = guildName,
        realmName = realmName,
        addonVersion = VERSION,
        scannedAt = scanTimestamp,
        scannedAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp),
        scanDurationSeconds = scanDuration,
        updatedAt = scanTimestamp,
        updatedBy = UnitName("player"),
        members = members,
    }
    MuklaOfficerSuiteDB.lastScanAt = scanTimestamp
    MuklaOfficerSuiteDB.lastScanAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp)
    MuklaOfficerSuiteDB.lastScanDurationSeconds = scanDuration
    MOS.pendingScan = nil
    MOS.scanStartedAt = nil
    MOS.scanAttempts = 0
    rosterRequestFrame.delay = nil
    rosterRequestFrame:Hide()
    return true
end

local function SaveRaidRoster()
    EnsureDatabase()
    local guildData = nil
    local guildKey = GuildKey()
    if guildKey then
        guildData = MuklaOfficerSuiteDB.guilds[guildKey]
    end

    local guildMembers = {}
    if guildData and guildData.members then
        local guildIndex
        for guildIndex = 1, table.getn(guildData.members) do
            guildMembers[string.lower(guildData.members[guildIndex].name or "")] = guildData.members[guildIndex]
        end
    end

    local members = {}
    local total = GetNumRaidMembers() or 0
    local raidIndex
    for raidIndex = 1, total do
        local name, raidRank, subgroup, level, class, classFile, zone, online, dead = GetRaidRosterInfo(raidIndex)
        if name then
            local guildMember = guildMembers[string.lower(name)]
            table.insert(members, {
                name = name,
                raidRank = raidRank or 0,
                subgroup = subgroup or 0,
                level = level or (guildMember and guildMember.level) or 0,
                class = class or (guildMember and guildMember.class) or "",
                classFile = classFile or "",
                zone = zone or "",
                online = online and true or false,
                dead = dead and true or false,
                guildRank = guildMember and guildMember.rank or "",
                guildRankIndex = guildMember and guildMember.rankIndex or nil,
                publicNote = guildMember and guildMember.publicNote or "",
                officerNote = guildMember and guildMember.officerNote or "",
                guildMember = guildMember and true or false,
            })
        end
    end

    local scanTimestamp = time()
    MuklaOfficerSuiteDB.csr = {
        addonVersion = VERSION,
        scannedAt = scanTimestamp,
        scannedAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp),
        raidName = GetRealZoneText() or "",
        updatedBy = UnitName("player"),
        raidMembers = members,
    }
    return table.getn(members)
end

local dashboard = CreateFrame("Frame", "MuklaOfficerSuiteDashboard", UIParent)
dashboard:SetWidth(840)
dashboard:SetHeight(540)
dashboard:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
dashboard:SetFrameStrata("DIALOG")
dashboard:SetMovable(true)
dashboard:EnableMouse(true)
dashboard:RegisterForDrag("LeftButton")
dashboard:SetScript("OnDragStart", function() this:StartMoving() end)
dashboard:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
dashboard:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
dashboard:SetBackdropColor(0.035, 0.03, 0.02, 0.98)
dashboard:SetBackdropBorderColor(1, 1, 1, 1)
dashboard:Hide()

local titleBar = CreateFrame("Frame", nil, dashboard)
titleBar:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 18, -14)
titleBar:SetPoint("TOPRIGHT", dashboard, "TOPRIGHT", -18, -14)
titleBar:SetHeight(32)
titleBar:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
titleBar:SetBackdropColor(0.025, 0.022, 0.018, 0.98)
titleBar:SetBackdropBorderColor(0.42, 0.42, 0.40, 1)

local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("CENTER", titleBar, "CENTER", 0, 2)
title:SetText("Mukla Officer Suite")

local closeButton = CreateFrame("Button", nil, dashboard, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", dashboard, "TOPRIGHT", -5, -5)

local versionText = dashboard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
versionText:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -22, 17)
versionText:SetText("v" .. VERSION)

local sidebar = CreateFrame("Frame", nil, dashboard)
sidebar:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 20, -68)
sidebar:SetPoint("BOTTOMLEFT", dashboard, "BOTTOMLEFT", 20, 28)
sidebar:SetWidth(174)
sidebar:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
sidebar:SetBackdropColor(0.05, 0.04, 0.02, 0.92)
sidebar:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)

local contentPanel = CreateFrame("Frame", nil, dashboard)
contentPanel:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 204, -68)
contentPanel:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -20, 32)
contentPanel:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
contentPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.90)
contentPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)

local background = sidebar:CreateTexture(nil, "BACKGROUND")
background:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 5, -5)
background:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -5, 5)
background:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\DashboardBackground")
background:SetTexCoord(0.22, 0.58, 0, 1)
background:SetAlpha(0.72)

local backgroundShade = sidebar:CreateTexture(nil, "BORDER")
backgroundShade:SetAllPoints(sidebar)
backgroundShade:SetTexture(0, 0, 0, 0.40)

local contentShade = contentPanel:CreateTexture(nil, "BACKGROUND")
contentShade:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 5, -5)
contentShade:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -5, 5)
contentShade:SetTexture(0.025, 0.022, 0.018, 0.96)

local rosterPage = CreateFrame("Frame", nil, contentPanel)
rosterPage:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 14, -14)
rosterPage:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -14, 14)

local exportPage = CreateFrame("Frame", nil, contentPanel)
exportPage:SetAllPoints(rosterPage)
exportPage:Hide()

local statisticsPage = CreateFrame("Frame", nil, contentPanel)
statisticsPage:SetAllPoints(rosterPage)
statisticsPage:Hide()

local raidPage = CreateFrame("Frame", nil, contentPanel)
raidPage:SetAllPoints(rosterPage)
raidPage:Hide()

local csrPage = CreateFrame("Frame", nil, contentPanel)
csrPage:SetAllPoints(rosterPage)
csrPage:Hide()

local aboutPage = CreateFrame("Frame", nil, contentPanel)
aboutPage:SetAllPoints(rosterPage)
aboutPage:Hide()

local rosterTitle = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rosterTitle:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -2)
rosterTitle:SetText("Roster Management")

local searchLabel = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -192, -79)
searchLabel:SetText("Search")

local searchBox = CreateFrame("EditBox", "MuklaOfficerSuiteRosterSearch", rosterPage, "InputBoxTemplate")
searchBox:SetWidth(178)
searchBox:SetHeight(20)
searchBox:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -4, -73)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

local rosterStatusText = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rosterStatusText:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -36)
rosterStatusText:SetWidth(565)
rosterStatusText:SetJustifyH("LEFT")

local rosterLastScan = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rosterLastScan:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -54)
rosterLastScan:SetWidth(330)
rosterLastScan:SetJustifyH("LEFT")

local rosterScanButton = CreateFrame("Button", nil, rosterPage, "UIPanelButtonTemplate")
rosterScanButton:SetWidth(180)
rosterScanButton:SetHeight(32)
rosterScanButton:SetPoint("CENTER", rosterPage, "CENTER", -96, 12)
rosterScanButton:SetText("Scan Guild Data")

local rosterRefreshButton = CreateFrame("Button", nil, rosterPage, "UIPanelButtonTemplate")
rosterRefreshButton:SetWidth(108)
rosterRefreshButton:SetHeight(22)
rosterRefreshButton:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -4, -48)
rosterRefreshButton:SetText("Refresh Data")
rosterRefreshButton:Hide()

local rosterSortHint = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rosterSortHint:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -94)
rosterSortHint:SetText("Click a column header to sort")
rosterSortHint:Hide()

local rows = {}
local rowCount = 13
local rowHeight = 20
local visibleMembers = {}
local sortKey = "name"
local sortAscending = true
local selectedMemberName = nil
local selectedClasses = {}
local selectedRanks = {}
local classFilterInitialized = false
local rankFilterInitialized = false
local RefreshRosterPage
local RefreshExportPage
local RefreshStatisticsPage
local RefreshCSRPage
local RefreshRaidPage
local RequestGuildAction
local menuButtons = {}
local currentPage = "roster"
local rosterReady = false
local statisticsReady = false

local filtersLabel = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
filtersLabel:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -80)
filtersLabel:SetText("Filters")

local function StyleCompactButton(button, text)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 9, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.08, 0.07, 0.05, 0.96)
    button:SetBackdropBorderColor(0.48, 0.38, 0.20, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetAllPoints(button)
    button.label:SetText(text)
    button.SetText = function(self, value) self.label:SetText(value) end
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture(1, 0.72, 0.12, 0.10)
end

local function CreateFilterToggle(text, x)
    local button = CreateFrame("Button", nil, rosterPage)
    button:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", x, -74)
    button:SetWidth(84)
    button:SetHeight(19)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.08, 0.07, 0.05, 0.95)
    button:SetBackdropBorderColor(0.42, 0.35, 0.20, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.label:SetText(text)
    button.arrow = button:CreateTexture(nil, "OVERLAY")
    button.arrow:SetWidth(16)
    button.arrow:SetHeight(16)
    button.arrow:SetPoint("RIGHT", button, "RIGHT", -5, 0)
    button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    button.arrow:SetTexCoord(0.20, 0.80, 0.20, 0.80)
    return button
end

local classFilterToggle = CreateFilterToggle("Class", 52)
local rankFilterToggle = CreateFilterToggle("Rank", 150)

local function CreateFilterPanel(toggle)
    local panel = CreateFrame("Frame", nil, rosterPage)
    panel:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(180)
    panel:SetHeight(230)
    panel:SetFrameLevel(rosterPage:GetFrameLevel() + 20)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    panel:SetBackdropColor(0.04, 0.03, 0.02, 0.98)
    panel.options = {}
    panel:Hide()
    return panel
end

local classFilterPanel = CreateFilterPanel(classFilterToggle)
local rankFilterPanel = CreateFilterPanel(rankFilterToggle)

local filterDismiss = CreateFrame("Button", nil, rosterPage)
filterDismiss:SetAllPoints(rosterPage)
filterDismiss:SetFrameLevel(rosterPage:GetFrameLevel() + 10)
filterDismiss:Hide()
classFilterPanel:SetFrameLevel(rosterPage:GetFrameLevel() + 20)
rankFilterPanel:SetFrameLevel(rosterPage:GetFrameLevel() + 20)
classFilterToggle:SetFrameLevel(rosterPage:GetFrameLevel() + 21)
rankFilterToggle:SetFrameLevel(rosterPage:GetFrameLevel() + 21)

local function HideFilterPanels(except)
    if except ~= classFilterPanel then classFilterPanel:Hide() end
    if except ~= rankFilterPanel then rankFilterPanel:Hide() end
    if not except then filterDismiss:Hide() end
end

filterDismiss:SetScript("OnClick", function() HideFilterPanels() end)

classFilterToggle:SetScript("OnClick", function()
    local show = not classFilterPanel:IsVisible()
    HideFilterPanels()
    if show then classFilterPanel:Show(); filterDismiss:Show() end
end)
rankFilterToggle:SetScript("OnClick", function()
    local show = not rankFilterPanel:IsVisible()
    HideFilterPanels()
    if show then rankFilterPanel:Show(); filterDismiss:Show() end
end)

local function Short(text, length)
    text = tostring(text or "")
    if string.len(text) > length then
        return string.sub(text, 1, length - 1) .. "~"
    end
    return text
end

local function CreateHeaderButton(text, x, width, alignment, key)
    local button = CreateFrame("Button", nil, rosterPage)
    button:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", x, -108)
    button:SetWidth(width)
    button:SetHeight(22)
    button.baseText = text
    button.sortKey = key

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetAllPoints(button)
    label:SetJustifyH(alignment or "LEFT")
    label:SetText(text .. " <>")
    button.label = label

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture(1, 0.72, 0.12, 0.12)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine("Sort by " .. this.baseText)
        GameTooltip:AddLine("Click again to reverse the order", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return button
end

local headerButtons = {
    CreateHeaderButton("Name", 4, 132, "LEFT", "name"),
    CreateHeaderButton("Lvl", 141, 38, "RIGHT", "level"),
    CreateHeaderButton("Class", 189, 82, "LEFT", "class"),
    CreateHeaderButton("Rank", 281, 100, "LEFT", "rank"),
}

local notesHeader = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
notesHeader:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 391, -108)
notesHeader:SetWidth(174)
notesHeader:SetHeight(22)
notesHeader:SetJustifyH("LEFT")
notesHeader:SetText("Public / Officer note")

local i
for i = 1, rowCount do
    local row = CreateFrame("Button", nil, rosterPage)
    row:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -114 - (i * rowHeight))
    row:SetWidth(560)
    row:SetHeight(rowHeight)
    row:EnableMouse(true)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    if math.mod(i, 2) == 0 then
        local stripe = row:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints(row)
        stripe:SetTexture(1, 0.78, 0.25, 0.075)
    end

    row.selection = row:CreateTexture(nil, "BACKGROUND")
    row.selection:SetAllPoints(row)
    row.selection:SetTexture(0, 0, 0, 0)
    row.selection:Hide()

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 7, -1)
    row.name:SetWidth(125)
    row.name:SetHeight(18)
    row.name:SetJustifyH("LEFT")

    row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.level:SetPoint("TOPLEFT", row, "TOPLEFT", 137, -1)
    row.level:SetWidth(38)
    row.level:SetHeight(18)
    row.level:SetJustifyH("RIGHT")

    row.class = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("TOPLEFT", row, "TOPLEFT", 185, -1)
    row.class:SetWidth(82)
    row.class:SetHeight(18)
    row.class:SetJustifyH("LEFT")

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.rank:SetPoint("TOPLEFT", row, "TOPLEFT", 277, -1)
    row.rank:SetWidth(100)
    row.rank:SetHeight(18)
    row.rank:SetJustifyH("LEFT")

    row.notes = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.notes:SetPoint("TOPLEFT", row, "TOPLEFT", 387, -1)
    row.notes:SetWidth(173)
    row.notes:SetHeight(18)
    row.notes:SetJustifyH("LEFT")
    row.actionPanel = CreateFrame("Frame", nil, row)
    row.actionPanel:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -20)
    row.actionPanel:SetWidth(552)
    row.actionPanel:SetHeight(26)
    row.actionPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    row.actionPanel:SetBackdropColor(0.07, 0.08, 0.07, 0.92)
    row.actionPanel:SetBackdropBorderColor(0.30, 0.34, 0.30, 1)
    row.actionPanel:Hide()

    local function CreateRowActionButton(text, action, x)
        local button = CreateFrame("Button", nil, row.actionPanel)
        button:SetPoint("RIGHT", row.actionPanel, "RIGHT", x, 0)
        button:SetWidth(78)
        button:SetHeight(19)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 9,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        button:SetBackdropColor(0.10, 0.07, 0.03, 0.94)
        button:SetBackdropBorderColor(0.58, 0.40, 0.10, 1)
        button.action = action
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.label:SetAllPoints(button)
        button.label:SetText(text)
        button:SetScript("OnClick", function() RequestGuildAction(this.action) end)
        return button
    end

    row.promoteButton = CreateRowActionButton("Promote", "promote", -86)
    row.demoteButton = CreateRowActionButton("Demote", "demote", -4)

    row:SetScript("OnClick", function()
        if this.displayedMember then
            if selectedMemberName == this.displayedMember.name then
                selectedMemberName = nil
            else
                selectedMemberName = this.displayedMember.name
            end
            RefreshRosterPage(false)
        end
    end)
    rows[i] = row
end

local rosterScrollFrame = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRosterScrollFrame", rosterPage, "FauxScrollFrameTemplate")
rosterScrollFrame:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", -4, -125)
rosterScrollFrame:SetPoint("BOTTOMRIGHT", rosterPage, "BOTTOMRIGHT", -12, 18)

local exportTitle = exportPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
exportTitle:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -10)
exportTitle:SetText("Export Roster")

local exportDescription = exportPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
exportDescription:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -66)
exportDescription:SetWidth(520)
exportDescription:SetJustifyH("LEFT")
exportDescription:SetText("Create a fresh guild roster snapshot.\nConfirm the UI reload to write it to disk, then run Export-Roster.ps1 to create the CSV file.")

local lastScanLabel = exportPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lastScanLabel:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -150)
lastScanLabel:SetText("Last saved scan")

local lastScanValue = exportPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lastScanValue:SetPoint("TOPLEFT", lastScanLabel, "BOTTOMLEFT", 0, -10)
lastScanValue:SetWidth(545)
lastScanValue:SetJustifyH("LEFT")

local scanSaveButton = CreateFrame("Button", nil, exportPage, "UIPanelButtonTemplate")
scanSaveButton:SetWidth(150)
scanSaveButton:SetHeight(28)
scanSaveButton:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -220)
scanSaveButton:SetText("Scan & Save")

local exportHint = exportPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
exportHint:SetPoint("LEFT", scanSaveButton, "RIGHT", 14, 0)
exportHint:SetWidth(350)
exportHint:SetJustifyH("LEFT")
exportHint:SetText("A confirmation dialog will reload the UI and write the roster to disk.")
exportHint:Hide()
scanSaveButton:SetParent(rosterPage)
scanSaveButton:ClearAllPoints()
scanSaveButton:SetPoint("CENTER", rosterPage, "CENTER", 96, 12)
scanSaveButton:SetText("Export Roster")

local statisticsTitle = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
statisticsTitle:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 12, -10)
statisticsTitle:SetText("Guild Statistics")

local statisticsOnlyLevel60 = CreateFrame("CheckButton", nil, statisticsPage, "UICheckButtonTemplate")
statisticsOnlyLevel60:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 8, -118)
statisticsOnlyLevel60:SetWidth(22)
statisticsOnlyLevel60:SetHeight(22)
statisticsOnlyLevel60:SetChecked(true)
statisticsOnlyLevel60.label = statisticsOnlyLevel60:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statisticsOnlyLevel60.label:SetPoint("LEFT", statisticsOnlyLevel60, "RIGHT", 2, 0)
statisticsOnlyLevel60.label:SetText("Only level 60")
statisticsOnlyLevel60:Hide()

local statisticsLastScan = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
statisticsLastScan:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 12, -48)
statisticsLastScan:SetWidth(360)
statisticsLastScan:SetJustifyH("LEFT")
statisticsLastScan:Hide()

local statisticsRefreshButton = CreateFrame("Button", nil, statisticsPage)
statisticsRefreshButton:SetWidth(108)
statisticsRefreshButton:SetHeight(22)
statisticsRefreshButton:SetPoint("TOPRIGHT", statisticsPage, "TOPRIGHT", -12, -42)
StyleCompactButton(statisticsRefreshButton, "Refresh Data")
statisticsRefreshButton:Hide()

local statisticsScanButton = CreateFrame("Button", nil, statisticsPage, "UIPanelButtonTemplate")
statisticsScanButton:SetWidth(180)
statisticsScanButton:SetHeight(32)
statisticsScanButton:SetPoint("CENTER", statisticsPage, "CENTER", 0, 12)
statisticsScanButton:SetText("Scan Guild Statistics")

local statisticsProgress = CreateFrame("StatusBar", nil, statisticsPage)
statisticsProgress:SetWidth(300)
statisticsProgress:SetHeight(22)
statisticsProgress:SetPoint("CENTER", statisticsPage, "CENTER", 0, 12)
statisticsProgress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
statisticsProgress:SetStatusBarColor(0.72, 0.48, 0.08, 1)
statisticsProgress:SetMinMaxValues(0, 100)
statisticsProgress:SetValue(0)
statisticsProgress:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
statisticsProgress:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
statisticsProgress.text = statisticsProgress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statisticsProgress.text:SetPoint("CENTER", statisticsProgress, "CENTER", 0, 0)
statisticsProgress:Hide()

local statisticsSummary = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statisticsSummary:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 12, -72)
statisticsSummary:SetWidth(545)
statisticsSummary:SetJustifyH("LEFT")
statisticsSummary:SetJustifyV("TOP")
statisticsSummary:Hide()

local statisticsClassPanel = statisticsPage:CreateTexture(nil, "BACKGROUND")
statisticsClassPanel:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 12, -154)
statisticsClassPanel:SetWidth(272)
statisticsClassPanel:SetHeight(245)
statisticsClassPanel:SetTexture(0.07, 0.065, 0.055, 0.82)
statisticsClassPanel:Hide()

local statisticsRankPanel = statisticsPage:CreateTexture(nil, "BACKGROUND")
statisticsRankPanel:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 300, -154)
statisticsRankPanel:SetWidth(262)
statisticsRankPanel:SetHeight(245)
statisticsRankPanel:SetTexture(0.07, 0.065, 0.055, 0.82)
statisticsRankPanel:Hide()

local statisticsClassBars = {}
for i = 1, 9 do
    local barBackground = statisticsPage:CreateTexture(nil, "BORDER")
    barBackground:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 205, -190 - ((i - 1) * 24))
    barBackground:SetWidth(62)
    barBackground:SetHeight(7)
    barBackground:SetTexture(0.18, 0.16, 0.12, 0.95)
    local barFill = statisticsPage:CreateTexture(nil, "ARTWORK")
    barFill:SetPoint("LEFT", barBackground, "LEFT", 0, 0)
    barFill:SetHeight(7)
    barFill:SetTexture(0.82, 0.56, 0.10, 0.95)
    barBackground:Hide()
    barFill:Hide()
    statisticsClassBars[i] = { background = barBackground, fill = barFill }
end

local statisticsClasses = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statisticsClasses:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 24, -165)
statisticsClasses:SetWidth(260)
statisticsClasses:SetJustifyH("LEFT")
statisticsClasses:SetJustifyV("TOP")
statisticsClasses:SetFont(STANDARD_TEXT_FONT, 13)
statisticsClasses:Hide()

local statisticsRanks = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statisticsRanks:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 316, -165)
statisticsRanks:SetWidth(255)
statisticsRanks:SetJustifyH("LEFT")
statisticsRanks:SetJustifyV("TOP")
statisticsRanks:SetFont(STANDARD_TEXT_FONT, 13)
statisticsRanks:Hide()

local raidTitle = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
raidTitle:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -10)
raidTitle:SetText("Raid Management")

local raidInfo = raidPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
raidInfo:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -12, -15)
raidInfo:SetText("")
raidInfo:Hide()

local raidUnavailable = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
raidUnavailable:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
raidUnavailable:SetText("You must be in a raid to scan the raid roster.")

local raidScanButton = CreateFrame("Button", nil, raidPage)
raidScanButton:SetWidth(160)
raidScanButton:SetHeight(32)
raidScanButton:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
StyleCompactButton(raidScanButton, "Scan Raid")
raidScanButton:Hide()

local raidExportButton = CreateFrame("Button", nil, raidPage)
raidExportButton:SetWidth(142)
raidExportButton:SetHeight(24)
raidExportButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -142, -42)
StyleCompactButton(raidExportButton, "Export Attendance")
raidExportButton:Hide()

local raidStatus = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
raidStatus:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -48)
raidStatus:SetWidth(545)
raidStatus:SetJustifyH("LEFT")

local raidHeaders = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidHeaders:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -76)
raidHeaders:SetWidth(190)
raidHeaders:SetJustifyH("LEFT")
raidHeaders:SetText("Name")
raidHeaders:Hide()

local raidGroupHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidGroupHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 220, -76)
raidGroupHeader:SetWidth(55)
raidGroupHeader:SetJustifyH("CENTER")
raidGroupHeader:SetText("Group")
raidGroupHeader:Hide()
local raidClassHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidClassHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 292, -76)
raidClassHeader:SetWidth(105)
raidClassHeader:SetJustifyH("LEFT")
raidClassHeader:SetText("Class")
raidClassHeader:Hide()
local raidRankHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidRankHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 414, -76)
raidRankHeader:SetWidth(140)
raidRankHeader:SetJustifyH("LEFT")
raidRankHeader:SetText("Guild rank")
raidRankHeader:Hide()

local raidRows = {}
for i = 1, 15 do
    local raidRow = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -98 - ((i - 1) * 21))
    raidRow:SetWidth(190)
    raidRow:SetHeight(20)
    raidRow:SetJustifyH("LEFT")
    raidRow.group = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.group:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 220, -98 - ((i - 1) * 21))
    raidRow.group:SetWidth(55)
    raidRow.group:SetHeight(20)
    raidRow.group:SetJustifyH("CENTER")
    raidRow.class = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.class:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 292, -98 - ((i - 1) * 21))
    raidRow.class:SetWidth(105)
    raidRow.class:SetHeight(20)
    raidRow.class:SetJustifyH("LEFT")
    raidRow.rank = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.rank:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 414, -98 - ((i - 1) * 21))
    raidRow.rank:SetWidth(140)
    raidRow.rank:SetHeight(20)
    raidRow.rank:SetJustifyH("LEFT")
    raidRow:Hide()
    raidRow.group:Hide()
    raidRow.class:Hide()
    raidRow.rank:Hide()
    raidRows[i] = raidRow
end

local raidScrollFrame = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRaidScrollFrame", raidPage, "FauxScrollFrameTemplate")
raidScrollFrame:SetPoint("TOPLEFT", raidPage, "TOPLEFT", -4, -88)
raidScrollFrame:SetPoint("BOTTOMRIGHT", raidPage, "BOTTOMRIGHT", -12, 18)

local csrTitle = csrPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
csrTitle:SetPoint("TOPLEFT", csrPage, "TOPLEFT", 12, -10)
csrTitle:SetText("CSR")

local csrDescription = csrPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
csrDescription:SetPoint("TOPLEFT", csrPage, "TOPLEFT", 12, -58)
csrDescription:SetWidth(545)
csrDescription:SetJustifyH("CENTER")
csrDescription:SetText("CSR tools are coming in a future version.")

local csrLastScanLabel = csrPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
csrLastScanLabel:SetPoint("TOPLEFT", csrPage, "TOPLEFT", 12, -135)
csrLastScanLabel:SetText("Last saved CSR scan")

local csrLastScanValue = csrPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
csrLastScanValue:SetPoint("TOPLEFT", csrLastScanLabel, "BOTTOMLEFT", 0, -10)
csrLastScanValue:SetWidth(545)
csrLastScanValue:SetJustifyH("LEFT")

local csrScanSaveButton = CreateFrame("Button", nil, csrPage, "UIPanelButtonTemplate")
csrScanSaveButton:SetWidth(150)
csrScanSaveButton:SetHeight(28)
csrScanSaveButton:SetPoint("TOPLEFT", csrPage, "TOPLEFT", 12, -205)
csrScanSaveButton:SetText("Scan & Save")

local csrHint = csrPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
csrHint:SetPoint("LEFT", csrScanSaveButton, "RIGHT", 14, 0)
csrHint:SetWidth(365)
csrHint:SetJustifyH("LEFT")
csrHint:SetText("You must be in a raid. The UI reload writes the snapshot to disk.")
csrLastScanLabel:Hide()
csrLastScanValue:Hide()
csrScanSaveButton:Hide()
csrHint:Hide()

local aboutTitle = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
aboutTitle:SetPoint("TOPLEFT", aboutPage, "TOPLEFT", 12, -10)
aboutTitle:SetText("About")

local aboutArtwork = aboutPage:CreateTexture(nil, "ARTWORK")
aboutArtwork:SetPoint("TOPRIGHT", aboutPage, "TOPRIGHT", -4, -4)
aboutArtwork:SetPoint("BOTTOMRIGHT", aboutPage, "BOTTOMRIGHT", -4, 4)
aboutArtwork:SetWidth(382)
aboutArtwork:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\AboutArtwork")
aboutArtwork:SetTexCoord(0.066, 0.934, 0, 1)
aboutArtwork:SetAlpha(0.88)

local aboutName = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
aboutName:SetPoint("TOPLEFT", aboutPage, "TOPLEFT", 28, -105)
aboutName:SetText("Mukla Officer Suite")

local aboutVersion = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
aboutVersion:SetPoint("TOPLEFT", aboutName, "BOTTOMLEFT", 0, -12)
aboutVersion:SetText("Version " .. VERSION)

local aboutAuthor = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
aboutAuthor:SetPoint("TOPLEFT", aboutVersion, "BOTTOMLEFT", 0, -24)
aboutAuthor:SetText("Created by Bootybaker")

local aboutDescription = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
aboutDescription:SetPoint("TOPLEFT", aboutAuthor, "BOTTOMLEFT", 0, -34)
aboutDescription:SetWidth(220)
aboutDescription:SetJustifyH("LEFT")
aboutDescription:SetText("")
aboutDescription:Hide()

local function GetCurrentGuildData()
    EnsureDatabase()
    local key, guildName = GuildKey()
    return key and MuklaOfficerSuiteDB.guilds[key], guildName
end

local function GetUniqueMemberValues(data, field)
    local values = {}
    local found = {}
    if data and data.members then
        for i = 1, table.getn(data.members) do
            local value = tostring(data.members[i][field] or "Unknown")
            if value == "" then value = "Unknown" end
            if not found[value] then
                found[value] = true
                table.insert(values, value)
            end
        end
    end
    table.sort(values, function(a, b) return string.lower(a) < string.lower(b) end)
    return values
end

local function RefreshFilterPanel(panel, values, selected, filterType)
    if not panel.selectAll then
        panel.selectAll = CreateFrame("Button", nil, panel)
        panel.selectAll:SetWidth(82)
        panel.selectAll:SetHeight(18)
        StyleCompactButton(panel.selectAll, "Select all")
        panel.selectAll.filterType = filterType
        panel.selectAll:SetScript("OnClick", function()
            local target = this.filterType == "class" and selectedClasses or selectedRanks
            local optionIndex
            for optionIndex = 1, table.getn(this:GetParent().values or {}) do
                target[this:GetParent().values[optionIndex]] = true
            end
            RefreshRosterPage(true)
        end)
    end
    panel.values = values
    panel.selectAll:ClearAllPoints()
    panel.selectAll:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 9)
    panel:SetHeight(38 + table.getn(values) * 20)

    local optionIndex
    for optionIndex = 1, table.getn(values) do
        local checkbox = panel.options[optionIndex]
        if not checkbox then
            checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            checkbox:SetWidth(20)
            checkbox:SetHeight(20)
            checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10 - ((optionIndex - 1) * 20))
            checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            checkbox.label:SetWidth(132)
            checkbox.label:SetJustifyH("LEFT")
            checkbox.filterType = filterType
            checkbox:SetScript("OnClick", function()
                local target = this.filterType == "class" and selectedClasses or selectedRanks
                target[this.value] = this:GetChecked() and true or false
                RefreshRosterPage(true)
            end)
            panel.options[optionIndex] = checkbox
        end
        checkbox.value = values[optionIndex]
        checkbox.label:SetText(values[optionIndex])
        checkbox:SetChecked(selected[values[optionIndex]] and true or false)
        checkbox:Show()
    end
    for optionIndex = table.getn(values) + 1, table.getn(panel.options) do
        panel.options[optionIndex]:Hide()
    end
end

local function InitializeAndRefreshFilters(data)
    local classes = GetUniqueMemberValues(data, "class")
    local ranks = GetUniqueMemberValues(data, "rank")
    local filterIndex
    if not classFilterInitialized then
        for filterIndex = 1, table.getn(classes) do selectedClasses[classes[filterIndex]] = true end
        classFilterInitialized = true
    end
    if not rankFilterInitialized then
        for filterIndex = 1, table.getn(ranks) do selectedRanks[ranks[filterIndex]] = true end
        rankFilterInitialized = true
    end
    RefreshFilterPanel(classFilterPanel, classes, selectedClasses, "class")
    RefreshFilterPanel(rankFilterPanel, ranks, selectedRanks, "rank")
end

local function MemberMatchesFilters(member)
    local className = tostring(member.class or "Unknown")
    local rankName = tostring(member.rank or "Unknown")
    if className == "" then className = "Unknown" end
    if rankName == "" then rankName = "Unknown" end
    return selectedClasses[className] and selectedRanks[rankName]
end

local function GetSelectedMember()
    if not selectedMemberName then
        return nil
    end
    local data = GetCurrentGuildData()
    if not data or not data.members then
        return nil
    end
    for i = 1, table.getn(data.members) do
        if data.members[i].name == selectedMemberName then
            return data.members[i]
        end
    end
    return nil
end

local function GetRankNameByIndex(rankIndex)
    local data = GetCurrentGuildData()
    if not data or not data.members then
        return nil
    end
    for i = 1, table.getn(data.members) do
        if data.members[i].rankIndex == rankIndex then
            return data.members[i].rank
        end
    end
    return nil
end

local function GetLowestRankIndex()
    local data = GetCurrentGuildData()
    local lowest = 0
    if data and data.members then
        for i = 1, table.getn(data.members) do
            local rankIndex = tonumber(data.members[i].rankIndex) or 0
            if rankIndex > lowest then
                lowest = rankIndex
            end
        end
    end
    return lowest
end

local function MemberMatchesSearch(member, query)
    if query == "" then
        return true
    end
    local searchable = string.lower(
        tostring(member.name or "") .. " " ..
        tostring(member.level or "") .. " " ..
        tostring(member.class or "") .. " " ..
        tostring(member.rank or "") .. " " ..
        tostring(member.rankIndex or "") .. " " ..
        tostring(member.publicNote or "") .. " " ..
        tostring(member.officerNote or "") .. " " ..
        tostring(member.zone or "") .. " " ..
        tostring(member.status or "") .. " " ..
        tostring(member.online)
    )
    return string.find(searchable, query, 1, true) ~= nil
end

local function SortMembers(a, b)
    local aValue
    local bValue
    if sortKey == "level" then
        aValue = tonumber(a.level) or 0
        bValue = tonumber(b.level) or 0
    elseif sortKey == "rank" then
        aValue = tonumber(a.rankIndex) or 999
        bValue = tonumber(b.rankIndex) or 999
    else
        aValue = string.lower(tostring(a[sortKey] or ""))
        bValue = string.lower(tostring(b[sortKey] or ""))
    end

    if aValue == bValue then
        aValue = string.lower(tostring(a.name or ""))
        bValue = string.lower(tostring(b.name or ""))
    end
    if sortAscending then
        return aValue < bValue
    end
    return aValue > bValue
end

local function SetRosterDataVisible(visible)
    local method = visible and "Show" or "Hide"
    filtersLabel[method](filtersLabel)
    searchLabel[method](searchLabel)
    searchBox[method](searchBox)
    classFilterToggle[method](classFilterToggle)
    rankFilterToggle[method](rankFilterToggle)
    notesHeader[method](notesHeader)
    rosterScrollFrame[method](rosterScrollFrame)
    rosterSortHint[method](rosterSortHint)
    rosterRefreshButton[method](rosterRefreshButton)
    for i = 1, table.getn(headerButtons) do headerButtons[i][method](headerButtons[i]) end
    if not visible then
        scanSaveButton:ClearAllPoints()
        scanSaveButton:SetPoint("CENTER", rosterPage, "CENTER", 96, 12)
        scanSaveButton:SetWidth(150)
        HideFilterPanels()
        for i = 1, table.getn(rows) do rows[i]:Hide() end
    else
        scanSaveButton:ClearAllPoints()
        scanSaveButton:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -120, -48)
        scanSaveButton:SetWidth(112)
    end
    scanSaveButton:Show()
end

RefreshRosterPage = function(resetScroll)
    local data, guildName = GetCurrentGuildData()
    if not rosterReady then
        SetRosterDataVisible(false)
        rosterScanButton:Show()
        rosterStatusText:SetText("")
        rosterLastScan:SetText("")
        return
    end
    rosterScanButton:Hide()
    SetRosterDataVisible(true)
    rosterLastScan:SetText(data and ("Last scan: " .. (data.scannedAtText or "Unknown")) or "No saved scan")
    local query = string.lower(searchBox:GetText() or "")
    query = string.gsub(query, "^%s*(.-)%s*$", "%1")

    InitializeAndRefreshFilters(data)
    visibleMembers = {}
    if data and data.members then
        for i = 1, table.getn(data.members) do
            if MemberMatchesSearch(data.members[i], query) and MemberMatchesFilters(data.members[i]) then
                table.insert(visibleMembers, data.members[i])
            end
        end
        table.sort(visibleMembers, SortMembers)
    end

    if not guildName then
        rosterStatusText:SetText("No guild found.")
    elseif not data then
        rosterStatusText:SetText(guildName .. " - no saved roster. Use Export Roster to scan.")
    elseif query ~= "" or table.getn(visibleMembers) ~= table.getn(data.members) then
        rosterStatusText:SetText(guildName .. " - showing " .. table.getn(visibleMembers) .. " of " .. table.getn(data.members) .. " members")
    else
        rosterStatusText:SetText(guildName .. " - " .. table.getn(data.members) .. " members")
    end

    if resetScroll then
        rosterScrollFrame.offset = 0
        rosterScrollFrame:SetVerticalScroll(0)
    end
    FauxScrollFrame_Update(rosterScrollFrame, table.getn(visibleMembers), rowCount, rowHeight)
    local offset = FauxScrollFrame_GetOffset(rosterScrollFrame)

    local rowY = -134
    for i = 1, rowCount do
        local member = visibleMembers[offset + i]
        rows[i]:ClearAllPoints()
        rows[i]:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, rowY)
        if member then
            local notes = member.publicNote or ""
            if member.officerNote and member.officerNote ~= "" then
                notes = notes .. " / " .. member.officerNote
            end
            rows[i].name:SetText(Short(member.name, 18))
            rows[i].level:SetText(member.level or "")
            rows[i].class:SetText(Short(member.class, 11))
            rows[i].rank:SetText(Short(member.rank, 14))
            rows[i].notes:SetText(Short(notes, 25))
            rows[i].displayedMember = member
            if member.name == selectedMemberName then
                rows[i].selection:Show()
                rows[i]:SetBackdropColor(0.16, 0.20, 0.17, 0.82)
                rows[i]:SetBackdropBorderColor(0.46, 0.55, 0.47, 0.90)
                rows[i].actionPanel:Show()
                rows[i]:SetHeight(50)
                if (tonumber(member.rankIndex) or 0) <= 0 then
                    rows[i].promoteButton:Disable()
                else
                    rows[i].promoteButton:Enable()
                end
                if (tonumber(member.rankIndex) or 0) >= GetLowestRankIndex() then
                    rows[i].demoteButton:Disable()
                else
                    rows[i].demoteButton:Enable()
                end
                rowY = rowY - 50
            else
                rows[i].selection:Hide()
                rows[i]:SetBackdropColor(0, 0, 0, 0)
                rows[i]:SetBackdropBorderColor(0, 0, 0, 0)
                rows[i].actionPanel:Hide()
                rows[i]:SetHeight(rowHeight)
                rowY = rowY - rowHeight
            end
            rows[i]:Show()
        else
            rows[i].displayedMember = nil
            rows[i].selection:Hide()
            rows[i]:SetBackdropColor(0, 0, 0, 0)
            rows[i]:SetBackdropBorderColor(0, 0, 0, 0)
            rows[i].actionPanel:Hide()
            rows[i]:Hide()
        end
    end

    for i = 1, table.getn(headerButtons) do
        local button = headerButtons[i]
        if button.sortKey == sortKey then
            button.label:SetText(button.baseText .. (sortAscending and " ^" or " v"))
        else
            button.label:SetText(button.baseText .. " <>")
        end
    end
end

RefreshExportPage = function()
    local data, guildName = GetCurrentGuildData()
    if not guildName then
        lastScanValue:SetText("No guild found for this character.")
    elseif not data then
        lastScanValue:SetText("No saved scan for " .. guildName .. ".")
    else
        local scanTime = data.scannedAtText or date("%Y-%m-%d %H:%M:%S", data.scannedAt or data.updatedAt)
        lastScanValue:SetText(scanTime .. " | " .. table.getn(data.members) .. " members | addon v" .. (data.addonVersion or MuklaOfficerSuiteDB.addonVersion or VERSION))
    end
end

local CLASS_ICONS = {
    Druid = "Interface\\Icons\\Spell_Nature_ForceOfNature",
    Hunter = "Interface\\Icons\\INV_Weapon_Bow_07",
    Mage = "Interface\\Icons\\INV_Staff_13",
    Paladin = "Interface\\Icons\\Spell_Holy_HolyBolt",
    Priest = "Interface\\Icons\\INV_Staff_30",
    Rogue = "Interface\\Icons\\INV_ThrowingKnife_04",
    Shaman = "Interface\\Icons\\Spell_Nature_BloodLust",
    Warlock = "Interface\\Icons\\Spell_Nature_FaerieFire",
    Warrior = "Interface\\Icons\\INV_Sword_27",
}

local function SortedClassLines(counts)
    local names = {}
    local name
    for name in pairs(counts) do table.insert(names, name) end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    local lines = { "|cffffd200Members by class|r" }
    local lineIndex
    for lineIndex = 1, table.getn(names) do
        local className = names[lineIndex]
        local icon = CLASS_ICONS[className]
        local prefix = icon and ("|T" .. icon .. ":24:24|t  ") or ""
        table.insert(lines, prefix .. className .. ": " .. counts[className])
    end
    return table.concat(lines, "\n")
end

local function SortedRankLines(ranks)
    local rankList = {}
    local rankName, rankData
    for rankName, rankData in pairs(ranks) do
        table.insert(rankList, { name = rankName, count = rankData.count, index = rankData.index })
    end
    table.sort(rankList, function(a, b)
        if a.index == b.index then return string.lower(a.name) < string.lower(b.name) end
        return a.index < b.index
    end)
    local lines = { "|cffffd200Members by rank|r" }
    local rankIndex
    for rankIndex = 1, table.getn(rankList) do
        table.insert(lines, rankList[rankIndex].name .. ": " .. rankList[rankIndex].count)
    end
    return table.concat(lines, "\n")
end

RefreshStatisticsPage = function()
    if not statisticsReady then return end
    local data, guildName = GetCurrentGuildData()
    if not data or not data.members then
        statisticsSummary:SetText((guildName or "Guild") .. " has no saved roster. Use Export Roster first.")
        statisticsClasses:SetText("")
        statisticsRanks:SetText("")
        return
    end
    local classes = {}
    local ranks = {}
    local included = 0
    local onlyLevel60 = statisticsOnlyLevel60:GetChecked()
    local memberIndex
    for memberIndex = 1, table.getn(data.members) do
        local member = data.members[memberIndex]
        local level = tonumber(member.level) or 0
        if not onlyLevel60 or level == 60 then
            local className = member.class ~= "" and member.class or "Unknown"
            local rankName = member.rank ~= "" and member.rank or "Unknown"
            classes[className] = (classes[className] or 0) + 1
            if not ranks[rankName] then ranks[rankName] = { count = 0, index = tonumber(member.rankIndex) or 999 } end
            ranks[rankName].count = ranks[rankName].count + 1
            included = included + 1
        end
    end
    local total = table.getn(data.members)
    statisticsSummary:SetText(
        "|cffffd200" .. (guildName or "Guild") .. "|r   |   Included members: " .. included ..
        (onlyLevel60 and " (level 60 only)" or (" of " .. total))
    )
    statisticsClasses:SetText(SortedClassLines(classes))
    statisticsRanks:SetText(SortedRankLines(ranks))
    local classNames = {}
    local className, classCount
    local maximumClassCount = 1
    for className, classCount in pairs(classes) do
        table.insert(classNames, className)
        if classCount > maximumClassCount then maximumClassCount = classCount end
    end
    table.sort(classNames, function(a, b) return string.lower(a) < string.lower(b) end)
    for i = 1, table.getn(statisticsClassBars) do
        local bar = statisticsClassBars[i]
        if classNames[i] then
            bar.fill:SetWidth(math.max(2, math.floor(62 * classes[classNames[i]] / maximumClassCount)))
            bar.background:Show()
            bar.fill:Show()
        else
            bar.background:Hide()
            bar.fill:Hide()
        end
    end
    statisticsSummary:Show()
    statisticsClasses:Show()
    statisticsRanks:Show()
    statisticsClassPanel:Show()
    statisticsRankPanel:Show()
    statisticsOnlyLevel60:Show()
    statisticsScanButton:Hide()
    statisticsLastScan:SetText("Last scan: " .. (data.scannedAtText or "Unknown"))
    statisticsLastScan:Show()
    statisticsRefreshButton:Show()
end

RefreshCSRPage = function()
end

RefreshRaidPage = function()
    local inRaid = (GetNumRaidMembers() or 0) > 0
    if not inRaid then
        MOS.raidScanReady = false
        raidUnavailable:Show()
        raidScanButton:Hide()
        raidExportButton:Hide()
        raidHeaders:Hide()
        raidGroupHeader:Hide(); raidClassHeader:Hide(); raidRankHeader:Hide()
        raidScrollFrame:Hide()
        raidStatus:SetText("")
        for i = 1, table.getn(raidRows) do raidRows[i]:Hide(); raidRows[i].group:Hide(); raidRows[i].class:Hide(); raidRows[i].rank:Hide() end
        return
    end
    raidUnavailable:Hide()
    if not MOS.raidScanReady then
        raidScanButton:ClearAllPoints()
        raidScanButton:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
        raidScanButton:SetWidth(160)
        raidScanButton:SetHeight(32)
        raidScanButton:SetText("Scan Raid")
        raidScanButton:Show()
        raidExportButton:Hide()
        raidHeaders:Hide()
        raidGroupHeader:Hide(); raidClassHeader:Hide(); raidRankHeader:Hide()
        raidScrollFrame:Hide()
        raidStatus:SetText("")
        return
    end
    raidScanButton:Show()
    raidScanButton:ClearAllPoints()
    raidScanButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -12, -42)
    raidScanButton:SetWidth(120)
    raidScanButton:SetHeight(24)
    raidScanButton:SetText("Scan again")
    raidExportButton:Show()
    local data = MuklaOfficerSuiteDB.csr
    local members = data and data.raidMembers or {}
    raidStatus:SetText((data and data.scannedAtText or "Unknown") .. " | " .. table.getn(members) .. " raid members")
    raidHeaders:Show()
    raidGroupHeader:Show(); raidClassHeader:Show(); raidRankHeader:Show()
    raidScrollFrame:Show()
    FauxScrollFrame_Update(raidScrollFrame, table.getn(members), table.getn(raidRows), 21)
    local raidOffset = FauxScrollFrame_GetOffset(raidScrollFrame)
    for i = 1, table.getn(raidRows) do
        local member = members[raidOffset + i]
        if member then
            raidRows[i]:SetText(Short(member.name, 22))
            raidRows[i].group:SetText(tostring(member.subgroup or ""))
            raidRows[i].class:SetText(Short(member.class, 12))
            raidRows[i].rank:SetText(Short(member.guildRank ~= "" and member.guildRank or "Not in guild", 18))
            raidRows[i]:Show()
            raidRows[i].group:Show(); raidRows[i].class:Show(); raidRows[i].rank:Show()
        else
            raidRows[i]:Hide()
            raidRows[i].group:Hide(); raidRows[i].class:Hide(); raidRows[i].rank:Hide()
        end
    end
end

local function SetActiveMenuButton(activeName)
    local name, button
    for name, button in pairs(menuButtons) do
        if name == activeName then
            button:SetBackdropColor(0.32, 0.19, 0.02, 0.96)
            button:SetBackdropBorderColor(1, 0.72, 0.08, 1)
            button.label:SetTextColor(1, 0.82, 0.18)
        else
            button:SetBackdropColor(0.12, 0.07, 0.02, 0.92)
            button:SetBackdropBorderColor(0.52, 0.31, 0.07, 1)
            button.label:SetTextColor(0.95, 0.72, 0.18)
        end
    end
end

local function ShowPage(pageName)
    currentPage = pageName
    rosterPage:Hide()
    exportPage:Hide()
    statisticsPage:Hide()
    raidPage:Hide()
    csrPage:Hide()
    aboutPage:Hide()
    HideFilterPanels()
    if pageName == "roster" then
        rosterPage:Show()
        RefreshRosterPage(false)
    elseif pageName == "statistics" then
        statisticsPage:Show()
    elseif pageName == "raid" then
        raidPage:Show()
        RefreshRaidPage()
    elseif pageName == "csr" then
        csrPage:Show()
        RefreshCSRPage()
    else
        aboutPage:Show()
    end
    SetActiveMenuButton(pageName)
end

local function CreateMenuButton(name, text, y, iconPath)
    local button = CreateFrame("Button", nil, sidebar)
    button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, y)
    button:SetWidth(154)
    button:SetHeight(46)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(28)
    icon:SetHeight(28)
    icon:SetPoint("LEFT", button, "LEFT", 9, 0)
    icon:SetTexture(iconPath)

    local iconBorder = button:CreateTexture(nil, "OVERLAY")
    iconBorder:SetWidth(36)
    iconBorder:SetHeight(36)
    iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
    iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")

    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("LEFT", button, "LEFT", 44, 0)
    button.label:SetWidth(104)
    button.label:SetJustifyH("LEFT")
    button.label:SetText(text)
    button:SetScript("OnClick", function() ShowPage(name) end)
    menuButtons[name] = button
    return button
end

CreateMenuButton("roster", "Roster Management", -12, "Interface\\Icons\\INV_Misc_Book_09")
CreateMenuButton("raid", "Raid Management", -66, "Interface\\Icons\\INV_Banner_03")
CreateMenuButton("statistics", "Guild Statistics", -120, "Interface\\Icons\\INV_Misc_Book_11")
CreateMenuButton("csr", "CSR", -174, "Interface\\Icons\\INV_Misc_Note_04")
CreateMenuButton("about", "About", -228, "Interface\\Icons\\INV_Misc_QuestionMark")

local function RequestRosterScan(scanMode)
    EnsureDatabase()
    if MOS.pendingScan then
        Print("A guild data scan is already in progress.")
        return false
    end
    if not IsInGuild() then
        Print("This character is not in a guild.")
        return false
    end
    MOS.pendingScan = scanMode or "manual"
    MOS.scanStartedAt = GetTime()
    MOS.scanAttempts = 1
    rosterRequestFrame.delay = 1
    rosterRequestFrame:Show()
    GuildRoster()
    if MOS.pendingScan == "reload" or MOS.pendingScan == "csr_reload" then
        Print("Requesting guild roster. Save confirmation will appear when the scan completes...")
    else
        Print("Requesting guild roster...")
    end
    return true
end

local function StartSharedGuildScan(origin)
    if not RequestRosterScan("shared") then return end
    MOS.sharedScanOrigin = origin
    if origin == "statistics" then
        statisticsReady = false
        statisticsSummary:Hide()
        statisticsClasses:Hide()
        statisticsRanks:Hide()
        statisticsClassPanel:Hide()
        statisticsRankPanel:Hide()
        for i = 1, table.getn(statisticsClassBars) do statisticsClassBars[i].background:Hide(); statisticsClassBars[i].fill:Hide() end
        statisticsOnlyLevel60:Hide()
        statisticsLastScan:Hide()
        statisticsRefreshButton:Hide()
        statisticsScanButton:Hide()
        statisticsProgress:SetValue(0)
        statisticsProgress.text:SetText("Scanning... 0%")
        statisticsProgress:Show()
        MOS.statisticsProgressStartedAt = GetTime()
    else
        rosterScanButton:Hide()
        rosterRefreshButton:Hide()
        rosterStatusText:SetText("Scanning guild data...")
    end
end

local function QueueRosterRefresh()
    MOS.pendingScan = "quiet"
    MOS.scanStartedAt = GetTime()
    MOS.scanAttempts = 1
    rosterRequestFrame.delay = 0.75
    rosterRequestFrame:Show()
end

StaticPopupDialogs["MUKLA_OFFICER_SUITE_PROMOTE"] = {
    text = "%s",
    button1 = "Promote",
    button2 = "Cancel",
    OnAccept = function()
        if MOS.pendingGuildAction and type(GuildPromoteByName) == "function" then
            local memberName = MOS.pendingGuildAction.name
            GuildPromoteByName(memberName)
            Print("Promotion requested for " .. memberName .. ".")
            QueueRosterRefresh()
        end
        MOS.pendingGuildAction = nil
    end,
    OnCancel = function() MOS.pendingGuildAction = nil end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["MUKLA_OFFICER_SUITE_DEMOTE"] = {
    text = "%s",
    button1 = "Demote",
    button2 = "Cancel",
    OnAccept = function()
        if MOS.pendingGuildAction and type(GuildDemoteByName) == "function" then
            local memberName = MOS.pendingGuildAction.name
            GuildDemoteByName(memberName)
            Print("Demotion requested for " .. memberName .. ".")
            QueueRosterRefresh()
        end
        MOS.pendingGuildAction = nil
    end,
    OnCancel = function() MOS.pendingGuildAction = nil end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

RequestGuildAction = function(action)
    local member = GetSelectedMember()
    if not member then return end
    if action == "promote" then
        local targetRank = GetRankNameByIndex((tonumber(member.rankIndex) or 0) - 1) or "the next rank"
        MOS.pendingGuildAction = { name = member.name, action = "promote" }
        StaticPopup_Show("MUKLA_OFFICER_SUITE_PROMOTE", "Promote " .. member.name .. "?\n" .. (member.rank or "Unknown") .. " -> " .. targetRank)
    elseif action == "demote" then
        local targetRank = GetRankNameByIndex((tonumber(member.rankIndex) or 0) + 1) or "the next rank"
        MOS.pendingGuildAction = { name = member.name, action = "demote" }
        StaticPopup_Show("MUKLA_OFFICER_SUITE_DEMOTE", "Demote " .. member.name .. "?\n" .. (member.rank or "Unknown") .. " -> " .. targetRank)
    end
end

scanSaveButton:SetScript("OnClick", function() RequestRosterScan("reload") end)
raidScanButton:SetScript("OnClick", function()
    if (GetNumRaidMembers() or 0) < 1 then
        RefreshRaidPage()
        return
    end
    raidScanButton:Hide()
    raidStatus:SetText("Scanning raid and guild data...")
    RequestRosterScan("raid")
end)

raidExportButton:SetScript("OnClick", function()
    if (GetNumRaidMembers() or 0) < 1 then
        RefreshRaidPage()
        return
    end
    local count = SaveRaidRoster()
    RefreshRaidPage()
    Print("Attendance snapshot prepared. Raid members: " .. count)
    StaticPopup_Show("MUKLA_OFFICER_SUITE_ATTENDANCE_RELOAD")
end)

statisticsScanButton:SetScript("OnClick", function() StartSharedGuildScan("statistics") end)
statisticsRefreshButton:SetScript("OnClick", function() StartSharedGuildScan("statistics") end)
rosterScanButton:SetScript("OnClick", function() StartSharedGuildScan("roster") end)
rosterRefreshButton:SetScript("OnClick", function() StartSharedGuildScan("roster") end)

statisticsOnlyLevel60:SetScript("OnClick", function() RefreshStatisticsPage() end)

statisticsProgress:SetScript("OnUpdate", function()
    if MOS.statisticsProgressStartedAt and not MOS.statisticsProgressCompleteAt then
        if not MOS.pendingScan then
            MOS.statisticsProgressStartedAt = nil
            this:Hide()
            statisticsScanButton:Show()
            return
        end
        local percent = math.min(92, math.floor((GetTime() - MOS.statisticsProgressStartedAt) * 32))
        this:SetValue(percent)
        this.text:SetText("Scanning... " .. percent .. "%")
    elseif MOS.statisticsProgressCompleteAt and GetTime() - MOS.statisticsProgressCompleteAt > 0.35 then
        MOS.statisticsProgressStartedAt = nil
        MOS.statisticsProgressCompleteAt = nil
        this:Hide()
        RefreshStatisticsPage()
    end
end)

raidPage.updateDelay = 0
raidPage:SetScript("OnUpdate", function()
    this.updateDelay = this.updateDelay - arg1
    if this.updateDelay <= 0 then
        this.updateDelay = 0.5
        if not MOS.pendingScan then RefreshRaidPage() end
    end
end)
raidScrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(21, RefreshRaidPage)
end)

for i = 1, table.getn(headerButtons) do
    headerButtons[i]:SetScript("OnClick", function()
        if sortKey == this.sortKey then
            sortAscending = not sortAscending
        else
            sortKey = this.sortKey
            sortAscending = true
        end
        RefreshRosterPage(true)
    end)
end

searchBox:SetScript("OnTextChanged", function() RefreshRosterPage(true) end)
rosterScrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(rowHeight, RefreshRosterPage)
end)

dashboard:SetScript("OnShow", function() ShowPage(currentPage) end)
SetActiveMenuButton("roster")

local function ToggleDashboard()
    if dashboard:IsVisible() then
        dashboard:Hide()
    else
        dashboard:Show()
        ShowPage(currentPage)
    end
end

local minimapButton = CreateFrame("Button", "MuklaOfficerSuiteMinimapButton", Minimap)
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetWidth(20)
minimapIcon:SetHeight(20)
minimapIcon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetWidth(52)
minimapBorder:SetHeight(52)
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function PositionMinimapButton()
    EnsureDatabase()
    local angle = MuklaOfficerSuiteDB.minimap.angle or 220
    local radians = math.rad(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(radians), 80 * math.sin(radians))
end

minimapButton:SetScript("OnClick", function()
    ToggleDashboard()
end)
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Mukla Officer Suite")
    GameTooltip:AddLine("Click to open the dashboard", 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
minimapButton:SetScript("OnDragStart", function() this:SetScript("OnUpdate", function()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    x = x / scale - mx
    y = y / scale - my
    MuklaOfficerSuiteDB.minimap.angle = math.deg(math.atan2(y, x))
    PositionMinimapButton()
end) end)
minimapButton:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)

SLASH_MUKLAOFFICERSUITE1 = "/mos"
SLASH_MUKLAOFFICERSUITE2 = "/mukla"
SlashCmdList["MUKLAOFFICERSUITE"] = function(message)
    local command = string.lower(message or "")
    command = string.gsub(command, "^%s*(.-)%s*$", "%1")
    if command == "scan" then
        if not dashboard:IsVisible() then dashboard:Show() end
        ShowPage("roster")
        Print("Use Scan Guild Data or Export Roster in Roster Management.")
    elseif command == "show" or command == "open" or command == "" then
        ToggleDashboard()
    elseif command == "hide" then
        dashboard:Hide()
    elseif command == "minimap" then
        MuklaOfficerSuiteDB.minimap.hidden = not MuklaOfficerSuiteDB.minimap.hidden
        if MuklaOfficerSuiteDB.minimap.hidden then minimapButton:Hide() else minimapButton:Show() end
    elseif command == "status" then
        Print("Saved members: " .. CountSavedMembers())
    else
        Print("Commands: /mos, /mos status, /mos minimap, /mos hide")
    end
end

MOS:RegisterEvent("VARIABLES_LOADED")
MOS:RegisterEvent("GUILD_ROSTER_UPDATE")
MOS:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        EnsureDatabase()
        PositionMinimapButton()
        if MuklaOfficerSuiteDB.minimap.hidden then minimapButton:Hide() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        local scanMode = MOS.pendingScan
        if MOS.pendingScan and SaveGuildRoster() then
            RefreshRosterPage(scanMode ~= "quiet")
            RefreshExportPage()
            if scanMode == "shared" then
                rosterReady = true
                statisticsReady = true
                RefreshRosterPage(true)
                if MOS.sharedScanOrigin == "statistics" then
                    statisticsProgress:SetValue(100)
                    statisticsProgress.text:SetText("Scanning... 100%")
                    MOS.statisticsProgressCompleteAt = GetTime()
                else
                    RefreshStatisticsPage()
                end
                MOS.sharedScanOrigin = nil
            elseif scanMode == "raid" then
                local raidCount = SaveRaidRoster()
                MOS.raidScanReady = true
                RefreshRaidPage()
                Print("Raid scanned. Members: " .. raidCount)
            elseif scanMode == "reload" then
                Print("Roster scanned. Confirm the reload to save it to disk.")
                StaticPopup_Show("MUKLA_OFFICER_SUITE_RELOAD")
            elseif scanMode ~= "quiet" then
                Print("Roster scanned. Members: " .. CountSavedMembers())
            end
        end
    end
end)

Print("v" .. VERSION .. " loaded. Type /mos")
