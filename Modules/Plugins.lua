local Suite,Lib,UI=BootySuite,BootyLib,BootyLib.UI.Components
local Plugins={pending={}}
Suite.Modules.Plugins=Plugins
local function Flag(value) return value~=nil and value~=false and value~=0 end
function Plugins.Inventory()
    local result={}
    if type(GetNumAddOns)~="function" or type(GetAddOnInfo)~="function" then return result end
    local ok,count=pcall(GetNumAddOns)
    if not ok or type(count)~="number" or count~=count or count<0 or count>4096 or count~=math.floor(count) then return result end
    for index=1,count do
        local success,name,title,notes,enabled,loadable,reason=pcall(GetAddOnInfo,index)
        if success and type(name)=="string" and name~="" then
            result[name]={name=name,title=title,notes=type(notes)=="string" and notes or nil,enabled=Flag(enabled),loadable=Flag(loadable),reason=reason,index=index}
        end
    end
    return result
end
function Plugins.GetProduct(name)
    for _,id in ipairs(Lib.GetProducts()) do
        local product=Lib.GetProduct(id)
        if product and (product.addonName or product.name)==name then return product,id end
    end
end
local descriptions={
    BootyLib="Shared interface, visual styles and utilities required by all Booty addons.",
    BootySuite="One dashboard, minimap menu, combined settings and plugin controls for installed Booty addons.",
    BootyProfiler="Live performance monitoring, addon profiling, login analysis and health checks.",
    BootyGuild="Guild roster, member details, guild information and guild statistics.",
    BootyRaider="Raid sessions, raid statistics, CSR, loot history, rolls and loot master tools.",
}
function Plugins.GetDescription(name,current)
    if descriptions[name] then return descriptions[name] end
    if current and type(current.notes)=="string" and string.find(current.notes,"%S") then return current.notes end
    local product=Plugins.GetProduct(name)
    if product and type(product.description)=="string" and string.find(product.description,"%S") then return product.description end
    return "Additional Booty addon."
end
local function IsBootyAddon(name)
    return type(name)=="string" and (string.find(name,"^Booty")~=nil or Plugins.GetProduct(name)~=nil)
end
function Plugins.GetNames(inventory)
    inventory=inventory or Plugins.Inventory()
    local names,seen,features={"BootyLib","BootySuite"},{BootyLib=true,BootySuite=true},{}
    local function Add(name)
        if type(name)=="string" and name~="" and not seen[name] then seen[name]=true;table.insert(features,name) end
    end
    for _,id in ipairs(Lib.GetProducts()) do
        local product=Lib.GetProduct(id)
        if product then Add(product.addonName or product.name) end
    end
    for name in pairs(inventory) do if IsBootyAddon(name) then Add(name) end end
    table.sort(features)
    for _,name in ipairs(features) do table.insert(names,name) end
    return names
end
local function EffectiveEnabled(name,inventory)
    if Plugins.pending[name]~=nil then return Plugins.pending[name] end
    return inventory[name] and inventory[name].enabled or false
end
local function Busy(product)
    if not product or not product.IsBusy then return false end
    local ok,value=pcall(product.IsBusy)
    if not ok then return true,"Cannot verify active work for "..tostring(product.name)..": "..tostring(value) end
    return Flag(value)
end
local function Dependencies(name)
    local dependencies={}
    local product=Plugins.GetProduct(name)
    for _,dependency in ipairs(product and (product.requiredAddons or product.dependencies) or {}) do
        if type(dependency)=="string" then dependencies[dependency]=true end
    end
    if type(GetAddOnDependencies)=="function" then
        local values={pcall(GetAddOnDependencies,name)}
        if values[1] then
            for index=2,table.getn(values) do if type(values[index])=="string" then dependencies[values[index]]=true end end
        end
    end
    if name~="BootyLib" and IsBootyAddon(name) then dependencies.BootyLib=true end
    return dependencies
end
function Plugins.CanReload()
    for _,id in ipairs(Lib.GetProducts()) do
        local busy,failure=Busy(Lib.GetProduct(id))
        if busy then return false,failure or "Finish the active raid or recording before reloading." end
    end
    return true
