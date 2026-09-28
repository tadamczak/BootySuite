local MOS = MuklaOfficerSuite
local Settings = MOS.Modules.Settings
local C = MOS.UI.Components

function Settings.CreateProfiles(page, onLoaded)
    local api = MOS.Core.SettingsProfiles
    local view = {}
    view.heading = C.Settings.CreateSectionAccordion(page, "Profile", -10)
    view.content = C.CreateContainer(nil, page)
    view.content:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -36)
    view.content:SetPoint("TOPRIGHT", page, "TOPRIGHT", 0, -36); view.content:SetHeight(64)
    local label = C.CreateComponentLabel(view.content, "Name", "white")
    label:SetPoint("TOPLEFT", view.content, "TOPLEFT", 24, -4)
    view.name = C.CreateFramedEditBox(view.content, nil, 150)
    view.name:SetMaxLetters(64); view.name:SetPoint("LEFT", label, "RIGHT", 8, 0)
    view.select = C.CreateDropdownButton(view.content, nil, "Profiles", 104)
    view.select:SetPoint("LEFT", view.name, "RIGHT", 8, 0)
    view.panel = C.CreateDropdownPanel(page, view.select, 220, 154, 20)
    view.rows, view.first = {}, 1
    local function RefreshChoices()
        view.names = api.List()
        view.first = math.max(1, math.min(view.first, math.max(1, table.getn(view.names) - 5)))
        local index
        for index = 1, 6 do
            local button = view.rows[index]
            local name = view.names[view.first + index - 1]
            button.profileName = name
            if name then button:SetText(name); button:Show() else button:Hide() end
        end
    end
    local index
    for index = 1, 6 do
        local button = C.CreateButton(view.panel, nil, "", 202, 22)
        button:SetPoint("TOPLEFT", view.panel, "TOPLEFT", 8, -8 - (index - 1) * 23)
        button:SetScript("OnClick", function() view.name:SetText(this.profileName); view.panel:Hide() end)
        view.rows[index] = button
    end
    view.panel:EnableMouseWheel(true)
    view.panel:SetScript("OnMouseWheel", function() view.first = view.first - arg1; RefreshChoices() end)
    view.select:SetScript("OnClick", function()
        if view.panel:IsVisible() then view.panel:Hide() else RefreshChoices(); view.panel:Show() end
    end)
    view.status = C.CreateComponentLabel(view.content, "", "white")
    view.status:SetPoint("TOPLEFT", view.content, "TOPLEFT", 24, -36)
    view.status:SetPoint("RIGHT", view.content, "RIGHT", -12, 0); view.status:SetJustifyH("LEFT")
    local previous = view.select
    for _, action in ipairs({ "Add", "Save", "Load", "Export" }) do
        local button = C.CreateButton(view.content, nil, action, 54, 24)
        button.action = action; button:SetPoint("LEFT", previous, "RIGHT", 6, 0)
        button:SetScript("OnClick", function()
            local actionName, name = this.action, view.name:GetText()
            if actionName == "Export" then
                local text, message = api.Export(name)
                if not text then view.status:SetText(message); return end
                if not view.export then
                    view.export = C.CreateTextEditor("MuklaOfficerSuiteProfileExport", "Export profile", 16384)
                    view.export.save:Hide(); view.export.cancel:SetText("Close")
                end
                view.export:Open(text); view.export.edit:HighlightText()
                view.export:SetMessage("Copy the selected text with Ctrl+C.", false)
            else
                local ok, message = api[actionName](name)
                view.status:SetText(message)
                if ok and actionName == "Load" then onLoaded() end
            end
            view.panel:Hide()
        end)
        view[action] = button; previous = button
    end
    view.content:SetScript("OnHide", function() view.panel:Hide(); if view.export then view.export:Hide() end end)
    page.profiles = view
    return view
end

function Settings.ApplyTopSections(page)
    local state = page.topSectionState
    if not state then return end
    local profileHeight = state.profile and 90 or 28
    local uiY = -10 - profileHeight
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
    page.settingsTopOffset = -profileHeight + (state.ui and 0 or 112)
    if page.primarySections and page.raidAccordionControls then
        Settings.ApplyRosterAccordions(page, page.primarySections, page.raidAccordionControls)
    end
end

function Settings.BindTopSections(page, onLoaded)
    page.topSectionState = { profile = true, ui = true, debug = false }
    Settings.CreateProfiles(page, onLoaded)
    page.profiles.heading:SetScript("OnClick", function()
        page.topSectionState.profile = not page.topSectionState.profile; Settings.ApplyTopSections(page)
    end)
    page.uiHeading:SetScript("OnClick", function()
        page.topSectionState.ui = not page.topSectionState.ui; Settings.ApplyTopSections(page)
    end)
    Settings.ApplyTopSections(page)
end
