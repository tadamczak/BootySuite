local MOS = MuklaOfficerSuite
MOS.Modules.RaidManagement = MOS.Modules.RaidManagement or {}
local RaidManagement = MOS.Modules.RaidManagement

local function ShowItemTooltip() MOS.UI.Components.ShowItemTooltip(this) end
local function HideItemTooltip() GameTooltip:Hide() end
local function HandleItemClick() MOS.UI.Components.HandleItemClick(this) end

local function IsCursorOverFrame(frame)
    if not frame or not frame:IsVisible() or not frame:GetLeft() then return false end
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale; y = y / scale
    return x >= frame:GetLeft() and x <= frame:GetRight() and y >= frame:GetBottom() and y <= frame:GetTop()
end

function RaidManagement.CreateSoftReserveImportDialog(options)
    local dialog
    dialog = MOS.UI.Components.CreateTextEditor("MuklaOfficerSuiteSoftReserveImport", "Import RaidRes Soft Reserves", 16000, function(value)
        if options.isTestRaid and options.isTestRaid() then
            local url = dialog.url:GetText() or ""
            if not options.setSrUrl(url) then dialog:SetMessage("SR URL is required.", true); return false end
            options.refresh(); options.printMessage("Test Raid Soft Reserve URL updated.")
            return true
        end
        local result, importError = options.importData(value, dialog.url:GetText() or "")
        if not result then dialog:SetMessage(importError or "The Soft Reserve import failed.", true); return false end
        options.refresh()
        options.printMessage("Soft Reserves imported. Matched: " .. result.matched .. ", outside raid: " .. result.unmatched .. ", raid members without SR: " .. result.missing .. ".")
        return true
    end)
    dialog:SetWidth(620); dialog:SetHeight(360); dialog.save:SetText("Import"); dialog.cancel:SetText("Cancel")
    dialog.urlLabel = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormalSmall")
    dialog.urlLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -42); dialog.urlLabel:SetText("SR URL")
    dialog.url = MOS.UI.Components.CreateSearchBox(dialog, nil, 580)
    dialog.url:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -58); dialog.url:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -18, -58); dialog.url:SetMaxLetters(500)
    dialog.exportLabel = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormalSmall")
    dialog.exportLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -86); dialog.exportLabel:SetText("RollFor export")
    dialog.scroll:ClearAllPoints(); dialog.scroll:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -103); dialog.scroll:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -34, 52)
    local openEditor = dialog.Open
    dialog.Open = function(self, value)
        local testMode = options.isTestRaid and options.isTestRaid()
        self.url:SetText(options.getSrUrl() or "")
        if testMode then
            self:SetHeight(175); self.exportLabel:Hide(); self.scroll:Hide(); self.counter:Hide(); self.save:SetText("Save")
        else
            self:SetHeight(360); self.exportLabel:Show(); self.scroll:Show(); self.counter:Show(); self.save:SetText("Import")
        end
        openEditor(self, testMode and "" or (options.getRollForExport() or value or ""))
        if testMode then self.url:SetFocus() end
    end
    dialog.cancel:ClearAllPoints(); dialog.cancel:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -92, 18)
    dialog.save:ClearAllPoints(); dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -14, 18)
    return dialog
end

