local MOS = MuklaOfficerSuite
local UI = MOS.UI

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
        buttons[index]:SetBackdropColor(color[1], color[2], color[3], color[4])
        buttons[index]:SetBackdropBorderColor(border[1], border[2], border[3], border[4])
        if UI.SetClassicButtonSelected then UI.SetClassicButtonSelected(buttons[index], selected) end
        -- Hover handlers restore mosNormalBorder on mouse leave. Keep that
        -- persistent state aligned with the current selection style.
        if buttons[index].mosNormalBorder then buttons[index].mosNormalBorder = border end
    end
    if loadButton then if selectedAvailable then loadButton:Enable() else loadButton:Disable() end end
    return selectedAvailable
end

function UI.CreateDropdownButton(parent, name, text, width)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(width or 84); button:SetHeight(19)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
    button:SetBackdropColor(0.08, 0.07, 0.05, 0.95)
    button:SetBackdropBorderColor(0.42, 0.35, 0.20, 1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.label:SetPoint("LEFT", button, "LEFT", 8, 0); button.label:SetText(text)
    button.arrow = button:CreateTexture(nil, "OVERLAY")
    button.arrow:SetWidth(16); button.arrow:SetHeight(16); button.arrow:SetPoint("RIGHT", button, "RIGHT", -5, 0)
    button.arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    button.arrow:SetTexCoord(0.20, 0.80, 0.20, 0.80)
    return button
end

function UI.CreateDropdownPanel(parent, toggle, width, height, levelOffset)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", toggle, "BOTTOMLEFT", 0, -2)
    panel:SetWidth(width or 130); panel:SetHeight(height or 230)
    if panel.SetFrameStrata and toggle.GetFrameStrata then panel:SetFrameStrata(toggle:GetFrameStrata()) end
    panel:SetFrameLevel(math.max(parent:GetFrameLevel(), toggle:GetFrameLevel()) + (levelOffset or 50))
    if panel.SetToplevel then panel:SetToplevel(true) end
    panel:EnableMouse(true)
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 5, right = 5, top = 5, bottom = 5 } })
    panel:SetBackdropColor(0.04, 0.03, 0.02, 0.98)
    UI.RegisterDialogSurface(panel, "panel", { 0.04, 0.03, 0.02, 0.98 })
    panel.options = {}; panel:Hide()
    return panel
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
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
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

function UI.CreateIconButton(parent, name, texturePath, size, iconInset)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(size or 20); button:SetHeight(size or 20)
    local normal = button:CreateTexture(nil, "ARTWORK")
    local inset = tonumber(iconInset) or 0
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
        normal:SetVertexColor(shade, shade, shade)
        highlight:SetAlpha(self.inactive and 0 or 1)
    end
    button:SetScript("OnMouseDown", function()
        if not this.inactive then normal:SetVertexColor(0.55, 0.55, 0.55) end
    end)
    button:SetScript("OnMouseUp", function()
        local shade = this.inactive and 0.35 or 1
        normal:SetVertexColor(shade, shade, shade)
    end)
    return button
end

function UI.AttachTooltip(frame, title, description)
    frame:SetScript("OnEnter", function()
        UI.AnchorTooltipRightOfCursor(this)
        GameTooltip:AddLine(type(title) == "function" and title() or title, 1, 0.82, 0)
        GameTooltip:AddLine(type(description) == "function" and description() or description, 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return frame
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
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16); frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -16); frame.title:SetJustifyH("LEFT")
    frame.close = UI.CreateButton(frame, nil, "X", 24, 22); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -10)
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
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14); frame.title:SetText(titleText)
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
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -15); frame.title:SetText(titleText or "Details")

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
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
