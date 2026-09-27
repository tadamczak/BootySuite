-- Run from the repository root with a Lua 5.0 interpreter:
-- lua Tests/ReyCoinRegression.lua
-- This is an isolated service test. It does not load the WoW client or UI.

MuklaOfficerSuite = {
    Services = {},
    Database = {},
    Diagnostics = { Count = function() end },
}

local attendance = {
    sessionStartedAt = 100,
    members = {
        { name = "LootMaster", guildRank = "Silverback", loot = {} },
        { name = "RayPlayer", guildRank = "Guest", loot = {} },
        { name = "Transmog", guildRank = "Guest", loot = {} },
    },
}
local rules = { guest = { sr = false, reyCoin = false } }
local now = 200

function MuklaOfficerSuite.Database.GetRaidAttendance() return attendance end
function MuklaOfficerSuite.Database.GetLootRules() return rules end
function GetNumRaidMembers() return 0 end
function GetItemInfo() return nil end
function time() return now end
function GetTime() return now end

dofile("MuklaOfficerSuite/Services/RaidService.lua")
local raid = MuklaOfficerSuite.Services.Raid

local function check(condition, message)
    if not condition then error(message, 2) end
end

local function item(id, name)
    return "|cffa335ee|Hitem:" .. id .. ":0:0:0|h[" .. name .. "]|h|r"
end

local first = item(2677, "Boar Ribs")
local second = item(769, "Chunk of Boar Meat")
local third = item(2296, "Great Goretusk Snout")

-- Changes to loot rules must be visible on the next roll, not cached.
local _, _, _, _, _, _, rights = raid.GetSoftReserveRollRights(first)
check(not rights.rayplayer, "Guest should initially lack ReyCoin rights")
rules.guest.reyCoin = true
local _, _, _, _, _, _, updatedRights = raid.GetSoftReserveRollRights(first)
check(updatedRights.rayplayer, "Guest rule change was not applied")

-- First award is carried by a Transmog winner, then traded to the ReyCoin roller.
check(raid.QueueReyCoinAward("RayPlayer", first, "Transmog", { rayplayer = true }, "round-1"), "first award was not queued")
check(raid.HasPendingReyCoinAward(), "first award is missing")
check(not raid.HasUsedReyCoin("RayPlayer"), "ReyCoin was consumed before receipt")
check(raid.ConfirmReyCoinReceipt("Transmog", first), "Transmog receipt was not recognized")
local pending = raid.GetPendingReyCoinTransfers()
check(table.getn(pending) == 1 and pending[1].state == "awaiting_trade", "first trade is not pending")
check(not raid.HasUsedReyCoin("RayPlayer"), "carrier receipt consumed the ReyCoin")
local traded = raid.ConfirmReyCoinTrade("Transmog", "RayPlayer", "Boar Ribs")
check(traded, "first trade was not confirmed by item name")
check(raid.HasUsedReyCoin("RayPlayer"), "first trade did not consume ReyCoin")
check(not raid.HasPendingReyCoinAward(), "first transaction was not removed")
check(table.getn(attendance.members[2].loot) == 1, "first trade was not recorded in recipient history")
check(attendance.members[2].loot[1].tradedFrom == "Transmog", "history lost the sender")

-- Removing the list entry restores eligibility; a second transaction must
-- behave exactly like the first, including a newly visible pending entry.
check(raid.SetReyCoinUsage("RayPlayer", nil, false), "usage could not be removed")
check(not raid.HasUsedReyCoin("RayPlayer"), "removed usage still blocks ReyCoin")
check(raid.QueueReyCoinAward("RayPlayer", second, "Transmog", { rayplayer = true }, "round-2"), "second award was not queued")
pending = raid.GetPendingReyCoinTransfers()
check(table.getn(pending) == 1 and pending[1].itemId == "769", "second transaction is missing")
check(raid.ConfirmReyCoinReceipt("Transmog", second), "second carrier receipt failed")
check(pending[1].state == "awaiting_trade", "second awaiting-trade state is missing")
local wrongRecipient = raid.ConfirmReyCoinTrade("Transmog", "LootMaster", "Chunk of Boar Meat")
check(not wrongRecipient and raid.HasPendingReyCoinAward(), "unqualified recipient finalized the trade")
check(raid.ConfirmReyCoinTrade("Transmog", "RayPlayer", "Chunk of Boar Meat"), "second trade failed")
check(raid.HasUsedReyCoin("RayPlayer"), "second trade did not consume ReyCoin")
check(not raid.HasPendingReyCoinAward(), "second transaction was not removed")
check(table.getn(attendance.members[2].loot) == 2, "second trade was not recorded in history")

-- A later direct award consumes only after the winner receives the item.
check(raid.SetReyCoinUsage("RayPlayer", nil, false), "second usage could not be removed")
check(raid.QueueReyCoinAward("RayPlayer", third, "RayPlayer", { rayplayer = true }, "round-3"), "direct award was not queued")
check(not raid.HasUsedReyCoin("RayPlayer"), "direct award consumed ReyCoin before receipt")
check(raid.ConfirmReyCoinReceipt("RayPlayer", third), "direct receipt was not confirmed")
check(raid.HasUsedReyCoin("RayPlayer"), "direct receipt did not consume ReyCoin")
check(not raid.HasPendingReyCoinAward(), "direct transaction was not removed")

print("ReyCoin service regression scenarios passed")
