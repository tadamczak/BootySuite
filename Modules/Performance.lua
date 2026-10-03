local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
MOS.Modules.Performance = MOS.Modules.Performance or {}
local Performance = MOS.Modules.Performance

local function Duration(value) return string.format("%.2f ms", (tonumber(value) or 0) * 1000) end
local function ClockGap(value)
    if type(value)~="number" then return "Not observed" end
    if value>0 and value<0.001 then return string.format("%.2f us",value*1000000) end
    return Duration(value)
end
local function ClockName(value)
    if type(value)~="string" then return "Unavailable" end
    if string.find(value,"debugprofilestop",1,true) then return "debugprofilestop" end
    if string.find(value,"GetTime",1,true) then return "GetTime" end
    return value
end
local function Memory(value)
    if type(value) ~= "number" then return "Unavailable" end
    if math.abs(value) >= 1024 then return string.format("%.2f MB", value / 1024) end
    return string.format("%.1f KB", value)
end
local function CompareTime(a, b) if a.time == b.time then return a.name < b.name end return a.time > b.time end
local function CompareCallbackTime(a,b)
    if (a.selfTime or 0)==(b.selfTime or 0) then
        if a.name==b.name then return (a.script or "")<(b.script or "") end
        return a.name<b.name
    end
    return (a.selfTime or 0)>(b.selfTime or 0)
end
local rowColor = {1,1,1}
local emptyEntries = {}
local tables = {
    operations = { first = "Operation", columns = {"Calls","Total","Average","Peak","Heap delta"}, minimum = 760, nameFraction = 0.34 },
    slow = { first = "Operation", columns = {"At","Duration","Heap delta","Event"}, minimum = 680, nameFraction = 0.34 },
    samples = { first = "At", columns = {"FPS","Lua heap","Latency"}, minimum = 460, nameFraction = 0.18 },
    memory = { first = "Addon", columns = {"Memory"}, minimum = 300, nameFraction = 0.70 },
    callbacks = { first = "Source addon", columns = {"Calls","Self","Inclusive","Peak","Errors"}, minimum = 760, nameFraction = 0.34 },
    callbackDetails = { first = "Frame / script", columns = {"Calls","Self","Inclusive","Peak","Errors"}, minimum = 760, nameFraction = 0.34 },
    callbackSlow = { first = "Frame / script", columns = {"At","Duration","Self","Event","Errors"}, minimum = 760, nameFraction = 0.34 },
    diagnostic = { first = "Detail", columns = {"Value"}, minimum = 440, nameFraction = 0.60 },
}
local hints = {
    calls = "Calls to selected MOS operations; nested calls count once. More calls mean more work, not every addon action.",
    total = "Time spent in selected MOS operations. Larger totals mean more measured work; this is not total addon CPU.",
    peak = "Longest measured call. Large peaks can interrupt a frame; timing includes profiler overhead.",
    average = "Measured time per call. Useful for comparing repeated operations.",
    heap = "Shared Lua memory change, including garbage collection. It cannot identify addon ownership or prove a leak.",
    heapPeak = "Largest shared-memory rise during one call. It is not retained MOS memory.",
    fps = "FPS sampled once per second. A low value shows reduced smoothness; it does not identify the cause.",
    lua = "Lua memory shared by all addons. Drops commonly include garbage collection; no per-addon ownership.",
    latency = "Network response delay. High latency affects responses, separately from FPS.",
    callbacks = "Self: time excluding intercepted children; high totals mean more Lua work.\nInclusive: includes children; do not add to parent time.\nPeak: longest call; large peaks may stall frames.\nCalls: frequency; OnUpdate can run every frame.\nFrame scripts only; not total addon CPU.",
    source = "Unknown: XML script labels omit their addon file, or function metadata is unavailable. Frame context helps inspection; it does not prove addon ownership.",
    slow = "Calls above the slow threshold. Peaks may interrupt a frame; matching FPS samples does not prove causation.",
}
local sections = {
    operations={title="MOS operations",expanded=true,hint=hints.total},
    slow={title="Slow MOS calls",hint=hints.slow},
    callbacks={title="Addon source ranking",hint=hints.source},
    callbackDetails={title="Frame callbacks",expanded=true,hint=hints.callbacks},
    callbackSlow={title="Slow callbacks",hint=hints.slow},
    samples={title="FPS and memory samples",hint="One sample per second; newest ten shown. Use this timeline to locate drops, not infer their cause."},
    memory={title="Memory by addon",hint="Manual native memory capture. This client may expose shared Lua memory only."},
    technical={title="Technical details",hint="Capture coverage, timing reliability and client support."},
    technicalTiming={title="Timing",nested=true,hint="Clocks, measurement precision and invalid readings."},
    technicalCoverage={title="Coverage",nested=true,hint="What was intercepted and how much discovery work ran."},
    technicalSources={title="Source identification",nested=true,hint="Why some callback sources cannot be attributed to addons."},
    technicalHealth={title="Capture health",nested=true,hint="Inspection, inventory and wrapper cleanup failures."},
    technicalSupport={title="Client support",nested=true,hint="Available APIs and extension markers; markers alone do not prove support."},
}
local liveValues={"calls","count","time","selfTime","timedCalls","peak","failures","memory","maxTime","maxMemory"}
local function ShortSource(value)
    value=string.gsub(tostring(value or ""),"[%c]"," ")
    if string.len(value)>160 then value=string.sub(value,1,157).."..." end
    return value