local function CreateWarningCard(page, dialogName, dialogTitle, background, border, textColor)
    local warning = MOS.UI.Components.CreateControl(nil, page)
    warning:SetHeight(58)
    warning:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    MOS.UI.Components.RegisterSkinnedSurface(warning, "warning", { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } }, { 0.15, 0.075, 0.012, 0.98 }, { 0.90, 0.48, 0.08, 1 })
    warning:SetBackdropColor(background[1], background[2], background[3], 0.94); warning:SetBackdropBorderColor(border[1], border[2], border[3], 0.9)
    warning.badge = MOS.UI.Components.CreateLabel(warning, nil, "OVERLAY", "GameFontDisableSmall")
    warning.badge:SetPoint("TOPLEFT", warning, "TOPLEFT", 8, -5); warning.badge:SetText("Warning")
    warning.badge:SetTextColor(textColor[1], textColor[2], textColor[3])
    warning.classicHeader = MOS.UI.Components.CreateContainer(nil, warning)
    warning.classicHeader:SetPoint("TOPLEFT", warning, "TOPLEFT", 6, -6); warning.classicHeader:SetPoint("TOPRIGHT", warning, "TOPRIGHT", -6, -6); warning.classicHeader:SetHeight(18)
    warning.classicHeader.divider = MOS.UI.Components.CreateTexture(warning.classicHeader, nil, "BORDER")
    warning.classicHeader.divider:SetTexture(0.48, 0.38, 0.20, 0.8); warning.classicHeader.divider:SetPoint("BOTTOMLEFT", warning.classicHeader, "BOTTOMLEFT", 0, 0); warning.classicHeader.divider:SetPoint("BOTTOMRIGHT", warning.classicHeader, "BOTTOMRIGHT", 0, 0); warning.classicHeader.divider:SetHeight(1)
    warning.classicHeader.icon = MOS.UI.Components.CreateTexture(warning.classicHeader, nil, "ARTWORK")
    warning.classicHeader.icon:SetTexture(MOS.UI.Components.ClassicAsset("Icons\\warning_triangle.tga")); warning.classicHeader.icon:SetWidth(12); warning.classicHeader.icon:SetHeight(12)
    warning.classicHeader.icon:SetPoint("LEFT", warning.classicHeader, "LEFT", 3, 1); warning.classicHeader.icon:SetVertexColor(1, 0.78, 0.24)
    warning.classicHeader.title = MOS.UI.Components.CreateLabel(warning.classicHeader, nil, "OVERLAY", "GameFontNormalSmall")
    warning.classicHeader.title:SetPoint("LEFT", warning.classicHeader.icon, "RIGHT", 6, 0); warning.classicHeader.title:SetText("Warning")
    warning.classicHeader.close = MOS.UI.Components.CreateWindowButton(warning.classicHeader, nil, "close")
    warning.classicHeader.close:SetPoint("RIGHT", warning.classicHeader, "RIGHT", -3, 1)
    warning.classicHeader.close:SetScript("OnClick", function()
        warning.userDismissed = true
        warning:Hide()
        if warning.onDismiss then warning.onDismiss() end
    end)
    MOS.UI.Components.AttachTooltip(warning.classicHeader.close, "Dismiss warning", "Hide this warning until its data is refreshed.")
    warning.classicHeader:Hide()
    warning.text = MOS.UI.Components.CreateLabel(warning, nil, "OVERLAY", "GameFontHighlightSmall")
    warning.text:SetPoint("LEFT", warning, "LEFT", 9, -5); warning.text:SetPoint("RIGHT", warning, "RIGHT", -9, -5)
    warning.text:SetJustifyH("CENTER"); warning.text:SetTextColor(textColor[1], textColor[2], textColor[3])
    MOS.UI.Components.RegisterSkinCallback(function(skin)
        if skin == "classic" then
            warning.classicHeader:Show(); warning.badge:Hide()
            warning.text:SetTextColor(0.92, 0.91, 0.87)
        else
            warning.classicHeader:Hide(); warning.badge:Show(); warning.badge:ClearAllPoints(); warning.badge:SetPoint("TOPLEFT", warning, "TOPLEFT", 8, -5)
            warning.text:SetTextColor(textColor[1], textColor[2], textColor[3])
        end
    end)
    warning.dialog = MOS.UI.Components.CreateReadOnlyDialog(dialogName, dialogTitle, 560, 340, background)
    warning.info = MOS.UI.Components.CreateButton(warning, nil, "INFO", 66, 20)
    warning.info:SetPoint("BOTTOMRIGHT", warning, "BOTTOMRIGHT", -8, 6); warning.info:SetFrameLevel(warning:GetFrameLevel() + 2)
    warning.info:SetScript("OnClick", function()
        warning.dialog.title:SetText("Warning: " .. (warning.text:GetText() or dialogTitle))
        warning.dialog:Open(warning.details or "")
    end)
    warning:Hide()
    return warning
end

