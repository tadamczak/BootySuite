local MOS = MuklaOfficerSuite

MOS.Modules.RosterManagement = MOS.Modules.RosterManagement or {}
local RosterManagement = MOS.Modules.RosterManagement

function RosterManagement.CreateShell(page, contentPanel)
    local title = MOS.UI.Components.CreateHeading(page, "", 1, "orange")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    title:SetText("Roster Management")

    local searchLabel = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -192, -87)
    searchLabel:SetText("Search")
    local searchBox = MOS.UI.Components.CreateSearchBox(page, "MuklaOfficerSuiteRosterSearch", 178)
    searchBox:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -81)

    local status = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -40)
    status:SetWidth(565)
    status:SetJustifyH("LEFT")
    local lastScan = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall")
    lastScan:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -58)
    lastScan:SetWidth(330)
    lastScan:SetJustifyH("LEFT")

    -- This panel follows the full content area; row capacity must not depend on
    -- the fitted visual panel height calculated during the preceding refresh.
    page.fittedPanel = MOS.UI.Components.CreateContainer(nil, contentPanel)
    page.fittedPanel:SetFrameLevel(contentPanel:GetFrameLevel())
    page.fittedPanel:SetAllPoints(contentPanel)
    page.fittedPanel:SetBackdrop(contentPanel:GetBackdrop())
    page.fittedPanel:SetBackdropColor(0.025, 0.022, 0.018, 0.99)
    page.fittedPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
    page.fittedPanel:Hide()
    return { searchLabel = searchLabel, searchBox = searchBox, status = status, lastScan = lastScan }
end

function RosterManagement.CreateGuildControls(page)
    local scanButton = MOS.UI.Components.CreateButton(page, nil, "Scan Guild Data", 140, 24)
    scanButton:SetPoint("CENTER", page, "CENTER", 0, 12)
    local refreshButton = MOS.UI.Components.CreateIconButton(page, nil, "Interface\\Buttons\\UI-RotationRight-Button-Up", 24)
    refreshButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -48)
    MOS.UI.Components.AttachTooltip(refreshButton, "Refresh guild data", "Refresh the saved guild roster. Disabled while Live tracking is active.")
    refreshButton:Hide()
    local exportButton = MOS.UI.Components.CreateButton(page, nil, "Export Roster", 120, 22)
    exportButton:SetPoint("CENTER", page, "CENTER", 96, 12)

    page.guildInfoEditor = MOS.UI.Components.CreateTextEditor("MuklaOfficerSuiteGuildInfoEditor", "Guild Information", 500, function(value)
        if type(SetGuildInfoText) == "function" then SetGuildInfoText(value) end
    end)
    page.guildMotdEditor = MOS.UI.Components.CreateTextEditor("MuklaOfficerSuiteGuildMotdEditor", "Guild Message of the Day", 128, function(value)
        if type(GuildSetMOTD) == "function" then GuildSetMOTD(value) end
    end)
    page.guildInfoButton = MOS.UI.Components.CreateButton(page, nil, "Guild Information", 108, 22)
    page.guildAddButton = MOS.UI.Components.CreateButton(page, nil, "Add Member", 84, 22)
    page.guildControlButton = MOS.UI.Components.CreateButton(page, nil, "Guild Control", 88, 22)
    page.guildInfoButton:Hide(); page.guildAddButton:Hide(); page.guildControlButton:Hide()
    RosterManagement.BindPermissionEvents(page)

    StaticPopupDialogs["MUKLA_OFFICER_SUITE_GUILD_INVITE"] = {
        text = "Invite a character to the guild", button1 = "Invite", button2 = "Cancel", hasEditBox = 1, maxLetters = 24,
        OnAccept = function() local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText(); if MOS.Services.Roster.CanManage("invite") and name and name ~= "" and type(GuildInvite) == "function" then GuildInvite(name) end end,
        OnShow = function() getglobal(this:GetName() .. "EditBox"):SetFocus() end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    page.guildInfoButton:SetScript("OnClick", function() page.guildInfoEditor:Open(type(GetGuildInfoText) == "function" and GetGuildInfoText() or "") end)
    page.guildAddButton:SetScript("OnClick", function() if MOS.Services.Roster.CanManage("invite") then MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_GUILD_INVITE") end end)
    page.guildControlButton:SetScript("OnClick", function() if not MOS.Services.Roster.CanManage("control") then return end; if type(GuildControlPopupFrame_Toggle) == "function" then GuildControlPopupFrame_Toggle() elseif type(ToggleGuildFrame) == "function" then ToggleGuildFrame() end end)

    page.footer = MOS.UI.Components.CreateControl(nil, page)
    page.footer:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 4, 4); page.footer:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 4); page.footer:SetHeight(38)
    page.footer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    page.footer:SetBackdropColor(0.07, 0.07, 0.06, 0.88); page.footer:SetBackdropBorderColor(0.30, 0.30, 0.28, 1)
    page.footer.guild = MOS.UI.Components.CreateLabel(page.footer, nil, "OVERLAY", "GameFontNormalSmall"); page.footer.guild:SetPoint("TOPLEFT", page.footer, "TOPLEFT", 8, -7)
    page.footer.motd = MOS.UI.Components.CreateLabel(page.footer, nil, "OVERLAY", "GameFontHighlightSmall"); page.footer.motd:SetPoint("BOTTOMLEFT", page.footer, "BOTTOMLEFT", 8, 6); page.footer.motd:SetWidth(520); page.footer.motd:SetJustifyH("LEFT")
    page.footer:SetScript("OnClick", function() page.guildMotdEditor:Open(type(GetGuildRosterMOTD) == "function" and GetGuildRosterMOTD() or "") end)
    MOS.UI.Components.AttachTooltip(page.footer, "Guild Message of the Day", "Click to edit the guild message of the day.")
    page.footer:Hide()
    local font, size, flags = page.footer.guild:GetFont()
    page.footer.guild:SetFont(font, size + 1, flags)
    font, size, flags = page.footer.motd:GetFont()
    page.footer.motd:SetFont(font, size + 1, flags)
    page.footer.rule = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    page.footer.rule:SetPoint("TOPLEFT", page.footer, "BOTTOMLEFT", 8, -8)
    page.footer.rule:SetPoint("TOPRIGHT", page.footer, "BOTTOMRIGHT", 0, -8)
    page.footer.rule:SetHeight(1); page.footer.rule:SetTexture(0.55, 0.42, 0.16, 0.75)
    return { scanButton = scanButton, refreshButton = refreshButton, exportButton = exportButton }
end

