-- Run from the repository root with a Lua 5.0 interpreter:
-- lua Tests/LootRulesRegression.lua
-- Uses the production RaidService policy, without loading the WoW UI.

MuklaOfficerSuite = { Services = {}, Database = {}, Diagnostics = { Count = function() end } }
local attendance = { sessionStartedAt = 100, members = {
    { name = "Reserver", guildRank = "Baboon", srItemIds = { 2677 } },
    { name = "Guest", guildRank = "Guest", srItemIds = { 2677 } },
    { name = "Outsider", guildRank = "Chimp" },
    { name = "Officer", guildRank = "Officer Wukong", officerNote = "Guest" },
} }
local rules = {
    baboon = { sr = true, reyCoin = true },
    guest = { sr = false, reyCoin = false },
    chimp = { sr = true, reyCoin = true },
}
function MuklaOfficerSuite.Database.GetRaidAttendance() return attendance end
function MuklaOfficerSuite.Database.GetLootRules() return rules end
function GetNumRaidMembers() return 0 end
function time() return 200 end
function GetTime() return 200 end
function GetItemInfo() return nil end
dofile("MuklaOfficerSuite/Services/RaidService.lua")
local raid = MuklaOfficerSuite.Services.Raid

local function check(condition, message)
    if not condition then error(message, 2) end
end
local function round(link)
    local restricted, reserved, allowed, names, rankRights, rankNames, coinRights = raid.GetSoftReserveRollRights(link)
    return { link = link, srRestricted = restricted, srReserved = reserved, srAllowed = allowed,
        srNames = names, srRankRights = rankRights, srRankNames = rankNames, reyCoinRights = coinRights,
        seen = {}, results = {}, highest = -1, highestPriority = -1, transmogHighest = -1 }
end
local function roll(state, name, value, range, used)
    return raid.ProcessLootRoll(state, name, value, range, used)
end

local reserved = round("|Hitem:2677:0:0:0|h[Boar Ribs]|h")
check(reserved.srRestricted, "item should be SR restricted")
local automatic = round("|Hitem:2677:0:0:0|h[Boar Ribs]|h")
local automaticWinner = raid.FinalizeLootRoll(automatic)
check(automaticWinner == "Reserver" and automatic.winnerResult.automatic
    and automatic.winnerResult.range == 102,
    "single eligible in-raid reserver did not win automatically")
local sr = roll(reserved, "Reserver", 31, 102)
check(sr and sr.valid and reserved.winner == "Reserver", "valid SR did not win")
local wrong, reason = roll(reserved, "Reserver", 99, 100)
check(wrong and not wrong.valid and reason == "wrong roll, use /roll 102", "reserved player wrong-range reason")
local noRank, rankReason = roll(reserved, "Guest", 100, 102)
check(noRank and not noRank.valid and rankReason == "no SR for rank guest", "Guest SR rank rule")
local noReserve, reserveReason = roll(reserved, "Outsider", 100, 102)
check(noReserve and not noReserve.valid and reserveReason == "no SR for this item", "non-reserver SR rule")
local wrongCoin = roll(reserved, "Reserver", 100, 101)
check(wrongCoin and not wrongCoin.valid and reserved.winner == "Reserver", "ReyCoin bypassed SR")
local transmog = roll(reserved, "Guest", 8, 98)
check(transmog and transmog.valid and reserved.transmogWinner == "Guest", "Transmog should be separate and rank independent")
check(reserved.winner == "Reserver", "Transmog displaced SR main-pool winner")

local open = round("|Hitem:769:0:0:0|h[Chunk of Boar Meat]|h")
check(not open.srRestricted, "unreserved item was restricted")
local os = roll(open, "Guest", 99, 99)
check(os and os.valid and open.winner == "Guest", "OS should be available to Guest")
local ms = roll(open, "Outsider", 1, 100)
check(ms and ms.valid and open.winner == "Outsider", "MS did not outrank OS")
local coin = roll(open, "Reserver", 1, 101)
check(coin and coin.valid and open.winner == "Reserver" and open.winnerUsesReyCoin,
    "ReyCoin did not outrank MS regardless of rolled value")