function RaidManagement.CreateSoftReserveWarnings(page, clearUnmatched, refresh, getAttendance)
    page.softReserveWarning = CreateWarningCard(page, "MuklaOfficerSuiteSoftReserveWarningDetails", "Soft Reserves outside raid", { 0.18, 0.08, 0.01 }, { 1, 0.55, 0.08 }, { 1, 0.72, 0.18 })
    page.softReserveWarning.onDismiss = refresh
    page.softReserveWarning.text:ClearAllPoints(); page.softReserveWarning.text:SetPoint("LEFT", page.softReserveWarning, "LEFT", 9, -5); page.softReserveWarning.text:SetPoint("RIGHT", page.softReserveWarning, "RIGHT", -84, -5)
    page.softReserveWarning.fix = MOS.UI.Components.CreateButton(page.softReserveWarning, nil, "FIX SR", 66, 22)
    MOS.UI.Components.SetClassicButtonVariant(page.softReserveWarning.fix, "red"); MOS.UI.Components.SetClassicButtonVariant(page.softReserveWarning.info, "red")
    MOS.UI.Components.SetClassicButtonIcon(page.softReserveWarning.fix, "fix", 12); MOS.UI.Components.SetClassicButtonIcon(page.softReserveWarning.info, "info", 12)
    page.softReserveWarning.fix:SetPoint("TOPRIGHT", page.softReserveWarning, "TOPRIGHT", -8, -6); page.softReserveWarning.fix:SetHeight(20); page.softReserveWarning.fix:SetFrameLevel(page.softReserveWarning:GetFrameLevel() + 2)
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SR"] = {
        text = "Remove every unassigned Soft Reserve from the current import? Assigned raid members will not be changed.", button1 = "Remove", button2 = "Cancel",
        OnAccept = function() if clearUnmatched(page.listRenderer.getData()) then refresh() end end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    page.softReserveWarning.fix:SetScript("OnClick", function() MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SR") end)
    page.missingSoftReserveWarning = CreateWarningCard(page, "MuklaOfficerSuiteMissingSoftReserveDetails", "Raid members without Soft Reserve", { 0.18, 0.08, 0.01 }, { 1, 0.55, 0.08 }, { 1, 0.72, 0.18 })
    page.missingSoftReserveWarning.onDismiss = refresh
    page.missingSoftReserveWarning.text:ClearAllPoints(); page.missingSoftReserveWarning.text:SetPoint("LEFT", page.missingSoftReserveWarning, "LEFT", 9, -5); page.missingSoftReserveWarning.text:SetPoint("RIGHT", page.missingSoftReserveWarning, "RIGHT", -84, -5)
    page.missingSoftReserveWarning.fix = MOS.UI.Components.CreateButton(page.missingSoftReserveWarning, nil, "FIX SR", 66, 22)
    MOS.UI.Components.SetClassicButtonVariant(page.missingSoftReserveWarning.fix, "red"); MOS.UI.Components.SetClassicButtonVariant(page.missingSoftReserveWarning.info, "red")
    MOS.UI.Components.SetClassicButtonIcon(page.missingSoftReserveWarning.fix, "fix", 10, 5); MOS.UI.Components.SetClassicButtonIcon(page.missingSoftReserveWarning.info, "info", 10, 5)
    page.missingSoftReserveWarning.fix:SetPoint("TOPRIGHT", page.missingSoftReserveWarning, "TOPRIGHT", -8, -4); page.missingSoftReserveWarning.fix:SetHeight(14); page.missingSoftReserveWarning.fix:SetFrameLevel(page.missingSoftReserveWarning:GetFrameLevel() + 2)
    page.missingSoftReserveWarning.info:ClearAllPoints(); page.missingSoftReserveWarning.info:SetPoint("TOPRIGHT", page.missingSoftReserveWarning, "TOPRIGHT", -8, -21); page.missingSoftReserveWarning.info:SetHeight(14)
    page.missingSoftReserveWarning.ping = MOS.UI.Components.CreateButton(page.missingSoftReserveWarning, nil, "PING", 66, 14)
    MOS.UI.Components.SetClassicButtonVariant(page.missingSoftReserveWarning.ping, "red")
    MOS.UI.Components.SetClassicButtonIcon(page.missingSoftReserveWarning.ping, "ping", 10, 5)
    page.missingSoftReserveWarning.ping:SetPoint("TOPRIGHT", page.missingSoftReserveWarning, "TOPRIGHT", -8, -38); page.missingSoftReserveWarning.ping:SetFrameLevel(page.missingSoftReserveWarning:GetFrameLevel() + 2)
    page.missingSoftReserveWarning.fix:SetScript("OnClick", function() if page.softReserveFixDialog then page.softReserveFixDialog:Open(getAttendance()) end end)
    page.missingSoftReserveWarning.ping:SetScript("OnClick", function() if page.pingMissingSoftReserves then page.pingMissingSoftReserves() end end)
    page.invalidSoftReserveWarning = CreateWarningCard(page, "MuklaOfficerSuiteInvalidSoftReserveDetails", "Soft Reserve without loot rights", { 0.18, 0.08, 0.01 }, { 1, 0.55, 0.08 }, { 1, 0.72, 0.18 })
    page.invalidSoftReserveWarning.onDismiss = refresh
    local invalidWarning = page.invalidSoftReserveWarning
    invalidWarning.text:ClearAllPoints(); invalidWarning.text:SetPoint("LEFT", invalidWarning, "LEFT", 9, -5); invalidWarning.text:SetPoint("RIGHT", invalidWarning, "RIGHT", -84, -5)
    invalidWarning.fix = MOS.UI.Components.CreateButton(invalidWarning, nil, "FIX SR", 66, 14)
    invalidWarning.ping = MOS.UI.Components.CreateButton(invalidWarning, nil, "PING", 66, 14)
    MOS.UI.Components.SetClassicButtonVariant(invalidWarning.fix, "red"); MOS.UI.Components.SetClassicButtonVariant(invalidWarning.info, "red"); MOS.UI.Components.SetClassicButtonVariant(invalidWarning.ping, "red")
    MOS.UI.Components.SetClassicButtonIcon(invalidWarning.fix, "fix", 10, 5); MOS.UI.Components.SetClassicButtonIcon(invalidWarning.info, "info", 10, 5); MOS.UI.Components.SetClassicButtonIcon(invalidWarning.ping, "ping", 10, 5)
    invalidWarning.fix:SetPoint("TOPRIGHT", invalidWarning, "TOPRIGHT", -8, -4); invalidWarning.fix:SetFrameLevel(invalidWarning:GetFrameLevel() + 2)
    invalidWarning.info:ClearAllPoints(); invalidWarning.info:SetPoint("TOPRIGHT", invalidWarning, "TOPRIGHT", -8, -21); invalidWarning.info:SetWidth(66); invalidWarning.info:SetHeight(14)
    invalidWarning.ping:SetPoint("TOPRIGHT", invalidWarning, "TOPRIGHT", -8, -38); invalidWarning.ping:SetFrameLevel(invalidWarning:GetFrameLevel() + 2)
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_CLEAR_INVALID_SR"] = {
        text = "Remove invalid Soft Reserves from raid members?", button1 = "Remove SR", button2 = "Cancel",
        OnAccept = function()
            if MOS.Services.RaidRes.ClearInvalidMemberReservations(getAttendance(), page.getSoftReserveRules and page.getSoftReserveRules()) > 0 then refresh() end
        end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    invalidWarning.fix:SetScript("OnClick", function() MOS.UI.Components.ShowOpaquePopup("MUKLA_OFFICER_SUITE_CLEAR_INVALID_SR") end)
    invalidWarning.ping:SetScript("OnClick", function()
        local names = MOS.Services.Raid.GetSoftReserveIssues(getAttendance(), page.getSoftReserveRules and page.getSoftReserveRules()).invalidNames
        if table.getn(names) == 0 then return end
        local sent = MOS.Services.Raid.SendRaidWarning("Members with invalid SR loot rights: " .. table.concat(names, ", "))
        if sent then MOS.Services.Raid.SendRaidWarning("Their invalid Soft Reserves will not be considered for loot and will be removed.") end
    end)
end

function RaidManagement.CreateSoftReserveFixDialog(page, applyAssignments, refresh)
    local dismiss = MOS.UI.Components.CreateControl(nil, UIParent)
    dismiss:SetAllPoints(UIParent); dismiss:SetFrameStrata("FULLSCREEN_DIALOG"); dismiss:SetFrameLevel(229); dismiss:Hide()
    local dialog = MOS.UI.Components.CreateContainer("MuklaOfficerSuiteSoftReserveFixDialog", UIParent)
    dialog:SetWidth(700); dialog:SetHeight(430); dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetFrameLevel(230); dialog:EnableMouse(true); dialog:Hide()
    if dialog.SetClampedToScreen then dialog:SetClampedToScreen(true) end
    dialog:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 7, right = 7, top = 7, bottom = 7 } }); dialog:SetBackdropColor(0.018, 0.018, 0.016, 1)
    MOS.UI.Components.RegisterDialogSurface(dialog, "panel", { 0.018, 0.018, 0.016, 1 })
    dialog.title = MOS.UI.Components.CreateHeading(dialog, "", 1, "gold"); dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -16); dialog.title:SetText("Fix Soft Reserve assignments")
    dialog.help = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontHighlightSmall"); dialog.help:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -43); dialog.help:SetText("Drag an unassigned Soft Reserve from the right onto the correct raid member.")
    dialog.leftTitle = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormal"); dialog.leftTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -72); dialog.leftTitle:SetText("Raid members without SR")
    dialog.rightTitle = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormal"); dialog.rightTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 358, -72); dialog.rightTitle:SetText("Unassigned Soft Reserves")
    dialog.leftPanel = MOS.UI.Components.CreateContainer(nil, dialog); dialog.leftPanel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -92); dialog.leftPanel:SetWidth(326); dialog.leftPanel:SetHeight(278)
    dialog.rightPanel = MOS.UI.Components.CreateContainer(nil, dialog); dialog.rightPanel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 356, -92); dialog.rightPanel:SetWidth(326); dialog.rightPanel:SetHeight(278)
    local panels = { dialog.leftPanel, dialog.rightPanel }
    local panelIndex, rowIndex
    for panelIndex = 1, 2 do
        panels[panelIndex]:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        panels[panelIndex]:SetBackdropColor(0.035, 0.035, 0.03, 1); panels[panelIndex]:SetBackdropBorderColor(0.38, 0.34, 0.24, 1); panels[panelIndex]:EnableMouseWheel(true)
    end
    dialog.leftRows = {}; dialog.rightRows = {}; dialog.assignments = {}
    for rowIndex = 1, 12 do
        local left = MOS.UI.Components.CreateButton(dialog.leftPanel, nil, "", 312, 20); left:SetPoint("TOPLEFT", dialog.leftPanel, "TOPLEFT", 7, -7 - ((rowIndex - 1) * 22)); left.label:SetJustifyH("LEFT")
        local right = MOS.UI.Components.CreateButton(dialog.rightPanel, nil, "", 312, 20); right:SetPoint("TOPLEFT", dialog.rightPanel, "TOPLEFT", 7, -7 - ((rowIndex - 1) * 22)); right.label:SetJustifyH("LEFT"); right:RegisterForDrag("LeftButton")
        dialog.leftRows[rowIndex] = left; dialog.rightRows[rowIndex] = right
    end
    dialog.save = MOS.UI.Components.CreateButton(dialog, nil, "Save", 78, 22); dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -100, 18)
    dialog.close = MOS.UI.Components.CreateButton(dialog, nil, "Close", 78, 22); dialog.close:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -16, 18)
    dialog.ghost = MOS.UI.Components.CreateContainer(nil, UIParent); dialog.ghost:SetWidth(260); dialog.ghost:SetHeight(22); dialog.ghost:SetFrameStrata("TOOLTIP"); dialog.ghost:SetFrameLevel(240)
    dialog.ghost:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }); dialog.ghost:SetBackdropColor(0.12, 0.09, 0.03, 0.98)
    dialog.ghost.text = MOS.UI.Components.CreateLabel(dialog.ghost, nil, "OVERLAY", "GameFontHighlightSmall"); dialog.ghost.text:SetPoint("LEFT", dialog.ghost, "LEFT", 8, 0); dialog.ghost:Hide()
    dialog.ghost:SetScript("OnUpdate", function() local x, y = GetCursorPosition(); local scale = UIParent:GetEffectiveScale(); this:ClearAllPoints(); this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale) end)

    local function CloseDialog() dialog.ghost:Hide(); dialog:Hide(); dismiss:Hide() end
    dialog.Close = CloseDialog
    local function BuildAvailable()
        local used = {}; local _, reservationName
        for _, reservationName in pairs(dialog.assignments) do used[string.lower(reservationName)] = true end
        dialog.available = {}; local count = 0
        local reservations = dialog.importInfo and dialog.importInfo.unmatchedReservations or {}
        local index
        for index = 1, table.getn(reservations) do if not used[string.lower(reservations[index].name or "")] then count = count + 1; dialog.available[count] = reservations[index] end end
    end
    local function RefreshDialog()
        BuildAvailable()
        dialog.leftOffset = math.max(0, math.min(math.max(0, table.getn(dialog.missing) - 12), dialog.leftOffset or 0))
        dialog.rightOffset = math.max(0, math.min(math.max(0, table.getn(dialog.available) - 12), dialog.rightOffset or 0))
        local index
        for index = 1, 12 do
            local memberName = dialog.missing[dialog.leftOffset + index]; local left = dialog.leftRows[index]; left.memberName = memberName
            if memberName then local assigned = dialog.assignments[memberName]; left.label:SetText(memberName .. (assigned and ("  <-  " .. assigned) or "")); left:Show() else left:Hide() end
            local reservation = dialog.available[dialog.rightOffset + index]; local right = dialog.rightRows[index]; right.reservation = reservation
            if reservation then right.itemId = reservation.itemIds and reservation.itemIds[1] or nil; right.labelPrefix = reservation.name .. "  -  "; right.label:SetText(right.labelPrefix .. (right.itemId and MOS.UI.Components.GetItemLabel(right.itemId) or "No item")); right:Show()
            else right.itemId = nil; right.labelPrefix = nil; right:Hide() end
        end
    end
    dialog.leftPanel:SetScript("OnMouseWheel", function() dialog.leftOffset = (dialog.leftOffset or 0) - arg1; RefreshDialog() end)
    dialog.rightPanel:SetScript("OnMouseWheel", function() dialog.rightOffset = (dialog.rightOffset or 0) - arg1; RefreshDialog() end)
    for rowIndex = 1, 12 do
        local left = dialog.leftRows[rowIndex]; left:SetScript("OnClick", function() if this.memberName and dialog.assignments[this.memberName] then dialog.assignments[this.memberName] = nil; RefreshDialog() end end)
        local right = dialog.rightRows[rowIndex]
        right:SetScript("OnEnter", ShowItemTooltip); right:SetScript("OnLeave", HideItemTooltip); right:SetScript("OnClick", HandleItemClick)
        right:SetScript("OnDragStart", function() if this.reservation then dialog.dragged = this.reservation; dialog.ghost.text:SetText(this.label:GetText() or this.reservation.name); dialog.ghost:Show() end end)
        right:SetScript("OnDragStop", function()
            dialog.ghost:Hide(); if not dialog.dragged then return end
            local targetIndex
            for targetIndex = 1, 12 do local target = dialog.leftRows[targetIndex]; if target.memberName and IsCursorOverFrame(target) then dialog.assignments[target.memberName] = dialog.dragged.name; break end end
            dialog.dragged = nil; RefreshDialog()
        end)
    end
    dismiss:SetScript("OnClick", CloseDialog); dialog.close:SetScript("OnClick", CloseDialog)
    dialog.save:SetScript("OnClick", function() if applyAssignments(dialog.attendance, dialog.assignments) then CloseDialog(); refresh() end end)
    dialog.Open = function(self, attendance)
        local importInfo = attendance and attendance.softReserveImport
        if not importInfo or not importInfo.missingNames or not importInfo.unmatchedReservations then return end
        self.attendance = attendance; self.importInfo = importInfo; self.missing = importInfo.missingNames; self.assignments = {}; self.leftOffset = 0; self.rightOffset = 0
        RefreshDialog(); dismiss:Show(); self:Show()
    end
    page.softReserveFixDialog = dialog
end
