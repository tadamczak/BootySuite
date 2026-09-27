local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local GuildStatistics = {}
MOS.Modules.GuildStatistics = GuildStatistics

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

local function OnSummaryClick()
    local entry = this.entry
    if not entry or entry.kind ~= "summary" then return end
    local controller = this.statisticsController
    if controller.expandedType == entry.statsType and controller.expandedValue == entry.value then
        controller.expandedType = nil
        controller.expandedValue = nil
    else
        controller.expandedType = entry.statsType
        controller.expandedValue = entry.value
    end
    controller.refresh()
end

local function OnTableScroll()
    FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback)
end

local function ShortText(text, length)
    text = tostring(text or "")
    if string.len(text) > length then return string.sub(text, 1, length - 1) .. "~" end
    return text
end

local function SortClassNames(a, b)
    return string.lower(a) < string.lower(b)
end

local function SortRanks(a, b)
    if a.index == b.index then return string.lower(a.name) < string.lower(b.name) end
    return a.index < b.index
end

function GuildStatistics.CreateSummaryState()
    return {
        classes = {},
        ranks = {},
        classNames = {},
        rankList = {},
        classSummaries = {},
        included = 0,
        total = 0,
    }
end

local function ClearArray(values)
    local index
    for index = table.getn(values), 1, -1 do values[index] = nil end
end

function GuildStatistics.BuildSummary(state, data, onlyLevel60)
    local className
    for className in pairs(state.classes) do state.classes[className] = 0 end
    local rankName, rankData
    for rankName, rankData in pairs(state.ranks) do rankData.count = 0 end
    ClearArray(state.classNames)
    ClearArray(state.rankList)
    state.included = 0
    state.total = table.getn(data.members)
    local memberIndex
    for memberIndex = 1, state.total do
        local member = data.members[memberIndex]
        if not onlyLevel60 or (tonumber(member.level) or 0) == 60 then
            className = member.class ~= "" and member.class or "Unknown"
            if not state.classes[className] or state.classes[className] == 0 then
                state.classes[className] = 0
                table.insert(state.classNames, className)
            end
            state.classes[className] = state.classes[className] + 1
            rankName = member.rank ~= "" and member.rank or "Unknown"
            rankData = state.ranks[rankName]
            if not rankData then
                rankData = { name = rankName, count = 0, index = 999 }
                state.ranks[rankName] = rankData
            end
            if rankData.count == 0 then table.insert(state.rankList, rankData) end
            rankData.index = tonumber(member.rankIndex) or 999
            rankData.count = rankData.count + 1
            state.included = state.included + 1
        end
    end
    table.sort(state.classNames, SortClassNames)
    table.sort(state.rankList, SortRanks)
    local classCount = table.getn(state.classNames)
    local index
    for index = 1, classCount do
        local summary = state.classSummaries[index]
        if not summary then summary = {}; state.classSummaries[index] = summary end
        summary.name = state.classNames[index]
        summary.count = state.classes[summary.name]
    end
    for index = table.getn(state.classSummaries), classCount + 1, -1 do state.classSummaries[index] = nil end
    return state
end

function GuildStatistics.CreateTable(page, name, x, width, controller)
    local statsTable = { entries = {}, entryPool = {}, memberScratch = {}, rows = {}, controller = controller }
    statsTable.scroll = CreateFrame("ScrollFrame", name, page, "FauxScrollFrameTemplate")
    statsTable.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", x - 4, -148)
    statsTable.scroll:SetWidth(width); statsTable.scroll:SetHeight(224)
    statsTable.scroll.refreshCallback = controller.refresh
    statsTable.scroll:SetScript("OnVerticalScroll", OnTableScroll)
    MOS.UI.RegisterSkinnedScrollBar(getglobal(name .. "ScrollBar"))
    local rowIndex
    for rowIndex = 1, 25 do
        local row = CreateFrame("Button", nil, page)
        row:SetPoint("TOPLEFT", page, "TOPLEFT", x, -152 - ((rowIndex - 1) * 24))
        row:SetWidth(width - 16); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        row:SetBackdropColor(0, 0, 0, 0); row:SetBackdropBorderColor(0, 0, 0, 0)
        MOS.UI.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
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
        row.statisticsController = controller
        row:SetScript("OnClick", OnSummaryClick)
        row:Hide(); statsTable.rows[rowIndex] = row
    end
    statsTable.scroll:Hide()
    return statsTable
