local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components

function UI.CreateResizeGrip(parent)
    local grip = UI.CreateControl(nil, parent)
    grip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -7, 7)
    grip:SetWidth(18); grip:SetHeight(18)
    grip:SetFrameLevel(parent:GetFrameLevel() + 100)
    grip.texture = grip:CreateTexture(nil, "OVERLAY")
    local function ApplySkin(skin)
        grip.texture:ClearAllPoints()
        if skin == "classic" then
            grip.texture:SetTexture(UI.ClassicAsset("Icons\\resize.tga"))
            grip.texture:SetVertexColor(1, 0.78, 0.24)
            grip.texture:SetPoint("CENTER", grip, "CENTER", 0, 0)
            grip.texture:SetWidth(13); grip.texture:SetHeight(13)
        else
            grip.texture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
            grip.texture:SetVertexColor(1, 1, 1); grip.texture:SetAllPoints(grip)
        end
    end
    ApplySkin(UI.IsClassicSkin() and "classic" or "default")
    UI.RegisterSkinCallback(ApplySkin)
    return grip
end

local function FinishClippedLayout()
    local viewport = this
    viewport:SetScript("OnUpdate", nil)
    UI.RefreshClippedContent(viewport, true)
end

function UI.RefreshClippedContent(viewport, settled)
    viewport.content:SetWidth(math.max(1, viewport:GetWidth()))
    if viewport.UpdateScrollChildRect then viewport:UpdateScrollChildRect() end
    viewport:SetVerticalScroll(math.max(0, math.min(viewport:GetVerticalScroll(), math.max(0, viewport.content:GetHeight() - viewport:GetHeight()))))
    if not settled and viewport:IsVisible() then viewport:SetScript("OnUpdate", FinishClippedLayout) end
end

function UI.CreateClippedContent(parent, contentHeight)
    local viewport = UI.CreateScrollFrame(nil, parent)
    local content = UI.CreateContainer(nil, viewport)
    content:SetHeight(contentHeight); viewport:SetScrollChild(content)
    viewport.content = content
    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", function()
        local maximum = math.max(0, this.content:GetHeight() - this:GetHeight())
        this:SetVerticalScroll(math.max(0, math.min(maximum, this:GetVerticalScroll() - arg1 * 24)))
    end)
    viewport:SetScript("OnShow", function() UI.RefreshClippedContent(this) end)
    viewport:SetScript("OnHide", function() this:SetScript("OnUpdate", nil) end)
    viewport:SetScript("OnSizeChanged", function()
        UI.RefreshClippedContent(this)
    end)
    return viewport, content
end

function UI.ShortenText(text, length)
    text = tostring(text or "")
    if string.len(text) > length then return string.sub(text, 1, length - 1) .. "~" end
    return text
end

local itemQualityHex = {
    [0] = "ff9d9d9d", [1] = "ffffffff", [2] = "ff1eff00", [3] = "ff0070dd",
    [4] = "ffa335ee", [5] = "ffff8000",
}

function UI.GetItemLabel(itemId)
    local itemName, _, itemQuality = GetItemInfo(itemId)
    if not itemName then return "|cffffffff[Item " .. itemId .. "]|r" end
    return "|c" .. (itemQualityHex[tonumber(itemQuality) or 1] or "ffffffff") .. "[" .. itemName .. "]|r"
end

function UI.AnchorTooltipRightOfCursor(owner)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale() or 1
    GameTooltip:SetOwner(owner, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x / scale) + 18, (y / scale) + 10)
end

function UI.ShowItemTooltip(owner)
    if not owner or not owner.itemId then return end
    UI.AnchorTooltipRightOfCursor(owner); GameTooltip:SetHyperlink("item:" .. owner.itemId .. ":0:0:0"); GameTooltip:Show()
    local texture = type(GetItemIcon) == "function" and GetItemIcon(owner.itemId) or nil
    if not texture then local _, _, _, _, _, _, _, _, _, cachedTexture = GetItemInfo(owner.itemId); texture = cachedTexture end
    if owner.iconRegion and texture then owner.iconRegion:SetTexture(texture) end
    if owner.label then owner.label:SetText((owner.labelPrefix or "") .. UI.GetItemLabel(owner.itemId) .. (owner.labelSuffix or "")) end
end

function UI.HandleItemClick(owner)
    if not owner or not owner.itemId then return false end
    local itemName, _, itemQuality = GetItemInfo(owner.itemId)
    itemName = itemName or owner.itemName
    if not itemName then
        UI.ShowItemTooltip(owner)
        itemName, _, itemQuality = GetItemInfo(owner.itemId)
    end
    local itemLink
    if itemName then
        local _, _, _, qualityColor = GetItemQualityColor(tonumber(itemQuality) or 1)
        local colorCode = qualityColor or "|cffffffff"
        if string.sub(colorCode, 1, 2) ~= "|c" then colorCode = "|cffffffff" end
        itemLink = "\124" .. string.sub(colorCode, 2) .. "\124Hitem:" .. owner.itemId .. ":0:0:0\124h[" .. itemName .. "]\124h\124r"
    end
    if type(IsShiftKeyDown) == "function" and IsShiftKeyDown() then
        if not itemLink then return true end
        if WIM_EditBoxInFocus then WIM_EditBoxInFocus:Insert(itemLink)
        elseif MessageBox and MessageBox.isInputFocused and MessageBox.whisperInput then MessageBox.whisperInput:Insert(itemLink)
        elseif ChatFrameEditBox and ChatFrameEditBox.Insert then ChatFrameEditBox:Insert(itemLink)
        elseif type(ChatEdit_InsertLink) == "function" then ChatEdit_InsertLink(itemLink) end
        return true
    end
    if type(IsControlKeyDown) == "function" and IsControlKeyDown() and type(DressUpItemLink) == "function" then
        if not itemLink then return true end
        DressUpItemLink(itemLink); return true
    end
    UI.ShowItemTooltip(owner)
    return true
