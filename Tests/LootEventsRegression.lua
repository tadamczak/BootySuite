-- Run from the repository root. Exercises the production service contracts
-- used by loot/chat events, without pretending to run the WoW frame layer.

MuklaOfficerSuite = { Services = {}, Database = {}, Diagnostics = { Count = function() end } }
local attendance = { sessionStartedAt = 100, members = {
    { name = "Master", guildRank = "Silverback", loot = {} },
    { name = "Carrier", guildRank = "Guest", loot = {} },
    { name = "Roller", guildRank = "Chimp", loot = {} },
    { name = "Other", guildRank = "Chimp", loot = {} },
    { name = "Reserver", guildRank = "Chimp", srItemIds = { 3333 }, loot = {} },
} }
function MuklaOfficerSuite.Database.GetRaidAttendance() return attendance end
function MuklaOfficerSuite.Database.GetLootRules() return { chimp = { sr = true, reyCoin = true } } end
function GetNumRaidMembers() return 0 end
function GetItemInfo() return nil end
function time() return 200 end
function GetTime() return 200 end
function UnitName() return "Master" end
dofile("MuklaOfficerSuite/Services/RaidService.lua")
local raid = MuklaOfficerSuite.Services.Raid
local changed, confirmed = 0, {}
raid.onReyCoinChanged = function() changed = changed + 1 end
raid.onReyCoinTradeConfirmed = function(sender, recipient, link, historyKey)
    table.insert(confirmed, { sender = sender, recipient = recipient, link = link, historyKey = historyKey })
end
local function check(condition, message)
    if not condition then error(message, 2) end
end
local first = "|cffa335ee|Hitem:2677:0:0:0|h[Boar Ribs]|h|r"
local second = "|cffa335ee|Hitem:769:0:0:0|h[Chunk of Boar Meat]|h|r"
local localItem = "|cffa335ee|Hitem:2296:0:0:0|h[Great Goretusk Snout]|h|r"
local reservedItem = "|cffa335ee|Hitem:3333:0:0:0|h[Reserved Item]|h|r"

check(raid.PrefixLootMasterMessage("Rolling started") == "[Loot Master]: Rolling started",
    "automatic message prefix changed")
check(raid.QueueReyCoinAward("Roller", first, "Carrier", { roller = true }, "round-1"), "queue failed")
check(not raid.HasUsedReyCoin("Roller"), "queue spent ReyCoin")
check(not raid.ConfirmReyCoinLoot("Other receives loot: " .. first .. "."),
    "unrelated loot message confirmed the award")
check(raid.ConfirmReyCoinLoot("Carrier receives loot: " .. first .. "."),
    "carrier loot event was not parsed")
local pending = raid.GetPendingReyCoinTransfers()
check(table.getn(pending) == 1 and pending[1].state == "awaiting_trade",
    "list did not expose awaiting-trade state")
check(not raid.HasUsedReyCoin("Roller"), "carrier receipt spent ReyCoin")
check(not raid.ConfirmReyCoinTrade("Other", "Roller", "Boar Ribs"),
    "wrong trade sender consumed ReyCoin")
check(not raid.ConfirmReyCoinTrade("Carrier", "Other", "Boar Ribs"),
    "recipient without valid ReyCoin roll consumed it")
check(raid.HasPendingReyCoinAward(), "rejected trade removed pending award")
check(raid.ConfirmReyCoinTrade("Carrier", "Roller", "Boar Ribs"),
    "matching item-name trade was not confirmed")
check(raid.HasUsedReyCoin("Roller") and not raid.HasPendingReyCoinAward(),
    "successful trade did not update usage and list")
check(table.getn(confirmed) == 1 and confirmed[1].historyKey == "round-1",
    "trade confirmation callback lost the round identity")
check(table.getn(attendance.members[3].loot) == 1
    and attendance.members[3].loot[1].tradedFrom == "Carrier",
    "recipient loot history was not updated")

check(raid.SetReyCoinUsage("Roller", nil, false), "entry removal failed")
check(raid.QueueReyCoinAward("Roller", second, "Carrier", { roller = true }, "round-2"),
    "second queue failed")
check(raid.ConfirmReyCoinLoot("Carrier receives loot: " .. second .. "."),
    "second carrier loot event was not parsed")
check(raid.ConfirmReyCoinTrade("Carrier", "Roller", "Chunk of Boar Meat"),
    "second item-name trade was not confirmed")
check(table.getn(confirmed) == 2 and confirmed[2].historyKey == "round-2",
    "second trade callback did not fire")
check(table.getn(attendance.members[3].loot) == 2, "second history entry is missing")

