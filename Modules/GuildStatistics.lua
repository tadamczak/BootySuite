local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components

MOS.Modules = MOS.Modules or {}
local GuildStatistics = {}
MOS.Modules.GuildStatistics = GuildStatistics

local function Lower(value) return string.lower(tostring(value or "")) end
local function DisplayRank(value)
    if value == nil or value == "" then return "Unknown" end
    return Lower(value) == "officer wukong" and "Officer (Chimp)" or tostring(value)
end
local function DisplayClass(value) return value and value ~= "" and value or "Unknown" end
local function OnTableScroll() FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback) end

local function ClearArray(values)
    local index
    for index = table.getn(values), 1, -1 do values[index] = nil end
end

function GuildStatistics.CreateSummaryState()
    return { classes = {}, ranks = {}, classNames = {}, rankList = {}, classSummaries = {}, included = 0, total = 0 }
end

function GuildStatistics.BuildSummary(state, data, onlyLevel60)
    state = state or GuildStatistics.CreateSummaryState()
    state.classes = {}; state.ranks = {}; ClearArray(state.classNames); ClearArray(state.rankList); ClearArray(state.classSummaries)
    state.included = 0; state.total = table.getn(data and data.members or {})
    local index
    for index = 1, state.total do
        local member = data.members[index]
        if not onlyLevel60 or tonumber(member.level) == 60 then
            local className = DisplayClass(member.class)
            local rankName = DisplayRank(member.rank)
            state.classes[className] = (state.classes[className] or 0) + 1
            local rank = state.ranks[rankName]
            if not rank then rank = { name = rankName, count = 0, index = tonumber(member.rankIndex) or 999 }; state.ranks[rankName] = rank end
            rank.count = rank.count + 1; state.included = state.included + 1
        end
    end
    local className
    for className in pairs(state.classes) do table.insert(state.classNames, className) end
    table.sort(state.classNames, function(a, b) return Lower(a) < Lower(b) end)
    for index = 1, table.getn(state.classNames) do table.insert(state.classSummaries, { name = state.classNames[index], count = state.classes[state.classNames[index]] }) end
    local _, rank
    for _, rank in pairs(state.ranks) do table.insert(state.rankList, rank) end
    table.sort(state.rankList, function(a, b) if a.index == b.index then return Lower(a.name) < Lower(b.name) end return a.index < b.index end)
    return state
end

local function ClassColor(className)
    local key = string.upper(tostring(className or ""))
    return (RAID_CLASS_COLORS and RAID_CLASS_COLORS[key]) or UI.Theme.classColors[key] or { r = 1, g = 1, b = 1 }
end

local function CreateFilterGroup(parent, labelText, buttonText, width)
    local group = UI.CreateContainer(nil, parent); group:SetWidth(width); group:SetHeight(26); group.mosFlowWidth = width
    group.label = UI.CreateLabel(group, nil, "OVERLAY", "GameFontHighlightSmall"); group.label:SetPoint("LEFT", group, "LEFT", 0, 0); group.label:SetText(labelText)
    group.button = UI.CreateDropdownButton(group, nil, buttonText, width - 48); group.button:SetPoint("RIGHT", group, "RIGHT", 0, 0); group.button:SetHeight(26)
    group.panel = UI.CreateDropdownPanel(parent, group.button, 150, 80, 50); UI.StyleProjectPopup(group.panel)
    group.button:SetScript("OnClick", function() if group.panel:IsVisible() then group.panel:Hide() else group.panel:Show() end end)
    return group
end

