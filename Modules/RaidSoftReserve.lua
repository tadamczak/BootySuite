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
    dialog = MOS.UI.Components.CreateTextEditor("MuklaOfficerSuiteSoftReserveImport", "Import Soft Reserves", 16000, function(value)
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
    dialog.close = MOS.UI.Components.CreateWindowButton(dialog, nil, "close")
    dialog.close:SetScript("OnClick", function() dialog:Hide() end)
    MOS.UI.Components.Window.StyleProjectDialog(dialog)
    dialog:SetWidth(620); dialog:SetHeight(360); dialog.save:SetText("Import"); dialog.cancel:SetText("Cancel")
    dialog.urlLabel = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormalSmall")
    dialog.urlLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -36); dialog.urlLabel:SetText("SR URL")
    dialog.url = MOS.UI.Components.CreateFramedEditBox(dialog, nil, 580)
    dialog.url:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -52); dialog.url:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -8, -52); dialog.url:SetMaxLetters(500)
    dialog.exportLabel = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormalSmall")
    dialog.exportLabel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -80); dialog.exportLabel:SetText("RollFor export")
    dialog.exportFrame = MOS.UI.Components.CreateContainer(nil, dialog)
    dialog.exportFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -97)
    dialog.exportFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -28, 38)
    dialog.exportFrame:SetBackdrop(dialog.scroll:GetBackdrop())
    dialog.exportFrame:SetBackdropColor(0.02, 0.02, 0.02, 0.96)
    dialog.scroll:SetBackdrop(nil)
    dialog.scroll:ClearAllPoints(); dialog.scroll:SetPoint("TOPLEFT", dialog.exportFrame, "TOPLEFT", 6, -6)
    dialog.scroll:SetPoint("BOTTOMRIGHT", dialog.exportFrame, "BOTTOMRIGHT", -6, 6)
    local openEditor = dialog.Open
    dialog.Open = function(self, value)
        local testMode = options.isTestRaid and options.isTestRaid()
        self.url:SetText(options.getSrUrl() or "")
        if testMode then
            self:SetHeight(175); self.exportLabel:Hide(); self.exportFrame:Hide(); self.scroll:Hide(); self.counter:Hide(); self.save:SetText("Save")
        else
            self:SetHeight(360); self.exportLabel:Show(); self.exportFrame:Show(); self.scroll:Show(); self.counter:Show(); self.save:SetText("Import")
        end
        openEditor(self, testMode and "" or (options.getRollForExport() or value or ""))
        if testMode then self.url:SetFocus() end
    end
    dialog.cancel:ClearAllPoints(); dialog.cancel:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -86, 8)
    dialog.save:ClearAllPoints(); dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)
    return dialog
end

