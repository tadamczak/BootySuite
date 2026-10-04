local MOS = MuklaOfficerSuite
MOS.Modules.NativeRaidTab = {}
local NativeRaidTab = MOS.Modules.NativeRaidTab

-- The original 1.12 function hides every native subframe for an unmatched
-- name. Keep its tab/header selection, replacing only the Raid body.
function NativeRaidTab.Create(options)
    options = options or {}
    local UI = MOS.UI.Components
    local service = options.service or MOS.Services.RaidTab
    local controller = {}
    local panel, groupHost, groups, inviteDialog
    local previous, wrapper, selected, enabled, binding
    local members = {}
    local rendering = false

    local function IsEnabled()
        return options.isEnabled and options.isEnabled() == true
    end
    local function NativeAvailable()
        return FriendsFrame and RaidFrame and type(FriendsFrame_ShowSubFrame) == "function"
    end
    local function SelectedRaid()
        return selected or (FriendsFrame and FriendsFrame.selectedTab == 4)
    end
    local function Hide()
        if groups then groups:Hide() end
        if panel then panel:Hide() end
        if inviteDialog then inviteDialog:Hide() end
    end
    local function Refresh()
        if rendering or not panel or not panel:IsVisible() then return end
        rendering = true
        local width = math.max(1, (FriendsFrame:GetWidth() or 384) - 28)
        local height = math.max(1, (FriendsFrame:GetHeight() or 512) - 98)
        panel:SetWidth(width); panel:SetHeight(height)
        local convert = service.CanConvert()
        panel.invite:SetText(convert and "Convert to Raid" or "Add Member")
        local toolbarHeight = UI.LayoutFlow(panel.toolbar, panel.toolbarControls, 6, 5, math.max(1, width - 12), 4) + 5
        panel.toolbar:SetHeight(toolbarHeight)
        groupHost:ClearAllPoints()
        groupHost:SetPoint("TOPLEFT", panel.toolbar, "BOTTOMLEFT", 6, -4)
        groupHost:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 4)
        local bodyHeight = math.max(1, height - toolbarHeight - 8)
        groupHost:SetWidth(math.max(1, width - 12)); groupHost:SetHeight(bodyHeight)
        UI.SetButtonEnabled(panel.invite, convert or service.CanInvite())
        UI.SetButtonEnabled(panel.ready, MOS.Services.Raid.CanReadyCheck())
        service.ReadMembers(members)
        groups:Render(members, math.max(1, width - 12), bodyHeight)
        rendering = false
    end
    local function Invite()
        if service.CanConvert() then service.Convert(); Refresh(); return end
        if not service.CanInvite() then return end
        if not inviteDialog then
            inviteDialog = UI.Window.CreateProjectConfirmation("MuklaOfficerSuiteRaidTabInvite", "Add Member", "Invite")
            inviteDialog.memberName = UI.CreateFramedEditBox(inviteDialog, "MuklaOfficerSuiteRaidTabInviteName", 304)
            inviteDialog.memberName:SetPoint("TOPLEFT", inviteDialog, "TOPLEFT", 8, -62)
            inviteDialog.memberName:SetAutoFocus(false)
            inviteDialog.memberName:SetMaxLetters(24)
            inviteDialog.memberName:SetScript("OnEscapePressed", function() inviteDialog:Hide() end)
            inviteDialog.memberName:SetScript("OnEnterPressed", function() inviteDialog.yes:GetScript("OnClick")() end)
            local hidden = inviteDialog:GetScript("OnHide")
            inviteDialog:SetScript("OnHide", function() if hidden then hidden() end; inviteDialog.memberName:ClearFocus() end)
        end
        inviteDialog:Open("Character name", function() service.Invite(inviteDialog.memberName:GetText()) end)
        inviteDialog.label:SetHeight(18); inviteDialog:SetHeight(128)
        inviteDialog.memberName:SetText("")
        inviteDialog.memberName:SetFocus()
    end
    local function CreatePanel()
        if panel then return end
        panel = UI.CreateContainer("MuklaOfficerSuiteNativeRaidTab", FriendsFrame)
        panel:Hide(); panel:SetPoint("TOPLEFT", FriendsFrame, "TOPLEFT", 14, -64)
        panel:SetPoint("BOTTOMRIGHT", FriendsFrame, "BOTTOMRIGHT", -14, 34)
        panel:SetFrameLevel(FriendsFrame:GetFrameLevel() + 3)
        UI.Window.ApplyProjectSurface(panel)
        local toolbar = UI.CreateToolbarSurface(panel, false, true)
        toolbar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0); toolbar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0); toolbar:SetHeight(32)
        panel.invite = UI.CreateButton(toolbar, nil, "Add Member", 112, 22)
        panel.invite:SetPoint("LEFT", toolbar, "LEFT", 6, 0)
        panel.ready = UI.CreateButton(toolbar, nil, "Ready Check", 104, 22)
        panel.ready:SetPoint("LEFT", panel.invite, "RIGHT", 4, 0)
        panel.info = UI.CreateButton(toolbar, nil, "Raid Info", 82, 22)
        panel.info:SetPoint("LEFT", panel.ready, "RIGHT", 4, 0)
        panel.toolbar = toolbar; panel.toolbarControls = { panel.invite, panel.ready, panel.info }
        panel.invite.mosFlowWidth = 112; panel.ready.mosFlowWidth = 104; panel.info.mosFlowWidth = 82
        panel.invite.mosFlowFitLabel = true; panel.ready.mosFlowFitLabel = true; panel.info.mosFlowFitLabel = true
        panel.invite:SetScript("OnClick", Invite)
        panel.ready:SetScript("OnClick", function() MOS.Services.Raid.ReadyCheck() end)
        panel.info:SetScript("OnClick", function() if options.openRaidInfo then options.openRaidInfo() end end)
        groupHost = UI.CreateContainer(nil, panel)
        groupHost:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 6, -4)
        groupHost:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -6, 4)
        groups = MOS.Modules.RaidManagement.CreateCompactGroupView(groupHost, {
            ensureDatabase = options.ensureDatabase or MOS.Database.Ensure,
            getLootMasterInfo = MOS.Services.Raid.GetLootMasterInfo,
            moveMemberToSlot = service.MoveMemberToSlot,
            runMemberAction = service.RunMemberAction,
            isPlayerIgnored = MOS.Services.Raid.IsPlayerIgnored,
            onChanged = Refresh,
        })
        panel:SetScript("OnShow", function()
            panel:RegisterEvent("RAID_ROSTER_UPDATE"); panel:RegisterEvent("PARTY_MEMBERS_CHANGED"); panel:RegisterEvent("PARTY_LEADER_CHANGED"); panel:RegisterEvent("PLAYER_ENTERING_WORLD")
            Refresh()
        end)
        panel:SetScript("OnHide", function()
            panel:UnregisterEvent("RAID_ROSTER_UPDATE"); panel:UnregisterEvent("PARTY_MEMBERS_CHANGED"); panel:UnregisterEvent("PARTY_LEADER_CHANGED"); panel:UnregisterEvent("PLAYER_ENTERING_WORLD")
            groups:Hide()
            if inviteDialog then inviteDialog:Hide() end
        end)
        panel:SetScript("OnEvent", Refresh)
        panel:SetScript("OnSizeChanged", Refresh)
    end
    local function Show()
        CreatePanel()
        if panel:IsVisible() then Refresh() else panel:Show() end
    end

    function controller:Sync()
        enabled = IsEnabled()
        if not enabled then
            local restoreRaid = SelectedRaid() and FriendsFrame and FriendsFrame:IsVisible()
            if binding then binding.active = false end
            Hide(); selected = false
            if wrapper and FriendsFrame_ShowSubFrame == wrapper then FriendsFrame_ShowSubFrame = previous end
            if restoreRaid and type(FriendsFrame_ShowSubFrame) == "function" then FriendsFrame_ShowSubFrame("RaidFrame") end
            wrapper, previous, binding = nil, nil, nil
            return true
        end
        if not NativeAvailable() then Hide(); return false end
        if not wrapper then
            previous = FriendsFrame_ShowSubFrame
            local original = previous
            binding = { active = true }
            local currentBinding = binding
            wrapper = function(frameName)
                if currentBinding.active and IsEnabled() and frameName == "RaidFrame" then
                    original("MuklaOfficerSuiteRaidReplacement")
                    selected = true; Show()
                else
                    selected = false; Hide(); original(frameName)
                end
            end
            FriendsFrame_ShowSubFrame = wrapper
        end
        if FriendsFrame:IsVisible() and SelectedRaid() then FriendsFrame_ShowSubFrame("RaidFrame") end
        return true
    end
    function controller:IsVisible() return panel and panel:IsVisible() or false end
    return controller
end
