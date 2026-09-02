local ADDON_NAME = "MuklaOfficerSuite"
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version") or "0.4.0"
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
dashboard:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
dashboard:Hide()

local titleBar = CreateFrame("Frame", nil, dashboard)
titleBar:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 18, -13)
titleBar:SetPoint("TOPRIGHT", dashboard, "TOPRIGHT", -18, -13)
titleBar:SetHeight(32)
titleBar:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
titleBar:SetBackdropColor(0.07, 0.06, 0.04, 0.96)
titleBar:SetBackdropBorderColor(0.48, 0.48, 0.45, 1)

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
sidebar:SetBackdropBorderColor(0.55, 0.38, 0.08, 1)

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
contentPanel:SetBackdropBorderColor(0.48, 0.35, 0.12, 1)

local background = contentPanel:CreateTexture(nil, "BACKGROUND")
background:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 5, -5)
background:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -5, 5)
background:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\DashboardBackground")
background:SetTexCoord(0, 1, 0, 0.625)
background:SetAlpha(0.34)

local backgroundShade = contentPanel:CreateTexture(nil, "BORDER")
backgroundShade:SetAllPoints(contentPanel)
backgroundShade:SetTexture(0, 0, 0, 0.20)

local rosterPage = CreateFrame("Frame", nil, contentPanel)
rosterPage:SetPoint("TOPLEFT", contentPanel, "TOPLEFT", 14, -14)
rosterPage:SetPoint("BOTTOMRIGHT", contentPanel, "BOTTOMRIGHT", -14, 14)

local exportPage = CreateFrame("Frame", nil, contentPanel)
exportPage:SetAllPoints(rosterPage)
exportPage:Hide()

local aboutPage = CreateFrame("Frame", nil, contentPanel)
aboutPage:SetAllPoints(rosterPage)
aboutPage:Hide()

local rosterTitle = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
rosterTitle:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -2)
rosterTitle:SetText("Roster Management")

local searchLabel = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
searchLabel:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -192, -7)
searchLabel:SetText("Search")

local searchBox = CreateFrame("EditBox", "MuklaOfficerSuiteRosterSearch", rosterPage, "InputBoxTemplate")
searchBox:SetWidth(178)
searchBox:SetHeight(20)
searchBox:SetPoint("TOPRIGHT", rosterPage, "TOPRIGHT", -4, -1)
searchBox:SetAutoFocus(false)
searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

local rosterStatusText = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rosterStatusText:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -36)
rosterStatusText:SetWidth(565)
rosterStatusText:SetJustifyH("LEFT")

local rows = {}
local rowCount = 14
local rowHeight = 20
local visibleMembers = {}
local sortKey = "name"
local sortAscending = true
local selectedMemberName = nil
local RefreshRosterPage
local RefreshExportPage
local UpdateSelectionControls
local menuButtons = {}
local currentPage = "roster"

local function Short(text, length)
    text = tostring(text or "")
    if string.len(text) > length then
        return string.sub(text, 1, length - 1) .. "~"
    end
    return text
end

local function CreateHeaderButton(text, x, width, alignment, key)
    local button = CreateFrame("Button", nil, rosterPage)
    button:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", x, -58)
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
notesHeader:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 391, -58)
notesHeader:SetWidth(174)
notesHeader:SetHeight(22)
notesHeader:SetJustifyH("LEFT")
notesHeader:SetText("Public / Officer note")

local i
for i = 1, rowCount do
    local row = CreateFrame("Frame", nil, rosterPage)
    row:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", 4, -78 - (i * rowHeight))
    row:SetWidth(560)
    row:SetHeight(rowHeight)
    row:EnableMouse(true)

    if math.mod(i, 2) == 0 then
        local stripe = row:CreateTexture(nil, "BACKGROUND")
        stripe:SetAllPoints(row)
        stripe:SetTexture(1, 0.78, 0.25, 0.035)
    end

    row.selection = row:CreateTexture(nil, "BACKGROUND")
    row.selection:SetAllPoints(row)
    row.selection:SetTexture(1, 0.72, 0.08, 0.22)
    row.selection:Hide()

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name:SetWidth(132)
    row.name:SetHeight(18)
    row.name:SetJustifyH("LEFT")

    row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.level:SetPoint("LEFT", row, "LEFT", 137, 0)
    row.level:SetWidth(38)
    row.level:SetHeight(18)
    row.level:SetJustifyH("RIGHT")

    row.class = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("LEFT", row, "LEFT", 185, 0)
    row.class:SetWidth(82)
    row.class:SetHeight(18)
    row.class:SetJustifyH("LEFT")

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.rank:SetPoint("LEFT", row, "LEFT", 277, 0)
    row.rank:SetWidth(100)
    row.rank:SetHeight(18)
    row.rank:SetJustifyH("LEFT")

    row.notes = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.notes:SetPoint("LEFT", row, "LEFT", 387, 0)
    row.notes:SetWidth(173)
    row.notes:SetHeight(18)
    row.notes:SetJustifyH("LEFT")
    row:SetScript("OnClick", function()
        if this.displayedMember then
            selectedMemberName = this.displayedMember.name
            RefreshRosterPage(false)
            UpdateSelectionControls()
        end
    end)
    rows[i] = row