local function CreateWarningCard(page, dialogName, dialogTitle, background, border, textColor)
    local warning = MOS.UI.Components.CreateControl(nil, page)
    warning:SetHeight(58)
    warning:SetFrameLevel(page:GetFrameLevel() + 50)
    warning:EnableMouse(true)
    MOS.UI.Components.Window.ApplyProjectSurface(warning)
    warning.badge = MOS.UI.Components.CreateLabel(warning, nil, "OVERLAY", "GameFontDisableSmall")
    warning.badge:SetPoint("TOPLEFT", warning, "TOPLEFT", 8, -5); warning.badge:SetText("Warning")
    warning.badge:SetTextColor(textColor[1], textColor[2], textColor[3])
    warning.classicHeader = MOS.UI.Components.CreateContainer(nil, warning)
    warning.classicHeader:SetPoint("TOPLEFT", warning, "TOPLEFT", 4, -4); warning.classicHeader:SetPoint("TOPRIGHT", warning, "TOPRIGHT", -4, -4); warning.classicHeader:SetHeight(22)
    warning.classicHeader.divider = MOS.UI.Components.CreateContainer(nil, warning)
    local divider = warning.classicHeader.divider
    divider:SetPoint("TOPLEFT", warning, "TOPLEFT", 4, -28)
    divider:SetPoint("TOPRIGHT", warning, "TOPRIGHT", -4, -28); divider:SetHeight(4)
    MOS.UI.Components.RegisterSkinnedSurface(divider, "content", nil, {0,0,0,0}, {0.68,0.54,0.27,1})
    MOS.UI.Components.JoinSurfaceEdges(divider, true, false)
    warning.classicHeader.icon = MOS.UI.Components.CreateTexture(warning.classicHeader, nil, "ARTWORK")
    warning.classicHeader.icon:SetTexture(MOS.UI.Components.ClassicAsset("Icons\\warning_triangle.tga")); warning.classicHeader.icon:SetWidth(12); warning.classicHeader.icon:SetHeight(12)
    warning.classicHeader.icon:SetPoint("LEFT", warning.classicHeader, "LEFT", 4, 0); warning.classicHeader.icon:SetVertexColor(1, 0.82, 0.28)
    warning.classicHeader.title = MOS.UI.Components.CreateLabel(warning.classicHeader, nil, "OVERLAY", "GameFontNormalSmall")
    warning.classicHeader.title:SetPoint("LEFT", warning.classicHeader.icon, "RIGHT", 6, 0); warning.classicHeader.title:SetText("Warning")
    warning.classicHeader.title:SetTextColor(1, 0.82, 0.28)
    local _, warningFontSize = warning.classicHeader.title:GetFont()
    warning.classicHeader.icon:SetWidth(warningFontSize); warning.classicHeader.icon:SetHeight(warningFontSize)
    warning.classicHeader.close = MOS.UI.Components.CreateWindowButton(warning.classicHeader, nil, "close")
    warning.classicHeader.close:SetPoint("RIGHT", warning.classicHeader, "RIGHT", -3, 0)
    warning.classicHeader.minimize = MOS.UI.Components.CreateWindowButton(warning.classicHeader, nil, "minimize")
    warning.classicHeader.minimize:SetPoint("RIGHT", warning.classicHeader.close, "LEFT", -2, 0)
    warning.classicHeader.title:SetPoint("RIGHT", warning.classicHeader.minimize, "LEFT", -4, 0)
    warning.classicHeader.title:SetJustifyH("LEFT")
    warning.classicHeader.minimize:SetScript("OnClick", function()
        warning.userMinimized = not warning.docked
        warning.forceExpanded = not warning.userMinimized
        if warning.onDismiss then warning.onDismiss() end
    end)
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
    MOS.UI.Components.RegisterSkinCallback(function()
        MOS.UI.Components.Window.ApplyProjectSurface(warning)
        warning.classicHeader:Show(); warning.badge:Hide()
        warning.text:SetTextColor(0.92, 0.91, 0.87)
    end)
    warning.dialog = MOS.UI.Components.CreateReadOnlyDialog(dialogName, dialogTitle, 560, 340, background)
    MOS.UI.Components.Window.StyleProjectDialog(warning.dialog)
    warning.dialog.title:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    warning.dialog.icon = MOS.UI.Components.CreateTexture(warning.dialog, nil, "ARTWORK")
    warning.dialog.icon:SetTexture(MOS.UI.Components.ClassicAsset("Icons\\warning_triangle.tga"))
    warning.dialog.icon:SetVertexColor(1, 0.82, 0.28)
    warning.dialog.icon:SetWidth(13); warning.dialog.icon:SetHeight(13)
    warning.dialog.icon:SetPoint("TOPLEFT", warning.dialog, "TOPLEFT", 8, -8)
    warning.dialog.title:ClearAllPoints(); warning.dialog.title:SetPoint("LEFT", warning.dialog.icon, "RIGHT", 6, 0)
    warning.dialog.ok:ClearAllPoints(); warning.dialog.ok:SetPoint("BOTTOMRIGHT", warning.dialog, "BOTTOMRIGHT", -8, 8)
    warning.dialog.playerRows = {}
    warning.info = MOS.UI.Components.CreateButton(warning, nil, "INFO", 66, 20)
    warning.info:SetPoint("BOTTOMRIGHT", warning, "BOTTOMRIGHT", -8, 6); warning.info:SetFrameLevel(warning:GetFrameLevel() + 2)
    warning.info:SetScript("OnClick", function()
        warning.dialog.title:SetText("|cffffd147Warning|r: " .. (warning.text:GetText() or dialogTitle))
        local attendance = page.getWarningAttendance and page.getWarningAttendance() or page.listRenderer and page.listRenderer.getData()
        local issues = MOS.Services.Raid.GetSoftReserveIssues(attendance, page.getSoftReserveRules and page.getSoftReserveRules())
        local key = warning == page.softReserveWarning and "unmatchedNames" or warning == page.missingSoftReserveWarning and "missingNames" or "invalidNames"
        local names = issues[key] or {}
        local dialog = warning.dialog
        dialog:Open(""); dialog.text:Hide()
        local contentHeight = table.getn(names) * 24
        local overflow = contentHeight > dialog:GetHeight() - 78
        dialog.scroll:ClearAllPoints(); dialog.scroll:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -36)
        dialog.scroll:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", overflow and -28 or -8, 38)
        local width = dialog:GetWidth() - (overflow and 36 or 16)
        dialog.canvas:SetWidth(width); dialog.canvas:SetHeight(math.max(1, contentHeight))
        if dialog.scrollBar then if overflow then dialog.scrollBar:Show() else dialog.scrollBar:Hide() end end
        for index=1, table.getn(names) do
            local row = dialog.playerRows[index]
            if not row then
                row = MOS.UI.Components.CreateButton(dialog.canvas, nil, "", width, 22)
                MOS.UI.Components.SetButtonLabelInsets(row, 6, 6)
                dialog.playerRows[index] = row
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", dialog.canvas, "TOPLEFT", 0, -(index-1)*24)
            local caption = RaidManagement.SoftReservePlayerLabel(names[index], attendance)
            if key == "invalidNames" then
                for _, member in ipairs(attendance and attendance.members or {}) do
                    if string.lower(member.name or "") == string.lower(names[index]) then
                        caption = caption .. " - " .. ((member.guildRank and member.guildRank ~= "" and member.guildRank) or "Guest") .. " rank has no SR"
                        break
                    end
                end
            end
            row:SetWidth(width); row:SetText(caption); row:Show()
        end
        for index=table.getn(names)+1, table.getn(dialog.playerRows) do dialog.playerRows[index]:Hide() end
    end)
    warning:Hide()
    return warning
