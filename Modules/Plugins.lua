local Suite,Lib,UI=BootySuite,BootyLib,BootyLib.UI.Components
local Plugins={pending={}}
Suite.Modules.Plugins=Plugins
local function Flag(value) return value~=nil and value~=false and value~=0 end
function Plugins.Inventory() return (Lib.Core.ProductCommands.Inventory()) end
function Plugins.GetProduct(name)
    for _,id in ipairs(Lib.GetProducts()) do
        local product=Lib.GetProduct(id)
        if product and (product.addonName or product.name)==name then return product,id end
    end
end
local function Feature(name)
    if name=="BootyLib" or name=="BootySuite" then return nil,"This addon does not provide a feature tab." end
    local product,id=Plugins.GetProduct(name)
    if not product or type(product.views)~="table" or table.getn(product.views)==0 then
        return nil,"This addon has no registered view. Enable it and reload first."
    end
    return product,id
end
function Plugins.CanOpen(name)
    local product,id=Feature(name)
    if not product then return false,id end
    local shell=Suite.Shell
    if not shell or type(shell.CanOpenProduct)~="function" then return false,"Opening addon views is unavailable." end
    return shell.CanOpenProduct(id)
end
function Plugins.Open(name)
    local ready,failure=Plugins.CanOpen(name)
    if not ready then return false,failure end
    local _,id=Feature(name)
    return Suite.Shell.OpenProduct(id)
end
function Plugins.IsInMenu(name)
    local product,id=Feature(name)
    local shell=Suite.Shell
    return product~=nil and shell~=nil and type(shell.IsInMenu)=="function" and shell.IsInMenu(id) or false
end
function Plugins.CanSetInMenu(name)
    local product,id=Feature(name)
    if not product then return false,id end
    local shell=Suite.Shell
    if not shell or type(shell.CanSetInMenu)~="function" then return false,"Changing addon menu tabs is unavailable." end
    return shell.CanSetInMenu(id)
end
function Plugins.SetInMenu(name,enabled)
    if type(enabled)~="boolean" then return false,"Choose whether to add this addon to the menu." end
    local ready,failure=Plugins.CanSetInMenu(name)
    if not ready then return false,failure end
    local _,id=Feature(name)
    return Suite.Shell.SetInMenu(id,enabled)
end
function Plugins.IsInQuickMenu(name)
    local product,id=Feature(name)
    return product~=nil and Suite.Shell.IsInQuickMenu(id) or false
