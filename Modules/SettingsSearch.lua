local MOS = MuklaOfficerSuite
local Settings = MOS.Modules.Settings
local UI = MOS.UI.Components
local Policy = MOS.Core.SettingsSearch

local function Node(text, heading, children)
    local node = {text=text, heading=heading, children=children or {}}
    node.expanded = not heading or not heading.SetScript
    if heading and heading.indicator then node.expanded = heading.indicator:GetText() == "-" end
    return node
end

local function Field(control, kind, companions, text)
    local label = control.fieldLabel or control.label
    return {text=text or control.settingLabel or label and label:GetText() or "", key=control.settingKey,
        control=control, kind=kind or (control.swatchBorder and "color" or control.SaveSetting and "check" or "row"), companions=companions}
end

local function Fields(controls, kind)
    local nodes = {}
    for _, control in ipairs(controls or {}) do table.insert(nodes, Field(control, kind)) end
    return nodes
end

local function Append(nodes, extra)
    for _, node in ipairs(extra) do table.insert(nodes, node) end
    return nodes
end

local function Group(view, shell)
    local size = Fields(view.autoChecks)
    if view.columnsButton then table.insert(size, 1, Field(view.columnsButton, "choice")) end
    Append(size, Fields(view.sliders, "slider"))
    local color = Append(Fields(view.colorChecks), Fields(view.colors, "color"))
    table.insert(color, Field(view.lightnessField, "row", {view.lightnessLabel}, "Odd record lightness (%)"))
    return Node("Group View", shell.groupHeading, {
        Node("Display", view.displayHeading, Fields(view.displayChecks)),
        Node("Size", view.sizeHeading, size),
        Node("Member tile color", view.colorHeading, color),
        Node("Group tile color", view.tileColorHeading, Fields(view.tileColors, "color")),
    })
end

local function Collect(node, result, seen)
    local function Add(frame)
        if frame and not seen[frame] then seen[frame] = true; table.insert(result, frame) end
    end
    Add(node.heading); Add(node.heading and node.heading.resetButton)
    Add(node.control)
    if node.control then Add(node.control.fieldLabel) end
    for _, frame in ipairs(node.companions or {}) do Add(frame) end
    for _, child in ipairs(node.children or {}) do Collect(child, result, seen) end
end

local function Remember(search, frame)
    if not frame or search.saved[frame] then return end
    local saved = {frame=frame, points={}, width=frame.GetWidth and frame:GetWidth(), height=frame.GetHeight and frame:GetHeight(), shown=frame:IsShown(), flowWidth=frame.mosFlowWidth}
    for index=1, frame.GetNumPoints and frame:GetNumPoints() or 0 do table.insert(saved.points, {frame:GetPoint(index)}) end
    search.saved[frame] = saved; table.insert(search.restore, saved)
end

local function At(search, frame, page, x, y)
    Remember(search, frame)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", page, "TOPLEFT", x, y)
end

local function Prepare(search, control)
    Remember(search, control); Remember(search, control.label); Remember(search, control.labelHit)
    Remember(search, control.fieldLabel)
end

local function ShowParents(control, page)
    local parent = control:GetParent()
    while parent and parent ~= page do parent:Show(); parent=parent:GetParent() end
end

local function BindHeading(page, node)
    local heading = node.heading
    if heading and heading.SetScript then
        local previous = heading:GetScript("OnClick")
        heading:SetScript("OnClick", function()
            if Settings.IsSearchActive(page) then node.expanded=not node.expanded; Settings.LayoutSearch(page)
            elseif previous then previous() end
        end)
    end
    for _, child in ipairs(node.children or {}) do BindHeading(page, child) end
end

function Settings.IsSearchActive(page)
    return page.settingsSearch and page.settingsSearch.query ~= ""
end