-- The local-player loot message is a separate parsing path.
check(raid.QueueReyCoinAward("Master", localItem, "Master", { master = true }, "round-3"),
    "direct queue failed")
check(raid.ConfirmReyCoinLoot("You receive loot: " .. localItem .. "."),
    "local loot event was not parsed")
check(raid.HasUsedReyCoin("Master"), "local receipt did not consume ReyCoin")
check(not raid.HasPendingReyCoinAward(), "local receipt left a pending entry")
check(changed > 0, "list refresh callback never fired")

check(raid.QueueReyCoinAward("Roller", first, "Carrier", { roller = true }, "cancelled"),
    "cancellable award was not queued")
local cancelled = raid.GetPendingReyCoinTransfers()[1]
check(raid.CancelPendingReyCoinTransfer(cancelled), "pending award could not be cancelled")
check(not raid.HasPendingReyCoinAward(), "cancelled award remains pending")
check(not raid.HasUsedReyCoin("Other"), "cancellation consumed another player's ReyCoin")
check(not raid.ConfirmReyCoinTrade("Carrier", "Roller", "Boar Ribs"),
    "cancelled award accepted a later trade")

-- The confirmed master-loot slot records history even without a separate
-- chat-loot event; a later copy of that event must not duplicate the record.
raid.QueueRollHistoryForAward("Master", second, { "Round 1: Master (42/100)" })
check(raid.RecordPendingAwardReceipt("Master", second), "confirmed award did not write loot history")
check(table.getn(attendance.members[1].loot) == 1
    and attendance.members[1].loot[1].rollHistory[1] == "Round 1: Master (42/100)",
    "confirmed award lost its roll history")
check(not raid.RecordLoot("Master receives loot: " .. second),
    "chat echo duplicated a confirmed master-loot record")

-- Two real awards of the same item may arrive before either chat echo.
raid.QueueRollHistoryForAward("Master", second, { "Round 2: Master (51/100)" })
check(raid.RecordPendingAwardReceipt("Master", second),
    "first rapid repeat award was mistaken for the previous chat echo")
raid.QueueRollHistoryForAward("Master", second, { "Round 3: Master (62/100)" })
check(raid.RecordPendingAwardReceipt("Master", second),
    "second rapid repeat award was mistaken for a chat echo")
check(table.getn(attendance.members[1].loot) == 3
    and attendance.members[1].loot[2].rollHistory[1] == "Round 2: Master (51/100)"
    and attendance.members[1].loot[3].rollHistory[1] == "Round 3: Master (62/100)",
    "rapid repeated awards lost separate loot-history records")
check(not raid.RecordLoot("Master receives loot: " .. second)
    and not raid.RecordLoot("Master receives loot: " .. second)
    and table.getn(attendance.members[1].loot) == 3,
    "chat echoes duplicated rapid repeated awards")

-- SR through Transmog remains available at carrier receipt. Only the
-- matching final transfer consumes the reserve and moves loot history.
check(raid.GetSoftReserveRollRights(reservedItem), "reserved item was not SR restricted")
check(raid.QueueSoftReserveTrade("Reserver", reservedItem, "Carrier", "sr-round",
    { "Round 1: Reserver (55/102)" }), "SR handoff was not queued")
check(not raid.HasPendingSoftReserveTrade(), "SR trade listened before carrier receipt")
check(raid.ConfirmSoftReserveCarrierReceipt("Carrier", reservedItem),
    "carrier receipt did not start SR trade listening")
check(raid.HasPendingSoftReserveTrade() and raid.GetSoftReserveRollRights(reservedItem),
    "carrier receipt consumed the reserver's SR")
check(not raid.ConfirmSoftReserveTrade("Other", "Reserver", "Reserved Item"),
    "wrong carrier consumed SR")
check(not raid.ConfirmSoftReserveTrade("Carrier", "Other", "Reserved Item"),
    "wrong recipient consumed SR")
check(not raid.ConfirmSoftReserveTrade("Carrier", "Reserver", "Different Item"),
    "wrong item consumed SR")
check(raid.ConfirmSoftReserveTrade("Carrier", "Reserver", "Reserved Item"),
    "matching SR transfer was not confirmed")
check(not raid.HasPendingSoftReserveAward() and not raid.GetSoftReserveRollRights(reservedItem),
    "confirmed transfer did not consume SR")
check(table.getn(attendance.members[5].loot) == 1
    and attendance.members[5].loot[1].tradedFrom == "Carrier"
    and attendance.members[5].loot[1].rollHistory[1] == "Round 1: Reserver (55/102)",
    "confirmed SR transfer lost recipient loot history")

print("Loot event service regression scenarios passed")
