local MOS = MuklaOfficerSuite
local Dialog = {}
MOS.Modules.LootRollDialog = Dialog

-- One lazy, compact dialog; its type and player selections are transient.
function Dialog.Create(options)
    local UI = MOS.UI.Components
    local frame = UI.Window.CreateProjectConfirmation("MuklaOfficerSuiteNewRoll", "New Roll", "Start Roll")
    local projectOpen = frame.Open
    frame.label:SetJustifyH("LEFT")
    frame.item = UI.CreateFramedEditBox(frame, nil, 304, 22)
    frame.item:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -60)
    frame.item:SetWidth(304); frame.item:SetHeight(22); frame.item:SetAutoFocus(false)
    frame.item:SetScript("OnEditFocusGained",function() frame.itemFocused=true end)
    frame.item:SetScript("OnEditFocusLost",function() frame.itemFocused=nil end)
    local linkBinding,bagBinding
    local function DetachLinkInput()
        if linkBinding then
            linkBinding.active=false
            if ChatEdit_InsertLink==linkBinding.wrapper then ChatEdit_InsertLink=linkBinding.original end
            linkBinding=nil
        end
        if bagBinding then
            bagBinding.active=false
            if ContainerFrameItemButton_OnClick==bagBinding.wrapper then ContainerFrameItemButton_OnClick=bagBinding.original end
            bagBinding=nil
        end
    end
    frame:SetScript("OnShow",function()
        DetachLinkInput()
        if type(ChatEdit_InsertLink)=="function" then
            local binding={active=true,original=ChatEdit_InsertLink}
            binding.wrapper=function(link)
                if binding.active and frame:IsVisible() and frame.itemFocused
                    and MOS.Services.LootRollRequest.Normalize({link=link}) then frame.item:SetText(link);return true end
                return binding.original(link)
            end
            linkBinding=binding;ChatEdit_InsertLink=binding.wrapper
        end
        if type(ContainerFrameItemButton_OnClick)=="function" then
            local binding={active=true,original=ContainerFrameItemButton_OnClick}
            binding.wrapper=function(button,ignoreModifiers)
                if binding.active and frame:IsVisible() and frame.itemFocused and button=="LeftButton" and not ignoreModifiers
                    and IsShiftKeyDown() and not IsControlKeyDown() and this and this.GetID and this:GetParent() then
                    local link=GetContainerItemLink(this:GetParent():GetID(),this:GetID())
                    if MOS.Services.LootRollRequest.Normalize({link=link}) then frame.item:SetText(link);return end
                end
                return binding.original(button,ignoreModifiers)
            end
            bagBinding=binding;ContainerFrameItemButton_OnClick=binding.wrapper
        end
    end)
    frame.types, frame.selected, frame.typeChecks, frame.memberEntries = {}, {}, {}, {}
    local binding = {ensure=function() end, get=function(key) return frame.types[key] end,
        set=function(key,value) frame.types[key]=value end}
    for index,range in ipairs({98,99,100,101,102}) do
        local check = UI.Settings.CreateCheckbox(frame, 8+(index-1)*61, -90,
            MOS.Services.LootRollRequest.CategoryNames[range], range, nil, binding)
        check:SetWidth(18); check:SetHeight(18)
        check.labelHit:SetHeight(18)
        frame.typeChecks[range]=check
    end
    frame.membersButton = UI.CreateButton(frame, nil, "All raid members", 304, 22)
    frame.membersButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -122)
    UI.SetClassicButtonIcon(frame.membersButton,"roster")
    UI.AttachTooltip(frame.membersButton,"Players","Choose who may roll. With no selection, all raid members may roll.")
    local function UpdateMembersCaption()
        local count=0
        for _,entry in ipairs(frame.memberEntries) do if frame.selected[entry.data] then count=count+1 end end
        frame.membersButton:SetText(count>0 and "Players: "..count or "All raid members")
    end
    frame.memberMenu = UI.CreateCascadingMenu(function(_,name)
        frame.selected[name]=not frame.selected[name] or nil
        for _,entry in ipairs(frame.memberEntries) do entry.checked=frame.selected[entry.data] and true or false end
        UpdateMembersCaption()
    end)
    frame.membersButton:SetScript("OnClick",function() frame.memberMenu:Open(frame.membersButton,frame.memberEntries) end)
    local projectHide=frame:GetScript("OnHide")
    frame:SetScript("OnHide",function()
        DetachLinkInput();frame.itemFocused=nil
        frame.memberMenu:Close(); frame.item:ClearFocus()
        if projectHide then projectHide() end
    end)
    frame.yes:SetScript("OnClick",function()
        local names={}
        for _,entry in ipairs(frame.memberEntries) do if frame.selected[entry.data] then table.insert(names,entry.data) end end
        local ok,failure=options.start({link=frame.item:GetText(),types=frame.types,names=names})
        if ok then frame:Hide()
        else frame.label:SetText(failure or "Could not start the roll.") end
    end)
    frame.Open=function(self)
        for key in pairs(self.selected) do self.selected[key]=nil end
        for key in pairs(self.types) do self.types[key]=nil end
        for _,range in ipairs({98,99,100,101,102}) do
            self.types[range]=range~=102
            self.typeChecks[range]:SetChecked(range~=102 and 1 or nil)
        end
        self.item:SetText("")
        local count=MOS.Services.Raid.GetRaidMemberCount()
        local used=0
        for index=1,math.min(40,math.max(0,count or 0)) do
            local name=MOS.Services.Raid.GetRaidMemberInfo(index)
            if name then
                used=used+1
                local entry=self.memberEntries[used] or {}
                self.memberEntries[used]=entry
                entry.text,entry.data,entry.action,entry.icon,entry.keepOpen,entry.checked=name,name,"player","roster",true,false
            end
        end
        for index=table.getn(self.memberEntries),used+1,-1 do table.remove(self.memberEntries,index) end
        UpdateMembersCaption()
        projectOpen(self,"Shift-click a bag item, then choose roll types.")
        self:SetWidth(320); self:SetHeight(192)
        self.label:SetHeight(18); self.label:SetJustifyH("LEFT")
        self:Raise(); self.item:SetFocus()
    end
    return frame
end
