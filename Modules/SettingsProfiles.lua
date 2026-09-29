local MOS = MuklaOfficerSuite
local Settings = MOS.Modules.Settings
local C = MOS.UI.Components

function Settings.CreateProfiles(page, onLoaded)
    local api = MOS.Core.SettingsProfiles
    local view = { rows = {}, first = 1 }
    view.heading = C.Settings.CreateSectionAccordion(page, "Profile", -10)
    view.content = C.CreateContainer(nil, page)
    view.general = C.Settings.CreateAccordion(page, "General", -38)
    view.content:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -64)
    view.content:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -64); view.content:SetHeight(82)
    local function Label(text, y, color)
        local label = C.CreateComponentLabel(view.content, text, color or "white")
        label:SetPoint("TOPLEFT", view.content, "TOPLEFT", 24, y); return label
    end
    view.currentLabel = Label("Current profile", -4, "white")
    view.current = C.CreateComponentLabel(view.content, "", "gold")
    view.current:SetWidth(180); view.current:SetHeight(20); view.current:SetJustifyH("LEFT"); view.current:SetPoint("TOPLEFT", view.content, "TOPLEFT", 126, 0)
    Label("Load profile", -32)
    view.select = C.CreateDropdownButton(view.content, nil, "Select profile", 180)
    view.select:SetPoint("TOPLEFT", view.content, "TOPLEFT", 126, -28)
    Label("New profile", -60)
    view.name = C.CreateFramedEditBox(view.content, nil, 180)
    view.name:SetHeight(20); view.name:SetMaxLetters(64); view.name:SetPoint("TOPLEFT", view.content, "TOPLEFT", 126, -56)
    local function Action(action, previous)
        local button = C.CreateButton(view.content, nil, action, 50, 18)
        C.SizeClassicButton(button, 50, 18, 0.8)
        button:SetPoint("LEFT", previous, "RIGHT", 6, 0); view[action] = button; return button
    end
    Action("Export", Action("Delete", Action("Load", view.select)))
    Action("Add", view.name)
    Action("Save", view.current)
    local function Status(button)
        local label = C.CreateColumnLabel(view.content, "", "gold")
        label:SetPoint("LEFT", button, "RIGHT", 8, 0)
        label:SetPoint("RIGHT", view.content, "RIGHT", -12, 0)
        label:SetHeight(20); label:SetJustifyH("LEFT")
        return label
    end
    view.saveStatus = Status(view.Save)
    view.loadStatus = Status(view.Export)
    view.addStatus = Status(view.Add)
    local function ClearStatus()
        view.saveStatus:SetText(""); view.loadStatus:SetText(""); view.addStatus:SetText("")
    end
    local function CommitPending()
        local controls = page.raidAccordionControls
        if not controls then return end
        if controls.opacityField and controls.opacityField.mosEditing then controls.opacityField:CommitValue(); controls.opacityField:ClearFocus() end
        if controls.focusField and controls.focusField.mosEditing then controls.focusField:CommitValue(); controls.focusField:ClearFocus() end
    end
    view.panel = C.CreateDropdownPanel(page, view.select, 220, 154, 20)
    local function RefreshState()
        local current = api.GetCurrent()
        view.current:SetText(current)
        if view.selected and not api.Exists(view.selected) then view.selected = nil end
        view.select.label:SetText(view.selected or "Select profile")
        C.SetButtonEnabled(view.Load, view.selected ~= nil)
        C.SetButtonEnabled(view.Delete, view.selected ~= nil)
        C.SetButtonEnabled(view.Export, view.selected ~= nil)
    end
    local function RefreshChoices()
        view.names = api.List()
        view.first = math.max(1, math.min(view.first, math.max(1, table.getn(view.names) - 5)))
        local index
        for index = 1, 6 do
            local button, name = view.rows[index], view.names[view.first + index - 1]
            button.profileName = name
            if name then button:SetText(name); button:Show() else button:Hide() end
        end
    end
    local index
    for index = 1, 6 do
        local button = C.CreateButton(view.panel, nil, "", 202, 22)
        button:SetPoint("TOPLEFT", view.panel, "TOPLEFT", 8, -8 - (index - 1) * 23)
        button:SetScript("OnClick", function() view.selected = this.profileName; RefreshState(); view.panel:Hide() end)
        view.rows[index] = button
    end
    view.panel:EnableMouseWheel(true)
    view.panel:SetScript("OnMouseWheel", function() view.first = view.first - arg1; RefreshChoices() end)
    view.select:SetScript("OnClick", function()
        if view.panel:IsVisible() then view.panel:Hide() else RefreshChoices(); view.panel:Show() end
    end)
    local function Confirm(message, yes, no)
        if not view.confirm then view.confirm = C.CreateConfirmation("MuklaOfficerSuiteProfileConfirm") end
        view.panel:Hide(); view.confirm:Open(message, yes, no)
    end
    local function Switch(action, target)
        ClearStatus()
        CommitPending()
        local status = action == "Add" and view.addStatus or view.loadStatus
        local function Apply()
            local ok, message = api[action](target)
            status:SetText(ok and action == "Add" and ("Added new profile: " .. api.GetCurrent()) or message)
            if ok then
                if action == "Add" then view.name:SetText(""); view.selected = api.GetCurrent() end
                RefreshState(); onLoaded()
            end
        end
        if api.IsDirty() then
            Confirm("Do you want to save current profile " .. api.GetCurrent() .. "?", function()
                local ok, message = api.SaveCurrent()
                view.saveStatus:SetText(message)
                if ok then Apply() end
            end, Apply)
        else Apply() end
    end
    view.Load:SetScript("OnClick", function() if view.selected then Switch("Load", view.selected) end end)
    view.Add:SetScript("OnClick", function()
        ClearStatus()
        local name = view.name:GetText()
        local ok, message = api.CanAdd(name)
        if ok then Switch("Add", name) else view.addStatus:SetText(message) end
    end)
    view.Save:SetScript("OnClick", function()
        ClearStatus()
        CommitPending()
        local _, message = api.SaveCurrent(); view.saveStatus:SetText(message); RefreshState()
    end)
    view.Delete:SetScript("OnClick", function()
        local selected = view.selected
        if not selected then return end
        ClearStatus()
        Confirm("Delete profile " .. selected .. "?", function()
            local _, message = api.Delete(selected)
            view.loadStatus:SetText(message); view.selected = nil; RefreshState()
        end)
    end)
    view.Export:SetScript("OnClick", function()
        if not view.selected then return end
        ClearStatus()
        local text, message = api.Export(view.selected)
        if not text then view.loadStatus:SetText(message); return end
        if not view.export then
            view.export = C.CreateTextEditor("MuklaOfficerSuiteProfileExport", "Export profile", 16384)
            view.export.save:Hide(); view.export.cancel:SetText("Close")
        end
        view.loadStatus:SetText("Exported profile: " .. view.selected)
        view.export:Open(text); view.export.edit:HighlightText()
        view.export:SetMessage("Copy the selected text with Ctrl+C.", false); view.panel:Hide()
    end)
    view.content:SetScript("OnHide", function()
        view.panel:Hide()
        if view.export then view.export:Hide() end
        if view.confirm then view.confirm:Hide() end
    end)
    view.RefreshState = RefreshState
    RefreshState(); page.profiles = view
    return view
