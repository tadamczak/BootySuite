local MOS = MuklaOfficerSuite
local Roster = MOS.Modules.RosterManagement
local C = MOS.UI.Components

local function Place(window, label, y)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", window, "TOPLEFT", 12, y)
    label:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, y)
end

local function MatchSmallLabel(label, reference)
    local font, size, flags = reference:GetFont()
    label:SetFont(font, size, flags)
    label:SetJustifyH("LEFT")
end

function Roster.LayoutDetailsWindow(window, member)
    window:SetWidth(230)
    Place(window, window.details.name, -12)
    window.details.name:SetPoint("TOPRIGHT", window, "TOPRIGHT", -34, -12)
    Place(window, window.details.level, -29)
    Place(window, window.zoneLabel, -48)
    window.zoneLabel:SetText("Zone: |cffffffff" .. (member.zone or "Unknown") .. "|r")
    Place(window, window.details.rank, -66)
    window.details.rank:SetPoint("TOPRIGHT", window, "TOPRIGHT", -64, -66)
    Place(window, window.details.lastOnline, -84)
    MatchSmallLabel(window.zoneLabel, window.details.level)
    MatchSmallLabel(window.details.rank, window.details.level)
    MatchSmallLabel(window.details.lastOnline, window.details.level)
    window.promoteButton:ClearAllPoints(); window.promoteButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -34, -62)
    window.demoteButton:ClearAllPoints(); window.demoteButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -62)
    local canPromote = MOS.Services.Roster.CanManage("promote", member)
    local canDemote = MOS.Services.Roster.CanManage("demote", member)
    window.promoteButton:SetInactive(not canPromote); window.promoteButton:Show()
    window.demoteButton:SetInactive(not canDemote); window.demoteButton:Show()
    if canPromote then window.promoteButton:Enable() else window.promoteButton:Disable() end
    if canDemote then window.demoteButton:Enable() else window.demoteButton:Disable() end
    local public, officer = window.publicNoteField, window.officerNoteField
    public.title:SetText("Note:")
    MatchSmallLabel(public.title, window.details.level)
    MatchSmallLabel(officer.title, window.details.level)
    public:ClearAllPoints(); public:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -116)
    public:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -116); public:SetHeight(36)
    public.title:ClearAllPoints(); public.title:SetPoint("BOTTOMLEFT", public, "TOPLEFT", 0, 4)
    officer:ClearAllPoints(); officer:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -178)
    officer:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -178); officer:SetHeight(36)
    officer.title:ClearAllPoints(); officer.title:SetPoint("BOTTOMLEFT", officer, "TOPLEFT", 0, 4)
    local canSeeOfficer = MOS.Services.Roster.CanManage("viewOfficerNote")
    window:SetHeight(canSeeOfficer and 258 or 196)
    window.removeButton:SetWidth(96); window.inviteButton:SetWidth(102)
    if MOS.Services.Roster.CanManage("remove", member) then window.removeButton:Enable() else window.removeButton:Disable() end
    if MOS.Services.Roster.CanManage("group", member) then window.inviteButton:Enable() else window.inviteButton:Disable() end
end

function Roster.UpdateDetailsWindow(page, member)
    if not member or MuklaOfficerSuiteDB.playerDetailsStyle ~= "window" then
        if page.detailsWindow then page.detailsWindow.displayedMember = nil; page.detailsWindow:Hide() end
        return
    end
    local window = page.detailsWindow
    if not window then
        window = C.Window.CreateAttached(page, page.detailsOwner or page:GetParent(), 230, 258, function()
            local selected = page.detailsWindow.displayedMember
            if selected then page.rowController.onSelect(selected) end
        end)
        page.detailsWindow = window
        window.detailsWindow = true; window.actionPanel = window; window.controller = page.rowController
        -- The shared note editor and permission binding use these reusable value labels.
        window.notes = C.CreateLabel(window, nil, "OVERLAY", "GameFontHighlightSmall"); window.notes:Hide()
        window.officer = C.CreateLabel(window, nil, "OVERLAY", "GameFontHighlightSmall"); window.officer:Hide()
        local function Action(button, action)
            button:SetScript("OnClick", function()
                if window.displayedMember then window.controller.onAction(action, window.displayedMember) end
            end)
        end
        window.promoteButton = C.CreateArrowButton(window, "up"); Action(window.promoteButton, "promote")
        window.demoteButton = C.CreateArrowButton(window, "down"); Action(window.demoteButton, "demote")
        window.removeButton = C.CreateButton(window, nil, "Remove", 112, 22)
        window.removeButton:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 12, 10); Action(window.removeButton, "remove")
        window.inviteButton = C.CreateButton(window, nil, "Group Invite", 118, 22)
        window.inviteButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -12, 10); Action(window.inviteButton, "group")
        window.zoneLabel = C.CreateComponentLabel(window, "", "orange")
        window:SetScript("OnHide", function()
            if page.noteTarget and page.noteTarget.row == window and page.noteEditor then page.noteEditor:Hide(); page.noteTarget = nil end
        end)
    end
    window.displayedMember = member
    Roster.BindMemberDetails(window, member)
    window:Show()
end
