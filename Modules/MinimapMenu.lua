local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components
local MinimapMenu = {}
MOS.Modules.MinimapMenu = MinimapMenu

local function Entry(text, action, data, children, icon)
    return {text = text, action = action, data = data, children = children, icon = icon}
end

-- Explicit feature APIs supply state and execute the existing workflows.
-- No timers, retained results or SavedVariables belong to this controller.
function MinimapMenu.Create(options)
    local controller = {}
    local roster = {
        Entry("Set GMOTD", "roster", "OpenGMOTD", nil, "rules"),
        Entry("Guild Stats", "page", "statistics", nil, "guild_stats"),
        Entry("Guild info", "roster", "OpenGuildInformation", nil, "info"),
    }
    local leader, loot, snapshots = {}, {}, {}
    local raid = {
        Entry("New raid", "raid", "primary", nil, "start"),
        Entry("RL Tools", nil, nil, leader, "raid_tools"),
        Entry("ML Tools", nil, nil, loot, "loot_tools"),
        Entry("Test Raid", "raid", "test", nil, "groups"),
        Entry("Load Raid", nil, nil, snapshots, "archive"),
        Entry("Save Raid", "raid", "save", nil, "save"),
        Entry("End Raid", "raid", "quit", nil, "quit"),
        Entry("Raid Stats", "page", "raidStatistics", nil, "raid_stats"),
    }
    local profiler = {
        Entry("Start", "performance", "startStop", nil, "start"),
        Entry("Reset", "performance", "reset", nil, "reset"),
        Entry("Export", "performance", "export", nil, "save"),
        Entry("Memory: OFF", "performance", "memory", nil, "memory"),
    }
    profiler[4].keepOpen = true
    local performance = {
        Entry("Live Monitor", "performance", "live", nil, "monitor"),
        Entry("Advanced Profiler", nil, nil, profiler, "performance"),
        Entry("Health Check", "health", nil, nil, "health"),
        Entry("Enable", "performance", "addon", nil, "enable"),
    }
    local entries = {
        Entry("Guild", "page", "roster", roster, "roster"),
        Entry("Raid", "page", "raid", raid, "raids"),
        Entry("CSR", "page", "csr", nil, "csr"),
        Entry("Profiler", "page", "performance", performance, "performance"),
        Entry("Settings", "settings", nil, nil, "settings"),
        Entry("About", "page", "about", nil, "about"),
    }
    local function FillTools(target, source, fallbackIcon)
        for index, tool in ipairs(source) do
            local entry = target[index] or Entry(tool.text, "raid", tool.id)
            target[index] = entry
            entry.text, entry.data, entry.enabled = tool.text, tool.id, tool.enabled
            entry.icon = tool.icon or fallbackIcon
        end
        for index = table.getn(target), table.getn(source) + 1, -1 do target[index] = nil end
    end
    local function RefreshProfiler()
        local state = options.performance:GetQuickState()
        entries[4].enabled = state.installed and true or false
        performance[4].text, performance[4].enabled = state.toggleLabel, state.toggleEnabled and true or false
        performance[4].icon = state.toggleLabel == "Reload UI" and "reload" or state.toggleLabel == "Disable" and "disable" or "enable"
        performance[1].enabled, performance[2].enabled, performance[3].enabled = state.liveEnabled and true or false, state.ready and true or false, state.healthEnabled and true or false
        profiler[1].text, profiler[1].enabled = state.startStopLabel, state.startStopEnabled and true or false
        profiler[1].icon = state.startStopLabel == "Stop" and "stop" or "start"
        profiler[2].enabled, profiler[3].enabled = state.resetEnabled and true or false, state.exportEnabled and true or false
        profiler[4].text, profiler[4].checked = state.memory and "Memory: ON" or "Memory: OFF", state.memory and true or false
        profiler[4].enabled = state.memoryEnabled and true or false
    end
    function controller:RefreshEntries()
        local guild = options.roster.GetQuickState()
        entries[1].enabled = options.isInGuild and options.isInGuild() == true or false
        roster[1].enabled, roster[3].enabled = guild.gmotd, guild.guildInformation
        local session = options.raid:GetState()
        raid[1].text, raid[1].enabled = session.primaryLabel == "Start new raid" and "New raid" or session.primaryLabel, session.active or session.canStart
        raid[1].icon = session.active and "raids" or "start"
        raid[2].enabled, raid[3].enabled = session.canTools, session.canTools
        raid[4].enabled, raid[6].enabled, raid[7].enabled = session.canTest, session.canSave, session.canQuit
        FillTools(leader, options.raid:GetTools("leader"), "raid_tools")
        FillTools(loot, options.raid:GetTools("loot"), "loot_tools")
        local recent = options.raid:GetRecentSnapshots(5)
        local count = math.min(5, table.getn(recent))
        for index = 1, count do
            local snapshot = recent[index]
            local entry = snapshots[index] or Entry(snapshot.text, "load", snapshot.id, nil, "archive")
            snapshots[index] = entry
            entry.text, entry.data, entry.enabled = snapshot.text, snapshot.id, snapshot.enabled
        end
        for index = table.getn(snapshots), count + 1, -1 do snapshots[index] = nil end
        raid[5].enabled = session.canLoad and count > 0
        RefreshProfiler()
        return entries
    end
    function controller:Close() if self.menu then self.menu:Close() end end
    function controller:OpenMain(page)
        self:Close()
        if page == "roster" and (not options.isInGuild or not options.isInGuild()) then return false end
        options.openMain(page)
        return true
    end
    local function Choose(action, data)
        if action == "page" then controller:OpenMain(data)
        elseif action == "settings" then controller:Close(); if options.openSettings then options.openSettings() end
        elseif action == "roster" then options.roster[data]()
        elseif action == "raid" then options.raid:Run(data)
        elseif action == "load" then options.raid:Run("load", data)
        elseif action == "health" then
            controller:OpenMain("performance")
            options.performance:ExecuteQuickAction("health")
        elseif action == "performance" then
            options.performance:ExecuteQuickAction(data)
            if data == "memory" then RefreshProfiler() end
        end
    end
    function controller:Toggle(anchor)
        if self.menu and self.menu:IsOpen() then self:Close();return end
        if not self.menu then self.menu = UI.CreateCascadingMenu(Choose, options.menuOptions) end
        self.menu:Open(anchor, self:RefreshEntries())
    end
    return controller
end
