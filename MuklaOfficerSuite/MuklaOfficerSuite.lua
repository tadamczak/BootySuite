local ADDON_NAME = "MuklaOfficerSuite"
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version") or "0.16.0"
local PREFIX = "|cff33ff99MOS|r"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message))
end

local MOS = CreateFrame("Frame", "MuklaOfficerSuiteEventFrame")
MOS.pendingScan = nil
MOS.lastRosterEvent = 0
MOS.scanStartedAt = nil
MOS.scanAttempts = 0
MOS.scanDeadline = nil

local CompletePendingGuildScan
local HandleGuildScanFailure
local scanProgress

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

    if CompletePendingGuildScan and CompletePendingGuildScan() then
        return
    end

    if MOS.scanDeadline and GetTime() >= MOS.scanDeadline then
        rosterRequestFrame.delay = nil
        rosterRequestFrame:Hide()
        MOS.pendingScan = nil
        MOS.scanStartedAt = nil
        MOS.scanAttempts = 0
        MOS.scanDeadline = nil
        if scanProgress then scanProgress:Hide() end
        Print("Guild roster could not be loaded after 15 seconds. Please try again.")
        if HandleGuildScanFailure then HandleGuildScanFailure() end
        return
    end

    if MOS.scanAttempts < 6 then
        MOS.scanAttempts = MOS.scanAttempts + 1
        rosterRequestFrame.delay = 2.5
        Print("Guild roster is still loading. Request " .. MOS.scanAttempts .. "/6...")
        GuildRoster()
        return
    end
    rosterRequestFrame.delay = 0.5
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
    if not MuklaOfficerSuiteDB.rosterData then
        return 0
    end
    return table.getn(MuklaOfficerSuiteDB.rosterData.members or {})
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

    if table.getn(members) < total then
        return false
    end

    table.sort(members, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    local scanTimestamp = time()
    local scanDuration = 0
    if MOS.scanStartedAt then
        scanDuration = GetTime() - MOS.scanStartedAt
    end
    MuklaOfficerSuiteDB.rosterData = {
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
    MuklaOfficerSuiteDB.guilds = nil
    MuklaOfficerSuiteDB.lastScanAt = scanTimestamp
    MuklaOfficerSuiteDB.lastScanAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp)
    MuklaOfficerSuiteDB.lastScanDurationSeconds = scanDuration
    MOS.pendingScan = nil
    MOS.scanStartedAt = nil
    MOS.scanAttempts = 0
    MOS.scanDeadline = nil
    rosterRequestFrame.delay = nil
    rosterRequestFrame:Hide()
    scanProgress:SetValue(100)
    scanProgress:Hide()
    return true
end

local function SaveRaidRoster()
    EnsureDatabase()
    local guildData = nil
    guildData = MuklaOfficerSuiteDB.rosterData

    local guildMembers = {}
    if guildData and guildData.members then
        local guildIndex
        for guildIndex = 1, table.getn(guildData.members) do
            guildMembers[string.lower(guildData.members[guildIndex].name or "")] = guildData.members[guildIndex]
        end
    end

    local previousLoot = {}
    local currentRaidName = GetRealZoneText() or ""
    local previousAttendance = MuklaOfficerSuiteDB.raidAttendance
    if previousAttendance and previousAttendance.raidName == currentRaidName and previousAttendance.members then
        for previousIndex = 1, table.getn(previousAttendance.members) do
            local previousMember = previousAttendance.members[previousIndex]
            previousLoot[string.lower(previousMember.name or "")] = previousMember.loot or {}
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
                subgroup = subgroup or 0,
                class = class or (guildMember and guildMember.class) or "",
                classFile = classFile or "",
                guildRank = guildMember and guildMember.rank or "",
                publicNote = guildMember and guildMember.publicNote or "",
                officerNote = guildMember and guildMember.officerNote or "",
                guildMember = guildMember and true or false,
                sr = "",
                loot = previousLoot[string.lower(name)] or {},
            })
        end
    end

    local scanTimestamp = time()
    MuklaOfficerSuiteDB.raidAttendance = {
        addonVersion = VERSION,
        scannedAt = scanTimestamp,
        scannedAtText = date("%Y-%m-%d %H:%M:%S", scanTimestamp),
        raidName = currentRaidName,
        updatedBy = UnitName("player"),
        members = members,
    }
    MuklaOfficerSuiteDB.csr = nil
    return table.getn(members)
end

local function RecordRaidLoot(message)
    local attendance = MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.raidAttendance
    if not attendance or not attendance.members or not message then return false end

    local _, _, itemLink = string.find(message, "(|c%x+|Hitem:.-|h%[.-%]|h|r)")
    if not itemLink then _, _, itemLink = string.find(message, "(|Hitem:.-|h%[.-%]|h)") end
    if not itemLink then return false end
    local recipient = nil
    if string.find(message, "You receive loot", 1, true) or string.find(message, "You receive item", 1, true) then
        recipient = UnitName("player")
    else
        local _, _, lootRecipient = string.find(message, "^([^%s]+) receives loot")
        if not lootRecipient then _, _, lootRecipient = string.find(message, "^([^%s]+) receives item") end
        recipient = lootRecipient
    end
    if not recipient then return false end

    local member = nil
    for memberIndex = 1, table.getn(attendance.members) do
        if string.lower(attendance.members[memberIndex].name or "") == string.lower(recipient) then member = attendance.members[memberIndex]; break end
    end
    if not member then return false end

    local _, _, parsedItemName = string.find(itemLink, "%[([^%]]+)%]")
    local _, _, parsedItemId = string.find(itemLink, "item:(%d+)")
    local _, _, parsedQuantity = string.find(message, "x(%d+)")
    local itemName = parsedItemName or "Unknown item"
    local itemId = parsedItemId or itemName
    local quantity = tonumber(parsedQuantity) or 1
    local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
    member.loot = member.loot or {}
    for lootIndex = 1, table.getn(member.loot) do
        if tostring(member.loot[lootIndex].itemId or member.loot[lootIndex].name) == tostring(itemId) then
            member.loot[lootIndex].count = (tonumber(member.loot[lootIndex].count) or 1) + quantity
            if itemTexture then member.loot[lootIndex].icon = itemTexture end
            return true
        end
    end
    table.insert(member.loot, { itemId = itemId, name = itemName, link = itemLink, icon = itemTexture, count = quantity })
    return true
end

local dashboard = CreateFrame("Frame", "MuklaOfficerSuiteDashboard", UIParent)
dashboard:SetWidth(840)
dashboard:SetHeight(540)
dashboard:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
dashboard:SetFrameStrata("DIALOG")
dashboard:SetMovable(true)
dashboard:SetResizable(true)
dashboard:SetMinResize(760, 420)
dashboard:SetMaxResize(1100, 760)
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

local resizeGrip = CreateFrame("Button", nil, dashboard)
resizeGrip:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -7, 7)
resizeGrip:SetWidth(18); resizeGrip:SetHeight(18)
resizeGrip:SetFrameLevel(dashboard:GetFrameLevel() + 100)
resizeGrip.texture = resizeGrip:CreateTexture(nil, "OVERLAY")
resizeGrip.texture:SetAllPoints(resizeGrip)
resizeGrip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetScript("OnMouseDown", function()
    dashboard:StartSizing("BOTTOMRIGHT")
end)
resizeGrip:SetScript("OnMouseUp", function()
    dashboard:StopMovingOrSizing()
    if MuklaOfficerSuiteDB then
        if MOS.lootMasterMode then
            MuklaOfficerSuiteDB.lootMasterWidth = dashboard:GetWidth(); MuklaOfficerSuiteDB.lootMasterHeight = dashboard:GetHeight()
        else
            MuklaOfficerSuiteDB.windowWidth = dashboard:GetWidth(); MuklaOfficerSuiteDB.windowHeight = dashboard:GetHeight()
        end
    end
end)
resizeGrip:SetScript("OnHide", function() dashboard:StopMovingOrSizing() end)

local lootMasterAlphaWatcher = CreateFrame("Frame", nil, dashboard)
lootMasterAlphaWatcher.elapsed = 0
lootMasterAlphaWatcher:SetScript("OnUpdate", function()
    if not MOS.lootMasterMode then return end
    this.elapsed = this.elapsed + arg1
    if this.elapsed < 0.08 then return end
    this.elapsed = 0
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX = cursorX / uiScale; cursorY = cursorY / uiScale
    local inside = dashboard:GetLeft() and cursorX >= dashboard:GetLeft() and cursorX <= dashboard:GetRight() and cursorY >= dashboard:GetBottom() and cursorY <= dashboard:GetTop()
    dashboard:SetAlpha(inside and 1 or 0.3)
end)

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
closeButton:SetWidth(24); closeButton:SetHeight(24)
closeButton:SetParent(titleBar)
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -4, -4)

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