local function CreateMemberTable(page, refresh)
    local tableView = { rows = {}, headers = {}, entries = {}, memberScratch = {}, columns = {
        { key = "name", text = "Name", desiredWidth = 210, minimumWidth = 72, fraction = 0.36 },
        { key = "class", text = "Class", desiredWidth = 130, minimumWidth = 48, fraction = 0.22 },
        { key = "rank", text = "Rank", desiredWidth = 180, minimumWidth = 60, fraction = 0.31 },
        { key = "level", text = "Lvl", desiredWidth = 46, minimumWidth = 30, fraction = 0.11 },
    } }
    tableView.scroll = UI.CreateScrollFrame("MuklaOfficerSuiteGuildStatisticsScroll", page, "FauxScrollFrameTemplate")
    tableView.scroll.refreshCallback = refresh; tableView.scroll:SetScript("OnVerticalScroll", OnTableScroll)
    UI.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteGuildStatisticsScrollScrollBar"))
    local index
    for index = 1, table.getn(tableView.columns) do
        local column = tableView.columns[index]
        tableView.headers[index] = UI.Table.CreateHeader(page, nil, column.text, 0, 0, column.desiredWidth, nil, false)
    end
    for index = 1, 30 do
        local row = UI.CreateContainer(nil, page); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0, 0, 0, 0)
        UI.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8" }, {0,0,0,0}, {0,0,0,0})
        row.name = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.class = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.rank = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.level = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row:Hide(); tableView.rows[index] = row
    end
    return tableView
end

local function MemberGroupValue(member, groupBy)
    if groupBy == "class" then return DisplayClass(member.class) end
    if groupBy == "rank" then return DisplayRank(member.rank) end
    if groupBy == "level" then return tostring(tonumber(member.level) or 0) end
    return ""
end

local function SortMembers(a, b)
    local aGroup, bGroup = a.group or "", b.group or ""
    if aGroup ~= bGroup then
        if a.groupNumber and b.groupNumber then return a.groupNumber > b.groupNumber end
        return Lower(aGroup) < Lower(bGroup)
    end
    local aRank, bRank = tonumber(a.member.rankIndex) or 999, tonumber(b.member.rankIndex) or 999
    if aRank ~= bRank then return aRank < bRank end
    return Lower(a.member.name) < Lower(b.member.name)
end

local function BuildEntries(controller, data)
    ClearArray(controller.table.memberScratch); ClearArray(controller.table.entries)
    local ranks, classes, rankSeen, classSeen = {}, {}, {}, {}
    local query = Lower(controller.search:GetText())
    local level = tonumber(controller.level:GetText())
    local index
    for index = 1, table.getn(data.members) do
        local member = data.members[index]
        local rank, className = DisplayRank(member.rank), DisplayClass(member.class)
        if not rankSeen[rank] then rankSeen[rank] = true; table.insert(ranks, rank) end
        if not classSeen[className] then classSeen[className] = true; table.insert(classes, className) end
        if controller.knownRanks[rank] == nil then controller.knownRanks[rank] = true; controller.selectedRanks[rank] = true end
        if controller.knownClasses[className] == nil then controller.knownClasses[className] = true; controller.selectedClasses[className] = true end
        local matchesQuery = query == "" or string.find(Lower(member.name), query, 1, true) or string.find(Lower(rank), query, 1, true) or string.find(Lower(className), query, 1, true)
        if controller.selectedRanks[rank] and controller.selectedClasses[className] and (not level or tonumber(member.level) == level) and matchesQuery then
            table.insert(controller.table.memberScratch, { member = member, group = MemberGroupValue(member, controller.groupBy), groupNumber = controller.groupBy == "level" and tonumber(member.level) or nil })
        end
    end
    table.sort(ranks, function(a,b) return Lower(a)<Lower(b) end); table.sort(classes, function(a,b) return Lower(a)<Lower(b) end)
    UI.FilterPanel.Refresh(controller.rankGroup.panel, ranks, controller.selectedRanks, controller.filterChanged, true)
    UI.FilterPanel.Refresh(controller.classGroup.panel, classes, controller.selectedClasses, controller.filterChanged, true)
    table.sort(controller.table.memberScratch, SortMembers)
    local previousGroup, groupEntry, count = nil, nil, 0
    for index = 1, table.getn(controller.table.memberScratch) do
        local wrapped = controller.table.memberScratch[index]
        if controller.groupBy ~= "none" and wrapped.group ~= previousGroup then
            groupEntry = { kind = "group", value = wrapped.group, count = 0 }
            table.insert(controller.table.entries, groupEntry); previousGroup = wrapped.group
        end
        if groupEntry and controller.groupBy ~= "none" then groupEntry.count = groupEntry.count + 1 end
        table.insert(controller.table.entries, { kind = "member", member = wrapped.member }); count = count + 1
    end
    return count
