local MOS = MuklaOfficerSuite

MOS.UI.Settings = MOS.UI.Settings or {}
local Settings = MOS.UI.Settings

function Settings.CreateSection(parent, title, y)
    local heading = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    heading:SetText(title)
    local rule = parent:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("LEFT", heading, "RIGHT", 10, 0)
    rule:SetPoint("RIGHT", parent, "RIGHT", -12, 0)
    rule:SetHeight(1)
    rule:SetTexture(0.55, 0.42, 0.16, 0.75)
    return heading, rule
end

function Settings.CreateAccordion(parent, text, y)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    button:SetWidth(180)
    button:SetHeight(16)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0, 0, 0, 0)
    button:SetBackdropBorderColor(0, 0, 0, 0)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.label:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.baseText = text
    button.label:SetText("+  " .. text)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    button.rule = parent:CreateTexture(nil, "ARTWORK")
    button.rule:SetTexture(0, 0, 0, 0)
    button.rule:Hide()
    return button
end

function Settings.CreateCheckbox(parent, x, y, text, key, onChanged)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(22)
    button:SetHeight(22)
    button.settingKey = key
    button.onChanged = onChanged
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button, "RIGHT", 2, 0)
    button.label:SetText(text)
    button.SaveSetting = function(owner)
        MOS.Database.Ensure()
        MOS.Database.SetSetting(owner.settingKey, owner:GetChecked() and true or false)
        if owner.onChanged then owner.onChanged(owner.settingKey) end
    end
    button:SetScript("OnShow", function()
        MOS.Database.Ensure()
        this:SetChecked(MuklaOfficerSuiteDB[this.settingKey] and 1 or nil)
    end)
    button:SetScript("OnClick", function() this:SaveSetting() end)
    button.labelHit = CreateFrame("Button", nil, button)
    button.labelHit:SetPoint("LEFT", button, "RIGHT", 1, 0)
    button.labelHit:SetWidth(math.max(18, button.label:GetStringWidth() + 5))
    button.labelHit:SetHeight(22)
    button.labelHit.owner = button
    button.labelHit:SetScript("OnClick", function()
        local owner = this.owner
        owner:SetChecked(not owner:GetChecked())
        owner:SaveSetting()
    end)
    return button
end

function Settings.CreateSlider(parent, name, x, y, label, key, minimum, maximum, onChanged)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(220)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(1)
    slider.settingKey = key
    slider.settingLabel = label
    slider.onChanged = onChanged
    getglobal(name .. "Low"):SetText(tostring(minimum))
    getglobal(name .. "High"):SetText(tostring(maximum))
    slider:SetScript("OnShow", function()
        MOS.Database.Ensure()
        this:SetValue(MuklaOfficerSuiteDB[this.settingKey])
    end)
    slider:SetScript("OnValueChanged", function()
        MOS.Database.Ensure()
        local value = math.floor(this:GetValue() + 0.5)
        MOS.Database.SetSetting(this.settingKey, value)
        getglobal(this:GetName() .. "Text"):SetText(this.settingLabel .. ": " .. value)
        if this.onChanged then this.onChanged(this.settingKey) end
    end)
    return slider
end

function Settings.SetSliderEnabled(slider, enabled)
    if not slider then return end
    if enabled then slider:Enable() else slider:Disable() end
    slider:SetAlpha(enabled and 1 or 0.42)
    local low = getglobal(slider:GetName() .. "Low")
    local high = getglobal(slider:GetName() .. "High")
    local text = getglobal(slider:GetName() .. "Text")
    local shade = enabled and 1 or 0.5
    if low then low:SetTextColor(shade, shade, shade) end
    if high then high:SetTextColor(shade, shade, shade) end
    if text then text:SetTextColor(shade, shade, shade) end
end