scanProgress = CreateFrame("StatusBar", nil, contentPanel)
scanProgress:SetWidth(300)
scanProgress:SetHeight(22)
scanProgress:SetPoint("CENTER", contentPanel, "CENTER", 0, 8)
scanProgress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
scanProgress:SetStatusBarColor(0.72, 0.48, 0.08, 1)
scanProgress:SetMinMaxValues(0, 100)
scanProgress:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
scanProgress:SetBackdropColor(0.03, 0.03, 0.03, 0.97)
scanProgress:SetFrameLevel(contentPanel:GetFrameLevel() + 50)
scanProgress.text = scanProgress:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
scanProgress.text:SetPoint("CENTER", scanProgress, "CENTER", 0, 0)
scanProgress:Hide()
scanProgress:SetScript("OnUpdate", function()
    if MOS.pendingScan and MOS.scanStartedAt then
        local percent = math.min(94, math.floor((GetTime() - MOS.scanStartedAt) * 7))
        this:SetValue(percent)
        this.text:SetText((MOS.scanProgressLabel or "Scanning") .. "... " .. percent .. "%")
    end
end)

local rosterTitle = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rosterTitle:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -10)
rosterTitle:SetText("Roster Management")

local searchLabel = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -192, -87)
searchLabel:SetText("Search")

local searchBox = CreateFrame("EditBox", "MuklaOfficerSuiteRosterSearch", rosterPage, "InputBoxTemplate")
searchBox:SetWidth(178)
searchBox:SetHeight(20)
searchBox:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -4, -81)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

local rosterStatusText = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rosterStatusText:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -40)
rosterStatusText:SetWidth(565)
rosterStatusText:SetJustifyH("LEFT")

local rosterLastScan = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rosterLastScan:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -58)
rosterLastScan:SetWidth(330)
rosterLastScan:SetJustifyH("LEFT")

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

local rosterScanButton = CreateFrame("Button", nil, rosterPage)
rosterScanButton:SetWidth(140)
rosterScanButton:SetHeight(24)
rosterScanButton:SetPoint("CENTER", rosterPage, "CENTER", 0, 12)
StyleCompactButton(rosterScanButton, "Scan Guild Data")

local rosterRefreshButton = CreateFrame("Button", nil, rosterPage)
rosterRefreshButton:SetWidth(120)
rosterRefreshButton:SetHeight(22)
rosterRefreshButton:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -4, -48)
StyleCompactButton(rosterRefreshButton, "Refresh Data")
rosterRefreshButton:Hide()

local rosterSortHint = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rosterSortHint:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -114)
rosterSortHint:SetText("Click a column header to sort")
rosterSortHint:Hide()

local rows = {}
local rowCount = 13
local rowHeight = 20
local visibleMembers = {}
local sortKey = nil
local sortAscending = true
local selectedMemberName = nil
local selectedClasses = {}
local selectedRanks = {}
local classFilterInitialized = false
local rankFilterInitialized = false
local RefreshRosterPage
local RefreshExportPage
local RefreshStatisticsPage
local RefreshStatisticsDetails
local RefreshCSRPage
local RefreshRaidPage
local RequestGuildAction
local ToggleLootMasterMode
local menuButtons = {}
local currentPage = "roster"
local rosterReady = false
local statisticsReady = false

local filtersLabel = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
filtersLabel:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -88)
filtersLabel:SetText("Filters")

local function CreateFilterToggle(text, x)
    local button = CreateFrame("Button", nil, rosterPage)
    button:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", x, -82)
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

local classFilterToggle = CreateFilterToggle("Class", 58)
local rankFilterToggle = CreateFilterToggle("Rank", 150)

local function CreateFilterPanel(toggle)
    local panel = CreateFrame("Frame", nil, rosterPage)
    panel:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(130)
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
    button:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", x, -130)
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
    CreateHeaderButton("Name", 12, 132, "LEFT", "name"),
    CreateHeaderButton("Lvl", 149, 38, "RIGHT", "level"),
    CreateHeaderButton("Class", 197, 82, "LEFT", "class"),
    CreateHeaderButton("Rank", 289, 100, "LEFT", "rank"),
}

local notesHeader = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
notesHeader:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 399, -130)
notesHeader:SetWidth(174)
notesHeader:SetHeight(22)
notesHeader:SetJustifyH("LEFT")
notesHeader:SetText("Public / Officer note")

local i
for i = 1, rowCount do
    local row = CreateFrame("Button", nil, rosterPage)
    row:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, -134 - (i * rowHeight))
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
rosterScrollFrame:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", -4, -145)
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

local scanSaveButton = CreateFrame("Button", nil, exportPage)
scanSaveButton:SetWidth(120)
scanSaveButton:SetHeight(22)
scanSaveButton:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -220)
StyleCompactButton(scanSaveButton, "Export Roster")

local exportHint = exportPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
exportHint:SetPoint("LEFT", scanSaveButton, "RIGHT", 14, 0)
exportHint:SetWidth(350)
exportHint:SetJustifyH("LEFT")
exportHint:SetText("A confirmation dialog will reload the UI and write the roster to disk.")
exportHint:Hide()
scanSaveButton:SetParent(rosterPage)
scanSaveButton:ClearAllPoints()
scanSaveButton:SetPoint("CENTER", rosterPage, "CENTER", 96, 12)

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

local statisticsScanButton = CreateFrame("Button", nil, statisticsPage)
statisticsScanButton:SetWidth(160)
statisticsScanButton:SetHeight(24)
statisticsScanButton:SetPoint("CENTER", statisticsPage, "CENTER", 0, 12)
StyleCompactButton(statisticsScanButton, "Scan Guild Statistics")

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
statisticsClassPanel:SetHeight(270)
statisticsClassPanel:SetTexture(0.07, 0.065, 0.055, 0.82)
statisticsClassPanel:Hide()

local statisticsRankPanel = statisticsPage:CreateTexture(nil, "BACKGROUND")
statisticsRankPanel:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 300, -154)
statisticsRankPanel:SetWidth(262)
statisticsRankPanel:SetHeight(270)
statisticsRankPanel:SetTexture(0.07, 0.065, 0.055, 0.82)
statisticsRankPanel:Hide()

local statisticsClasses = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statisticsClasses:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 24, -170)
statisticsClasses:SetWidth(260)
statisticsClasses:SetJustifyH("LEFT")
statisticsClasses:SetJustifyV("TOP")
statisticsClasses:SetText("Members by class")
statisticsClasses:Hide()

local statisticsRanks = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statisticsRanks:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 316, -170)
statisticsRanks:SetWidth(255)
statisticsRanks:SetJustifyH("LEFT")
statisticsRanks:SetJustifyV("TOP")
statisticsRanks:SetText("Members by rank")
statisticsRanks:Hide()

local statisticsClassRows = {}
local statisticsRankRows = {}
for i = 1, 10 do
    local classRow = {}
    classRow.icon = statisticsPage:CreateTexture(nil, "ARTWORK")
    classRow.icon:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 24, -196 - ((i - 1) * 24))
    classRow.icon:SetWidth(20)
    classRow.icon:SetHeight(20)
    classRow.name = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    classRow.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 52, -198 - ((i - 1) * 24))
    classRow.name:SetWidth(145)
    classRow.name:SetJustifyH("LEFT")
    classRow.count = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    classRow.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 222, -198 - ((i - 1) * 24))
    classRow.count:SetWidth(38)
    classRow.count:SetJustifyH("RIGHT")
    classRow.button = CreateFrame("Button", nil, statisticsPage)
    classRow.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 20, -194 - ((i - 1) * 24))
    classRow.button:SetWidth(248); classRow.button:SetHeight(22)
    classRow.button:SetScript("OnClick", function()
        if MOS.statisticsExpandedType == "class" and MOS.statisticsExpandedValue == this.value then
            MOS.statisticsExpandedType = nil; MOS.statisticsExpandedValue = nil
        else
            MOS.statisticsExpandedType = "class"; MOS.statisticsExpandedValue = this.value
        end
        RefreshStatisticsPage()
    end)
    classRow.icon:Hide(); classRow.name:Hide(); classRow.count:Hide(); classRow.button:Hide()
    statisticsClassRows[i] = classRow

    local rankRow = {}
    rankRow.name = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rankRow.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 316, -198 - ((i - 1) * 24))
    rankRow.name:SetWidth(170)
    rankRow.name:SetJustifyH("LEFT")
    rankRow.count = statisticsPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rankRow.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 500, -198 - ((i - 1) * 24))
    rankRow.count:SetWidth(38)
    rankRow.count:SetJustifyH("RIGHT")
    rankRow.button = CreateFrame("Button", nil, statisticsPage)
    rankRow.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 312, -194 - ((i - 1) * 24))
    rankRow.button:SetWidth(230); rankRow.button:SetHeight(22)
    rankRow.button:SetScript("OnClick", function()
        if MOS.statisticsExpandedType == "rank" and MOS.statisticsExpandedValue == this.value then
            MOS.statisticsExpandedType = nil; MOS.statisticsExpandedValue = nil
        else
            MOS.statisticsExpandedType = "rank"; MOS.statisticsExpandedValue = this.value
        end
        RefreshStatisticsPage()
    end)
    rankRow.name:Hide(); rankRow.count:Hide(); rankRow.button:Hide()
    statisticsRankRows[i] = rankRow