end

local function LayoutTable(controller, rowWidth)
    UI.Table.AllocateColumnWidths(controller.table.columns, rowWidth)
    local x, index = 0, nil
    for index = 1, table.getn(controller.table.columns) do
        local column, header = controller.table.columns[index], controller.table.headers[index]
        header:ClearAllPoints(); header:SetPoint("TOPLEFT", controller.page, "TOPLEFT", controller.tableRect.x + x, -controller.tableRect.y)
        header:SetWidth(column.width); header:SetHeight(20); x = x + column.width
    end
    UI.Table.FitHeaders(controller.table.headers, 12)
end

local function RenderTable(controller)
    local rect, entries = controller.tableRect, controller.table.entries
    local offset, visible, rowWidth = UI.Table.LayoutViewport(controller.table.scroll, controller.page, rect.x, rect.y + 22, rect.width, rect.height - 22, table.getn(entries), 24, table.getn(controller.table.rows))
    LayoutTable(controller, rowWidth)
    local index
    for index = 1, table.getn(controller.table.rows) do
        local row, entry = controller.table.rows[index], entries[offset + index]
        if entry and index <= visible then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", controller.page, "TOPLEFT", rect.x, -rect.y - 22 - (index - 1) * 24); row:SetWidth(rowWidth)
            UI.ApplyRowBackground(row, offset + index, false)
            if entry.kind == "group" then
                UI.Table.Cell(row.name, row, 6, rowWidth - 12, 23, entry.value .. "  (" .. entry.count .. ")")
                row.name:SetTextColor(unpack(UI.Theme.colors.goldText)); row.class:Hide(); row.rank:Hide(); row.level:Hide()
            else
                local member, columns = entry.member, controller.table.columns
                local x = 0
                UI.Table.Cell(row.name, row, x + 6, columns[1].width - 10, 23, member.name); x = x + columns[1].width
                local color = ClassColor(member.class); row.name:SetTextColor(color.r or color[1], color.g or color[2], color.b or color[3])
                UI.Table.Cell(row.class, row, x, columns[2].width - 4, 23, DisplayClass(member.class)); x = x + columns[2].width
                UI.Table.Cell(row.rank, row, x, columns[3].width - 4, 23, DisplayRank(member.rank)); x = x + columns[3].width
                UI.Table.Cell(row.level, row, x, columns[4].width - 2, 23, member.level or "")
                row.class:Show(); row.rank:Show(); row.level:Show()
            end
            row:Show()
        else row:Hide() end
    end
end

function GuildStatistics.AttachExport(view, button)
    button:SetParent(view.page); button:ClearAllPoints(); button:SetWidth(100); button:SetHeight(26); button:Show()
    UI.StyleActionButton(button); UI.SetClassicButtonIcon(button, "save", 13, 7, 0); UI.SetClassicButtonLabelOffset(button, 2)
    view.exportButton = button
end