function RosterManagement.CreateGuildActionHandler(options)
    local pendingAction
    local function Finish(apiFunction, verb)
        if pendingAction and type(apiFunction) == "function" then
            local memberName = pendingAction.name
            if not MOS.Services.Roster.PerformMemberAction(pendingAction.action, memberName) then pendingAction = nil; return end
            options.printMessage(verb .. " requested for " .. memberName .. ".")
            options.queueRefresh()
        end
        pendingAction = nil
    end
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_PROMOTE"] = {
        text = "%s", button1 = "Promote", button2 = "Cancel",
        OnAccept = function() Finish(GuildPromoteByName, "Promotion") end,
        OnCancel = function() pendingAction = nil end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_DEMOTE"] = {
        text = "%s", button1 = "Demote", button2 = "Cancel",
        OnAccept = function() Finish(GuildDemoteByName, "Demotion") end,
        OnCancel = function() pendingAction = nil end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    return function(action, requestedMember)
        if action == "refresh" then options.queueRefresh(); return end
        local data = options.getData()
        local member = requestedMember or options.findMember(data, options.getSelectedName())
        if not member or not MOS.Services.Roster.CanManage(action, member) then return end
        local direction = action == "promote" and -1 or 1
        local targetRank = options.findRankName(data, (tonumber(member.rankIndex) or 0) + direction) or "the next rank"
        if action == "promote" or action == "demote" then
            pendingAction = { name = member.name, action = action }
            local label = action == "promote" and "Promote" or "Demote"
            MOS.UI.Components.ShowOpaquePopup(action == "promote" and "MUKLA_OFFICER_SUITE_PROMOTE" or "MUKLA_OFFICER_SUITE_DEMOTE", label .. " " .. member.name .. "?\n" .. (member.rank or "Unknown") .. " -> " .. targetRank)
        end
    end
end

function RosterManagement.CreateFilterView(page)
    local sortHint = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall")
    sortHint:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -114)
    sortHint:SetText("Click a column header to sort")
    sortHint:Hide()
    local label = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -112)
    label:SetText("Filters")

    local classToggle = MOS.UI.Components.CreateDropdownButton(page, nil, "Class", 84)
    classToggle:SetPoint("TOPLEFT", page, "TOPLEFT", 50, -106)
    local rankToggle = MOS.UI.Components.CreateDropdownButton(page, nil, "Rank", 84)
    rankToggle:SetPoint("TOPLEFT", page, "TOPLEFT", 142, -106)

    page.showOfflineCheck = MOS.UI.Components.CreateCheckButton("MuklaOfficerSuiteShowOffline", page, "UICheckButtonTemplate")
    page.showOfflineCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 232, -104)
    page.showOfflineCheck:SetWidth(22); page.showOfflineCheck:SetHeight(22)
    page.showOfflineCheck.label = MOS.UI.Components.CreateLabel(page.showOfflineCheck, nil, "OVERLAY", "GameFontHighlightSmall")
    page.showOfflineCheck.label:SetPoint("LEFT", page.showOfflineCheck, "RIGHT", 2, 0)
    page.showOfflineCheck.label:SetText("Show offline")

    page.modeButton = MOS.UI.Components.CreateControl(nil, page)
    page.modeButton:SetWidth(28); page.modeButton:SetHeight(28)
    page.modeButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -102)
    page.modeButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    page.modeButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    page.modeButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    page.modeButton.label = MOS.UI.Components.CreateLabel(page.modeButton, nil, "OVERLAY", "GameFontNormalSmall")
    page.modeButton.label:SetPoint("RIGHT", page.modeButton, "LEFT", -4, 0)
    page.modeButton.label:SetText("Show Player Status")
    MOS.UI.Components.AttachTooltip(page.modeButton, "Show player status", "Switch between guild notes and player status columns.")

    local classPanel = MOS.UI.Components.CreateDropdownPanel(page, classToggle, 130, 230, 20)
    local rankPanel = MOS.UI.Components.CreateDropdownPanel(page, rankToggle, 130, 230, 20)
    local dismiss = MOS.UI.Components.CreateControl(nil, page)
    dismiss:SetAllPoints(page)
    dismiss:SetFrameLevel(page:GetFrameLevel() + 10)
    dismiss:Hide()
    classPanel:SetFrameLevel(page:GetFrameLevel() + 20)
    rankPanel:SetFrameLevel(page:GetFrameLevel() + 20)
    classToggle:SetFrameLevel(page:GetFrameLevel() + 21)
    rankToggle:SetFrameLevel(page:GetFrameLevel() + 21)
    return { sortHint = sortHint, label = label, classToggle = classToggle, rankToggle = rankToggle, classPanel = classPanel, rankPanel = rankPanel, dismiss = dismiss }
end

function RosterManagement.MountList(page, filterView, options)
    RosterManagement.CreateFilterController({
        page = page,
        classToggle = filterView.classToggle,
        rankToggle = filterView.rankToggle,
        classPanel = filterView.classPanel,
        rankPanel = filterView.rankPanel,
        dismiss = filterView.dismiss,
        selectedClasses = options.selectedClasses,
        selectedRanks = options.selectedRanks,
        getUniqueValues = options.getUniqueValues,
        refresh = options.refreshFilters,
    })
    RosterManagement.CreateHeaders(page, options.onSort)
    page.rowController = {
        onAction = options.onAction,
        onSelect = options.onSelect,
        isSelected = options.isSelected,
    }
    return RosterManagement.CreateListController(page, options.rowHeight, page.rowController)
end

function RosterManagement.BuildLayoutControls(page, shell, filterView, guildControls)
    page.layoutControls = {
        footer = page.footer,
        filtersLabel = filterView.label,
        classFilter = filterView.classToggle,
        rankFilter = filterView.rankToggle,
        searchLabel = shell.searchLabel,
        searchBox = shell.searchBox,
        showOffline = page.showOfflineCheck,
        refreshButton = guildControls.refreshButton,
        status = shell.lastScan,
        modeButton = page.modeButton,
        actions = {
            { button = page.guildInfoButton, width = 118 },
            { button = page.guildAddButton, width = 90, permission = "invite" },
            { button = page.guildControlButton, width = 100, permission = "control" },
            { button = guildControls.exportButton, width = 120 },
        },
    }
    return page.layoutControls
end

local rosterHeaderSpecs = {
    { "Name", 12, 132, "name" },
    { "Lvl", 149, 38, "level" },
    { "Class", 197, 82, "class" },
    { "Rank", 289, 100, "rank" },
}

local function CreateHeaderButton(page, controller, text, x, width, key, sortable)
    return MOS.UI.Components.Table.CreateHeader(page, controller, text, x, -130, width, key, sortable)
end

-- Pure layout calculation. Keeping this outside the view prevents accidental
-- frame-to-frame feedback loops when the roster page is resized.
function RosterManagement.CalculateVisibleRows(viewportHeight, rowHeight, hasExpandedRow)
    local height = math.max(0, tonumber(viewportHeight) or 0)
    local step = math.max(1, tonumber(rowHeight) or 1)
    local expandedReserve = hasExpandedRow and 208 or 0
    return math.max(hasExpandedRow and height >= step and 1 or 0, math.floor((height - expandedReserve) / step))
end

function RosterManagement.NeedsLayout(width, height, previousWidth, previousHeight, forced)
    if forced then return true end
    return math.abs((tonumber(width) or 0) - (tonumber(previousWidth) or 0)) > 0.5
        or math.abs((tonumber(height) or 0) - (tonumber(previousHeight) or 0)) > 0.5
end

