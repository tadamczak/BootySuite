local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
MOS.Modules.Performance = MOS.Modules.Performance or {}
local Performance = MOS.Modules.Performance

local function Duration(value) return string.format("%.2f ms", (tonumber(value) or 0) * 1000) end
local function Memory(value)
    if type(value) ~= "number" then return "Unavailable" end
    if math.abs(value) >= 1024 then return string.format("%.2f MB", value / 1024) end
    return string.format("%.1f KB", value)
end
local function CompareTime(a, b) if a.time == b.time then return a.name < b.name end return a.time > b.time end
local rowColor = {1,1,1}
local tables = {
    operations = { first = "Operation", columns = {"Calls","Total","Average","Peak","Heap delta"}, minimum = 760, nameFraction = 0.34 },
    slow = { first = "Operation", columns = {"At","Duration","Heap delta","Event"}, minimum = 680, nameFraction = 0.34 },
    samples = { first = "At", columns = {"FPS","Lua heap","Latency"}, minimum = 460, nameFraction = 0.18 },
    memory = { first = "Addon", columns = {"Memory"}, minimum = 300, nameFraction = 0.70 },
}
local hints = {
    calls = "Successful calls to selected MOS entry points. Nested calls count once; this is not every addon action.",
    total = "Sum of time inside selected MOS calls. This is not total addon CPU time. GetTime resolution is unverified.",
    peak = "Longest single measured call in this session. Clock resolution and profiler overhead require native verification.",
    average = "Measured time divided by measured calls.",
    heap = "Change in the shared Lua heap. Garbage collection and measurement overhead are included; this is not memory owned by MOS or proof of a leak.",
    heapPeak = "Largest positive shared-heap change during one measured call; not gross allocation or retained addon memory.",
    fps = "A sampled FPS reading, not individual frame timings or proof of the cause of a drop.",
    lua = "Memory reported by gcinfo for the shared Lua heap across addons.",
    latency = "Network latency from GetNetStats. It is separate from frame rendering time.",
}
local function Elapsed(value)
    value=math.max(0,math.floor(tonumber(value) or 0))
    if value>=3600 then return string.format("%d:%02d:%02d",math.floor(value/3600),math.mod(math.floor(value/60),60),math.mod(value,60)) end
    return string.format("%02d:%02d",math.floor(value/60),math.mod(value,60))
end
local function TooltipTitle() return this.reportTitle or "" end
local function TooltipBody()
    local text,schema=this.reportHint or "",this.reportSchema
    if schema then for index=1,table.getn(schema.columns) do text=text.."\n"..schema.columns[index]..": "..this.values[index] end end
    return text
end
local function FontSize(label,size)
    local font,_,flags=label:GetFont();label:SetFont(font,size+UI.GetTextSizeDelta(label:GetParent()),flags)
end

