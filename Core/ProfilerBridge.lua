local MOS = MuklaOfficerSuite
local Bridge = {}
MOS.Core.ProfilerBridge = Bridge
local source = {}

function source.start(observer)
    local D = MOS.Diagnostics
    if D.sampleObserver then return nil, "Another MOS sample observer is active." end
    local scope = D.BeginScope("bootyprofiler")
    scope.previousTracking, scope.observer = D.trackOperations, observer
    D.SetSampleObserver(observer); D.SetTracking(true)
    return { scope = scope, operations = scope.operations }
end

function source.stop(handle)
    local D, scope = MOS.Diagnostics, handle.scope
    D.EndScope(scope)
    if D.sampleObserver == scope.observer then D.SetSampleObserver(nil) end
    D.SetTracking(scope.previousTracking)
end

function source.capabilities()
    return MOS.Core.ClientCapabilities and MOS.Core.ClientCapabilities.Collect()
end

function Bridge.Resolve()
    local provider = BootyProfiler
    if type(provider) ~= "table" then return nil, "BootyProfiler is not installed or enabled. Install BootyProfiler beside MOS, restart the game, and enable it in the character addon list." end
    if provider.API_VERSION ~= 1 or type(provider.GetState) ~= "function" or type(provider.RegisterSource) ~= "function"
        or type(provider.SetListener) ~= "function" or type(provider.Enable) ~= "function" or type(provider.Start) ~= "function"
        or type(provider.Stop) ~= "function" or type(provider.Reset) ~= "function" or type(provider.Export) ~= "function"
        or type(provider.HistoryEntry) ~= "function" or type(provider.ReadAddonMemory) ~= "function"
        or type(provider.Runtime) ~= "table" or type(provider.Runtime.SetRunning) ~= "function" then return nil, "BootyProfiler has an incompatible API. Install a compatible BootyProfiler version and reload." end
    local ok,state=pcall(provider.GetState)
    if not ok or type(state)~="table" or type(state.enabled)~="boolean" or type(state.recording)~="boolean" then
        return nil,"BootyProfiler returned an incompatible state. Install a compatible version and reload."
    end
    return provider
end

function Bridge.Connect()
    local provider, failure = Bridge.Resolve()
    if not provider then return nil, failure end
    -- Reopening a page must not replace a live source or start a measurement.
    if not provider.GetState().recording then
        local ok, message = provider.RegisterSource("MOS", source)
        if not ok then return nil, message end
    end
    return provider
end

function Bridge.GetAddonStatus(refresh)
    local service = MOS.Services and MOS.Services.ProfilerAddon
    if not service then return nil end
    if refresh then return service.Refresh() end
    return service.GetStatus()
end

-- The addon loader toggle is separate from Engine.Enable. Stop transient
-- profiling before asking the client to omit BootyProfiler on its next reload.
function Bridge.PrepareDisable()
    local provider = BootyProfiler
    if type(provider) ~= "table" then return true end
    local ready, failure = true, nil
    if type(provider.GetState) == "function" and type(provider.Stop) == "function" then
        local ok, state = pcall(provider.GetState)
        if not ok or type(state) ~= "table" then ready, failure = false, "Profiler state is unavailable."
        elseif state.recording then
            local stopped, result = pcall(provider.Stop)
            if not stopped or result == false then ready, failure = false, "Profiler cleanup failed." end
        end
    end
    if type(provider.Enable) == "function" then
        local ok = pcall(provider.Enable, false)
        if not ok then ready, failure = false, "Profiler shutdown failed." end
    end
    local login = provider.LoginMemory
    if type(login) == "table" and type(login.Cancel) == "function" then
        local ok, result = pcall(login.Cancel)
        if not ok or result == false then ready, failure = false, "Login capture cleanup failed." end
    end
    return ready, failure
end

function Bridge.SetAddonEnabled(enabled)
    local service = MOS.Services and MOS.Services.ProfilerAddon
    if not service then return false, "addon-control-unavailable" end
    return service.SetEnabled(enabled, Bridge.PrepareDisable)
end

function Bridge.ReloadUI()
    local service = MOS.Services and MOS.Services.ProfilerAddon
    if not service then return false, "reload-unavailable" end
    return service.Reload()
end