end

local function SortMembers(a, b)
    local aRank, bRank = tonumber(a.rankIndex) or 999, tonumber(b.rankIndex) or 999
    if aRank == bRank then return string.lower(a.name or "") < string.lower(b.name or "") end
    return aRank < bRank
end

local function AcquireEntry(statsTable, index)
    local entry = statsTable.entryPool[index]
    if not entry then entry = {}; statsTable.entryPool[index] = entry end
    statsTable.entries[index] = entry
    return entry
end

function GuildStatistics.PopulateTable(statsTable, summaries, statsType, data, onlyLevel60, classIcons)
    local expandedType = statsTable.controller.expandedType
    local expandedValue = statsTable.controller.expandedValue
    local entries = statsTable.entries
    local entriesCount = table.getn(entries)
    while entriesCount > 0 do entries[entriesCount] = nil; entriesCount = entriesCount - 1 end
    local entryCount = 0
    local summaryIndex
    for summaryIndex = 1, table.getn(summaries) do
        local summary = summaries[summaryIndex]
        entryCount = entryCount + 1
        local entry = AcquireEntry(statsTable, entryCount)
        entry.kind = "summary"; entry.statsType = statsType; entry.value = summary.name; entry.count = summary.count; entry.member = nil
        if expandedType == statsType and expandedValue == summary.name then
            local members = statsTable.memberScratch
            local memberCount = table.getn(members)
            while memberCount > 0 do members[memberCount] = nil; memberCount = memberCount - 1 end
            local memberIndex
            for memberIndex = 1, table.getn(data.members) do
                local member = data.members[memberIndex]
                local matches = (statsType == "class" and member.class == summary.name) or (statsType == "rank" and member.rank == summary.name)
                if matches and (not onlyLevel60 or tonumber(member.level) == 60) then table.insert(members, member) end
            end
            table.sort(members, SortMembers)
            for memberIndex = 1, table.getn(members) do
                entryCount = entryCount + 1
                entry = AcquireEntry(statsTable, entryCount)
                entry.kind = "member"; entry.statsType = nil; entry.value = nil; entry.count = nil; entry.member = members[memberIndex]
            end
        end
    end
    local visibleRows = statsTable.visibleRows or table.getn(statsTable.rows)
    local offset = MOS.UI.UpdateScrollFrame(statsTable.scroll, table.getn(entries), visibleRows, 24)
    local rowIndex
    for rowIndex = 1, table.getn(statsTable.rows) do
        local row = statsTable.rows[rowIndex]
        local entry = entries[offset + rowIndex]
        row.entry = entry
        if entry and rowIndex <= visibleRows then
            local expanded = entry.kind == "summary" and expandedType == statsType and expandedValue == entry.value
            MOS.UI.ApplyRowBackground(row, offset + rowIndex, expanded)
            if entry.kind == "summary" then
                row.icon:SetTexture(statsType == "class" and (classIcons[entry.value] or "Interface\\Icons\\INV_Misc_QuestionMark") or nil)
                if statsType == "class" then row.icon:Show() else row.icon:Hide() end
                row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", statsType == "class" and 28 or 0, 0)
                row.name:SetWidth(statsType == "class" and 132 or 180)
                row.name:SetText(entry.value .. (expanded and "  ^" or ""))
                row.count:SetText(entry.count); row.count:Show(); row.rank:Hide(); row.level:Hide()
            else
                row.icon:Hide(); row.count:Hide()
                row.name:ClearAllPoints(); row.name:SetPoint("LEFT", row, "LEFT", 12, 0); row.name:SetWidth(82); row.name:SetText(statsTable.controller.shortText(entry.member.name, 12))
                row.rank:SetWidth(onlyLevel60 and 116 or 96); row.rank:SetText(statsTable.controller.shortText(entry.member.rank, 18)); row.rank:Show()
                if onlyLevel60 then row.level:Hide() else row.level:SetText(entry.member.level or ""); row.level:Show() end
            end
            row:Show()
        else
            row:Hide()
        end
    end
