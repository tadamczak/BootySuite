local MOS = MuklaOfficerSuite
local Roster = MOS.Modules.RosterManagement
local C = MOS.UI.Components

local function Place(window, label, y)
    label:ClearAllPoints()
    label:SetPoint("TOPLEFT", window, "TOPLEFT", 12, y)
    label:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, y)
end

function Roster.LayoutDetailsWindow(window, member)
    Place(window, window.details.name, -12)
    window.details.name:SetPoint("TOPRIGHT", window, "TOPRIGHT", -34, -12)
    Place(window, window.details.level, -31)
    Place(window, window.zoneLabel, -52)
    window.zoneLabel:SetText("Zone: |cffffffff" .. (member.zone or "Unknown") .. "|r")
    Place(window, window.details.rank, -72)
    window.details.rank:SetPoint("TOPRIGHT", window, "TOPRIGHT", -64, -72)
    Place(window, window.details.lastOnline, -92)
    window.promoteButton:ClearAllPoints(); window.promoteButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -34, -68)
    window.demoteButton:ClearAllPoints(); window.demoteButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -10, -68)
    local public, officer = window.publicNoteField, window.officerNoteField
    public:ClearAllPoints(); public:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -132)
    public:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -132); public:SetHeight(52)
    officer:ClearAllPoints(); officer:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -214)
    officer:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -214); officer:SetHeight(52)
    local canSeeOfficer = MOS.Services.Roster.CanManage("viewOfficerNote")
    window:SetHeight(canSeeOfficer and 310 or 228)
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
        window = C.Window.CreateAttached(page, page.detailsOwner or page:GetParent(), 260, 310, function()
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