function Settings.CreateColor(parent, x, y, label, key, onChanged)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetWidth(176)
    button:SetHeight(20)
    button.settingKey = key
    button.onChanged = onChanged
    button.swatchBorder = CreateFrame("Frame", nil, button)
    button.swatchBorder:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.swatchBorder:SetWidth(20)
    button.swatchBorder:SetHeight(20)
    button.swatchBorder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button.swatchBorder:SetBackdropColor(0, 0, 0, 1)
    button.swatchBorder:SetBackdropBorderColor(0.65, 0.55, 0.32, 1)
    button.swatch = button.swatchBorder:CreateTexture(nil, "ARTWORK")
    button.swatch:SetPoint("TOPLEFT", button.swatchBorder, "TOPLEFT", 3, -3)
    button.swatch:SetPoint("BOTTOMRIGHT", button.swatchBorder, "BOTTOMRIGHT", -3, 3)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button.swatchBorder, "RIGHT", 6, 0)
    button.label:SetText(label)
    button:SetScript("OnShow", function()
        MOS.Database.Ensure()
        local color = MuklaOfficerSuiteDB[this.settingKey]
        this.swatch:SetTexture(color[1], color[2], color[3], 1)
    end)
    button:SetScript("OnClick", function()
        MOS.Database.Ensure()
        local owner = this
        local color = MuklaOfficerSuiteDB[owner.settingKey]
        local original = { color[1], color[2], color[3] }
        ColorPickerFrame:Hide()
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.opacity = nil
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.previousValues = original
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            MOS.Database.SetSetting(owner.settingKey, { r, g, b })
            owner.swatch:SetTexture(r, g, b, 1)
            if owner.onChanged then owner.onChanged(owner.settingKey) end
        end
        ColorPickerFrame.cancelFunc = function()
            MOS.Database.SetSetting(owner.settingKey, original)
            owner.swatch:SetTexture(original[1], original[2], original[3], 1)
            if owner.onChanged then owner.onChanged(owner.settingKey) end
        end
        if ColorPickerFrame.SetParent then ColorPickerFrame:SetParent(UIParent) end
        if ColorPickerFrame.SetToplevel then ColorPickerFrame:SetToplevel(true) end
        ColorPickerFrame:SetFrameStrata("TOOLTIP")
        ColorPickerFrame:SetFrameLevel(10000)
        ColorPickerFrame:SetColorRGB(color[1], color[2], color[3])
        local pickerControls = {
            getglobal("ColorPickerOkayButton") or getglobal("ColorPickerFrameOkayButton"),
            getglobal("ColorPickerCancelButton") or getglobal("ColorPickerFrameCancelButton"),
            getglobal("DL_RedBox"),
            getglobal("DL_GreenBox"),
            getglobal("DL_BlueBox"),
        }
        local pickerIndex
        for pickerIndex = 1, table.getn(pickerControls) do
            local control = pickerControls[pickerIndex]
            if control then
                if control.SetFrameStrata then control:SetFrameStrata("TOOLTIP") end
                if control.SetFrameLevel then control:SetFrameLevel(10000 + pickerIndex) end
                if control.SetToplevel then control:SetToplevel(true) end
                if control.Enable then control:Enable() end
                if control.EnableMouse then control:EnableMouse(true) end
                if control.Raise then control:Raise() end
            end
        end
        if not Settings.colorPickerDismiss then
            local dismiss = CreateFrame("Button", nil, UIParent)
            dismiss:SetAllPoints(UIParent)
            dismiss:SetFrameStrata("FULLSCREEN")
            dismiss:SetFrameLevel(1)
            dismiss:EnableMouse(true)
            dismiss:SetScript("OnClick", function() ColorPickerFrame:Hide(); this:Hide() end)
            dismiss:SetScript("OnUpdate", function() if not ColorPickerFrame:IsVisible() then this:Hide() end end)
            Settings.colorPickerDismiss = dismiss
        end
        Settings.colorPickerDismiss:Show()
        ColorPickerFrame:Show()
        if ColorPickerFrame.Raise then ColorPickerFrame:Raise() end
    end)
    return button
end