function GuildStatistics.CreateView(host, styleButton, refresh)
    local page = UI.CreateResponsiveCanvas(host, "MOSGuildStatisticsPage")
    local view = { page = page, host = host }
    view.title = UI.CreateHeading(page, "", 1, "gold"); view.title:SetText("Guild Statistics")
    view.titleSeparator = UI.CreateHeading(page, "", 1, "white"); view.titleSeparator:SetText("|"); view.titleSeparator:SetTextColor(1,1,1)
    view.guildTitle = UI.CreateHeading(page, "", 1, "gold"); view.guildTitle:SetText("Guild")
    view.refreshButton = UI.CreateControl(nil, page); view.refreshButton:SetWidth(108); view.refreshButton:SetHeight(26); styleButton(view.refreshButton, "Refresh Data"); view.refreshButton:Hide()
    UI.SetClassicButtonIcon(view.refreshButton, "reset", 13, 7, 0); UI.SetClassicButtonLabelOffset(view.refreshButton, 2)
    view.showing = UI.CreateLabel(page, nil, "OVERLAY", "GameFontHighlightSmall"); view.showing:SetJustifyH("RIGHT"); view.showing:Hide()
    view.lastScan = UI.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall"); view.lastScan:Hide()
    view.scanButton = UI.CreateControl(nil, page); view.scanButton:SetWidth(160); view.scanButton:SetHeight(26); styleButton(view.scanButton, "Scan Guild Statistics")
    view.empty = UI.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall"); view.empty:SetJustifyH("CENTER"); view.empty:Hide()
    view.filterPanel = UI.CreateContainer(nil, page); view.filterPanel:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=8, insets={left=2,right=2,top=2,bottom=2} }); view.filterPanel:SetBackdropColor(0.035,0.03,0.02,0.94)
    UI.RegisterSkinnedSurface(view.filterPanel, "content"); UI.SetSurfaceHorizontalBorders(view.filterPanel, true, true)
    view.rankGroup = CreateFilterGroup(view.filterPanel, "Rank", "Rank", 142)
    view.classGroup = CreateFilterGroup(view.filterPanel, "Class", "Class", 142)
    view.groupGroup = UI.CreateContainer(nil, view.filterPanel); view.groupGroup:SetWidth(184); view.groupGroup:SetHeight(26); view.groupGroup.mosFlowWidth=184
    local groupChoices={{value="none",text="None"},{value="class",text="Class"},{value="rank",text="Rank"},{value="level",text="Level"}}
    view.groupLabel=UI.CreateLabel(view.groupGroup,nil,"OVERLAY","GameFontHighlightSmall");view.groupLabel:SetPoint("LEFT",view.groupGroup,"LEFT",0,0);view.groupLabel:SetText("Group by:")
    view.groupButton=UI.CreateDropdownButton(view.groupGroup,nil,"None",104);view.groupButton:SetPoint("RIGHT",view.groupGroup,"RIGHT",0,0);view.groupButton:SetHeight(26)
    view.groupPanel=UI.CreateDropdownPanel(view.filterPanel,view.groupButton,104,88,50)
    local choiceIndex
    for choiceIndex=1,table.getn(groupChoices) do
        local choice=UI.CreateButton(view.groupPanel,nil,groupChoices[choiceIndex].text,96,18);UI.StyleDropdownChoice(choice)
        choice:SetPoint("TOPLEFT",view.groupPanel,"TOPLEFT",4,-4-(choiceIndex-1)*20);choice.choiceValue=groupChoices[choiceIndex].value;choice.choiceText=groupChoices[choiceIndex].text
        choice:SetScript("OnClick",function() view.groupBy=this.choiceValue;view.groupButton:SetText(this.choiceText);view.groupPanel:Hide();refresh() end)
        table.insert(view.groupPanel.options,choice)
    end
    view.groupButton:SetScript("OnClick",function() if view.groupPanel:IsVisible() then view.groupPanel:Hide() else view.groupPanel:Show() end end)
    UI.StyleProjectPopup(view.groupPanel)
    view.levelGroup=UI.CreateContainer(nil,view.filterPanel);view.levelGroup:SetWidth(96);view.levelGroup:SetHeight(26);view.levelGroup.mosFlowWidth=96
    view.levelLabel=UI.CreateLabel(view.levelGroup,nil,"OVERLAY","GameFontHighlightSmall");view.levelLabel:SetPoint("LEFT",view.levelGroup,"LEFT",0,0);view.levelLabel:SetText("Level")
    view.level=UI.CreateFramedEditBox(view.levelGroup,nil,48);view.level:SetPoint("RIGHT",view.levelGroup,"RIGHT",0,0);view.level:SetMaxLetters(2);view.level:SetScript("OnTextChanged",function() refresh() end)
    view.searchGroup=UI.CreateContainer(nil,view.filterPanel);view.searchGroup:SetWidth(180);view.searchGroup:SetHeight(26);view.searchGroup.mosFlowWidth=180
    view.searchLabel=UI.CreateLabel(view.searchGroup,nil,"OVERLAY","GameFontHighlightSmall");view.searchLabel:SetPoint("LEFT",view.searchGroup,"LEFT",0,0);view.searchLabel:SetText("Search")
    view.search=UI.CreateFramedEditBox(view.searchGroup,nil,132);view.search:SetPoint("RIGHT",view.searchGroup,"RIGHT",0,0);view.search:SetScript("OnTextChanged",function() refresh() end)
    view.flow={view.rankGroup,view.classGroup,view.groupGroup,view.levelGroup,view.searchGroup}
    view.table=CreateMemberTable(page,refresh)
    return view