function Performance.Create(parent)
    local page = UI.CreateContainer(nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 1.5, -3); page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1.5, 1.5); page:Hide()
    page.bodyHost=UI.CreateContainer(nil,page)
    page.canvas = UI.CreateResponsiveCanvas(page.bodyHost, "MuklaOfficerSuitePerformanceBody")
    page.header=UI.CreateContainer(nil,page)
    page.title = UI.CreateHeading(page.header, "Performance", 1, "gold")
    page.message = UI.CreateLabel(page.canvas, nil, "OVERLAY", "GameFontHighlight")
    page.message:SetJustifyH("LEFT"); if page.message.SetWordWrap then page.message:SetWordWrap(true) end
    local module = { frame = page, tab = "MOS", items = {}, rows = {}, sessionEntries = {}, metricFlow = {}, detailsExpanded = {} }

    local function AddItem(kind, text, data, value, hint)
        module.itemCount = module.itemCount + 1
        local item = module.items[module.itemCount]
        if not item then item = {}; table.insert(module.items, item) end
        item.kind, item.text, item.operation, item.value, item.hint = kind, text, data, value, hint
    end
    local function AddMetric(name, value, hint) AddItem("metric",name,nil,tostring(value),hint) end
    local function AddTable(name) AddItem("tableHeader",tables[name].first,tables[name]) end

    function module:GetSessionOperations()
        local state = self.provider and self.provider.GetState()
        local operations = state and state.session and state.session.operations or self.operationScope and self.operationScope.operations
        local entries, count, calls, total, heap, largest, slowestTime, slowest = self.sessionEntries, 0, 0, 0, 0, 0, 0, nil
        local name, operation
        if operations then
        for name, operation in pairs(operations) do
            calls, total, heap = calls + (operation.count or 0), total + (operation.time or 0), heap + (operation.memory or 0)
            if (operation.maxMemory or 0) > largest then largest = operation.maxMemory end
            if (operation.maxTime or 0) > slowestTime then slowestTime, slowest = operation.maxTime, name end
            if count < 128 then
                count = count + 1
                local entry = entries[count]
                if not entry then entry = {}; table.insert(entries, entry) end
                entry.name, entry.count, entry.time, entry.memory = name, operation.count or 0, operation.time or 0, operation.memory or 0
                entry.maxTime, entry.maxMemory = operation.maxTime or 0, operation.maxMemory or 0
            end
        end
        end
        for index = table.getn(entries), count + 1, -1 do table.remove(entries, index) end
        table.sort(entries, CompareTime)
        return calls, total, heap, largest, slowest, entries, slowestTime
    end

    function module:BuildItems()
        self.itemCount = 0
        local state, session = self.provider.GetState(), self.provider.GetState().session
        if not session then
            AddItem("message",state.enabled and "Ready to record. Press Start, use Roster or Raid, then Stop to inspect the results." or "Enable BootyProfiler, then press Start. Measurements stay off until you start a recording.")
            if self.tab=="All Addons" then AddItem("message","Global Lua heap and sampled FPS/latency. Per-addon callback timings are not available.") end
        elseif self.tab == "MOS" then
            local calls,total,heap,largest,slowest,entries,peak=self:GetSessionOperations()
            AddItem("message","Selected MOS operations. Heap values refer to shared Lua memory.")
            AddMetric("Measured calls",calls,hints.calls);AddMetric("Measured time",Duration(total),hints.total)
            AddMetric("Peak call time",calls>0 and Duration(peak) or "-",hints.peak);AddMetric("Average call time",calls>0 and Duration(total/calls) or "-",hints.average)
            AddMetric("Heap delta",Memory(heap),hints.heap);AddMetric("Peak heap rise",Memory(largest),hints.heapPeak)
            if slowest then AddItem("message","Slowest operation: "..slowest.." ("..Duration(peak)..")") end
            AddItem("heading","MOS operations — sorted by total time")
            if table.getn(entries)==0 then AddItem("message","No measured calls yet. Use Roster or Raid while recording.")
            else
                AddTable("operations")
                for index=1,table.getn(entries) do AddItem("operation",entries[index].name,entries[index],nil,hints.total.." "..hints.heap) end
            end
            AddItem("heading","Recent slow calls ("..session.history.count.."/64)")
            AddItem("message","Calls lasting at least 5 ms. Newest first.")
            if session.history.count==0 then AddItem("message","No measured calls reached 5 ms.")
            else
                AddTable("slow")
                for index=session.history.count,1,-1 do
                    local entry=self.provider.HistoryEntry(session.history,index)
                    AddItem("slow",entry.name,entry,nil,hints.peak.." "..hints.heap)
                end
            end
        else
            AddItem("message","Sampled FPS and shared Lua memory. Per-addon callback timings are not available.")
            AddMetric("Sampled FPS",session.fps and string.format("%.1f",session.fps) or "Unavailable",hints.fps)
            AddMetric("Minimum FPS",session.minFps and string.format("%.1f",session.minFps) or "Unavailable",hints.fps)
            AddMetric("Maximum FPS",session.maxFps and string.format("%.1f",session.maxFps) or "Unavailable",hints.fps)
            AddMetric("Lua heap",Memory(session.heap),hints.lua)
            AddMetric("Heap delta since Start",session.heap and session.startHeap and Memory(session.heap-session.startHeap) or "Unavailable",hints.heap)
            AddMetric("Network latency",session.latency and tostring(session.latency).." ms" or "Unavailable",hints.latency)
            AddItem("heading","Recent samples")
            AddItem("message","Up to one sample per second; last 10 shown, newest first. "..session.samples.count.."/600 retained.")
            AddTable("samples")
            for index=session.samples.count,math.max(1,session.samples.count-9),-1 do
                local entry=self.provider.HistoryEntry(session.samples,index)
                AddItem("sample",string.format("+%.1f s",entry.at),entry,nil,hints.fps.." "..hints.lua)
            end
        end
        if self.tab=="All Addons" then
            AddItem("heading","Memory by addon")
            local entries=state.addonEntries
            local supported=session and session.capabilities and session.capabilities.addonMemory
            if entries and table.getn(entries)>0 then
                AddItem("message","Last manual capture, sorted by memory. Use Refresh memory to update.")
                AddTable("memory")
                for index=1,table.getn(entries) do AddItem("memory",entries[index].name,entries[index]) end
            elseif supported==false then AddItem("message","Per-addon memory is unavailable in this client. Shared Lua memory is shown above.")
            else AddItem("message","Use Refresh memory to request per-addon memory when supported. It does not start recording.") end
            if state.addonMemoryTruncated then AddItem("message","Partial inventory: first 256 addons only.") end
        end
        if session then
            AddItem("technical","Technical details")
            if self.detailsExpanded[self.tab] then
                AddItem("message","Clock: "..session.clock.."; resolution "..session.clockResolution..".")
                AddItem("message",session.coverage.." "..hints.heap.." "..hints.fps)
                if self.tab=="All Addons" then AddItem("message",session.allAddonsCoverage);AddItem("message","GC threshold: "..Memory(session.gcThreshold)) end
                AddItem("message","BootyProfiler "..tostring(self.provider.version))
                if session.capabilities and MOS.Core.ClientCapabilities then
                    local runtime,extensions=MOS.Core.ClientCapabilities.Describe(session.capabilities)
                    AddItem("message",runtime);AddItem("message",extensions)
                end
            end
        end
        for index=table.getn(self.items),self.itemCount+1,-1 do table.remove(self.items,index) end
    end

    local function EnsureRow(index)
        local row = module.rows[index]
        if row then return row end
        row = UI.CreateControl(nil,page.canvas)
        row.label=UI.CreateLabel(row,nil,"OVERLAY","GameFontHighlightSmall")
        row.detail=UI.CreateLabel(row,nil,"OVERLAY","GameFontHighlightSmall")
        row.columns, row.values = {}, {}
        for column=1,5 do row.columns[column]=UI.CreateLabel(row,nil,"OVERLAY","GameFontHighlightSmall") end
        for _,label in ipairs({row.label,row.detail}) do
            label:SetJustifyH("LEFT");if label.SetWordWrap then label:SetWordWrap(true) end
            if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
        end
        UI.StyleSelectableTableRow(row,false,false)
        UI.AttachTooltip(row,TooltipTitle,TooltipBody)
        table.insert(module.rows,row);return row
    end
    local function ResetRow(row,item,width)
        row:SetWidth(width);row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,-6)
        row.label:SetWidth(math.max(1,width-16));row.label:SetHeight(0);FontSize(row.label,12);row.label:SetJustifyV("TOP")
        row.label:SetText(item.text);row.label:SetTextColor(1,1,1);row.label:Show()
        row.detail:Hide();for column=1,5 do row.columns[column]:Hide() end
        row.reportTitle,row.reportHint,row.reportSchema=item.text,item.hint,nil
        if row.label.SetNonSpaceWrap then row.label:SetNonSpaceWrap(true) end
        row:EnableMouse(item.hint~=nil)
        UI.SetRowColor(row,rowColor,0);row.mosTableRowSelection:Hide();row.mosTableRowHover:Hide();UI.SetProjectButtonOutline(row,false)
    end
    local function SetValue(row,index,value) row.values[index]=tostring(value) end
    local function TechnicalClick() this.reportModule:ToggleDetails() end
    local function MeasureTableRow(row,item,schema,width,stripe)
        local count=table.getn(schema.columns)
        row.reportSchema=schema
        local values=row.values
        if item.kind=="tableHeader" then for index=1,count do SetValue(row,index,schema.columns[index]) end
        elseif item.kind=="operation" then
            local data=item.operation
            SetValue(row,1,data.count);SetValue(row,2,Duration(data.time));SetValue(row,3,Duration(data.count>0 and data.time/data.count or 0))
            SetValue(row,4,Duration(data.maxTime));SetValue(row,5,Memory(data.memory))
        elseif item.kind=="slow" then
            local data=item.operation
            SetValue(row,1,string.format("+%.1f s",data.at));SetValue(row,2,Duration(data.elapsed));SetValue(row,3,Memory(data.heapChange));SetValue(row,4,data.event or "-")
        elseif item.kind=="sample" then
            local data=item.operation
            SetValue(row,1,data.fps and string.format("%.1f",data.fps) or "-");SetValue(row,2,Memory(data.heap));SetValue(row,3,data.latency and data.latency.." ms" or "-")
        else SetValue(row,1,Memory(item.operation.memory)) end
        if item.kind~="tableHeader" then
            UI.SetRowColor(row,rowColor,math.mod(stripe,2)==0 and 0.14 or 0.025);row:EnableMouse(true)
            row.reportHint=item.hint or "Last explicit native memory capture."
        end
        if width>=schema.minimum then
            local nameWidth=math.floor((width-16)*schema.nameFraction)
            local cellWidth=(width-16-nameWidth)/count
            row.label:SetWidth(nameWidth-8)
            local height=math.max(28,UI.MeasureTextHeight(row.label,nameWidth-8)+12)
            row.label:SetHeight(height);row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,0);row.label:SetJustifyV("MIDDLE")
            for index=1,count do
                local label=row.columns[index];FontSize(label,12)
                UI.Table.Cell(label,row,8+nameWidth+(index-1)*cellWidth,cellWidth-8,height,values[index]);label:SetJustifyH("RIGHT")
                if item.kind=="tableHeader" then label:SetTextColor(unpack(UI.Theme.colors.goldText)) else label:SetTextColor(1,1,1) end
                label:Show()
            end
            if item.kind=="tableHeader" then row.label:SetTextColor(unpack(UI.Theme.colors.goldText));row:EnableMouse(false) end
            return height
        end
        if item.kind=="tableHeader" then row.label:Hide();return 0 end
        local height=UI.MeasureTextHeight(row.label,width-16)+10
        local columns=width>=360 and 2 or 1
        local cellWidth=(width-16)/columns
        for first=1,count,columns do
            local bandHeight=0
            for index=first,math.min(count,first+columns-1) do
                local label=row.columns[index];FontSize(label,12);label:ClearAllPoints()
                label:SetPoint("TOPLEFT",row,"TOPLEFT",8+(index-first)*cellWidth,-height)
                label:SetWidth(math.max(1,cellWidth-8));label:SetHeight(0);label:SetJustifyH("LEFT")
                if label.SetWordWrap then label:SetWordWrap(true) end
                if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
                label:SetText(schema.columns[index]..": "..values[index]);label:SetTextColor(0.86,0.86,0.86);label:Show()
                bandHeight=math.max(bandHeight,UI.MeasureTextHeight(label,cellWidth-8))
            end
            height=height+bandHeight+4
        end
        return height+4
    end
    local function MeasureItems(width, top)
        local y,index,stripe,schema=top,1,0,nil
        page.detailsToggle:Hide()
        while index<=module.itemCount do
            local item,row=module.items[index],EnsureRow(index)
            if item.kind=="metric" then
                local columns=math.min(3,math.max(1,math.floor((width+8)/228)))
                local cardWidth=math.floor((width-(columns-1)*8)/columns)
                local flow,count,height=module.metricFlow,0,0
                while index<=module.itemCount and module.items[index].kind=="metric" do
                    item,row=module.items[index],EnsureRow(index);ResetRow(row,item,cardWidth)
                    row.label:SetTextColor(unpack(UI.Theme.colors.goldText));row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,-8);row.label:SetWidth(math.max(1,cardWidth-16))
                    local labelHeight=UI.MeasureTextHeight(row.label,cardWidth-16)
                    row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",row,"TOPLEFT",8,-labelHeight-12);row.detail:SetWidth(math.max(1,cardWidth-16));row.detail:SetHeight(0)
                    FontSize(row.detail,18);row.detail:SetText(item.value);row.detail:SetTextColor(1,1,1);row.detail:Show()
                    height=math.max(height,labelHeight+UI.MeasureTextHeight(row.detail,cardWidth-16)+20)
                    UI.SetRowColor(row,rowColor,0.045);row.mosFlowWidth=cardWidth;row:Show()
                    count=count+1;flow[count]=row;index=index+1
                end
                for tail=table.getn(flow),count+1,-1 do table.remove(flow,tail) end
                for card=1,count do flow[card]:SetHeight(height) end
                y=UI.LayoutFlow(page.canvas,flow,8,y,width,8)+12
            else
                ResetRow(row,item,width);row:ClearAllPoints();row:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-y)
                local height=math.max(22,UI.MeasureTextHeight(row.label,width-16)+12)
                if item.kind=="tableHeader" then schema=item.operation;stripe=0;height=MeasureTableRow(row,item,schema,width,0)
                elseif item.kind=="operation" or item.kind=="slow" or item.kind=="sample" or item.kind=="memory" then
                    stripe=stripe+1;height=MeasureTableRow(row,item,schema,width,stripe)
                elseif item.kind=="heading" then
                    FontSize(row.label,14);row.label:SetTextColor(unpack(UI.Theme.colors.goldText))
                    height=UI.MeasureTextHeight(row.label,width-16)+16
                elseif item.kind=="technical" then
                    row.label:Hide();row:EnableMouse(false)
                    local toggle=page.detailsToggle
                    if toggle:GetParent()~=row then toggle:SetParent(row) end
                    toggle:ClearAllPoints();toggle:SetPoint("TOPLEFT",row,"TOPLEFT",8,0);toggle:SetWidth(math.max(1,width-16));toggle:SetHeight(26)
                    toggle.label:SetText((module.detailsExpanded[module.tab] and "- " or "+ ").."Technical details")
                    UI.FitButtonLabel(toggle,width-32);toggle.label:SetJustifyH("LEFT")
                    toggle.rule:Hide();toggle:SetExpanded(module.detailsExpanded[module.tab]);toggle:Show();height=26
                else row.label:SetTextColor(0.78,0.78,0.78) end
                row:SetHeight(math.max(1,height));if height>0 then row:Show();y=y+height+2 else row:Hide() end
                index=index+1
            end
        end
        for index=module.itemCount+1,table.getn(module.rows) do module.rows[index]:Hide() end
        return y+8
    end

    function module:EnsureUI()
        if page.controls then return end
        page.tabs=UI.CreateToolbarSurface(page.header,true,true);page.controls=UI.CreateToolbarSurface(page.header,false,true)
        page.mosTab=UI.CreateButton(page.tabs,nil,"MOS",90,26);page.allTab=UI.CreateButton(page.tabs,nil,"All Addons",120,26)
        page.enableButton=UI.CreateButton(page.controls,nil,"Enable",88,26)
        page.startButton=UI.CreateButton(page.controls,nil,"Start",82,26);page.stopButton=UI.CreateButton(page.controls,nil,"Stop",82,26)
        page.resetButton=UI.CreateButton(page.controls,nil,"Reset",82,26);page.exportButton=UI.CreateButton(page.controls,nil,"Export",82,26)
        page.monitorButton=UI.CreateButton(page.controls,nil,"Live Monitor",126,26)
        page.memoryButton=UI.CreateButton(page.controls,nil,"Refresh memory",142,26)
        page.tabFlow={page.mosTab,page.allTab};page.actions={page.enableButton,page.startButton,page.stopButton,page.resetButton,page.exportButton,page.monitorButton,page.memoryButton};page.flow={}
        for _,flow in ipairs({page.tabFlow,page.actions}) do for _,button in ipairs(flow) do button.mosFlowWidth=button:GetWidth();UI.StyleActionButton(button) end end
        page.status=UI.CreateLabel(page.header,nil,"OVERLAY","GameFontHighlightSmall");page.status:SetJustifyH("LEFT");if page.status.SetWordWrap then page.status:SetWordWrap(true) end
        page.detailsToggle=UI.Settings.CreateSectionAccordion(page.canvas,"Technical details",0)
        page.detailsToggle.reportModule=module;page.detailsToggle:SetScript("OnClick",TechnicalClick);page.detailsToggle:Hide()
        page.mosTab:SetScript("OnClick",function() module:SelectTab("MOS") end);page.allTab:SetScript("OnClick",function() module:SelectTab("All Addons") end)
        page.enableButton:SetScript("OnClick",function() module.provider.Enable(not module.provider.GetState().enabled);module.notice=nil;module:Refresh() end)
        page.startButton:SetScript("OnClick",function() module:Start() end);page.stopButton:SetScript("OnClick",function() module:Stop() end)
        page.resetButton:SetScript("OnClick",function() module:Reset() end);page.exportButton:SetScript("OnClick",function() module:Export() end)
        page.monitorButton:SetScript("OnClick",function() module:ToggleMonitor() end)
        page.memoryButton:SetScript("OnClick",function() module:RefreshAddons() end)
        UI.AttachTooltip(page.exportButton,"Export session","Stores one bounded report in BootyProfiler SavedVariables. Stop first; /reload or logout writes it to disk.")
        UI.AttachTooltip(page.enableButton,"Enable / Disable","Enable does not record. Disable stops recording. Recording never resumes automatically after reload.")
        UI.AttachTooltip(page.memoryButton,"Memory by addon","Explicitly refresh native addon memory statistics when available. This may perform work across all addons.")
    end
    local function MeasureHeader(width)
        page.header:SetWidth(width)
        page.title:ClearAllPoints();page.title:SetPoint("TOPLEFT",page.header,"TOPLEFT",8,-8);UI.FitButtonLabel(page.title,width-16)
        if not module.provider then page.header:SetHeight(38);return 38 end
        local tabHeight=UI.LayoutFlow(page.tabs,page.tabFlow,8,8,width-16,8)+8
        page.tabs:ClearAllPoints();page.tabs:SetPoint("TOPLEFT",page.header,"TOPLEFT",0,-38);page.tabs:SetWidth(width);page.tabs:SetHeight(tabHeight)
        local controlHeight=UI.LayoutFlow(page.controls,page.flow,8,8,width-16,8)+8
        page.controls:ClearAllPoints();page.controls:SetPoint("TOPLEFT",page.header,"TOPLEFT",0,-38-tabHeight);page.controls:SetWidth(width);page.controls:SetHeight(controlHeight)
        local top=38+tabHeight+controlHeight+8
        page.status:ClearAllPoints();page.status:SetPoint("TOPLEFT",page.header,"TOPLEFT",8,-top);page.status:SetWidth(math.max(1,width-16));page.status:SetHeight(0)
        top=top+math.max(16,UI.MeasureTextHeight(page.status,width-16))+8;page.header:SetHeight(top);return top
    end
    local function MeasurePage(width)
        local top=8
        if not module.headerPinned then top=MeasureHeader(width)+8 end
        if not module.provider then
            page.message:ClearAllPoints();page.message:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-top);page.message:SetWidth(math.max(1,width-16));page.message:SetHeight(0)
            return top+8+UI.MeasureTextHeight(page.message,width-16)
        end
        return MeasureItems(math.max(1,width-16),top)
    end
    function module:Layout()
        local width,height=UI.GetFrameSpan(parent)
        width,height=math.max(80,width-3),math.max(80,height-4.5)
        page:SetWidth(width);page:SetHeight(height)
        local headerHeight=MeasureHeader(width)
        self.headerPinned=self.provider~=nil and height>=headerHeight+120
        local headerParent=self.headerPinned and page or page.canvas
        if page.header:GetParent()~=headerParent then page.header:SetParent(headerParent) end
        page.header:ClearAllPoints();page.header:SetPoint("TOPLEFT",headerParent,"TOPLEFT",0,0)
        local inset=self.headerPinned and headerHeight or 0
        page.bodyHost:ClearAllPoints();page.bodyHost:SetPoint("TOPLEFT",page,"TOPLEFT",0,-inset)
        height=math.max(1,height-inset)
        page.bodyHost:SetWidth(width);page.bodyHost:SetHeight(height)
        UI.LayoutResponsiveCanvas(page.canvas,MeasurePage,self,width,height)
    end
    function module:Refresh()
        if not self.provider then return end
        local state=self.provider.GetState()
        if self.monitor and self.monitor:IsVisible() then
            local session=state.session
            self.monitor.text:SetText((state.recording and "Recording" or state.enabled and "Stopped" or "Disabled") .. "\nLua: " .. Memory(session and session.heap) .. "\nFPS: " .. tostring(session and session.fps or "-") .. "\nTime: " .. string.format("%.1f s",session and session.elapsed or 0))
        end
        if not page:IsVisible() then return end
        self:EnsureUI();self:BuildItems()
        local actionCount=self.tab=="All Addons" and 7 or 6
        for index=1,actionCount do page.flow[index]=page.actions[index];page.actions[index]:Show() end
        for index=actionCount+1,table.getn(page.actions) do page.actions[index]:Hide() end
        for index=table.getn(page.flow),actionCount+1,-1 do table.remove(page.flow,index) end
        page.enableButton:SetText(state.enabled and "Disable" or "Enable")
        UI.SetButtonEnabled(page.startButton,state.enabled and not state.recording);UI.SetButtonEnabled(page.stopButton,state.recording)
        UI.SetButtonEnabled(page.resetButton,state.session~=nil);UI.SetButtonEnabled(page.exportButton,state.session~=nil and not state.recording)
        local memorySupported=state.session and state.session.capabilities and state.session.capabilities.addonMemory
        UI.SetButtonEnabled(page.memoryButton,state.enabled and self.tab=="All Addons" and memorySupported~=false)
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(page.mosTab,self.tab=="MOS");UI.SetClassicButtonSelected(page.allTab,self.tab=="All Addons") end
        UI.SetProjectButtonOutline(page.mosTab,self.tab=="MOS");UI.SetProjectButtonOutline(page.allTab,self.tab=="All Addons")
        page.status:SetText((state.recording and "Recording" or state.enabled and "Ready / stopped" or "Disabled") .. (state.session and " | "..Elapsed(state.session.elapsed).." elapsed" or "") .. (state.error and "\n" .. state.error or self.notice and "\n" .. self.notice or ""))
        if state.recording then page.status:SetTextColor(unpack(UI.Theme.colors.goldText)) else page.status:SetTextColor(1,1,1) end
        self:Layout()
    end
    local function Updated() module:Refresh() end
    local function Subscribe()
        if module.provider then module.provider.SetListener((page:IsVisible() or module.monitor and module.monitor:IsVisible()) and Updated or nil) end
    end
    function module:SelectTab(tab) self.tab=tab;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end
    function module:ToggleDetails() self.detailsExpanded[self.tab]=not self.detailsExpanded[self.tab];self:Refresh() end
    function module:Start() if not self.provider then return false end local ok,message=self.provider.Start();self.notice=message;self:Refresh();return ok end
    function module:Stop() if self.provider then self.provider.Stop();self:Refresh() end end
    function module:Reset() if self.provider then self.provider.Reset();self.notice=nil;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end end
    function module:Export()
        local result,message=self.provider.Export()
        self.notice=result and "Session exported. Use /reload or logout to write BootyProfiler SavedVariables to disk." or message
        self:Refresh();return result
    end
    function module:RefreshAddons()
        local ok,message=self.provider.ReadAddonMemory()
        self.addonEntries=self.provider.GetState().addonEntries
        self.notice=ok and "Native addon memory refreshed." or message
        self:Refresh();return ok
    end
    function module:ToggleMonitor()
        if not self.monitor then
            local monitor=UI.CreateContainer(nil,UIParent);monitor:SetPoint("CENTER",UIParent,"CENTER",280,100);monitor:SetWidth(260);monitor:SetHeight(142)
            monitor:SetFrameStrata("FULLSCREEN_DIALOG");monitor:SetMovable(true);monitor:EnableMouse(true);monitor:RegisterForDrag("LeftButton")
            if monitor.SetClampedToScreen then monitor:SetClampedToScreen(true) end
            monitor.title=UI.CreateHeading(monitor,"BootyProfiler",3,"gold");monitor.title:SetPoint("TOPLEFT",monitor,"TOPLEFT",8,-8)
            monitor.close=UI.CreateWindowButton(monitor,nil,"close");monitor.close:SetPoint("TOPRIGHT",monitor,"TOPRIGHT",-8,-8)
            monitor.close:SetScript("OnClick",function() monitor:Hide();Subscribe() end)
            monitor.text=UI.CreateLabel(monitor,nil,"OVERLAY","GameFontHighlightSmall");monitor.text:SetPoint("TOPLEFT",monitor,"TOPLEFT",8,-38);monitor.text:SetWidth(244);monitor.text:SetJustifyH("LEFT")
            monitor:SetScript("OnDragStart",function() this:StartMoving() end);monitor:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
            monitor:SetScript("OnShow",Subscribe);monitor:SetScript("OnHide",Subscribe)
            UI.Window.StyleProjectDialog(monitor);monitor:Hide();self.monitor=monitor
        end
        if self.monitor:IsShown() then self.monitor:Hide() else self.monitor:Show() end
        Subscribe();self:Refresh()
    end
    function module:Show()
        local bridge=MOS.Core.ProfilerBridge
        local provider,failure
        if bridge then provider,failure=bridge.Connect() else failure="BootyProfiler integration is unavailable." end
        if self.provider and self.provider~=provider then self.provider.SetListener(nil) end
        self.provider=provider;page:Show()
        if provider then
            self:EnsureUI();page.message:Hide();page.tabs:Show();page.controls:Show();page.status:Show()
            Subscribe();self:Refresh()
        else
            page.message:SetText(failure);page.message:Show()
            if page.controls then page.tabs:Hide();page.controls:Hide();page.status:Hide() end
            self.itemCount=0;for _,row in ipairs(self.rows) do row:Hide() end
            self:Layout()
        end
    end
    function module:Hide() page:Hide();Subscribe() end
    function module:OnResize() if page:IsVisible() then self:Layout() end end
    page:SetScript("OnShow",Subscribe);page:SetScript("OnHide",Subscribe)
    module:Layout();return module
end