local function Build(page)
    Settings.EnsureGameRaidControls(page)
    Settings.EnsureAddonMessageControls(page)
    local profile, primary, raid = page.profiles, page.primarySections, page.raidAccordionControls
    local views, game, messages = page.responsiveRaid, page.gameUI, page.addonMessages
    local profileNodes = {
        Field(profile.currentLabel, "row", {profile.current,profile.Save,profile.saveStatus}, "Current profile Save"),
        Field(profile.select, "row", {profile.loadLabel,profile.Load,profile.Delete,profile.Export,profile.loadStatus}, "Load profile Delete Export"),
        Field(profile.name, "row", {profile.newLabel,profile.Add,profile.addStatus}, "New profile Add"),
    }
    profileNodes[1].flow={profile.currentLabel,profile.current,profile.Save,profile.saveStatus}
    profileNodes[2].flow={profile.loadLabel,profile.select,profile.Load,profile.Delete,profile.Export,profile.loadStatus}
    profileNodes[3].flow={profile.newLabel,profile.name,profile.Add,profile.addStatus}
    local general = {Field(page.skinControl,"choice")}; Append(general, Fields(page.generalGrid))
    local listColors = Fields(views.list.colors,"color")
    table.insert(listColors, Field(views.list.lightnessField,"row",{views.list.lightnessLabel},"Odd record lightness (%)"))
    local lootFields={}
    if raid.opacityField then table.insert(lootFields,Field(raid.opacityField,"row",{raid.opacityLabel},"Opacity (%)")) end
    if raid.focusField then table.insert(lootFields,Field(raid.focusField,"row",{raid.focusLabel},"Out-of-focus opacity (%)")) end
    local addon = {
        Node("General",page.uiGeneralHeading,general),
        Node("Layout",page.uiLayoutHeading,{
            Node("General",page.uiLayoutGeneralHeading,{Field(page.menuStyleControl,"choice"),Field(page.iconTabsCheck)}),
            Node("Display",page.uiLayoutDisplayHeading,Fields(page.chromeChecks)),
        }),
        Node("Guild",primary.rosterHeading,{
            Node("General",primary.rosterGeneral,{Field(page.playerDetailsControl,"choice"),Field(page.rosterLiveTrackingCheck)}),
            Node("Layout",primary.rosterLayout,{
                Node("Display",page.rosterDisplayHeading,Fields(page.rosterLayoutChecks)),
                Node("Member tile color",page.rosterColorHeading,Append({Field(page.rosterClassColorsCheck)},
                    Append(Fields(page.rosterColors,"color"),{Field(page.rosterLightnessField,"row",{page.rosterLightnessLabel},"Odd record lightness (%)")}))),
            }),
        }),
        Node("Raid",primary.raidHeading,{
            Node("General",raid.general,Fields(raid.generalControls)),
            Node("Layout",raid.layout,{Group(views.group,views.shell),Node("List View",views.shell.listHeading,{
                Node("Display",views.list.displayHeading,Fields(views.list.checks)),
                Node("Size",views.list.sizeHeading,Fields(views.list.sliders,"slider")),
                Node("Member tile color",views.list.colorHeading,listColors),
            })}),
            Node("Raid Leader Mode",raid.leader),
            Node("Loot Master Mode",raid.loot,lootFields),
        }),
    }
    for _, section in ipairs(page.uiEmptySections) do
        table.insert(addon,Node(section.heading.baseText,section.heading,{Node("General",section.general),Node("Layout",section.layout)}))
    end
    local messageNodes = {}
    for index, row in ipairs(messages.rows) do
        local definition = MOS.Services.LootMessages.Definitions[index]
        table.insert(messageNodes,Field(row.check,"message",{row.field},definition[2].." "..definition[4]))
    end
    local roots = {
        Node("Profile",profile.heading,{Node("General",profile.general,profileNodes)}),
        Node("Addon UI",page.uiHeading,addon),
        Node("Game UI",game.heading,{Node("Interface",game.interface,{Field(page.interfaceCheck)}),
            Node("Layout",game.layout,{Node("Raid",game.raid,{Group(game.group,game.shell)})})}),
        Node("Addon Messages",messages.heading,{Node("Loot Master",messages.loot,messageNodes)}),
        Node("Keybindings",page.keybindings.heading,{Node("General",page.keybindings.general)}),
        Node("Debug",raid.debugHeading,{Field(page.chatLogsCheck)}),
    }
    local search = page.settingsSearch
    search.roots, search.controls = roots, {}
    local seen = {}
    for _, node in ipairs(roots) do Collect(node,search.controls,seen); BindHeading(page,node) end
    -- Background-only hosts may otherwise cover labels after compact reflow.
    search.panels={views.shell.panel,game.shell.panel}
    for _, panel in ipairs(search.panels) do
        local red,green,blue,alpha=panel:GetBackdropColor()
        table.insert(search.backgrounds,{panel,red or 0.025,green or 0.025,blue or 0.025,alpha or 0.48})
    end
    Policy.Index(roots)