end

function UI.ApplySelectionListStyle(buttons, items, selectedId, loadButton)
    local selectedAvailable = false
    local selectedColors = UI.Theme.colors.rowSelected
    local normalColors = UI.Theme.colors.button
    local index
    for index = 1, table.getn(buttons) do
        local selected = items[index] and items[index].id == selectedId
        if selected then selectedAvailable = true end
        local color = selected and selectedColors or normalColors
        local border = selected and { 0.85, 0.68, 0.22, 1 } or { 0.48, 0.38, 0.20, 1 }
        if not buttons[index].mosClassicKeepNormalSurface then
        buttons[index]:SetBackdropColor(color[1], color[2], color[3], color[4])
        buttons[index]:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
        end
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(buttons[index], selected) end
        if buttons[index].mosClassicKeepNormalSurface then UI.ApplyDropdownChoiceSurface(buttons[index]) end
        -- Hover handlers restore mosNormalBorder on mouse leave. Keep that
        -- persistent state aligned with the current selection style.
        if buttons[index].mosNormalBorder and not buttons[index].mosClassicKeepNormalSurface then buttons[index].mosNormalBorder = border end
    end
    if loadButton then UI.SetButtonEnabled(loadButton, selectedAvailable) end
    return selectedAvailable
end

function UI.CreateDropdownButton(parent, name, text, width)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(width or 84); button:SetHeight(19)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.08, 0.07, 0.05, 0.95)
    button:SetBackdropBorderColor(0.42, 0.35, 0.20, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local font, size, flags = button.label:GetFont()
    if font then button.label:SetFont(font, size + math.min(0, UI.GetTextSizeDelta(parent) + 1), flags) end
    button.label:SetPoint("LEFT", button, "LEFT", 8, 0); button.label:SetText(text)
    button.SetText = function(self, value) self.label:SetText(value) end
    button.GetText = function(self) return self.label:GetText() end
    button.arrow = button:CreateTexture(nil, "OVERLAY")
    button.arrow:SetWidth(16); button.arrow:SetHeight(16); button.arrow:SetPoint("RIGHT", button, "RIGHT", -5, 0)
    button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    button.arrow:SetTexCoord(0.20, 0.80, 0.20, 0.80)
    return button
end

function UI.RefreshDropdownLayers(panel, toggle)
    local strata = toggle:GetFrameStrata()
    local level = math.max(toggle:GetFrameLevel(), toggle:GetParent():GetFrameLevel()) + 20
    panel:SetFrameStrata(strata); panel:SetFrameLevel(level)
    panel.dismiss:SetFrameStrata(strata); panel.dismiss:SetFrameLevel(level - 1)
    local index
    for index = 1, table.getn(panel.options) do
        local option = panel.options[index]
        option:SetFrameStrata(strata); option:SetFrameLevel(level + 1)
        if option.labelHit then option.labelHit:SetFrameStrata(strata); option.labelHit:SetFrameLevel(level + 2) end
    end
    if panel.selectAll then panel.selectAll:SetFrameStrata(strata); panel.selectAll:SetFrameLevel(level + 1) end
end

function UI.CreateDropdownPanel(parent, toggle, width, height, levelOffset)
    local panel = CreateFrame("Frame", nil, UIParent)
    panel.mosTextSizeDelta = UI.GetTextSizeDelta(parent)
    panel:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(width or 130); panel:SetHeight(height or 230)
    if panel.SetFrameStrata and toggle.GetFrameStrata then panel:SetFrameStrata(toggle:GetFrameStrata()) end
    panel:SetFrameLevel(math.max(parent:GetFrameLevel(), toggle:GetFrameLevel()) + (levelOffset or 50) + 100)
    if panel.SetToplevel then panel:SetToplevel(true) end
    panel:EnableMouse(true)
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    panel:SetBackdropColor(0.04, 0.03, 0.02, 0.98)
    UI.RegisterDialogSurface(panel, "panel", { 0.04, 0.03, 0.02, 0.98 })
    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    if dismiss.SetFrameStrata and toggle.GetFrameStrata then dismiss:SetFrameStrata(toggle:GetFrameStrata()) end
    dismiss:SetFrameLevel(panel:GetFrameLevel() - 1)
    dismiss:EnableMouse(true)
    dismiss:SetScript("OnClick", function() panel:Hide() end)
    dismiss:Hide()
    panel.dismiss = dismiss
    panel.options = {}
    panel:SetScript("OnShow", function() UI.RefreshDropdownLayers(panel, toggle); dismiss:Show() end)
    panel:SetScript("OnHide", function() dismiss:Hide() end)
    panel:Hide()
    return panel
end

function UI.StyleDropdownChoice(button)
    if UI.SetClassicButtonCompact then UI.SetClassicButtonCompact(button, true) end
    if UI.AttachGoldHoverBorder then UI.AttachGoldHoverBorder(button, 0.35, 0.35, 0.35, 1) end
    if button.label and button.label.GetFont then
        local font, _, flags = button.label:GetFont()
        if font then button.label:SetFont(font, 9 + math.min(0, UI.GetTextSizeDelta(button) + 1), flags) end
    end
    return button
end

function UI.CreateSearchBox(parent, name, width)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetWidth(width or 178); box:SetHeight(20); box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    box:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    return box
end

function UI.CreateFramedEditBox(parent, name, width)
    local box = CreateFrame("EditBox", name, parent)
    box:SetWidth(width or 92); box:SetHeight(24); box:SetAutoFocus(false); box:SetFontObject(GameFontHighlightSmall)
    UI.ApplyTextSizeDelta(box, parent)
    box:SetTextInsets(7, 7, 2, 2)
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    box:SetBackdropColor(0.018, 0.018, 0.016, 1); box:SetBackdropBorderColor(0.48, 0.34, 0.10, 1)
    box:SetScript("OnEscapePressed", function() this:ClearFocus() end); box:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    return box
end

function UI.CreateDatePicker(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(232); frame:SetHeight(206); frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(235); frame:EnableMouse(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 14, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    frame:SetBackdropColor(0.025, 0.025, 0.022, 1)
    UI.RegisterDialogSurface(frame, "panel")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame.previous = UI.CreateButton(frame, nil, "<", 24, 22); frame.previous:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
    frame.next = UI.CreateButton(frame, nil, ">", 24, 22); frame.next:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    frame.monthLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.monthLabel:SetPoint("LEFT", frame.previous, "RIGHT", 5, 0); frame.monthLabel:SetPoint("RIGHT", frame.next, "LEFT", -5, 0); frame.monthLabel:SetJustifyH("CENTER")
    local weekdayNames = { "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" }
    local index
    for index = 1, 7 do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); label:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + ((index - 1) * 30), -41); label:SetWidth(28); label:SetJustifyH("CENTER"); label:SetText(weekdayNames[index])
    end
    frame.days = {}
    for index = 1, 42 do
        local column, row = math.mod(index - 1, 7), math.floor((index - 1) / 7)
        local button = UI.CreateButton(frame, nil, "", 28, 22); button:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (column * 30), -57 - (row * 23)); button.datePicker = frame
        button:SetScript("OnClick", function()
            local picker = this.datePicker
            if this.day and picker.target then picker.target:SetText(string.format("%04d-%02d-%02d", picker.year, picker.month, this.day)); picker:Hide() end
        end)
        frame.days[index] = button
    end
    frame.Refresh = function(self)
        local nextYear, nextMonth = self.year, self.month + 1
        if nextMonth > 12 then nextMonth = 1; nextYear = nextYear + 1 end
        local lastStamp = time({ year = nextYear, month = nextMonth, day = 1, hour = 12 }) - 86400
        local daysInMonth = tonumber(date("%d", lastStamp)) or 30
        local firstWeekday = tonumber(date("%w", time({ year = self.year, month = self.month, day = 1, hour = 12 }))) or 0
        self.monthLabel:SetText(date("%B %Y", time({ year = self.year, month = self.month, day = 1, hour = 12 })))
        local buttonIndex
        for buttonIndex = 1, table.getn(self.days) do
            local day = buttonIndex - firstWeekday
            local button = self.days[buttonIndex]
            if day >= 1 and day <= daysInMonth then button.day = day; button:SetText(day); button:Show() else button.day = nil; button:Hide() end
        end
    end
    frame.ChangeMonth = function(self, delta)
        self.month = self.month + delta
        if self.month < 1 then self.month = 12; self.year = self.year - 1 elseif self.month > 12 then self.month = 1; self.year = self.year + 1 end
        self:Refresh()
    end
    frame.previous:SetScript("OnClick", function() frame:ChangeMonth(-1) end); frame.next:SetScript("OnClick", function() frame:ChangeMonth(1) end)
    frame.Open = function(self, owner, target)
        self.target = target
        local value = target and target:GetText() or ""
        local _, _, year, month = string.find(value, "^(%d%d%d%d)%-(%d%d)%-%d%d$")
        local current = date("*t")
        self.year = tonumber(year) or current.year; self.month = tonumber(month) or current.month
        self:ClearAllPoints(); self:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -3); self:Refresh(); self:Show()
    end
    frame:Hide()
    return frame