end

local function CreateStatisticsDetailPanel(x)
    local panel = CreateFrame("Frame", nil, statisticsPage)
    panel:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", x, -154)
    panel:SetWidth(x < 100 and 272 or 262); panel:SetHeight(270)
    panel:SetFrameLevel(statisticsPage:GetFrameLevel() + 3)
    panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    panel:SetBackdropColor(0.055, 0.055, 0.048, 0.98); panel:SetBackdropBorderColor(0.34, 0.38, 0.34, 1)
    panel.title = CreateFrame("Button", nil, panel)
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -8); panel.title:SetWidth(panel:GetWidth() - 20); panel.title:SetHeight(22)
    panel.title.label = panel.title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title.label:SetAllPoints(panel.title); panel.title.label:SetJustifyH("LEFT")
    panel.title:SetScript("OnClick", function() MOS.statisticsExpandedType = nil; MOS.statisticsExpandedValue = nil; RefreshStatisticsPage() end)
    panel.nameHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.nameHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -36); panel.nameHeader:SetWidth(92); panel.nameHeader:SetJustifyH("LEFT"); panel.nameHeader:SetText("Name")
    panel.rankHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.rankHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 108, -36); panel.rankHeader:SetWidth(112); panel.rankHeader:SetJustifyH("LEFT"); panel.rankHeader:SetText("Rank")
    panel.levelHeader = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.levelHeader:SetPoint("TOPLEFT", panel, "TOPLEFT", 224, -36); panel.levelHeader:SetWidth(28); panel.levelHeader:SetJustifyH("RIGHT"); panel.levelHeader:SetText("Lvl")
    panel.rows = {}
    for detailIndex = 1, 9 do
        local line = {}
        line.name = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.name:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -58 - ((detailIndex - 1) * 21)); line.name:SetWidth(92); line.name:SetJustifyH("LEFT")
        line.rank = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.rank:SetPoint("TOPLEFT", panel, "TOPLEFT", 108, -58 - ((detailIndex - 1) * 21)); line.rank:SetWidth(112); line.rank:SetJustifyH("LEFT")
        line.level = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        line.level:SetPoint("TOPLEFT", panel, "TOPLEFT", 224, -58 - ((detailIndex - 1) * 21)); line.level:SetWidth(28); line.level:SetJustifyH("RIGHT")
        panel.rows[detailIndex] = line
    end
    panel.scroll = CreateFrame("ScrollFrame", x < 100 and "MuklaOfficerSuiteStatisticsClassScroll" or "MuklaOfficerSuiteStatisticsRankScroll", panel, "FauxScrollFrameTemplate")
    panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", -3, -50); panel.scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
    panel.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(21, RefreshStatisticsDetails) end)
    panel:Hide()
    return panel
end
local statisticsClassDetail = CreateStatisticsDetailPanel(12)
local statisticsRankDetail = CreateStatisticsDetailPanel(300)

local CLASS_ICONS

local function CreateStatisticsTable(name, x, width)
    local statsTable = { entries = {}, rows = {} }
    statsTable.scroll = CreateFrame("ScrollFrame", name, statisticsPage, "FauxScrollFrameTemplate")
    statsTable.scroll:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", x - 4, -190)
    statsTable.scroll:SetWidth(width); statsTable.scroll:SetHeight(224)
    for rowIndex = 1, 9 do
        local row = CreateFrame("Button", nil, statisticsPage)
        row:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", x, -194 - ((rowIndex - 1) * 24))
        row:SetWidth(width - 16); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        row:SetBackdropColor(0, 0, 0, 0); row:SetBackdropBorderColor(0, 0, 0, 0)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetPoint("LEFT", row, "LEFT", 0, 0); row.icon:SetWidth(20); row.icon:SetHeight(20)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row, "LEFT", 28, 0); row.name:SetWidth(132); row.name:SetJustifyH("LEFT")
        row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.rank:SetPoint("LEFT", row, "LEFT", 100, 0); row.rank:SetWidth(116); row.rank:SetJustifyH("LEFT")
        row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.level:SetPoint("RIGHT", row, "RIGHT", -2, 0); row.level:SetWidth(25); row.level:SetJustifyH("RIGHT")
        row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.count:SetPoint("RIGHT", row, "RIGHT", -2, 0); row.count:SetWidth(35); row.count:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function()
            if not this.entry or this.entry.kind ~= "summary" then return end
            if MOS.statisticsExpandedType == this.entry.statsType and MOS.statisticsExpandedValue == this.entry.value then
                MOS.statisticsExpandedType = nil; MOS.statisticsExpandedValue = nil
            else
                MOS.statisticsExpandedType = this.entry.statsType; MOS.statisticsExpandedValue = this.entry.value
            end
            RefreshStatisticsPage()
        end)
        row:Hide(); statsTable.rows[rowIndex] = row
    end
    statsTable.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, RefreshStatisticsPage) end)
    statsTable.scroll:Hide()
    return statsTable
end

local statisticsClassTable = CreateStatisticsTable("MuklaOfficerSuiteStatisticsClassTableScroll", 24, 252)
local statisticsRankTable = CreateStatisticsTable("MuklaOfficerSuiteStatisticsRankTableScroll", 316, 238)

local function PopulateStatisticsTable(statsTable, summaries, statsType, data, onlyLevel60)
    local entries = {}
    for summaryIndex = 1, table.getn(summaries) do
        local summary = summaries[summaryIndex]
        table.insert(entries, { kind = "summary", statsType = statsType, value = summary.name, count = summary.count })
        if MOS.statisticsExpandedType == statsType and MOS.statisticsExpandedValue == summary.name then
            local members = {}
            for memberIndex = 1, table.getn(data.members) do
                local member = data.members[memberIndex]
                local matches = (statsType == "class" and member.class == summary.name) or (statsType == "rank" and member.rank == summary.name)
                if matches and (not onlyLevel60 or tonumber(member.level) == 60) then table.insert(members, member) end
            end
            table.sort(members, function(a, b)
                local aRank, bRank = tonumber(a.rankIndex) or 999, tonumber(b.rankIndex) or 999
                if aRank == bRank then return string.lower(a.name or "") < string.lower(b.name or "") end
                return aRank < bRank
            end)
            for memberIndex = 1, table.getn(members) do table.insert(entries, { kind = "member", member = members[memberIndex] }) end
        end
    end
    statsTable.entries = entries
    FauxScrollFrame_Update(statsTable.scroll, table.getn(entries), table.getn(statsTable.rows), 24)
    local offset = FauxScrollFrame_GetOffset(statsTable.scroll)
    for rowIndex = 1, table.getn(statsTable.rows) do
        local row = statsTable.rows[rowIndex]
        local entry = entries[offset + rowIndex]
        row.entry = entry
        if entry then
            local isExpandedSummary = entry.kind == "summary" and MOS.statisticsExpandedType == statsType and MOS.statisticsExpandedValue == entry.value
            if isExpandedSummary then
                row:SetBackdropColor(0.16, 0.20, 0.17, 0.82); row:SetBackdropBorderColor(0.46, 0.55, 0.47, 0.90)
            elseif math.mod(offset + rowIndex, 2) == 0 then
                row:SetBackdropColor(1, 0.78, 0.25, 0.075); row:SetBackdropBorderColor(0, 0, 0, 0)
            else
                row:SetBackdropColor(0, 0, 0, 0); row:SetBackdropBorderColor(0, 0, 0, 0)
            end
            if entry.kind == "summary" then
                row.icon:SetTexture(statsType == "class" and (CLASS_ICONS[entry.value] or "Interface\\Icons\\INV_Misc_QuestionMark") or nil)
                if statsType == "class" then row.icon:Show() else row.icon:Hide() end
                row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", statsType == "class" and 28 or 0, 0)
                row.name:SetWidth(statsType == "class" and 132 or 180)
                row.name:SetText(entry.value .. ((MOS.statisticsExpandedType == statsType and MOS.statisticsExpandedValue == entry.value) and "  ^" or ""))
                row.count:SetText(entry.count); row.count:Show(); row.rank:Hide(); row.level:Hide()
            else
                row.icon:Hide(); row.count:Hide()
                row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 12, 0); row.name:SetWidth(82); row.name:SetText(Short(entry.member.name, 12))
                row.rank:SetWidth(onlyLevel60 and 116 or 96); row.rank:SetText(Short(entry.member.rank, 18)); row.rank:Show()
                if onlyLevel60 then row.level:Hide() else row.level:SetText(entry.member.level or ""); row.level:Show() end
            end
            row:Show()
        else row:Hide() end
    end
    statsTable.scroll:Show()
end

local raidTitle = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
raidTitle:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -10)
raidTitle:SetText("Raid Management")

