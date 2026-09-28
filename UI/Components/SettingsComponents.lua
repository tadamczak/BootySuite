local MOS = MuklaOfficerSuite

MOS.UI.Components.Settings = MOS.UI.Components.Settings or {}
local Settings = MOS.UI.Components.Settings

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

function Settings.CreateCheckbox(parent, x, y, text, key, onChanged, binding)
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
        binding.ensure()
        binding.set(owner.settingKey, owner:GetChecked() and true or false)
        if owner.onChanged then owner.onChanged(owner.settingKey) end
    end
    button:SetScript("OnShow", function()
        binding.ensure()
        this:SetChecked(binding.get(this.settingKey) and 1 or nil)
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

function Settings.CreateSlider(parent, name, x, y, label, key, minimum, maximum, onChanged, binding)
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
        binding.ensure()
        this:SetValue(binding.get(this.settingKey))
    end)
    slider:SetScript("OnValueChanged", function()
        binding.ensure()
        local value = math.floor(this:GetValue() + 0.5)
        binding.set(this.settingKey, value)
        getglobal(this:GetName() .. "Text"):SetText(this.settingLabel .. ": " .. value)
        if this.onChanged then this.onChanged(this.settingKey) end
    end)
    return slider
end

function Settings.SetSliderEnabled(slider, enabled)
    if not slider then return end
    if slider.Enable and slider.Disable then
        if enabled then slider:Enable() else slider:Disable() end
    else
        slider:EnableMouse(enabled and true or false)
    end
    slider.mosEnabled = enabled and true or false
    slider:SetAlpha(enabled and 1 or 0.42)
    local low = getglobal(slider:GetName() .. "Low")
    local high = getglobal(slider:GetName() .. "High")
    local text = getglobal(slider:GetName() .. "Text")
    local shade = enabled and 1 or 0.5
    if low then low:SetTextColor(shade, shade, shade) end
    if high then high:SetTextColor(shade, shade, shade) end
    if text then
        if enabled then text:SetTextColor(1, 0.82, 0) else text:SetTextColor(shade, shade, shade) end
    end
end

function Settings.CreateColor(parent, x, y, label, key, onChanged, binding)
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
        binding.ensure()
        local color = binding.get(this.settingKey)
        this.swatch:SetTexture(color[1], color[2], color[3], 1)
    end)
    button:SetScript("OnClick", function()
        binding.ensure()
        local owner = this
        local color = binding.get(owner.settingKey)
        local original = { color[1], color[2], color[3] }
        ColorPickerFrame:Hide()
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.opacity = nil
        ColorPickerFrame.opacityFunc = nil
        ColorPickerFrame.previousValues = original
        ColorPickerFrame.func = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            binding.set(owner.settingKey, { r, g, b })
            owner.swatch:SetTexture(r, g, b, 1)
            if owner.onChanged then owner.onChanged(owner.settingKey) end
        end
        ColorPickerFrame.cancelFunc = function()
            binding.set(owner.settingKey, original)
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

function Settings.CreateSavedCheckbox(parent, name, x, y, text, settingKey, tooltipTitle, tooltipText, onChanged, binding)
    local check = MOS.UI.Components.CreateCheckButton(name, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check:SetWidth(24)
    check:SetHeight(24)
    check.settingKey = settingKey
    check.label = MOS.UI.Components.CreateLabel(check, nil, "OVERLAY", "GameFontHighlight")
    check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    check.label:SetText(text)
    check:SetScript("OnShow", function()
        binding.ensure()
        this:SetChecked(binding.get(this.settingKey) and 1 or nil)
    end)
    check.SaveSetting = function(owner)
        binding.ensure()
        binding.set(owner.settingKey, owner:GetChecked() and true or false)
        if onChanged then onChanged(owner.settingKey) end
    end
    check:SetScript("OnClick", function() this:SaveSetting() end)
    check.labelHit = MOS.UI.Components.CreateControl(nil, check)
    check.labelHit:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.labelHit:SetWidth(math.max(18, check.label:GetStringWidth() + 8))
    check.labelHit:SetHeight(24)
    check.labelHit.owner = check
    check.labelHit:SetScript("OnClick", function()
        local owner = this.owner
        owner:SetChecked(not owner:GetChecked())
        owner:SaveSetting()
    end)
    if tooltipTitle then
        MOS.UI.Components.AttachTooltip(check, tooltipTitle, tooltipText)
        MOS.UI.Components.AttachTooltip(check.labelHit, tooltipTitle, tooltipText)
    end
    return check
end

function Settings.CreatePercentageField(parent, name, labelText, x, y, settingKey, fallback, binding)
    local label = MOS.UI.Components.CreateLabel(parent, name .. "Label", "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    local field = MOS.UI.Components.CreateEditField(name, parent, "InputBoxTemplate")
    field:SetWidth(34)
    field:SetHeight(18)
    field:SetPoint("LEFT", label, "RIGHT", 8, 0)
    field:SetAutoFocus(false)
    field:SetMaxLetters(3)
    field.settingKey = settingKey
    field.fallback = fallback
    field:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    field:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    field:SetScript("OnEditFocusLost", function()
        binding.ensure()
        local value = math.max(0, math.min(100, tonumber(this:GetText()) or this.fallback))
        binding.set(this.settingKey, value)
        this:SetText(value)
    end)
    return label, field
end

function Settings.UpdateScroll(viewport, page, pageHeight)
    if not viewport or not page then return end
    page:SetWidth(math.max(640, viewport:GetWidth() - 4))
    page:SetHeight(pageHeight or 960)
    local scrollBar = getglobal(viewport:GetName() .. "ScrollBar")
    local maximum = math.max(0, page:GetHeight() - viewport:GetHeight())
    if scrollBar then
        scrollBar:SetMinMaxValues(0, maximum)
        scrollBar:SetValue(math.max(0, math.min(maximum, viewport:GetVerticalScroll())))
        if maximum > 0 then scrollBar:Show() else scrollBar:Hide() end
    end
    if viewport.UpdateScrollChildRect then viewport:UpdateScrollChildRect() end
end

function Settings.CreateFactory(binding)
    local factory = {}
    factory.CreateCheckbox = function(parent, x, y, text, key, onChanged)
        return Settings.CreateCheckbox(parent, x, y, text, key, onChanged, binding)
    end
    factory.CreateSlider = function(parent, name, x, y, label, key, minimum, maximum, onChanged)
        return Settings.CreateSlider(parent, name, x, y, label, key, minimum, maximum, onChanged, binding)
    end
    factory.CreateColor = function(parent, x, y, label, key, onChanged)
        return Settings.CreateColor(parent, x, y, label, key, onChanged, binding)
    end
    factory.CreateSavedCheckbox = function(parent, name, x, y, text, settingKey, tooltipTitle, tooltipText, onChanged)
        return Settings.CreateSavedCheckbox(parent, name, x, y, text, settingKey, tooltipTitle, tooltipText, onChanged, binding)
    end
    factory.CreatePercentageField = function(parent, name, labelText, x, y, settingKey, fallback)
        return Settings.CreatePercentageField(parent, name, labelText, x, y, settingKey, fallback, binding)
    end
    return factory
end