end

function UI.CreateTextPrompt(name, titleText, labelText, acceptText, onAccept, maxLetters)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(360); frame:SetHeight(145); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(220); frame:EnableMouse(true)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    frame:SetBackdropColor(0.025, 0.025, 0.022, 1)
    UI.RegisterDialogSurface(frame, "panel")
    frame.title = UI.CreateHeading(frame, "", 2, "orange")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16); frame.title:SetText(titleText or "Enter value")
    frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -43); frame.label:SetText(labelText or "Value")
    frame.edit = UI.CreateSearchBox(frame, nil, 320)
    frame.edit:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -61); frame.edit:SetMaxLetters(maxLetters or 48)
    frame.message = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.message:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 20); frame.message:SetWidth(170); frame.message:SetJustifyH("LEFT")
    frame.accept = UI.CreateButton(frame, nil, acceptText or "OK", 72, 22)
    frame.accept:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -92, 16)
    frame.cancel = UI.CreateButton(frame, nil, "Cancel", 72, 22)
    frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 16)
    local function Submit()
        frame.message:SetText("")
        local accepted, message = onAccept(frame.edit:GetText() or "")
        if accepted then frame:Hide() else frame.message:SetText(message or "Invalid value"); frame.message:SetTextColor(1, 0.25, 0.2) end
    end
    frame.accept:SetScript("OnClick", Submit); frame.edit:SetScript("OnEnterPressed", Submit)
    frame.edit:SetScript("OnEscapePressed", function() this:ClearFocus(); frame:Hide() end)
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.Open = function(self) self.edit:SetText(""); self.message:SetText(""); self:Show(); self.edit:SetFocus() end
    frame:Hide()
    return frame