local raidModeButton = CreateFrame("Button", nil, raidPage)
raidModeButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -8)
raidModeButton:SetWidth(118); raidModeButton:SetHeight(22)
StyleCompactButton(raidModeButton, "Loot Master Mode")
raidModeButton:SetScript("OnClick", function() ToggleLootMasterMode() end)

local raidInfo = raidPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
raidInfo:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -12, -15)
raidInfo:SetText("")
raidInfo:Hide()

local raidSearchLabel = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
raidSearchLabel:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -192, -82)
raidSearchLabel:SetText("Search")
raidSearchLabel:Hide()
local raidSearchBox = CreateFrame("EditBox", "MuklaOfficerSuiteRaidSearch", raidPage, "InputBoxTemplate")
raidSearchBox:SetWidth(178); raidSearchBox:SetHeight(20)
raidSearchBox:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -76)
raidSearchBox:SetAutoFocus(false)
raidSearchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
raidSearchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
raidSearchBox:Hide()

local raidFilterLabel = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
raidFilterLabel:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -82)
raidFilterLabel:SetText("Filters")
raidFilterLabel:Hide()

local function CreateRaidFilterButton(text, x)
    local button = CreateFrame("Button", nil, raidPage)
    button:SetPoint("TOPLEFT", raidPage, "TOPLEFT", x, -76)
    button:SetWidth(84); button:SetHeight(19)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.08, 0.07, 0.05, 0.95); button:SetBackdropBorderColor(0.42, 0.35, 0.20, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button, "LEFT", 8, 0); button.label:SetText(text)
    button.SetText = function(self, value) self.label:SetText(value) end
    button.arrow = button:CreateTexture(nil, "OVERLAY")
    button.arrow:SetWidth(14); button.arrow:SetHeight(14)
    button.arrow:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    button.arrow:SetTexCoord(0.20, 0.80, 0.20, 0.80)
    button:Hide()
    return button
end
local raidClassFilterButton = CreateRaidFilterButton("Class", 58)
local raidRankFilterButton = CreateRaidFilterButton("Rank", 150)

local function CreateRaidFilterPanel(button)
    local panel = CreateFrame("Frame", nil, raidPage)
    panel:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(130); panel:SetHeight(80)
    panel:SetFrameLevel(raidPage:GetFrameLevel() + 25)
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    panel:SetBackdropColor(0.04, 0.03, 0.02, 0.98)
    panel.options = {}
    panel:Hide()
    return panel
end
local raidClassFilterPanel = CreateRaidFilterPanel(raidClassFilterButton)
local raidRankFilterPanel = CreateRaidFilterPanel(raidRankFilterButton)
local selectedRaidClasses, selectedRaidRanks = {}, {}
local raidFiltersInitialized = false
local raidSortKey, raidSortAscending = nil, true
local visibleRaidMembers = {}
local selectedRaidMemberName = nil

local raidUnavailable = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
raidUnavailable:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
raidUnavailable:SetText("You must be in a raid to scan the raid roster.")

local raidScanButton = CreateFrame("Button", nil, raidPage)
raidScanButton:SetWidth(140)
raidScanButton:SetHeight(24)
raidScanButton:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
StyleCompactButton(raidScanButton, "Scan Raid")
raidScanButton:Hide()

local raidExportButton = CreateFrame("Button", nil, raidPage)
raidExportButton:SetWidth(118)
raidExportButton:SetHeight(22)
raidExportButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -110, -42)
StyleCompactButton(raidExportButton, "Export Attendance")
raidExportButton:Hide()

local raidImportButton = CreateFrame("Button", nil, raidPage)
raidImportButton:SetWidth(82); raidImportButton:SetHeight(22)
raidImportButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -236, -42)
StyleCompactButton(raidImportButton, "Import SR")
raidImportButton:Hide()
raidImportButton:SetScript("OnClick", function() end)

local raidStatus = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
raidStatus:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -48)
raidStatus:SetWidth(245)
raidStatus:SetJustifyH("LEFT")

local raidHeaders = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidHeaders:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -110)
raidHeaders:SetWidth(155)
raidHeaders:SetJustifyH("LEFT")
raidHeaders:SetText("Name")
raidHeaders:Hide()

local raidGroupHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidGroupHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 172, -110)
raidGroupHeader:SetWidth(70)
raidGroupHeader:SetJustifyH("CENTER")
raidGroupHeader:SetText("Group")
raidGroupHeader:Hide()
local raidClassHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidClassHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 252, -110)
raidClassHeader:SetWidth(85)
raidClassHeader:SetJustifyH("LEFT")
raidClassHeader:SetText("Class")
raidClassHeader:Hide()
local raidRankHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidRankHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 347, -110)
raidRankHeader:SetWidth(135)
raidRankHeader:SetJustifyH("LEFT")
raidRankHeader:SetText("Guild rank")
raidRankHeader:Hide()

local raidSRHeader = raidPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidSRHeader:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 500, -110)
raidSRHeader:SetWidth(55); raidSRHeader:SetJustifyH("LEFT"); raidSRHeader:SetText("SR"); raidSRHeader:Hide()

local raidHeaderButtons = {}
local function AddRaidHeaderButton(label, baseText, key, x, width)
    local button = CreateFrame("Button", nil, raidPage)
    button:SetPoint("TOPLEFT", raidPage, "TOPLEFT", x, -106)
    button:SetWidth(width); button:SetHeight(22)
    button.label = label; button.baseText = baseText; button.sortKey = key
    button:SetScript("OnClick", function()
        if raidSortKey ~= this.sortKey then raidSortKey = this.sortKey; raidSortAscending = true
        elseif raidSortAscending then raidSortAscending = false
        else raidSortKey = nil; raidSortAscending = true end
        RefreshRaidPage()
    end)
    button:Hide()
    table.insert(raidHeaderButtons, button)
end
AddRaidHeaderButton(raidHeaders, "Name", "name", 12, 155)
AddRaidHeaderButton(raidGroupHeader, "Group", "subgroup", 172, 70)
AddRaidHeaderButton(raidClassHeader, "Class", "class", 252, 85)
AddRaidHeaderButton(raidRankHeader, "Guild rank", "guildRank", 347, 138)
AddRaidHeaderButton(raidSRHeader, "SR", "sr", 500, 55)

local raidRows = {}
for i = 1, 15 do
    local raidRow = CreateFrame("Button", nil, raidPage)
    raidRow:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -132 - ((i - 1) * 21))
    raidRow:SetWidth(543)
    raidRow:SetHeight(20)
    raidRow.name = raidRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.name:SetPoint("TOPLEFT", raidRow, "TOPLEFT", 7, 0)
    raidRow.name:SetWidth(148); raidRow.name:SetHeight(20); raidRow.name:SetJustifyH("LEFT")
    raidRow.group = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.group:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 172, -132 - ((i - 1) * 21))
    raidRow.group:SetWidth(70)
    raidRow.group:SetHeight(20)
    raidRow.group:SetJustifyH("CENTER")
    raidRow.class = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.class:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 252, -132 - ((i - 1) * 21))
    raidRow.class:SetWidth(85)
    raidRow.class:SetHeight(20)
    raidRow.class:SetJustifyH("LEFT")
    raidRow.rank = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.rank:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 347, -132 - ((i - 1) * 21))
    raidRow.rank:SetWidth(135)
    raidRow.rank:SetHeight(20)
    raidRow.rank:SetJustifyH("LEFT")
    raidRow.sr = raidPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    raidRow.sr:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 500, -132 - ((i - 1) * 21))
    raidRow.sr:SetWidth(55); raidRow.sr:SetHeight(20); raidRow.sr:SetJustifyH("LEFT")
    raidRow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    raidRow:SetBackdropColor(0, 0, 0, 0); raidRow:SetBackdropBorderColor(0, 0, 0, 0)
    raidRow.lootPanel = CreateFrame("Frame", nil, raidRow)
    raidRow.lootPanel:SetPoint("TOPLEFT", raidRow, "TOPLEFT", 4, -21)
    raidRow.lootPanel:SetWidth(535); raidRow.lootPanel:SetHeight(106)
    raidRow.lootPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    raidRow.lootPanel:SetBackdropColor(0.07, 0.08, 0.07, 0.94); raidRow.lootPanel:SetBackdropBorderColor(0.30, 0.34, 0.30, 1)
    raidRow.lootTitle = raidRow.lootPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    raidRow.lootTitle:SetPoint("TOPLEFT", raidRow.lootPanel, "TOPLEFT", 10, -8); raidRow.lootTitle:SetText("Loot received")
    raidRow.lootEmpty = raidRow.lootPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    raidRow.lootEmpty:SetPoint("TOPLEFT", raidRow.lootPanel, "TOPLEFT", 10, -34); raidRow.lootEmpty:SetText("No recorded items.")
    raidRow.lootRows = {}
    for lootIndex = 1, 3 do
        local lootRow = {}
        lootRow.icon = raidRow.lootPanel:CreateTexture(nil, "ARTWORK")
        lootRow.icon:SetPoint("TOPLEFT", raidRow.lootPanel, "TOPLEFT", 10, -28 - ((lootIndex - 1) * 24)); lootRow.icon:SetWidth(20); lootRow.icon:SetHeight(20)
        lootRow.name = raidRow.lootPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lootRow.name:SetPoint("LEFT", lootRow.icon, "RIGHT", 7, 0); lootRow.name:SetWidth(455); lootRow.name:SetJustifyH("LEFT")
        raidRow.lootRows[lootIndex] = lootRow
    end
    raidRow.lootScroll = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRaidLootScroll" .. i, raidRow.lootPanel, "FauxScrollFrameTemplate")
    raidRow.lootScroll:SetPoint("TOPLEFT", raidRow.lootPanel, "TOPLEFT", -3, -24); raidRow.lootScroll:SetPoint("BOTTOMRIGHT", raidRow.lootPanel, "BOTTOMRIGHT", -12, 8)
    raidRow.lootScroll.ownerRow = raidRow
    raidRow.lootScroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, RefreshRaidPage) end)
    raidRow.lootPanel:Hide()
    raidRow:SetScript("OnClick", function()
        if not this.displayedMember then return end
        if selectedRaidMemberName == this.displayedMember.name then
            selectedRaidMemberName = nil
            if MOS.raidHeightBeforeExpansion then dashboard:SetHeight(MOS.raidHeightBeforeExpansion); MOS.raidHeightBeforeExpansion = nil end
        else
            if not selectedRaidMemberName and MOS.lootMasterMode and dashboard:GetHeight() < 320 then
                MOS.raidHeightBeforeExpansion = dashboard:GetHeight(); dashboard:SetHeight(320)
            end
            selectedRaidMemberName = this.displayedMember.name
        end
        RefreshRaidPage()
    end)
    raidRow:Hide()
    raidRow.name:Hide()
    raidRow.group:Hide()
    raidRow.class:Hide()
    raidRow.rank:Hide(); raidRow.sr:Hide()
    raidRows[i] = raidRow