end

function GuildStatistics.CreateView(page, styleButton, refresh)
    local view = { page = page }
    view.title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    view.title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    view.title:SetText("Guild Statistics")
    view.onlyLevel60 = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    view.onlyLevel60:SetPoint("TOPRIGHT", page, "TOPRIGHT", -225, -42)
    view.onlyLevel60:SetWidth(22); view.onlyLevel60:SetHeight(22); view.onlyLevel60:SetChecked(true)
    view.onlyLevel60.label = view.onlyLevel60:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    view.onlyLevel60.label:SetPoint("LEFT", view.onlyLevel60, "RIGHT", 2, 0)
    view.onlyLevel60.label:SetText("Only level 60"); view.onlyLevel60:Hide()
    view.lastScan = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    view.lastScan:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -48); view.lastScan:SetWidth(360); view.lastScan:SetJustifyH("LEFT"); view.lastScan:Hide()
    view.refreshButton = CreateFrame("Button", nil, page)
    view.refreshButton:SetWidth(108); view.refreshButton:SetHeight(22); view.refreshButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -42)
    styleButton(view.refreshButton, "Refresh Data"); view.refreshButton:Hide()
    view.scanButton = CreateFrame("Button", nil, page)
    view.scanButton:SetWidth(160); view.scanButton:SetHeight(24); view.scanButton:SetPoint("CENTER", page, "CENTER", 0, 12)
    styleButton(view.scanButton, "Scan Guild Statistics")
    view.summary = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    view.summary:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -72); view.summary:SetWidth(545); view.summary:SetJustifyH("LEFT"); view.summary:SetJustifyV("TOP"); view.summary:Hide()
    view.classPanel = page:CreateTexture(nil, "BACKGROUND")
    view.classPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -112); view.classPanel:SetWidth(272); view.classPanel:SetHeight(270); view.classPanel:SetTexture(0.07, 0.065, 0.055, 0.82); view.classPanel:Hide()
    view.rankPanel = page:CreateTexture(nil, "BACKGROUND")
    view.rankPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 300, -112); view.rankPanel:SetWidth(262); view.rankPanel:SetHeight(270); view.rankPanel:SetTexture(0.07, 0.065, 0.055, 0.82); view.rankPanel:Hide()
    view.classesHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.classesHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 24, -128); view.classesHeading:SetWidth(260); view.classesHeading:SetJustifyH("LEFT"); view.classesHeading:SetJustifyV("TOP"); view.classesHeading:SetText("Members by class"); view.classesHeading:Hide()
    view.ranksHeading = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    view.ranksHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 316, -128); view.ranksHeading:SetWidth(255); view.ranksHeading:SetJustifyH("LEFT"); view.ranksHeading:SetJustifyV("TOP"); view.ranksHeading:SetText("Members by rank"); view.ranksHeading:Hide()
    view.tableController = {
        refresh = refresh,
        shortText = ShortText,
        expandedType = nil,
        expandedValue = nil,
    }
    view.classTable = GuildStatistics.CreateTable(page, "MuklaOfficerSuiteStatisticsClassTableScroll", 24, 252, view.tableController)
    view.rankTable = GuildStatistics.CreateTable(page, "MuklaOfficerSuiteStatisticsRankTableScroll", 316, 238, view.tableController)
    return view
end

local function OnStatisticsScan()
    this.statisticsController.startScan("statistics")
end

local function OnStatisticsFilter()
    GuildStatistics.Refresh(this.statisticsController)
end