end

local deleteIconTint = {0.72, 0.70, 0.8}
function UI.CreateDeleteButton(parent, name, size, iconInset)
    return UI.CreateIconButton(parent, name, "Interface\\AddOns\\MuklaOfficerSuite\\Assets\\DeleteRaid", size, iconInset, deleteIconTint)
end

function UI.CreateIconButton(parent, name, texturePath, size, iconInset, tint)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(size or 20); button:SetHeight(size or 20)
    local normal = button:CreateTexture(nil, "ARTWORK")
    local inset = tonumber(iconInset) or 0
    local red, green, blue = tint and tint[1] or 1, tint and tint[2] or 1, tint and tint[3] or 1
    normal:SetVertexColor(red, green, blue)
    normal:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset); normal:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset); normal:SetTexture(texturePath)
    normal:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetNormalTexture(normal)
    local disabled = button:CreateTexture(nil, "ARTWORK")
    disabled:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset); disabled:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset); disabled:SetTexture(texturePath); disabled:SetTexCoord(0.08, 0.92, 0.08, 0.92); disabled:SetVertexColor(0.35, 0.35, 0.35)
    button:SetDisabledTexture(disabled)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button); highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(highlight)
    button.SetInactive = function(self, inactive)
        self.inactive = inactive and true or false
        local shade = self.inactive and 0.35 or 1
        normal:SetVertexColor(red * shade, green * shade, blue * shade)
        highlight:SetAlpha(self.inactive and 0 or 1)
    end
    button:SetScript("OnMouseDown", function()
        if not this.inactive then normal:SetVertexColor(red * 0.55, green * 0.55, blue * 0.55) end
    end)
    button:SetScript("OnMouseUp", function()
        local shade = this.inactive and 0.35 or 1
        normal:SetVertexColor(red * shade, green * shade, blue * shade)
    end)
    return button
end

function UI.CreateReadOnlyInput(parent, name, width)
    local field = UI.CreateFramedEditBox(parent, name, width)
    field.mosReadOnlyValue = ""
    field.SetValueText = function(self, value) self.mosReadOnlyValue = value or ""; self:SetText(self.mosReadOnlyValue) end
    field:SetScript("OnTextChanged", function()
        if this:GetText() ~= this.mosReadOnlyValue then this:SetText(this.mosReadOnlyValue) end
    end)
    return field
end

function UI.CreateConfirmation(name)
    local frame = UI.CreateTextPrompt(name, "Confirm", "", "No", function() return true end)
    frame:SetWidth(440); frame:SetHeight(150); frame:SetFrameLevel(600)
    frame.edit:Hide(); frame.message:Hide()
    frame.label:SetWidth(404); frame.label:SetHeight(56); frame.label:SetJustifyH("LEFT")
    frame.no, frame.yes = frame.accept, frame.cancel
    frame.no:SetFrameLevel(601); frame.yes:SetFrameLevel(601)
    frame.yes:SetText("Yes")
    local blocker = UI.CreateControl(nil, UIParent)
    blocker:SetAllPoints(UIParent); blocker:SetFrameStrata("FULLSCREEN_DIALOG"); blocker:SetFrameLevel(599); blocker:EnableMouse(true); blocker:Hide()
    frame:SetScript("OnHide", function() blocker:Hide(); frame.onYes = nil; frame.onNo = nil end)
    frame.no:SetScript("OnClick", function() local callback = frame.onNo; frame:Hide(); if callback then callback() end end)
    frame.yes:SetScript("OnClick", function() local callback = frame.onYes; frame:Hide(); if callback then callback() end end)
    frame.close = UI.CreateWindowButton(frame, nil, "close")
    frame.close:SetFrameLevel(601)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12); frame.close:SetScript("OnClick", function() frame:Hide() end)
    frame.Open = function(self, message, onYes, onNo)
        self.label:SetText(message); self.onYes = onYes; self.onNo = onNo
        blocker:Show(); self:Show()
    end
    return frame
