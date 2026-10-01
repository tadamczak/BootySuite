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

local function CreateFilterGroup(parent, buttonText, width)
    local group = UI.CreateContainer(nil, parent); group:SetWidth(width); group:SetHeight(26); group.mosFlowWidth = width
    group.button = UI.CreateDropdownButton(group, nil, buttonText, width); group.button:SetAllPoints(group); group.button:SetHeight(26)
    group.panel = UI.CreateDropdownPanel(parent, group.button, 150, 80, 50); UI.StyleProjectPopup(group.panel)
    group.button:SetScript("OnClick", function() if group.panel:IsVisible() then group.panel:Hide() else group.panel:Show() end end)
    return group
end

local function OnGuildRowClick()
    local row = this
    if not row.entry or row.entry.kind ~= "group" then return end
    local controller = row.tableController.controller
    controller.expandedGroups[row.entry.value] = not controller.expandedGroups[row.entry.value]
    GuildStatistics.Refresh(controller)
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
        tableView.headers[index] = UI.Table.CreateHeader(page, tableView, column.text, 0, 0, column.desiredWidth, column.key, true)
    end
    for index = 1, 30 do
        local row = UI.CreateControl(nil, page); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0, 0, 0, 0)
        UI.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8" }, {0,0,0,0}, {0,0,0,0})
        row.name = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.class = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.rank = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.level = UI.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall")
        row.classIcon = UI.CreateClassIcon(row,16)
        UI.SetProjectButtonOutline(row, false)
        row.childBorder=UI.CreateProjectLeftAccent(row); row.tableController = tableView; row:SetScript("OnClick", OnGuildRowClick)
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
        if a.groupNumber and b.groupNumber then return a.groupNumber < b.groupNumber end
        return Lower(aGroup) < Lower(bGroup)
    end
    if a.sortNumber ~= b.sortNumber then return a.sortAscending and a.sortNumber < b.sortNumber or (not a.sortAscending and a.sortNumber > b.sortNumber) end
    if a.sortText ~= b.sortText then return a.sortAscending and a.sortText < b.sortText or (not a.sortAscending and a.sortText > b.sortText) end
    local aName,bName=Lower(a.member.name),Lower(b.member.name)
    if aName==bName then return false end
    return a.sortAscending and aName<bName or (not a.sortAscending and aName>bName)
end

local function CreateWrappedMember(member,group,groupNumber,controller)
    local number,text=0,""
    if controller.sortKey=="level" then number=tonumber(member.level) or 0
    elseif controller.sortKey=="rank" then number=tonumber(member.rankIndex) or 999;text=Lower(DisplayRank(member.rank))
    elseif controller.sortKey=="class" then text=Lower(DisplayClass(member.class))
    else text=Lower(member.name) end
    return {member=member,group=group,groupNumber=groupNumber,sortNumber=number,sortText=text,sortAscending=controller.sortAscending}
end