function RosterManagement.MatchesFilters(member, selectedClasses, selectedRanks, showOffline)
    local className = tostring(member.class or "Unknown")
    local rankName = tostring(member.rank or "Unknown")
    if className == "" then className = "Unknown" end
    if rankName == "" then rankName = "Unknown" end
    if not showOffline and not member.online then return false end
    return selectedClasses[className] and selectedRanks[rankName]
end

function RosterManagement.MatchesSearch(member, query)
    if query == "" then return true end
    local searchable = string.lower(
        tostring(member.name or "") .. " " .. tostring(member.level or "") .. " " ..
        tostring(member.class or "") .. " " .. tostring(member.rank or "") .. " " ..
        tostring(member.rankIndex or "") .. " " .. tostring(member.publicNote or "") .. " " ..
        tostring(member.officerNote or "") .. " " .. tostring(member.zone or "") .. " " ..
        tostring(member.status or "") .. " " .. tostring(member.online)
    )
    return string.find(searchable, query, 1, true) ~= nil
end

function RosterManagement.FilterMembers(target, data, query, selectedClasses, selectedRanks, showOffline)
    local targetIndex
    for targetIndex = table.getn(target), 1, -1 do target[targetIndex] = nil end
    if not data or not data.members then return target end
    local memberIndex
    for memberIndex = 1, table.getn(data.members) do
        local member = data.members[memberIndex]
        if RosterManagement.MatchesSearch(member, query)
            and RosterManagement.MatchesFilters(member, selectedClasses, selectedRanks, showOffline) then
            target[table.getn(target) + 1] = member
        end
    end
    return target
end

function RosterManagement.CreateFilterController(options)
    local controller = {
        page = options.page,
        classToggle = options.classToggle,
        rankToggle = options.rankToggle,
        classPanel = options.classPanel,
        rankPanel = options.rankPanel,
        dismiss = options.dismiss,
        selectedClasses = options.selectedClasses,
        selectedRanks = options.selectedRanks,
        getUniqueValues = options.getUniqueValues,
        refresh = options.refresh,
        classInitialized = false,
        rankInitialized = false,
    }

    function controller:Hide()
        self.classPanel:Hide(); self.rankPanel:Hide(); self.dismiss:Hide()
    end

    function controller:Build(data)
        if self.page.filterData == data then return end
        local classes = self.getUniqueValues(data, "class")
        local ranks = self.getUniqueValues(data, "rank")
        local index
        if not self.classInitialized then
            for index = 1, table.getn(classes) do self.selectedClasses[classes[index]] = true end
            self.classInitialized = true
        end
        if not self.rankInitialized then
            for index = 1, table.getn(ranks) do self.selectedRanks[ranks[index]] = true end
            self.rankInitialized = true
        end
        MOS.UI.Components.FilterPanel.Refresh(self.classPanel, classes, self.selectedClasses, self.refresh)
        MOS.UI.Components.FilterPanel.Refresh(self.rankPanel, ranks, self.selectedRanks, self.refresh)
        self.page.filterData = data
    end

    controller.dismiss:SetScript("OnClick", function() controller:Hide() end)
    controller.classToggle:SetScript("OnClick", function()
        local show = not controller.classPanel:IsVisible()
        controller:Hide()
        if show then controller.classPanel:Show(); controller.dismiss:Show() end
    end)
    controller.rankToggle:SetScript("OnClick", function()
        local show = not controller.rankPanel:IsVisible()
        controller:Hide()
        if show then controller.rankPanel:Show(); controller.dismiss:Show() end
    end)
    options.page.filterController = controller
    return controller
end

function RosterManagement.CreateHeaders(page, onSort)
    local ui = { buttons = {}, controller = { onSort = onSort } }
    local index
    for index = 1, table.getn(rosterHeaderSpecs) do
        local spec = rosterHeaderSpecs[index]
        ui.buttons[index] = CreateHeaderButton(page, ui.controller, spec[1], spec[2], spec[3], spec[4], true)
    end
    ui.zone = CreateHeaderButton(page, ui.controller, "Zone", 149, 150, "zone", true)
    ui.lastOnline = CreateHeaderButton(page, ui.controller, "Last online", 430, 140, "lastOnlineHours", true)
    ui.zone:Hide(); ui.lastOnline:Hide()
    ui.notes = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
    ui.notes:SetPoint("TOPLEFT", page, "TOPLEFT", 399, -130); ui.notes:SetWidth(174); ui.notes:SetHeight(22); ui.notes:SetJustifyH("LEFT"); ui.notes:SetText("Public note")
    ui.officer = CreateHeaderButton(page, ui.controller, "Officer note", 399, 100, "officerNote", false); ui.officer:Hide()
    page.tableViewport = MOS.UI.Components.CreateContainer(nil, page)
    page.tableViewport:SetPoint("TOPLEFT", ui.buttons[1], "BOTTOMLEFT", 0, -2); page.tableViewport:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -30, 32)
    page.officerHeader = ui.officer
    page.guildColumns = {
        { key = "name", header = ui.buttons[1], fraction = 0.28 },
        { key = "zone", header = ui.zone, fraction = 0.34 },
        { key = "level", header = ui.buttons[2], fraction = 0.10 },
        { key = "class", header = ui.buttons[3], fraction = 0.28 },
    }
    page.playerColumns = {
        { key = "name", header = ui.buttons[1], fraction = 0.20 },
        { key = "rank", header = ui.buttons[4], fraction = 0.16 },
        { key = "notes", header = ui.notes, fraction = 0.23 },
        { key = "officer", header = ui.officer, fraction = 0.23 },
        { key = "lastOnline", header = ui.lastOnline, fraction = 0.18 },
    }
    page.listHeaderUI = ui
    return ui
end

function RosterManagement.CompareMembers(a, b, sortKey, ascending)
    if not sortKey then return string.lower(tostring(a.name or "")) < string.lower(tostring(b.name or "")) end
    local aValue, bValue
    if sortKey == "level" then
        aValue, bValue = tonumber(a.level) or 0, tonumber(b.level) or 0
    elseif sortKey == "rank" then
        aValue, bValue = tonumber(a.rankIndex) or 999, tonumber(b.rankIndex) or 999
    else
        aValue, bValue = string.lower(tostring(a[sortKey] or "")), string.lower(tostring(b[sortKey] or ""))
    end
    if aValue == bValue then aValue, bValue = string.lower(tostring(a.name or "")), string.lower(tostring(b.name or "")) end
    if ascending then return aValue < bValue end
    return aValue > bValue
end

function RosterManagement.FormatLastOnline(member)
    if member.online then return "Online" end
    local years = tonumber(member.lastOnlineYears) or 0
    local months = tonumber(member.lastOnlineMonths) or 0
    local days = tonumber(member.lastOnlineDays) or 0
    local hours = tonumber(member.lastOnlineHours) or 0
    if years > 0 then return years .. " year" .. (years == 1 and "" or "s") end
    if months > 0 then return months .. " month" .. (months == 1 and "" or "s") end
    if days > 0 then return days .. " day" .. (days == 1 and "" or "s") end
    return hours .. " hour" .. (hours == 1 and "" or "s")
end

local function OnActionClick()
    local row = this.ownerRow
    if row and row.controller and row.controller.onAction then row.controller.onAction(this.action, row.displayedMember) end