end

local function OnStatisticsScan() this.statisticsController.startScan("statistics") end

function GuildStatistics.CreateController(options)
    local view=options.view
    options.page=view.page;options.view=view;options.rankGroup=view.rankGroup;options.classGroup=view.classGroup;options.level=view.level;options.search=view.search;options.table=view.table
    options.ready=false;options.groupBy="none";options.selectedRanks={};options.selectedClasses={};options.knownRanks={};options.knownClasses={}
    view.groupBy="none";options.filterChanged=function() GuildStatistics.Refresh(options) end
    options.page.statisticsController=options;view.host.statisticsController=options;view.scanButton.statisticsController=options;view.refreshButton.statisticsController=options
    view.scanButton:SetScript("OnClick",OnStatisticsScan);view.refreshButton:SetScript("OnClick",OnStatisticsScan)
    return options
end

function GuildStatistics.SetReady(controller,ready) controller.ready=ready and true or false end
function GuildStatistics.IsReady(controller) return controller.ready end

local function HideResults(controller)
    controller.view.showing:Hide();controller.view.lastScan:Hide();controller.view.filterPanel:Hide();controller.table.scroll:Hide()
    local index
    for index=1,table.getn(controller.table.headers) do controller.table.headers[index]:Hide() end
    for index=1,table.getn(controller.table.rows) do controller.table.rows[index]:Hide() end
    UI.SetScrollBarVisible(getglobal("MuklaOfficerSuiteGuildStatisticsScrollScrollBar"),false)
end

function GuildStatistics.BeginScan(controller)
    controller.ready=false;HideResults(controller);controller.view.refreshButton:Hide();controller.view.scanButton:Hide();controller.view.empty:Hide()
end
function GuildStatistics.HandleScanFailure(controller) controller.view.scanButton:Show() end