end

local rosterScrollFrame = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRosterScrollFrame", rosterPage, "FauxScrollFrameTemplate")
rosterScrollFrame:SetPoint("TOPLEFT", rosterPage, "TOPLEFT", -4, -89)
rosterScrollFrame:SetPoint("BOTTOMRIGHT", rosterPage, "BOTTOMRIGHT", -12, 57)

local selectedMemberText = rosterPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
selectedMemberText:SetPoint("BOTTOMLEFT", rosterPage, "BOTTOMLEFT", 4, 10)
selectedMemberText:SetWidth(275)
selectedMemberText:SetJustifyH("LEFT")
selectedMemberText:SetText("Select a guild member")

local promoteButton = CreateFrame("Button", nil, rosterPage, "UIPanelButtonTemplate")
promoteButton:SetWidth(105)
promoteButton:SetHeight(24)
promoteButton:SetPoint("BOTTOMRIGHT", rosterPage, "BOTTOMRIGHT", -116, 4)
promoteButton:SetText("Promote")
promoteButton:Hide()

local demoteButton = CreateFrame("Button", nil, rosterPage, "UIPanelButtonTemplate")
demoteButton:SetWidth(105)
demoteButton:SetHeight(24)
demoteButton:SetPoint("BOTTOMRIGHT", rosterPage, "BOTTOMRIGHT", -4, 4)
demoteButton:SetText("Demote")
demoteButton:Hide()

local exportTitle = exportPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
exportTitle:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -10)
exportTitle:SetText("Export Roster")

local exportDescription = exportPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
exportDescription:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -58)
exportDescription:SetWidth(545)
exportDescription:SetJustifyH("LEFT")
exportDescription:SetText("Scan the complete guild roster and save it to SavedVariables. After the UI reloads, run Export-Roster.ps1 to create the CSV file.")

local lastScanLabel = exportPage:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lastScanLabel:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -135)
lastScanLabel:SetText("Last saved scan")

local lastScanValue = exportPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lastScanValue:SetPoint("TOPLEFT", lastScanLabel, "BOTTOMLEFT", 0, -10)
lastScanValue:SetWidth(545)
lastScanValue:SetJustifyH("LEFT")

local scanSaveButton = CreateFrame("Button", nil, exportPage, "UIPanelButtonTemplate")
scanSaveButton:SetWidth(150)
scanSaveButton:SetHeight(28)
scanSaveButton:SetPoint("TOPLEFT", exportPage, "TOPLEFT", 12, -205)
scanSaveButton:SetText("Scan & Save")

local exportHint = exportPage:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
exportHint:SetPoint("LEFT", scanSaveButton, "RIGHT", 14, 0)
exportHint:SetWidth(365)
exportHint:SetJustifyH("LEFT")
exportHint:SetText("A confirmation dialog will reload the UI and write the roster to disk.")

local aboutTitle = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
aboutTitle:SetPoint("TOPLEFT", aboutPage, "TOPLEFT", 12, -10)
aboutTitle:SetText("About")

local aboutName = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
aboutName:SetPoint("TOP", aboutPage, "TOP", 0, -95)
aboutName:SetText("Mukla Officer Suite")

local aboutVersion = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
aboutVersion:SetPoint("TOP", aboutName, "BOTTOM", 0, -12)
aboutVersion:SetText("Version " .. VERSION)

local aboutAuthor = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
aboutAuthor:SetPoint("TOP", aboutVersion, "BOTTOM", 0, -24)
aboutAuthor:SetText("Created by Bootybaker")

local aboutDescription = aboutPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
aboutDescription:SetPoint("TOP", aboutAuthor, "BOTTOM", 0, -34)
aboutDescription:SetWidth(450)
aboutDescription:SetText("Guild management tools for World of Warcraft 1.12.1")

local function GetCurrentGuildData()
    EnsureDatabase()
    local key, guildName = GuildKey()
    return key and MuklaOfficerSuiteDB.guilds[key], guildName
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

