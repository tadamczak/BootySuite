local MOS = MuklaOfficerSuite

MOS.Modules.RaidManagement = MOS.Modules.RaidManagement or {}
local RaidManagement = MOS.Modules.RaidManagement

function RaidManagement.CreateLootRulesDialog(options)
    local frame = CreateFrame("Frame", "MuklaOfficerSuiteLootRulesDialog", UIParent)
    frame:SetWidth(690); frame:SetHeight(560); frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    frame:SetFrameStrata("FULLSCREEN_DIALOG"); frame:SetFrameLevel(230); frame:EnableMouse(true); frame:Hide()
    frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end); frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 7, right = 7, top = 7, bottom = 7 } })
    MOS.UI.RegisterDialogSurface(frame, "panel")
    frame:SetBackdropColor(0.018, 0.018, 0.016, 1)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -17); frame.title:SetText("Set Loot Rules")
    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    local headers = { { "Guild rank", 22, 190 }, { "SR", 224, 66 }, { "ReyCoin", 310, 92 }, { "CSR", 422, 66 }, { "Highly Contested Items", 508, 158 } }
    local index
    for index = 1, table.getn(headers) do
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); header:SetPoint("TOPLEFT", frame, "TOPLEFT", headers[index][2], -58); header:SetWidth(headers[index][3]); header:SetJustifyH(index == 1 and "LEFT" or "CENTER"); header:SetText(headers[index][1])
    end
    frame.rows = {}; frame.working = {}
    local keys = { "sr", "reyCoin", "csr", "highlyContested" }
    local checkX = { 257, 356, 455, 587 }
    for index = 1, 10 do
        local row = CreateFrame("Frame", nil, frame); row:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -78 - ((index - 1) * 27)); row:SetWidth(654); row:SetHeight(24)
        row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0.05, 0.05, 0.045, math.mod(index, 2) == 0 and 0.92 or 0.72)
        row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.rank:SetPoint("LEFT", row, "LEFT", 5, 0); row.rank:SetWidth(190); row.rank:SetJustifyH("LEFT")
        row.checks = {}
        local keyIndex
        for keyIndex = 1, 4 do
            local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate"); check:SetWidth(22); check:SetHeight(22); check:SetPoint("CENTER", frame, "TOPLEFT", checkX[keyIndex], -90 - ((index - 1) * 27)); check.ruleKey = keys[keyIndex]; check.ownerRow = row
            check:SetScript("OnClick", function() if this.ownerRow.rankIndex then frame.working[this.ownerRow.rankIndex][this.ruleKey] = this:GetChecked() and true or false end end)
            row.checks[keyIndex] = check
        end
        frame.rows[index] = row
    end
    frame.empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable"); frame.empty:SetPoint("CENTER", frame, "CENTER", 0, 0); frame.empty:SetText("Refresh the guild roster before setting loot rules."); frame.empty:Hide()
    frame.rulesTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.rulesTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -250); frame.rulesTitle:SetText("Loot rights reference")
    frame.rulesPanel = CreateFrame("Frame", nil, frame); frame.rulesPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -270); frame.rulesPanel:SetWidth(656); frame.rulesPanel:SetHeight(232)
    frame.rulesPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 4, right = 4, top = 4, bottom = 4 } }); frame.rulesPanel:SetBackdropColor(0.025, 0.025, 0.022, 1)
    MOS.UI.RegisterDialogSurface(frame.rulesPanel, "panel")
    frame.rulesScroll = CreateFrame("ScrollFrame", "MuklaOfficerSuiteLootRulesReferenceScroll", frame.rulesPanel, "UIPanelScrollFrameTemplate")
    MOS.UI.RegisterSkinnedScrollBar(getglobal("MuklaOfficerSuiteLootRulesReferenceScrollScrollBar"))
    frame.rulesScroll:SetPoint("TOPLEFT", frame.rulesPanel, "TOPLEFT", 8, -7); frame.rulesScroll:SetPoint("BOTTOMRIGHT", frame.rulesPanel, "BOTTOMRIGHT", -28, 7)
    frame.rulesCanvas = CreateFrame("Frame", nil, frame.rulesScroll); frame.rulesCanvas:SetWidth(604); frame.rulesCanvas:SetHeight(280); frame.rulesScroll:SetScrollChild(frame.rulesCanvas)
    frame.rulesText = frame.rulesCanvas:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.rulesText:SetPoint("TOPLEFT", frame.rulesCanvas, "TOPLEFT", 0, 0); frame.rulesText:SetWidth(596); frame.rulesText:SetJustifyH("LEFT"); frame.rulesText:SetJustifyV("TOP")
    frame.rulesText:SetText("MACAQUE\nLoot rights: none. Lower raid priority than other ranks and may not be selected for the raid.\n\nGUEST\nStarts with Macaque rights and may earn Baboon or Chimp rights under the same requirements as guild members. Silverback rights are unavailable.\n\nALT\nAn alt requested by the raid leader receives the main character's loot rights. A voluntary alt has no loot rights and receives loot after mains. Rights may change with progression and guild needs.\n\nBABOON\nLoot rights: SR excluding Highly Contested Items, plus ReyCoin.\n\nCHIMP\nLoot rights: SR plus ReyCoin.\n\nSILVERBACK\nLoot rights: CSR, SR and ReyCoin. Gains +10 CSR after each unsuccessful SR.")
    frame.rulesCanvas:SetHeight(math.max(280, frame.rulesText:GetStringHeight() + 8))
    frame.contestedItems = MOS.UI.CreateButton(frame, nil, "Set Highly Contested Items", 154, 22)
    frame.contestedItems:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 18)
    frame.contestedItems:SetScript("OnClick", function() options.openHighlyContestedItems() end)
    frame.save = MOS.UI.CreateButton(frame, nil, "Save", 78, 22); frame.save:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -100, 18)
    frame.cancel = MOS.UI.CreateButton(frame, nil, "Cancel", 78, 22); frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 18)
    local function Close() frame:Hide() end
    frame.Close = Close
    frame.close:SetScript("OnClick", Close); frame.cancel:SetScript("OnClick", Close)
    frame.save:SetScript("OnClick", function()
        options.saveRules(frame.working); frame:Hide()
        options.refresh()
        options.printMessage(options.isTestRaid and options.isTestRaid() and "Loot rules saved for this Test Raid session." or "Loot rules saved.")
    end)
    frame.Open = function(self)
        local ranks = {
            { index = "silverback", name = "Silverback" }, { index = "chimp", name = "Chimp" }, { index = "baboon", name = "Baboon" },
            { index = "alt", name = "Alt" }, { index = "guest", name = "Guest" }, { index = "macaque", name = "Macaque" },
        }
        local saved = options.getRules(); self.working = {}
        for index = 1, table.getn(self.rows) do
            local row, rank = self.rows[index], ranks[index]
            if rank then
                row.rankIndex = rank.index; row.rank:SetText(rank.name); self.working[rank.index] = {}
                local savedRule = saved[rank.index] or saved[tostring(rank.index)]
                if not savedRule then
                    if rank.index == "baboon" then savedRule = { sr = true, reyCoin = true }
                    elseif rank.index == "chimp" then savedRule = { sr = true, reyCoin = true, highlyContested = true }
                    elseif rank.index == "silverback" then savedRule = { sr = true, reyCoin = true, csr = true, highlyContested = true }
                    else savedRule = {} end
                end
                local keyIndex
                for keyIndex = 1, 4 do local key = keys[keyIndex]; self.working[rank.index][key] = savedRule[key] and true or false; row.checks[keyIndex]:SetChecked(self.working[rank.index][key] and 1 or nil) end
                row:Show()
            else row.rankIndex = nil; row:Hide() end
        end
        self:Show()
    end
    return frame