end

local function OnRowClick()
    if arg1 == "RightButton" and this.displayedMember then RosterManagement.OpenMemberMenu(this); return end
    if this.displayedMember and this.controller and this.controller.onSelect then
        this.controller.onSelect(this.displayedMember)
    end
end

local function OnRowEnter()
    if this.displayedMember then
        this.hover:Show()
    end
end

local function OnRowLeave()
    this.hover:Hide()
    if this.displayedMember and this.controller and not this.controller.isSelected(this.displayedMember) then
        this:SetBackdropColor(0, 0, 0, 0)
        this:SetBackdropBorderColor(0, 0, 0, 0)
    end
end

local function CreateActionButton(row, text, action, x)
    local button = MOS.UI.Components.CreateArrowButton(row.actionPanel, action == "promote" and "up" or "down")
    button:SetPoint("TOPRIGHT", row.actionPanel, "TOPRIGHT", x, -6)
    MOS.UI.Components.AttachTooltip(button, text, text .. " this guild member.")
    button.action = action
    button.ownerRow = row
    button:SetScript("OnClick", OnActionClick)
    return button
end

local function AddCell(row, key, x, width)
    row[key] = MOS.UI.Components.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
    row[key]:SetPoint("TOPLEFT", row, "TOPLEFT", x, -1)
    row[key]:SetWidth(width)
    row[key]:SetHeight(18)
    row[key]:SetJustifyH("LEFT")
end

function RosterManagement.CreateRow(parent, index, rowHeight, controller)
    local row = MOS.UI.Components.CreateControl(nil, parent)
    row.controller = controller
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -134 - (index * rowHeight))
    row:SetWidth(560)
    row:SetHeight(rowHeight)
    row:EnableMouse(true)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row.hover = MOS.UI.Components.CreateTexture(row, nil, "ARTWORK")
    row.hover:SetAllPoints(row); row.hover:SetTexture(1, 0.82, 0.28, 0.16); row.hover:Hide()
    row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)
    MOS.UI.Components.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
    if math.mod(index, 2) == 0 then
        local stripe = MOS.UI.Components.CreateTexture(row, nil, "BACKGROUND")
        stripe:SetAllPoints(row)
        stripe:SetTexture(1, 0.78, 0.25, 0.075)
    end
    row.selection = MOS.UI.Components.CreateTexture(row, nil, "BACKGROUND")
    row.selection:SetAllPoints(row)
    row.selection:SetTexture(0, 0, 0, 0)
    row.selection:Hide()

    AddCell(row, "name", 7, 125)
    AddCell(row, "level", 137, 38)
    AddCell(row, "class", 185, 82)
    AddCell(row, "rank", 277, 100)
    AddCell(row, "notes", 387, 173)
    AddCell(row, "officer", 0, 1)
    AddCell(row, "zone", 0, 1)
    AddCell(row, "lastOnline", 0, 1)
    row.zone:Hide()
    row.lastOnline:Hide()

    row.actionPanel = MOS.UI.Components.CreateContainer(nil, row)
    row.actionPanel:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -20)
    row.actionPanel:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -20)
    row.actionPanel:SetHeight(204)
    row.actionPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    row.actionPanel:SetBackdropColor(0.07, 0.08, 0.07, 0.92)
    row.actionPanel:SetBackdropBorderColor(0.30, 0.34, 0.30, 1)
    row.actionPanel:Hide()
    row.promoteButton = CreateActionButton(row, "Promote", "promote", -28)
    row.demoteButton = CreateActionButton(row, "Demote", "demote", -4)
    row:SetScript("OnHide", function() this.hover:Hide() end)
    row:SetScript("OnClick", OnRowClick)
    row:SetScript("OnEnter", OnRowEnter)
    row:SetScript("OnLeave", OnRowLeave)
    return row
end

local function HideColumns(rows, columns)
    local columnIndex
    for columnIndex = 1, table.getn(columns) do
        local column = columns[columnIndex]
        column.header:Hide()
        local rowIndex
        for rowIndex = 1, table.getn(rows) do rows[rowIndex][column.key]:Hide() end
    end
end

function RosterManagement.ApplyRowColumns(row, columns, tableWidth)
    local columnX = 0
    local columnIndex
    for columnIndex = 1, table.getn(columns) do
        local column = columns[columnIndex]
        local width = math.floor(tableWidth * column.fraction)
        local cell = row[column.key]
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", row, "TOPLEFT", columnX + (column.key == "name" and 7 or 0), -1)
        cell:SetWidth(math.max(1, width - (column.key == "name" and 14 or 6)))
        cell:Show()
        columnX = columnX + width
    end
end

function RosterManagement.LayoutColumns(page, rows, columns, tableWidth, headerY)
    HideColumns(rows, page.guildColumns)
    HideColumns(rows, page.playerColumns)
    local columnX = 0
    local columnIndex
    for columnIndex = 1, table.getn(columns) do
        local column = columns[columnIndex]
        local width = math.floor(tableWidth * column.fraction)
        column.header:ClearAllPoints()
        column.header:SetPoint("TOPLEFT", page, "TOPLEFT", 12 + columnX, headerY)
        column.header:SetWidth(math.max(1, width - 6))
        column.header:Show()
        local rowIndex
        for rowIndex = 1, table.getn(rows) do
            local cell = rows[rowIndex][column.key]
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", rows[rowIndex], "TOPLEFT", columnX, -1)
            cell:SetWidth(math.max(1, width - (column.key == "name" and 14 or 6)))
            cell:Show()
        end
        columnX = columnX + width
    end
end

local function SetRowTextColor(row, shade)
    row.officer:SetTextColor(shade, shade, shade)
    row.name:SetTextColor(shade, shade, shade)
    row.level:SetTextColor(shade, shade, shade)
    row.class:SetTextColor(shade, shade, shade)
    row.rank:SetTextColor(shade, shade, shade)
    row.notes:SetTextColor(shade, shade, shade)
    row.zone:SetTextColor(shade, shade, shade)
    row.lastOnline:SetTextColor(shade, shade, shade)
end

function RosterManagement.BindRow(row, member, visibleIndex, selectedName, rowHeight, lowestRankIndex, useClassColors)
    row.name:SetText(member.name or "")
    row.level:SetText(member.level or "")
    row.class:SetText(member.class or "")
    row.rank:SetText(member.rank or "")
    row.notes:SetText(member.publicNote or "")
    row.officer:SetText(MOS.Services.Roster.CanManage("viewOfficerNote") and (member.officerNote or "") or "")
    row.zone:SetText(member.zone or "")
    row.lastOnline:SetText(RosterManagement.FormatLastOnline(member))
    row.hover:Hide()
    row.displayedMember = member
    row.visibleIndex = visibleIndex
    local shade = member.online and 1 or 0.48
    SetRowTextColor(row, shade)
    if useClassColors then
        local classKey = string.upper(member.classFile or member.class or "")
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]) or MOS.UI.Components.Theme.classColors[classKey]
        if classColor then
            row.name:SetTextColor(classColor.r * shade, classColor.g * shade, classColor.b * shade)
            row.class:SetTextColor(classColor.r * shade, classColor.g * shade, classColor.b * shade)
        end
    end
    if member.name == selectedName then
        row.selection:Show()
        row:SetBackdropColor(0.16, 0.20, 0.17, 0.82)
        row:SetBackdropBorderColor(0.46, 0.55, 0.47, 0.90)
        row.actionPanel:Show()
        row:SetHeight(rowHeight + 208)
        RosterManagement.BindMemberDetails(row, member)
        row:Show()
        return rowHeight + 208
    end
    row.selection:Hide()
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row.actionPanel:Hide()
    row:SetHeight(rowHeight)
    row:Show()
    return rowHeight
