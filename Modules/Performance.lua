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
local function SignedMemory(value)
    if type(value)~="number" then return "Unavailable" end
    return (value>0 and "+" or "")..Memory(value)
end
local function FPS(value) return type(value)=="number" and tostring(math.floor(value+0.5)) or "-" end
local function CompareTime(a, b) if a.time == b.time then return a.name < b.name end return a.time > b.time end
local function CompareCallbackTime(a,b)
    if (a.selfTime or 0)==(b.selfTime or 0) then
        if a.name==b.name then return (a.script or "")<(b.script or "") end
        return a.name<b.name
    end
    return (a.selfTime or 0)>(b.selfTime or 0)
end
local function CompareHeapRise(a,b)
    if (a.heapRise or 0)==(b.heapRise or 0) then return a.name<b.name end
    return (a.heapRise or 0)>(b.heapRise or 0)
end
local rowColor = {1,1,1}
local emptyEntries = {}
local FAMILY_PAGE_SIZE=50
local tables = {
    operations = { first = "Operation", columns = {"Calls","Total","Average","Peak","Heap delta"}, minimum = 760, nameFraction = 0.34 },
    slow = { first = "Operation", columns = {"At","Duration","Heap delta","Event"}, minimum = 680, nameFraction = 0.34 },
    samples = { first = "At", columns = {"FPS","Lua heap","Latency"}, minimum = 460, nameFraction = 0.18 },
    memory = { first = "Addon", columns = {"Memory"}, minimum = 300, nameFraction = 0.70 },
    memoryActivity = { first = "Source addon", columns = {"Calls","Heap growth","Net heap delta","Peak growth"}, minimum = 680, nameFraction = 0.34 },
    callbackMemory = { first = "Frame family / script", columns = {"Calls","Heap growth","Net heap delta","Peak growth","Errors"}, minimum = 760, nameFraction = 0.34 },
    loginMemory = { first = "Stage / addon", columns = {"At","Lua heap","Net heap delta","Window"}, minimum = 680, nameFraction = 0.34 },
    callbacks = { first = "Source addon", columns = {"Calls","Self","Inclusive","Peak","Errors"}, minimum = 760, nameFraction = 0.34 },
    callbackDetails = { first = "Frame family / script", columns = {"Calls","Self","Inclusive","Peak","Errors"}, minimum = 760, nameFraction = 0.34 },
    callbackSlow = { first = "Frame / script", columns = {"At","Duration","Self","Event","Errors"}, minimum = 760, nameFraction = 0.34 },
    diagnostic = { first = "Detail", columns = {"Value"}, minimum = 440, nameFraction = 0.60 },
    heapDrops = { first = "At", columns = {"Net decrease","Window","Worst frame gap","Slow frames"}, minimum = 680, nameFraction = 0.18 },
    frameGaps = { first = "At", columns = {"Frame gap"}, minimum = 360, nameFraction = 0.35 },
}
local columnHints={
    Calls="Number of recorded calls. High frequency means more repeated processing.",
    Total="Total measured duration of this operation, including profiler overhead.",
    Average="Measured duration divided by recorded calls. Compare repeated operations with this value.",
    Self="Measured duration excluding nested intercepted callbacks. Use this to compare callback work.",
    Inclusive="Measured duration including nested callbacks. Parent and child totals overlap.",
    Peak="Longest measured call. A large value can interrupt a frame.",
    Errors="Original callbacks that raised a caught Lua error.",
    ["Heap delta"]="Net shared Lua memory change during measured calls. Collection can make this negative.",
    At="Seconds since recording started. Compare timestamps across tables.",
    Duration="Measured call duration, including profiler overhead.",
    Event="Client event handled by this call. A dash means no event.",
    FPS="FPS sampled once per second; brief stalls can be missed.",
    ["Lua heap"]="Lua memory shared by the UI and addons. This excludes total game process memory.",
    Latency="Network response delay in milliseconds; it is separate from rendering speed.",
    Memory="Last manual native memory measurement attributed by the client to this addon.",
    ["Heap growth"]="Sum of positive shared Lua heap changes during measured calls. Use this to find growing callbacks; nested calls can overlap.",
    ["Net heap delta"]="Signed shared Lua memory change. Negative values include collection; this is not memory owned by the addon.",
    ["Peak growth"]="Largest observed positive heap change in one call. This is not retained memory.",
    ["Net decrease"]="Net Lua memory fall between samples. GC can contribute; this is not a confirmed collection event.",
    Window="Elapsed time between the two valid memory readings.",
    ["Worst frame gap"]="Largest OnUpdate elapsed value in this memory window. Compare with heap decreases; this does not prove GC caused the stall.",
    ["Slow frames"]="Observed frame gaps of at least 50 ms in this memory window.",
    ["Frame gap"]="OnUpdate elapsed time between frames. At least 50 ms is retained here; this is not addon CPU time.",
    Detail="Diagnostic being checked. Hover its label for its purpose and effect.",
    Value="Observed diagnostic result for this recording.",
}
local firstHints={
    operations="Selected MOS operation being measured.",slow="Selected MOS operation that reached the slow-call threshold.",
    callbacks="Addon folder recovered from a function source. Missing file metadata is grouped as Unknown owner.",
    callbackDetails="Observed frame family, not an addon owner. Expand to inspect its scripts; family totals include all captured members.",
    callbackSlow="Frame script that reached the slow-call threshold.",memory="Addon named by the native memory API.",
    memoryActivity="Source addon of measured callbacks. Growth is observed during calls, rather than current owned RAM.",
    callbackMemory="Frame family grouped by observed context. Expand to locate memory growth in individual scripts.",
    loginMemory="Observed loading stage or addon-loaded event. A window includes loader and event-handler work; it is not exclusive addon memory.",
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
    source = "Source files identify addons when available. XML labels and missing metadata can prevent attribution; frame families remain inspectable.",
    slow = "Calls above the slow threshold. Peaks may interrupt a frame; matching FPS samples does not prove causation.",
}
local sections = {
    operations={title="MOS operations",expanded=true,hint=hints.total},
    slow={title="Slow MOS calls",hint=hints.slow},
    callbacks={title="Addon source ranking",hint=hints.source},
    callbackDetails={title="Frame callbacks",expanded=true,hint="Grouped by observed frame naming or parent context. Families are not addon owners."},
    callbackSlow={title="Slow callbacks",hint=hints.slow},
    samples={title="FPS and memory samples",hint="One sample per second; newest ten shown. Use this timeline to locate drops, not infer their cause."},
    memory={title="Memory by addon",hint="Callback memory growth works without native addon counters. Native snapshots are shown separately when available."},
    loginMemory={title="Login memory analysis",hint="One requested login capture: loading windows and the first five seconds in the world. Earlier addons belong to its baseline."},
    technical={title="Technical details",hint="Capture coverage, timing reliability and client support."},
    technicalTiming={title="Timing",nested=true,hint="Clocks, measurement precision and invalid readings."},
    technicalCoverage={title="Coverage",nested=true,hint="What was intercepted and how much discovery work ran."},
    technicalSources={title="Source identification",nested=true,hint="Why some callback sources cannot be attributed to addons."},
    technicalHealth={title="Capture health",nested=true,hint="Inspection, inventory and wrapper cleanup failures."},
    technicalSupport={title="Client support",nested=true,hint="Available APIs and extension markers; markers alone do not prove support."},
    memoryGC={title="Memory and garbage collection",expanded=true,hint="Shared Lua memory, observed decreases and frame gaps. Decreases do not establish exact GC count or duration."},
    heapDrops={title="Heap drop windows",hint="Compare net memory decreases with slow frames in the same sampling window."},
    frameGaps={title="Slow frame gaps",hint="Frames taking at least 50 ms. This includes game and observer work, not just addon execution."},
}
local liveValues={"calls","count","time","selfTime","timedCalls","peak","failures","memory","maxTime","maxMemory","heapSamples","heapRise","heapDelta","heapPeak"}
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
    return this.reportHint or ""
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
    local module = { frame = page, tab = "MOS", items = {}, rows = {}, sessionEntries = {}, callbackEntries = {}, callbackDetails = {}, memoryEntries = {}, metricFlow = {}, detailsExpanded = {}, sectionState = {}, snapshots = {}, familyPages = {}, familyPage = 1, callbackView = "time", measureMemory = false, loginPage = 1, loginPaging = {} }

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
            AddItem(kind,title,entry)
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

    function module:CancelFamilyJob()
        page:SetScript("OnUpdate",nil)
        self.familyJob=nil;self.familyPending=nil
    end
    local function FamilyTick()
        local job=module.familyJob
        if not job then page:SetScript("OnUpdate",nil);return end
        if not page:IsVisible() or module.tab~="All Addons" or not module:IsSectionExpanded("callbackDetails") then
            module:CancelFamilyJob();return
        end
        local api=module.provider.CallbackFamilies
        local complete
        if job.phase=="sync" then
            if api.Sync(job.model,128) then api.BeginUpdate(job.model);job.phase="update" end
        elseif job.phase=="update" then
            if api.UpdateStep(job.model,128) then
                if job.build then api.BeginSort(job.model);job.phase="sort" else complete=true end
            end
        elseif job.phase=="sort" then complete=api.SortStep(job.model,1024) end
        if complete then
            local model=job.model
            module:CancelFamilyJob();module.familyModel=model
            module.familyUpdateReady=true;module:Refresh();module.familyUpdateReady=nil
        end
    end
    function module:QueueFamilyJob(model,phase,build)
        self.familyJob={model=model,phase=phase,build=build}
        if build then self.familyPending=model end
        page:SetScript("OnUpdate",FamilyTick)
    end
    function module:BuildFrameFamilies(callbacks,live)
        for index=table.getn(self.callbackDetails),1,-1 do table.remove(self.callbackDetails,index) end
        local api=self.provider.CallbackFamilies
        if not api then AddItem("message","Update BootyProfiler to view frame families.");return end
        local model=self.familyModel
        if not model then
            if not self.familyPending then
                model=api.Create(callbacks.operations,self.callbackView=="memory" and "heapRise" or nil)
                if model.total<=128 then api.Sync(model,128);api.Update(model);api.Sort(model);self.familyModel=model
                else self:QueueFamilyJob(model,"sync",true) end
            end
            model=self.familyModel
        elseif live and not self.familyJob and not self.familyUpdateReady then
            if model.total<=128 then api.Update(model)
            else api.BeginUpdate(model);self:QueueFamilyJob(model,"update",false) end
        end
        if not model then AddItem("message","Preparing frame families...");return end
        local total=table.getn(model.families)
        if total==0 then AddItem("message","No frame callbacks captured.");return end
        AddTable(self.callbackView=="memory" and "callbackMemory" or "callbackDetails")
        self.familyPage=math.max(1,math.min(self.familyPage,math.ceil(total/FAMILY_PAGE_SIZE)))
        local first=(self.familyPage-1)*FAMILY_PAGE_SIZE+1
        if total>FAMILY_PAGE_SIZE then AddItem("familyPager",string.format("Families %d-%d / %d",first,math.min(total,first+FAMILY_PAGE_SIZE-1),total),model) end
        for index=first,math.min(total,first+FAMILY_PAGE_SIZE-1) do
            local family=model.families[index]
            local expanded=self.expandedFamily==family.name
            AddItem("family",(expanded and "- " or "+ ")..family.name.." ("..family.count..")",family,family.name)
            if expanded then
                local childPage=math.max(1,math.min(self.familyPages[family.name] or 1,math.ceil(family.count/FAMILY_PAGE_SIZE)))
                self.familyPages[family.name]=childPage
                local childFirst=(childPage-1)*FAMILY_PAGE_SIZE+1
                if family.count>FAMILY_PAGE_SIZE then AddItem("familyPager",string.format("Scripts %d-%d / %d",childFirst,math.min(family.count,childFirst+FAMILY_PAGE_SIZE-1),family.count),model,family.name) end
                for child=childFirst,math.min(family.count,childFirst+FAMILY_PAGE_SIZE-1) do
                    local entry=family.children[child]
                    table.insert(self.callbackDetails,entry);AddItem("callbackDetail",entry.name,entry)
                end
            end
        end
    end
    function module:ToggleFamily(name)
        self.expandedFamily=self.expandedFamily~=name and name or nil;self:Refresh()
    end
    function module:SetFamilyPage(name,direction)
        if name then self.familyPages[name]=math.max(1,(self.familyPages[name] or 1)+direction)
        else self.familyPage=math.max(1,self.familyPage+direction) end
        self:Refresh()
    end
    function module:BuildCallbackItems(callbacks,session)
        for index=table.getn(self.callbackDetails),1,-1 do table.remove(self.callbackDetails,index) end
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
        if AddSection("callbackDetails",table.getn(callbacks.operations or emptyEntries)) then self:BuildFrameFamilies(callbacks,live) end
        AddRows("callbacks","callback",entries,session,hints.source.."\n"..hints.callbacks,"No identified addon sources yet.",false,table.getn(callbacks.addons or emptyEntries))
        if callbacks.history then
            AddRows("callbackSlow","callbackSlow",self:HistoryRows(callbacks.history,64),session,hints.slow,"No callbacks reached the slow threshold.",true)
        end
    end

    local function AddMemoryHistory(section,kind,history,session,empty)
        if module:IsSectionExpanded(section) then
            AddRows(section,kind,module:HistoryRows(history,64),session,nil,empty,true)
        else AddSection(section,history.count or 0) end
    end
    function module:BuildMemoryItems(session)
        local gc,gaps=session.gc or {},session.frameGaps or {}
        if AddSection("memoryGC") then
            AddMetric("Shared Lua memory",Memory(session.heap),columnHints["Lua heap"])
            AddMetric("Change since Start",session.heap and session.startHeap and SignedMemory(session.heap-session.startHeap) or "Unavailable","Current shared Lua memory minus the first sample. A negative value includes memory reclaimed between samples.")
            AddMetric("GC threshold",Memory(session.gcThreshold),"Lua's reported collection threshold. This is not the amount reclaimed or a per-addon memory limit.")
            AddMetric("Observed heap drops",gc.heapDropCount or 0,"Memory samples with a net decrease. This can miss or combine collections; it is not an exact GC counter.")
            AddMetric("Last heap drop",gc.lastHeapDrop and Memory(gc.lastHeapDrop) or "-","Net decrease during the last observed window. Open Heap drop windows to compare its worst frame gap.")
            AddMetric("Worst frame gap",gaps.maximum and Duration(gaps.maximum) or "-",columnHints["Frame gap"])
            if gc.history then AddMemoryHistory("heapDrops","heapDrop",gc.history,session,"No net memory decreases observed.") end
            if gaps.history then AddMemoryHistory("frameGaps","frameGap",gaps.history,session,"No frame gaps reached 50 ms.") end
        end
    end

    function module:BuildAddonMemoryItems(session,state)
        local callbacks=session and session.callbacks
        local native=state.addonEntries or emptyEntries
        local activity=callbacks and callbacks.memoryRequested and callbacks.memoryAvailable
        local available=activity and table.getn(callbacks.addons or emptyEntries) or table.getn(native)
        if not AddSection("memory",available) then return end
        if activity then
            local entries=self.memoryEntries
            local frozen=state.recording and self.snapshots[self.tab..":memoryActivity"]
            if not frozen then
                for index=table.getn(entries),1,-1 do table.remove(entries,index) end
                for index=1,math.min(256,table.getn(callbacks.addons or emptyEntries)) do table.insert(entries,callbacks.addons[index]) end
                table.sort(entries,CompareHeapRise)
            end
            local rows=self:SnapshotRows("memoryActivity",entries,session,false)
            if table.getn(rows)>0 then
                AddTable("memoryActivity")
                for _,entry in ipairs(rows) do AddItem("memoryActivity",entry.name,entry) end
            else AddItem("message","No callback memory samples yet. Use Refresh tables after activity.") end
        else
            AddItem("message",callbacks and callbacks.memoryRequested and "This capture could not read callback memory." or "Memory: ON, then Start in All Addons to measure callback memory growth.")
        end
        if table.getn(native)>0 then
            AddItem("heading","Client memory snapshot")
            AddTable("memory")
            for _,entry in ipairs(native) do AddItem("memory",entry.name,entry) end
        end
    end

    local loginStages={BASELINE="Profiler loaded",VARIABLES_LOADED="Saved variables ready",PLAYER_LOGIN="Player login",PLAYER_ENTERING_WORLD="Entered world",SETTLE_SAMPLE="After entering world"}
    local loginReasons={ ["logout-before-settle"]="Logged out before completion",["user-cancelled"]="Cancelled by user",["capture-driver-hidden"]="Capture interrupted",["clock-or-heap-api-unavailable"]="Clock or memory API unavailable",["clock-unavailable-or-invalid"]="Invalid client clock",["heap-unavailable-or-invalid"]="Invalid memory reading",["invalid-frame-elapsed"]="Invalid frame interval" }
    function module:BuildLoginItems()
        local capture=self.provider.LoginMemory
        if not capture then return end
        local report=capture.GetReport()
        local count=report and table.getn(report.events or emptyEntries) or 0
        if not AddSection("loginMemory",count) then return end
        if not report then AddItem("message",capture.IsArmed() and "Capture armed for the next login or reload." or "Analyze next login records loading and the first five seconds in the world.");return end
        if self.loginReport~=report then self.loginReport=report;self.loginPage=1 end
        AddMetric("At profiler load",Memory(report.startHeap),columnHints["Lua heap"])
        AddMetric("Latest login memory",Memory(report.heap),columnHints["Lua heap"])
        AddMetric("Change during login",SignedMemory(report.heapDelta),"Latest login sample minus the profiler-load baseline. Includes startup work and collection.")
        AddMetric("Observed login heap drops",report.heapDropCount or 0,"Loading windows with a net memory decrease. Collection may contribute; this is not an exact GC event count.")
        AddDiagnostic("Login capture",report.kind or capture.GetStatus(),"One requested loading capture. It ends after the first five seconds in the world.")
        if report.kind~="completed" and report.reason then AddDiagnostic("Capture stopped",loginReasons[report.reason] or report.reason,"An interrupted report includes only the stages observed before capture stopped.") end
        if report.truncated then AddDiagnostic("Omitted records",report.omittedRecords or 0,"The report keeps at most 256 stage rows. Summary memory continues to update after the table fills.") end
        AddItem("message","Starts at BootyProfiler load; earlier addons are included in the baseline.")
        if count==0 then return end
        self.loginPage=math.max(1,math.min(self.loginPage,math.ceil(count/FAMILY_PAGE_SIZE)))
        local first=(self.loginPage-1)*FAMILY_PAGE_SIZE+1
        self.loginPaging.total=count
        if count>FAMILY_PAGE_SIZE then AddItem("loginPager",string.format("Stages %d-%d / %d",first,math.min(count,first+FAMILY_PAGE_SIZE-1),count),self.loginPaging) end
        AddTable("loginMemory")
        for index=first,math.min(count,first+FAMILY_PAGE_SIZE-1) do
            local entry=report.events[index]
            AddItem("loginMemory",entry.event=="ADDON_LOADED" and entry.addon and "Loaded: "..entry.addon or loginStages[entry.event] or entry.event,entry)
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
                AddDiagnostic("Callback memory",callbacks.memoryRequested and (callbacks.memoryAvailable and "Measured" or "Unavailable") or "Off","Optional before/after heap readings identify growth during callbacks. Nested readings overlap; these are not owned RAM.")
                AddDiagnostic("Memory read failures",callbacks.heapReadFailures or 0,"Invalid heap readings are omitted from memory totals; callback execution and time measurement continue.")
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
                local debugReads,dumpReads=callbacks.sourceDebug or 0,callbacks.sourceDump or 0
                local lookup=debugReads>0 and (dumpReads>0 and "Debug + bytecode" or "Debug metadata") or dumpReads>0 and "Lua 5.0 bytecode" or "None succeeded"
                AddDiagnostic("Source lookup",lookup,"Methods that recovered function labels. A recovered addon filename allows work to be assigned to its source addon.")
                AddDiagnostic("Debug metadata reads",debugReads,"Functions whose source label was read through a debug API. File labels improve addon attribution.")
                AddDiagnostic("Bytecode source reads",dumpReads,"Functions whose source label was recovered from Lua bytecode. Only labels with an addon filename identify a source addon.")
                AddDiagnostic("Source unavailable",callbacks.sourceUnavailable or 0,"Functions without readable source metadata. Their execution still appears in frame families.")
                AddDiagnostic("Dump rejected",callbacks.sourceDumpRejected or 0,SourceHint(callbacks,"The client refused this function dump. Its source cannot be read this way; frame timing remains available.","dump-rejected"))
                AddDiagnostic("Unsupported dump",callbacks.sourceUnsupportedDump or 0,SourceHint(callbacks,"Bytecode format or size was unsupported; no source guess is made.","unsupported-dump"))
                AddDiagnostic("Missing source API",callbacks.sourceApiUnavailable or 0,SourceHint(callbacks,"No usable function-source API was exposed.","no-source-api"))
                AddDiagnostic("XML-shaped script labels",callbacks.sourceFrameScripts or 0,SourceHint(callbacks,"Frame:script labels contain no addon file. This cannot establish XML ownership.","frame-script"))
                AddDiagnostic("Other non-file sources",math.max(0,(callbacks.sourceNonFile or 0)-(callbacks.sourceFrameScripts or 0)),SourceHint(callbacks,"Code labels lack a verified addon path. These functions contribute to frame families but cannot be assigned to a source addon.","code-chunk"))
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
            self:CancelFamilyJob();self.familyModel=nil
            for index=table.getn(self.memoryEntries),1,-1 do table.remove(self.memoryEntries,index) end
        end
        if not session or not session.callbacks then
            self:CancelFamilyJob();self.familyModel=nil
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
            self:BuildMemoryItems(session)
            AddRows("operations","operation",entries,session,hints.total.."\n"..hints.heap,"No displayed MOS calls. Use Refresh tables after activity.")
            AddRows("slow","slow",self:HistoryRows(session.history,64),session,hints.slow.."\n"..hints.heap,"No MOS calls reached 5 ms.",true)
        else
            AddMetric("Sampled FPS",session.fps and string.format("%.1f",session.fps) or "Unavailable",hints.fps)
            AddMetric("Minimum FPS",session.minFps and string.format("%.1f",session.minFps) or "Unavailable",hints.fps)
            AddMetric("Network latency",session.latency and tostring(session.latency).." ms" or "Unavailable",hints.latency)
            self:BuildMemoryItems(session)
            if session.callbacks then
                local callbacks=session.callbacks
                self:BuildCallbackItems(callbacks,session)
            else
                AddItem("message","Callbacks were not recorded. Start from All Addons to measure frame scripts.")
            end
            AddRows("samples","sample",self:HistoryRows(session.samples,10),session,hints.fps.."\n"..hints.lua,"No samples yet.",true)
        end
        if self.tab=="All Addons" then
            self:BuildAddonMemoryItems(session,state)
        end
        self:BuildLoginItems()
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
        local hoverEnter=row:GetScript("OnEnter")
        UI.AttachTooltip(row,TooltipTitle,TooltipBody)
        local tooltipEnter=row:GetScript("OnEnter")
        row:SetScript("OnEnter",function() if this.reportHint then tooltipEnter() elseif hoverEnter then hoverEnter() end end)
        table.insert(module.rows,row);return row
    end
    local function ResetRow(row,item,width)
        row:SetWidth(width);row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,-6)
        row.label:SetWidth(math.max(1,width-16));row.label:SetHeight(0);FontSize(row.label,12);row.label:SetJustifyV("TOP")
        row.label:SetText(item.text);row.label:SetTextColor(1,1,1);row.label:Show()
        row.detail:Hide();for column=1,5 do row.columns[column]:Hide() end
        if row.headerHits then for _,hit in ipairs(row.headerHits) do hit:Hide() end end
        if row.previous then row.previous:Hide();row.next:Hide() end
        row:SetScript("OnClick",nil);row.familyName=nil
        row.reportTitle,row.reportHint,row.reportSchema=item.text,item.hint,nil
        if row.label.SetNonSpaceWrap then row.label:SetNonSpaceWrap(true) end
        row:EnableMouse(item.hint~=nil)
        UI.SetRowColor(row,rowColor,0);row.mosTableRowSelection:Hide();row.mosTableRowHover:Hide();UI.SetProjectButtonOutline(row,false)
    end
    local function SetValue(row,index,value) row.values[index]=tostring(value) end
    local function SectionClick() this.reportModule:ToggleSection(this.reportSection) end
    local function ColumnTitle() return this.columnTitle end
    local function ColumnHint() return this.columnHint end
    local function HeaderHit(row,index,label,title,hint,width,height)
        row.headerHits=row.headerHits or {}
        while table.getn(row.headerHits)<index do
            local created=UI.CreateControl(nil,row);UI.AttachTooltip(created,ColumnTitle,ColumnHint);table.insert(row.headerHits,created)
        end
        local hit=row.headerHits[index]
        hit.columnTitle,hit.columnHint=title,hint
        hit:ClearAllPoints();hit:SetPoint("TOPLEFT",label,"TOPLEFT",0,0);hit:SetWidth(math.max(1,width));hit:SetHeight(math.max(1,height));hit:EnableMouse(true);hit:Show()
    end
    local function FirstHint(schema)
        for name,entry in pairs(tables) do if entry==schema then return firstHints[name] or columnHints[schema.first] or columnHints.Detail end end
    end
    local function FamilyClick() this.reportModule:ToggleFamily(this.familyName) end
    local function PagerClick()
        if this.pagerLogin then this.reportModule:SetLoginPage(this.direction)
        else this.reportModule:SetFamilyPage(this.pagerFamily,this.direction) end
    end
    local function MeasurePager(row,item,width)
        if not row.previous then
            row.previous=UI.CreateButton(row,nil,"Previous",74,24);row.next=UI.CreateButton(row,nil,"Next",56,24)
            row.pagerFlow={row.previous,row.next}
            row.previous.mosFlowWidth=74;row.next.mosFlowWidth=56
            row.previous.mosFlowFitLabel=true;row.next.mosFlowFitLabel=true
            row.previous.direction=-1;row.next.direction=1
            row.previous:SetScript("OnClick",PagerClick);row.next:SetScript("OnClick",PagerClick)
        end
        local model=item.operation
        local login=item.kind=="loginPager"
        local total=login and model.total or item.value and model.familyMap[item.value].count or table.getn(model.families)
        local current=login and module.loginPage or item.value and module.familyPages[item.value] or module.familyPage
        for _,button in ipairs(row.pagerFlow) do button.reportModule=module;button.pagerFamily=item.value;button.pagerLogin=login;button:Show() end
        UI.SetButtonEnabled(row.previous,current>1);UI.SetButtonEnabled(row.next,current<math.ceil(total/FAMILY_PAGE_SIZE))
        local labelHeight=UI.MeasureTextHeight(row.label,width-16)
        return UI.LayoutFlow(row,row.pagerFlow,8,labelHeight+10,math.max(1,width-16),4)+4
    end
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
        elseif item.kind=="heapDrop" then
            local data=item.operation
            SetValue(row,1,Memory(data.heapDrop));SetValue(row,2,string.format("%.2f s",data.windowDuration));SetValue(row,3,Duration(data.maxFrameGap));SetValue(row,4,data.slowFrames or 0)
        elseif item.kind=="frameGap" then SetValue(row,1,Duration(item.operation.elapsed))
        elseif item.kind=="loginMemory" then
            local data=item.operation
            SetValue(row,1,data.at and string.format("+%.1f s",data.at) or "-");SetValue(row,2,Memory(data.heap))
            SetValue(row,3,SignedMemory(data.delta));SetValue(row,4,data.windowElapsed and string.format("%.2f s",data.windowElapsed) or "-")
        elseif item.kind=="memoryActivity" or schema==tables.callbackMemory then
            local data=item.operation
            local measured=(data.heapSamples or 0)>0
            SetValue(row,1,data.calls or 0);SetValue(row,2,measured and Memory(data.heapRise) or "-")
            SetValue(row,3,measured and SignedMemory(data.heapDelta) or "-");SetValue(row,4,measured and Memory(data.heapPeak) or "-")
            if schema==tables.callbackMemory then SetValue(row,5,data.failures or 0) end
        elseif item.kind=="callback" or item.kind=="callbackDetail" or item.kind=="family" then
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
            row.reportHint=item.hint
            if item.kind=="family" then
                UI.SetRowColor(row,rowColor,0.16);UI.SetProjectButtonOutline(row,true)
                row.familyName=item.value;row.reportModule=module;row:SetScript("OnClick",FamilyClick)
                row.label:SetTextColor(unpack(UI.Theme.colors.goldText))
            end
        end
        if width>=schema.minimum then
            local nameWidth=math.floor((width-16)*schema.nameFraction)
            local cellWidth=(width-16-nameWidth)/count
            row.label:SetWidth(nameWidth-8)
            local height=math.max(28,UI.MeasureTextHeight(row.label,nameWidth-8)+12)
            row.label:SetHeight(height);row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",8,0);row.label:SetJustifyV("MIDDLE")
            if item.kind=="callbackDetail" then row.label:SetPoint("TOPLEFT",row,"TOPLEFT",16,0);row.label:SetWidth(math.max(1,nameWidth-16)) end
            for index=1,count do
                local label=row.columns[index];FontSize(label,12)
                UI.Table.Cell(label,row,8+nameWidth+(index-1)*cellWidth,cellWidth-8,height,values[index]);label:SetJustifyH("RIGHT")
                if item.kind=="tableHeader" then label:SetTextColor(unpack(UI.Theme.colors.goldText)) else label:SetTextColor(1,1,1) end
                label:Show()
                if item.kind=="tableHeader" then HeaderHit(row,index+1,label,schema.columns[index],columnHints[schema.columns[index]],cellWidth-8,height) end
            end
            if item.kind=="tableHeader" then row.label:SetTextColor(unpack(UI.Theme.colors.goldText));row:EnableMouse(false);HeaderHit(row,1,row.label,schema.first,FirstHint(schema),nameWidth-8,height) end
            return height
        end
        local height=UI.MeasureTextHeight(row.label,width-16)+10
        if item.kind=="tableHeader" then
            row.label:SetTextColor(unpack(UI.Theme.colors.goldText));row:EnableMouse(false)
            HeaderHit(row,1,row.label,schema.first,FirstHint(schema),width-16,height-10)
        end
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
                label:SetText((item.kind=="diagnostic" or item.kind=="tableHeader") and values[index] or schema.columns[index]..": "..values[index]);label:SetTextColor(0.86,0.86,0.86);label:Show()
                -- Reserve two lines so changing numeric precision does not move following sections.
                bandHeight=math.max(bandHeight,28,UI.MeasureTextHeight(label,cellWidth-8))
                if item.kind=="tableHeader" then
                    label:SetTextColor(unpack(UI.Theme.colors.goldText));HeaderHit(row,index+1,label,schema.columns[index],columnHints[schema.columns[index]],cellWidth-8,bandHeight)
                end
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
                elseif item.kind=="operation" or item.kind=="slow" or item.kind=="sample" or item.kind=="memory" or item.kind=="memoryActivity" or item.kind=="loginMemory" or item.kind=="callback" or item.kind=="callbackDetail" or item.kind=="callbackSlow" or item.kind=="family" or item.kind=="heapDrop" or item.kind=="frameGap" then
                    stripe=stripe+1;height=MeasureTableRow(row,item,schema,width,stripe)
                elseif item.kind=="familyPager" or item.kind=="loginPager" then height=MeasurePager(row,item,width)
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
        page.memoryModeButton=UI.CreateButton(page.controls,nil,"Memory: OFF",116,26)
        page.callbackViewButton=UI.CreateButton(page.controls,nil,"View: Time",120,26)
        page.loginButton=UI.CreateButton(page.controls,nil,"Analyze next login",166,26)
        page.tabFlow={page.mosTab,page.allTab};page.actions={page.enableButton,page.startButton,page.stopButton,page.resetButton,page.exportButton,page.monitorButton,page.refreshButton,page.loginButton,page.memoryModeButton,page.callbackViewButton,page.memoryButton};page.flow={}
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
        page.memoryModeButton:SetScript("OnClick",function() module:ToggleMemoryCapture() end)
        page.callbackViewButton:SetScript("OnClick",function() module:ToggleCallbackView() end)
        page.loginButton:SetScript("OnClick",function() module:ToggleLoginCapture() end)
        UI.AttachTooltip(page.exportButton,"Export session","Stop first. Saves one report; reload or logout writes it to disk.")
        UI.AttachTooltip(page.enableButton,"Enable / Disable","Enable allows capture; Start records. Disable stops it. Reload leaves capture off.")
        UI.AttachTooltip(page.startButton,"Start recording","MOS: selected operations. All Addons: frame callbacks too. More hooks mean more profiler overhead.")
        UI.AttachTooltip(page.refreshButton,"Refresh tables","Update displayed rows and ranking. While recording, row order stays fixed; counters keep updating. Histories update on refresh.")
        UI.AttachTooltip(page.memoryButton,"Native memory snapshot","Refresh the client's per-addon memory counters when available. Callback growth is measured separately.")
        UI.AttachTooltip(page.memoryModeButton,"Measure callback memory","Enable before Start in All Addons. Measures heap growth around callbacks, including profiling overhead; adds two reads per call.")
        UI.AttachTooltip(page.callbackViewButton,"Callback view","Switch family columns and ranking between time and memory growth. This does not change a running capture.")
        UI.AttachTooltip(page.loginButton,"Analyze next login","Record loading and the first five seconds in the world on the next login or reload. One capture; normal profiling stays off.")
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
            local gc,gaps=session and session.gc or {},session and session.frameGaps or {}
            local delta=session and session.heap and session.startHeap and session.heap-session.startHeap
            self.monitor.text:SetText((state.recording and "Recording" or state.enabled and "Stopped" or "Disabled")
                .."\nFPS: "..FPS(session and session.fps)
                .."\nShared Lua memory: "..Memory(session and session.heap)
                .."\nChange since Start: "..SignedMemory(delta)
                .."\nGC threshold: "..Memory(session and session.gcThreshold)
                .."\nHeap drops: "..(gc.heapDropCount or 0).." (last: "..(gc.lastHeapDrop and Memory(gc.lastHeapDrop) or "-")..")"
                .."\nWorst frame gap: "..(gaps.maximum and Duration(gaps.maximum) or "-")
                .."\nGap during last drop: "..(gc.lastHeapDropMaxFrameGap and Duration(gc.lastHeapDropMaxFrameGap) or "-"))
        end
        if not page:IsVisible() then return end
        self:EnsureUI();self:BuildItems()
        local memorySupported=state.session and state.session.capabilities and state.session.capabilities.addonMemory
        if self.provider.HasNativeAddonMemory then memorySupported=memorySupported~=false and self.provider.HasNativeAddonMemory() end
        local login=self.provider.LoginMemory
        local actionCount=0
        local previousCount=table.getn(page.flow)
        for _,button in ipairs(page.actions) do
            local show=true
            if button==page.loginButton then show=login~=nil
            elseif button==page.memoryModeButton or button==page.callbackViewButton then show=self.tab=="All Addons"
            elseif button==page.memoryButton then show=self.tab=="All Addons" and memorySupported~=false end
            if show then
                actionCount=actionCount+1
                if actionCount<=previousCount then page.flow[actionCount]=button else table.insert(page.flow,button) end
                button:Show()
            else button:Hide() end
        end
        for index=table.getn(page.flow),actionCount+1,-1 do table.remove(page.flow,index) end
        page.enableButton:SetText(state.enabled and "Disable" or "Enable")
        UI.SetButtonEnabled(page.startButton,state.enabled and not state.recording);UI.SetButtonEnabled(page.stopButton,state.recording)
        UI.SetButtonEnabled(page.resetButton,state.session~=nil);UI.SetButtonEnabled(page.exportButton,state.session~=nil and not state.recording)
        UI.SetButtonEnabled(page.refreshButton,state.session~=nil or login and login.GetReport()~=nil)
        UI.SetButtonEnabled(page.memoryButton,state.enabled and self.tab=="All Addons" and memorySupported~=false)
        page.memoryModeButton:SetText(self.measureMemory and "Memory: ON" or "Memory: OFF")
        page.callbackViewButton:SetText(self.callbackView=="memory" and "View: Memory" or "View: Time")
        UI.SetButtonEnabled(page.memoryModeButton,not state.recording)
        UI.SetButtonEnabled(page.callbackViewButton,self.measureMemory or state.session and state.session.callbackMemoryRequested)
        if login then page.loginButton:SetText(login.IsArmed() and "Login capture armed" or "Analyze next login");UI.SetButtonEnabled(page.loginButton,not login.IsRecording()) end
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(page.mosTab,self.tab=="MOS");UI.SetClassicButtonSelected(page.allTab,self.tab=="All Addons") end
        UI.SetProjectButtonOutline(page.mosTab,self.tab=="MOS");UI.SetProjectButtonOutline(page.allTab,self.tab=="All Addons")
        page.status:SetText((state.recording and "Recording" or state.enabled and "Ready / stopped" or "Disabled") .. (state.session and " | "..Elapsed(state.session.elapsed) or "") .. (state.error and "\n" .. state.error or self.notice and "\n" .. self.notice or ""))
        if state.recording then page.status:SetTextColor(unpack(UI.Theme.colors.goldText)) else page.status:SetTextColor(1,1,1) end
        self:Layout()
    end
    local function Updated() module:Refresh() end
    local function Subscribe()
        if module.provider then module.provider.SetListener((page:IsVisible() or module.monitor and module.monitor:IsVisible()) and Updated or nil) end
        if module.provider and module.provider.LoginMemory then module.provider.LoginMemory.SetListener(page:IsVisible() and Updated or nil) end
    end
    function module:SelectTab(tab) self:CancelFamilyJob();self.familyModel=nil;self.tab=tab;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end
    function module:ToggleSection(name)
        if name=="technical" then self.detailsExpanded[self.tab]=not self.detailsExpanded[self.tab]
        else self.sectionState[self.tab..":"..name]=not self:IsSectionExpanded(name) end
        if self:IsSectionExpanded(name) then self.snapshots[self.tab..":"..name]=nil end
        if name=="callbackDetails" then self:CancelFamilyJob();self.familyModel=nil end
        self:Refresh()
    end
    function module:ToggleDetails() self:ToggleSection("technical") end
    function module:RefreshTables() self:CancelFamilyJob();self.familyModel=nil;self.snapshots={};self:Refresh() end
    function module:ToggleMemoryCapture()
        if self.provider.GetState().recording then return end
        self.measureMemory=not self.measureMemory
        self.callbackView=self.measureMemory and "memory" or "time"
        self:RefreshTables()
    end
    function module:ToggleCallbackView()
        self.callbackView=self.callbackView=="memory" and "time" or "memory"
        self:RefreshTables()
    end
    function module:ToggleLoginCapture()
        local capture=self.provider.LoginMemory
        if not capture then return end
        local ok,message=capture.Arm(not capture.IsArmed())
        self.notice=ok and nil or message
        self.sectionState[self.tab..":loginMemory"]=true
        self:Refresh()
    end
    function module:SetLoginPage(direction) self.loginPage=math.max(1,self.loginPage+direction);self:Refresh() end
    function module:ReleasePresentation()
        self:CancelFamilyJob();self.familyModel=nil
        self.snapshots={};self.snapshotSession=nil;self.snapshotRecording=nil
        self.loginReport=nil
        for _,entries in ipairs({self.sessionEntries,self.callbackEntries,self.callbackDetails,self.memoryEntries,self.historyEntries or emptyEntries}) do
            for index=table.getn(entries),1,-1 do table.remove(entries,index) end
        end
        for _,item in ipairs(self.items) do item.operation=nil end
    end
    function module:Start()
        if not self.provider then return false end
        local ok,message=self.provider.Start({callbacks=self.tab=="All Addons",memory=self.measureMemory})
        if ok then self.familyPages={};self.familyPage=1;self.expandedFamily=nil end
        self.notice=message;self:Refresh();return ok
    end
    function module:Stop() if self.provider then self.provider.Stop();self:Refresh() end end
    function module:Reset() if self.provider then self.provider.Reset();self.familyPages={};self.familyPage=1;self.expandedFamily=nil;self.notice=nil;page.canvas.layoutViewport:SetVerticalScroll(0);self:Refresh() end end
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
            local monitor=UI.CreateContainer(nil,UIParent);monitor:SetPoint("CENTER",UIParent,"CENTER",280,100);monitor:SetWidth(340);monitor:SetHeight(204)
            monitor:SetFrameStrata("FULLSCREEN_DIALOG");monitor:SetMovable(true);monitor:EnableMouse(true);monitor:RegisterForDrag("LeftButton")
            if monitor.SetClampedToScreen then monitor:SetClampedToScreen(true) end
            monitor.title=UI.CreateHeading(monitor,"BootyProfiler",3,"gold");monitor.title:SetPoint("TOPLEFT",monitor,"TOPLEFT",8,-8)
            monitor.close=UI.CreateWindowButton(monitor,nil,"close");monitor.close:SetPoint("TOPRIGHT",monitor,"TOPRIGHT",-8,-8)
            monitor.close:SetScript("OnClick",function() monitor:Hide();Subscribe() end)
            monitor.text=UI.CreateLabel(monitor,nil,"OVERLAY","GameFontHighlightSmall");monitor.text:SetPoint("TOPLEFT",monitor,"TOPLEFT",8,-38);monitor.text:SetWidth(324);monitor.text:SetJustifyH("LEFT")
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
        if self.provider and self.provider~=provider then
            self.provider.SetListener(nil)
            if self.provider.LoginMemory then self.provider.LoginMemory.SetListener(nil) end
        end
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