end

local raidScrollFrame = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRaidScrollFrame", raidPage, "FauxScrollFrameTemplate")
raidScrollFrame:SetPoint("TOPLEFT", raidPage, "TOPLEFT", -4, -121)
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
aboutTitle:Hide()

local aboutArtwork = aboutPage:CreateTexture(nil, "ARTWORK")
aboutArtwork:SetPoint("TOPRIGHT", aboutPage, "TOPRIGHT", -4, -4)
aboutArtwork:SetPoint("BOTTOMRIGHT", aboutPage, "BOTTOMRIGHT", -4, 4)
aboutArtwork:SetWidth(382)
aboutArtwork:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\AboutArtwork")
aboutArtwork:SetTexCoord(0.066, 0.934, 0, 1)
aboutArtwork:SetAlpha(0.88)

local aboutName = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
aboutName:SetPoint("CENTER", aboutPage, "LEFT", 105, 34)
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
    if not MuklaOfficerSuiteDB.rosterData and key and type(MuklaOfficerSuiteDB.guilds) == "table" then
        MuklaOfficerSuiteDB.rosterData = MuklaOfficerSuiteDB.guilds[key]
    end
    MuklaOfficerSuiteDB.guilds = nil
    return MuklaOfficerSuiteDB.rosterData, guildName
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
            checkbox.label:SetWidth(80)
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
    if not sortKey then
        return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or ""))
    end
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
        scanSaveButton:Hide()
        HideFilterPanels()
        for i = 1, table.getn(rows) do rows[i]:Hide() end
    else
        scanSaveButton:ClearAllPoints()
        scanSaveButton:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -128, -48)
        scanSaveButton:SetWidth(120)
        scanSaveButton:SetHeight(22)
        scanSaveButton:Show()
    end
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
    -- The expanded action area consumes the space of two regular rows. Reduce
    -- the visible capacity so the final records stay inside the table frame.
    local visibleRowCount = selectedMemberName and (rowCount - 2) or rowCount
    FauxScrollFrame_Update(rosterScrollFrame, table.getn(visibleMembers), visibleRowCount, rowHeight)
    local offset = FauxScrollFrame_GetOffset(rosterScrollFrame)

    local rowY = -154
    for i = 1, rowCount do
        local member = visibleMembers[offset + i]
        rows[i]:ClearAllPoints()
        rows[i]:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 12, rowY)
        if member and i <= visibleRowCount then
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

CLASS_ICONS = {
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
    local classNames = {}
    statisticsClasses:SetText("Members by class")
    statisticsRanks:SetText("Members by rank")
    -- Restore the compact row layout before applying an optional inline expansion.
    for i = 1, table.getn(statisticsClassRows) do
        local classRow = statisticsClassRows[i]
        classRow.icon:ClearAllPoints(); classRow.icon:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 24, -196 - ((i - 1) * 24))
        classRow.name:ClearAllPoints(); classRow.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 52, -198 - ((i - 1) * 24))
        classRow.count:ClearAllPoints(); classRow.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 222, -198 - ((i - 1) * 24))
        classRow.button:ClearAllPoints(); classRow.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 20, -194 - ((i - 1) * 24))
        local rankRow = statisticsRankRows[i]
        rankRow.name:ClearAllPoints(); rankRow.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 316, -198 - ((i - 1) * 24))
        rankRow.count:ClearAllPoints(); rankRow.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 500, -198 - ((i - 1) * 24))
        rankRow.button:ClearAllPoints(); rankRow.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 312, -194 - ((i - 1) * 24))
    end
    local className, classCount
    for className, classCount in pairs(classes) do
        table.insert(classNames, className)
    end
    table.sort(classNames, function(a, b) return string.lower(a) < string.lower(b) end)
    for i = 1, table.getn(statisticsClassRows) do
        local row = statisticsClassRows[i]
        if classNames[i] then
            row.icon:SetTexture(CLASS_ICONS[classNames[i]] or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(classNames[i])
            row.count:SetText(classes[classNames[i]])
            row.button.value = classNames[i]
            row.icon:Show(); row.name:Show(); row.count:Show(); row.button:Show()
        else
            row.icon:Hide(); row.name:Hide(); row.count:Hide(); row.button:Hide()
        end
    end
    local rankList = {}
    local rankName, rankData
    for rankName, rankData in pairs(ranks) do table.insert(rankList, { name = rankName, count = rankData.count, index = rankData.index }) end
    table.sort(rankList, function(a, b)
        if a.index == b.index then return string.lower(a.name) < string.lower(b.name) end
        return a.index < b.index
    end)
    for i = 1, table.getn(statisticsRankRows) do
        local row = statisticsRankRows[i]
        if rankList[i] then
            row.name:SetText(rankList[i].name)
            row.count:SetText(rankList[i].count)
            row.button.value = rankList[i].name
            row.name:Show(); row.count:Show(); row.button:Show()
        else
            row.name:Hide(); row.count:Hide(); row.button:Hide()
        end
    end
    local classSummaries = {}
    for i = 1, table.getn(classNames) do table.insert(classSummaries, { name = classNames[i], count = classes[classNames[i]] }) end
    PopulateStatisticsTable(statisticsClassTable, classSummaries, "class", data, onlyLevel60)
    PopulateStatisticsTable(statisticsRankTable, rankList, "rank", data, onlyLevel60)
    for i = 1, table.getn(statisticsClassRows) do
        statisticsClassRows[i].icon:Hide(); statisticsClassRows[i].name:Hide(); statisticsClassRows[i].count:Hide(); statisticsClassRows[i].button:Hide()
        statisticsRankRows[i].name:Hide(); statisticsRankRows[i].count:Hide(); statisticsRankRows[i].button:Hide()
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
    statisticsClassDetail:Hide(); statisticsRankDetail:Hide()
end

RefreshStatisticsDetails = function()
    statisticsClassDetail:Hide(); statisticsRankDetail:Hide()
    if not MOS.statisticsExpandedType or not MOS.statisticsExpandedValue then return end
    local data = GetCurrentGuildData()
    if not data or not data.members then return end
    local onlyLevel60 = statisticsOnlyLevel60:GetChecked()
    local matches = {}
    for i = 1, table.getn(data.members) do
        local member = data.members[i]
        local matchesType = (MOS.statisticsExpandedType == "class" and member.class == MOS.statisticsExpandedValue) or (MOS.statisticsExpandedType == "rank" and member.rank == MOS.statisticsExpandedValue)
        if matchesType and (not onlyLevel60 or tonumber(member.level) == 60) then table.insert(matches, member) end
    end
    table.sort(matches, function(a, b) return string.lower(a.name or "") < string.lower(b.name or "") end)
    local isClass = MOS.statisticsExpandedType == "class"
    local panel = isClass and statisticsClassDetail or statisticsRankDetail
    local sourceRows = isClass and statisticsClassRows or statisticsRankRows
    local selectedIndex = 1
    for i = 1, table.getn(sourceRows) do
        if sourceRows[i].button.value == MOS.statisticsExpandedValue then selectedIndex = i; break end
    end
    local displayedRows = math.min(table.getn(matches), 5)
    local panelHeight = 54 + (displayedRows * 21)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", isClass and 12 or 300, -194 - (selectedIndex * 24))
    panel:SetHeight(panelHeight)
    panel.title.label:SetText(MOS.statisticsExpandedValue .. " (" .. table.getn(matches) .. ")  ^")
    if onlyLevel60 then panel.levelHeader:Hide() else panel.levelHeader:Show() end
    FauxScrollFrame_Update(panel.scroll, table.getn(matches), displayedRows, 21)
    local detailOffset = FauxScrollFrame_GetOffset(panel.scroll)
    for i = 1, table.getn(panel.rows) do
        local member = matches[detailOffset + i]
        local line = panel.rows[i]
        if member and i <= displayedRows then
            line.name:SetText(Short(member.name, 14)); line.rank:SetText(Short(member.rank, 16)); line.level:SetText(tostring(member.level or ""))
            line.name:Show(); line.rank:Show(); if onlyLevel60 then line.level:Hide() else line.level:Show() end
        else line.name:Hide(); line.rank:Hide(); line.level:Hide() end
    end
    panel:Show()

    -- Push the following summary rows down, matching the expandable roster-row
    -- interaction instead of covering the list with a floating window.
    local extra = panelHeight + 4
    for i = selectedIndex + 1, table.getn(sourceRows) do
        local row = sourceRows[i]
        local baseY = -194 - ((i - 1) * 24) - extra
        if isClass then
            row.icon:ClearAllPoints(); row.icon:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 24, baseY - 2)
            row.name:ClearAllPoints(); row.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 52, baseY - 4)
            row.count:ClearAllPoints(); row.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 222, baseY - 4)
            row.button:ClearAllPoints(); row.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 20, baseY)
        else
            row.name:ClearAllPoints(); row.name:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 316, baseY - 4)
            row.count:ClearAllPoints(); row.count:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 500, baseY - 4)
            row.button:ClearAllPoints(); row.button:SetPoint("TOPLEFT", statisticsPage, "TOPLEFT", 312, baseY)
        end
    end