local function BuildEntries(controller, data)
    ClearArray(controller.table.memberScratch); ClearArray(controller.table.entries)
    controller.rawRanks = controller.rawRanks or {}; controller.rawClasses = controller.rawClasses or {}; controller.rawLevels = controller.rawLevels or {0,0,0}
    controller.rawRanks = {}; controller.rawClasses = {}; controller.rawLevels[1]=0;controller.rawLevels[2]=0;controller.rawLevels[3]=0
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
            table.insert(controller.table.memberScratch,CreateWrappedMember(member,MemberGroupValue(member,controller.groupBy),controller.groupBy=="level" and tonumber(member.level) or nil,controller))
            controller.rawRanks[rank]=(controller.rawRanks[rank] or 0)+1;controller.rawClasses[className]=(controller.rawClasses[className] or 0)+1
            local memberLevel=tonumber(member.level) or 0
            if memberLevel<=30 then controller.rawLevels[1]=controller.rawLevels[1]+1 elseif memberLevel<60 then controller.rawLevels[2]=controller.rawLevels[2]+1 else controller.rawLevels[3]=controller.rawLevels[3]+1 end
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
        if controller.groupBy == "none" or controller.expandedGroups[wrapped.group] then table.insert(controller.table.entries, { kind = "member", member = wrapped.member, child = controller.groupBy ~= "none" }) end
        count = count + 1
    end
    if controller.rawMode then
        ClearArray(controller.table.entries)
        local rawRankList,rawClassList={},{}
        local name,value
        for name,value in pairs(controller.rawRanks) do table.insert(rawRankList,{name=name,count=value}) end
        for name,value in pairs(controller.rawClasses) do table.insert(rawClassList,{name=name,count=value}) end
        table.sort(rawRankList,function(a,b)return Lower(a.name)<Lower(b.name) end);table.sort(rawClassList,function(a,b)return Lower(a.name)<Lower(b.name) end)
        table.insert(controller.table.entries,{kind="rawHeader",value="Members by Rank"})
        for index=1,table.getn(rawRankList) do table.insert(controller.table.entries,{kind="raw",value=rawRankList[index].name.." - "..rawRankList[index].count.." members"}) end
        table.insert(controller.table.entries,{kind="rawHeader",value="Members by Class"})
        for index=1,table.getn(rawClassList) do table.insert(controller.table.entries,{kind="rawClass",className=rawClassList[index].name,value=rawClassList[index].name.." - "..rawClassList[index].count.." members"}) end
        table.insert(controller.table.entries,{kind="rawHeader",value="Members by Level"})
        table.insert(controller.table.entries,{kind="raw",value="1 - 30lvl - "..controller.rawLevels[1].." members"});table.insert(controller.table.entries,{kind="raw",value="31 - 59lvl - "..controller.rawLevels[2].." members"});table.insert(controller.table.entries,{kind="raw",value="60lvl - "..controller.rawLevels[3].." members"})
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

local function SetClassIcon(texture, className)
    local coordinates = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[string.upper(tostring(className or ""))]
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    if coordinates then texture:SetTexCoord(coordinates[1],coordinates[2],coordinates[3],coordinates[4]) else texture:SetTexCoord(0,1,0,1) end
end

local function SetRowDecorations(row, kind, child)
    UI.SetProjectButtonOutline(row, kind=="group")
    row.childBorder:Hide();row.classIcon:Hide()
    if kind=="group" then
        row:SetBackdropColor(0.15,0.115,0.035,0.92)
    elseif kind=="rawHeader" then row:SetBackdropColor(0.13,0.10,0.03,0.9)
    elseif child then
        row.childBorder:ClearAllPoints();row.childBorder:SetPoint("TOPLEFT",row,"TOPLEFT",12,0);row.childBorder:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",12,0);row.childBorder:Show()
    end
end

local function RenderTable(controller)
    local rect, entries = controller.tableRect, controller.table.entries
    local headerHeight=controller.rawMode and 0 or 22
    local offset, visible, rowWidth = UI.Table.LayoutViewport(controller.table.scroll, controller.page, rect.x, rect.y + headerHeight, rect.width, rect.height - headerHeight, table.getn(entries), 24, table.getn(controller.table.rows))
    LayoutTable(controller, rowWidth)
    local index
    for index = 1, table.getn(controller.table.rows) do
        local row, entry = controller.table.rows[index], entries[offset + index]
        if entry and index <= visible then
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", controller.page, "TOPLEFT", rect.x, -rect.y - headerHeight - (index - 1) * 24); row:SetWidth(rowWidth);row.entry=entry
            UI.ApplyRowBackground(row, offset + index, false)
            SetRowDecorations(row,entry.kind,entry.child)
            if entry.kind == "group" then
                local marker=controller.expandedGroups[entry.value] and "- " or "+ "
                UI.Table.Cell(row.name, row, 6, rowWidth - 12, 23, marker..entry.value .. "  (" .. entry.count .. ")")
                row.name:SetTextColor(unpack(UI.Theme.colors.goldText)); row.class:Hide(); row.rank:Hide(); row.level:Hide()
            elseif entry.kind=="rawHeader" then
                UI.Table.Cell(row.name,row,6,rowWidth-12,23,entry.value);row.name:SetTextColor(unpack(UI.Theme.colors.goldText));row.class:Hide();row.rank:Hide();row.level:Hide()
            elseif entry.kind=="raw" or entry.kind=="rawClass" then
                local left=entry.kind=="rawClass" and 28 or 12
                UI.Table.Cell(row.name,row,left,rowWidth-left-6,23,entry.value);row.name:SetTextColor(1,1,1);row.class:Hide();row.rank:Hide();row.level:Hide()
                if entry.kind=="rawClass" then row.classIcon:ClearAllPoints();row.classIcon:SetPoint("LEFT",row,"LEFT",8,0);SetClassIcon(row.classIcon,entry.className);row.classIcon:Show() end
            else
                local member, columns = entry.member, controller.table.columns
                local x = 0
                local nameInset=entry.child and 18 or 6
                UI.Table.Cell(row.name, row, x + nameInset, columns[1].width - nameInset - 4, 23, member.name); x = x + columns[1].width
                local color = ClassColor(member.class); row.name:SetTextColor(color.r or color[1], color.g or color[2], color.b or color[3])
                UI.Table.Cell(row.class, row, x, columns[2].width - 4, 23, DisplayClass(member.class)); x = x + columns[2].width
                UI.Table.Cell(row.rank, row, x, columns[3].width - 4, 23, DisplayRank(member.rank)); x = x + columns[3].width
                UI.Table.Cell(row.level, row, x, columns[4].width - 2, 23, member.level or "")
                row.class:Show(); row.rank:Show(); row.level:Show()
            end
            row:Show()
        else row.entry=nil;row:Hide() end
    end