end

function RosterManagement.HideRow(row)
    row.displayedMember = nil
    row.selection:Hide()
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)
    row.actionPanel:Hide()
    row:Hide()
end

local function OnListScroll()
    FauxScrollFrame_OnVerticalScroll(this.rowHeight, this.refreshCallback)
end

function RosterManagement.CreateListController(page, rowHeight, rowController)
    local controller = {
        page = page,
        rows = {},
        rowCount = 0,
        rowHeight = rowHeight,
        rowController = rowController,
    }
    controller.scrollFrame = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteRosterScrollFrame", page, "FauxScrollFrameTemplate")
    controller.scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", -4, -145)
    controller.scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -12, 18)
    controller.scrollFrame.rowHeight = rowHeight
    controller.scrollFrame:SetScript("OnVerticalScroll", OnListScroll)
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteRosterScrollFrameScrollBar"))
    page.listController = controller
    return controller
end

function RosterManagement.SetListRefreshCallback(controller, refreshCallback)
    controller.scrollFrame.refreshCallback = refreshCallback
end

function RosterManagement.EnsureRowPool(controller, requiredCount, columns, tableWidth)
    while controller.rowCount < requiredCount do
        controller.rowCount = controller.rowCount + 1
        local row = RosterManagement.CreateRow(controller.page, controller.rowCount, controller.rowHeight, controller.rowController)
        controller.rows[controller.rowCount] = row
        row.name:Hide(); row.zone:Hide(); row.level:Hide(); row.class:Hide()
        row.rank:Hide(); row.notes:Hide(); row.officer:Hide(); row.lastOnline:Hide()
        RosterManagement.ApplyRowColumns(row, columns, tableWidth)
    end
end

local function OnModeToggle()
    local page = this.rosterPage
    page.statusMode = not page.statusMode
    this.label:SetText(page.statusMode and "Show Guild Status" or "Show Player Status")
    this.modeChangedCallback()
end

function RosterManagement.AttachModeToggle(page, button, modeChangedCallback)
    page.statusMode = false
    button.rosterPage = page
    button.modeChangedCallback = modeChangedCallback
    button:SetScript("OnClick", OnModeToggle)
end

function RosterManagement.CreateVisibilityController(options)
    local controller = options
    options.page.visibilityController = controller
    return controller
end

function RosterManagement.SetDataVisible(controller, visible)
    local method = visible and "Show" or "Hide"
    local page = controller.page
    local controls = controller.controls
    page.fittedPanel[method](page.fittedPanel)
    if visible then
        controller.contentPanel:SetBackdropColor(0, 0, 0, 0)
        controller.contentPanel:SetBackdropBorderColor(0, 0, 0, 0)
        controller.contentShade:Hide()
    else
        controller.contentPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.90)
        controller.contentPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
        controller.contentShade:Show()
    end
    controls.footer.rule[method](controls.footer.rule)
    controls.filtersLabel[method](controls.filtersLabel)
    controls.searchLabel[method](controls.searchLabel)
    controls.searchBox[method](controls.searchBox)
    controls.classFilter[method](controls.classFilter)
    controls.rankFilter[method](controls.rankFilter)
    controls.showOffline[method](controls.showOffline)
    controls.showOffline.label[method](controls.showOffline.label)
    controls.modeButton[method](controls.modeButton)
    page.listHeaderUI.notes[method](page.listHeaderUI.notes)
    page.listController.scrollFrame[method](page.listController.scrollFrame)
    controller.sortHint:Hide()
    controller.refreshButton[method](controller.refreshButton)
    controller.infoButton[method](controller.infoButton)
    controller.addButton[method](controller.addButton)
    controller.controlButton[method](controller.controlButton)
    if not MOS.Services.Roster.CanManage("invite") then controller.addButton:Hide() end
    if not MOS.Services.Roster.CanManage("control") then controller.controlButton:Hide() end
    controls.footer[method](controls.footer)
    local i
    for i = 1, table.getn(page.listHeaderUI.buttons) do
        local header = page.listHeaderUI.buttons[i]
        header[method](header)
    end
    if not visible then
        page.listHeaderUI.zone:Hide()
        page.listHeaderUI.lastOnline:Hide()
        page.officerHeader:Hide()
        controller.scanSaveButton:Hide()
        page.filterController:Hide()
        for i = 1, table.getn(page.listController.rows) do page.listController.rows[i]:Hide() end
    else
        controller.scanSaveButton:ClearAllPoints()
        controller.scanSaveButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -128, -48)
        controller.scanSaveButton:SetWidth(120)
        controller.scanSaveButton:SetHeight(22)
        controller.scanSaveButton:Show()
    end
end

