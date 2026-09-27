-- Headless integration exercise for the production Master Loot window.
-- Run from the repository root with the other regression scripts.

local frames = {}
local function frame(parent, kind)
    local f = { parent = parent, kind = kind, scripts = {}, registered = {}, shown = true,
        enabled = true, width = 400, height = 300, text = "", value = 0, level = 1 }
    local methods = {}
    function methods:SetWidth(value) self.width = value end
    function methods:GetWidth() return self.width end
    function methods:SetHeight(value) self.height = value end
    function methods:GetHeight() return self.height end
    function methods:SetText(value) self.text = tostring(value or "") end
    function methods:GetText() return self.text end
    function methods:GetStringWidth() return string.len(self.text or "") * 6 end
    function methods:GetTextColor() return 1, 1, 1 end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:Enable() self.enabled = true end
    function methods:Disable() self.enabled = false end
    function methods:IsEnabled() return self.enabled end
    function methods:SetScript(name, fn) self.scripts[name] = fn end
    function methods:GetScript(name) return self.scripts[name] end
    function methods:RegisterEvent(name) self.registered[name] = true end
    function methods:UnregisterEvent(name) self.registered[name] = nil end
    function methods:IsEventRegistered(name) return self.registered[name] and true or false end
    function methods:GetParent() return self.parent end
    function methods:GetFrameLevel() return self.level end
    function methods:SetFrameLevel(value) self.level = value end
    function methods:GetLeft() return 10 end
    function methods:GetTop() return 500 end
    function methods:SetValue(value) self.value = value end
    function methods:GetValue() return self.value end
    function methods:SetAlpha(value) self.alpha = value end
    function methods:SetBackdropBorderColor(r, g, b, a) self.borderColor = { r, g, b, a } end
    function methods:GetAlpha() return self.alpha end
    function methods:SetScrollChild(child) self.scrollChild = child end
    function methods:CreateFontString() return frame(self, "FontString") end
    function methods:CreateTexture() return frame(self, "Texture") end
    setmetatable(f, { __index = function(_, key)
        if methods[key] then return methods[key] end
        if string.match(key, "^[A-Z]") then return function() return f end end
        return nil
    end })
    table.insert(frames, f)
    return f
end

UIParent = frame(nil, "UIParent")
CreateFrame = function(kind, _, parent) return frame(parent or UIParent, kind) end
GameTooltip = frame(UIParent, "Tooltip")
StaticPopupDialogs = {}
StaticPopup_Show = function() return frame(UIParent, "Popup") end
LootFrame_OnEvent = function() end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
RAID_CLASS_COLORS = {}
ITEM_QUALITY_COLORS = {}
CANCEL = "Cancel"
ERR_TRADE_COMPLETE = "Trade complete"

local item = "|cffa335ee|Hitem:2677:0:0:0|h[Boar Ribs]|h|r"
local names = { "Master", "Carrier", "Roller" }
local announcements, grants = {}, {}
local attendance = { raidName = "Test", sessionStartedAt = 100, members = {
    { name = "Master", guildRank = "Silverback", loot = {} },
    { name = "Carrier", guildRank = "Guest", loot = {} },
    { name = "Roller", guildRank = "Chimp", loot = {} },
} }
MuklaOfficerSuite = {
    Services = {}, Modules = {}, Diagnostics = { Count = function() end },
    Database = {
        GetRaidAttendance = function() return attendance end,
        GetLootRules = function() return { guest = { sr = false, reyCoin = false },
            chimp = { sr = true, reyCoin = true } } end,
        GetSetting = function() return false end,
        SetSetting = function() end,
    },
    UI = { Theme = { classColors = {} } },
}
local ui = MuklaOfficerSuite.UI
ui.CreateButton = function(_, _, label) local b = frame(UIParent, "Button"); b.label = frame(b, "FontString"); b.label:SetText(label); return b end
ui.CreateFramedEditBox = function(parent) return frame(parent, "EditBox") end
ui.ClassicAsset = function(path) return path end
ui.RegisterSkinCallback = function() end
ui.RegisterSkinnedSurface = function() end
ui.AttachGoldHoverBorder = function() end
setmetatable(ui, { __index = function() return function() end end })

