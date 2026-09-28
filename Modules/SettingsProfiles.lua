local MOS = MuklaOfficerSuite
local Settings = MOS.Modules.Settings
local C = MOS.UI.Components

function Settings.CreateProfiles(page, onLoaded)
    local api = MOS.Core.SettingsProfiles
    local view = { rows = {}, first = 1 }
    view.heading = C.Settings.CreateSectionAccordion(page, "Profile", -10)
    view.content = C.CreateContainer(nil, page)
    view.content:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -36)
    view.content:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -36); view.content:SetHeight(130)
    local function Label(text, y, color)
        local label = C.CreateComponentLabel(view.content, text, color or "white")
        label:SetPoint("TOPLEFT", view.content, "TOPLEFT", 24, y); return label
    end
    view.currentLabel = Label("Current profile", -4, "gold")
    view.current = C.CreateReadOnlyInput(view.content, nil, 180)
    view.current:SetHeight(20); view.current:SetPoint("TOPLEFT", view.content, "TOPLEFT", 142, 0)
    Label("Load profile", -32)
    view.select = C.CreateDropdownButton(view.content, nil, "Select profile", 180)
    view.select:SetPoint("TOPLEFT", view.content, "TOPLEFT", 142, -28)
    Label("New profile", -60)
    view.name = C.CreateFramedEditBox(view.content, nil, 180)
    view.name:SetHeight(20); view.name:SetMaxLetters(64); view.name:SetPoint("TOPLEFT", view.content, "TOPLEFT", 142, -56)
    view.loadedLabel = Label("Loaded profile", -88, "gold")
    view.loaded = C.CreateComponentLabel(view.content, "", "white")
    view.loaded:SetPoint("LEFT", view.loadedLabel, "RIGHT", 8, 0)
    view.status = C.CreateComponentLabel(view.content, "", "white")
    view.status:SetPoint("TOPLEFT", view.content, "TOPLEFT", 24, -110)
    view.status:SetPoint("RIGHT", view.content, "RIGHT", -12, 0); view.status:SetJustifyH("LEFT")
    local function Action(action, previous)
        local button = C.CreateButton(view.content, nil, action, 50, 18)
        button:SetPoint("LEFT", previous, "RIGHT", 6, 0); view[action] = button; return button
    end
    Action("Export", Action("Delete", Action("Load", view.select)))
    Action("Save", Action("Add", view.name))
    view.panel = C.CreateDropdownPanel(page, view.select, 220, 154, 20)
    local function RefreshState()
        local current = api.GetCurrent()
        view.current:SetValueText(current); view.loaded:SetText(current)
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
        local function Apply()
            local ok, message = api[action](target)
            view.status:SetText(message)
            if ok then
                if action == "Add" then view.name:SetText(""); view.selected = api.GetCurrent() end
                RefreshState(); onLoaded()
            end
        end
        if api.IsDirty() then
            Confirm("Do you want to save current profile " .. api.GetCurrent() .. "?", function()
                local ok, message = api.SaveCurrent()
                if ok then Apply() else view.status:SetText(message) end
            end, Apply)
        else Apply() end
    end
    view.Load:SetScript("OnClick", function() if view.selected then Switch("Load", view.selected) end end)
    view.Add:SetScript("OnClick", function()
        local name = view.name:GetText()
        local ok, message = api.CanAdd(name)
        if ok then Switch("Add", name) else view.status:SetText(message) end
    end)
    view.Save:SetScript("OnClick", function()
        local _, message = api.SaveCurrent(); view.status:SetText(message); RefreshState()
    end)
    view.Delete:SetScript("OnClick", function()
        local selected = view.selected
        if not selected then return end
        Confirm("Delete profile " .. selected .. "?", function()
            local _, message = api.Delete(selected)
            view.status:SetText(message); view.selected = nil; RefreshState()
        end)
    end)
    view.Export:SetScript("OnClick", function()
        if not view.selected then return end
        local text, message = api.Export(view.selected)
        if not text then view.status:SetText(message); return end
        if not view.export then
            view.export = C.CreateTextEditor("MuklaOfficerSuiteProfileExport", "Export profile", 16384)
            view.export.save:Hide(); view.export.cancel:SetText("Close")
        end
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
    local profileHeight = state.profile and 156 or 28
    local uiY = -10 - profileHeight
    page.uiHeadingY = uiY
    page.profiles.heading.label:SetText((state.profile and "-  " or "+  ") .. "Profile")
    if state.profile then page.profiles.content:Show() else page.profiles.content:Hide() end
    page.uiHeading.label:SetText((state.ui and "-  " or "+  ") .. "UI")
    page.uiHeading:ClearAllPoints(); page.uiHeading:SetPoint("TOPLEFT", page, "TOPLEFT", 12, uiY)
    page.uiContent:ClearAllPoints()
    page.uiContent:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -profileHeight)
    page.uiContent:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -profileHeight)
    if state.ui then page.uiContent:Show() else
        page.uiContent:Hide(); page.skinControl.panel:Hide(); page.menuStyleControl.panel:Hide()
    end
    page.settingsTopOffset = -profileHeight
    if page.primarySections and page.raidAccordionControls then
        Settings.ApplyRosterAccordions(page, page.primarySections, page.raidAccordionControls)
    end
end

function Settings.BindTopSections(page, onLoaded)
    page.topSectionState = { profile = false, ui = false, debug = false }
    Settings.CreateProfiles(page, onLoaded)
    page.profiles.heading:SetScript("OnClick", function()
        page.topSectionState.profile = not page.topSectionState.profile; Settings.ApplyTopSections(page)
    end)
    page.uiHeading:SetScript("OnClick", function()
        page.topSectionState.ui = not page.topSectionState.ui; Settings.ApplyTopSections(page)
    end)
    Settings.ApplyTopSections(page)
end