function RosterManagement.RenderList(page, visibleMembers, columns, selectedName, lowestRankIndex, useClassColors, resetScroll, headerY)
    local controller = page.listController
    local rows = controller.rows
    local rowHeight = controller.rowHeight
    local tableWidth = math.max(1, page:GetWidth() - 42)
    RosterManagement.LayoutColumns(page, rows, columns, tableWidth, headerY)
    if resetScroll == true then
        controller.scrollFrame.offset = 0
        controller.scrollFrame:SetVerticalScroll(0)
    end
    local availableHeight = math.max(0, page.tableViewport:GetHeight())
    local visibleRowCount = RosterManagement.CalculateVisibleRows(availableHeight, rowHeight, selectedName ~= nil)
    RosterManagement.EnsureRowPool(controller, visibleRowCount, columns, tableWidth)
    controller.scrollFrame:ClearAllPoints()
    controller.scrollFrame:SetPoint("TOPLEFT", page.tableViewport, "TOPLEFT", -8, 9)
    controller.scrollFrame:SetPoint("TOPRIGHT", page.tableViewport, "TOPRIGHT", 0, 9)
    controller.scrollFrame:SetHeight((visibleRowCount * rowHeight) + 8)
    if selectedName and selectedName ~= controller.lastSelectedName then
        local memberIndex
        for memberIndex = 1, table.getn(visibleMembers) do
            if visibleMembers[memberIndex].name == selectedName then
                local current = controller.scrollFrame.offset or 0
                controller.scrollFrame.offset = math.max(0, math.min(current, memberIndex - 1))
                if memberIndex > controller.scrollFrame.offset + visibleRowCount then
                    controller.scrollFrame.offset = math.max(0, memberIndex - visibleRowCount)
                end
                break
            end
        end
    end
    controller.lastSelectedName = selectedName
    local offset = MOS.UI.Components.UpdateScrollFrame(controller.scrollFrame, table.getn(visibleMembers), visibleRowCount, rowHeight)
    page.measuredCapacity = visibleRowCount
    page.measuredOffset = offset
    page.measuredCount = table.getn(visibleMembers)
    page.measuredHeight = availableHeight
    page.measuredShown = 0
    local rowY = 0
    local i
    for i = 1, controller.rowCount do
        local member = visibleMembers[offset + i]
        local row = rows[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", page.tableViewport, "TOPLEFT", 0, rowY)
        row:SetPoint("TOPRIGHT", page.tableViewport, "TOPRIGHT", 0, rowY)
        if member and i <= visibleRowCount then
            page.measuredShown = page.measuredShown + 1
            rowY = rowY - RosterManagement.BindRow(row, member, offset + i, selectedName, rowHeight, lowestRankIndex, useClassColors)
        else
            RosterManagement.HideRow(row)
        end
    end
end

function RosterManagement.UpdateSortHeaders(page, sortKey)
    local i
    for i = 1, table.getn(page.listHeaderUI.buttons) do
        local button = page.listHeaderUI.buttons[i]
        button.label:SetText(button.baseText)
        if button.sortKey == sortKey then button.label:SetTextColor(1, 1, 1)
        else button.label:SetTextColor(1, 0.82, 0) end
    end
end

local function OnDataScanClick()
    if this.inactive then return end
    this.dataController.startSharedScan("roster")
end

function RosterManagement.CreateDataController(options)
    local controller = options
    controller.ready = false
    controller.liveTracking = false
    options.page.dataController = controller
    options.scanButton.dataController = controller
    options.refreshButton.dataController = controller
    options.scanButton:SetScript("OnClick", OnDataScanClick)
    options.refreshButton:SetScript("OnClick", OnDataScanClick)
    return controller
end

function RosterManagement.MountControllers(page, options)
    local guildControls = options.guildControls
    RosterManagement.CreateVisibilityController({
        page = page,
        controls = page.layoutControls,
        contentPanel = options.contentPanel,
        contentShade = options.contentShade,
        sortHint = options.sortHint,
        refreshButton = guildControls.refreshButton,
        infoButton = page.guildInfoButton,
        addButton = page.guildAddButton,
        controlButton = page.guildControlButton,
        scanSaveButton = guildControls.exportButton,
    })
    return RosterManagement.CreateDataController({
        page = page,
        scanButton = guildControls.scanButton,
        refreshButton = guildControls.refreshButton,
        startSharedScan = options.startSharedScan,
        requestScan = options.requestScan,
        printMessage = options.printMessage,
        buildSnapshot = options.buildSnapshot,
        storeSnapshot = options.storeSnapshot,
        refresh = options.refresh,
    })
end

function RosterManagement.CreateRenderer(options)
    return options
end

function RosterManagement.RefreshView(renderer, data, guildName, resetScroll, sortKey, selectedMemberName)
    local page = renderer.page
    if not RosterManagement.IsReady(page.dataController) then
        RosterManagement.SetDataVisible(page.visibilityController, false)
        renderer.scanButton:Show()
        renderer.statusText:Show(); renderer.summaryText:Show()
        renderer.statusText:SetText("")
        renderer.summaryText:SetText("")
        return
    end

    renderer.scanButton:Hide()
    RosterManagement.SetDataVisible(page.visibilityController, true)
    renderer.statusText:Hide(); renderer.summaryText:Hide()
    local onlineCount = 0
    local memberCount = data and data.members and table.getn(data.members) or 0
    if data and data.members then
        local memberIndex
        for memberIndex = 1, memberCount do
            if data.members[memberIndex].online then onlineCount = onlineCount + 1 end
        end
    end
    renderer.summaryText:SetWidth(math.max(1, page:GetWidth() - 180))
    renderer.summaryText:SetText("|cffffffff" .. memberCount .. "|r |cffffd100Guild Members|r  |  |cffffffff" .. onlineCount .. "|r |cffffd100Online|r")
    renderer.summaryText:Show()
    local rosterShift = RosterManagement.LayoutChrome(page, page.layoutControls, renderer.getMotd())
    local query = string.lower(renderer.searchBox:GetText() or "")
    query = string.gsub(query, "^%s*(.-)%s*$", "%1")

    page.filterController:Build(data)
    RosterManagement.FilterMembers(renderer.visibleMembers, data, query, renderer.selectedClasses, renderer.selectedRanks, MuklaOfficerSuiteDB.showOfflineMembers)
    table.sort(renderer.visibleMembers, renderer.sortMembers)

    if not guildName then
        renderer.statusText:SetText("No guild found.")
    elseif not data then
        renderer.statusText:SetText(guildName .. " - no saved roster. Use Export Roster to scan.")
    elseif query ~= "" or table.getn(renderer.visibleMembers) ~= memberCount then
        renderer.statusText:SetText(guildName .. " - showing " .. table.getn(renderer.visibleMembers) .. " of " .. memberCount .. " members")
    else
        renderer.statusText:SetText(guildName .. " - " .. memberCount .. " members")
    end

    page.showOfflineCheck:SetChecked(MuklaOfficerSuiteDB.showOfflineMembers and 1 or nil)
    local columns = page.statusMode and page.playerColumns or page.guildColumns
    local lowestRankIndex = renderer.getLowestRankIndex(data)
    RosterManagement.RenderList(page, renderer.visibleMembers, columns, selectedMemberName, lowestRankIndex, MuklaOfficerSuiteDB.rosterClassColors, resetScroll, -132 - rosterShift)
    renderer.summaryText:ClearAllPoints()
    renderer.summaryText:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 12, 12)
    RosterManagement.UpdateSortHeaders(page, sortKey)
end

function RosterManagement.SetReady(controller, ready)
    controller.ready = ready and true or false
end

function RosterManagement.IsReady(controller)
    return controller.ready
end

function RosterManagement.SetRefreshPending(controller, pending)
    controller.refreshPending = pending and true or false
    local configuredTracking = controller.page:IsVisible() and MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.rosterLiveTrackingEnabled
    controller.refreshButton:SetInactive(controller.refreshPending or controller.liveTracking or configuredTracking)
end

function RosterManagement.HandleGuildRosterUpdate(controller, scanCompleted, scanPending)
    if not controller.liveTracking or scanCompleted or scanPending then return false end
    local snapshot = controller.buildSnapshot(GetTime())
    if not snapshot then return false end
    controller.storeSnapshot(snapshot)
    controller.ready = true
    controller.refresh(false)
    return true
end

function RosterManagement.DeactivateDataController(controller)
    if not controller.liveTracking then return end
    controller.liveTracking = false
    controller.refreshButton:SetInactive(controller.refreshPending)
end

function RosterManagement.ActivateDataController(controller, scanAlreadyStarted)
    MOS.Database.Ensure()
    if not MuklaOfficerSuiteDB.rosterLiveTrackingEnabled then
        controller.liveTracking = false
        controller.refreshButton:SetInactive(controller.refreshPending)
        return
    end
    controller.liveTracking = true
    if not scanAlreadyStarted and not controller.requestScan("quiet") then
        controller.liveTracking = false
    end
    controller.refreshButton:SetInactive(controller.refreshPending or controller.liveTracking)
