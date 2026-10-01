local MOS = MuklaOfficerSuite
MOS.Modules.RaidSessionController = MOS.Modules.RaidSessionController or {}
local RaidSessionController = MOS.Modules.RaidSessionController

-- Feature lifecycle state is separate from durable session transformations and
-- presentation. Explicit callbacks retain the original ordering at UI boundaries.
function RaidSessionController.Create(dependencies)
    local state, session = dependencies.state, dependencies.session
    local controller = {}

    function controller:Complete(saveOptions)
        if not session:Complete(saveOptions) then return false end
        state.raidSessionDraft = false; state.raidSessionPaused = true; state.raidLiveTracking = false
        state.raidScanReady = false; state.raidSessionContinuedContext = nil
        dependencies.setHistoricalLoaded(false); dependencies.clearSelection()
        dependencies.showSavedPopup()
        return true
    end

    function controller:Begin()
        state.raidSessionPaused = false; state.raidSessionDraft = true
        state.raidSessionContinuedContext = nil
        session:BeginDraft()
    end

    function controller:StartNew(raidId, raidName)
        state.pendingRaidSessionId = raidId; state.pendingRaidName = raidName
        session:ClearAttendance()
        dependencies.setHistoricalLoaded(false)
        state.raidSessionPaused = false; state.raidSessionDraft = true
    end

    function controller:Quit()
        session:Quit()
        state.raidSessionPaused = true; state.raidSessionDraft = false; state.raidLiveTracking = false
        dependencies.setHistoricalLoaded(false); state.raidScanReady = false; dependencies.clearSelection()
        state.raidSessionContinuedContext = nil
    end

    function controller:Continue(contextKey)
        state.raidSessionContinuedContext = contextKey; state.raidSessionPaused = false
    end

    function controller:StartTest()
        session:StartTest(); state.raidLiveTracking = false; dependencies.clearSelection()
    end

    local function RestoreState(ready, draft)
        state.raidScanReady = ready; state.raidSessionDraft = draft; state.raidSessionPaused = false
        dependencies.setHistoricalLoaded(false)
    end
    function controller:RestoreActive()
        return session:RestoreActive(RestoreState)
    end

    return controller
end