UpdateSelectionControls = function()
    local member = GetSelectedMember()
    if not member then
        selectedMemberName = nil
        selectedMemberText:SetText("Select a guild member")
        promoteButton:Hide()
        demoteButton:Hide()
        return
    end

    selectedMemberText:SetText("Selected: " .. member.name .. " (" .. (member.rank or "Unknown rank") .. ")")
    promoteButton:Show()
    demoteButton:Show()

    if (tonumber(member.rankIndex) or 0) <= 0 then
        promoteButton:Disable()
    else
        promoteButton:Enable()
    end

    if (tonumber(member.rankIndex) or 0) >= GetLowestRankIndex() then
        demoteButton:Disable()
    else
        demoteButton:Enable()
    end
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

RefreshRosterPage = function(resetScroll)
    local data, guildName = GetCurrentGuildData()
    local query = string.lower(searchBox:GetText() or "")
    query = string.gsub(query, "^%s*(.-)%s*$", "%1")

    visibleMembers = {}
    if data and data.members then
        for i = 1, table.getn(data.members) do
            if MemberMatchesSearch(data.members[i], query) then
                table.insert(visibleMembers, data.members[i])
            end
        end
        table.sort(visibleMembers, SortMembers)
    end

    if not guildName then
        rosterStatusText:SetText("No guild found.")
    elseif not data then
        rosterStatusText:SetText(guildName .. " - no saved roster. Use Export Roster to scan.")
    elseif query ~= "" then
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

    for i = 1, rowCount do
        local member = visibleMembers[offset + i]
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
            else
                rows[i].selection:Hide()
            end
            rows[i]:Show()
        else
            rows[i].displayedMember = nil
            rows[i].selection:Hide()
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
    UpdateSelectionControls()
end

RefreshExportPage = function()
    local data, guildName = GetCurrentGuildData()
    if not guildName then
        lastScanValue:SetText("No guild found for this character.")
    elseif not data then
        lastScanValue:SetText("No saved scan for " .. guildName .. ".")
    else
        local scanTime = data.scannedAtText or date("%Y-%m-%d %H:%M:%S", data.scannedAt or data.updatedAt)
        lastScanValue:SetText(scanTime .. " | " .. table.getn(data.members) .. " members | addon v" .. (data.addonVersion or "unknown"))
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
    aboutPage:Hide()
    if pageName == "roster" then
        rosterPage:Show()
        RefreshRosterPage(false)
    elseif pageName == "export" then
        exportPage:Show()
        RefreshExportPage()
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
CreateMenuButton("export", "Export Roster", -66, "Interface\\Icons\\INV_Misc_Note_01")
CreateMenuButton("about", "About", -120, "Interface\\Icons\\INV_Misc_QuestionMark")

local function RequestRosterScan(scanMode)
    EnsureDatabase()
    if not IsInGuild() then
        Print("This character is not in a guild.")
        return
    end
    MOS.pendingScan = scanMode or "manual"
    MOS.scanStartedAt = GetTime()
    MOS.scanAttempts = 1
    rosterRequestFrame.delay = 1
    rosterRequestFrame:Show()
    GuildRoster()
    if MOS.pendingScan == "reload" then
        Print("Requesting guild roster. Save confirmation will appear when the scan completes...")
    else
        Print("Requesting guild roster...")
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

promoteButton:SetScript("OnClick", function()
    local member = GetSelectedMember()
    if not member then return end
    local targetRank = GetRankNameByIndex((tonumber(member.rankIndex) or 0) - 1) or "the next rank"
    MOS.pendingGuildAction = { name = member.name, action = "promote" }
    StaticPopup_Show("MUKLA_OFFICER_SUITE_PROMOTE", "Promote " .. member.name .. "?\n" .. (member.rank or "Unknown") .. " -> " .. targetRank)
end)

demoteButton:SetScript("OnClick", function()
    local member = GetSelectedMember()
    if not member then return end
    local targetRank = GetRankNameByIndex((tonumber(member.rankIndex) or 0) + 1) or "the next rank"
    MOS.pendingGuildAction = { name = member.name, action = "demote" }
    StaticPopup_Show("MUKLA_OFFICER_SUITE_DEMOTE", "Demote " .. member.name .. "?\n" .. (member.rank or "Unknown") .. " -> " .. targetRank)
end)

scanSaveButton:SetScript("OnClick", function() RequestRosterScan("reload") end)

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
        ShowPage("export")
        Print("Click 'Scan & Save' on the Export Roster page.")
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
            RefreshRosterPage(true)
            RefreshExportPage()
            if scanMode == "reload" then
                Print("Roster scanned. Confirm the reload to save it to disk.")
                StaticPopup_Show("MUKLA_OFFICER_SUITE_RELOAD")
            elseif scanMode ~= "quiet" then
                Print("Roster scanned. Members: " .. CountSavedMembers())
            end
        end
    end
end)

Print("v" .. VERSION .. " loaded. Type /mos")
