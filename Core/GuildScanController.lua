local MOS = MuklaOfficerSuite

MOS.Core = MOS.Core or {}
local GuildScanController = {}
MOS.Core.GuildScanController = GuildScanController

local function OnScanUpdate()
    local controller = this.controller
    if not controller.mode then
        this.delay = nil
        this:Hide()
        return
    end
    this.delay = this.delay - arg1
    if this.delay > 0 then return end
    if controller.tryComplete() then return end
    if controller.deadline and GetTime() >= controller.deadline then
        GuildScanController.Finish(controller)
        controller.onFailure()
        return
    end
    if controller.attempts < 6 then
        controller.attempts = controller.attempts + 1
        this.delay = 2.5
        controller.printMessage("Guild roster is still loading. Request " .. controller.attempts .. "/6...")
        controller.requestRoster()
        return
    end
    this.delay = 0.5
end

function GuildScanController.Create(options)
    local controller = options
    controller.mode = nil
    controller.startedAt = nil
    controller.attempts = 0
    controller.deadline = nil
    controller.frame = CreateFrame("Frame", "MuklaOfficerSuiteRosterRequestFrame", UIParent)
    controller.frame.controller = controller
    controller.frame.delay = nil
    controller.frame:Hide()
    controller.frame:SetScript("OnUpdate", OnScanUpdate)
    MOS.guildScanController = controller
    return controller
end

local function Begin(controller, mode, delay)
    if controller.mode then
        controller.printMessage("A guild data scan is already in progress.")
        return false
    end
    if not controller.isInGuild() then
        controller.printMessage("This character is not in a guild.")
        return false
    end
    controller.mode = mode or "manual"
    controller.startedAt = GetTime()
    controller.attempts = 1
    controller.deadline = controller.startedAt + 15
    controller.frame.delay = delay
    controller.frame:Show()
    controller.onStart(controller.mode, controller)
    return true
end

function GuildScanController.Request(controller, mode)
    if not Begin(controller, mode, 1) then return false end
    controller.requestRoster()
    controller.printMessage((mode == "reload" or mode == "csr_reload") and
        "Requesting guild roster. Save confirmation will appear when the scan completes..." or
        "Requesting guild roster...")
    return true
end

function GuildScanController.RequestShared(controller, origin)
    if controller.mode then return false end
    controller.origin = origin
    if GuildScanController.Request(controller, "shared") then return true end
    controller.origin = nil
    return false
end

function GuildScanController.Queue(controller)
    return Begin(controller, "quiet", 0.75)
end

function GuildScanController.Finish(controller)
    controller.mode = nil
    controller.startedAt = nil
    controller.attempts = 0
    controller.deadline = nil
    controller.frame.delay = nil
    controller.frame:Hide()
end

function GuildScanController.GetMode(controller)
    return controller.mode
end

function GuildScanController.GetStartedAt(controller)
    return controller.startedAt
end

function GuildScanController.GetOrigin(controller)
    return controller.origin
end

function GuildScanController.ClearOrigin(controller)
    controller.origin = nil
end

function GuildScanController.IsPending(controller)
    return controller.mode ~= nil
end