end

function RosterManagement.CreateLifecycle(page, dataController, refresh)
    return {
        Hide = function(self)
            RosterManagement.DeactivateDataController(dataController)
            page.filterController:Hide()
            page:Hide()
        end,
        Show = function(self)
            page:Show()
            refresh(false)
            local scanStarted = dataController.startSharedScan("roster")
            RosterManagement.ActivateDataController(dataController, scanStarted)
        end,
        Refresh = function(self) refresh(false) end,
        OnResize = function(self) refresh(false) end,
    }
end

function RosterManagement.AttachInteractions(options)
    local page = options.page
    options.exportButton:SetScript("OnClick", function() options.requestScan("reload") end)
    page.showOfflineCheck:SetScript("OnClick", function()
        options.ensureDatabase()
        MOS.Database.SetSetting("showOfflineMembers", this:GetChecked() and true or false)
        options.clearSelection()
        options.refresh(true)
    end)
    RosterManagement.AttachModeToggle(page, page.modeButton, function()
        options.clearSelection()
        options.refresh(false)
    end)
    options.searchBox:SetScript("OnTextChanged", function() options.refresh(true) end)
    RosterManagement.SetListRefreshCallback(options.listController, options.refresh)

    page.layoutElapsed = 0; page.layoutWidth = 0; page.layoutHeight = 0
    page.tableViewport:SetScript("OnSizeChanged", function()
        if page:IsVisible() and math.abs(this:GetHeight() - (page.measuredHeight or 0)) > 0.5 then
            page.viewportChanged = true
            page:SetScript("OnUpdate", page.finishLayout)
        end
    end)
    page:SetScript("OnSizeChanged", function()
        if this:IsVisible() then this:SetScript("OnUpdate", this.finishLayout) end
    end)
    page.finishLayout = function()
        this:SetScript("OnUpdate", nil)
        local currentWidth, currentHeight = this:GetWidth(), this:GetHeight()
        if RosterManagement.NeedsLayout(currentWidth, currentHeight, this.layoutWidth, this.layoutHeight, this.viewportChanged) then
            this.viewportChanged = nil
            this.layoutWidth = currentWidth; this.layoutHeight = currentHeight
            options.refresh(false)
        end
    end
    page:SetScript("OnHide", function()
        this:SetScript("OnUpdate", nil); this.fittedPanel:Hide()
        if this.memberMenu then this.memberMenu:Hide() end
        if this.memberReport then this.memberReport:Hide() end
        if this.noteEditor then this.noteEditor:Hide() end
        options.contentPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.90)
        options.contentPanel:SetBackdropBorderColor(0.36, 0.36, 0.34, 1)
        options.contentShade:Show()
    end)
end

function RosterManagement.LayoutChrome(page, controls, motdText)
    local width = page:GetWidth()
    controls.footer.guild:SetText("Guild Message Of The Day:")
    controls.footer.guild:SetWidth(math.max(1, width - 24))
    controls.footer.guild:SetJustifyH("LEFT")
    controls.footer.guild:SetHeight(0)
    controls.footer.motd:ClearAllPoints()
    controls.footer.motd:SetPoint("TOPLEFT", controls.footer.guild, "BOTTOMLEFT", 0, -6)
    controls.footer.motd:SetWidth(math.max(1, width - 24))
    controls.footer.motd:SetHeight(0)
    controls.footer.motd:SetText(motdText or "Guild Message of the Day")
    controls.footer:ClearAllPoints()
    controls.footer:SetPoint("TOPLEFT", page, "TOPLEFT", 4, -78)
    controls.footer:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -78)
    controls.footer:SetHeight(20 + controls.footer.guild:GetStringHeight() + controls.footer.motd:GetStringHeight())

    local shift = controls.footer:GetHeight() - 10
    controls.filtersLabel:ClearAllPoints()
    controls.filtersLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -112 - shift)
    controls.classFilter:ClearAllPoints()
    controls.classFilter:SetPoint("TOPLEFT", page, "TOPLEFT", 50, -106 - shift)
    controls.classFilter:SetWidth(width < 650 and 60 or 84)
    controls.rankFilter:ClearAllPoints()
    controls.rankFilter:SetPoint("LEFT", controls.classFilter, "RIGHT", 8, 0)
    controls.rankFilter:SetWidth(width < 650 and 60 or 84)
    controls.searchLabel:ClearAllPoints()
    controls.searchLabel:SetPoint("LEFT", controls.rankFilter, "RIGHT", 10, 0)
    controls.searchBox:ClearAllPoints()
    controls.searchBox:SetPoint("LEFT", controls.searchLabel, "RIGHT", 8, 0)
    controls.searchBox:SetWidth(math.max(40, math.min(178, width - (width < 650 and 470 or 520))))
    controls.showOffline.label:ClearAllPoints()
    controls.showOffline.label:SetPoint("LEFT", controls.searchBox, "RIGHT", 10, 0)
    controls.showOffline:ClearAllPoints()
    controls.showOffline:SetPoint("LEFT", controls.showOffline.label, "RIGHT", 4, 0)
    controls.refreshButton:ClearAllPoints()
    controls.refreshButton:SetPoint("LEFT", controls.showOffline, "RIGHT", 4, 0)
    controls.status:ClearAllPoints()
    controls.status:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 12, 12)
    controls.status:SetHeight(14)
    controls.modeButton:ClearAllPoints()
    controls.modeButton:SetPoint("RIGHT", page, "BOTTOMRIGHT", -4, 19)
    controls.modeButton.label:ClearAllPoints()
    controls.modeButton.label:SetPoint("RIGHT", controls.modeButton, "LEFT", -4, 0)

    local actionCount = table.getn(controls.actions)
    local baseWidth, visibleCount = 0, 0
    local actionIndex
    for actionIndex = 1, actionCount do
        local action = controls.actions[actionIndex]
        action.available = not action.permission or MOS.Services.Roster.CanManage(action.permission)
        if action.available then baseWidth = baseWidth + action.width; visibleCount = visibleCount + 1 end
    end
    baseWidth = math.max(1, baseWidth + math.max(0, visibleCount - 1) * 6)
    local availableWidth = math.max(1, width - 24)
    local widthScale = math.min(1, availableWidth / baseWidth)
    local actionX = 12
    for actionIndex = 1, actionCount do
        local action = controls.actions[actionIndex]
        if action.available then
            action.button:Show()
            action.button:ClearAllPoints()
            action.button:SetScale(1)
            action.button:SetWidth(math.floor(action.width * widthScale))
            action.button:SetHeight(22)
            action.button:SetPoint("TOPLEFT", page, "TOPLEFT", actionX, -42)
            actionX = actionX + math.floor(action.width * widthScale) + 6
        else action.button:Hide() end
    end
    return shift
end