end

function RaidManagement.CreateSoftReserveWarnings(page, clearUnmatched, refresh, getAttendance)
    page.getWarningAttendance = getAttendance
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
    local confirmMUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SR = MOS.UI.Components.Window.CreateProjectConfirmation("MUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SRDialog", "Fix Soft Reserves", "Remove")
    page.softReserveWarning.fix:SetScript("OnClick", function() local spec=StaticPopupDialogs.MUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SR; confirmMUKLA_OFFICER_SUITE_CLEAR_UNMATCHED_SR:Open(spec.text, spec.OnAccept) end)
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
    local confirmMUKLA_OFFICER_SUITE_CLEAR_INVALID_SR = MOS.UI.Components.Window.CreateProjectConfirmation("MUKLA_OFFICER_SUITE_CLEAR_INVALID_SRDialog", "Fix Soft Reserves", "Remove")
    confirmMUKLA_OFFICER_SUITE_CLEAR_INVALID_SR:SetWidth(300)
    invalidWarning.fix:SetScript("OnClick", function() local spec=StaticPopupDialogs.MUKLA_OFFICER_SUITE_CLEAR_INVALID_SR; confirmMUKLA_OFFICER_SUITE_CLEAR_INVALID_SR:Open(spec.text, spec.OnAccept) end)
    invalidWarning.ping:SetScript("OnClick", function()
        local names = MOS.Services.Raid.GetSoftReserveIssues(getAttendance(), page.getSoftReserveRules and page.getSoftReserveRules()).invalidNames
        if table.getn(names) == 0 then return end
        local sent = MOS.Services.Raid.SendRaidWarning("Members with invalid SR loot rights: " .. table.concat(names, ", "))
        if sent then MOS.Services.Raid.SendRaidWarning("Their invalid Soft Reserves will not be considered for loot and will be removed.") end
    end)
end