function GuildStatistics.CreateController(options)
    local view = options.view
    if view then
        options.summary = view.summary
        options.classesHeading = view.classesHeading
        options.ranksHeading = view.ranksHeading
        options.classPanel = view.classPanel
        options.rankPanel = view.rankPanel
        options.classTable = view.classTable
        options.rankTable = view.rankTable
        options.onlyLevel60 = view.onlyLevel60
        options.scanButton = view.scanButton
        options.refreshButton = view.refreshButton
        options.lastScan = view.lastScan
    end
    options.ready = false
    options.classIcons = CLASS_ICONS
    options.summaryState = GuildStatistics.CreateSummaryState()
    options.page.statisticsController = options
    options.scanButton.statisticsController = options
    options.refreshButton.statisticsController = options
    options.onlyLevel60.statisticsController = options
    options.scanButton:SetScript("OnClick", OnStatisticsScan)
    options.refreshButton:SetScript("OnClick", OnStatisticsScan)
    options.onlyLevel60:SetScript("OnClick", OnStatisticsFilter)
    return options
end

function GuildStatistics.SetReady(controller, ready)
    controller.ready = ready and true or false
end

function GuildStatistics.IsReady(controller)
    return controller.ready
end

function GuildStatistics.BeginScan(controller)
    controller.ready = false
    controller.summary:Hide()
    controller.classesHeading:Hide()
    controller.ranksHeading:Hide()
    controller.classPanel:Hide()
    controller.rankPanel:Hide()
    controller.classTable.scroll:Hide()
    controller.rankTable.scroll:Hide()
    local index
    for index = 1, table.getn(controller.classTable.rows) do
        controller.classTable.rows[index]:Hide()
        controller.rankTable.rows[index]:Hide()
    end
    controller.onlyLevel60:Hide()
    controller.lastScan:Hide()
    controller.refreshButton:Hide()
    controller.scanButton:Hide()
end

function GuildStatistics.HandleScanFailure(controller)
    controller.scanButton:Show()
end

function GuildStatistics.Refresh(controller)
    MOS.Diagnostics.Count("uiRefreshes")
    if not controller.ready then return end
    local data, guildName = controller.getData()
    if not data or not data.members then
        controller.summary:SetText((guildName or "Guild") .. " has no saved roster. Use Export Roster first.")
        controller.classesHeading:SetText("")
        controller.ranksHeading:SetText("")
        return
    end
    local onlyLevel60 = controller.onlyLevel60:GetChecked()
    local summaryState = GuildStatistics.BuildSummary(controller.summaryState, data, onlyLevel60)
    controller.summary:SetText(
        "|cffffd200" .. (guildName or "Guild") .. "|r   |   Included members: " .. summaryState.included ..
        (onlyLevel60 and " (level 60 only)" or (" of " .. summaryState.total))
    )
    controller.classesHeading:SetText("Members by class")
    controller.ranksHeading:SetText("Members by rank")
    local panelHeight = math.max(120, controller.page:GetHeight() - 130)
    controller.classPanel:SetHeight(panelHeight)
    controller.rankPanel:SetHeight(panelHeight)
    controller.classTable.scroll:SetHeight(panelHeight - 36)
    controller.rankTable.scroll:SetHeight(panelHeight - 36)
    local visibleRows = MOS.UI.CalculateVisibleRows(panelHeight, 44, 24, table.getn(controller.classTable.rows), 3)
    controller.classTable.visibleRows = visibleRows
    controller.rankTable.visibleRows = visibleRows
    GuildStatistics.PopulateTable(controller.classTable, summaryState.classSummaries, "class", data, onlyLevel60, controller.classIcons)
    GuildStatistics.PopulateTable(controller.rankTable, summaryState.rankList, "rank", data, onlyLevel60, controller.classIcons)
    controller.summary:Show()
    controller.classesHeading:Show()
    controller.ranksHeading:Show()
    controller.classPanel:Show()
    controller.rankPanel:Show()
    controller.onlyLevel60:Show()
    controller.scanButton:Hide()
    controller.lastScan:SetText("Last scan: " .. (data.scannedAtText or "Unknown"))
    controller.lastScan:Show()
    controller.refreshButton:Show()
end

function GuildStatistics.CreateLifecycle(controller)
    return {
        Hide = function(self) controller.page:Hide() end,
        Show = function(self) controller.page:Show(); GuildStatistics.Refresh(controller) end,
        Refresh = function(self) GuildStatistics.Refresh(controller) end,
        OnResize = function(self) GuildStatistics.Refresh(controller) end,
    }
end