end

function UI.AttachTooltip(frame, title, description, highlight)
    local onEnter, onLeave = frame:GetScript("OnEnter"), frame:GetScript("OnLeave")
    frame:SetScript("OnEnter", function()
        if onEnter then onEnter() end
        if highlight then this:LockHighlight() end
        UI.AnchorTooltipRightOfCursor(this)
        GameTooltip:AddLine(type(title) == "function" and title() or title, 1, 0.82, 0)
        GameTooltip:AddLine(type(description) == "function" and description() or description, 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() if onLeave then onLeave() end; if highlight then this:UnlockHighlight() end; GameTooltip:Hide() end)
    return frame
end

function UI.KeepTooltipAboveWindows(tooltip)
    if not tooltip or tooltip.mosLayerHook then return end
    tooltip.mosLayerHook = true
    local previous = tooltip:GetScript("OnShow")
    tooltip:SetScript("OnShow", function()
        if previous then previous() end
        tooltip:SetFrameStrata("TOOLTIP")
    end)
    tooltip:SetFrameStrata("TOOLTIP")
end

function UI.CreateItemListDialog(name)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(430); frame:SetHeight(350); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(230); frame:SetMovable(true); frame:SetResizable(true); frame:EnableMouse(true)
    frame:SetMinResize(320, 220); frame:SetMaxResize(700, 700); frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    frame:SetBackdropColor(0.025, 0.025, 0.022, 1)
    UI.RegisterDialogSurface(frame, "panel")
    frame:SetScript("OnDragStart", function() this:StartMoving() end); frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame.title = UI.CreateHeading(frame, "", 2, "orange"); frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16); frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -16); frame.title:SetJustifyH("LEFT")
    frame.close = UI.CreateWindowButton(frame, nil, "close"); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -10)
    frame.ok = UI.CreateButton(frame, nil, "OK", 74, 22); frame.ok:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
    frame.scroll = CreateFrame("ScrollFrame", name .. "Scroll", frame, "FauxScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -44); frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 48)
    frame.scroll.ownerDialog = frame
    frame.rows = {}; frame.items = {}
    local index
    for index = 1, 28 do
        local row = CreateFrame("Button", nil, frame); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -48 - ((index - 1) * 24)); row:SetPoint("RIGHT", frame, "RIGHT", -34, 0); row:SetHeight(22)
        row.context = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); row.context:SetPoint("LEFT", row, "LEFT", 1, 0); row.context:SetWidth(150); row.context:SetJustifyH("LEFT"); row.context:Hide()
        row.iconRegion = row:CreateTexture(nil, "ARTWORK"); row.iconRegion:SetPoint("LEFT", row, "LEFT", 1, 0); row.iconRegion:SetWidth(20); row.iconRegion:SetHeight(20)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.label:SetPoint("LEFT", row.iconRegion, "RIGHT", 7, 0); row.label:SetPoint("RIGHT", row, "RIGHT", -2, 0); row.label:SetJustifyH("LEFT")
        local highlight = row:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints(row); highlight:SetTexture(1, 0.72, 0.12, 0.14)
        row:SetScript("OnEnter", function() UI.ShowItemTooltip(this) end); row:SetScript("OnLeave", function() GameTooltip:Hide() end); row:SetScript("OnClick", function() UI.HandleItemClick(this) end)
        row:Hide(); frame.rows[index] = row
    end
    frame.Refresh = function(self)
        local visible = math.max(1, math.min(table.getn(self.rows), math.floor(math.max(24, self.scroll:GetHeight()) / 24)))
        local offset = UI.UpdateScrollFrame(self.scroll, table.getn(self.items), visible, 24)
        local rowIndex
        for rowIndex = 1, table.getn(self.rows) do
            local row, item = self.rows[rowIndex], self.items[offset + rowIndex]
            if item and rowIndex <= visible then
                row.itemId = item.itemId; row.itemName = item.name; row.itemCount = item.count; row.labelSuffix = (tonumber(item.count) or 1) > 1 and (" x " .. item.count) or ""
                row.context:SetText(item.context or "")
                if item.missing or not item.itemId then
                    row.itemId = nil; row.iconRegion:Hide(); row.label:SetText("-")
                else
                    row.iconRegion:Show(); row.label:SetText(UI.GetItemLabel(item.itemId) .. row.labelSuffix)
                    local texture = type(GetItemIcon) == "function" and GetItemIcon(item.itemId) or nil
                    if texture then row.iconRegion:SetTexture(texture) else row.iconRegion:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") end
                end
                row:Show()
            else row.itemId = nil; row.iconRegion:Hide(); row:Hide() end
        end
    end
    frame.scroll.refreshCallback = function() frame:Refresh() end
    frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback) end)
    frame:SetScript("OnSizeChanged", function() this:Refresh() end)
    frame.grip = CreateFrame("Button", nil, frame); frame.grip:SetWidth(20); frame.grip:SetHeight(20); frame.grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end); frame.grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); frame:Refresh() end)
    frame.close:SetScript("OnClick", function() frame:Hide() end); frame.ok:SetScript("OnClick", function() frame:Hide() end)
    frame.Open = function(self, title, items)
        self.title:SetText(title or "Items"); self.items = items or {}; self.scroll.offset = 0; self.scroll:SetVerticalScroll(0)
        local showContext, itemIndex = false, nil
        for itemIndex = 1, table.getn(self.items) do if self.items[itemIndex].context then showContext = true; break end end
        for itemIndex = 1, table.getn(self.rows) do
            local row = self.rows[itemIndex]; row.iconRegion:ClearAllPoints()
            if showContext then row.context:Show(); row.iconRegion:SetPoint("LEFT", row.context, "RIGHT", 5, 0) else row.context:Hide(); row.iconRegion:SetPoint("LEFT", row, "LEFT", 1, 0) end
        end
        self:Refresh(); self:Show()
    end
    frame:Hide()
    return frame