end

RefreshCSRPage = function()
end

local function RefreshRaidFilterOptions(panel, values, selected)
    table.sort(values, function(a, b) return string.lower(a) < string.lower(b) end)
    local widest = 0
    for i = 1, table.getn(values) do widest = math.max(widest, string.len(tostring(values[i]))) end
    local panelWidth = math.max(112, math.min(190, 42 + (widest * 7)))
    panel:SetWidth(panelWidth)
    panel:SetHeight(38 + table.getn(values) * 20)
    if not panel.selectAll then
        panel.selectAll = CreateFrame("Button", nil, panel)
        panel.selectAll:SetWidth(82); panel.selectAll:SetHeight(18)
        panel.selectAll:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 9)
        StyleCompactButton(panel.selectAll, "Select all")
        panel.selectAll:SetScript("OnClick", function()
            for i = 1, table.getn(this:GetParent().values) do selected[this:GetParent().values[i]] = true end
            RefreshRaidPage()
        end)
    end
    panel.values = values
    for i = 1, table.getn(values) do
        local option = panel.options[i]
        if not option then
            option = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            option:SetWidth(20); option:SetHeight(20)
            option:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10 - ((i - 1) * 20))
            option.label = option:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            option.label:SetPoint("LEFT", option, "RIGHT", 2, 0); option.label:SetWidth(panelWidth - 42); option.label:SetHeight(18); option.label:SetJustifyH("LEFT")
            option:SetScript("OnClick", function() selected[this.value] = this:GetChecked() and true or false; RefreshRaidPage() end)
            panel.options[i] = option
        end
        option.value = values[i]; option.label:SetText(values[i]); option:SetChecked(selected[values[i]] and true or false); option:Show()
    end
    for i = table.getn(values) + 1, table.getn(panel.options) do panel.options[i]:Hide() end
end

local function BuildRaidFilters(members)
    local classes, ranks, seenClasses, seenRanks = {}, {}, {}, {}
    for i = 1, table.getn(members) do
        local className = members[i].class ~= "" and members[i].class or "Unknown"
        local rankName = members[i].guildRank ~= "" and members[i].guildRank or "Not in guild"
        if not seenClasses[className] then seenClasses[className] = true; table.insert(classes, className) end
        if not seenRanks[rankName] then seenRanks[rankName] = true; table.insert(ranks, rankName) end
    end
    if not raidFiltersInitialized then
        for i = 1, table.getn(classes) do selectedRaidClasses[classes[i]] = true end
        for i = 1, table.getn(ranks) do selectedRaidRanks[ranks[i]] = true end
        raidFiltersInitialized = true
    end
    for i = 1, table.getn(classes) do if selectedRaidClasses[classes[i]] == nil then selectedRaidClasses[classes[i]] = true end end
    for i = 1, table.getn(ranks) do if selectedRaidRanks[ranks[i]] == nil then selectedRaidRanks[ranks[i]] = true end end
    RefreshRaidFilterOptions(raidClassFilterPanel, classes, selectedRaidClasses)
    RefreshRaidFilterOptions(raidRankFilterPanel, ranks, selectedRaidRanks)
end

raidClassFilterButton:SetScript("OnClick", function() raidRankFilterPanel:Hide(); if raidClassFilterPanel:IsVisible() then raidClassFilterPanel:Hide() else raidClassFilterPanel:Show() end end)
raidRankFilterButton:SetScript("OnClick", function() raidClassFilterPanel:Hide(); if raidRankFilterPanel:IsVisible() then raidRankFilterPanel:Hide() else raidRankFilterPanel:Show() end end)

local function SortRaidMembers(a, b)
    if not raidSortKey then
        if (tonumber(a.subgroup) or 0) == (tonumber(b.subgroup) or 0) then return string.lower(a.name or "") < string.lower(b.name or "") end
        return (tonumber(a.subgroup) or 0) < (tonumber(b.subgroup) or 0)
    end
    local av, bv = a[raidSortKey] or "", b[raidSortKey] or ""
    if raidSortKey == "subgroup" then av, bv = tonumber(av) or 0, tonumber(bv) or 0 else av, bv = string.lower(tostring(av)), string.lower(tostring(bv)) end
    if av == bv then av, bv = string.lower(a.name or ""), string.lower(b.name or "") end
    if raidSortAscending then return av < bv end
    return av > bv
end