end

function Settings.ApplyTopSections(page)
    local state = page.topSectionState
    if not state then return end
    local profileHeight = state.profile and (state.profileGeneral and 136 or 56) or 28
    local uiY = -10 - profileHeight
    page.uiHeadingY = uiY
    page.profiles.heading.label:SetText((state.profile and "-  " or "+  ") .. "Profile")
    page.profiles.general.label:SetText((state.profileGeneral and "-  " or "+  ") .. "General")
    if state.profile then page.profiles.general:Show() else page.profiles.general:Hide() end
    if state.profile and state.profileGeneral then page.profiles.content:Show() else page.profiles.content:Hide() end
    page.uiHeading.label:SetText((state.ui and "-  " or "+  ") .. "UI")
    page.uiHeading:ClearAllPoints(); page.uiHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, uiY)
    page.uiContent:ClearAllPoints()
    page.uiContent:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -profileHeight)
    page.uiContent:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -profileHeight)
    if state.ui then page.uiContent:Show() else
        page.uiContent:Hide(); page.skinControl.panel:Hide(); page.menuStyleControl.panel:Hide()
    end
    page.settingsTopOffset = -profileHeight - 28 - 56
    if page.primarySections and page.raidAccordionControls then
        Settings.ApplyRosterAccordions(page, page.primarySections, page.raidAccordionControls)
    end
end

function Settings.BindTopSections(page, onLoaded)
    page.topSectionState = { profile = false, profileGeneral = true, ui = false, debug = false }
    Settings.CreateProfiles(page, onLoaded)
    page.profiles.general:SetScript("OnClick", function()
        page.topSectionState.profileGeneral = not page.topSectionState.profileGeneral; Settings.ApplyTopSections(page)
    end)
    page.profiles.heading:SetScript("OnClick", function()
        page.topSectionState.profile = not page.topSectionState.profile; Settings.ApplyTopSections(page)
    end)
    page.uiHeading:SetScript("OnClick", function()
        page.topSectionState.ui = not page.topSectionState.ui; Settings.ApplyTopSections(page)
    end)
    Settings.ApplyTopSections(page)
end