end

function UI.ShowOpaquePopup(dialogKey, textArg1, textArg2)
    -- StaticPopup frames are pooled and reused by Blizzard. Styling or
    -- registering one here would also skin unrelated dialogs later, such as
    -- Release Spirit. Only dedicated MOS frames belong in the skin registry.
    return StaticPopup_Show(dialogKey, textArg1, textArg2)
end

function UI.CreateTextEditor(name, titleText, maxLetters, onSave)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(430); frame:SetHeight(250); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(220); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    frame:SetBackdropColor(0.025, 0.025, 0.022, 1)
    UI.RegisterDialogSurface(frame, "panel")
    frame:SetScript("OnDragStart", function() this:StartMoving() end); frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame.title = UI.CreateHeading(frame, "", 2, "orange"); frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14); frame.title:SetText(titleText)
    frame.scroll = CreateFrame("ScrollFrame", name .. "Scroll", frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42); frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 52)
    frame.scrollBar = getglobal(name .. "ScrollScrollBar")
    frame.scroll:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }); frame.scroll:SetBackdropColor(0.02, 0.02, 0.02, 0.96)
    frame.edit = CreateFrame("EditBox", nil, frame.scroll)
    frame.edit:SetWidth(390); frame.edit:SetHeight(150); frame.scroll:SetScrollChild(frame.edit)
    frame.edit:SetMultiLine(true); frame.edit:SetAutoFocus(false); frame.edit:SetMaxLetters(maxLetters or 500); frame.edit:SetFontObject(GameFontHighlightSmall)
    frame.edit:SetTextInsets(6, 6, 6, 6)
    frame.measure = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    frame.measure:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0); frame.measure:SetAlpha(0)
    frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); frame.counter:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 28)
    frame.save = UI.CreateButton(frame, nil, "Save", 72, 20); frame.save:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -92, 18)
    frame.cancel = UI.CreateButton(frame, nil, "Cancel", 72, 20); frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 18)
    local function UpdateEditorGeometry()
        local viewportWidth = math.max(40, frame.scroll:GetWidth() - 4)
        frame.edit:SetWidth(viewportWidth)
        frame.measure:SetWidth(math.max(20, viewportWidth - 12)); frame.measure:SetText(frame.edit:GetText() or "")
        local textHeight = frame.measure:GetStringHeight() or 0
        frame.edit:SetHeight(math.max(frame.scroll:GetHeight(), textHeight + 14))
    end
    frame.edit:SetScript("OnTextChanged", function() frame.counter:SetText(string.len(this:GetText() or "") .. " / " .. (maxLetters or 500)); UpdateEditorGeometry() end)
    frame.scroll:SetScript("OnSizeChanged", UpdateEditorGeometry)
    frame.save:SetScript("OnClick", function()
        local shouldClose = true
        if onSave and onSave(frame.edit:GetText() or "") == false then shouldClose = false end
        if shouldClose then frame:Hide() end
    end)
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.SetMessage = function(self, message, isError)
        self.counter:SetText(message or "")
        if isError then self.counter:SetTextColor(1, 0.25, 0.2) else self.counter:SetTextColor(0.3, 1, 0.45) end
    end
    frame.Open = function(self, value)
        self.edit:SetText(value or ""); self.counter:SetTextColor(0.6, 0.6, 0.6)
        self.counter:SetText(string.len(value or "") .. " / " .. (maxLetters or 500)); UpdateEditorGeometry(); self.scroll:SetVerticalScroll(0); self:Show(); self.edit:SetFocus()
    end
    frame.BringToFront = function(self, level)
        local baseLevel = level or 220
        self:SetFrameStrata("FULLSCREEN_DIALOG"); self:SetFrameLevel(baseLevel)
        self.scroll:SetFrameStrata("FULLSCREEN_DIALOG"); self.scroll:SetFrameLevel(baseLevel + 1); self.scroll:Show()
        if self.scrollBar then self.scrollBar:SetFrameStrata("FULLSCREEN_DIALOG"); self.scrollBar:SetFrameLevel(baseLevel + 2) end
        self.edit:SetFrameStrata("FULLSCREEN_DIALOG"); self.edit:SetFrameLevel(baseLevel + 2); self.edit:EnableMouse(true); self.edit:EnableKeyboard(true); self.edit:Show()
        self.save:SetFrameStrata("FULLSCREEN_DIALOG"); self.save:SetFrameLevel(baseLevel + 3); self.save:EnableMouse(true); self.save:Enable()
        self.cancel:SetFrameStrata("FULLSCREEN_DIALOG"); self.cancel:SetFrameLevel(baseLevel + 3); self.cancel:EnableMouse(true); self.cancel:Enable()
    end
    frame:Hide()
    return frame