function RaidManagement.SoftReservePlayerLabel(name, attendance, reservation)
    local member = reservation
    local function Find(members)
        for _, candidate in ipairs(members or {}) do
            if string.lower(candidate.name or "") == string.lower(name or "") then return candidate end
        end
    end
    member = Find(attendance and attendance.members) or member or Find(attendance and attendance.softReserveImport and attendance.softReserveImport.unmatchedReservations)
    if not member or not (member.classFile or member.class) then
        local roster = MOS.Database and MOS.Database.GetRosterData and MOS.Database.GetRosterData()
        member = Find(roster and roster.members) or member
    end
    local key = string.upper(member and (member.classFile or member.class) or "")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[key] or MOS.UI.Components.Theme.classColors[key]
    if not color then return name or "" end
    return string.format("|cff%02x%02x%02x%s|r", math.floor(color.r*255), math.floor(color.g*255), math.floor(color.b*255), name or "")
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
    dialog.title = MOS.UI.Components.CreateHeading(dialog, "", 1, "gold"); dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -16); dialog.title:SetText("Fix Soft Reserve assignments")
    MOS.UI.Components.Window.StyleProjectDialog(dialog)
    dialog.help = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontHighlightSmall"); dialog.help:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -36); dialog.help:SetText("Drag an unassigned Soft Reserve from the right onto the correct raid member.")
    dialog.leftTitle = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormal"); dialog.leftTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -72); dialog.leftTitle:SetText("Raid members without SR")
    dialog.rightTitle = MOS.UI.Components.CreateLabel(dialog, nil, "OVERLAY", "GameFontNormal"); dialog.rightTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 354, -72); dialog.rightTitle:SetText("Unassigned Soft Reserves")
    dialog.leftPanel = MOS.UI.Components.CreateContainer(nil, dialog); dialog.leftPanel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 8, -92); dialog.leftPanel:SetWidth(338); dialog.leftPanel:SetHeight(278)
    dialog.rightPanel = MOS.UI.Components.CreateContainer(nil, dialog); dialog.rightPanel:SetPoint("TOPLEFT", dialog, "TOPLEFT", 354, -92); dialog.rightPanel:SetWidth(338); dialog.rightPanel:SetHeight(278)
    local panels = { dialog.leftPanel, dialog.rightPanel }
    local panelIndex, rowIndex
    for panelIndex = 1, 2 do
        panels[panelIndex]:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        panels[panelIndex]:SetBackdropColor(0.035, 0.035, 0.03, 1); panels[panelIndex]:SetBackdropBorderColor(0.38, 0.34, 0.24, 1); panels[panelIndex]:EnableMouseWheel(true)
    end
    dialog.leftRows = {}; dialog.rightRows = {}; dialog.assignments = {}
    for rowIndex = 1, 12 do
        local left = MOS.UI.Components.CreateButton(dialog.leftPanel, nil, "", 324, 20); left:SetPoint("TOPLEFT", dialog.leftPanel, "TOPLEFT", 7, -7 - ((rowIndex - 1) * 22)); left.label:SetJustifyH("LEFT")
        local right = MOS.UI.Components.CreateButton(dialog.rightPanel, nil, "", 324, 20); right:SetPoint("TOPLEFT", dialog.rightPanel, "TOPLEFT", 7, -7 - ((rowIndex - 1) * 22)); right.label:SetJustifyH("LEFT"); right:RegisterForDrag("LeftButton")
        MOS.UI.Components.SetButtonLabelInsets(left, 6, 6); MOS.UI.Components.SetButtonLabelInsets(right, 6, 6)
        right.itemHit = MOS.UI.Components.CreateControl(nil, right)
        right.itemHit:SetHeight(20); right.itemHit:RegisterForDrag("LeftButton")
        right.itemHit:SetScript("OnEnter", ShowItemTooltip); right.itemHit:SetScript("OnLeave", HideItemTooltip)
        right.itemHit:SetScript("OnClick", HandleItemClick)
        dialog.leftRows[rowIndex] = left; dialog.rightRows[rowIndex] = right
    end
    dialog.save = MOS.UI.Components.CreateButton(dialog, nil, "Save", 78, 22); dialog.save:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -94, 8)
    dialog.close = MOS.UI.Components.CreateButton(dialog, nil, "Close", 78, 22); dialog.close:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -8, 8)
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
            if memberName then local assigned = dialog.assignments[memberName]; left.label:SetText(RaidManagement.SoftReservePlayerLabel(memberName, dialog.attendance) .. (assigned and ("  <-  " .. RaidManagement.SoftReservePlayerLabel(assigned, dialog.attendance, dialog.reservationByName and dialog.reservationByName[string.lower(assigned)])) or "")); left:Show() else left:Hide() end
            local reservation = dialog.available[dialog.rightOffset + index]; local right = dialog.rightRows[index]; right.reservation = reservation
            if reservation then
                right.itemId = reservation.itemIds and reservation.itemIds[1] or nil
                right.labelPrefix = RaidManagement.SoftReservePlayerLabel(reservation.name, dialog.attendance, reservation) .. "  -  "
                right.label:SetText(right.labelPrefix)
                local inset = math.min(260, right.label:GetStringWidth()) + 6
                local itemText = right.itemId and MOS.UI.Components.GetItemLabel(right.itemId) or "No item"
                right.label:SetText(itemText)
                local itemWidth = math.min(306 - inset, right.label:GetStringWidth())
                right.label:SetText(right.labelPrefix .. itemText)
                right.itemHit.itemId = right.itemId
                right.itemHit:ClearAllPoints(); right.itemHit:SetPoint("LEFT", right, "LEFT", inset, 0)
                right.itemHit:SetWidth(math.max(1,itemWidth)); right.itemHit:Show(); right:Show()
            else right.itemId = nil; right.labelPrefix = nil; right:Hide() end
        end
    end
    dialog.leftPanel:SetScript("OnMouseWheel", function() dialog.leftOffset = (dialog.leftOffset or 0) - arg1; RefreshDialog() end)
    dialog.rightPanel:SetScript("OnMouseWheel", function() dialog.rightOffset = (dialog.rightOffset or 0) - arg1; RefreshDialog() end)
    for rowIndex = 1, 12 do
        local left = dialog.leftRows[rowIndex]; left:SetScript("OnClick", function() if this.memberName and dialog.assignments[this.memberName] then dialog.assignments[this.memberName] = nil; RefreshDialog() end end)
        local right = dialog.rightRows[rowIndex]
        right:SetScript("OnEnter", nil); right:SetScript("OnLeave", HideItemTooltip)
        right:SetScript("OnDragStart", function() if this.reservation then dialog.dragged = this.reservation; dialog.ghost.text:SetText(this.label:GetText() or this.reservation.name); dialog.ghost:Show() end end)
        right:SetScript("OnDragStop", function()
            dialog.ghost:Hide(); if not dialog.dragged then return end
            local targetIndex
            for targetIndex = 1, 12 do local target = dialog.leftRows[targetIndex]; if target.memberName and IsCursorOverFrame(target) then dialog.assignments[target.memberName] = dialog.dragged.name; break end end
            dialog.dragged = nil; RefreshDialog()
        end)
    end
    for _, row in ipairs(dialog.rightRows) do
        local owner = row
        for _, script in ipairs({"OnDragStart", "OnDragStop"}) do
            local handler = owner:GetScript(script)
            owner.itemHit:SetScript(script, function() local previous=this; this=owner; handler(); this=previous end)
        end
    end
    dismiss:SetScript("OnClick", CloseDialog); dialog.close:SetScript("OnClick", CloseDialog)
    dialog.save:SetScript("OnClick", function() if applyAssignments(dialog.attendance, dialog.assignments) then CloseDialog(); refresh() end end)
    dialog.Open = function(self, attendance)
        local importInfo = attendance and attendance.softReserveImport
        if not importInfo or not importInfo.missingNames or not importInfo.unmatchedReservations then return end
        self.attendance = attendance; self.importInfo = importInfo; self.missing = importInfo.missingNames; self.assignments = {}; self.leftOffset = 0; self.rightOffset = 0
        self.reservationByName = {}
        for _, reservation in ipairs(importInfo.unmatchedReservations) do self.reservationByName[string.lower(reservation.name or "")] = reservation end
        RefreshDialog(); dismiss:Show(); self:Show()
    end
    page.softReserveFixDialog = dialog
end
