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

function Performance.Create(parent)
    local page = UI.CreateContainer(nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", 1.5, -3); page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -1.5, 1.5); page:Hide()
    page.canvas = UI.CreateResponsiveCanvas(page, "MuklaOfficerSuitePerformanceBody")
    page.title = UI.CreateHeading(page.canvas, "Performance", 1, "gold")
    page.message = UI.CreateLabel(page.canvas, nil, "OVERLAY", "GameFontHighlight")
    page.message:SetJustifyH("LEFT"); if page.message.SetWordWrap then page.message:SetWordWrap(true) end
    local module = { frame = page, tab = "MOS", items = {}, rows = {}, sessionEntries = {} }

    local function AddItem(kind, text, operation)
        module.itemCount = module.itemCount + 1
        local item = module.items[module.itemCount]
        if not item then item = {}; table.insert(module.items, item) end
        item.kind, item.text, item.operation = kind, text, operation
    end
    local function AddMetric(name, value) AddItem("metric", name .. ": " .. tostring(value)) end

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
        return calls, total, heap, largest, slowest, entries
    end

    function module:BuildItems()
        self.itemCount = 0
        local state, session = self.provider.GetState(), self.provider.GetState().session
        if not session then
            AddItem("message", state.enabled and "Press Start to record. Opening Performance does not start measurements." or "BootyProfiler is loaded but disabled. Enable it, then press Start when you want to measure.")
            if self.tab == "All Addons" then AddItem("message", "Package 1: global Lua heap, sampled FPS and latency. Other addons' callback profiling arrives in package 2.") end
        elseif self.tab == "MOS" then
            local calls, total, heap, largest, slowest, entries = self:GetSessionOperations()
            AddItem("message", session.coverage .. " Heap deltas are global, include collection and measurement overhead, and are not MOS-owned memory.")
            AddMetric("Recorded time", string.format("%.1f s", session.elapsed))
            AddMetric("Measured calls", calls); AddMetric("Measured time", Duration(total))
            AddMetric("Average measured call", Duration(calls > 0 and total / calls or 0))
            AddMetric("Signed heap change during calls", Memory(heap)); AddMetric("Largest single call heap rise", Memory(largest))
            AddMetric("Slowest single call", slowest or "-")
            AddMetric("Clock", session.clock .. "; resolution " .. session.clockResolution)
            AddItem("heading", "MOS operations: Calls | Total | Average | Maximum | Heap")
            if table.getn(entries) == 0 then AddItem("message", "No measured MOS operations in this session.") end
            for index = 1, table.getn(entries) do AddItem("operation", entries[index].name, entries[index]) end
            AddItem("heading", "Recent slow calls (at least 5 ms; last 64)")
            if session.history.count == 0 then AddItem("message", "No calls reached the slow-call threshold.") end
            for index = 1, session.history.count do
                local entry = self.provider.HistoryEntry(session.history, index)
                AddItem("history", string.format("+%.2f s  %s — %s; heap %s%s", entry.at, entry.name, Duration(entry.elapsed), Memory(entry.heapChange), entry.event and "  [" .. entry.event .. "]" or ""))
            end
        else
            AddItem("message", session.allAddonsCoverage .. " FPS samples are not individual frame timings; no automatic cause of a drop is inferred.")
            AddMetric("Recorded time", string.format("%.1f s", session.elapsed))
            AddMetric("Last sampled Lua heap", Memory(session.heap))
            AddMetric("Global heap change since Start", session.heap and session.startHeap and Memory(session.heap-session.startHeap) or "Unavailable")
            AddMetric("GC threshold", Memory(session.gcThreshold))
            AddMetric("Last sampled FPS", session.fps and string.format("%.1f", session.fps) or "Unavailable")
            AddMetric("Minimum / maximum sampled FPS", session.minFps and string.format("%.1f / %.1f",session.minFps,session.maxFps) or "Unavailable")
            AddMetric("Network latency", session.latency and tostring(session.latency) .. " ms" or "Unavailable")
            AddMetric("Samples retained", session.samples.count .. " / 600 (one per second)")
            if session.capabilities and MOS.Core.ClientCapabilities then
                local runtime, extensions = MOS.Core.ClientCapabilities.Describe(session.capabilities)
                AddItem("message",runtime);AddItem("message",extensions)
            end
            AddItem("heading","Recent samples (last 10)")
            for index = math.max(1,session.samples.count-9),session.samples.count do
                local entry = self.provider.HistoryEntry(session.samples,index)
                AddItem("history",string.format("+%.1f s  Lua %s  FPS %s  Latency %s",entry.at,Memory(entry.heap),entry.fps and string.format("%.1f",entry.fps) or "-",entry.latency and tostring(entry.latency) .. " ms" or "-"))
            end
        end
        if self.tab=="All Addons" then
            AddItem("heading","Memory by addon (explicit refresh)")
            AddItem("message","Native-reported addon memory requires client support. Refresh memory is manual; it never starts recording.")
            local entries=state.addonEntries
            if entries then for index=1,table.getn(entries) do AddMetric(entries[index].name,Memory(entries[index].memory)) end end
            if state.addonMemoryTruncated then AddItem("message","Addon memory display is limited to the first 256 inventory entries.") end
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
        for _,label in ipairs({row.label,row.detail}) do label:SetJustifyH("LEFT");if label.SetWordWrap then label:SetWordWrap(true) end end
        table.insert(module.rows,row);return row
    end
    local function MeasureItems(width, top)
        local y, operationIndex = top, 0
        for index=1,module.itemCount do
            local item,row=module.items[index],EnsureRow(index)
            row:ClearAllPoints();row:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-y);row:SetWidth(width)
            row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,-4);row.label:SetWidth(math.max(1,width-16));row.label:SetHeight(0)
            row.label:SetText(item.text);row.label:Show()
            if item.kind=="heading" then row.label:SetTextColor(unpack(UI.Theme.colors.goldText)) else row.label:SetTextColor(1,1,1) end
            row.detail:Hide();for column=1,5 do row.columns[column]:Hide() end
            local height=math.max(22,UI.MeasureTextHeight(row.label,width-16)+8)
            if item.kind=="operation" then
                operationIndex=operationIndex+1
                local operation=item.operation
                if width>=600 then
                    local nameWidth=math.floor((width-16)*0.36);local cellWidth=(width-16-nameWidth)/5
                    row.label:SetWidth(nameWidth);height=math.max(28,UI.MeasureTextHeight(row.label,nameWidth)+8)
                    local values=row.values
                    values[1]=tostring(operation.count);values[2]=Duration(operation.time)
                    values[3]=Duration(operation.count>0 and operation.time/operation.count or 0)
                    values[4]=Duration(operation.maxTime);values[5]=Memory(operation.memory)
                    for column=1,5 do local label=row.columns[column];UI.Table.Cell(label,row,8+nameWidth+(column-1)*cellWidth,cellWidth,height,values[column]);label:Show() end
                else
                    local nameHeight=UI.MeasureTextHeight(row.label,width-16)
                    row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",row,"TOPLEFT",8,-nameHeight-6);row.detail:SetWidth(math.max(1,width-16));row.detail:SetHeight(0)
                    row.detail:SetText(string.format("Calls %d | Total %s | Avg %s | Max %s | Heap %s",operation.count,Duration(operation.time),Duration(operation.count>0 and operation.time/operation.count or 0),Duration(operation.maxTime),Memory(operation.memory)))
                    row.detail:Show();height=nameHeight+UI.MeasureTextHeight(row.detail,width-16)+12
                end
                UI.StyleSelectableTableRow(row,math.mod(operationIndex,2)==0,false)
                row:SetScript("OnEnter",UI.SelectableTableRowEnter);row:SetScript("OnLeave",UI.SelectableTableRowLeave)
            else
                UI.SetRowColor(row,{1,1,1},item.kind=="history" and math.mod(index,2)==0 and 0.10 or 0)
                if row.mosTableRowSelection then row.mosTableRowSelection:Hide();row.mosTableRowHover:Hide();UI.SetProjectButtonOutline(row,false) end
                row:SetScript("OnEnter",nil);row:SetScript("OnLeave",nil)
            end
            row:SetHeight(height);row:Show();y=y+height+(item.kind=="heading" and 6 or 2)
        end
        for index=module.itemCount+1,table.getn(module.rows) do module.rows[index]:Hide() end
        return y+8
    end

    function module:EnsureUI()
        if page.controls then return end
        page.tabs=UI.CreateToolbarSurface(page.canvas,true,true);page.controls=UI.CreateToolbarSurface(page.canvas,false,true)
        page.mosTab=UI.CreateButton(page.tabs,nil,"MOS",90,26);page.allTab=UI.CreateButton(page.tabs,nil,"All Addons",120,26)
        page.enableButton=UI.CreateButton(page.controls,nil,"Enable",88,26)
        page.startButton=UI.CreateButton(page.controls,nil,"Start",82,26);page.stopButton=UI.CreateButton(page.controls,nil,"Stop",82,26)
        page.resetButton=UI.CreateButton(page.controls,nil,"Reset",82,26);page.exportButton=UI.CreateButton(page.controls,nil,"Export",82,26)
        page.monitorButton=UI.CreateButton(page.controls,nil,"Live Monitor",126,26)
        page.memoryButton=UI.CreateButton(page.controls,nil,"Refresh memory",142,26)
        page.tabFlow={page.mosTab,page.allTab};page.flow={page.enableButton,page.startButton,page.stopButton,page.resetButton,page.exportButton,page.monitorButton,page.memoryButton}
        for _,flow in ipairs({page.tabFlow,page.flow}) do for _,button in ipairs(flow) do button.mosFlowWidth=button:GetWidth();UI.StyleActionButton(button) end end
        page.status=UI.CreateLabel(page.canvas,nil,"OVERLAY","GameFontHighlightSmall");page.status:SetJustifyH("LEFT");if page.status.SetWordWrap then page.status:SetWordWrap(true) end
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
    local function MeasurePage(width)
        page.title:ClearAllPoints();page.title:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-8);UI.FitButtonLabel(page.title,width-16)
        if not module.provider then
            page.message:ClearAllPoints();page.message:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-48);page.message:SetWidth(math.max(1,width-16));page.message:SetHeight(0)
            return 56+UI.MeasureTextHeight(page.message,width-16)
        end
        local tabHeight=UI.LayoutFlow(page.tabs,page.tabFlow,8,8,width-16,8)+8
        page.tabs:ClearAllPoints();page.tabs:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",0,-38);page.tabs:SetWidth(width);page.tabs:SetHeight(tabHeight)
        local controlHeight=UI.LayoutFlow(page.controls,page.flow,8,8,width-16,8)+8
        page.controls:ClearAllPoints();page.controls:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",0,-38-tabHeight);page.controls:SetWidth(width);page.controls:SetHeight(controlHeight)
        local top=38+tabHeight+controlHeight+8
        page.status:ClearAllPoints();page.status:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-top);page.status:SetWidth(math.max(1,width-16));page.status:SetHeight(0)
        return MeasureItems(math.max(1,width-16),top+math.max(16,UI.MeasureTextHeight(page.status,width-16))+8)
    end
    function module:Layout()
        local width,height=UI.GetFrameSpan(parent)
        page:SetWidth(math.max(80,width-3));page:SetHeight(math.max(80,height-4.5))
        UI.LayoutResponsiveCanvas(page.canvas,MeasurePage,self)
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
        page.enableButton:SetText(state.enabled and "Disable" or "Enable")
        UI.SetButtonEnabled(page.startButton,state.enabled and not state.recording);UI.SetButtonEnabled(page.stopButton,state.recording)
        UI.SetButtonEnabled(page.resetButton,state.session~=nil);UI.SetButtonEnabled(page.exportButton,state.session~=nil and not state.recording)
        UI.SetButtonEnabled(page.memoryButton,state.enabled and self.tab=="All Addons")
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(page.mosTab,self.tab=="MOS");UI.SetClassicButtonSelected(page.allTab,self.tab=="All Addons") end
        UI.SetProjectButtonOutline(page.mosTab,self.tab=="MOS");UI.SetProjectButtonOutline(page.allTab,self.tab=="All Addons")
        page.status:SetText("BootyProfiler " .. tostring(self.provider.version) .. " | " .. (state.recording and "Recording" or state.enabled and "Ready / stopped" or "Disabled") .. (state.error and "\n" .. state.error or self.notice and "\n" .. self.notice or ""))
        self:Layout()
    end
    local function Updated() module:Refresh() end
    local function Subscribe()
        if module.provider then module.provider.SetListener((page:IsVisible() or module.monitor and module.monitor:IsVisible()) and Updated or nil) end
    end
    function module:SelectTab(tab) self.tab=tab;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end
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
