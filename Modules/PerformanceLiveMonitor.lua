local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
MOS.Modules.Performance = MOS.Modules.Performance or {}

local function Memory(value)
    return type(value)=="number" and string.format("%.2f MB",value/1024) or "-"
end
local function Pair(current,threshold) return Memory(current).." / "..Memory(threshold) end
local healthColors={{0.72,0.72,0.72},{0.45,0.85,0.45},{1,0.78,0.25},{1,0.35,0.25}}
local function HealthHint() return this.monitorFrame.healthHint or "Checking recent FPS, latency and memory readings." end

function MOS.Modules.Performance.CreateLiveMonitor(backend)
    local frame=UI.CreateContainer(nil,UIParent)
    frame:SetPoint("CENTER",UIParent,"CENTER",280,100);frame:SetWidth(292);frame:SetHeight(130)
    frame:SetFrameStrata("FULLSCREEN_DIALOG");frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame.title=UI.CreateHeading(frame,"Live Monitor",3,"gold");frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-5)
    local font,_,flags=frame.title:GetFont();frame.title:SetFont(font,13,flags)
    frame.close=UI.CreateWindowButton(frame,nil,"close");frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)
    frame.close:SetScript("OnClick",function() frame:Close() end)
    frame:SetScript("OnDragStart",function() this:StartMoving() end);frame:SetScript("OnDragStop",function() this:StopMovingOrSizing() end)
    frame.art=UI.CreatePerformanceBackground(frame,0.22)
    UI.LayoutPerformanceBackground(frame.art,frame,292,130)
    frame.values={};frame.labels={}
    local names={"FPS","Memory / GC","Rate","Cleanup","Health"}
    local keys={"fps","memory","rate","cleanup","health"}
    local hints={"Current FPS sampled once per second; brief pauses can fall between readings.",
        "Current shared Lua memory / current collection threshold. Includes addons and UI; not total game RAM.",
        "Net shared memory change per second. Cleanup can make it negative; this is not allocation throughput.",
        "Last observed memory decrease and its age. This is not GC duration.",HealthHint}
    for index,key in ipairs(keys) do
        local label=UI.CreateLabel(frame,nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-28-(index-1)*20);label:SetText(names[index]);label:SetTextColor(unpack(UI.Theme.colors.goldText))
        UI.FitButtonLabel(label,76);label:SetJustifyV("MIDDLE")
        local value=UI.CreateLabel(frame,nil,"OVERLAY","GameFontHighlightSmall")
        value:SetPoint("TOPLEFT",frame,"TOPLEFT",88,-28-(index-1)*20);value:SetWidth(198);value:SetHeight(16);value:SetJustifyH("LEFT")
        frame.labels[key]=label;frame.values[key]=value;frame[key]=value
        local hit=UI.CreateControl(nil,frame);hit.monitorFrame=frame;hit:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-26-(index-1)*20);hit:SetWidth(280);hit:SetHeight(20)
        UI.AttachTooltip(hit,names[index],hints[index])
    end
    function frame:Refresh()
        if not self:IsVisible() then return end
        local state=backend.GetState()
        self.fps:SetText(type(state.fps)=="number" and tostring(math.floor(state.fps+0.5)) or "-")
        self.rate:SetText(type(state.rate)=="number" and string.format("%+.1f KB/s",state.rate) or "-")
        self.memory:SetText(Pair(state.heap,state.gcThreshold))
        local age=type(state.lastCleanupAge)=="number" and tostring(math.floor(state.lastCleanupAge)).."s ago" or "age unavailable"
        self.cleanup:SetText(state.lastCleanup and Memory(state.lastCleanup).." ("..age..")" or "-")
        local health=state.health
        self.health:SetText(health and health.status or "Checking")
        self.healthHint=health and health.reason or "Checking recent FPS, latency and memory readings."
        self.health:SetTextColor(unpack(healthColors[(health and health.severity or 0)+1] or healthColors[1]))
        for _,value in pairs(self.values) do UI.FitButtonLabel(value,198);value:SetJustifyH("LEFT") end
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
    UI.LayoutPerformanceBackground(frame.art,frame,292,130)
    frame.title:ClearAllPoints();frame.title:SetPoint("TOPLEFT",frame,"TOPLEFT",6,-6)
    frame.close:ClearAllPoints();frame.close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-4,-4)
    frame:Hide()
    return frame
end