function GetNumRaidMembers() return 3 end
function GetRaidRosterInfo(index) return names[index], 0, 1, 60, "Warrior", "WARRIOR", "Test", true end
function GetMasterLootCandidate(index) return names[index] end
function GetNumLootItems() return 1 end
function GetLootSlotLink(slot) if slot == 1 then return item end end
function GetLootSlotInfo(slot) if slot == 1 then return "icon", "Boar Ribs", 1, 4 end end
function GetLootSourceInfo() return "corpse-1" end
function LootSlotIsItem(slot) return slot == 1 end
function LootSlotIsCoin() return false end
function GetRealZoneText() return "Test" end
function GetItemInfo() return "Boar Ribs", item end
function UnitName(unit) if unit == "player" then return "Master" end return "Carrier" end
function GetTime() return 200 end
function time() return 200 end
function date() return "12:00:00" end
function GetContainerNumSlots() return 0 end
function GiveMasterLoot(slot, candidate) table.insert(grants, { slot = slot, candidate = candidate }) end
function SendChatMessage(message) table.insert(announcements, message) end
function IsShiftKeyDown() return false end
function IsControlKeyDown() return false end

dofile("MuklaOfficerSuite/Services/RaidService.lua")
local raid = MuklaOfficerSuite.Services.Raid
raid.IsPlayerLootMaster = function() return true end
raid.IsInRaid = function() return true end
raid.SendRaidWarning = function(message) table.insert(announcements, message); return true end
dofile("MuklaOfficerSuite/Modules/MasterLootEvents.lua")
dofile("MuklaOfficerSuite/Modules/MasterLootWindow.lua")
local window = MuklaOfficerSuite.Modules.MasterLootWindow

local function check(value, message)
    if not value then error(message, 2) end
end
local function click(control)
    check(control and control.scripts.OnClick, "missing clickable control")
    this = control
    control.scripts.OnClick()
    this = nil
end
local function emit(target, name, message)
    check(target and target.scripts.OnEvent, "missing event handler: " .. name)
    event, arg1 = name, message
    target.scripts.OnEvent()
    event, arg1 = nil, nil
end
local function find(predicate)
    local index
    for index = 1, table.getn(frames) do
        if predicate(frames[index]) then return frames[index] end
    end
end
local function announced(fragment)
    local index
    for index = 1, table.getn(announcements) do
        if string.find(announcements[index], fragment, 1, true) then return true end
    end
    return false
end

window.Open()
local lootRow = find(function(f) return f.rollButton and f.link == item end)
check(lootRow, "loot row was not rendered")
click(lootRow.rollButton)
local rollEvents = find(function(f) return f.registered.CHAT_MSG_SYSTEM and f.scripts.OnEvent end)
check(rollEvents, "roll event listener was not registered")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Roller rolls 18 (1-101)")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Carrier rolls 29 (1-98)")
local finish = find(function(f) return f.label and f.label.text == "Finish" and f.scripts.OnClick end)
click(finish)
check(announced("must trade it to Roller"), "Transmog handoff warning was not sent")
local invalidRow = find(function(f) return f.giveButton and f.playerName == "Roller" end)
local carrierRow = find(function(f) return f.giveButton and f.playerName == "Carrier" end)
check(carrierRow and carrierRow.giveButton.enabled, "winning Give loot button is not enabled")
check(invalidRow and invalidRow.giveButton.enabled,
    "valid non-carrier roll cannot be selected manually")
check(rollEvents.registered.CHAT_MSG_SYSTEM, "roll listener stopped before item award")
click(carrierRow.giveButton)
local popup = StaticPopupDialogs.MUKLA_OFFICER_SUITE_GIVE_MASTER_LOOT
check(popup and popup.OnAccept, "Give loot confirmation is missing")
popup.OnAccept({ roll = carrierRow.roll, name = carrierRow.playerName })
check(table.getn(grants) == 1 and grants[1].candidate == 2, "Give loot targeted the wrong player")
check(raid.HasPendingReyCoinAward(), "Give loot did not queue ReyCoin transaction")
check(not find(function(f) return f.registered.CHAT_MSG_SYSTEM and f ~= rollEvents end),
    "trade listener started before carrier receipt")
emit(rollEvents, "LOOT_SLOT_CLEARED", 1)
check(not rollEvents.registered.CHAT_MSG_SYSTEM, "roll listener remained active after item award")
check(table.getn(attendance.members[2].loot) == 1
    and table.getn(attendance.members[2].loot[1].rollHistory or {}) > 0,
    "confirmed carrier award did not record loot and roll history")
local pending = raid.GetPendingReyCoinTransfers()
check(table.getn(pending) == 1 and pending[1].state == "awaiting_trade",
    "carrier receipt did not expose awaiting trade")
