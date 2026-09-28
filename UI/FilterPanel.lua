local MOS = MuklaOfficerSuite
local UI = MOS.UI

UI.FilterPanel = UI.FilterPanel or {}
local FilterPanel = UI.FilterPanel

local function SortText(a, b)
    return string.lower(a) < string.lower(b)
end

function FilterPanel.Refresh(panel, values, selected, onChanged, dynamicWidth)
    table.sort(values, SortText)
    panel.values = values
    panel.selected = selected
    panel.onChanged = onChanged

    if not panel.selectAll then
        panel.selectAll = UI.CreateButton(panel, nil, "Select all", 82, 18)
        panel.selectAll:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 9)
        panel.selectAll:SetScript("OnClick", function()
            local owner = this:GetParent()
            local optionIndex
            for optionIndex = 1, table.getn(owner.values or {}) do
                owner.selected[owner.values[optionIndex]] = true
                if owner.options[optionIndex] then owner.options[optionIndex]:SetChecked(1) end
            end
            if owner.onChanged then owner.onChanged(true) end
        end)
    end

    local panelWidth = panel:GetWidth()
    if dynamicWidth then
        local widest = 0
        local valueIndex
        for valueIndex = 1, table.getn(values) do widest = math.max(widest, string.len(tostring(values[valueIndex]))) end
        panelWidth = math.max(112, math.min(190, 42 + (widest * 7)))
        panel:SetWidth(panelWidth)
    end
    panel.selectAll:ClearAllPoints()
    panel.selectAll:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 9)
    panel:SetHeight(38 + (table.getn(values) * 20))

    local optionIndex
    for optionIndex = 1, table.getn(values) do
        local checkbox = panel.options[optionIndex]
        if not checkbox then
            checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            checkbox:SetWidth(20)
            checkbox:SetHeight(20)
            checkbox:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10 - ((optionIndex - 1) * 20))
            checkbox.label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
            checkbox.label:SetWidth(80)
            checkbox.label:SetJustifyH("LEFT")
            checkbox:SetScript("OnClick", function()
                local owner = this:GetParent()
                owner.selected[this.value] = this:GetChecked() and true or false
                if owner.onChanged then owner.onChanged(true) end
            end)
            panel.options[optionIndex] = checkbox
        end
        checkbox.value = values[optionIndex]
        checkbox.label:SetText(values[optionIndex])
        checkbox.label:SetWidth(panelWidth - 42)
        checkbox:SetChecked(selected[values[optionIndex]] and true or false)
        checkbox:Show()
    end
    for optionIndex = table.getn(values) + 1, table.getn(panel.options) do
        panel.options[optionIndex]:Hide()
    end
end