end

function GuildStatistics.AttachExport(view, button)
    button:SetParent(view.actionPanel or view.page); button:ClearAllPoints(); button:SetWidth(100); button:SetHeight(26); button:Show()
    UI.StyleActionButton(button); UI.SetClassicButtonIcon(button, "save", 13, 7, 0); UI.SetClassicButtonLabelOffset(button, 2)
    view.exportButton = button
end

function GuildStatistics.CreateView(host, styleButton, refresh)
    local page = UI.CreateResponsiveCanvas(host, "MOSGuildStatisticsPage")
    local view = { page = page, host = host, onFilterChanged = refresh }
    view.title = UI.CreateHeading(page, "", 1, "gold"); view.title:SetText("Guild Statistics")
    view.titleSeparator = UI.CreateHeading(page, "", 1, "white"); view.titleSeparator:SetText("|"); view.titleSeparator:SetTextColor(1,1,1)
    view.guildTitle = UI.CreateHeading(page, "", 1, "orange"); view.guildTitle:SetText("Guild")
    local headingFont,_,headingFlags=view.guildTitle:GetFont();view.titleSeparator:SetFont(headingFont,13,headingFlags);view.guildTitle:SetFont(headingFont,13,headingFlags)
    view.actionPanel=UI.CreateContainer(nil,page);view.actionPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});view.actionPanel:SetBackdropColor(0.025,0.022,0.016,0.72);UI.RegisterSkinnedSurface(view.actionPanel,"content");UI.SetSurfaceHorizontalBorders(view.actionPanel,true,true)
    view.refreshButton = UI.CreateControl(nil, view.actionPanel); view.refreshButton:SetWidth(108); view.refreshButton:SetHeight(26); styleButton(view.refreshButton, "Refresh Data"); view.refreshButton:Hide()
    UI.SetClassicButtonIcon(view.refreshButton, "reset", 13, 7, 0); UI.SetClassicButtonLabelOffset(view.refreshButton, 2)
    view.rawButton=UI.CreateControl(nil,view.actionPanel);view.rawButton:SetWidth(92);view.rawButton:SetHeight(26);styleButton(view.rawButton,"Raw Data");view.rawButton:Hide()
    UI.SetClassicButtonIcon(view.rawButton,"list",13,7,0);UI.SetClassicButtonLabelOffset(view.rawButton,2)
    view.showingLabel = UI.CreateLabel(view.actionPanel, nil, "OVERLAY", "GameFontHighlightSmall"); view.showingLabel:SetText("Showing members:"); view.showingLabel:SetTextColor(unpack(UI.Theme.colors.goldText)); view.showingLabel:SetJustifyH("RIGHT"); view.showingLabel:Hide()
    view.showing = UI.CreateLabel(view.actionPanel, nil, "OVERLAY", "GameFontHighlightSmall"); view.showing:SetTextColor(1,1,1); view.showing:SetJustifyH("RIGHT"); view.showing:Hide()
    view.lastScan = UI.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall"); view.lastScan:Hide()
    view.scanButton = UI.CreateControl(nil, page); view.scanButton:SetWidth(160); view.scanButton:SetHeight(26); styleButton(view.scanButton, "Scan Guild Statistics")
    view.empty = UI.CreateLabel(page, nil, "OVERLAY", "GameFontDisableSmall"); view.empty:SetJustifyH("CENTER"); view.empty:Hide()
    view.filterPanel = UI.CreateContainer(nil, page); view.filterPanel:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=8, insets={left=2,right=2,top=2,bottom=2} }); view.filterPanel:SetBackdropColor(0.035,0.03,0.02,0.94)
    UI.RegisterSkinnedSurface(view.filterPanel, "content"); UI.SetSurfaceHorizontalBorders(view.filterPanel, true, true)
    view.rankGroup = CreateFilterGroup(view.filterPanel, "Rank", 88)
    view.classGroup = CreateFilterGroup(view.filterPanel, "Class", 88)
    view.groupGroup = UI.CreateContainer(nil, view.filterPanel); view.groupGroup:SetWidth(112); view.groupGroup:SetHeight(26); view.groupGroup.mosFlowWidth=112
    local groupChoices={{value="none",text="None"},{value="class",text="Class"},{value="rank",text="Rank"},{value="level",text="Level"}}
    view.groupLabel=UI.CreateLabel(view.groupGroup,nil,"OVERLAY","GameFontHighlightSmall");view.groupLabel:SetPoint("LEFT",view.groupGroup,"LEFT",0,0);view.groupLabel:SetText("Group by:")
    view.groupButton=UI.CreateDropdownButton(view.groupGroup,nil,"None",52);view.groupButton:SetPoint("RIGHT",view.groupGroup,"RIGHT",0,0);view.groupButton:SetHeight(26)
    view.groupPanel=UI.CreateDropdownPanel(view.filterPanel,view.groupButton,104,88,50)
    local choiceIndex
    for choiceIndex=1,table.getn(groupChoices) do
        local choice=UI.CreateButton(view.groupPanel,nil,groupChoices[choiceIndex].text,96,18);UI.StyleDropdownChoice(choice)
        choice:SetPoint("TOPLEFT",view.groupPanel,"TOPLEFT",4,-4-(choiceIndex-1)*20);choice.choiceValue=groupChoices[choiceIndex].value;choice.choiceText=groupChoices[choiceIndex].text
        choice:SetScript("OnClick",function() view.groupBy=this.choiceValue;view.groupButton:SetText(this.choiceText);view.groupPanel:Hide();view.onFilterChanged() end)
        table.insert(view.groupPanel.options,choice)
    end
    view.groupButton:SetScript("OnClick",function() if view.groupPanel:IsVisible() then view.groupPanel:Hide() else view.groupPanel:Show() end end)
    UI.StyleProjectPopup(view.groupPanel)
    view.levelGroup=UI.CreateContainer(nil,view.filterPanel);view.levelGroup:SetWidth(64);view.levelGroup:SetHeight(26);view.levelGroup.mosFlowWidth=64
    view.levelLabel=UI.CreateLabel(view.levelGroup,nil,"OVERLAY","GameFontHighlightSmall");view.levelLabel:SetPoint("LEFT",view.levelGroup,"LEFT",0,0);view.levelLabel:SetText("Level:")
    view.level=UI.CreateFramedEditBox(view.levelGroup,nil,24);view.level:SetPoint("RIGHT",view.levelGroup,"RIGHT",0,0);view.level:SetMaxLetters(2);view.level:SetScript("OnTextChanged",function() view.onFilterChanged() end)
    view.searchGroup=UI.CreateContainer(nil,view.filterPanel);view.searchGroup:SetWidth(188);view.searchGroup:SetHeight(26);view.searchGroup.mosFlowWidth=188
    view.searchLabel=UI.CreateLabel(view.searchGroup,nil,"OVERLAY","GameFontHighlightSmall");view.searchLabel:SetPoint("LEFT",view.searchGroup,"LEFT",0,0);view.searchLabel:SetText("Search:")
    view.search=UI.CreateFramedEditBox(view.searchGroup,nil,132);view.search:SetPoint("RIGHT",view.searchGroup,"RIGHT",0,0);view.search:SetScript("OnTextChanged",function() view.onFilterChanged() end)
    view.flow={view.rankGroup,view.classGroup,view.groupGroup,view.levelGroup,view.searchGroup}
    view.table=CreateMemberTable(page,refresh)
    return view
