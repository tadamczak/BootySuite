local MOS = MuklaOfficerSuite
local Match = MOS.Core and MOS.Core.Compatibility and MOS.Core.Compatibility.Match or string.match

MOS.Core.Commands = MOS.Core.Commands or {}
local Commands = MOS.Core.Commands

function Commands.Attach(options)
    SLASH_MUKLAOFFICERSUITE1 = "/mos"
    SLASH_MUKLAOFFICERSUITE2 = "/mukla"
    SlashCmdList["MUKLAOFFICERSUITE"] = function(message)
        local raw = string.gsub(message or "", "^%s*(.-)%s*$", "%1")
        local command = string.lower(raw)
        command = string.gsub(command, "^%s*(.-)%s*$", "%1")
        local rollArgument = Match(raw, "^[Rr][Oo][Ll][Ll]%s+(.+)$")
        if rollArgument then
            options.startLinkedItemRoll(rollArgument)
        elseif command == "roll" then
            if options.openNewRoll then options.openNewRoll() end
        elseif command == "layout" then
            options.printLayoutDiagnostics()
        elseif command == "capabilities" then
            if options.printCapabilities then options.printCapabilities() end
        elseif command == "scan" then
            if not options.dashboard:IsVisible() then options.dashboard:Show() end
            if options.showPage("roster") == false then
                options.printMessage("Join a guild to open Guild.")
            else
                options.printMessage("Open Guild, then use Scan Guild Data or Export Guild.")
            end
        elseif command == "show" or command == "open" or command == "" then
            options.toggleDashboard()
        elseif command == "hide" then
            options.dashboard:Hide()
        elseif command == "minimap" then
            MOS.Database.Ensure()
            MuklaOfficerSuiteDB.hideMinimapIcon = not MuklaOfficerSuiteDB.hideMinimapIcon
            MuklaOfficerSuiteDB.minimap.hidden = MuklaOfficerSuiteDB.hideMinimapIcon
            if MuklaOfficerSuiteDB.hideMinimapIcon then options.minimapButton:Hide() else options.minimapButton:Show() end
        elseif command == "status" then
            options.printMessage("Saved members: " .. options.countSavedMembers())
        else
            options.printMessage("Commands: /mos, /mos roll [linked item], /mos status, /mos capabilities, /mos minimap, /mos hide")
        end
    end
end