local used, usedReason = roll(open, "Outsider", 80, 101, true)
check(used and not used.valid and usedReason == "ReyCoin already used", "used ReyCoin should be invalid")
local guestCoin, guestReason = roll(open, "Guest", 80, 101)
check(guestCoin and not guestCoin.valid and guestReason == "no loot rights to ReyCoin for rank guest",
    "Guest ReyCoin restriction")
local bad, badReason = roll(open, "Guest", 100, 102)
check(bad and not bad.valid and badReason == "wrong roll, use /roll 98, 99, 100 or 101",
    "unreserved item wrong-range reason")
local repeated = roll(open, "Reserver", 99, 101)
check(not repeated and open.winnerResult == coin, "repeat of a valid roll replaced the first roll")
check(open.results[table.getn(open.results)].valid == false, "invalid rolls should sort last")

-- A rejected roll remains in history, but a later eligible roll in that
-- same range may supersede it without changing the first result's validity.
rules.guest.reyCoin = true
local updated = round("|Hitem:2296:0:0:0|h[Great Goretusk Snout]|h")
check(updated.reyCoinRights.guest, "changed ReyCoin rule was not used by the next round")
local invalid = roll(updated, "Guest", 20, 101, true)
check(invalid and not invalid.valid, "already-used roll should remain visible")
local valid = roll(updated, "Guest", 30, 101, false)
check(valid and valid.valid and updated.winner == "Guest", "valid retry after invalid roll failed")
check(invalid.valid == false, "valid retry changed the invalid history entry")
local officer = round("|Hitem:3333:0:0:0|h[Officer Item]|h")
check(officer.reyCoinRights.officer, "Officer Wukong did not use updated Guest officer-note rank")

local carrierRound = round("|Hitem:4444:0:0:0|h[Carrier Item]|h")
roll(carrierRound, "Outsider", 1, 101)
roll(carrierRound, "Guest", 98, 98)
local carrier, beneficiary = raid.FinalizeLootRoll(carrierRound)
check(carrier == "Guest" and beneficiary == "Outsider", "Transmog carrier and ReyCoin beneficiary were not separated")
check(carrierRound.winnerResult.range == 98 and carrierRound.tradeWinnerResult.range == 101,
    "finalized roll lost either pool result")
local ordinaryRound = round("|Hitem:5555:0:0:0|h[Ordinary Item]|h")
roll(ordinaryRound, "Outsider", 50, 100)
local ordinaryWinner, ordinaryTrade = raid.FinalizeLootRoll(ordinaryRound)
check(ordinaryWinner == "Outsider" and not ordinaryTrade, "ordinary winner incorrectly requires a trade")

-- A reserve is available until receipt, not merely until the winning roll.
local secondCopy = round("|Hitem:2677:0:0:0|h[Boar Ribs]|h")
check(secondCopy.srRestricted and secondCopy.srAllowed.reserver,
    "winning an earlier roll consumed SR before receipt")
check(raid.ConfirmSoftReserveReceipt("Reserver", secondCopy.link), "confirmed direct SR receipt was not recorded")
local afterReceipt = round(secondCopy.link)
check(not afterReceipt.srRestricted and not afterReceipt.srAllowed.reserver,
    "the second copy still requires an already fulfilled SR")
attendance.sessionStartedAt = 201
local nextSession = round(secondCopy.link)
check(nextSession.srRestricted and nextSession.srAllowed.reserver,
    "fulfilled SR leaked into a new raid session")

-- Re-evaluating a finished round must honor a manual valid choice, even
-- when a Transmog carrier previously won automatically.
local manual = round("|Hitem:4444:0:0:0|h[Carrier Item]|h")
local mainRoll = roll(manual, "Outsider", 20, 101)
roll(manual, "Guest", 30, 98)
check(raid.FinalizeLootRoll(manual) == "Guest", "automatic Transmog carrier changed")
manual.manualWinnerResult = mainRoll
check(raid.FinalizeLootRoll(manual) == "Outsider" and not manual.tradeWinner,
    "manual valid main-pool selection did not override Transmog")

print("Loot rules regression scenarios passed")