end

function UI.CreateReadOnlyDialog(name, titleText, width, height, backgroundColor)
    local dismiss = CreateFrame("Button", nil, UIParent)
    dismiss:SetAllPoints(UIParent); dismiss:SetFrameStrata("FULLSCREEN_DIALOG"); dismiss:SetFrameLevel(219); dismiss:Hide()

    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetWidth(width or 520); frame:SetHeight(height or 320); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(220); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    local dialogBackground = backgroundColor or { 0.025, 0.025, 0.022 }
    frame:SetBackdropColor(dialogBackground[1], dialogBackground[2], dialogBackground[3], 1)
    UI.RegisterDialogSurface(frame, "warning", { dialogBackground[1], dialogBackground[2], dialogBackground[3], 1 })
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame.title = UI.CreateHeading(frame, "", 2, "orange")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15); frame.title:SetText(titleText or "Details")

    frame.close = UI.CreateWindowButton(frame, nil, "close")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.ok = UI.CreateButton(frame, nil, "OK", 74, 22)
    frame.ok:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 18)

    frame.scroll = CreateFrame("ScrollFrame", name .. "Scroll", frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -42); frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 52)
    frame.scrollBar = getglobal(name .. "ScrollScrollBar")
    frame.canvas = CreateFrame("Frame", nil, frame.scroll); frame.canvas:SetWidth((width or 520) - 64); frame.canvas:SetHeight(1)
    frame.scroll:SetScrollChild(frame.canvas)
    frame.text = frame.canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("TOPLEFT", frame.canvas, "TOPLEFT", 4, -4); frame.text:SetWidth((width or 520) - 72); frame.text:SetJustifyH("LEFT"); frame.text:SetJustifyV("TOP")

    local function CloseDialog() frame:Hide() end
    dismiss:SetScript("OnClick", CloseDialog); frame.close:SetScript("OnClick", CloseDialog); frame.ok:SetScript("OnClick", CloseDialog)
    frame:SetScript("OnShow", function() dismiss:Show() end)
    frame:SetScript("OnHide", function() dismiss:Hide() end)
    frame.Open = function(self, value)
        self.text:SetText(value or "")
        local contentHeight = self.text:GetStringHeight() + 12
        self.canvas:SetHeight(math.max(self.scroll:GetHeight(), contentHeight))
        if self.scrollBar then if contentHeight > self.scroll:GetHeight() then self.scrollBar:Show() else self.scrollBar:Hide() end end
        self.scroll:SetVerticalScroll(0)
        self:Show()
    end
    frame:Hide()
    return frame
end

function UI.AttachLabelTooltip(parent, label, title, description)
    local hit = UI.CreateControl(nil, parent)
    hit:SetAllPoints(label)
    UI.AttachTooltip(hit, title, description)
    return hit
end

function UI.CreateTextArea(parent, width, height, maxLetters)
    local field = UI.CreateFramedEditBox(parent, nil, width)
    field:SetHeight(height); field:SetMultiLine(true); field:SetMaxLetters(maxLetters or 255)
    field:SetScript("OnEnterPressed", nil)
    return field
end

function UI.CreateArrowButton(parent, direction)
    local icon = direction == "up" and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"
    local button = UI.CreateIconButton(parent, nil, icon, 20)
    return button
end

function UI.CreateContextMenu(parent, specs, onAction)
    local menu = UI.CreateDropdownPanel(parent, parent, 138, 28 + table.getn(specs) * 18, 50)
    menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu.dismiss:SetFrameStrata("FULLSCREEN_DIALOG")
    menu.dismiss:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    menu:SetClampedToScreen(true); menu.buttons = {}
    menu.title = UI.CreateComponentLabel(menu, "", "gold")
    menu.title:SetPoint("TOPLEFT", menu, "TOPLEFT", 12, -8)
    local index
    for index = 1, table.getn(specs) do
        local spec = specs[index]
        local button = UI.CreateMenuItem(menu, spec[1], 126, 18)
        button:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -24 - (index - 1) * 18)
        button.action = spec[2]
        button:SetScript("OnClick", function() local action = this.action; menu:Hide(); onAction(action) end)
        menu.buttons[index] = button
    end
    function menu:Open(anchor)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale() or 1
        self:ClearAllPoints(); self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale); self:Show()
    end
    return menu
end

function UI.CreateMenuItem(parent, text, width, height)
    local button = UI.CreateControl(nil, parent)
    button:SetWidth(width); button:SetHeight(height)
    button.label = UI.CreateColumnLabel(button, text, "white")
    button.label:SetPoint("LEFT", button, "LEFT", 6, 0)
    button.label:SetPoint("RIGHT", button, "RIGHT", -6, 0)
    button.label:SetJustifyH("LEFT")
    local hover = UI.CreateTexture(button, nil, "HIGHLIGHT")
    hover:SetAllPoints(button); hover:SetTexture(1, 0.82, 0.28, 0.12)
    return button
