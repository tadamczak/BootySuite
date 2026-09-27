local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local CSR = {}
MOS.Modules.CSR = CSR

local function CreateTestLab(onChanged, onExit)
    local dialog = CreateFrame("Frame", "MuklaOfficerSuiteCSRTestLab", UIParent)
    dialog:SetWidth(590); dialog:SetHeight(420); dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetFrameLevel(230); dialog:SetMovable(true); dialog:SetResizable(true); dialog:EnableMouse(true); dialog:RegisterForDrag("LeftButton")
    dialog:SetMinResize(590, 420); dialog:SetMaxResize(850, 700)
    if dialog.SetClampedToScreen then dialog:SetClampedToScreen(true) end
    dialog:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 6, right = 6, top = 6, bottom = 6 } })
    MOS.UI.RegisterDialogSurface(dialog, "panel")
    dialog:SetBackdropColor(0.025, 0.025, 0.022, 1)
    dialog:SetScript("OnDragStart", function() this:StartMoving() end); dialog:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    dialog:SetScript("OnSizeChanged", function()
        if this:GetWidth() < 590 then this:SetWidth(590) end
        if this:GetHeight() < 420 then this:SetHeight(420) end
    end)
    dialog.title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); dialog.title:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -16); dialog.title:SetText("CSR Test Lab")
    dialog.help = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); dialog.help:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -47); dialog.help:SetPoint("RIGHT", dialog, "RIGHT", -16, 0); dialog.help:SetJustifyH("LEFT")
    dialog.help:SetText("Transient simulation only. Add players and independent item reservations, award items, change rank, or advance beyond the 60-day window.")
    dialog.state = MOS.Services.CSRTest.Create(); dialog.summary = { players = {} }
    dialog.status = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal"); dialog.status:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -88); dialog.status:SetPoint("RIGHT", dialog, "RIGHT", -16, 0); dialog.status:SetJustifyH("LEFT")
    dialog.item = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); dialog.item:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -116); dialog.item:SetPoint("RIGHT", dialog, "RIGHT", -16, 0); dialog.item:SetJustifyH("LEFT")
    dialog.result = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); dialog.result:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -148); dialog.result:SetPoint("RIGHT", dialog, "RIGHT", -16, 0); dialog.result:SetJustifyH("LEFT")
    dialog.logTitle = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal"); dialog.logTitle:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -262); dialog.logTitle:SetText("Simulation log")
    dialog.logLines = {}
    local index
    for index = 1, 5 do
        local line = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); line:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -282 - ((index - 1) * 19)); line:SetPoint("RIGHT", dialog, "RIGHT", -16, 0); line:SetJustifyH("LEFT"); dialog.logLines[index] = line
    end
    local addPlayer = MOS.UI.CreateButton(dialog, nil, "Add player", 84, 24); addPlayer:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -190)
    local missed = MOS.UI.CreateButton(dialog, nil, "Add unsuccessful SR", 126, 24); missed:SetPoint("LEFT", addPlayer, "RIGHT", 7, 0)
    local award = MOS.UI.CreateButton(dialog, nil, "Award item", 90, 24); award:SetPoint("LEFT", missed, "RIGHT", 7, 0)
    local nextItem = MOS.UI.CreateButton(dialog, nil, "Next item", 82, 24); nextItem:SetPoint("LEFT", award, "RIGHT", 7, 0)
    local rank = MOS.UI.CreateButton(dialog, nil, "Toggle rank", 88, 24); rank:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -224)
    local days = MOS.UI.CreateButton(dialog, nil, "+7 days", 72, 24); days:SetPoint("LEFT", rank, "RIGHT", 7, 0)
    local reset = MOS.UI.CreateButton(dialog, nil, "Reset Test", 84, 22); reset:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 16, 14)
    local exit = MOS.UI.CreateButton(dialog, nil, "Exit Test", 76, 22); exit:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -16, 14)
    dialog.grip = CreateFrame("Button", nil, dialog); dialog.grip:SetWidth(20); dialog.grip:SetHeight(20); dialog.grip:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -2, 2)
    dialog.grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    dialog.grip:SetScript("OnMouseDown", function() dialog:StartSizing("BOTTOMRIGHT") end)
    dialog.grip:SetScript("OnMouseUp", function() dialog:StopMovingOrSizing(); dialog:Refresh() end)
    exit:ClearAllPoints(); exit:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -28, 14)
    dialog.Refresh = function(self)
        MOS.Services.CSRTest.BuildSummary(self.state, self.summary)
        local totalItems, totalCsr, rowIndex = 0, 0, nil
        for rowIndex = 1, table.getn(self.summary.players) do totalItems = totalItems + self.summary.players[rowIndex].items; totalCsr = totalCsr + self.summary.players[rowIndex].csr end
        local selected = self.state.currentPlayer
        self.status:SetText("Selected player: " .. (selected or "none") .. "   Rank: " .. (selected and self.state.ranks[selected] or "-") .. "   Date: " .. date("%Y-%m-%d", self.state.now))
        self.item:SetText("Selected item: " .. MOS.UI.GetItemLabel(MOS.Services.CSRTest.GetItemId(self.state)))
        self.result:SetText("Table rows: " .. table.getn(self.summary.players) .. "     Outstanding reserves: " .. totalItems .. "     CSR: " .. totalCsr)
        for rowIndex = 1, table.getn(self.logLines) do self.logLines[rowIndex]:SetText(self.state.log[rowIndex] or "") end
        if onChanged then onChanged() end
    end
    addPlayer:SetScript("OnClick", function() MOS.Services.CSRTest.AddPlayer(dialog.state); dialog:Refresh() end)
    missed:SetScript("OnClick", function() MOS.Services.CSRTest.AddMissedReserve(dialog.state); dialog:Refresh() end)
    award:SetScript("OnClick", function() MOS.Services.CSRTest.AwardItem(dialog.state); dialog:Refresh() end)
    nextItem:SetScript("OnClick", function() MOS.Services.CSRTest.NextItem(dialog.state); dialog:Refresh() end)
    rank:SetScript("OnClick", function() MOS.Services.CSRTest.ToggleRank(dialog.state); dialog:Refresh() end)
    days:SetScript("OnClick", function() MOS.Services.CSRTest.AdvanceDays(dialog.state, 7); dialog:Refresh() end)
    reset:SetScript("OnClick", function() MOS.Services.CSRTest.Reset(dialog.state); dialog:Refresh() end)
    exit:SetScript("OnClick", function() dialog:Hide(); if onExit then onExit() end end)
    dialog.Open = function(self) self:Refresh(); self:Show() end
    dialog:Hide()
    return dialog
