local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local RaidStatistics = {}
MOS.Modules.RaidStatistics = RaidStatistics

local function OnRaidSelect()
    local controller = this.statisticsController
    if controller.selectedId == this.raidId then controller.selectedId = nil
    else controller.selectedId = this.raidId end
    controller:Refresh()
end

local function OnItemsClick()
    if this.inactive or not this.ownerRow or not this.ownerRow.player then return end
    local player = this.ownerRow.player
    local items = this.itemKind == "sr" and player.srItems or player.lootItems
    local kind = this.itemKind == "sr" and "Soft Reserves" or "Loot received"
    this.statisticsController.itemDialog:Open(kind .. " - " .. tostring(player.name or "Player"), items)
end

local function OnDirectItemEnter()
    MOS.UI.Components.ShowItemTooltip(this)
end

function RaidStatistics.Create(page, getEntries, deleteEntry, updateEntry)
    local controller = { page = page, getEntries = getEntries, deleteEntry = deleteEntry, updateEntry = updateEntry, selectedId = nil, raidButtons = {}, rows = {}, filteredEntries = {}, selectedRaids = {} }
    controller.itemDialog = MOS.UI.Components.CreateItemListDialog("MuklaOfficerSuiteRaidStatisticsItems")
    controller.title = MOS.UI.Components.CreateHeading(page, "", 1, "gold"); controller.title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10); controller.title:SetText("Raid Statistics")
    local raidNames = MOS.Services.RaidStatistics.GetRaidNames(); local raidNameIndex
    for raidNameIndex = 1, table.getn(raidNames) do controller.selectedRaids[raidNames[raidNameIndex]] = true end
    controller.filterPanel = MOS.UI.Components.CreateContainer(nil, page); controller.filterPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 8, -40); controller.filterPanel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -8, -40); controller.filterPanel:SetHeight(66)
    controller.filterPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }); controller.filterPanel:SetBackdropColor(0.035, 0.03, 0.02, 0.94); controller.filterPanel:SetBackdropBorderColor(0.42, 0.34, 0.18, 1)
    controller.filterTitle = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontNormalSmall"); controller.filterTitle:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 10, -8); controller.filterTitle:SetText("Filters")
    controller.raidFilter = MOS.UI.Components.CreateDropdownButton(controller.filterPanel, nil, "Raid", 140); controller.raidFilter:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 62, -6)
    controller.raidPanel = MOS.UI.Components.CreateDropdownPanel(controller.filterPanel, controller.raidFilter, 190, 178, 20)
    controller.raidDismiss = controller.raidPanel.dismiss
    controller.raidFilter:SetScript("OnClick", function() if controller.raidPanel:IsVisible() then controller.raidPanel:Hide() else controller.raidPanel:Show() end end)
    local allCheck = MOS.UI.Components.CreateCheckButton(nil, controller.raidPanel, "UICheckButtonTemplate"); allCheck:SetPoint("TOPLEFT", controller.raidPanel, "TOPLEFT", 8, -6); allCheck:SetWidth(20); allCheck:SetHeight(20); allCheck:SetChecked(1)
    allCheck.label = MOS.UI.Components.CreateLabel(controller.raidPanel, nil, "OVERLAY", "GameFontHighlightSmall"); allCheck.label:SetPoint("LEFT", allCheck, "RIGHT", 2, 0); allCheck.label:SetText("All")
    controller.raidChecks = {}
    MOS.UI.Components.BindCheckboxLabel(allCheck, function(owner) local enabled = owner:GetChecked() and true or false; local i; for i = 1, table.getn(raidNames) do controller.selectedRaids[raidNames[i]] = enabled and true or nil; controller.raidChecks[i]:SetChecked(enabled and 1 or nil) end; controller:Refresh() end)
    for raidNameIndex = 1, table.getn(raidNames) do
        local check = MOS.UI.Components.CreateCheckButton(nil, controller.raidPanel, "UICheckButtonTemplate"); check:SetPoint("TOPLEFT", controller.raidPanel, "TOPLEFT", 8, -6 - (raidNameIndex * 23)); check:SetWidth(20); check:SetHeight(20); check:SetChecked(1); check.raidName = raidNames[raidNameIndex]
        check.label = MOS.UI.Components.CreateLabel(controller.raidPanel, nil, "OVERLAY", "GameFontHighlightSmall"); check.label:SetPoint("LEFT", check, "RIGHT", 2, 0); check.label:SetText(check.raidName)
        MOS.UI.Components.BindCheckboxLabel(check, function(owner) controller.selectedRaids[owner.raidName] = owner:GetChecked() and true or nil; local allSelected, i = true, nil; for i = 1, table.getn(raidNames) do if not controller.selectedRaids[raidNames[i]] then allSelected = false; break end end; allCheck:SetChecked(allSelected and 1 or nil); controller:Refresh() end)
        controller.raidChecks[raidNameIndex] = check
    end
    controller.listTitle = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal"); controller.listTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -120); controller.listTitle:SetText("Raids")
    controller.fromLabel = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontHighlightSmall"); controller.fromLabel:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 10, -38); controller.fromLabel:SetText("From")
    controller.fromDate = MOS.UI.Components.CreateFramedEditBox(controller.filterPanel, nil, 80); controller.fromDate:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 48, -33); controller.fromDate:SetMaxLetters(10); controller.fromDate:EnableKeyboard(false)
    controller.datePicker = MOS.UI.Components.CreateDatePicker("MuklaOfficerSuiteRaidStatisticsDatePicker")
    controller.dateDismiss = MOS.UI.Components.CreateControl(nil, UIParent); controller.dateDismiss:SetAllPoints(UIParent); controller.dateDismiss:SetFrameStrata("FULLSCREEN_DIALOG"); controller.dateDismiss:SetFrameLevel(3); controller.dateDismiss:Hide()
    controller.datePicker:SetFrameStrata("FULLSCREEN_DIALOG"); controller.datePicker:SetFrameLevel(4)
    local function CloseDatePicker() controller.datePicker:Hide(); controller.dateDismiss:Hide() end
    local function ToggleDatePicker(anchor, target)
        if controller.datePicker:IsShown() then CloseDatePicker() else controller.dateDismiss:Show(); controller.datePicker:Open(anchor, target) end
    end
    controller.dateDismiss:SetScript("OnClick", CloseDatePicker)
    local datePickerOnHide = controller.datePicker:GetScript("OnHide")
    controller.datePicker:SetScript("OnHide", function() if datePickerOnHide then datePickerOnHide() end; controller.dateDismiss:Hide() end)
    controller.fromPicker = MOS.UI.Components.CreateIconButton(controller.filterPanel, nil, "Interface\\Icons\\INV_Misc_PocketWatch_01", 20, 2); controller.fromPicker:SetPoint("LEFT", controller.fromDate, "RIGHT", 2, 0)
    controller.fromPicker:SetScript("OnClick", function() ToggleDatePicker(this, controller.fromDate) end)
    controller.toLabel = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontHighlightSmall"); controller.toLabel:SetPoint("LEFT", controller.fromPicker, "RIGHT", 7, 0); controller.toLabel:SetText("To")
    controller.toDate = MOS.UI.Components.CreateFramedEditBox(controller.filterPanel, nil, 80); controller.toDate:SetPoint("LEFT", controller.toLabel, "RIGHT", 7, 0); controller.toDate:SetMaxLetters(10); controller.toDate:EnableKeyboard(false)
    controller.toPicker = MOS.UI.Components.CreateIconButton(controller.filterPanel, nil, "Interface\\Icons\\INV_Misc_PocketWatch_01", 20, 2); controller.toPicker:SetPoint("LEFT", controller.toDate, "RIGHT", 2, 0)
    controller.toPicker:SetScript("OnClick", function() ToggleDatePicker(this, controller.toDate) end)
    controller.searchLabel = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontHighlightSmall"); controller.searchLabel:SetPoint("LEFT", controller.raidFilter, "RIGHT", 14, 0); controller.searchLabel:SetText("Search")
    controller.search = MOS.UI.Components.CreateSearchBox(controller.filterPanel, nil, 160); controller.search:SetPoint("LEFT", controller.searchLabel, "RIGHT", 6, 0); controller.search:SetScript("OnTextChanged", function() controller:Refresh() end)
    controller.applyDates = MOS.UI.Components.CreateButton(controller.filterPanel, nil, "Apply", 62, 22); controller.applyDates:SetPoint("LEFT", controller.toPicker, "RIGHT", 8, 0)
    controller.fromDate:SetScript("OnMouseDown", function() ToggleDatePicker(this, controller.fromDate) end); controller.toDate:SetScript("OnMouseDown", function() ToggleDatePicker(this, controller.toDate) end)
    MOS.UI.Components.AttachTooltip(controller.fromDate, "From date", "Optional date in YYYY-MM-DD format."); MOS.UI.Components.AttachTooltip(controller.toDate, "To date", "Optional date in YYYY-MM-DD format.")
    MOS.UI.Components.AttachTooltip(controller.fromPicker, "Choose From date", "Open the calendar."); MOS.UI.Components.AttachTooltip(controller.toPicker, "Choose To date", "Open the calendar.")
    controller.filterStatus = MOS.UI.Components.CreateHeading(page, "", 1, "gold"); controller.filterStatus:SetPoint("TOPLEFT", page, "TOPLEFT", 260, -120); controller.filterStatus:SetPoint("TOPRIGHT", page, "TOPRIGHT", -72, -120); controller.filterStatus:SetJustifyH("LEFT")
    controller.headerRemove = MOS.UI.Components.CreateIconButton(page, nil, "Interface\\Icons\\INV_Misc_Bag_09", 22, 2); controller.headerRemove:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -115); controller.headerRemove.statisticsController = controller; MOS.UI.Components.AttachGoldHoverBorder(controller.headerRemove, 0.35, 0.35, 0.35, 1); MOS.UI.Components.AttachTooltip(controller.headerRemove, "Remove raid", "Remove the selected raid from Raid Statistics and CSR history."); controller.headerRemove:Hide()
    controller.headerEdit = MOS.UI.Components.CreateIconButton(page, nil, "Interface\\Icons\\INV_Misc_Note_01", 22, 2); controller.headerEdit:SetPoint("RIGHT", controller.headerRemove, "LEFT", -5, 0); controller.headerEdit.statisticsController = controller; MOS.UI.Components.AttachGoldHoverBorder(controller.headerEdit, 0.35, 0.35, 0.35, 1); MOS.UI.Components.AttachTooltip(controller.headerEdit, "Edit raid", "Edit statistics options for the selected raid."); controller.headerEdit:Hide()
    controller.raidScroll = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteRaidStatisticsHistoryScroll", page, "FauxScrollFrameTemplate"); controller.raidScroll:SetPoint("TOPLEFT", page, "TOPLEFT", 8, -140); controller.raidScroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", 246, 10)
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteRaidStatisticsHistoryScrollScrollBar"))
    controller.raidScroll.refreshCallback = function() controller:Refresh() end; controller.raidScroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(28, this.refreshCallback) end)
    local index
    for index = 1, 20 do
        local button = MOS.UI.Components.CreateButton(page, nil, "", 234, 26); button:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -144 - ((index - 1) * 28)); button.statisticsController = controller; button:SetScript("OnClick", OnRaidSelect); button.label:Hide()
        button.allText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.allText:SetPoint("LEFT", button, "LEFT", 8, 0); button.allText:SetPoint("RIGHT", button, "RIGHT", -8, 0); button.allText:SetJustifyH("LEFT")
        button.idText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.idText:SetPoint("LEFT", button, "LEFT", 8, 0); button.idText:SetWidth(42); button.idText:SetJustifyH("LEFT")
        button.zoneText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.zoneText:SetPoint("LEFT", button, "LEFT", 51, 0); button.zoneText:SetWidth(57); button.zoneText:SetJustifyH("LEFT")
        button.dateText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontDisableSmall"); button.dateText:SetPoint("RIGHT", button, "RIGHT", -91, 0); button.dateText:SetWidth(55); button.dateText:SetJustifyH("RIGHT")
        button:Hide(); controller.raidButtons[index] = button
    end
    local function CreateModal(name, title, height)
        local dialog = MOS.UI.Components.CreateContainer(name, UIParent)
        dialog:SetWidth(360); dialog:SetHeight(height); dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
        dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetFrameLevel(245); dialog:EnableMouse(true)
        dialog:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
        dialog:SetBackdropColor(0.03, 0.025, 0.02, 1)
        if dialog.SetClampedToScreen then dialog:SetClampedToScreen(true) end
        dialog.title = MOS.UI.Components.CreateHeading(dialog, "", 1, "gold"); dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 18, -17); dialog.title:SetText(title)
        dialog:Hide(); return dialog
    end
    controller.removeDialog = CreateModal("MuklaOfficerSuiteRemoveRaidStatisticDialog", "Remove raid from history?", 145)
    controller.removeDialog.message = MOS.UI.Components.CreateLabel(controller.removeDialog, nil, "OVERLAY", "GameFontHighlight")
    controller.removeDialog.message:SetPoint("TOPLEFT", controller.removeDialog, "TOPLEFT", 18, -50); controller.removeDialog.message:SetWidth(324); controller.removeDialog.message:SetJustifyH("LEFT")
    controller.removeDialog.cancel = MOS.UI.Components.CreateButton(controller.removeDialog, nil, "Cancel", 86, 24); controller.removeDialog.cancel:SetPoint("BOTTOMLEFT", controller.removeDialog, "BOTTOMLEFT", 72, 18)
    controller.removeDialog.remove = MOS.UI.Components.CreateButton(controller.removeDialog, nil, "Remove", 86, 24); controller.removeDialog.remove:SetPoint("BOTTOMRIGHT", controller.removeDialog, "BOTTOMRIGHT", -72, 18)
    controller.removeDialog.cancel:SetScript("OnClick", function() controller.removeDialog:Hide() end)
    controller.removeDialog.remove:SetScript("OnClick", function()
        local raidId = controller.removeDialog.raidId
        controller.removeDialog:Hide()
        if raidId and controller.deleteEntry and controller.deleteEntry(raidId) then
            if controller.selectedId == raidId then controller.selectedId = nil end
            controller:Refresh()
        end
    end)
    controller.editDialog = CreateModal("MuklaOfficerSuiteEditRaidStatisticDialog", "Edit raid options", 175)
    local function CreateEditCheckbox(label, y)
        local checkbox = MOS.UI.Components.CreateCheckButton(nil, controller.editDialog, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", controller.editDialog, "TOPLEFT", 18, y); checkbox:SetWidth(22); checkbox:SetHeight(22)
        checkbox.label = MOS.UI.Components.CreateLabel(controller.editDialog, nil, "OVERLAY", "GameFontHighlightSmall"); checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 3, 0); checkbox.label:SetText(label)
        return checkbox
    end
    controller.editDialog.attendance = CreateEditCheckbox("Save attendance", -54)
    controller.editDialog.csr = CreateEditCheckbox("Save CSR", -84)
    controller.editDialog.cancel = MOS.UI.Components.CreateButton(controller.editDialog, nil, "Cancel", 86, 24); controller.editDialog.cancel:SetPoint("BOTTOMLEFT", controller.editDialog, "BOTTOMLEFT", 72, 18)
    controller.editDialog.save = MOS.UI.Components.CreateButton(controller.editDialog, nil, "Save", 86, 24); controller.editDialog.save:SetPoint("BOTTOMRIGHT", controller.editDialog, "BOTTOMRIGHT", -72, 18)
    controller.editDialog.cancel:SetScript("OnClick", function() controller.editDialog:Hide() end)
    controller.editDialog.save:SetScript("OnClick", function()
        local raidId = controller.editDialog.raidId
        local attendanceEnabled = controller.editDialog.attendance:GetChecked() and true or false
        local csrEnabled = controller.editDialog.csr:GetChecked() and true or false
        controller.editDialog:Hide()
        if raidId and controller.updateEntry and controller.updateEntry(raidId, attendanceEnabled, csrEnabled) then controller:Refresh() end
    end)
    local function OnEditRaid()
        local raidId = this.raidId
        local entries = controller.getEntries()
        local entry, entryIndex
        for entryIndex = 1, table.getn(entries) do if entries[entryIndex].id == raidId then entry = entries[entryIndex]; break end end
        if not entry then return end
        controller.editDialog.raidId = raidId
        controller.editDialog.attendance:SetChecked(entry.attendanceEnabled ~= false and 1 or nil)
        controller.editDialog.csr:SetChecked(entry.csrEnabled ~= false and 1 or nil)
        controller.editDialog:Show()
    end
    local function OnRemoveRaid()
        controller.removeDialog.raidId = this.raidId
        controller.removeDialog.message:SetText("Remove raid " .. tostring(this.raidId or "") .. " from Raid Statistics and CSR history?")
        controller.removeDialog:Show()
    end
    controller.headerEdit:SetScript("OnClick", OnEditRaid); controller.headerRemove:SetScript("OnClick", OnRemoveRaid)
    controller.playerHeader = MOS.UI.Components.CreateColumnLabel(page, "", "orange"); controller.playerHeader:SetPoint("TOPLEFT", page, "TOPLEFT", 264, -150); controller.playerHeader:SetText("Player")
    controller.attendanceHeader = MOS.UI.Components.CreateColumnLabel(page, "", "orange"); controller.attendanceHeader:SetPoint("TOPLEFT", page, "TOPLEFT", 386, -150); controller.attendanceHeader:SetWidth(66); controller.attendanceHeader:SetText("Attendance")
    controller.srHeader = MOS.UI.Components.CreateColumnLabel(page, "", "orange"); controller.srHeader:SetPoint("TOPLEFT", page, "TOPLEFT", 454, -150); controller.srHeader:SetText("SR")
    controller.lootHeader = MOS.UI.Components.CreateColumnLabel(page, "", "orange"); controller.lootHeader:SetPoint("TOPRIGHT", page, "TOPRIGHT", -32, -150); controller.lootHeader:SetWidth(28); controller.lootHeader:SetJustifyH("LEFT"); controller.lootHeader:SetText("Loot")
    controller.scroll = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteRaidStatisticsScroll", page, "FauxScrollFrameTemplate"); controller.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 260, -166); controller.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 10)
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteRaidStatisticsScrollScrollBar"))
    controller.scroll.refreshCallback = function() controller:Refresh() end; controller.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback) end)
    for index = 1, 25 do
        local row = MOS.UI.Components.CreateContainer(nil, page); row:SetPoint("TOPLEFT", page, "TOPLEFT", 264, -170 - ((index - 1) * 24)); row:SetPoint("RIGHT", page, "RIGHT", -32, 0); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0, 0, 0, 0)
        MOS.UI.Components.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8" }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
        row.name = MOS.UI.Components.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("LEFT", row, "LEFT", 0, 0); row.name:SetWidth(112); row.name:SetJustifyH("LEFT")
        row.attendance = MOS.UI.Components.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall"); row.attendance:SetPoint("LEFT", row, "LEFT", 122, 0); row.attendance:SetWidth(58)
        row.sr = MOS.UI.Components.CreateIconButton(row, nil, "Interface\\Icons\\INV_Misc_Note_01", 20, 2); row.sr:SetPoint("LEFT", row, "LEFT", 190, 0); row.sr.ownerRow = row; row.sr.itemKind = "sr"; row.sr.statisticsController = controller; row.sr:SetScript("OnClick", OnItemsClick)
        row.srDirect = MOS.UI.Components.CreateControl(nil, row); row.srDirect:SetPoint("LEFT", row, "LEFT", 190, 0); row.srDirect:SetPoint("RIGHT", row, "RIGHT", -42, 0); row.srDirect:SetHeight(22)
        row.srDirect.iconRegion = MOS.UI.Components.CreateTexture(row.srDirect, nil, "ARTWORK"); row.srDirect.iconRegion:SetPoint("LEFT", row.srDirect, "LEFT", 0, 0); row.srDirect.iconRegion:SetWidth(19); row.srDirect.iconRegion:SetHeight(19)
        row.srDirect.label = MOS.UI.Components.CreateLabel(row.srDirect, nil, "OVERLAY", "GameFontHighlightSmall"); row.srDirect.label:SetPoint("LEFT", row.srDirect.iconRegion, "RIGHT", 5, 0); row.srDirect.label:SetPoint("RIGHT", row.srDirect, "RIGHT", 0, 0); row.srDirect.label:SetJustifyH("LEFT")
        row.srDirect:SetScript("OnEnter", OnDirectItemEnter); row.srDirect:SetScript("OnLeave", function() GameTooltip:Hide() end); row.srDirect:SetScript("OnClick", function() MOS.UI.Components.HandleItemClick(this) end); row.srDirect:Hide()
        row.srMissing = MOS.UI.Components.CreateLabel(row, nil, "OVERLAY", "GameFontHighlightSmall"); row.srMissing:SetPoint("LEFT", row, "LEFT", 190, 0); row.srMissing:SetText("-"); row.srMissing:Hide()
        row.loot = MOS.UI.Components.CreateIconButton(row, nil, "Interface\\Icons\\INV_Misc_Bag_10", 20, 2); row.loot:SetPoint("RIGHT", row, "RIGHT", -8, 0); row.loot.ownerRow = row; row.loot.itemKind = "loot"; row.loot.statisticsController = controller; row.loot:SetScript("OnClick", OnItemsClick)
        MOS.UI.Components.AttachTooltip(row.sr, "Soft Reserves", "Show every item reserved by this player in the selected raids."); MOS.UI.Components.AttachTooltip(row.loot, "Loot received", "Show every recorded item received by this player in the selected raids.")
        row:Hide(); controller.rows[index] = row
    end
    function controller:Refresh()
        MOS.Diagnostics.Count("uiRefreshes")
        local entries, filterError = MOS.Services.RaidStatistics.FilterEntries(self.getEntries(), self.fromDate:GetText(), self.toDate:GetText(), self.filteredEntries, self.selectedRaids, self.search:GetText())
        if not entries then self.filterStatus:SetText(filterError); entries = self.filteredEntries end
        local selectedRaid = nil
        if self.selectedId then for index = 1, table.getn(entries) do if entries[index].id == self.selectedId then selectedRaid = entries[index]; break end end end
        if self.selectedId and not selectedRaid then self.selectedId = nil end
        if filterError then self.headerEdit:Hide(); self.headerRemove:Hide()
        elseif selectedRaid then self.filterStatus:SetText(tostring(selectedRaid.id) .. " | " .. tostring(selectedRaid.raidName or "Unknown zone") .. " | " .. date("%Y-%m-%d", tonumber(selectedRaid.savedAt) or 0)); self.headerEdit.raidId = selectedRaid.id; self.headerRemove.raidId = selectedRaid.id; self.headerEdit:Show(); self.headerRemove:Show()
        else self.filterStatus:SetText("Raid Statistics"); self.headerEdit:Hide(); self.headerRemove:Hide() end
        local visibleRaids = math.max(1, math.min(table.getn(self.raidButtons), math.floor(math.max(28, self.raidScroll:GetHeight()) / 28)))
        local raidOffset = MOS.UI.Components.UpdateScrollFrame(self.raidScroll, table.getn(entries), visibleRaids, 28)
        for index = 1, table.getn(self.raidButtons) do
            local button, logicalIndex = self.raidButtons[index], raidOffset + index
            local raid = entries[logicalIndex]
            if raid and index <= visibleRaids then
                button.raidId = raid.id
                button.allText:SetText(tostring(raid.id) .. "  |  " .. tostring(raid.raidName or "Unknown") .. "  |  " .. date("%Y-%m-%d", tonumber(raid.savedAt) or 0)); button.allText:Show(); button.idText:Hide(); button.zoneText:Hide(); button.dateText:Hide()
                local selected = self.selectedId == raid.id; button:SetBackdropColor(selected and 0.32 or 0.12, selected and 0.19 or 0.07, 0.02, 0.96); button:Show()
                MOS.UI.Components.SetClassicButtonSelected(button, selected)
            else MOS.UI.Components.SetClassicButtonSelected(button, false); button:Hide() end
        end
        local summary = MOS.Services.RaidStatistics.BuildSummary(entries, self.selectedId)
        local visible = math.max(1, math.min(table.getn(self.rows), math.floor(math.max(24, self.scroll:GetHeight()) / 24)))
        local offset = MOS.UI.Components.UpdateScrollFrame(self.scroll, table.getn(summary.players), visible, 24)
        for index = 1, table.getn(self.rows) do
            local row, player = self.rows[index], summary.players[offset + index]
            if player and index <= visible then
                row.player = player; row.name:SetText(player.name); row.attendance:SetText(player.attendanceOff and "Off" or player.raids); row.loot:SetInactive(table.getn(player.lootItems or {}) == 0)
                row.srMissing:Hide()
                if self.selectedId and player.srItems and player.srItems[1] and player.srItems[1].itemId then
                    local item = player.srItems[1]; row.sr:Hide(); row.srDirect.itemId = item.itemId; row.srDirect.itemName = item.name; row.srDirect.label:SetText(MOS.UI.Components.GetItemLabel(item.itemId) .. (table.getn(player.srItems) > 1 and (" +" .. (table.getn(player.srItems) - 1)) or "")); row.srDirect:Show()
                    local texture = type(GetItemIcon) == "function" and GetItemIcon(item.itemId) or nil; row.srDirect.iconRegion:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                elseif self.selectedId then row.srDirect.itemId = nil; row.srDirect:Hide(); row.sr:Hide(); row.srMissing:Show()
                else row.srDirect.itemId = nil; row.srDirect:Hide(); row.sr:SetInactive(table.getn(player.srItems or {}) == 0); row.sr:Show() end
                row:Show()
            else row.player = nil; row.srDirect.itemId = nil; row.srDirect:Hide(); row.srMissing:Hide(); row:Hide() end
        end
    end
    controller.applyDates:SetScript("OnClick", function() controller.selectedId = nil; controller.raidScroll.offset = 0; controller.scroll.offset = 0; controller:Refresh() end)
    return {
        Hide = function(self) controller.raidPanel:Hide(); controller.raidDismiss:Hide(); controller.dateDismiss:Hide(); controller.itemDialog:Hide(); controller.datePicker:Hide(); controller.editDialog:Hide(); controller.removeDialog:Hide(); page:Hide() end,
        Show = function(self) page:Show(); controller:Refresh() end,
        Refresh = function(self) controller:Refresh() end,
        OnResize = function(self) controller.datePicker:Hide(); controller:Refresh() end,
        SelectRaid = function(self, raidId) controller.selectedId = raidId; controller.raidScroll.offset = 0; controller.scroll.offset = 0; controller:Refresh() end,
    }
end