end

function UI.CreateNoteDisplay(parent, height)
    local button = UI.CreateControl(nil, parent)
    button:SetHeight(height or 76)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.025, 0.025, 0.022, 1); button:SetBackdropBorderColor(0.45, 0.40, 0.28, 1)
    button.label = UI.CreateComponentLabel(button, "", "white")
    button.label:SetPoint("TOPLEFT", button, "TOPLEFT", 10, -10)
    button.label:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -10, 10)
    button.label:SetJustifyH("LEFT"); button.label:SetJustifyV("TOP")
    button.SetText = function(self, value) self.label:SetText(value) end
    button.GetText = function(self) return self.label:GetText() end
    return button
end

function UI.BindCheckboxLabel(checkbox, onChanged, width)
    checkbox.onLabelChanged = onChanged
    checkbox:SetScript("OnClick", function() this.onLabelChanged(this) end)
    if not checkbox.labelHit then
        local hit = UI.CreateControl(nil, checkbox)
        hit:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
        hit:SetHeight(checkbox:GetHeight())
        hit.owner = checkbox
        hit:SetScript("OnClick", function()
            local owner = this.owner
            owner:SetChecked(not owner:GetChecked())
            owner.onLabelChanged(owner)
        end)
        checkbox.labelHit = hit
    end
    checkbox.labelHit:SetWidth(width or math.max(20, checkbox.label:GetStringWidth() + 4))
    return checkbox
end

local function SetOpenBorderColor(self, r, g, b, a)
    local index
    for index = 1, 8 do self.pieces[index]:SetVertexColor(r, g, b, a or 1) end
end

function UI.SetOpenButtonBorder(button, visible, openEdge)
    local border = button.openBorder
    if not visible then if border then border:Hide() end; return end
    if not border then
        border = UI.CreateContainer(nil, button); border:EnableMouse(false); border:SetAllPoints(button)
        border.pieces = {}; border.border = border
        border.SetBackdropBorderColor = SetOpenBorderColor
        local index
        for index = 1, 8 do
            local texture = border:CreateTexture(nil, "OVERLAY")
            texture:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
            local left, right = (index - 1) / 8 + 1 / 128, index / 8 - 1 / 128
            if index == 3 or index == 4 then texture:SetTexCoord(left, 15/16, right, 15/16, left, 1/16, right, 1/16)
            else texture:SetTexCoord(left, right, 1/16, 15/16) end
            border.pieces[index] = texture
        end
        local corners = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }
        for index = 5, 8 do
            local texture = border.pieces[index]
            texture:SetWidth(8); texture:SetHeight(8); texture:SetPoint(corners[index-4], border, corners[index-4], 0, 0)
        end
        border.pieces[3]:SetHeight(8); border.pieces[3]:SetPoint("TOPLEFT", border, "TOPLEFT", 8, 0); border.pieces[3]:SetPoint("TOPRIGHT", border, "TOPRIGHT", -8, 0)
        border.pieces[4]:SetHeight(8); border.pieces[4]:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 8, 0); border.pieces[4]:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -8, 0)
        border:SetBackdropBorderColor(1, 0.78, 0.2, 1); button.openBorder = border
    end
    border:SetFrameStrata(button:GetFrameStrata()); border:SetFrameLevel(button:GetFrameLevel() + 1)
    local index
    for index = 1, 8 do border.pieces[index]:Show() end
    if openEdge == "top" then border.pieces[3]:Hide(); border.pieces[5]:Hide(); border.pieces[6]:Hide()
    elseif openEdge == "bottom" then border.pieces[4]:Hide(); border.pieces[7]:Hide(); border.pieces[8]:Hide() end
    for index = 1, 2 do
        local side = index == 1 and "LEFT" or "RIGHT"
        local texture = border.pieces[index]; texture:ClearAllPoints(); texture:SetWidth(8)
        texture:SetPoint("TOP"..side, border, "TOP"..side, 0, openEdge == "top" and 0 or -8)
        texture:SetPoint("BOTTOM"..side, border, "BOTTOM"..side, 0, openEdge == "bottom" and 0 or 8)
    end
    border.mosOpenEdge = openEdge; border:Show()
end

function UI.FitButtonLabel(button, available)
    local label = button.label
    if not label then return end
    local font, size, flags = label:GetFont()
    button.mosFitFontSize = button.mosFitFontSize or size
    label:SetFont(font, button.mosFitFontSize, flags); label:SetWidth(0)
    label:SetHeight(button.mosFitFontSize + 3)
    local width = math.max(1, label:GetStringWidth())
    local fitted = math.max(1, button.mosFitFontSize * math.min(1, math.max(1, available) / width))
    label:SetFont(font, fitted, flags); label:SetWidth(math.max(1, available)); label:SetHeight(fitted + 3); label:SetJustifyH("CENTER")
end

function UI.ApplyGoldRadialHighlight(texture)
    texture:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Assets\\Skins\\Classic\\Buttons\\red-hover-radial.tga")
    texture:SetVertexColor(1, 0.8742857, 0.17, 0.42)
end
