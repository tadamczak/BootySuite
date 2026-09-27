-- Exercise production SR issue classification and classic warning layout.
MuklaOfficerSuite = {
    Services = {}, Modules = {}, Database = {},
    UI = { IsClassicSkin = function() return true end },
}

local attendance = { softReserveImport = { unmatchedNames = { "Outside" }, missingNames = { "Guest" } }, members = {
    { name = "Guest", guildRank = "Guest" },
    { name = "Chimp", guildRank = "Chimp" },
    { name = "Reserved", guildRank = "Baboon", srItemIds = { 2677 } },
} }
local rules = { guest = { sr = false }, chimp = { sr = true }, baboon = { sr = true } }
function MuklaOfficerSuite.Database.GetLootRules() return rules end
function MuklaOfficerSuite.Database.GetRaidAttendance() return attendance end
dofile("MuklaOfficerSuite/Services/RaidService.lua")
dofile("MuklaOfficerSuite/Services/RaidResService.lua")
dofile("MuklaOfficerSuite/Modules/RaidManagement.lua")

local function check(value, message)
    if not value then error(message, 2) end
end

local raid = MuklaOfficerSuite.Services.Raid
local function issues() return raid.GetSoftReserveIssues(attendance, rules) end
local current = issues()
check(table.getn(current.missingNames) == 1 and current.missingNames[1] == "Chimp", "Guest without SR rights was marked missing")
check(table.getn(current.invalidNames) == 0, "eligible reservation was marked invalid")
check(table.getn(current.unmatchedNames) == 1 and current.unmatchedNames[1] == "Outside", "outside-raid import was lost")

rules.baboon.sr = false
current = issues()
check(table.getn(current.invalidNames) == 1 and current.invalidNames[1] == "Reserved", "rank change did not expose invalid SR")
rules.guest.sr = true
current = issues()
check(table.getn(current.missingNames) == 2, "granting SR rights did not add Guest to missing list")
rules.guest.sr = false

local function region()
    local value = { shown = false }
    function value:ClearAllPoints() self.anchor = nil end
    function value:SetPoint(_, _, _, x, y) self.anchor = { x or 0, y or 0 } end
    function value:SetWidth(width) self.width = width end
    function value:SetHeight(height) self.height = height end
    function value:GetHeight() return self.height or 0 end
    function value:SetText(text) self.text = text end
    function value:SetJustifyH(value) self.justification = value end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:IsShown() return self.shown end
    return value
end
local function warning(withFix, withPing)
    local value = region()
    value.text = region(); value.info = region()
    if withFix then value.fix = region() end
    if withPing then value.ping = region() end
    return value
end
local page = region()
page.width = 800; page.height = 500
function page:GetWidth() return self.width end
function page:GetHeight() return self.height end
function page:GetLeft() return 0 end
function page:GetRight() return self.width end
function page:GetTop() return self.height end
function page:GetBottom() return 0 end
page.getSoftReserveData = function() return attendance end
page.getSoftReserveRules = function() return rules end
page.softReserveWarning = warning(true, false)
page.missingSoftReserveWarning = warning(true, true)
page.invalidSoftReserveWarning = warning(true, true)
local management = MuklaOfficerSuite.Modules.RaidManagement
local width = management.LayoutSoftReserveWarnings(page, false, true)
check(width <= 250, "three warnings widened the sidebar")
check(page.softReserveWarning:IsShown() and page.missingSoftReserveWarning:IsShown()
    and page.invalidSoftReserveWarning:IsShown(), "not all three SR warnings are shown")
check(page.softReserveWarning.height + page.missingSoftReserveWarning.height + page.invalidSoftReserveWarning.height + 16 <= 392,
    "three warnings exceed the available vertical space")
check(string.find(page.invalidSoftReserveWarning.details, "Reserved", 1, true), "invalid SR details omitted the player")

rules.baboon.sr = true
management.LayoutSoftReserveWarnings(page, false, true)
check(not page.invalidSoftReserveWarning:IsShown(), "invalid SR warning remained after rights were restored")

rules.baboon.sr = false
local historySyncs = 0
MuklaOfficerSuite.Services.RaidRes.SyncHistory = function() historySyncs = historySyncs + 1 end
local cleared = MuklaOfficerSuite.Services.RaidRes.ClearInvalidMemberReservations(attendance, rules)
check(cleared == 1 and not attendance.members[3].srItemIds and attendance.members[3].sr == "", "FIX SR did not clear only the invalid reservation")
check(historySyncs == 1, "FIX SR did not persist the change once")
check(table.getn(attendance.softReserveImport.unmatchedNames) == 1 and attendance.softReserveImport.unmatchedNames[1] == "Outside",
    "FIX SR moved a removed reservation into outside-raid imports")
print("Soft Reserve warning regression scenarios passed")
