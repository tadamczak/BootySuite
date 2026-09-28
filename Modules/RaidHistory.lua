local MOS = MuklaOfficerSuite

MOS.Modules.RaidManagement = MOS.Modules.RaidManagement or {}
local RaidManagement = MOS.Modules.RaidManagement

function RaidManagement.HideRaidHistoryControls(controls)
    controls.loadRaid:Hide(); controls.testRaid:Hide(); controls.historyTitle:Hide(); controls.historyEmpty:Hide()
    local index
    for index = 1, table.getn(controls.historyButtons) do controls.historyButtons[index]:Hide() end
    for index = 1, table.getn(controls.historyDeleteButtons or {}) do controls.historyDeleteButtons[index]:Hide() end
end

function RaidManagement.ShowRaidHistoryControls(page, controls, canStartRaid)
    controls.scan:ClearAllPoints(); controls.scan:SetPoint("CENTER", page, "CENTER", -91, 64); controls.scan:SetWidth(130); controls.scan:SetHeight(24); controls.scan:SetText("Start New Raid"); controls.scan:Show()
    if canStartRaid then controls.scan:Enable() else controls.scan:Disable() end
    controls.loadRaid:ClearAllPoints(); controls.loadRaid:SetPoint("LEFT", controls.scan, "RIGHT", 8, 0); controls.loadRaid:Show()
    controls.testRaid:ClearAllPoints(); controls.testRaid:SetPoint("LEFT", controls.loadRaid, "RIGHT", 8, 0); controls.testRaid:Show()
    controls.historyTitle:ClearAllPoints(); controls.historyTitle:SetPoint("TOP", controls.scan, "BOTTOM", 91, -18); controls.historyTitle:Show()
    local snapshots = page.getRaidHistory and page.getRaidHistory() or {}; page.raidHistorySnapshots = snapshots
    local historyWidth = math.max(380, page:GetWidth() - 80)
    local index
    for index = 1, 5 do
        local snapshot, button, deleteButton = snapshots[index], controls.historyButtons[index], controls.historyDeleteButtons[index]
        button:ClearAllPoints(); button:SetPoint("TOP", controls.historyTitle, "BOTTOM", 0, -8 - ((index - 1) * 32)); button:SetWidth(historyWidth)
        deleteButton:ClearAllPoints(); deleteButton:SetPoint("LEFT", button, "RIGHT", 4, 0)
        if snapshot then
            button:SetText(tostring(snapshot.id or "Unknown") .. "  |  " .. (snapshot.raidName or "Unknown zone"))
            local savedAt = snapshot.savedAt or snapshot.updatedAt
            button.savedAt:SetText(savedAt and date("%Y-%m-%d %H:%M", savedAt) or "")
            button:Show(); deleteButton:Show()
        else button.savedAt:SetText(""); button:Hide(); deleteButton:Hide() end
    end
    if not MOS.UI.ApplySelectionListStyle(controls.historyButtons, snapshots, page.selectedRaidHistoryId, controls.loadRaid) then page.selectedRaidHistoryId = nil end
    if table.getn(snapshots) == 0 then
        controls.historyEmpty:ClearAllPoints(); controls.historyEmpty:SetPoint("TOP", controls.historyTitle, "BOTTOM", 0, -14); controls.historyEmpty:Show()
    else controls.historyEmpty:Hide() end
end