end

local function OnStatisticsScan() this.statisticsController.startScan("statistics") end
local function SetControlText(control,text) if control.label then control.label:SetText(text) else control:SetText(text) end end

function GuildStatistics.CreateController(options)
    local view=options.view
    options.page=view.page;options.view=view;options.rankGroup=view.rankGroup;options.classGroup=view.classGroup;options.level=view.level;options.search=view.search;options.table=view.table
    options.ready=false;options.groupBy="none";options.selectedRanks={};options.selectedClasses={};options.knownRanks={};options.knownClasses={};options.expandedGroups={};options.sortKey="name";options.sortAscending=true;options.rawMode=false
    view.groupBy="none";options.filterChanged=function() options.expandedGroups={};GuildStatistics.Refresh(options) end;view.onFilterChanged=options.filterChanged
    options.table.controller=options;options.table.onSort=function(key)
        if options.sortKey==key then options.sortAscending=not options.sortAscending else options.sortKey=key;options.sortAscending=true end
        GuildStatistics.Refresh(options)
    end
    view.rawButton.statisticsController=options;view.rawButton:SetScript("OnClick",function()
        local controller=this.statisticsController;controller.rawMode=not controller.rawMode;SetControlText(this,controller.rawMode and "Table Data" or "Raw Data");GuildStatistics.Refresh(controller)
    end)
    options.page.statisticsController=options;view.host.statisticsController=options;view.scanButton.statisticsController=options;view.refreshButton.statisticsController=options
    view.scanButton:SetScript("OnClick",OnStatisticsScan);view.refreshButton:SetScript("OnClick",OnStatisticsScan)
    return options