RefreshRaidPage = function()
    local inRaid = (GetNumRaidMembers() or 0) > 0
    if not inRaid then
        MOS.raidScanReady = false
        raidUnavailable:Show()
        raidScanButton:Hide()
        raidExportButton:Hide()
        raidImportButton:Hide()
        raidSearchLabel:Hide(); raidSearchBox:Hide(); raidFilterLabel:Hide(); raidClassFilterButton:Hide(); raidRankFilterButton:Hide(); raidClassFilterPanel:Hide(); raidRankFilterPanel:Hide()
        raidHeaders:Hide()
        raidGroupHeader:Hide(); raidClassHeader:Hide(); raidRankHeader:Hide(); raidSRHeader:Hide()
        for i = 1, table.getn(raidHeaderButtons) do raidHeaderButtons[i]:Hide() end
        raidScrollFrame:Hide()
        raidStatus:SetText("")
        for i = 1, table.getn(raidRows) do raidRows[i]:Hide(); raidRows[i].name:Hide(); raidRows[i].group:Hide(); raidRows[i].class:Hide(); raidRows[i].rank:Hide(); raidRows[i].sr:Hide(); raidRows[i].lootPanel:Hide() end
        return
    end
    raidUnavailable:Hide()
    if not MOS.raidScanReady then
        raidScanButton:ClearAllPoints()
        raidScanButton:SetPoint("CENTER", raidPage, "CENTER", 0, 12)
        raidScanButton:SetWidth(140)
        raidScanButton:SetHeight(24)
        raidScanButton:SetText("Scan Raid")
        raidScanButton:Show()
        raidExportButton:Hide()
        raidImportButton:Hide()
        raidSearchLabel:Hide(); raidSearchBox:Hide(); raidFilterLabel:Hide(); raidClassFilterButton:Hide(); raidRankFilterButton:Hide()
        raidHeaders:Hide()
        raidGroupHeader:Hide(); raidClassHeader:Hide(); raidRankHeader:Hide(); raidSRHeader:Hide()
        for i = 1, table.getn(raidHeaderButtons) do raidHeaderButtons[i]:Hide() end
        raidScrollFrame:Hide()
        raidStatus:SetText("")
        return
    end
    raidScanButton:Show()
    raidScanButton:ClearAllPoints()
    raidScanButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -42)
    raidScanButton:SetWidth(98)
    raidScanButton:SetHeight(22)
    raidScanButton:SetText("Scan again")
    if MOS.lootMasterMode then raidExportButton:Hide(); raidImportButton:Hide() else raidExportButton:Show(); raidImportButton:Show() end
    local data = MuklaOfficerSuiteDB.raidAttendance
    local members = data and data.members or {}
    BuildRaidFilters(members)
    local query = string.lower(raidSearchBox:GetText() or "")
    visibleRaidMembers = {}
    for i = 1, table.getn(members) do
        local member = members[i]
        local className = member.class ~= "" and member.class or "Unknown"
        local rankName = member.guildRank ~= "" and member.guildRank or "Not in guild"
        local searchable = string.lower((member.name or "") .. " " .. tostring(member.subgroup or "") .. " " .. className .. " " .. rankName .. " " .. tostring(member.sr or ""))
        if selectedRaidClasses[className] and selectedRaidRanks[rankName] and (query == "" or string.find(searchable, query, 1, true)) then table.insert(visibleRaidMembers, member) end
    end
    table.sort(visibleRaidMembers, SortRaidMembers)
    local selectedRaidMemberVisible = false
    for i = 1, table.getn(visibleRaidMembers) do
        if visibleRaidMembers[i].name == selectedRaidMemberName then selectedRaidMemberVisible = true; break end
    end
    if not selectedRaidMemberVisible then
        selectedRaidMemberName = nil
        if MOS.raidHeightBeforeExpansion then dashboard:SetHeight(MOS.raidHeightBeforeExpansion); MOS.raidHeightBeforeExpansion = nil end
    end
    raidStatus:SetText((data and data.scannedAtText or "Unknown") .. " | showing " .. table.getn(visibleRaidMembers) .. " of " .. table.getn(members) .. " raid members")
    if MOS.lootMasterMode then raidStatus:Hide() else raidStatus:Show() end
    if MOS.lootMasterMode then
        raidFilterLabel:ClearAllPoints(); raidFilterLabel:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 8, -14)
        raidClassFilterButton:ClearAllPoints(); raidClassFilterButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 50, -8); raidClassFilterButton:SetWidth(76)
        raidRankFilterButton:ClearAllPoints(); raidRankFilterButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 132, -8); raidRankFilterButton:SetWidth(76)
        raidModeButton:ClearAllPoints(); raidModeButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 214, -8); raidModeButton:SetWidth(112)
        raidScanButton:ClearAllPoints(); raidScanButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 332, -8); raidScanButton:SetWidth(88)
        raidSearchLabel:ClearAllPoints(); raidSearchLabel:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 428, -14)
        raidSearchBox:ClearAllPoints(); raidSearchBox:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 478, -8); raidSearchBox:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -8, -8); raidSearchBox:SetWidth(140)
    else
        raidFilterLabel:ClearAllPoints(); raidFilterLabel:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, -82)
        raidClassFilterButton:ClearAllPoints(); raidClassFilterButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 58, -76); raidClassFilterButton:SetWidth(84)
        raidRankFilterButton:ClearAllPoints(); raidRankFilterButton:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 150, -76); raidRankFilterButton:SetWidth(84)
        raidModeButton:ClearAllPoints(); raidModeButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -8); raidModeButton:SetWidth(118)
        raidScanButton:ClearAllPoints(); raidScanButton:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -42); raidScanButton:SetWidth(98)
        raidSearchLabel:ClearAllPoints(); raidSearchLabel:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -192, -82)
        raidSearchBox:ClearAllPoints(); raidSearchBox:SetPoint("TOPRIGHT", raidPage, "TOPRIGHT", -4, -76); raidSearchBox:SetWidth(178)
    end
    raidSearchLabel:Show(); raidSearchBox:Show(); raidFilterLabel:Show(); raidClassFilterButton:Show(); raidRankFilterButton:Show()
    local raidHeaderY = MOS.lootMasterMode and -42 or -110
    local raidRowStartY = MOS.lootMasterMode and -64 or -132
    local headerPositions = MOS.lootMasterMode and { 12, 0, 172, 267, 417 } or { 12, 172, 252, 347, 500 }
    local headerWidths = MOS.lootMasterMode and { 150, 0, 85, 140, 45 } or { 155, 70, 85, 138, 55 }
    local headerLabels = { raidHeaders, raidGroupHeader, raidClassHeader, raidRankHeader, raidSRHeader }
    for headerIndex = 1, 5 do
        headerLabels[headerIndex]:ClearAllPoints(); headerLabels[headerIndex]:SetPoint("TOPLEFT", raidPage, "TOPLEFT", headerPositions[headerIndex], raidHeaderY); headerLabels[headerIndex]:SetWidth(headerWidths[headerIndex])
        raidHeaderButtons[headerIndex]:ClearAllPoints(); raidHeaderButtons[headerIndex]:SetPoint("TOPLEFT", raidPage, "TOPLEFT", headerPositions[headerIndex], raidHeaderY + 4); raidHeaderButtons[headerIndex]:SetWidth(headerWidths[headerIndex])
    end
    raidHeaders:Show()
    if MOS.lootMasterMode then raidGroupHeader:Hide() else raidGroupHeader:Show() end
    raidClassHeader:Show(); raidRankHeader:Show(); raidSRHeader:Show()
    for i = 1, table.getn(raidHeaderButtons) do
        local header = raidHeaderButtons[i]
        if MOS.lootMasterMode and header.sortKey == "subgroup" then header:Hide() else header:Show() end
        if raidSortKey == header.sortKey then header.label:SetText(header.baseText .. (raidSortAscending and " ^" or " v")) else header.label:SetText(header.baseText .. " <>") end
    end
    raidScrollFrame:ClearAllPoints(); raidScrollFrame:SetPoint("TOPLEFT", raidPage, "TOPLEFT", -4, raidRowStartY + 11); raidScrollFrame:SetPoint("BOTTOMRIGHT", raidPage, "BOTTOMRIGHT", -12, 18); raidScrollFrame:Show()
    local reservedHeight = MOS.lootMasterMode and 78 or 150
    local availableRaidRows = math.max(3, math.min(table.getn(raidRows), math.floor((raidPage:GetHeight() - reservedHeight) / 21)))
    local raidVisibleRowCount = selectedRaidMemberName and math.max(1, availableRaidRows - 5) or availableRaidRows
    FauxScrollFrame_Update(raidScrollFrame, table.getn(visibleRaidMembers), raidVisibleRowCount, 21)
    local raidOffset = FauxScrollFrame_GetOffset(raidScrollFrame)
    local raidRowY = raidRowStartY
    for i = 1, table.getn(raidRows) do
        local member = visibleRaidMembers[raidOffset + i]
        local row = raidRows[i]
        local groupX, classX, rankX, srX = 172, 252, 347, 500
        if MOS.lootMasterMode then groupX, classX, rankX, srX = 0, 172, 267, 417 end
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", raidPage, "TOPLEFT", 12, raidRowY)
        row.group:ClearAllPoints(); row.group:SetPoint("TOPLEFT", raidPage, "TOPLEFT", groupX, raidRowY)
        row.class:ClearAllPoints(); row.class:SetPoint("TOPLEFT", raidPage, "TOPLEFT", classX, raidRowY)
        row.rank:ClearAllPoints(); row.rank:SetPoint("TOPLEFT", raidPage, "TOPLEFT", rankX, raidRowY)
        row.sr:ClearAllPoints(); row.sr:SetPoint("TOPLEFT", raidPage, "TOPLEFT", srX, raidRowY)
        if member and i <= raidVisibleRowCount then
            row.displayedMember = member
            row:SetWidth(MOS.lootMasterMode and 462 or 543)
            row.name:SetWidth(MOS.lootMasterMode and 150 or 148)
            row.group:SetWidth(MOS.lootMasterMode and 0 or 70)
            row.class:SetWidth(MOS.lootMasterMode and 85 or 85)
            row.rank:SetWidth(MOS.lootMasterMode and 140 or 135)
            row.sr:SetWidth(MOS.lootMasterMode and 45 or 55)
            row.lootPanel:SetWidth(MOS.lootMasterMode and 447 or 535)
            for lootLayoutIndex = 1, table.getn(row.lootRows) do row.lootRows[lootLayoutIndex].name:SetWidth(MOS.lootMasterMode and 367 or 455) end
            row.name:SetText(Short(member.name, 22))
            raidRows[i].group:SetText(tostring(member.subgroup or ""))
            raidRows[i].class:SetText(Short(member.class, 12))
            raidRows[i].rank:SetText(Short(member.guildRank ~= "" and member.guildRank or "Not in guild", 18))
            raidRows[i].sr:SetText(member.sr or "")
            row.name:SetTextColor(1, 1, 1); row.group:SetTextColor(1, 1, 1); row.class:SetTextColor(1, 1, 1); row.rank:SetTextColor(1, 1, 1); row.sr:SetTextColor(1, 1, 1)
            row:Show(); row.name:Show(); if MOS.lootMasterMode then row.group:Hide() else row.group:Show() end; row.class:Show(); row.rank:Show(); row.sr:Show()
            if member.name == selectedRaidMemberName then
                row:SetHeight(131); row:SetBackdropColor(0.16, 0.20, 0.17, 0.82); row:SetBackdropBorderColor(0.46, 0.55, 0.47, 0.90)
                row.lootPanel:Show()
                local loot = member.loot or {}
                table.sort(loot, function(a, b) return string.lower(a.name or "") < string.lower(b.name or "") end)
                FauxScrollFrame_Update(row.lootScroll, table.getn(loot), table.getn(row.lootRows), 24)
                local lootOffset = FauxScrollFrame_GetOffset(row.lootScroll)
                if table.getn(loot) == 0 then row.lootEmpty:Show() else row.lootEmpty:Hide() end
                for lootIndex = 1, table.getn(row.lootRows) do
                    local item = loot[lootOffset + lootIndex]
                    local lootRow = row.lootRows[lootIndex]
                    if item then
                        if not item.icon and item.link then
                            local _, _, _, _, _, _, _, _, _, refreshedTexture = GetItemInfo(item.link)
                            if refreshedTexture then item.icon = refreshedTexture end
                        end
                        lootRow.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                        lootRow.name:SetText((item.name or "Unknown item") .. ((tonumber(item.count) or 1) > 1 and (" x " .. item.count) or ""))
                        lootRow.icon:Show(); lootRow.name:Show()
                    else lootRow.icon:Hide(); lootRow.name:Hide() end
                end
                raidRowY = raidRowY - 131
            else
                row:SetHeight(20)
                if math.mod(raidOffset + i, 2) == 0 then row:SetBackdropColor(1, 0.78, 0.25, 0.075) else row:SetBackdropColor(0, 0, 0, 0) end
                row:SetBackdropBorderColor(0, 0, 0, 0); row.lootPanel:Hide()
                raidRowY = raidRowY - 21
            end
        else
            row.displayedMember = nil; row:Hide(); row.name:Hide(); row.group:Hide(); row.class:Hide(); row.rank:Hide(); row.sr:Hide(); row.lootPanel:Hide()
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