end
local function SourceHint(callbacks,text,category)
    for _,example in ipairs(callbacks and callbacks.sourceExamples or emptyEntries) do
        if example.category==category and example.source then return text.."\nExample: "..ShortSource(example.source) end
    end
    return text
end
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
    local module = { frame = page, tab = "MOS", items = {}, rows = {}, sessionEntries = {}, callbackEntries = {}, callbackDetails = {}, metricFlow = {}, detailsExpanded = {}, sectionState = {}, snapshots = {} }

    local function AddItem(kind, text, data, value, hint)
        module.itemCount = module.itemCount + 1
        local item = module.items[module.itemCount]
        if not item then item = {}; table.insert(module.items, item) end
        item.kind, item.text, item.operation, item.value, item.hint = kind, text, data, value, hint
    end
    local function AddMetric(name, value, hint) AddItem("metric",name,nil,tostring(value),hint) end
    local function AddTable(name) AddItem("tableHeader",tables[name].first,tables[name]) end
    local function AddDiagnostic(name,value,hint) AddItem("diagnostic",name,nil,tostring(value or "Unavailable"),hint) end

    function module:IsSectionExpanded(name)
        if name=="technical" then return self.detailsExpanded[self.tab] and true or false end
        local key=self.tab..":"..name
        if self.sectionState[key]==nil then return sections[name].expanded and true or false end
        return self.sectionState[key]
    end
    local function AddSection(name,count)
        local section=sections[name]
        AddItem("section",section.title,name,count,section.hint)
        return module:IsSectionExpanded(name)
    end
    function module:SnapshotRows(name,entries,session,history)
        if not self.provider.GetState().recording then return entries end
        local key=self.tab..":"..name
        local snapshot=self.snapshots[key]
        if not snapshot then
            snapshot={rows={},byName={},bindings={}}
            self.snapshots[key]=snapshot
            for _,entry in ipairs(entries) do
                local row={}
                for field,value in pairs(entry) do if type(value)~="table" and type(value)~="function" then row[field]=value end end
                table.insert(snapshot.rows,row);table.insert(snapshot.bindings,entry)
                if entry.name then snapshot.byName[entry.name]=row end
            end
        elseif not history then
            local updates=name=="operations" and entries or snapshot.bindings
            for index,entry in ipairs(updates) do
                local row=name=="operations" and snapshot.byName[entry.name] or snapshot.rows[index]
                if row then for _,field in ipairs(liveValues) do row[field]=entry[field] end end
            end
        end
        return snapshot.rows
    end
    local function AddRows(section,kind,entries,session,hint,empty,history,available)
        if not AddSection(section,available or table.getn(entries)) then return end
        local rows=module:SnapshotRows(section,entries,session,history)
        if table.getn(rows)==0 then
            AddItem("message",empty or "No measurements. Refresh tables after recording activity.")
            return
        end
        AddTable(section)
        for _,entry in ipairs(rows) do
            local title=entry.name or string.format("+%.1f s",entry.at)
            local rowHint=hint
            if kind=="callbackDetail" or kind=="callbackSlow" then
                rowHint="Source: "..(entry.owner or "Unknown").."\n"..hint
                if entry.source then rowHint=rowHint.."\n"..ShortSource(entry.source) end
                if entry.frameContext then rowHint=rowHint.."\n"..entry.frameContext end
            end
            AddItem(kind,title,entry,nil,rowHint)
        end
    end
    function module:HistoryRows(history,limit)
        local entries=self.historyEntries or {};self.historyEntries=entries
        for index=table.getn(entries),1,-1 do table.remove(entries,index) end
        for index=history.count,math.max(1,history.count-limit+1),-1 do table.insert(entries,self.provider.HistoryEntry(history,index)) end
        return entries
    end

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

    function module:BuildCallbackItems(callbacks,session)
        local entries,count=self.callbackEntries,0
        local previousCount=table.getn(entries)
        local live=self.provider.GetState().recording and not session.stopped
        local rankSources=not live or self:IsSectionExpanded("callbacks") and not self.snapshots[self.tab..":callbacks"]
        if not rankSources then count=previousCount
        elseif callbacks.addons then
            for _,entry in ipairs(callbacks.addons) do
                if count<256 then
                    count=count+1
                    if count<=previousCount then entries[count]=entry else table.insert(entries,entry) end
                end
            end
        end
        for index=table.getn(entries),count+1,-1 do table.remove(entries,index) end
        if rankSources then table.sort(entries,CompareCallbackTime) end
        local top=self.callbackDetails
        local rankDetails=not live or self:IsSectionExpanded("callbackDetails") and not self.snapshots[self.tab..":callbackDetails"]
        if rankDetails then for index=table.getn(top),1,-1 do table.remove(top,index) end end
        if rankDetails and callbacks.operations then
            -- Keep twenty references without sorting or copying the backend inventory.
            for _,entry in ipairs(callbacks.operations) do
                local size=table.getn(top)
                if size<20 or CompareCallbackTime(entry,top[size]) then
                    local position=math.min(20,size+1)
                    while position>1 and CompareCallbackTime(entry,top[position-1]) do position=position-1 end
                    if size==20 then table.remove(top,20) end
                    table.insert(top,position,entry)
                end
            end
        end
        AddRows("callbackDetails","callbackDetail",top,session,hints.callbacks,"No displayed callbacks. Use Refresh tables after discovery.",false,math.min(20,table.getn(callbacks.operations or emptyEntries)))
        AddRows("callbacks","callback",entries,session,hints.source.."\n"..hints.callbacks,"No identified addon sources yet.",false,table.getn(callbacks.addons or emptyEntries))
        if callbacks.history then
            AddRows("callbackSlow","callbackSlow",self:HistoryRows(callbacks.history,64),session,hints.slow,"No callbacks reached the slow threshold.",true)
        end
    end

    function module:BuildTechnicalItems(session)
        local callbacks=session.callbacks
        if AddSection("technicalTiming") then
            AddTable("diagnostic")
            AddDiagnostic("MOS clock",session.clock,"MOS durations use this clock. Small durations can be rounded by its resolution.")
            AddDiagnostic("Clock precision","Not verified","Observed clock gaps do not prove timer resolution. Times include profiling overhead.")
            AddDiagnostic("Scope","Selected MOS operations",hints.total)
            if self.tab=="All Addons" then
                AddDiagnostic("FPS sampling","1 per second",hints.fps)
                AddDiagnostic("Memory API",session.capabilities and session.capabilities.addonMemory and "Per-addon available" or "Shared Lua only",hints.lua)
                AddDiagnostic("GC threshold",Memory(session.gcThreshold),"Shared Lua collection threshold. It is not an addon memory limit.")
            end
            if callbacks and self.tab=="All Addons" then
                AddDiagnostic("Callback clock",ClockName(callbacks.clock),"Durations are differences between clock reads; no overhead compensation.")
                AddDiagnostic("Smallest observed clock gap",ClockGap(callbacks.clockMinPositiveDelta),"Observed read gap, not verified timer resolution.")
                AddDiagnostic("Zero-duration calls",callbacks.zeroDurations or 0,"Timer granularity may round small calls to zero. Zero does not mean no work.")
                AddDiagnostic("Invalid timings",callbacks.timingFailures or 0,"Calls counted but excluded from duration totals.")
                AddDiagnostic("Clock read failures",callbacks.clockReadFailures or 0,"Failed timing reads reduce measured coverage.")
                AddDiagnostic("Metric failures",callbacks.metricFailures or 0,"Metrics that could not be recorded.")
                AddDiagnostic("Clock baseline",ClockGap(callbacks.overhead),"Clock read baseline only; not full hook overhead.")
            end
        end
        if callbacks and self.tab=="All Addons" then
            if AddSection("technicalCoverage") then
                AddTable("diagnostic")
                AddDiagnostic("Callback frames",callbacks.discovered or 0,"Retained frames with OnEvent or OnUpdate callbacks; not all addon functions.")
                AddDiagnostic(session.stopped and "Hooks at Stop" or "Active hooks",callbacks.activeHookedAtStop or callbacks.hooked or 0,"Only intercepted callbacks contribute to the ranking.")
                AddDiagnostic("Unknown-source hooks",callbacks.unknownAtStop or callbacks.unknown or 0,hints.source)
                AddDiagnostic("Callbacks wrapped",callbacks.everHooked or 0,"Cumulative wrapped callbacks; replacements can increase this count.")
                local discovery=callbacks.available==false and "Unavailable" or callbacks.pending and not session.stopped and "In progress" or callbacks.truncated and "Limit reached" or callbacks.firstScanComplete and "Initial scan complete" or session.stopped and "Stopped before first scan" or "Incomplete"
                AddDiagnostic("Discovery",discovery,"Discovery runs gradually. Work before interception is not measured; coverage remains partial.")
                AddDiagnostic("Completed sweeps",callbacks.scans or 0,"Later sweeps discover new or replaced scripts.")
                AddDiagnostic("Discovery time",Duration(callbacks.discoveryTime),"Profiler work spent discovering scripts. This is separate from callback work.")
                AddDiagnostic("Frame visits",callbacks.scanned or 0,"Repeated sweeps revisit frames; this is not a unique-frame count.")
                AddDiagnostic("Visits without callbacks",callbacks.inertSkipped or 0,"Skipped frames consume inspection time, not callback retention capacity.")
                AddDiagnostic("Script replacements",callbacks.replacements or 0,"Replacements are reconciled on subsequent discovery sweeps.")
                AddDiagnostic("Known scripts skipped",callbacks.skippedKnown or 0,"Known client and profiler sources are excluded from addon rankings.")
            end
            if AddSection("technicalSources") then
                AddTable("diagnostic")
                AddDiagnostic("Source method",callbacks.sourceMethod or "Unavailable",hints.source)
                AddDiagnostic("Debug metadata reads",callbacks.sourceDebug or 0,"Function-source metadata supplied by an exposed debug API.")
                AddDiagnostic("Bytecode source reads",callbacks.sourceDump or 0,"Lua5.0 function-source metadata; dumped bytecode is not executed.")
                AddDiagnostic("Source unavailable",callbacks.sourceUnavailable or 0,"No usable function metadata; attribution remains Unknown.")
                AddDiagnostic("Dump rejected",callbacks.sourceDumpRejected or 0,SourceHint(callbacks,"This client rejects C functions and closures with captured variables; their source is unavailable.","dump-rejected"))
                AddDiagnostic("Unsupported dump",callbacks.sourceUnsupportedDump or 0,SourceHint(callbacks,"Bytecode format or size was unsupported; no source guess is made.","unsupported-dump"))
                AddDiagnostic("Missing source API",callbacks.sourceApiUnavailable or 0,SourceHint(callbacks,"No usable function-source API was exposed.","no-source-api"))
                AddDiagnostic("XML-shaped script labels",callbacks.sourceFrameScripts or 0,SourceHint(callbacks,"Frame:script labels contain no addon file. This cannot establish XML ownership.","frame-script"))
                AddDiagnostic("Other non-file sources",math.max(0,(callbacks.sourceNonFile or 0)-(callbacks.sourceFrameScripts or 0)),SourceHint(callbacks,"Code chunks have no verified addon path; attribution remains Unknown.","code-chunk"))
                AddDiagnostic("Folder not in inventory",callbacks.sourceUnmatchedFolder or 0,SourceHint(callbacks,"Source folder did not match the installed addon inventory.","folder-unmatched"))
                AddDiagnostic("Installed addon folders",callbacks.inventoryCount or 0,"Bounded inventory used to match actual source folders.")
            end
            if AddSection("technicalHealth") then
                AddTable("diagnostic")
                AddDiagnostic("Inventory read failures",callbacks.inventoryReadFailures or 0,"Failed inventory reads can leave source folders unmatched.")
                AddDiagnostic("Inspection failures",callbacks.inspectionFailures or 0,"Frame scripts that could not be inspected.")
                AddDiagnostic("Source failures",callbacks.sourceFailures or 0,"Source reads that failed during discovery.")
                AddDiagnostic("Restore failures",callbacks.restoreFailures or 0,"Wrappers could not be removed. Reload before another external capture.")
                AddDiagnostic("Depth-limit skips",callbacks.depthSkipped or 0,"Deep nested calls beyond the measurement limit were not timed.")
            end
        end
        if AddSection("technicalSupport") then
            AddTable("diagnostic")
            AddDiagnostic("BootyProfiler",self.provider.version)
            local capabilities=session.capabilities or {}
            AddDiagnostic("Runtime",capabilities.lua or "Not identified","A version marker is not proof that a measurement API is available.")
            AddDiagnostic("Lua heap",capabilities.heap and "Available" or "Unavailable",hints.lua)
            AddDiagnostic("ClassicAPI",capabilities.classicAPIVersion or capabilities.classicAPI and "Present" or "Absent","Extension marker only; features are probed independently.")
            AddDiagnostic("SuperAPI",capabilities.superAPI and "Present" or "Absent","Extension marker only; features are probed independently.")
            AddDiagnostic("SuperWoW",capabilities.superwow or "Absent","Extension marker only; features are probed independently.")
            AddDiagnostic("Nampower",capabilities.nampower or "Absent","Extension marker only; features are probed independently.")
        end
    end

    function module:BuildItems()
        self.itemCount=0
        local state=self.provider.GetState()
        local session=state.session
        if self.snapshotSession~=session or self.snapshotRecording~=state.recording then
            self.snapshots={};self.snapshotSession=session;self.snapshotRecording=state.recording
        end
        if state.recording then AddItem("message","Counters live; Refresh tables updates rows and ranking.") end
        if not session or not session.callbacks then
            for index=table.getn(self.callbackEntries),1,-1 do table.remove(self.callbackEntries,index) end
            for index=table.getn(self.callbackDetails),1,-1 do table.remove(self.callbackDetails,index) end
        end
        if not session then
            for index=table.getn(self.sessionEntries),1,-1 do table.remove(self.sessionEntries,index) end
            for index=table.getn(self.historyEntries or emptyEntries),1,-1 do table.remove(self.historyEntries,index) end
            AddItem("message",state.enabled and "Press Start, use the addon, then Stop to inspect results." or "Enable, then Start. Measurements are off until recording.")
        elseif self.tab=="MOS" then
            local calls,total,heap,largest,_,entries,peak=self:GetSessionOperations()
            AddMetric("Measured calls",calls,hints.calls);AddMetric("Measured time",Duration(total),hints.total)
            AddMetric("Peak call time",calls>0 and Duration(peak) or "-",hints.peak);AddMetric("Average call time",calls>0 and Duration(total/calls) or "-",hints.average)
            AddMetric("Heap delta",Memory(heap),hints.heap);AddMetric("Peak heap rise",Memory(largest),hints.heapPeak)
            AddRows("operations","operation",entries,session,hints.total.."\n"..hints.heap,"No displayed MOS calls. Use Refresh tables after activity.")
            AddRows("slow","slow",self:HistoryRows(session.history,64),session,hints.slow.."\n"..hints.heap,"No MOS calls reached 5 ms.",true)
        else
            AddMetric("Sampled FPS",session.fps and string.format("%.1f",session.fps) or "Unavailable",hints.fps)
            AddMetric("Minimum FPS",session.minFps and string.format("%.1f",session.minFps) or "Unavailable",hints.fps)
            AddMetric("Maximum FPS",session.maxFps and string.format("%.1f",session.maxFps) or "Unavailable",hints.fps)
            AddMetric("Lua heap",Memory(session.heap),hints.lua)
            AddMetric("Heap delta since Start",session.heap and session.startHeap and Memory(session.heap-session.startHeap) or "Unavailable",hints.heap)
            AddMetric("Network latency",session.latency and tostring(session.latency).." ms" or "Unavailable",hints.latency)
            if session.callbacks then
                local callbacks=session.callbacks
                AddDiagnostic("Capture",callbacks.available==false and "Callbacks unavailable" or callbacks.pending and "Discovering callbacks" or callbacks.truncated and "Partial: limit reached" or "Frame callbacks only",hints.callbacks)
                AddDiagnostic("Source identification",tostring(callbacks.unknownAtStop or callbacks.unknown or 0).." unknown hooks",hints.source)
                local invalid,zero=callbacks.timingFailures or 0,callbacks.zeroDurations or 0
                AddDiagnostic("Timing quality",invalid>0 and "Invalid readings" or zero>0 and "Rounded to zero" or "No invalid readings","Invalid: "..invalid.."; zero: "..zero..". Invalid readings are excluded; zero can mean timer rounding.")
                self:BuildCallbackItems(callbacks,session)
            else
                AddItem("message","Callbacks were not recorded. Start from All Addons to measure frame scripts.")
            end
            AddRows("samples","sample",self:HistoryRows(session.samples,10),session,hints.fps.."\n"..hints.lua,"No samples yet.",true)
        end
        if self.tab=="All Addons" then
            local entries=state.addonEntries or emptyEntries
            if AddSection("memory",table.getn(entries)) then
                if table.getn(entries)>0 then
                    AddTable("memory")
                    for _,entry in ipairs(entries) do AddItem("memory",entry.name,entry,nil,"Last manual native memory capture; refresh to update.") end
                else
                    AddItem("message",session and session.capabilities and session.capabilities.addonMemory==false and "Unavailable: this client reports shared Lua memory only." or "Use Refresh memory to request native addon statistics.")
                end
            end
        end
        if session and AddSection("technical") then self:BuildTechnicalItems(session) end
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
    local function SectionClick() this.reportModule:ToggleSection(this.reportSection) end
    local function MeasureTableRow(row,item,schema,width,stripe)
        local count=table.getn(schema.columns)
        row.reportSchema=schema
        local values=row.values
        if item.kind=="tableHeader" then for index=1,count do SetValue(row,index,schema.columns[index]) end
        elseif item.kind=="diagnostic" then SetValue(row,1,item.value)
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
        elseif item.kind=="callback" or item.kind=="callbackDetail" then
            local data=item.operation
            local measured=data.timedCalls~=0
            SetValue(row,1,data.calls or 0);SetValue(row,2,measured and Duration(data.selfTime) or "Unavailable");SetValue(row,3,measured and Duration(data.time) or "Unavailable")
            SetValue(row,4,measured and Duration(data.peak) or "Unavailable");SetValue(row,5,data.failures or 0)
        elseif item.kind=="callbackSlow" then
            local data=item.operation
            SetValue(row,1,string.format("+%.1f s",data.at));SetValue(row,2,Duration(data.elapsed));SetValue(row,3,Duration(data.selfTime))
            SetValue(row,4,data.event or "-");SetValue(row,5,data.failed and 1 or 0)
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
                label:SetText(item.kind=="diagnostic" and values[index] or schema.columns[index]..": "..values[index]);label:SetTextColor(0.86,0.86,0.86);label:Show()
                -- Reserve two lines so changing numeric precision does not move following sections.
                bandHeight=math.max(bandHeight,28,UI.MeasureTextHeight(label,cellWidth-8))
            end
            height=height+bandHeight+4
        end
        return height+4
    end
    local function MeasureItems(width, top)
        local y,index,stripe,schema=top,1,0,nil
        for _,toggle in pairs(page.sectionToggles) do toggle:Hide() end
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
                    row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",row,"TOPLEFT",8,-labelHeight-12);row.detail:SetWidth(math.max(1,cardWidth-16))
                    FontSize(row.detail,18);row.detail:SetText(item.value);row.detail:SetTextColor(1,1,1);row.detail:Show()
                    UI.FitButtonLabel(row.detail,math.max(1,cardWidth-16));row.detail:SetHeight(22);row.detail:SetJustifyV("MIDDLE")
                    height=math.max(height,labelHeight+22+20)
                    UI.SetRowColor(row,rowColor,0.045);row.mosFlowWidth=cardWidth;row:Show()
                    count=count+1
                    if count<=table.getn(flow) then flow[count]=row else table.insert(flow,row) end
                    index=index+1
                end
                for tail=table.getn(flow),count+1,-1 do table.remove(flow,tail) end
                for card=1,count do flow[card]:SetHeight(height) end
                y=UI.LayoutFlow(page.canvas,flow,8,y,width,8)+12
            else
                ResetRow(row,item,width);row:ClearAllPoints();row:SetPoint("TOPLEFT",page.canvas,"TOPLEFT",8,-y)
                local height=math.max(22,UI.MeasureTextHeight(row.label,width-16)+12)
                if item.kind=="tableHeader" then schema=item.operation;stripe=0;height=MeasureTableRow(row,item,schema,width,0)
                elseif item.kind=="diagnostic" then stripe=stripe+1;height=MeasureTableRow(row,item,tables.diagnostic,width,stripe)
                elseif item.kind=="operation" or item.kind=="slow" or item.kind=="sample" or item.kind=="memory" or item.kind=="callback" or item.kind=="callbackDetail" or item.kind=="callbackSlow" then
                    stripe=stripe+1;height=MeasureTableRow(row,item,schema,width,stripe)
                elseif item.kind=="heading" then
                    FontSize(row.label,14);row.label:SetTextColor(unpack(UI.Theme.colors.goldText))
                    height=UI.MeasureTextHeight(row.label,width-16)+16
                elseif item.kind=="section" then
                    row.label:Hide();row:EnableMouse(false)
                    local name=item.operation
                    local toggle=page.sectionToggles[name]
                    if not toggle then
                        toggle=UI.Settings.CreateSectionAccordion(page.canvas,item.text,0)
                        toggle.reportModule=module;toggle.reportSection=name;toggle:SetScript("OnClick",SectionClick)
                        UI.SetProjectButtonOutline(toggle,true)
                        UI.AttachTooltip(toggle,item.text,item.hint)
                        page.sectionToggles[name]=toggle
                        if name=="technical" then page.detailsToggle=toggle end
                    end
                    if toggle:GetParent()~=row then toggle:SetParent(row) end
                    local inset=sections[name].nested and 8 or 0
                    toggle:ClearAllPoints();toggle:SetPoint("TOPLEFT",row,"TOPLEFT",inset,0);toggle:SetWidth(math.max(1,width-inset));toggle:SetHeight(28)
                    toggle.label:SetText((module:IsSectionExpanded(name) and "- " or "+ ")..item.text..(item.value~=nil and " ("..item.value..")" or ""))
                    UI.FitButtonLabel(toggle,width-32);toggle.label:SetJustifyH("LEFT")
                    toggle.label:ClearAllPoints();toggle.label:SetPoint("LEFT",toggle,"LEFT",8,0)
                    toggle.rule:Hide();toggle:SetExpanded(module:IsSectionExpanded(name));toggle:Show();height=28
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
        page.refreshButton=UI.CreateButton(page.controls,nil,"Refresh tables",126,26)
        page.memoryButton=UI.CreateButton(page.controls,nil,"Refresh memory",142,26)
        page.tabFlow={page.mosTab,page.allTab};page.actions={page.enableButton,page.startButton,page.stopButton,page.resetButton,page.exportButton,page.monitorButton,page.refreshButton,page.memoryButton};page.flow={}
        for _,flow in ipairs({page.tabFlow,page.actions}) do for _,button in ipairs(flow) do button.mosFlowWidth=button:GetWidth();UI.StyleActionButton(button) end end
        page.status=UI.CreateLabel(page.header,nil,"OVERLAY","GameFontHighlightSmall");page.status:SetJustifyH("LEFT");if page.status.SetWordWrap then page.status:SetWordWrap(true) end
        page.sectionToggles={}
        page.mosTab:SetScript("OnClick",function() module:SelectTab("MOS") end);page.allTab:SetScript("OnClick",function() module:SelectTab("All Addons") end)
        page.enableButton:SetScript("OnClick",function() module.provider.Enable(not module.provider.GetState().enabled);module.notice=nil;module:Refresh() end)
        page.startButton:SetScript("OnClick",function() module:Start() end);page.stopButton:SetScript("OnClick",function() module:Stop() end)
        page.resetButton:SetScript("OnClick",function() module:Reset() end);page.exportButton:SetScript("OnClick",function() module:Export() end)
        page.monitorButton:SetScript("OnClick",function() module:ToggleMonitor() end)
        page.refreshButton:SetScript("OnClick",function() module:RefreshTables() end)
        page.memoryButton:SetScript("OnClick",function() module:RefreshAddons() end)
        UI.AttachTooltip(page.exportButton,"Export session","Stop first. Saves one report; reload or logout writes it to disk.")
        UI.AttachTooltip(page.enableButton,"Enable / Disable","Enable allows capture; Start records. Disable stops it. Reload leaves capture off.")
        UI.AttachTooltip(page.startButton,"Start recording","MOS: selected operations. All Addons: frame callbacks too. More hooks mean more profiler overhead.")
        UI.AttachTooltip(page.refreshButton,"Refresh tables","Update displayed rows and ranking. While recording, row order stays fixed; counters keep updating. Histories update on refresh.")
        UI.AttachTooltip(page.memoryButton,"Memory by addon","Manual native memory capture. Requires a client API; shared heap cannot identify addon memory.")
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
        top=top+math.max(32,UI.MeasureTextHeight(page.status,width-16))+8;page.header:SetHeight(top);return top
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
        local memorySupported=state.session and state.session.capabilities and state.session.capabilities.addonMemory
        local actionCount=self.tab=="All Addons" and memorySupported~=false and 8 or 7
        local previousCount=table.getn(page.flow)
        for index=1,actionCount do
            if index<=previousCount then page.flow[index]=page.actions[index] else table.insert(page.flow,page.actions[index]) end
            page.actions[index]:Show()
        end
        for index=actionCount+1,table.getn(page.actions) do page.actions[index]:Hide() end
        for index=table.getn(page.flow),actionCount+1,-1 do table.remove(page.flow,index) end
        page.enableButton:SetText(state.enabled and "Disable" or "Enable")
        UI.SetButtonEnabled(page.startButton,state.enabled and not state.recording);UI.SetButtonEnabled(page.stopButton,state.recording)
        UI.SetButtonEnabled(page.resetButton,state.session~=nil);UI.SetButtonEnabled(page.exportButton,state.session~=nil and not state.recording)
        UI.SetButtonEnabled(page.refreshButton,state.session~=nil)
        UI.SetButtonEnabled(page.memoryButton,state.enabled and self.tab=="All Addons" and memorySupported~=false)
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(page.mosTab,self.tab=="MOS");UI.SetClassicButtonSelected(page.allTab,self.tab=="All Addons") end
        UI.SetProjectButtonOutline(page.mosTab,self.tab=="MOS");UI.SetProjectButtonOutline(page.allTab,self.tab=="All Addons")
        page.status:SetText((state.recording and "Recording" or state.enabled and "Ready / stopped" or "Disabled") .. (state.session and " | "..Elapsed(state.session.elapsed) or "") .. (state.error and "\n" .. state.error or self.notice and "\n" .. self.notice or ""))
        if state.recording then page.status:SetTextColor(unpack(UI.Theme.colors.goldText)) else page.status:SetTextColor(1,1,1) end
        self:Layout()
    end
    local function Updated() module:Refresh() end
    local function Subscribe()
        if module.provider then module.provider.SetListener((page:IsVisible() or module.monitor and module.monitor:IsVisible()) and Updated or nil) end
    end
    function module:SelectTab(tab) self.tab=tab;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end
    function module:ToggleSection(name)
        if name=="technical" then self.detailsExpanded[self.tab]=not self.detailsExpanded[self.tab]
        else self.sectionState[self.tab..":"..name]=not self:IsSectionExpanded(name) end
        if self:IsSectionExpanded(name) then self.snapshots[self.tab..":"..name]=nil end
        self:Refresh()
    end
    function module:ToggleDetails() self:ToggleSection("technical") end
    function module:RefreshTables() self.snapshots={};self:Refresh() end
    function module:ReleasePresentation()
        self.snapshots={};self.snapshotSession=nil;self.snapshotRecording=nil
        for _,entries in ipairs({self.sessionEntries,self.callbackEntries,self.callbackDetails,self.historyEntries or emptyEntries}) do
            for index=table.getn(entries),1,-1 do table.remove(entries,index) end
        end
        for _,item in ipairs(self.items) do item.operation=nil end
    end
    function module:Start()
        if not self.provider then return false end
        local ok,message=self.provider.Start({callbacks=self.tab=="All Addons"})
        self.notice=message;self:Refresh();return ok
    end
    function module:Stop() if self.provider then self.provider.Stop();self:Refresh() end end
    function module:Reset() if self.provider then self.provider.Reset();self.notice=nil;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end end
    function module:Export()
        local result,message=self.provider.Export()
        self.notice=result and "Report exported; reload or logout writes it to disk." or message
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
        self.provider=provider
        if provider then
            self:EnsureUI();page.message:Hide();page.tabs:Show();page.controls:Show();page.status:Show()
        else
            page.message:SetText(failure);page.message:Show()
            if page.controls then page.tabs:Hide();page.controls:Hide();page.status:Hide() end
            self.itemCount=0;for _,row in ipairs(self.rows) do row:Hide() end
        end
        self.showRefreshPerformed=false;page:Show();Subscribe()
        if provider then if not self.showRefreshPerformed then self:Refresh() end else self:Layout() end
    end
    function module:Hide() self:ReleasePresentation();page:Hide();Subscribe() end
    function module:OnResize() if page:IsVisible() then self:Layout() end end
    page:SetScript("OnShow",function() Subscribe();if module.provider then module.showRefreshPerformed=true;module:Refresh() end end)
    page:SetScript("OnHide",function() module:ReleasePresentation();Subscribe() end)
    module:Layout();return module
end