end

function RaidManagement.CreateHighlyContestedItemsDialog(options)
    local dialog
    dialog = MOS.UI.CreateTextEditor("MuklaOfficerSuiteHighlyContestedItemsDialog", "Set Highly Contested Items", 8000, function(value)
        local items = {}
        for line in string.gfind((value or "") .. "\n", "([^\r\n]*)[\r\n]") do table.insert(items, line) end
        local count = options.saveHighlyContestedItems(items)
        options.refresh()
        options.printMessage("Highly Contested Items saved: " .. count .. ".")
        return true
    end)
    dialog:SetWidth(560); dialog:SetHeight(400); dialog.save:SetText("Save"); dialog.cancel:SetText("Close")
    dialog:BringToFront(500)
    dialog.description = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dialog.description:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -39); dialog.description:SetWidth(528); dialog.description:SetJustifyH("LEFT")
    dialog.description:SetText("Enter one exact item name per line. Empty and duplicate lines are removed when saved.")
    dialog.scroll:ClearAllPoints(); dialog.scroll:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -68); dialog.scroll:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -32, 52)
    dialog.OpenItems = function(self)
        self:Open(table.concat(options.getHighlyContestedItems(), "\n"))
        self.scroll:Show(); self.edit:Show(); self:BringToFront(500); self.edit:SetFocus()
    end
    return dialog
end