ToggleLootMasterMode = function()
    MOS.lootMasterMode = not MOS.lootMasterMode
    MOS.raidHeightBeforeExpansion = nil
    if MOS.lootMasterMode then
        MuklaOfficerSuiteDB.windowWidth = dashboard:GetWidth(); MuklaOfficerSuiteDB.windowHeight = dashboard:GetHeight()
        dashboard:SetMinResize(700, 170); dashboard:SetMaxResize(1100, 760)
        dashboard:SetWidth(math.max(700, tonumber(MuklaOfficerSuiteDB.lootMasterWidth) or 760))
        dashboard:SetHeight(math.min(260, tonumber(MuklaOfficerSuiteDB.lootMasterHeight) or 220))
        dashboard:SetAlpha(0.3)
        sidebar:Hide(); titleBar:Hide(); closeButton:Hide(); versionText:Hide(); raidTitle:Hide()
        contentPanel:ClearAllPoints()
        contentPanel:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 6, -6)
        contentPanel:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -6, 6)
        rosterPage:ClearAllPoints(); rosterPage:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 5, -5); rosterPage:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -5, 5)
        raidModeButton:SetText("Turn Off LM Mode")
    else
        MuklaOfficerSuiteDB.lootMasterWidth = dashboard:GetWidth(); MuklaOfficerSuiteDB.lootMasterHeight = dashboard:GetHeight()
        dashboard:SetAlpha(1)
        dashboard:SetMinResize(760, 420); dashboard:SetMaxResize(1100, 760)
        dashboard:SetWidth(math.max(760, tonumber(MuklaOfficerSuiteDB.windowWidth) or 840))
        dashboard:SetHeight(math.max(420, tonumber(MuklaOfficerSuiteDB.windowHeight) or 540))
        sidebar:Show(); titleBar:Show(); closeButton:Show(); versionText:Show(); raidTitle:Show()
        contentPanel:ClearAllPoints()
        contentPanel:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 204, -68)
        contentPanel:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -20, 32)
        rosterPage:ClearAllPoints(); rosterPage:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 14, -14); rosterPage:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -14, 14)
        raidModeButton:SetText("Loot Master Mode")
    end
    RefreshRaidPage()
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
    MOS.scanDeadline = GetTime() + 15
    rosterRequestFrame.delay = 1
    rosterRequestFrame:Show()
    if scanMode == "raid" then MOS.scanProgressLabel = "Scanning raid"
    elseif scanMode == "reload" then MOS.scanProgressLabel = "Preparing roster export"
    else MOS.scanProgressLabel = "Scanning guild data" end
    scanProgress:SetValue(0)
    scanProgress.text:SetText(MOS.scanProgressLabel .. "... 0%")
    scanProgress:Show()
    GuildRoster()
    if MOS.pendingScan == "reload" or MOS.pendingScan == "csr_reload" then
        Print("Requesting guild roster. Save confirmation will appear when the scan completes...")
    else
        Print("Requesting guild roster...")
    end
    return true
end

local function StartSharedGuildScan(origin)
    MOS.sharedScanOrigin = origin
    if not RequestRosterScan("shared") then MOS.sharedScanOrigin = nil; return end
    if origin == "statistics" then
        statisticsReady = false
        statisticsSummary:Hide()
        statisticsClasses:Hide()
        statisticsRanks:Hide()
        statisticsClassPanel:Hide()
        statisticsRankPanel:Hide()
        statisticsClassTable.scroll:Hide(); statisticsRankTable.scroll:Hide()
        for i = 1, table.getn(statisticsClassTable.rows) do statisticsClassTable.rows[i]:Hide(); statisticsRankTable.rows[i]:Hide() end
        for i = 1, table.getn(statisticsClassRows) do statisticsClassRows[i].icon:Hide(); statisticsClassRows[i].name:Hide(); statisticsClassRows[i].count:Hide() end
        for i = 1, table.getn(statisticsRankRows) do statisticsRankRows[i].name:Hide(); statisticsRankRows[i].count:Hide() end
        statisticsOnlyLevel60:Hide()
        statisticsLastScan:Hide()
        statisticsRefreshButton:Hide()
        statisticsScanButton:Hide()
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
    MOS.scanDeadline = GetTime() + 15
    rosterRequestFrame.delay = 0.75
    rosterRequestFrame:Show()
    MOS.scanProgressLabel = "Refreshing guild data"
    scanProgress:SetValue(0)
    scanProgress.text:SetText(MOS.scanProgressLabel .. "... 0%")
    scanProgress:Show()
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
        if sortKey ~= this.sortKey then
            sortKey = this.sortKey
            sortAscending = true
        elseif sortAscending then
            sortAscending = false
        else
            sortKey = nil
            sortAscending = true
        end
        RefreshRosterPage(true)
    end)
end

searchBox:SetScript("OnTextChanged", function() RefreshRosterPage(true) end)
raidSearchBox:SetScript("OnTextChanged", function() RefreshRaidPage() end)
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
MOS:RegisterEvent("CHAT_MSG_LOOT")

HandleGuildScanFailure = function()
    if MOS.sharedScanOrigin == "roster" then
        RefreshRosterPage(false)
    elseif MOS.sharedScanOrigin == "statistics" then
        statisticsScanButton:Show()
    elseif currentPage == "raid" then
        RefreshRaidPage()
    end
    MOS.sharedScanOrigin = nil
end

CompletePendingGuildScan = function()
    if not MOS.pendingScan then return false end
    local scanMode = MOS.pendingScan
    if not SaveGuildRoster() then return false end

    RefreshRosterPage(scanMode ~= "quiet")
    RefreshExportPage()
    if scanMode == "shared" then
        rosterReady = true
        statisticsReady = true
        RefreshRosterPage(true)
        if MOS.sharedScanOrigin == "statistics" then
            RefreshStatisticsPage()
        else
            RefreshStatisticsPage()
        end
        MOS.sharedScanOrigin = nil
        Print("Guild data loaded successfully. Members: " .. CountSavedMembers() .. ".")
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
    return true
end

MOS:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        EnsureDatabase()
        dashboard:SetScale(1)
        dashboard:SetWidth(math.max(760, math.min(1100, tonumber(MuklaOfficerSuiteDB.windowWidth) or 840)))
        dashboard:SetHeight(math.max(420, math.min(760, tonumber(MuklaOfficerSuiteDB.windowHeight) or 540)))
        MuklaOfficerSuiteDB.uiScale = nil
        PositionMinimapButton()
        if MuklaOfficerSuiteDB.minimap.hidden then minimapButton:Hide() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        CompletePendingGuildScan()
    elseif event == "CHAT_MSG_LOOT" then
        if RecordRaidLoot(arg1) and currentPage == "raid" then RefreshRaidPage() end
    end
end)

Print("v" .. VERSION .. " loaded. Type /mos")
