local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
MOS.Modules.Performance = MOS.Modules.Performance or {}

local function Memory(value)
    return type(value)=="number" and string.format("%.2f MB",value/1024) or "-"
end
local function Pair(current,maximum) return Memory(current).." / "..Memory(maximum) end

function MOS.Modules.Performance.CreateLiveMonitor(backend)
    local frame=UI.CreateContainer(nil,UIParent)
    frame:SetPoint("CENTER",UIParent,"CENTER",280,100);frame:SetWidth(366);frame:SetHeight(130)
    frame:SetFrameStrata("FULLSCREEN_DIALOG");frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame.title=UI.CreateHeading(frame,"Live Monitor",3,"gold");frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-5)
    local font,_,flags=frame.title:GetFont();frame.title:SetFont(font,13,flags)
    frame.close=UI.CreateWindowButton(frame,nil,"close");frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)
    frame.close:SetScript("OnClick",function() frame:Close() end)
    frame:SetScript("OnDragStart",function() this:StartMoving() end);frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
    frame.values={};frame.labels={}
    local names={"FPS","Current rate","Shared Lua: current / max","GC threshold: current / max","Last cleanup"}
    local keys={"fps","rate","memory","threshold","cleanup"}
    local hints={"Current FPS sampled once per second; brief pauses can fall between readings.",
        "Net shared Lua memory change per second, including cleanup. A negative rate means memory fell; this is not allocation throughput.",
        "Lua memory shared by addons and the UI. Maximum is observed while this monitor is open; this is not game process RAM.",
        "Lua's reported collection threshold and its highest observed value while this monitor is open. It is not memory reclaimed.",
        "Last net decrease between memory readings, and how long ago it was observed. GC can contribute; this does not measure the duration of a collection."}
    for index,key in ipairs(keys) do
        local label=UI.CreateLabel(frame,nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-28-(index-1)*20);label:SetText(names[index]);label:SetTextColor(unpack(UI.Theme.colors.goldText))
        UI.FitButtonLabel(label,150);label:SetJustifyV("MIDDLE")
        local value=UI.CreateLabel(frame,nil,"OVERLAY","GameFontHighlightSmall")
        value:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-6,-28-(index-1)*20);value:SetWidth(194);value:SetHeight(16);value:SetJustifyH("RIGHT")
        frame.labels[key]=label;frame.values[key]=value;frame[key]=value
        local hit=UI.CreateControl(nil,frame);hit:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-26-(index-1)*20);hit:SetWidth(354);hit:SetHeight(20)
        UI.AttachTooltip(hit,names[index],hints[index])
    end
    function frame:Refresh()
        if not self:IsVisible() then return end
        local state=backend.GetState()
        self.fps:SetText(type(state.fps)=="number" and tostring(math.floor(state.fps+0.5)) or "-")
        self.rate:SetText(type(state.rate)=="number" and string.format("%+.1f KB/s",state.rate) or "-")
        self.memory:SetText(Pair(state.heap,state.maxHeap));self.threshold:SetText(Pair(state.gcThreshold,state.maxGcThreshold))
        local age=type(state.lastCleanupAge)=="number" and tostring(math.floor(state.lastCleanupAge)).." sec ago" or "age unavailable"
        self.cleanup:SetText(state.lastCleanup and Memory(state.lastCleanup).." / ("..age..")" or "Not observed")
        for _,value in pairs(self.values) do UI.FitButtonLabel(value,194);value:SetJustifyH("RIGHT") end
    end
    local function Updated() frame:Refresh() end
    local function Shown()
        if not frame:IsVisible() then return false end
        backend.SetListener(Updated)
        local ok=backend.SetVisible(true)
        if not ok then frame:Hide() end
        frame:Refresh();return ok
    end
    function frame:Open()
        self:Show();return Shown()
    end
    function frame:Close() backend.SetVisible(false);self:Hide() end
    frame:SetScript("OnShow",Shown)
    frame:SetScript("OnHide",function() backend.SetVisible(false) end)
    UI.Window.StyleProjectDialog(frame)
    frame.title:ClearAllPoints();frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-6)
    frame.close:ClearAllPoints();frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)
    frame:Hide()
    return frame
end