end
function Plugins.SetInQuickMenu(name,enabled)
    local ready,failure=Plugins.CanSetInMenu(name)
    if not ready then return false,failure end
    local _,id=Feature(name)
    return Suite.Shell.SetInQuickMenu(id,enabled)
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
    if Suite.RefreshProductAvailability then Suite.RefreshProductAvailability() end
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
    if product.stopCleanupPending then
        if not runtime or type(runtime.StopProduct)~="function" then return false,"Stop cleanup is unavailable." end
        local cleaned,result,message=pcall(runtime.StopProduct,id)
        if not cleaned or result==false then return false,message or tostring(result) end
    end
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
    hint:SetText("Choose where addons appear. Loading changes require /reload.")
    local function Font(label,size)
        local font,_,flags=label:GetFont()
        label:SetFont(font,size,flags);label:SetHeight(size+4)
        if label.SetWordWrap then label:SetWordWrap(false) end
        if label.SetNonSpaceWrap then label:SetNonSpaceWrap(false) end
    end
    local function Cell(label,text,parent,x,y,width)
        Font(label,11);label:ClearAllPoints();label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
        label:SetWidth(0);label:SetText(text)
        if label:GetStringWidth()>width-2 then
            local low,high=0,string.len(text)
            while low<high do
                local middle=math.floor((low+high+1)/2)
                label:SetText(string.sub(text,1,middle).."...")
                if label:GetStringWidth()<=width-2 then low=middle else high=middle-1 end
            end
            label:SetText(string.sub(text,1,low).."...")
        end
        label:SetWidth(math.max(1,math.min(width,label:GetStringWidth()+2)))
    end
    local headers,headerTitles={},{"Addon","Version","Status","Menu","Quick"}
    for _,text in ipairs(headerTitles) do
        local label=UI.CreateComponentLabel(page,nil,"gold");label:SetJustifyH("LEFT")
        table.insert(headers,label)
    end
    controller.headers=headers
    local function HideOwnedTooltip()
        if GameTooltip and type(GameTooltip.GetOwner)=="function" and GameTooltip:GetOwner()==this then GameTooltip:Hide() end
    end
    local function LabelTooltip(parent,label,title,description)
        local hit=UI.AttachLabelTooltip(parent,label,title,description)
        hit:SetScript("OnHide",HideOwnedTooltip)
        return hit
    end
    headers[4].tooltip=LabelTooltip(page,headers[4],"Add to menu","Show addons in the Suite window menu.")
    headers[5].tooltip=LabelTooltip(page,headers[5],"Add to Quick Menu","Show addons in the separate Quick Menu.")
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
        row.version=UI.CreateComponentLabel(row,nil,"gold");row.version:SetJustifyH("LEFT")
        row.labelTooltip=LabelTooltip(row,row.label,name,function() return row.description end)
        row.versionTooltip=LabelTooltip(row,row.version,name.." version",function() return row.versionText end)
        row.statusTooltip=LabelTooltip(row,row.status,name.." status",function() return row.statusText end)
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
        row.open=UI.CreateButton(row,nil,"Open",72,26)
        row.open:SetScript("OnClick",function() UpdateMessage(Plugins.Open(name)) end)
        row.menuSlot=UI.CreateContainer(nil,row);row.menuSlot:SetHeight(26)
        row.addToMenu=UI.Settings.CreateCheckbox(row.menuSlot,0,0,"Add to menu",name,nil,{
            ensure=function() end,
            get=function() return Plugins.IsInMenu(name) end,
            set=function(_,value) UpdateMessage(Plugins.SetInMenu(name,value)) end,
        })
        row.addToMenu:ClearAllPoints();row.addToMenu:SetPoint("LEFT",row.menuSlot,"LEFT",0,0)
        row.quickSlot=UI.CreateContainer(nil,row);row.quickSlot:SetHeight(26)
        row.addToQuickMenu=UI.Settings.CreateCheckbox(row.quickSlot,0,0,"Add to Quick Menu",name,nil,{
            ensure=function() end,
            get=function() return Plugins.IsInQuickMenu(name) end,
            set=function(_,value) UpdateMessage(Plugins.SetInQuickMenu(name,value)) end,
        })
        row.addToQuickMenu:ClearAllPoints();row.addToQuickMenu:SetPoint("LEFT",row.quickSlot,"LEFT",0,0)
        UI.AttachTooltip(row.addToMenu,"Add to menu","Show this addon in the Suite window menu.")
        UI.AttachTooltip(row.addToQuickMenu,"Add to Quick Menu","Show this addon in the separate Quick Menu.")
        row.actions={row.menuSlot,row.quickSlot,row.open,row.toggle,row.stop}
        controller.rows[name]=row
        return row
    end
    local reload=UI.CreateButton(page,nil,"Reload UI",120,28)
    controller.reload=reload
    reload:SetScript("OnClick",function() UpdateMessage(Plugins.Reload()) end)
    local function Measure(width)
        Font(title,16);title:ClearAllPoints();title:SetPoint("TOPLEFT",page,"TOPLEFT",12,-12)
        Font(hint,11);hint:ClearAllPoints();hint:SetPoint("TOPLEFT",page,"TOPLEFT",12,-36)
        hint:SetWidth(math.max(1,width-24))
        if hint.SetWordWrap then hint:SetWordWrap(true) end
        local hintHeight=UI.MeasureTextHeight(hint,math.max(1,width-24));hint:SetHeight(hintHeight)
        local rowWidth=math.max(1,width-24)
        local wide=rowWidth>=560
        local nameWidth=math.max(118,rowWidth*0.24)
        local versionWidth=rowWidth-nameWidth-334
        local columns={0,nameWidth+4,nameWidth+versionWidth+8,rowWidth-228,rowWidth-192}
        local sizes={nameWidth,versionWidth,94,32,32}
        local y=44+hintHeight
        for index,label in ipairs(headers) do
            if wide then
                Cell(label,headerTitles[index],page,12+columns[index],y,sizes[index]);label:Show()
                if label.tooltip then label.tooltip:Show() end
            else label:Hide();if label.tooltip then label.tooltip:Hide() end end
        end
        if wide then y=y+20 end
        for _,name in ipairs(controller.names) do
            local row=controller.rows[name]
            row:ClearAllPoints();row:SetPoint("TOPLEFT",page,"TOPLEFT",12,-y);row:SetWidth(rowWidth)
            row.open:SetWidth(44);row.toggle:SetWidth(54);row.stop:SetWidth(50)
            for _,button in ipairs({row.open,row.toggle,row.stop}) do
                button:SetHeight(20);button.bootyFitFontSize=11;Font(button.label,11)
                button.label:SetWidth(button:GetWidth()-8)
            end
            for index,check in ipairs({row.addToMenu,row.addToQuickMenu}) do
                local slot=check:GetParent();slot:SetWidth(wide and 32 or 56);slot:SetHeight(20)
                check:SetWidth(16);check:SetHeight(16);check:ClearAllPoints()
                check:SetPoint("LEFT",slot,"LEFT",wide and 8 or 0,0)
                if wide then check.label:Hide();check.labelHit:Hide()
                else
                    check.label:SetText(index==1 and "Menu" or "Quick");Font(check.label,11)
                    check.label:SetWidth(38);check.labelHit:SetWidth(38);check.labelHit:SetHeight(20)
                    check.label:Show();check.labelHit:Show()
                end
            end
            local bottom
            if wide then
                Cell(row.label,name,row,columns[1],3,sizes[1])
                Cell(row.version,row.versionText,row,columns[2],3,sizes[2])
                Cell(row.status,row.statusText,row,columns[3],3,sizes[3])
                bottom=UI.LayoutFlow(row,row.actions,columns[4],0,rowWidth-columns[4],4)
            else
                local small=rowWidth<320
                Cell(row.label,name,row,0,2,small and rowWidth or 118)
                Cell(row.version,row.versionText,row,small and 0 or 122,small and 18 or 2,small and rowWidth or math.max(1,rowWidth-220))
                Cell(row.status,row.statusText,row,small and 0 or rowWidth-94,small and 34 or 2,small and rowWidth or 94)
                bottom=UI.LayoutFlow(row,row.actions,0,small and 52 or 22,rowWidth,4)
            end
            row:SetHeight(bottom+4);y=y+row:GetHeight()
        end
        reload:SetHeight(22);reload:SetWidth(84);reload.bootyFitFontSize=11;Font(reload.label,11);reload.label:SetWidth(76)
        reload:ClearAllPoints();reload:SetPoint("TOPLEFT",page,"TOPLEFT",12,-y-8)
        return y+42
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
            row.versionText=Lib.Core.ProductCommands.Version(name)
            local pending=Plugins.pending[name]
            local loaded=name=="BootyLib" or name=="BootySuite" or product and product.initialized
            row.statusText=pending~=nil and "Pending /reload" or not current and "Not installed" or product and product.failure and "Unavailable" or loaded and (product and product.stopped and "Stopped" or "Loaded") or "Not loaded"
            row.toggle:SetText(EffectiveEnabled(name,inventory) and "Disable" or "Enable")
            UI.SetButtonEnabled(row.toggle,current~=nil and (name~="BootyLib" or not EffectiveEnabled(name,inventory)))
            row.stop:SetText(product and product.stopped and "Resume" or "Stop")
            UI.SetButtonEnabled(row.stop,product~=nil and not product.failure and (not product.stopped or type(product.Start)=="function"))
            local canOpen=Plugins.CanOpen(name)
            UI.SetButtonEnabled(row.open,canOpen)
            row.addToMenu:SetChecked(Plugins.IsInMenu(name) and 1 or nil)
            UI.Settings.SetCheckboxEnabled(row.addToMenu,Plugins.CanSetInMenu(name))
            row.addToQuickMenu:SetChecked(Plugins.IsInQuickMenu(name) and 1 or nil)
            UI.Settings.SetCheckboxEnabled(row.addToQuickMenu,Plugins.CanSetInMenu(name))
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