end
function Plugins.SetEnabled(name,enabled)
    if type(enabled)~="boolean" then return false,"Choose enabled or disabled." end
    if not IsBootyAddon(name) then return false,"This addon is outside Booty Suite." end
    local inventory=Plugins.Inventory()
    if not inventory[name] then return false,"Addon is not installed." end
    if name=="BootyLib" and not enabled then return false,"BootyLib is required by all Booty products." end
    if enabled then
        for dependency in pairs(Dependencies(name)) do
            if not EffectiveEnabled(dependency,inventory) then return false,"Enable "..dependency.." before enabling "..name.."." end
        end
    else
        local busy,failure=Busy(Plugins.GetProduct(name))
        if busy then return false,failure or "Finish active work before changing this addon's loading." end
        if name=="BootySuite" then
            local ready,message=Plugins.CanReload()
            if not ready then return false,message end
        end
        for other in pairs(inventory) do
            if other~=name and EffectiveEnabled(other,inventory) and Dependencies(other)[name] then
                return false,"Disable "..other.." before disabling "..name.."."
            end
        end
    end
    local action
    if enabled then action=EnableAddOn else action=DisableAddOn end
    if type(action)~="function" then return false,"The client cannot change addon loading." end
    local ok,failure=pcall(action,name)
    if not ok or failure==false or failure==0 then return false,tostring(failure) end
    Plugins.pending[name]=enabled
    return true
end
function Plugins.Reload()
    local ready,failure=Plugins.CanReload()
    if not ready then return false,failure end
    if type(ReloadUI)~="function" then return false,"Reload is unavailable." end
    local ok,result=pcall(ReloadUI)
    if not ok or result==false or result==0 then return false,tostring(result) end
    return true
end
local function Notify()
    if Suite.RefreshProductAvailability then Suite.RefreshProductAvailability() end
end
function Plugins.Stop(name)
    local product,id=Plugins.GetProduct(name)
    if not product then return false,"Product is not loaded." end
    local busy,failure=Busy(product)
    if busy then return false,failure or "Finish active work before stopping this addon." end
    local runtime=Lib.Core.Runtime
    if not runtime or not runtime.StopProduct then return false,"Stopping products is unavailable." end
    local ok,result,message=pcall(runtime.StopProduct,id)
    if not ok or result==false then return false,message or tostring(result) end
    Notify();return true
end
function Plugins.Resume(name)
    local product,id=Plugins.GetProduct(name)
    if not product or not product.stopped then return false,"Product is not stopped." end
    if product.failure then return false,product.failure end
    local start=product.Start
    if type(start)~="function" then return false,"This product cannot resume without /reload." end
    local runtime=Lib.Core.Runtime
    local host=runtime and runtime.hosts and runtime.hosts[id]
    local ok,result,message=pcall(start,host)
    if not ok or result==false then return false,message or tostring(result) end
    product.stopped=nil
    if runtime and runtime.RefreshDirectory then runtime.RefreshDirectory(false) end
    if host and host.ApplySettings then host.ApplySettings() end
    Notify();return true
