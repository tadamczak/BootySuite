local MOS = MuklaOfficerSuite

MOS.UI.Dialogs = MOS.UI.Dialogs or {}
local Dialogs = MOS.UI.Dialogs

local function ReloadInterface()
    if type(ReloadUI) == "function" then ReloadUI()
    elseif type(ConsoleExec) == "function" then ConsoleExec("reloadui") end
end

function Dialogs.RegisterPersistencePrompts(printMessage)
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_RELOAD"] = {
        text = "The guild roster scan is complete. Reload the UI now to write it to disk?",
        button1 = "Reload now", button2 = "Later", OnAccept = ReloadInterface,
        OnCancel = function() printMessage("Roster remains in memory. Use /reload before closing the game to save it.") end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_CSR_RELOAD"] = {
        text = "The raid and guild data scan is complete. Reload the UI now to write the CSR snapshot to disk?",
        button1 = "Reload now", button2 = "Later", OnAccept = ReloadInterface,
        OnCancel = function() printMessage("CSR remains in memory. Use /reload before closing the game to save it.") end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopupDialogs["MUKLA_OFFICER_SUITE_ATTENDANCE_RELOAD"] = {
        text = "Attendance snapshot is ready. Reload the UI now to write it to disk?",
        button1 = "Reload now", button2 = "Later", OnAccept = ReloadInterface,
        OnCancel = function() printMessage("Attendance remains in memory. Use /reload before running Export-Attendance.ps1.") end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
end