end

local function LayoutField(page, search, node, x, y, width)
    local control=node.control
    if control.settingKey == "rosterShowOfficerNote" and not Settings.CanShowOfficerOption() then return y end
    if control == page.iconTabsCheck and MOS.Database.GetSetting("menuStyle") ~= "tabs" and MOS.Database.GetSetting("menuStyle") ~= "bottomTabs" then return y end
    Prepare(search,control); ShowParents(control,page); control:Show()
    for _, frame in ipairs(node.companions or {}) do Prepare(search,frame); ShowParents(frame,page); frame:Show() end
    if node.kind=="check" or node.kind=="color" then
        return y-UI.Settings.LayoutGrid(page,{control},x,y,width,28)-4
    elseif node.kind=="slider" then
        return y-18-UI.Settings.LayoutGrid(page,{control},x,y-18,width,46,true)-4
    elseif node.kind=="choice" then
        control.fieldLabel:Show(); ShowParents(control.fieldLabel,page)
        At(search,control.fieldLabel,page,x,y-4)
        local desired=search.saved[control].width
        control:SetWidth(math.max(1,math.min(width,desired)))
        if control.fieldLabel:GetStringWidth()+10+desired>width then
            At(search,control,page,x,y-22);return y-22-control:GetHeight()-8
        end
        control:ClearAllPoints();control:SetPoint("LEFT",control.fieldLabel,"RIGHT",10,0)
        return y-32
    elseif node.kind=="message" then
        local field=node.companions[1]
        local used=UI.Settings.LayoutGrid(page,{control},x,y,width,26)
        At(search,field,page,x,y-used);field:SetWidth(math.max(1,width));field:RefreshValue()
        return y-used-field:GetHeight()-10
    end
    local fields={}
    local candidates=node.flow or {}
    if not node.flow then
        for _, frame in ipairs(node.companions or {}) do table.insert(candidates,frame) end
        table.insert(candidates,control)
    end
    for _, frame in ipairs(candidates) do
        if frame.SetScript or frame.GetText and frame:GetText() ~= "" then
            local saved=search.saved[frame]
            frame.mosFlowWidth=saved.flowWidth or saved.width
            if not frame.SetScript then
                frame.mosFlowWidth=math.max(1,frame:GetStringWidth()+2)
                local _,size=frame:GetFont();frame:SetHeight((size or 12)+4)
            end
            table.insert(fields,frame)
        end
    end
    local used=UI.LayoutFlow(page,fields,x,-y,width,6)
    return -used-8
end

local function LayoutNode(page,search,node,depth,y)
    if not node.visible then return y end
    if node.heading then
        local heading=node.heading
        ShowParents(heading,page);At(search,heading,page,depth*12,y)
        if heading.SetScript then
            heading:SetPoint("TOPRIGHT",page,"TOPRIGHT",0,y)
            heading.label:SetText((node.expanded and "-  " or "+  ")..node.text)
            if heading.SetExpanded then heading:SetExpanded(node.expanded) end
        else heading:SetText(node.text) end
        heading:Show();y=y-28
        if not node.expanded then return y end
    end
    if node.control then y=LayoutField(page,search,node,depth*12,y,math.max(1,page:GetWidth()-depth*12-12)) end
    for _, child in ipairs(node.children or {}) do y=LayoutNode(page,search,child,depth+1,y) end
    return y
