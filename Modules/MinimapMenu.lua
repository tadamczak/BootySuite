local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
local MinimapMenu = {}
MOS.Modules.MinimapMenu = MinimapMenu

local function Entry(text, action, data, children)
    return {text = text, action = action, data = data, children = children}
end

-- Explicit feature APIs supply state and execute the existing workflows.
-- No timers, retained results or SavedVariables belong to this controller.
function MinimapMenu.Create(options)
    local controller = {}
    local roster = {
        Entry("Set GMOTD", "roster", "OpenGMOTD"),
        Entry("Guild Information", "roster", "OpenGuildInformation"),
        Entry("Add Member", "roster", "OpenAddMember"),
    }
    local leader, loot, snapshots = {}, {}, {}
    local raid = {
        Entry("Start new raid", "raid", "primary"),
        Entry("RL Tools", nil, nil, leader),
        Entry("ML Tools", nil, nil, loot),
        Entry("Test Raid", "raid", "test"),
        Entry("Load Raid", nil, nil, snapshots),
        Entry("Save Session", "raid", "save"),
        Entry("Quit", "raid", "quit"),
    }
    local profiler = {
        Entry("Start", "performance", "startStop"),
        Entry("Reset", "performance", "reset"),
        Entry("Export", "performance", "export"),
        Entry("Memory: OFF", "performance", "memory"),
    }
    local performance = {
        Entry("Enable", "performance", "addon"),
        Entry("Live Monitor", "performance", "live"),
        Entry("Advanced Profiler", nil, nil, profiler),
        Entry("Health Check", "health"),
    }
    local entries = {
        Entry("Roster", nil, nil, roster),
        Entry("Raid", nil, nil, raid),
        Entry("Guild Statistics", "page", "statistics"),
        Entry("Raid Statistics", "page", "raidStatistics"),
        Entry("CSR", "page", "csr"),
        Entry("Performance", nil, nil, performance),
        Entry("About", "page", "about"),
    }
    local function FillTools(target, source)
        for index, tool in ipairs(source) do
            local entry = target[index] or Entry(tool.text, "raid", tool.id)
            target[index] = entry
            entry.text, entry.data, entry.enabled = tool.text, tool.id, tool.enabled
        end
        for index = table.getn(target), table.getn(source) + 1, -1 do target[index] = nil end
    end
    function controller:RefreshEntries()
        local guild = options.roster.GetQuickState()
        roster[1].enabled, roster[2].enabled, roster[3].enabled = guild.gmotd, guild.guildInformation, guild.addMember
        local session = options.raid:GetState()
        raid[1].text, raid[1].enabled = session.primaryLabel, session.active or session.canStart
        raid[2].enabled, raid[3].enabled = session.canTools, session.canTools
        raid[4].enabled, raid[6].enabled, raid[7].enabled = session.canTest, session.canSave, session.canQuit
        FillTools(leader, options.raid:GetTools("leader"))
        FillTools(loot, options.raid:GetTools("loot"))
        local recent = options.raid:GetRecentSnapshots(5)
        local count = math.min(5, table.getn(recent))
        for index = 1, count do
            local snapshot = recent[index]
            local entry = snapshots[index] or Entry(snapshot.text, "load", snapshot.id)
            snapshots[index] = entry
            entry.text, entry.data, entry.enabled = snapshot.text, snapshot.id, snapshot.enabled
        end
        for index = table.getn(snapshots), count + 1, -1 do snapshots[index] = nil end
        raid[5].enabled = session.canLoad and count > 0
        local state = options.performance:GetQuickState()
        entries[6].enabled = state.installed
        performance[1].text, performance[1].enabled = state.toggleLabel, state.toggleEnabled
        performance[2].enabled, performance[3].enabled, performance[4].enabled = state.liveEnabled, state.ready, state.healthEnabled
        profiler[1].text, profiler[1].enabled = state.startStopLabel, state.startStopEnabled
        profiler[2].enabled, profiler[3].enabled = state.resetEnabled, state.exportEnabled
        profiler[4].text, profiler[4].checked = state.memory and "Memory: ON" or "Memory: OFF", state.memory and true or false
        profiler[4].enabled = state.memoryEnabled
        return entries
    end
    function controller:Close() if self.menu then self.menu:Close() end end
    function controller:OpenMain(page)
        self:Close()
        options.openMain(page)
    end
    local function Choose(action, data)
        if action == "page" then controller:OpenMain(data)
        elseif action == "roster" then options.roster[data]()
        elseif action == "raid" then options.raid:Run(data)
        elseif action == "load" then options.raid:Run("load", data)
        elseif action == "health" then
            controller:OpenMain("performance")
            options.performance:ExecuteQuickAction("health")
        elseif action == "performance" then options.performance:ExecuteQuickAction(data) end
    end
    function controller:Toggle(anchor)
        if self.menu and self.menu:IsOpen() then self:Close();return end
        if not self.menu then self.menu = UI.CreateCascadingMenu(Choose) end
        self.menu:Open(anchor, self:RefreshEntries())
    end
    return controller
end