local tradeEvents = find(function(f) return f.registered.CHAT_MSG_SYSTEM and f ~= rollEvents and f.scripts.OnEvent end)
check(tradeEvents, "trade message listener was not registered")
check(not tradeEvents.registered.CHAT_MSG_SAY, "ordinary say channel should be disabled")
emit(tradeEvents, "CHAT_MSG_SAY", "Carrier traded Boar Ribs to Roller.")
check(raid.HasPendingReyCoinAward(), "say message finalized a production trade")
emit(tradeEvents, "CHAT_MSG_SYSTEM", "Carrier trades item Boar Ribs to Roller.")
check(announced("Carrier traded"), "confirmed trade raid warning is missing")
check(raid.HasUsedReyCoin("Roller"), "trade did not consume ReyCoin")
check(not raid.HasPendingReyCoinAward(), "confirmed trade remained on pending list")
check(not tradeEvents.registered.CHAT_MSG_SYSTEM, "trade listener remained active after confirmation")
check(table.getn(attendance.members[3].loot) == 1
    and attendance.members[3].loot[1].tradedFrom == "Carrier",
    "real-format trade did not move the history to the recipient")

-- A second copy with SR stays open to late rolls after the timer finishes.
attendance.members[3].srItemIds = { 2677 }
click(lootRow.rollButton)
check(rollEvents.registered.CHAT_MSG_SYSTEM, "second roll did not start listening")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Roller rolls 51 (1-102)")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Carrier rolls 70 (1-98)")
click(finish)
check(rollEvents.registered.CHAT_MSG_SYSTEM, "listener stopped at timer end instead of award")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Master rolls 80 (1-98)")
local late = find(function(f) return f.result and f.result.name == "Master" and f.result.range == 98 end)
check(late and late.result.valid and late.roll, "late valid roll was not shown in Current roll")
click(late)
check(late.roll.manualWinnerResult == late.result and late.roll.winner == "Master"
    and late.borderColor and late.borderColor[1] == 1,
    "clicking a late valid roll did not select it with a gold border")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Master rolls 30 (1-102)")
local invalid = find(function(f) return f.result and f.result.name == "Master" and f.result.range == 102 end)
check(invalid and invalid.result.valid == false, "late invalid roll was not displayed")
click(invalid)
check(late.roll.winner == "Master" and late.roll.manualWinnerResult == late.result,
    "invalid row changed the selected winner")
local reserverRow = find(function(f) return f.giveButton and f.result and f.result.name == "Roller" and f.result.range == 102 end)
check(reserverRow and reserverRow.giveButton.enabled, "valid SR row could not be granted manually")
click(reserverRow)
check(reserverRow.roll.winner == "Roller", "manual SR choice did not replace the Transmog carrier")
popup.OnAccept({ roll = reserverRow.roll, name = "Roller" })
check(not attendance.members[3].srConsumedAt, "SR was consumed before direct receipt")
emit(rollEvents, "LOOT_SLOT_CLEARED", 1)
check(attendance.members[3].srConsumedAt and attendance.members[3].srConsumedAt[2677],
    "confirmed direct receipt did not consume SR")
check(not rollEvents.registered.CHAT_MSG_SYSTEM, "listener remained after the second award")
check(table.getn(attendance.members[3].loot) == 2,
    "second confirmed award did not append recipient loot history")
check(not raid.GetSoftReserveRollRights(item), "a second copy still offered fulfilled SR")

-- A linked item starts the same roll UI without exposing Master Loot award
-- actions, and reused rows must return to ordinary loot state afterwards.
check(window.OpenLinkedItemRoll(item), "linked-item roll did not open")
local manualRow = find(function(f) return f.rollButton and f.link == item and f.rollButton.shown == false end)
check(manualRow, "linked item was not rendered as a manual row")
check(rollEvents.registered.CHAT_MSG_SYSTEM, "linked-item roll did not start listening")
emit(rollEvents, "CHAT_MSG_SYSTEM", "Master rolls 64 (1-100)")
click(finish)
check(not rollEvents.registered.CHAT_MSG_SYSTEM, "linked-item listener remained active after finish")
local manualResult = find(function(f) return f.result and f.result.name == "Master" and f.roll and f.roll.manual end)
check(manualResult and manualResult.giveButton.shown == false,
    "linked-item result exposed a Master Loot award action")
window.Open()
local reopenedLootRow = find(function(f) return f.rollButton and f.link == item and f.rollButton.shown end)
check(reopenedLootRow, "manual row state leaked into the next corpse loot window")

-- The slash command preserves the item link and delegates to the window.
MuklaOfficerSuite.Core = {}
SlashCmdList = {}
dofile("MuklaOfficerSuite/Core/Commands.lua")
local delegated
MuklaOfficerSuite.Core.Commands.Attach({
    dashboard = frame(UIParent, "Frame"), minimapButton = frame(UIParent, "Button"),
    showPage = function() end, toggleDashboard = function() end, printMessage = function() end,
    countSavedMembers = function() return 0 end, printLayoutDiagnostics = function() end,
    startLinkedItemRoll = function(link) delegated = link end,
})
SlashCmdList.MUKLAOFFICERSUITE("roll " .. item)
check(delegated == item, "/mos roll did not preserve and forward the linked item")

print("Master Loot window regression scenarios passed")
