local MOS = MuklaOfficerSuite

MOS.Services = MOS.Services or {}
local RaidSession = {}
MOS.Services.RaidSession = RaidSession

local Session = {}
Session.__index = Session

-- Dependencies are domain adapters, never UI objects or session flag owners.
-- Keeping their namespaces also preserves instrumentation installed afterward.
function RaidSession.Create(dependencies)
    return setmetatable({ dependencies = dependencies }, Session)
end

function Session:RaidIdExists(raidId)
    local database = self.dependencies.database
    return database.HasSoftReserveSnapshot(raidId) or database.HasRaidStatistic(raidId)
end

function Session:Complete(saveOptions)
    if type(saveOptions) ~= "table" then
        local enabled = saveOptions and true or false
        saveOptions = { saveRaidStatistics = enabled, saveAttendance = enabled, saveCSR = enabled }
    end
    local dependencies = self.dependencies
    if dependencies.testRaid.IsActive() then
        dependencies.testRaid.Stop()
    else
        local attendance = dependencies.database.GetRaidAttendance()
        if attendance then
            local savedAt = dependencies.now()
            local requestedRaidId = string.gsub(tostring(saveOptions.raidId or attendance.snapshotId or ""), "^%s+", "")
            requestedRaidId = string.gsub(requestedRaidId, "%s+$", "")
            if requestedRaidId == "" or self:RaidIdExists(requestedRaidId) then return false end
            attendance.snapshotId = requestedRaidId
            attendance._loadedSnapshotId = nil
            attendance.lastSavedAt = savedAt
            attendance._sessionDraft = nil
            dependencies.raidRes.SyncHistory(attendance)
            if saveOptions.saveRaidStatistics or saveOptions.saveCSR then
                local entry = dependencies.raidStatistics.BuildEntry(attendance, saveOptions)
                if entry then dependencies.database.StoreRaidStatistic(entry) end
            end
        end
        dependencies.database.StoreRaidAttendance(nil)
    end
    return true
end

function Session:LoadSnapshot(snapshotId)
    local dependencies = self.dependencies
    local snapshots = dependencies.database.GetSoftReserveHistory()
    local index
    for index = 1, table.getn(snapshots) do
        if snapshots[index].id == snapshotId then
            local attendance = dependencies.raidRes.RestoreSnapshot(snapshots[index])
            dependencies.raidRes.Reconcile(attendance, attendance)
            return attendance
        end
    end
    return nil
end

function Session:RestoreActive(onStateResolved)
    local dependencies = self.dependencies
    local attendance = dependencies.database.GetRaidAttendance()
    local importInfo = attendance and attendance.softReserveImport
    local raidId = attendance and (attendance.snapshotId or (importInfo and importInfo.id))
    local restorable = raidId and attendance.sessionStartedAt and type(attendance.members) == "table"
    local ready = restorable and true or false
    local draft = restorable and attendance._sessionDraft and true or false
    if onStateResolved then onStateResolved(ready, draft) end
    if restorable then dependencies.raidRes.Reconcile(attendance, attendance) end
    return attendance, ready, draft
end

function Session:BeginDraft()
    local dependencies = self.dependencies
    local attendance = dependencies.testRaid.IsActive() and dependencies.testRaid.GetAttendance()
        or dependencies.database.GetRaidAttendance()
    if attendance then attendance._sessionDraft = true end
end

function Session:ClearAttendance()
    self.dependencies.database.StoreRaidAttendance(nil)
end

function Session:Quit()
    local dependencies = self.dependencies
    local wasTestRaid = dependencies.testRaid.IsActive()
    dependencies.testRaid.Stop()
    if not wasTestRaid then dependencies.database.StoreRaidAttendance(nil) end
end

function Session:StartTest()
    self.dependencies.testRaid.Start()
end
