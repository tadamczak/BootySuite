local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components

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

function RaidStatistics.Create(host, getEntries, deleteEntry, updateEntry)
    local page=UI.CreateResponsiveCanvas(host,"MOSRaidStatisticsPage")
    local controller = { page = page, getEntries = getEntries, deleteEntry = deleteEntry, updateEntry = updateEntry, selectedId = nil, raidButtons = {}, rows = {}, filteredEntries = {}, selectedRaids = {} }
    page.statisticsController = controller
    host.statisticsController = controller
    controller.itemDialog = MOS.UI.Components.CreateItemListDialog("MuklaOfficerSuiteRaidStatisticsItems")
    controller.title = MOS.UI.Components.CreateHeading(page, "", 1, "gold"); controller.title:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -10); controller.title:SetText("Raid Statistics")
    local raidNames = MOS.Services.RaidStatistics.GetRaidNames(); local raidNameIndex
    for raidNameIndex = 1, table.getn(raidNames) do controller.selectedRaids[raidNames[raidNameIndex]] = true end
    controller.filterPanel = MOS.UI.Components.CreateContainer(nil, page); controller.filterPanel:SetPoint("TOPLEFT", page, "TOPLEFT", 2, -40); controller.filterPanel:SetPoint("TOPRIGHT", page, "TOPRIGHT", -8, -40); controller.filterPanel:SetHeight(66)
    controller.filterPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }); controller.filterPanel:SetBackdropColor(0.035, 0.03, 0.02, 0.94); controller.filterPanel:SetBackdropBorderColor(0.42, 0.34, 0.18, 1)
    controller.filterTitle = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontNormalSmall"); controller.filterTitle:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 10, -8); controller.filterTitle:SetText("Filters")
    controller.raidFilter = MOS.UI.Components.CreateDropdownButton(controller.filterPanel, nil, "Raid", 140); controller.raidFilter:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 62, -6)
    controller.raidPanel = MOS.UI.Components.CreateDropdownPanel(controller.filterPanel, controller.raidFilter, 190, 178, 20)
    controller.raidDismiss = controller.raidPanel.dismiss
    controller.raidFilter:SetScript("OnClick", function() if controller.raidPanel:IsVisible() then controller.raidPanel:Hide() else controller.datePicker:Hide();controller.raidPanel:Show() end end)
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
    controller.listTitle = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal"); controller.listTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -120); controller.listTitle:SetText("Raids")
    controller.historyToggle = MOS.UI.Components.CreateButton(page, nil, "<<", 22, 20)
    MOS.UI.Components.SetClassicButtonCompact(controller.historyToggle, true); MOS.UI.Components.AttachGoldHoverBorder(controller.historyToggle, 0.35, 0.35, 0.35, 1)
    MOS.UI.Components.AttachTooltip(controller.historyToggle, "Saved raids", "Collapse or restore the saved raid list.")
    controller.historyToggle:SetScript("OnClick", function() controller.historyCollapsed = not controller.historyCollapsed; controller:Refresh() end)
    controller.historyHeaders = {}
    for index, text in ipairs({"Name", "Raid", "Time"}) do controller.historyHeaders[index] = MOS.UI.Components.CreateColumnLabel(page, text, "gold") end
    controller.fromLabel = MOS.UI.Components.CreateLabel(controller.filterPanel, nil, "OVERLAY", "GameFontHighlightSmall"); controller.fromLabel:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 10, -38); controller.fromLabel:SetText("From")
    controller.fromDate = MOS.UI.Components.CreateFramedEditBox(controller.filterPanel, nil, 80); controller.fromDate:SetPoint("TOPLEFT", controller.filterPanel, "TOPLEFT", 48, -33); controller.fromDate:SetMaxLetters(10); controller.fromDate:EnableKeyboard(false)
    controller.datePicker = MOS.UI.Components.CreateDatePicker("MuklaOfficerSuiteRaidStatisticsDatePicker")
    controller.dateDismiss = MOS.UI.Components.CreateControl(nil, UIParent); controller.dateDismiss:SetAllPoints(UIParent); controller.dateDismiss:SetFrameStrata("FULLSCREEN_DIALOG"); controller.dateDismiss:SetFrameLevel(3); controller.dateDismiss:Hide()
    controller.datePicker:SetFrameStrata("FULLSCREEN_DIALOG"); controller.datePicker:SetFrameLevel(4)
    local function CloseDatePicker() controller.datePicker:Hide(); controller.dateDismiss:Hide() end
    local function ToggleDatePicker(anchor, target)
        if controller.datePicker:IsShown() then CloseDatePicker() else
            controller.raidPanel:Hide()
            local level=math.max(230,page:GetFrameLevel()+30)
            controller.dateDismiss:SetFrameLevel(level);controller.datePicker:SetFrameLevel(level+1)
            controller.dateDismiss:Show(); controller.datePicker:Open(anchor, target)
        end
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
    controller.search = MOS.UI.Components.CreateFramedEditBox(controller.filterPanel, nil, 160); controller.search:SetPoint("LEFT", controller.searchLabel, "RIGHT", 6, 0); controller.search:SetScript("OnTextChanged", function() controller:Refresh() end)
    controller.applyDates = MOS.UI.Components.CreateButton(controller.filterPanel, nil, "Apply", 62, 22); controller.applyDates:SetPoint("LEFT", controller.toPicker, "RIGHT", 8, 0)
    controller.fromDate:SetScript("OnMouseDown", function() ToggleDatePicker(this, controller.fromDate) end); controller.toDate:SetScript("OnMouseDown", function() ToggleDatePicker(this, controller.toDate) end)
    MOS.UI.Components.AttachTooltip(controller.fromDate, "From date", "Optional date in YYYY-MM-DD format."); MOS.UI.Components.AttachTooltip(controller.toDate, "To date", "Optional date in YYYY-MM-DD format.")
    MOS.UI.Components.AttachTooltip(controller.fromPicker, "Choose From date", "Open the calendar."); MOS.UI.Components.AttachTooltip(controller.toPicker, "Choose To date", "Open the calendar.")
    controller.filterStatus = MOS.UI.Components.CreateHeading(page, "", 1, "gold"); controller.filterStatus:SetPoint("TOPLEFT", page, "TOPLEFT", 260, -120); controller.filterStatus:SetPoint("TOPRIGHT", page, "TOPRIGHT", -72, -120); controller.filterStatus:SetJustifyH("LEFT")
    controller.headerRemove = MOS.UI.Components.CreateDeleteButton(page, nil, 22, 2); controller.headerRemove:SetPoint("TOPRIGHT", page, "TOPRIGHT", -6, -115); controller.headerRemove.statisticsController = controller; MOS.UI.Components.AttachGoldHoverBorder(controller.headerRemove, 0.35, 0.35, 0.35, 1); MOS.UI.Components.AttachTooltip(controller.headerRemove, "Remove raid", "Remove the selected raid from Raid Statistics and CSR history."); controller.headerRemove:Hide()
    controller.headerEdit = MOS.UI.Components.CreateIconButton(page, nil, "Interface\\Icons\\INV_Misc_Note_01", 22, 2); controller.headerEdit:SetPoint("RIGHT", controller.headerRemove, "LEFT", -5, 0); controller.headerEdit.statisticsController = controller; MOS.UI.Components.AttachGoldHoverBorder(controller.headerEdit, 0.35, 0.35, 0.35, 1); MOS.UI.Components.AttachTooltip(controller.headerEdit, "Edit raid", "Edit statistics options for the selected raid."); controller.headerEdit:Hide()
    controller.raidScroll = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteRaidStatisticsHistoryScroll", page, "FauxScrollFrameTemplate"); controller.raidScroll:SetPoint("TOPLEFT", page, "TOPLEFT", 2, -140); controller.raidScroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMLEFT", 246, 5)
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteRaidStatisticsHistoryScrollScrollBar"))
    controller.raidScroll.refreshCallback = function() controller:Refresh() end; controller.raidScroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(28, this.refreshCallback) end)
    local index
    for index = 1, 20 do
        local button = MOS.UI.Components.CreateSelectionButton(page, nil, "", 234, 26); button:SetPoint("TOPLEFT", page, "TOPLEFT", 6, -144 - ((index - 1) * 28)); button.statisticsController = controller; button:SetScript("OnClick", OnRaidSelect); button.label:Hide()
        button.allText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.allText:SetPoint("LEFT", button, "LEFT", 8, 0); button.allText:SetPoint("RIGHT", button, "RIGHT", -8, 0); button.allText:SetJustifyH("LEFT")
        button.idText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.idText:SetPoint("LEFT", button, "LEFT", 8, 0); button.idText:SetWidth(42); button.idText:SetJustifyH("LEFT")
        button.zoneText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontHighlightSmall"); button.zoneText:SetPoint("LEFT", button, "LEFT", 51, 0); button.zoneText:SetWidth(57); button.zoneText:SetJustifyH("LEFT")
        button.dateText = MOS.UI.Components.CreateLabel(button, nil, "OVERLAY", "GameFontDisableSmall"); button.dateText:SetPoint("RIGHT", button, "RIGHT", -91, 0); button.dateText:SetWidth(55); button.dateText:SetJustifyH("RIGHT")
        UI.AttachTooltip(button,"Saved raid",function() return this.allText:GetText() end)
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
        local messageHeight=math.max(32,controller.removeDialog.message:GetStringHeight())
        controller.removeDialog.message:SetHeight(messageHeight);controller.removeDialog:SetHeight(messageHeight+78)
        controller.removeDialog:Show()
    end
    controller.headerEdit:SetScript("OnClick", OnEditRaid); controller.headerRemove:SetScript("OnClick", OnRemoveRaid)
    UI.Window.StyleProjectDialog(controller.removeDialog); UI.Window.StyleProjectDialog(controller.editDialog)
    controller.playerHeader = MOS.UI.Components.Table.CreateHeader(page, nil, "Player", 264, -150, 120, nil, false)
    controller.attendanceHeader = MOS.UI.Components.Table.CreateHeader(page, nil, "Attendance", 386, -150, 66, nil, false)
    controller.srHeader = MOS.UI.Components.Table.CreateHeader(page, nil, "SR", 454, -150, 50, nil, false)
    controller.lootHeader = MOS.UI.Components.Table.CreateHeader(page, nil, "Loot", 0, -150, 28, nil, false)
    controller.lootHeader:ClearAllPoints(); controller.lootHeader:SetPoint("TOPRIGHT", page, "TOPRIGHT", -32, -150)
    controller.playerHeader:SetHeight(18); controller.attendanceHeader:SetHeight(18); controller.srHeader:SetHeight(18); controller.lootHeader:SetHeight(18)
    controller.scroll = MOS.UI.Components.CreateScrollFrame("MuklaOfficerSuiteRaidStatisticsScroll", page, "FauxScrollFrameTemplate"); controller.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 260, -166); controller.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -22, 5)
    MOS.UI.Components.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteRaidStatisticsScrollScrollBar"))
    controller.scroll.refreshCallback = function() controller:Refresh() end; controller.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback) end)
    for index = 1, 25 do
        local row = MOS.UI.Components.CreateContainer(nil, page); row:SetPoint("TOPLEFT", page, "TOPLEFT", 264, -170 - ((index - 1) * 24)); row:SetPoint("RIGHT", page, "RIGHT", -26, 0); row:SetHeight(23)
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
    UI.StyleProjectPopup(controller.raidPanel); UI.StyleProjectPopup(controller.datePicker)
    for _,button in ipairs(controller.datePicker.days) do UI.ApplyDropdownChoiceSurface(button);UI.AttachGoldHoverBorder(button,0.35,0.35,0.35,1) end
    UI.ApplyDropdownChoiceSurface(controller.datePicker.previous);UI.ApplyDropdownChoiceSurface(controller.datePicker.next)
    controller.raidPanel:SetHeight(8+20+table.getn(controller.raidChecks)*23)
    controller.raidPanel.options=controller.raidChecks;controller.raidPanel.selectAll=allCheck
    local choiceWidth=130
    for _,check in ipairs(controller.raidChecks) do choiceWidth=math.max(choiceWidth,check.label:GetStringWidth()+30) end
    controller.raidPanel:SetWidth(choiceWidth)
    allCheck:ClearAllPoints();allCheck:SetPoint("TOPLEFT",controller.raidPanel,"TOPLEFT",4,-4)
    for i=1,table.getn(controller.raidChecks) do controller.raidChecks[i]:ClearAllPoints();controller.raidChecks[i]:SetPoint("TOPLEFT",controller.raidPanel,"TOPLEFT",4,-4-i*23) end
    UI.RegisterSkinnedSurface(controller.filterPanel,"content")
    UI.SetSurfaceHorizontalBorders(controller.filterPanel,true,true)
    controller.filterTitle:Hide()
    local function Group(width)
        local group=UI.CreateContainer(nil,controller.filterPanel);group:SetWidth(width);group:SetHeight(26);group.mosFlowWidth=width;return group
    end
    controller.searchGroup=Group(166)
    controller.searchLabel:ClearAllPoints();controller.searchLabel:SetPoint("LEFT",controller.searchGroup,"LEFT",0,0)
    controller.search:SetParent(controller.searchGroup);controller.search:ClearAllPoints();controller.search:SetPoint("LEFT",controller.searchGroup,"LEFT",42,0);controller.search:SetWidth(124)
    controller.fromGroup=Group(130);controller.toGroup=Group(114)
    for _,key in ipairs({"from","to"}) do
        local group=controller[key.."Group"];local label=controller[key.."Label"];local field=controller[key.."Date"];local picker=controller[key.."Picker"]
        label:ClearAllPoints();label:SetPoint("LEFT",group,"LEFT",0,0)
        field:SetParent(group);field:ClearAllPoints();field:SetPoint("LEFT",group,"LEFT",key=="from" and 32 or 16,0);field:SetWidth(76)
        picker:SetParent(group);picker:ClearAllPoints();picker:SetPoint("LEFT",field,"RIGHT",2,0);picker:SetWidth(18);picker:SetHeight(18)
    end
    controller.raidFilter:SetHeight(26);controller.raidFilter.mosFlowWidth=130
    controller.applyDates:SetWidth(54);controller.applyDates.mosFlowWidth=54
    controller.flow={controller.raidFilter,controller.searchGroup,controller.fromGroup,controller.toGroup,controller.applyDates}
    UI.StyleActionButton(controller.applyDates)
    for _,dialog in ipairs({controller.removeDialog,controller.editDialog}) do
        dialog:SetWidth(320)
        if not dialog.close then dialog.close=UI.CreateWindowButton(dialog,nil,"close");dialog.close:SetPoint("TOPRIGHT",dialog,"TOPRIGHT",-6,-6);dialog.close:SetScript("OnClick",function() this:GetParent():Hide() end) end
        local action=dialog.remove or dialog.save
        UI.StyleActionButton(action);UI.StyleActionButton(dialog.cancel)
        action:ClearAllPoints();action:SetPoint("BOTTOMRIGHT",dialog,"BOTTOMRIGHT",-8,8)
        dialog.cancel:ClearAllPoints();dialog.cancel:SetPoint("RIGHT",action,"LEFT",-8,0)
    end
    controller.removeDialog.message:ClearAllPoints();controller.removeDialog.message:SetPoint("TOPLEFT",controller.removeDialog,"TOPLEFT",8,-36);controller.removeDialog.message:SetWidth(304);controller.removeDialog.message:SetJustifyH("CENTER")
    controller.editDialog.attendance:ClearAllPoints();controller.editDialog.attendance:SetPoint("TOPLEFT",controller.editDialog,"TOPLEFT",8,-36)
    controller.editDialog.csr:ClearAllPoints();controller.editDialog.csr:SetPoint("TOPLEFT",controller.editDialog,"TOPLEFT",8,-66)
    UI.BindCheckboxLabel(controller.editDialog.attendance,function() end);UI.BindCheckboxLabel(controller.editDialog.csr,function() end)
    controller.editDialog:SetHeight(128)
    controller.datePicker:SetHeight(236)
    controller.datePicker.clear=UI.CreateButton(controller.datePicker,nil,"Clear date",100,26)
    UI.StyleActionButton(controller.datePicker.clear)
    controller.datePicker.clear:SetPoint("BOTTOMRIGHT",controller.datePicker,"BOTTOMRIGHT",-8,8)
    controller.datePicker.clear:SetScript("OnClick",function()
        if controller.datePicker.target then controller.datePicker.target:SetText("") end
        controller.datePicker:Hide()
    end)
    controller.emptyHistory=UI.CreateLabel(page,nil,"OVERLAY","GameFontDisableSmall");controller.emptyHistory:SetText("No matching saved raids.")
    controller.emptyPlayers=UI.CreateLabel(page,nil,"OVERLAY","GameFontDisableSmall");controller.emptyPlayers:SetText("No matching players.")
    UI.AttachLabelTooltip(page,controller.filterStatus,"Selected raids",function() return controller.filterStatus:GetText() end)
    controller.headers={controller.playerHeader,controller.attendanceHeader,controller.srHeader,controller.lootHeader}
    local function LayoutContent(width,height,self)
        local available=math.max(80,width-16)
        self.title:ClearAllPoints();self.title:SetPoint("TOPLEFT",page,"TOPLEFT",8,-8);UI.FitButtonLabel(self.title,available)
        self.filterPanel:ClearAllPoints();self.filterPanel:SetPoint("TOPLEFT",page,"TOPLEFT",0,-38);self.filterPanel:SetWidth(width)
        local filterBottom=UI.LayoutFlow(self.filterPanel,self.flow,4,8,available,6)+8
        self.filterPanel:SetHeight(filterBottom)
        self.search:SetWidth(math.max(24,self.searchGroup:GetWidth()-42))
        for _,key in ipairs({"from","to"}) do
            self[key.."Date"]:SetWidth(math.max(24,self[key.."Group"]:GetWidth()-(key=="from" and 54 or 38)))
        end
        local top=38+filterBottom+8
        local stacked=available<650
        local historyWidth=stacked and available or math.min(270,available*0.34)
        local remaining=math.max(96,height-top-8)
        local historyHeight=stacked and math.max(56,math.min(84,math.floor((remaining-100)/28)*28)) or remaining-44
        self.listTitle:ClearAllPoints();self.listTitle:SetPoint("TOPLEFT",page,"TOPLEFT",8,-top);self.listTitle:SetWidth(historyWidth)
        self.historyToggle:ClearAllPoints();self.historyToggle:SetPoint("TOPLEFT",page,"TOPLEFT",8+historyWidth-22,-top+1);self.historyToggle:SetText(self.historyCollapsed and ">>" or "<<")
        local headerX=8
        local headerName=math.floor(historyWidth*0.38);local headerRaid=math.floor(historyWidth*0.34);local headerTime=historyWidth-headerName-headerRaid
        local headerWidths={headerName,headerRaid,headerTime}
        for index=1,3 do local header=self.historyHeaders[index];header:ClearAllPoints();header:SetPoint("TOPLEFT",page,"TOPLEFT",headerX,-top-24);header:SetWidth(headerWidths[index]);header:SetHeight(18);headerX=headerX+headerWidths[index] end
        self.historyRect=self.historyRect or {}
        self.historyRect.x=8;self.historyRect.y=top+44;self.historyRect.width=historyWidth;self.historyRect.height=historyHeight
        local playerX=self.historyCollapsed and 8 or (stacked and 8 or 8+historyWidth+12)
        local playerTop=self.historyCollapsed and top+28 or (stacked and top+44+historyHeight+8 or top)
        local playerWidth=self.historyCollapsed and available or (stacked and available or available-historyWidth-12)
        if self.historyCollapsed then
            self.listTitle:SetWidth(math.max(1,available-28));self.historyToggle:ClearAllPoints();self.historyToggle:SetPoint("TOPRIGHT",page,"TOPRIGHT",-8,-top+1)
            for index=1,3 do self.historyHeaders[index]:Hide() end
        else for index=1,3 do self.historyHeaders[index]:Show() end end
        local statusHeight=self.showResultStatus and 22 or 0
        self.filterStatus:ClearAllPoints();self.filterStatus:SetPoint("TOPLEFT",page,"TOPLEFT",playerX,-playerTop);self.filterStatus:SetWidth(math.max(1,playerWidth-54))
        local font,_,flags=self.filterStatus:GetFont();self.filterStatus:SetFont(font,12,flags);self.filterStatus:SetHeight(18)
        if self.filterStatus.SetWordWrap then self.filterStatus:SetWordWrap(false) end
        self.headerRemove:ClearAllPoints();self.headerRemove:SetPoint("TOPLEFT",page,"TOPLEFT",playerX+playerWidth-18,-playerTop);self.headerRemove:SetWidth(16);self.headerRemove:SetHeight(16)
        self.headerEdit:SetWidth(18);self.headerEdit:SetHeight(18)
        self.playerRect=self.playerRect or {}
        self.playerRect.x=playerX;self.playerRect.y=playerTop+statusHeight+22;self.playerRect.width=playerWidth;self.playerRect.height=math.max(48,height-playerTop-statusHeight-30)
        return self.playerRect.y+self.playerRect.height+8
    end
    function controller:Layout() UI.LayoutResponsiveCanvas(page,LayoutContent,self) end
    function controller:LayoutColumns(width)
        local nameWidth=math.floor(width*0.30);local attendanceWidth=math.floor(width*0.23);local lootWidth=32
        local srX=nameWidth+attendanceWidth;local srWidth=math.max(24,width-srX-lootWidth)
        self.directItemLabel=srWidth>=90
        local starts={0,nameWidth,srX,width-lootWidth};local widths={nameWidth,attendanceWidth,srWidth,lootWidth}
        for i=1,4 do local header=self.headers[i];header:ClearAllPoints();header:SetPoint("TOPLEFT",page,"TOPLEFT",self.playerRect.x+starts[i],-self.playerRect.y+22);header:SetWidth(widths[i]);header:SetHeight(20) end
        self.attendanceHeader.label:SetText(width<420 and "Raids" or "Attendance")
        UI.Table.FitHeaders(self.headers,12)
        for _,row in ipairs(self.rows) do
            UI.Table.Cell(row.name,row,4,nameWidth-6,23);UI.Table.Cell(row.attendance,row,nameWidth,attendanceWidth-4,23)
            row.sr:ClearAllPoints();row.sr:SetPoint("LEFT",row,"LEFT",srX,0)
            row.srDirect:ClearAllPoints();row.srDirect:SetPoint("LEFT",row,"LEFT",srX,0);row.srDirect:SetWidth(srWidth-4)
            UI.Table.Cell(row.srMissing,row,srX,srWidth-4,23)
            row.loot:ClearAllPoints();row.loot:SetPoint("LEFT",row,"LEFT",width-lootWidth+4,0)
        end
    end
    function controller:Refresh()
        if not host:IsShown() or self.refreshing then return end
        self.refreshing=true
        MOS.Diagnostics.Count("uiRefreshes")
        local entries, filterError = MOS.Services.RaidStatistics.FilterEntries(self.getEntries(), self.fromDate:GetText(), self.toDate:GetText(), self.filteredEntries, self.selectedRaids, self.search:GetText())
        if not entries then self.filterStatus:SetText(filterError);while table.getn(self.filteredEntries)>0 do table.remove(self.filteredEntries) end;entries=self.filteredEntries end
        local selectedRaid = nil
        if self.selectedId then for index = 1, table.getn(entries) do if entries[index].id == self.selectedId then selectedRaid = entries[index]; break end end end
        if self.selectedId and not selectedRaid then self.selectedId = nil end
        self.showResultStatus=filterError or selectedRaid
        if filterError then self.filterStatus:SetText(filterError);self.filterStatus:Show();self.headerEdit:Hide(); self.headerRemove:Hide()
        elseif selectedRaid then self.filterStatus:SetText(tostring(selectedRaid.id) .. " | " .. tostring(selectedRaid.raidName or "Unknown zone") .. " | " .. date("%Y-%m-%d", tonumber(selectedRaid.savedAt) or 0)); self.filterStatus:Show();self.headerEdit.raidId = selectedRaid.id; self.headerRemove.raidId = selectedRaid.id; self.headerEdit:Show(); self.headerRemove:Show()
        else self.filterStatus:SetText("");self.filterStatus:Hide(); self.headerEdit:Hide(); self.headerRemove:Hide() end
        self:Layout()
        local rect=self.historyRect
        local raidOffset,visibleRaids,historyWidth=0,0,rect.width
        if self.historyCollapsed then
            self.raidScroll:Hide();UI.SetScrollBarVisible(getglobal("MuklaOfficerSuiteRaidStatisticsHistoryScrollScrollBar"),false)
        else raidOffset,visibleRaids,historyWidth=UI.Table.LayoutViewport(self.raidScroll,page,rect.x,rect.y,rect.width,rect.height,table.getn(entries),28,table.getn(self.raidButtons)) end
        for index = 1, table.getn(self.raidButtons) do
            local button, logicalIndex = self.raidButtons[index], raidOffset + index
            local raid = entries[logicalIndex]
            if raid and index <= visibleRaids then
                button:ClearAllPoints();button:SetPoint("TOPLEFT",page,"TOPLEFT",rect.x,-rect.y-(index-1)*28);button:SetWidth(historyWidth)
                button.raidId = raid.id
                local nameWidth=math.floor(historyWidth*0.38);local raidWidth=math.floor(historyWidth*0.34);local timeWidth=historyWidth-nameWidth-raidWidth
                button.idText:ClearAllPoints();button.idText:SetPoint("LEFT",button,"LEFT",6,0);button.idText:SetWidth(nameWidth-8);button.idText:SetJustifyH("LEFT");button.idText:SetText(tostring(raid.id));button.idText:Show()
                button.zoneText:ClearAllPoints();button.zoneText:SetPoint("LEFT",button,"LEFT",nameWidth,0);button.zoneText:SetWidth(raidWidth-4);button.zoneText:SetJustifyH("LEFT");button.zoneText:SetText(tostring(raid.raidName or "Unknown"));button.zoneText:Show()
                button.dateText:ClearAllPoints();button.dateText:SetPoint("LEFT",button,"LEFT",nameWidth+raidWidth,0);button.dateText:SetWidth(timeWidth-4);button.dateText:SetJustifyH("LEFT");button.dateText:SetText(date("%Y-%m-%d",tonumber(raid.savedAt) or 0));button.dateText:Show();button.allText:Hide()
                local selected = self.selectedId == raid.id; button:Show()
                MOS.UI.Components.SetClassicButtonSelected(button, selected)
                MOS.UI.Components.StyleWarmListRow(button, selected)
            else MOS.UI.Components.SetClassicButtonSelected(button, false); button:Hide() end
        end
        local summary = MOS.Services.RaidStatistics.BuildSummary(entries, self.selectedId)
        local body=self.playerRect
        local offset,visible,rowWidth=UI.Table.LayoutViewport(self.scroll,page,body.x,body.y,body.width,body.height,table.getn(summary.players),24,table.getn(self.rows))
        self:LayoutColumns(rowWidth)
        self.emptyHistory:ClearAllPoints();self.emptyHistory:SetPoint("TOPLEFT",page,"TOPLEFT",rect.x,-rect.y-4);self.emptyHistory:SetWidth(historyWidth)
        self.emptyPlayers:ClearAllPoints();self.emptyPlayers:SetPoint("TOPLEFT",page,"TOPLEFT",body.x,-body.y-4);self.emptyPlayers:SetWidth(rowWidth)
        if not self.historyCollapsed and table.getn(entries)==0 then self.emptyHistory:Show() else self.emptyHistory:Hide() end
        if table.getn(summary.players)==0 then self.emptyPlayers:Show() else self.emptyPlayers:Hide() end
        for index = 1, table.getn(self.rows) do
            local row, player = self.rows[index], summary.players[offset + index]
            if player and index <= visible then
                row:ClearAllPoints();row:SetPoint("TOPLEFT",page,"TOPLEFT",body.x,-body.y-(index-1)*24);row:SetWidth(rowWidth)
                UI.ApplyRowBackground(row,offset+index,false)
                row.player = player; row.name:SetText(player.name)
                local classKey=string.upper(tostring(player.class or ""));local classColor=(RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]) or UI.Theme.classColors[classKey]
                if classColor then row.name:SetTextColor(classColor.r,classColor.g,classColor.b) else row.name:SetTextColor(1,1,1) end
                row.attendance:SetText(player.attendanceOff and "Off" or player.raids); row.loot:SetInactive(table.getn(player.lootItems or {}) == 0)
                row.srMissing:Hide()
                if self.selectedId and self.directItemLabel and player.srItems and player.srItems[1] and player.srItems[1].itemId then
                    local item = player.srItems[1]; row.sr:Hide(); row.srDirect.itemId = item.itemId; row.srDirect.itemName = item.name; row.srDirect.label:SetText(MOS.UI.Components.GetItemLabel(item.itemId) .. (table.getn(player.srItems) > 1 and (" +" .. (table.getn(player.srItems) - 1)) or "")); row.srDirect:Show()
                    local texture = type(GetItemIcon) == "function" and GetItemIcon(item.itemId) or nil; row.srDirect.iconRegion:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
                elseif self.selectedId and table.getn(player.srItems or {})==0 then row.srDirect.itemId = nil; row.srDirect:Hide(); row.sr:Hide(); row.srMissing:Show()
                else row.srDirect.itemId = nil; row.srDirect:Hide(); row.sr:SetInactive(table.getn(player.srItems or {}) == 0); row.sr:Show() end
                row:Show()
            else row.player = nil; row.srDirect.itemId = nil; row.srDirect:Hide(); row.srMissing:Hide(); row:Hide() end
        end
        self.refreshing=false
    end
    controller.applyDates:SetScript("OnClick", function() controller.selectedId = nil; controller.raidScroll.offset = 0; controller.scroll.offset = 0; controller:Refresh() end)
    return {
        Hide = function(self) controller.raidPanel:Hide(); controller.raidDismiss:Hide(); controller.dateDismiss:Hide(); controller.itemDialog:Hide(); controller.datePicker:Hide(); controller.editDialog:Hide(); controller.removeDialog:Hide(); page:Hide();host:Hide() end,
        Show = function(self) host:Show();page:Show(); controller:Refresh() end,
        Refresh = function(self) controller:Refresh() end,
        OnResize = function(self) controller.datePicker:Hide(); controller.raidPanel:Hide(); controller:Refresh() end,
        SelectRaid = function(self, raidId) controller.selectedId = raidId; controller.raidScroll.offset = 0; controller.scroll.offset = 0; controller:Refresh() end,
    }
end