end

function Settings.LayoutSearch(page)
    local search=page.settingsSearch
    if not search or search.query=="" or search.busy then return end
    search.busy=true
    if not search.roots then Build(page) end
    for _, control in ipairs(search.controls) do
        Remember(search,control);control:Hide()
        if control.panel then control.panel:Hide() end
    end
    for _, panel in ipairs(search.panels) do panel:SetBackdropColor(0,0,0,0) end
    page.globalReset:Hide()
    local count=Policy.Apply(search.roots,search.query)
    local y=-10
    for _, node in ipairs(search.roots) do y=LayoutNode(page,search,node,0,y) end
    if count==0 then
        search.empty:SetText("No settings match your search.");search.empty:Show();y=y-32
    else search.empty:Hide() end
    page.settingsContentHeight=math.max(32,-y+8)
    search.busy=nil
    Settings.UpdateScroll(page.settingsViewport,page,page.settingsContentHeight)
end

local function Restore(page)
    local search=page.settingsSearch
    page.searchRestoring=true
    for _, saved in ipairs(search.restore) do
        local frame=saved.frame
        frame:ClearAllPoints()
        for _, point in ipairs(saved.points) do
            local x=point[4]
            if x and frame.mosHeadingIconInset then
                x=x-(string.find(point[1],"LEFT",1,true) and frame.mosHeadingIconInset or point[1]=="CENTER" and frame.mosHeadingIconInset/2 or 0)
            end
            frame:SetPoint(point[1],point[2],point[3],x,point[5])
        end
        if saved.width then frame:SetWidth(saved.width>0 and saved.width+(frame.mosHeadingIconInset or 0) or saved.width) end
        if saved.height then frame:SetHeight(saved.height) end
        frame.mosFlowWidth=saved.flowWidth
        if saved.shown then frame:Show() else frame:Hide() end
    end
    for _, background in ipairs(search.backgrounds) do background[1]:SetBackdropColor(background[2],background[3],background[4],background[5]) end
    search.empty:Hide();search.saved={};search.restore={}
    page.searchRestoring=nil
end

function Settings.SetSearch(page,query)
    local search=page.settingsSearch
    query=Policy.Normalize(query)
    if search.query==query then return end
    local prior=search.query
    search.query=query
    if UI.openDropdownPanel then UI.openDropdownPanel:Hide() end
    if query=="" then
        if prior~="" then Restore(page) end
        Settings.ApplyTopSections(page)
    else Settings.LayoutSearch(page) end
end

function Settings.CreateSearchToolbar(page,toolbar)
    page.settingsSearch={query="",saved={},restore={},backgrounds={}}
    local search=page.settingsSearch
    search.empty=UI.CreateComponentLabel(page,"No settings match your search.","white")
    search.empty:SetPoint("TOPLEFT",page,"TOPLEFT",12,-10);search.empty:Hide()
    local field=UI.CreateFramedEditBox(toolbar,"MuklaOfficerSuiteSettingsSearch",200,20)
    field:SetPoint("TOPLEFT",toolbar,"TOPLEFT",4,-4);field:SetPoint("BOTTOMRIGHT",toolbar,"BOTTOMRIGHT",-4,4)
    field:SetMaxLetters(100);field:SetAutoFocus(false)
    field:SetScript("OnTextChanged",function() if page:IsVisible() then Settings.SetSearch(page,this:GetText()) end end)
    UI.AttachPlaceholder(field,"Search settings...")
    field:SetScript("OnEscapePressed",function() this:SetText("");Settings.SetSearch(page,"");this:ClearFocus() end)
    field:SetScript("OnEnterPressed",function() this:ClearFocus() end)
    field:SetScript("OnHide",function() this:ClearFocus() end)
    search.field=field
end
