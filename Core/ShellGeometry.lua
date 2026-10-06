local Suite, Lib = BootySuite, BootyLib
local Geometry = {}
Suite.Core.ShellGeometry = Geometry
local adapter

local function Frame(id)
    local shell = Suite.Shell
    return id == "suite" and shell and shell.dashboard and shell.dashboard.frame or nil
end
local function Context()
    return {width = UIParent:GetWidth(), height = UIParent:GetHeight(),
        scale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1}
end
local function Limits(_, context)
    local maximumWidth = math.max(1, math.min(1100, context.width - 24))
    local maximumHeight = math.max(1, math.min(760, context.height - 24))
    return {minWidth = math.min(350, maximumWidth), minHeight = math.min(380, maximumHeight),
        maxWidth = maximumWidth, maxHeight = maximumHeight}
end
local function Defaults(id, context)
    local limits = Limits(id, context)
    local width, height = math.min(840, limits.maxWidth), math.min(540, limits.maxHeight)
    return {left = (context.width - width) / 2,
        bottom = math.min(context.height - height, (context.height - height) / 2 + 10), width = width, height = height}
end
local function Stored()
    if BootySuiteDB ~= nil and type(BootySuiteDB) ~= "table" then error("Invalid Booty Suite geometry data.") end
    local db = BootySuiteDB or {}
    return {left = db.windowLeft, bottom = db.windowBottom, width = db.windowWidth, height = db.windowHeight}
end
local function WriteStored(_, rect)
    local expected = BootySuiteDB
    if type(expected) ~= "table" then return false, "Booty Suite geometry data is unavailable or invalid." end
    local db, failure = Suite.GetDatabase()
    if not db then return false, failure or "Booty Suite settings are unavailable." end
    if db ~= expected or BootySuiteDB ~= expected then return false, "Booty Suite geometry ownership changed during its write." end
    db.windowLeft, db.windowBottom = rect.left, rect.bottom
    db.windowWidth, db.windowHeight = rect.width, rect.height
    return true
end
local function GetAdapter()
    if not adapter then
        adapter = Lib.Core.WindowGeometry.Create({getFrame = Frame, getStored = Stored, writeStored = WriteStored,
            getDefaults = Defaults, getLimits = Limits, getContext = Context,
            refresh = function() return Suite.RefreshLayout() end,
            isAvailable = function(id)
                if id ~= "suite" then return false, "unknown-window" end
                local frame = Frame(id)
                if not frame then return false, "not-created" end
                if BootySuiteDB == nil then return false, "not-ready" end
                if not frame:IsVisible() then return false, "hidden" end
                return true
            end,
            isMinimized = function() return Suite.Shell and Suite.Shell.dashboard and Suite.Shell.dashboard.minimized == true end})
    end
    return adapter
end

function Geometry.ReadGeometry(id) return GetAdapter().ReadGeometry(id) end
function Geometry.BeginGeometryPreview(id, onEnded) return GetAdapter().BeginGeometryPreview(id, onEnded) end
function Geometry.PreviewGeometry(token, rect) return GetAdapter().PreviewGeometry(token, rect) end
function Geometry.ApplyGeometry(token) return GetAdapter().ApplyGeometry(token) end
function Geometry.CancelGeometry(token) return GetAdapter().CancelGeometry(token) end
function Geometry.ResetGeometry(token) return GetAdapter().ResetGeometry(token) end
function Geometry.HasPreview() return adapter and adapter.HasPreview("suite") or false end
function Geometry.IsApplying() return adapter and adapter.IsApplying() or false end
function Geometry.EndPreview(reason)
    if not adapter or not adapter.HasPreview("suite") then return true end
    return adapter.EndPreview("suite", reason)
end
function Geometry.CaptureManual() return GetAdapter().CaptureManual("suite") end
