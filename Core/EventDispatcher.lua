local MOS = MuklaOfficerSuite

MOS.Core.EventDispatcher = MOS.Core.EventDispatcher or {}
local EventDispatcher = MOS.Core.EventDispatcher

function EventDispatcher.Attach(frame, handlers)
    local eventName
    for eventName in pairs(handlers) do frame:RegisterEvent(eventName) end
    frame.eventHandlers = handlers
    frame:SetScript("OnEvent", function()
        MOS.Diagnostics.Count("events")
        local handler = this.eventHandlers[event]
        if handler then handler(arg1) end
    end)
end