end
function Plugins.Create(parent)
    local frame=UI.CreateContainer(nil,parent);frame:SetAllPoints(parent)
    local page=UI.CreateResponsiveCanvas(frame,"BootySuitePluginsScroll")
    local controller={frame=frame,page=page,rows={}}
    local title=UI.CreateHeading(page,"Plugins",1,"gold","groups")
    local hint=UI.CreateComponentLabel(page,nil,"white")
    hint:SetJustifyH("LEFT")
    controller.hint=hint
    hint:SetText("Loading changes apply after /reload. Stop pauses current work without unloading the addon.")
    local function UpdateMessage(ok,failure)
        if not ok then Lib.Print(failure) end
        controller:Refresh()
    end
    local function EnsureRow(name)
        if controller.rows[name] then return controller.rows[name] end
        local row=UI.CreateContainer(nil,page)
        row.label=UI.CreateComponentLabel(row,nil,"white");row.label:SetText(name);row.label:SetJustifyH("LEFT")
        row.status=UI.CreateComponentLabel(row,nil,"gray")
        row.status:SetJustifyH("LEFT")
        row.labelTooltip=UI.AttachLabelTooltip(row,row.label,name,function() return row.description end)
        row.labelTooltip:SetScript("OnHide",function()
            if GameTooltip and type(GameTooltip.GetOwner)=="function" and GameTooltip:GetOwner()==this then GameTooltip:Hide() end
        end)
        row.toggle=UI.CreateButton(row,nil,"Enabled",95,26)
        row.toggle:SetScript("OnClick",function()
            local inventory=Plugins.Inventory()
            if inventory[name] then UpdateMessage(Plugins.SetEnabled(name,not EffectiveEnabled(name,inventory))) end
        end)
        row.stop=UI.CreateButton(row,nil,"Stop",76,26)
        row.stop:SetScript("OnClick",function()
            local product=Plugins.GetProduct(name)
            if product and product.stopped then UpdateMessage(Plugins.Resume(name))
            else UpdateMessage(Plugins.Stop(name)) end
        end)
        controller.rows[name]=row
        return row
    end
    local reload=UI.CreateButton(page,nil,"Reload UI",120,28)
    controller.reload=reload
    reload:SetScript("OnClick",function() UpdateMessage(Plugins.Reload()) end)
    local function Measure(width)
        title:ClearAllPoints();title:SetPoint("TOPLEFT",page,"TOPLEFT",12,-12)
        hint:ClearAllPoints();hint:SetPoint("TOPLEFT",page,"TOPLEFT",12,-44);hint:SetWidth(math.max(1,width-24));hint:SetHeight(0)
        local hintHeight=math.max(32,UI.MeasureTextHeight(hint,math.max(1,width-24)))
        hint:SetHeight(hintHeight)
        local y=52+hintHeight
        for _,name in ipairs(controller.names) do
            local row=controller.rows[name]
            local narrow=width<520
            local rowWidth=math.max(1,width-24)
            row:ClearAllPoints();row:SetPoint("TOPLEFT",page,"TOPLEFT",12,-y);row:SetWidth(rowWidth);row:SetHeight(narrow and 84 or 38)
            row.label:ClearAllPoints();row.label:SetPoint("TOPLEFT",row,"TOPLEFT",0,-5)
            row.label:SetWidth(math.max(1,math.min(narrow and rowWidth or 150,row.label:GetStringWidth())))
            row.status:ClearAllPoints();row.status:SetPoint("TOPLEFT",row,"TOPLEFT",narrow and 0 or 155,narrow and -31 or -5)
            row.status:SetWidth(math.max(1,narrow and rowWidth or width-364))
            row.toggle:ClearAllPoints();row.stop:ClearAllPoints()
            if narrow then
                local buttonSpace=math.max(2,rowWidth-6)
                local toggleWidth=math.min(95,math.floor(buttonSpace*0.55))
                row.toggle:SetWidth(toggleWidth);row.stop:SetWidth(math.min(76,buttonSpace-toggleWidth))
                row.toggle:SetPoint("TOPLEFT",row,"TOPLEFT",0,-55)
                row.stop:SetPoint("LEFT",row.toggle,"RIGHT",6,0)
            else
                row.toggle:SetWidth(95);row.stop:SetWidth(76)
                row.toggle:SetPoint("TOPRIGHT",row,"TOPRIGHT",-82,0)
                row.stop:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
            end
            y=y+(narrow and 92 or 44)
        end
        reload:ClearAllPoints();reload:SetPoint("TOPLEFT",page,"TOPLEFT",12,-y)
        return y+40
    end
    function controller:Refresh()
        local inventory=Plugins.Inventory()
        self.names=Plugins.GetNames(inventory)
        local active={}
        for _,name in ipairs(self.names) do
            active[name]=true
            local row=EnsureRow(name)
            local current,product=inventory[name],Plugins.GetProduct(name)
            row.description=Plugins.GetDescription(name,current)
            local pending=Plugins.pending[name]
            local loaded=name=="BootyLib" or name=="BootySuite" or product and product.initialized
            row.status:SetText(pending~=nil and "Pending /reload" or not current and "Not installed" or product and product.failure and "Unavailable" or loaded and (product and product.stopped and "Stopped" or "Loaded") or "Not loaded")
            row.toggle:SetText(EffectiveEnabled(name,inventory) and "Disable" or "Enable")
            UI.SetButtonEnabled(row.toggle,current~=nil and (name~="BootyLib" or not EffectiveEnabled(name,inventory)))
            row.stop:SetText(product and product.stopped and "Resume" or "Stop")
            UI.SetButtonEnabled(row.stop,product~=nil and not product.failure and (not product.stopped or type(product.Start)=="function"))
            row:Show()
        end
        for name,row in pairs(self.rows) do if not active[name] then row:Hide() end end
        local width,height=UI.GetFrameSpan(parent)
        frame:SetWidth(math.max(1,width));frame:SetHeight(math.max(1,height))
        UI.LayoutResponsiveCanvas(page,Measure,nil,math.max(1,width),math.max(1,height))
    end
    function controller:Show() frame:Show();self:Refresh() end
    function controller:Hide() frame:Hide() end
    function controller:OnResize() if frame:IsVisible() then self:Refresh() end end
    frame:Hide();return controller
end
