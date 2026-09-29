local MOS = MuklaOfficerSuite
local Navigation = {}
MOS.Modules.Navigation = Navigation
Navigation.SetActive = MOS.UI.Components.Navigation.SetActive

function Navigation.Create(options)
    options.order = { "roster", "raid", "statistics", "raidStatistics", "csr", "performance", "about" }
    options.items = {
        { key = "roster", text = "Roster", icon = "Interface\\Icons\\INV_Misc_Book_09" },
        { key = "raid", text = "Raid", icon = "Interface\\Icons\\INV_Banner_03" },
        { key = "statistics", text = "Guild Statistics", shortText = "Stats", icon = "Interface\\Icons\\INV_Misc_Book_11" },
        { key = "raidStatistics", text = "Raid Statistics", shortText = "Stats", icon = "Interface\\Icons\\INV_Misc_Note_06" },
        { key = "csr", text = "CSR", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
        { key = "performance", text = "Performance", shortText = "Perf", icon = "Interface\\Icons\\INV_Gizmo_02" },
        { key = "about", text = "About", icon = "Interface\\Icons\\INV_Misc_QuestionMark" },
    }
    options.ensure = MOS.Database.Ensure
    options.get = MOS.Database.GetSetting
    options.set = function(key, value)
        MOS.Database.SetSetting(key, value)
        if key == "sidebarCollapsed" then MOS.sidebarCollapsed = value end
    end
    return MOS.UI.Components.Navigation.Create(options)
end