local function LayoutContent(width,height,controller)
    local view,page=controller.view,controller.page
    local available=math.max(80,width-16)
    local titleWidth=math.min(view.title:GetStringWidth()+2,available*0.55)
    view.title:ClearAllPoints();view.title:SetPoint("TOPLEFT",page,"TOPLEFT",8,-8);view.title:SetWidth(titleWidth)
    view.titleSeparator:ClearAllPoints();view.titleSeparator:SetPoint("LEFT",view.title,"RIGHT",8,0);view.titleSeparator:SetWidth(8)
    local guildWidth=math.max(1,available-titleWidth-32)
    view.guildTitle:ClearAllPoints();view.guildTitle:SetPoint("LEFT",view.titleSeparator,"RIGHT",8,0);view.guildTitle:SetWidth(guildWidth);UI.FitButtonLabel(view.guildTitle,guildWidth)
    local top=38
    if controller.ready then
        local showingWidth=math.min(105,available*0.36)
        local actionAvailable=math.max(72,available-showingWidth-12)
        local actionScale=math.min(1,math.max(0.62,(actionAvailable-8)/212))
        local actionX=8
        if view.exportButton then UI.SizeClassicButton(view.exportButton,math.floor(100*actionScale),26,actionScale);view.exportButton:ClearAllPoints();view.exportButton:SetPoint("TOPLEFT",page,"TOPLEFT",actionX,-top);actionX=actionX+view.exportButton:GetWidth()+8 end
        UI.SizeClassicButton(view.refreshButton,math.floor(104*actionScale),26,actionScale);view.refreshButton:ClearAllPoints();view.refreshButton:SetPoint("TOPLEFT",page,"TOPLEFT",actionX,-top)
        top=top+34
        view.showing:ClearAllPoints();view.showing:SetPoint("TOPRIGHT",page,"TOPRIGHT",-8,-42);view.showing:SetWidth(showingWidth);view.showing:SetHeight(18)
        view.filterPanel:ClearAllPoints();view.filterPanel:SetPoint("TOPLEFT",page,"TOPLEFT",4,-top);view.filterPanel:SetWidth(width-8)
        local filterBottom=UI.LayoutFlow(view.filterPanel,view.flow,4,8,available,6)+8;view.filterPanel:SetHeight(filterBottom)
        view.rankGroup.button:SetWidth(math.max(32,view.rankGroup:GetWidth()-48));view.classGroup.button:SetWidth(math.max(32,view.classGroup:GetWidth()-48))
        view.groupButton:SetWidth(math.max(32,view.groupGroup:GetWidth()-76));view.level:SetWidth(math.max(28,view.levelGroup:GetWidth()-48));view.search:SetWidth(math.max(32,view.searchGroup:GetWidth()-48))
        top=top+filterBottom+8
        controller.tableRect=controller.tableRect or {};controller.tableRect.x=8;controller.tableRect.y=top;controller.tableRect.width=available;controller.tableRect.height=math.max(96,height-top-8)
        return controller.tableRect.y+controller.tableRect.height+8
    end
    view.empty:ClearAllPoints();view.empty:SetPoint("TOPLEFT",page,"TOPLEFT",8,-64);view.empty:SetWidth(available)
    view.scanButton:ClearAllPoints();view.scanButton:SetPoint("TOP",view.empty,"BOTTOM",0,-12);view.scanButton:SetWidth(math.min(160,available))
    return 130
end

function GuildStatistics.Layout(controller) UI.LayoutResponsiveCanvas(controller.page,LayoutContent,controller) end

function GuildStatistics.Refresh(controller)
    if controller.page.IsShown and not controller.page:IsShown() then return end
    if controller.refreshing then return end
    controller.refreshing=true;MOS.Diagnostics.Count("uiRefreshes")
    if not controller.ready then GuildStatistics.Layout(controller);controller.refreshing=false;return end
    local data,guildName=controller.getData();guildName=guildName or "Guild";controller.view.guildTitle:SetText(guildName)
    if not data or not data.members then
        HideResults(controller);controller.view.empty:SetText(guildName.." has no saved roster. Scan Guild Statistics to begin.");controller.view.empty:Show();controller.view.scanButton:Show();GuildStatistics.Layout(controller);controller.refreshing=false;return
    end
    controller.groupBy=controller.view.groupBy or "none"
    local count=BuildEntries(controller,data)
    controller.view.showing:SetText("Showing members: "..count);controller.view.showing:Show()
    controller.view.lastScan:SetText("Last scan: "..(data.scannedAtText or "Unknown"))
    controller.view.empty:Hide();controller.view.scanButton:Hide();controller.view.refreshButton:Show();controller.view.filterPanel:Show()
    GuildStatistics.Layout(controller);RenderTable(controller)
    local index
    for index=1,table.getn(controller.table.headers) do controller.table.headers[index]:Show() end
    controller.refreshing=false
end

function GuildStatistics.CreateLifecycle(controller)
    return {
        Hide=function() controller.view.rankGroup.panel:Hide();controller.view.classGroup.panel:Hide();controller.view.groupPanel:Hide();controller.page:Hide();controller.view.host:Hide();UI.SetScrollBarVisible(getglobal("MuklaOfficerSuiteGuildStatisticsScrollScrollBar"),false) end,
        Show=function() controller.view.host:Show();controller.page:Show();GuildStatistics.Refresh(controller) end,
        Refresh=function() GuildStatistics.Refresh(controller) end,
        OnResize=function() GuildStatistics.Refresh(controller) end,
    }
end