end

function CSR.Create(page, getEntries, getRules, getRosterData, openRaidStatistics)
    local controller = { page = page, rows = {}, summary = { players = {} }, testMode = false, selectedRaids = {}, expandedKey = nil }
    local raidNames = MOS.Services.RaidStatistics.GetRaidNames()
    local raidFilterIndex
    for raidFilterIndex = 1, table.getn(raidNames) do controller.selectedRaids[raidNames[raidFilterIndex]] = true end
    controller.testLab = CreateTestLab(function() controller.testMode = true; controller:Refresh() end, function() controller.testMode = false; controller:Refresh() end)
    controller.title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); controller.title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10); controller.title:SetText("CSR")
    controller.description = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); controller.description:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -40); controller.description:SetPoint("RIGHT", page, "RIGHT", -12, 0); controller.description:SetJustifyH("LEFT")
    controller.description:SetText("Unsuccessful Soft Reserves from the last 60 days. Each player-item pair accumulates independently. Each miss grants 10 CSR.")
    controller.testButton = MOS.UI.CreateButton(page, nil, "CSR Test Lab", 96, 22); controller.testButton:SetPoint("TOPRIGHT", page, "TOPRIGHT", -12, -10); controller.testButton:SetScript("OnClick", function() controller.testLab:Open() end)
    controller.filterLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); controller.filterLabel:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -75); controller.filterLabel:SetText("Filters")
    controller.raidFilter = MOS.UI.CreateDropdownButton(page, nil, "Raid", 150); controller.raidFilter:SetPoint("LEFT", controller.filterLabel, "RIGHT", 10, 0)
    controller.raidPanel = MOS.UI.CreateDropdownPanel(page, controller.raidFilter, 190, 178, 20)
    controller.searchLabel = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); controller.searchLabel:SetPoint("LEFT", controller.raidFilter, "RIGHT", 18, 0); controller.searchLabel:SetText("Search")
    controller.search = MOS.UI.CreateFramedEditBox(page, nil, 180); controller.search:ClearAllPoints(); controller.search:SetPoint("LEFT", controller.searchLabel, "RIGHT", 7, 0); controller.search:SetHeight(22); controller.search:SetAutoFocus(false); controller.search:SetScript("OnEscapePressed", function() this:ClearFocus() end); controller.search:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    controller.raidDismiss = CreateFrame("Button", nil, UIParent); controller.raidDismiss:SetAllPoints(UIParent); controller.raidDismiss:SetFrameStrata("FULLSCREEN_DIALOG"); controller.raidDismiss:SetFrameLevel(1); controller.raidDismiss:Hide()
    controller.raidPanel:SetFrameStrata("FULLSCREEN_DIALOG"); controller.raidPanel:SetFrameLevel(2)
    controller.raidDismiss:SetScript("OnClick", function() controller.raidPanel:Hide(); controller.raidDismiss:Hide() end)
    controller.raidFilter:SetScript("OnClick", function()
        if controller.raidPanel:IsVisible() then controller.raidPanel:Hide(); controller.raidDismiss:Hide()
        else controller.raidDismiss:Show(); controller.raidPanel:Show() end
    end)
    local allCheckbox = CreateFrame("CheckButton", nil, controller.raidPanel, "UICheckButtonTemplate"); allCheckbox:SetPoint("TOPLEFT", controller.raidPanel, "TOPLEFT", 8, -6); allCheckbox:SetWidth(20); allCheckbox:SetHeight(20); allCheckbox:SetChecked(1)
    allCheckbox.label = controller.raidPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); allCheckbox.label:SetPoint("LEFT", allCheckbox, "RIGHT", 2, 0); allCheckbox.label:SetText("All")
    controller.raidChecks = {}
    allCheckbox:SetScript("OnClick", function()
        local enabled = this:GetChecked() and true or false
        local optionIndex
        for optionIndex = 1, table.getn(raidNames) do controller.selectedRaids[raidNames[optionIndex]] = enabled and true or nil; controller.raidChecks[optionIndex]:SetChecked(enabled and 1 or nil) end
        controller:Refresh()
    end)
    for raidFilterIndex = 1, table.getn(raidNames) do
        local checkbox = CreateFrame("CheckButton", nil, controller.raidPanel, "UICheckButtonTemplate"); checkbox:SetPoint("TOPLEFT", controller.raidPanel, "TOPLEFT", 8, -6 - (raidFilterIndex * 23)); checkbox:SetWidth(20); checkbox:SetHeight(20); checkbox.raidName = raidNames[raidFilterIndex]; checkbox:SetChecked(1)
        checkbox.label = controller.raidPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0); checkbox.label:SetText(raidNames[raidFilterIndex])
        checkbox:SetScript("OnClick", function()
            controller.selectedRaids[this.raidName] = this:GetChecked() and true or nil
            local allSelected, optionIndex = true, nil
            for optionIndex = 1, table.getn(raidNames) do if not controller.selectedRaids[raidNames[optionIndex]] then allSelected = false; break end end
            allCheckbox:SetChecked(allSelected and 1 or nil); controller:Refresh()
        end)
        controller.raidChecks[raidFilterIndex] = checkbox
    end
    controller.search:SetScript("OnTextChanged", function() controller:Refresh() end)
    controller.playerHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); controller.playerHeader:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -108); controller.playerHeader:SetText("Player name")
    controller.itemsHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); controller.itemsHeader:SetPoint("TOPLEFT", page, "TOPLEFT", 180, -108); controller.itemsHeader:SetText("Item")
    controller.csrHeader = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); controller.csrHeader:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -108); controller.csrHeader:SetWidth(60); controller.csrHeader:SetText("CSR")
    controller.scroll = CreateFrame("ScrollFrame", "MuklaOfficerSuiteCSRScroll", page, "FauxScrollFrameTemplate"); controller.scroll:SetPoint("TOPLEFT", page, "TOPLEFT", 8, -124); controller.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 10)
    MOS.UI.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteCSRScrollScrollBar"))
    local index
    for index = 1, 30 do
        local row = CreateFrame("Button", nil, page); row:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -98 - ((index - 1) * 24)); row:SetPoint("RIGHT", page, "RIGHT", -32, 0); row:SetHeight(23)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0.035, 0.035, 0.032, math.mod(index, 2) == 0 and 0.82 or 0.58)
        MOS.UI.RegisterSkinnedSurface(row, "row", { bgFile = "Interface\\Buttons\\WHITE8X8" }, { 0.035, 0.035, 0.032, math.mod(index, 2) == 0 and 0.82 or 0.58 }, { 0, 0, 0, 0 })
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -4); row.name:SetWidth(150); row.name:SetJustifyH("LEFT")
        row.iconRegion = row:CreateTexture(nil, "ARTWORK"); row.iconRegion:SetPoint("TOPLEFT", row, "TOPLEFT", 163, -2); row.iconRegion:SetWidth(19); row.iconRegion:SetHeight(19)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.label:SetPoint("TOPLEFT", row.iconRegion, "TOPRIGHT", 5, -2); row.label:SetPoint("RIGHT", row, "RIGHT", -84, 0); row.label:SetJustifyH("LEFT")
        row.csr = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.csr:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -4); row.csr:SetWidth(60)
        row.itemHit = CreateFrame("Button", nil, row); row.itemHit:SetPoint("TOPLEFT", row, "TOPLEFT", 160, 0); row.itemHit:SetPoint("TOPRIGHT", row, "TOPRIGHT", -78, 0); row.itemHit:SetHeight(23); row.itemHit.ownerRow = row
        row.itemHit:SetScript("OnEnter", function() MOS.UI.ShowItemTooltip(this.ownerRow) end); row.itemHit:SetScript("OnLeave", function() GameTooltip:Hide() end); row.itemHit:SetScript("OnClick", function() this.ownerRow:Click() end)
        row.detailRows = {}; row.detailLines = {}; row.viewButtons = {}
        local detailIndex
        for detailIndex = 1, 8 do
            local detail = CreateFrame("Frame", nil, row); detail:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -29 - ((detailIndex - 1) * 22)); detail:SetPoint("RIGHT", row, "RIGHT", -6, 0); detail:SetHeight(21)
            detail:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); detail.normalAlpha = math.mod(detailIndex, 2) == 0 and 0.28 or 0.16; detail:SetBackdropColor(0.20, 0.16, 0.08, detail.normalAlpha); detail:EnableMouse(true)
            detail:SetScript("OnEnter", function() this:SetBackdropColor(0.34, 0.25, 0.08, 0.55) end); detail:SetScript("OnLeave", function() this:SetBackdropColor(0.20, 0.16, 0.08, this.normalAlpha) end); detail:Hide(); row.detailRows[detailIndex] = detail
            local line = detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); line:SetPoint("LEFT", detail, "LEFT", 7, 0); line:SetPoint("RIGHT", detail, "RIGHT", -60, 0); line:SetJustifyH("LEFT"); row.detailLines[detailIndex] = line
            local view = MOS.UI.CreateButton(detail, nil, "View", 52, 19); view:SetPoint("RIGHT", detail, "RIGHT", -1, 0); view:SetScript("OnClick", function() if openRaidStatistics and this.raidId then openRaidStatistics(this.raidId) end end); row.viewButtons[detailIndex] = view
        end
        row:SetScript("OnClick", function()
            if not this.player then return end
            local key = string.lower(this.player.name or "") .. ":" .. tostring(this.player.itemId or "")
            controller.expandedKey = controller.expandedKey == key and nil or key
            controller:Refresh()
        end)
        row:Hide(); controller.rows[index] = row
    end
    function controller:Refresh()
        MOS.Diagnostics.Count("uiRefreshes")
        if self.testMode then MOS.Services.CSRTest.BuildSummary(self.testLab.state, self.summary) else MOS.Services.CSR.BuildSummary(getEntries(), getRules(), time(), self.summary, getRosterData(), self.selectedRaids, self.search:GetText()) end
        local visible = math.max(1, math.min(table.getn(self.rows), math.floor(math.max(24, self.scroll:GetHeight()) / 24)))
        local offset = MOS.UI.UpdateScrollFrame(self.scroll, table.getn(self.summary.players), visible, 24)
        local rowIndex
        local nextY = -128
        for rowIndex = 1, table.getn(self.rows) do
            local row, player = self.rows[rowIndex], self.summary.players[offset + rowIndex]
            if player and rowIndex <= visible then
                row.player = player; row.itemId = player.itemId; row.name:SetText(player.name); row.label:SetText(MOS.UI.GetItemLabel(player.itemId) .. (player.items > 1 and (" x " .. player.items) or "")); row.csr:SetText(player.csr)
                local texture = type(GetItemIcon) == "function" and GetItemIcon(player.itemId) or nil; row.iconRegion:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark"); row:Show()
                local key = string.lower(player.name or "") .. ":" .. tostring(player.itemId or "")
                local expanded = self.expandedKey == key
                local detailCount = expanded and math.min(8, table.getn(player.raids or {})) or 0
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", page, "TOPLEFT", 12, nextY); row:SetPoint("RIGHT", page, "RIGHT", -32, 0); row:SetHeight(23 + (detailCount > 0 and 12 or 0) + (detailCount * 22))
                local detailIndex
                for detailIndex = 1, 8 do
                    local raid = player.raids and player.raids[detailIndex]
                    if expanded and raid then
                        row.detailLines[detailIndex]:SetText(tostring(detailIndex) .. ".  " .. tostring(raid.id or "-") .. " | " .. tostring(raid.raidName or "Other") .. " | " .. date("%Y-%m-%d", tonumber(raid.savedAt) or 0))
                        row.viewButtons[detailIndex].raidId = raid.id; row.detailRows[detailIndex]:Show()
                    else row.detailRows[detailIndex]:Hide() end
                end
                nextY = nextY - row:GetHeight() - 1
            else
                row.player = nil; row.itemId = nil
                local detailIndex; for detailIndex = 1, 8 do row.detailRows[detailIndex]:Hide() end
                row:Hide()
            end
        end
    end
    controller.scroll.refreshCallback = function() controller:Refresh() end
    controller.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(24, this.refreshCallback) end)
    return { Show = function(self) page:Show(); controller:Refresh() end, Hide = function(self) controller.testLab:Hide(); controller.raidPanel:Hide(); controller.raidDismiss:Hide(); page:Hide() end, Refresh = function(self) controller:Refresh() end, OnResize = function(self) controller:Refresh() end }
end
