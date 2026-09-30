local MOS = MuklaOfficerSuite

MOS.Modules.RaidManagement = MOS.Modules.RaidManagement or {}
local RaidManagement = MOS.Modules.RaidManagement

function RaidManagement.HideRaidHistoryControls(controls)
    controls.historyScroll:Hide()
    controls.loadRaid:Hide(); controls.testRaid:Hide(); controls.historyTitle:Hide(); controls.historyEmpty:Hide()
    for _, group in ipairs({controls.historyButtons, controls.historyDeleteButtons, controls.historyLoadButtons, controls.historyHeaders}) do
        for index = 1, table.getn(group) do group[index]:Hide() end
    end
end

local function Cell(label, parent, x, width, text)
    label:ClearAllPoints(); label:SetPoint("LEFT", parent, "LEFT", x, 0); label:SetJustifyV("MIDDLE")
    label:SetWidth(width); label:SetHeight(0); label:SetJustifyH("LEFT")
    if label.SetWordWrap then label:SetWordWrap(true) end
    if label.SetNonSpaceWrap then label:SetNonSpaceWrap(true) end
    label:SetText(text); label:Show()
    return label:GetStringHeight() + 10
end

function RaidManagement.ShowRaidHistoryControls(page, controls, canStartRaid)
    local width = math.max(120, page:GetWidth() - 16)
    local buttonWidth = math.min(110, (width - 8) / 2)
    local actionY = -94
    if controls.unavailable and controls.unavailable:IsVisible() then
        controls.unavailable:SetWidth(width)
        actionY = -48 - controls.unavailable:GetStringHeight() - 16
    end
    controls.scan:ClearAllPoints(); controls.scan:SetPoint("TOPLEFT", page, "TOPLEFT", 8, actionY)
    controls.scan:SetWidth(buttonWidth); controls.scan:SetHeight(22); controls.scan:SetText("New Raid"); controls.scan:Show()
    if canStartRaid then controls.scan:Enable() else controls.scan:Disable() end
    controls.loadRaid:Hide()
    controls.testRaid:ClearAllPoints(); controls.testRaid:SetPoint("LEFT", controls.scan, "RIGHT", 8, 0)
    controls.testRaid:SetWidth(buttonWidth); controls.testRaid:SetHeight(22); controls.testRaid:Show()
    controls.historyTitle:ClearAllPoints(); controls.historyTitle:SetPoint("TOPLEFT", page, "TOPLEFT", 8, actionY - 38); controls.historyTitle:Show()
    local snapshots = page.getRaidHistory and page.getRaidHistory() or {}; page.raidHistorySnapshots = snapshots
    if not MOS.UI.Components.ApplySelectionListStyle(controls.historyButtons, snapshots, page.selectedRaidHistoryId, controls.loadRaid) then page.selectedRaidHistoryId = nil end
    local dataWidth = math.max(60, width - 68)
    local nameWidth, raidWidth = math.floor(dataWidth * 0.34), math.floor(dataWidth * 0.34)
    local timeWidth = dataWidth - nameWidth - raidWidth
    local widths = {nameWidth, raidWidth, timeWidth}
    local x = 8
    for index = 1, 3 do
        local heading = controls.historyHeaders[index]
        heading:ClearAllPoints(); heading:SetPoint("TOPLEFT", page, "TOPLEFT", x, actionY - 62); heading:SetWidth(widths[index] - 6); heading:SetJustifyH("LEFT"); heading:Show()
        x = x + widths[index]
    end
    controls.historyScroll:ClearAllPoints(); controls.historyScroll:SetPoint("TOPLEFT",page,"TOPLEFT",8,actionY-82);controls.historyScroll:SetPoint("BOTTOMRIGHT",page,"BOTTOMRIGHT",-28,8)
    controls.historyCanvas:SetWidth(width-20);controls.historyScroll:Show()
    local y = 0
    for index = 1, 5 do
        local snapshot, button = snapshots[index], controls.historyButtons[index]
        local deleteButton, load = controls.historyDeleteButtons[index], controls.historyLoadButtons[index]
        button:ClearAllPoints(); button:SetPoint("TOPLEFT", controls.historyCanvas, "TOPLEFT", 0, y); button:SetWidth(dataWidth)
        if snapshot then
            local savedAt = snapshot.savedAt or snapshot.updatedAt
            local height = math.max(26,
                Cell(button.label, button, 4, nameWidth - 6, tostring(snapshot.id or "Unknown")),
                Cell(button.raidName, button, nameWidth + 4, raidWidth - 6, snapshot.raidName or "Unknown zone"),
                Cell(button.savedAt, button, nameWidth + raidWidth + 4, timeWidth - 6, savedAt and date("%Y-%m-%d %H:%M", savedAt) or ""))
            button:SetHeight(height); button:Show()
            MOS.UI.Components.StyleWarmListRow(button, page.selectedRaidHistoryId == snapshot.id)
            load:SetWidth(24); load:SetHeight(24); deleteButton:SetWidth(16); deleteButton:SetHeight(16)
            load:ClearAllPoints(); load:SetPoint("LEFT", button, "RIGHT", 4, 0); load:Show()
            deleteButton:ClearAllPoints(); deleteButton:SetPoint("LEFT", load, "RIGHT", 4, 0); deleteButton:Show()
            y = y - height - 2
        else button:Hide(); load:Hide(); deleteButton:Hide() end
    end
    controls.historyCanvas:SetHeight(math.max(1,-y))
    if controls.historyScroll.UpdateScrollChildRect then controls.historyScroll:UpdateScrollChildRect() end
    if table.getn(snapshots) == 0 then
        controls.historyEmpty:ClearAllPoints(); controls.historyEmpty:SetPoint("TOPLEFT", page, "TOPLEFT", 8, actionY - 86); controls.historyEmpty:Show()
    else controls.historyEmpty:Hide() end
end