end

function GuildStatistics.SetReady(controller,ready) controller.ready=ready and true or false end
function GuildStatistics.IsReady(controller) return controller.ready end

local function HideResults(controller)
    controller.view.showingLabel:Hide();controller.view.showing:Hide();controller.view.lastScan:Hide();controller.view.actionPanel:Hide();controller.view.rawButton:Hide();controller.view.filterPanel:Hide();controller.table.scroll:Hide()
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
    view.titleSeparator:ClearAllPoints();view.titleSeparator:SetPoint("BOTTOMLEFT",view.title,"BOTTOMRIGHT",8,0);view.titleSeparator:SetWidth(8);view.titleSeparator:SetHeight(16)
    local guildWidth=math.max(1,available-titleWidth-32)
    view.guildTitle:ClearAllPoints();view.guildTitle:SetPoint("BOTTOMLEFT",view.titleSeparator,"BOTTOMRIGHT",8,0);view.guildTitle:SetWidth(guildWidth);view.guildTitle:SetHeight(16);UI.FitButtonLabel(view.guildTitle,guildWidth)
    local top=36
    if controller.ready then
        local showingLabelWidth=math.ceil(view.showingLabel:GetStringWidth())
        local showingCountWidth=math.ceil(view.showing:GetStringWidth())
        local showingWidth=math.min(available,showingLabelWidth+4+showingCountWidth)
        local actionAvailable=math.max(72,available-showingWidth-12)
        local baseActionWidth=(view.exportButton and 100 or 0)+104+92+(view.exportButton and 16 or 8)
        local actionScale=math.min(1,math.max(0.52,actionAvailable/math.max(1,baseActionWidth)))
        local actionHeight=38
        if baseActionWidth*actionScale>actionAvailable+1 then actionAvailable=available;actionScale=math.min(1,actionAvailable/math.max(1,baseActionWidth));actionHeight=68 end
        view.actionPanel:ClearAllPoints();view.actionPanel:SetPoint("TOPLEFT",page,"TOPLEFT",0,-top);view.actionPanel:SetWidth(width);view.actionPanel:SetHeight(actionHeight);view.actionPanel:Show()
        local actionX=8
        if view.exportButton then UI.SizeClassicButton(view.exportButton,math.floor(100*actionScale),26,actionScale);view.exportButton:ClearAllPoints();view.exportButton:SetPoint("TOPLEFT",view.actionPanel,"TOPLEFT",actionX,-6);actionX=actionX+view.exportButton:GetWidth()+8 end
        UI.SizeClassicButton(view.refreshButton,math.floor(104*actionScale),26,actionScale);view.refreshButton:ClearAllPoints();view.refreshButton:SetPoint("TOPLEFT",view.actionPanel,"TOPLEFT",actionX,-6);actionX=actionX+view.refreshButton:GetWidth()+8
        UI.SizeClassicButton(view.rawButton,math.floor(92*actionScale),26,actionScale);view.rawButton:ClearAllPoints();view.rawButton:SetPoint("TOPLEFT",view.actionPanel,"TOPLEFT",actionX,-6)
        view.showing:ClearAllPoints();view.showing:SetPoint("TOPRIGHT",view.actionPanel,"TOPRIGHT",-8,actionHeight==38 and -10 or -44);view.showing:SetWidth(showingCountWidth);view.showing:SetHeight(18)
        view.showingLabel:ClearAllPoints();view.showingLabel:SetPoint("RIGHT",view.showing,"LEFT",-4,0);view.showingLabel:SetWidth(math.max(1,showingWidth-showingCountWidth-4));view.showingLabel:SetHeight(18)
        top=top+actionHeight+4
        view.filterPanel:ClearAllPoints();view.filterPanel:SetPoint("TOPLEFT",page,"TOPLEFT",0,-top);view.filterPanel:SetWidth(width)
        local flowWidth=math.max(1,width-16)
        local groupLabelWidth=math.ceil(view.groupLabel:GetStringWidth())
        local levelLabelWidth=math.ceil(view.levelLabel:GetStringWidth())
        view.groupGroup.mosFlowWidth=groupLabelWidth+4+52
        view.levelGroup.mosFlowWidth=levelLabelWidth+4+24
        local searchLabelWidth=math.ceil(view.searchLabel:GetStringWidth())
        local searchMinimum=searchLabelWidth+4+66
        local searchMaximum=searchLabelWidth+4+132
        local precedingWidth=view.rankGroup.mosFlowWidth+view.classGroup.mosFlowWidth+view.groupGroup.mosFlowWidth+view.levelGroup.mosFlowWidth+24
        local sameRowWidth=flowWidth-precedingWidth
        local searchGroupWidth
        if sameRowWidth>=searchMinimum then searchGroupWidth=math.min(searchMaximum,sameRowWidth)
        else searchGroupWidth=math.min(searchMaximum,math.max(searchMinimum,flowWidth)) end
        view.searchGroup.mosFlowWidth=searchGroupWidth
        local filterBottom=UI.LayoutFlow(view.filterPanel,view.flow,8,8,flowWidth,6)+8;view.filterPanel:SetHeight(filterBottom)
        view.rankGroup.button:SetWidth(view.rankGroup:GetWidth());view.classGroup.button:SetWidth(view.classGroup:GetWidth())
        view.groupButton:SetWidth(52);view.groupButton:ClearAllPoints();view.groupButton:SetPoint("LEFT",view.groupLabel,"RIGHT",4,0)
        view.level:SetWidth(24);view.level:ClearAllPoints();view.level:SetPoint("LEFT",view.levelLabel,"RIGHT",4,0)
        view.search:SetWidth(math.max(66,math.min(132,view.searchGroup:GetWidth()-searchLabelWidth-4)));view.search:ClearAllPoints();view.search:SetPoint("LEFT",view.searchLabel,"RIGHT",4,0)
        top=top+filterBottom+8
        controller.tableRect=controller.tableRect or {};controller.tableRect.x=8;controller.tableRect.y=top;controller.tableRect.width=available;controller.tableRect.height=math.max(24,height-top-8)
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
    controller.view.showing:SetText(tostring(count));controller.view.showingLabel:Show();controller.view.showing:Show()
    controller.view.lastScan:SetText("Last scan: "..(data.scannedAtText or "Unknown"))
    controller.view.empty:Hide();controller.view.scanButton:Hide();controller.view.refreshButton:Show();controller.view.rawButton:Show();controller.view.actionPanel:Show();controller.view.filterPanel:Show()
    GuildStatistics.Layout(controller);RenderTable(controller)
    local index
    for index=1,table.getn(controller.table.headers) do if controller.rawMode then controller.table.headers[index]:Hide() else controller.table.headers[index]:Show() end end
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