function RosterManagement.CreateMemberDetails(row)
    local C, panel = MOS.UI.Components, row.actionPanel
    row.details = {}
    local function Text(key, y, color, small)
        local label = small and C.CreateColumnLabel(panel, "", color) or C.CreateComponentLabel(panel, "", color)
        label:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, y)
        label:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, y); label:SetJustifyH("LEFT")
        row.details[key] = label
        return label
    end
    Text("name", -10, "orange")
    Text("level", -29, "white", true)
    Text("rank", -47, "orange")
    Text("lastOnline", -67, "orange")
    local function Note(key, title)
        local field = C.CreateNoteDisplay(panel, 82)
        field.title = C.CreateComponentLabel(panel, title, "orange")
        field.title:SetPoint("BOTTOMLEFT", field, "TOPLEFT", 0, 6)
        field:SetScript("OnClick", function() RosterManagement.OpenNoteEditor(row, key) end)
        row[key .. "Field"] = field
    end
    Note("publicNote", "Public Note:")
    Note("officerNote", "Officer's Note:")
end

function RosterManagement.OpenNoteEditor(row, key)
    local page, C, service = row:GetParent(), MOS.UI.Components, MOS.Services.Roster
    local member = row.displayedMember
    if not member or not service.CanManage(key) then return end
    if not page.noteEditor then
        page.noteEditor = C.CreateTextEditor("MuklaOfficerSuiteRosterNoteEditor", "", 31, function(value)
            local target = page.noteTarget
            if not target or not service.PerformMemberAction(target.key, target.name, value) then
                page.noteEditor:SetMessage("You cannot edit this note.", true); return false
            end
            target.member[target.key] = value
            if target.row.displayedMember == target.member then
                RosterManagement.BindMemberDetails(target.row, target.member)
                target.row.notes:SetText(target.member.publicNote or "")
            end
            if target.row.controller.onAction then target.row.controller.onAction("refresh") end
            return true
        end)
        page.noteEditor.save:SetText("Accept")
    end
    page.noteTarget = { name = member.name, member = member, row = row, key = key }
    page.noteEditor.title:SetText(key == "publicNote" and "Set Player Note" or "Set Officer Note")
    page.noteEditor:Open(member[key] or ""); page.noteEditor:BringToFront(600)
end

function RosterManagement.BindMemberDetails(row, member)
    local C, service = MOS.UI.Components, MOS.Services.Roster
    if not row.details then RosterManagement.CreateMemberDetails(row) end
    local officerVisible = service.CanManage("viewOfficerNote")
    row.officer:SetText(officerVisible and (member.officerNote or "") or "")
    row.details.name:SetText(member.name or "")
    row.details.level:SetText("Level " .. tostring(member.level or 0) .. " " .. (member.class or ""))
    row.details.rank:SetText("Rank: |cffffffff" .. (member.rank or "Unknown") .. "|r")
    row.details.lastOnline:SetText("Last online: " .. (member.online and "|cffffffffOnline|r" or "|cff808080" .. RosterManagement.FormatLastOnline(member) .. " ago|r"))
    local public, officer = row.publicNoteField, row.officerNoteField
    public:ClearAllPoints(); public:SetPoint("TOPLEFT", row.actionPanel, "TOPLEFT", 12, -110)
    public:SetPoint("TOPRIGHT", row.actionPanel, officerVisible and "TOP" or "TOPRIGHT", officerVisible and -6 or -12, -110)
    public:SetText(member.publicNote and member.publicNote ~= "" and member.publicNote or "Click to set a public note.")
    public:EnableMouse(service.CanManage("publicNote"))
    officer:ClearAllPoints(); officer:SetPoint("TOPLEFT", row.actionPanel, "TOP", 6, -110)
    officer:SetPoint("TOPRIGHT", row.actionPanel, "TOPRIGHT", -12, -110)
    if officerVisible then
        officer:Show(); officer.title:Show()
        officer:SetText(member.officerNote and member.officerNote ~= "" and member.officerNote or "Click to set an officer note.")
        officer:EnableMouse(service.CanManage("officerNote"))
    else officer:SetText(""); officer:Hide(); officer.title:Hide() end
    local arrowX = -12
    local _, action
    for _, action in ipairs({ "demote", "promote" }) do
        local button = row[action .. "Button"]
        if service.CanManage(action, member) then
            button:ClearAllPoints(); button:SetPoint("TOPRIGHT", row.actionPanel, "TOPRIGHT", arrowX, -44)
            button:Enable(); button:Show(); arrowX = arrowX - 24
        else button:Hide() end
    end
    row.details.rank:ClearAllPoints()
    row.details.rank:SetPoint("TOPLEFT", row.actionPanel, "TOPLEFT", 12, -47)
    row.details.rank:SetPoint("TOPRIGHT", row.actionPanel, "TOPRIGHT", arrowX - 4, -47)
end

function RosterManagement.OpenMemberMenu(row)
    local page, C = row:GetParent(), MOS.UI.Components
    if not page.memberMenu then
        page.memberMenu = C.CreateContextMenu(page, {
            { "Whisper", "whisper" }, { "Invite", "group" }, { "Target", "target" },
            { "Report", "report" }, { "Ignore Player", "ignore" },
        }, function(action)
            local name = page.contextMemberName
            if action == "report" then
                if not page.memberReport then
                    page.memberReport = C.CreateTextEditor("MuklaOfficerSuiteRosterReport", "Report player", 1000, function(reason)
                        if MOS.Services.Roster.PerformSocialAction("report", page.reportMemberName, reason) then page.memberReport:Hide()
                        else page.memberReport:SetMessage("Enter a reason; reporting requires GM ticket support.", true); return false end
                    end)
                    page.memberReport.save:SetText("Submit")
                end
                page.reportMemberName = name
                page.memberReport:Open(""); page.memberReport:BringToFront(600); page.memberReport:SetMessage("Report " .. name .. ": describe the issue for a GM.", false)
            else MOS.Services.Roster.PerformSocialAction(action, name) end
        end)
    end
    page.memberMenu.title:SetText(row.displayedMember.name)
    page.contextMemberName = row.displayedMember.name
    page.memberMenu:Open(row)
end

function RosterManagement.BindPermissionEvents(page)
    local watcher = MOS.UI.Components.CreateContainer(nil, page)
    local function Refresh()
        local C, service = MOS.UI.Components, MOS.Services.Roster
        if service.CanManage("invite") then page.guildAddButton:Show() else page.guildAddButton:Hide() end
        if service.CanManage("control") then page.guildControlButton:Show() else page.guildControlButton:Hide() end
        if page.layoutControls then RosterManagement.LayoutChrome(page, page.layoutControls, page.footer.motd:GetText()) end
        if page.listController then
            local _, row
            for _, row in ipairs(page.listController.rows) do
                if row.displayedMember and row.actionPanel:IsVisible() and row.details then RosterManagement.BindMemberDetails(row, row.displayedMember) end
            end
        end
    end
    watcher:SetScript("OnEvent", Refresh)
    watcher:SetScript("OnShow", function() watcher:RegisterEvent("GUILD_ROSTER_UPDATE"); watcher:RegisterEvent("PLAYER_GUILD_UPDATE"); Refresh() end)
    watcher:SetScript("OnHide", function() watcher:UnregisterEvent("GUILD_ROSTER_UPDATE"); watcher:UnregisterEvent("PLAYER_GUILD_UPDATE") end)
    page.permissionWatcher = watcher
end
