local ADDON_NAME = "MuklaOfficerSuite"
local VERSION = "0.1.0"
local PREFIX = "|cff33ff99MOS|r"

local MOS = CreateFrame("Frame", "MuklaOfficerSuiteEventFrame")
MOS.pendingScan = nil
MOS.lastRosterEvent = 0

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. ": " .. tostring(message))
end

local function EnsureDatabase()
    if type(MuklaOfficerSuiteDB) ~= "table" then
        MuklaOfficerSuiteDB = {}
    end
    if type(MuklaOfficerSuiteDB.guilds) ~= "table" then
        MuklaOfficerSuiteDB.guilds = {}
    end
    if type(MuklaOfficerSuiteDB.minimap) ~= "table" then
        MuklaOfficerSuiteDB.minimap = { angle = 220, hidden = false }
    end
end

local function GuildKey()
    local guildName = GetGuildInfo("player")
    if not guildName then
        return nil
    end
    local realmName = GetRealmName() or "UnknownRealm"
    return realmName .. " - " .. guildName, guildName, realmName
end

local function CountSavedMembers()
    local key = GuildKey()
    if not key or not MuklaOfficerSuiteDB.guilds[key] then
        return 0
    end
    return table.getn(MuklaOfficerSuiteDB.guilds[key].members or {})
end

local function SaveGuildRoster()
    EnsureDatabase()
    local key, guildName, realmName = GuildKey()
    if not key then
        Print("This character is not in a guild.")
        return false
    end

    local total = GetNumGuildMembers(true)
    if not total or total < 1 then
        return false
    end

    local members = {}
    local i
    for i = 1, total do
        local name, rank, rankIndex, level, class, zone, publicNote, officerNote, online, status = GetGuildRosterInfo(i)
        if name then
            table.insert(members, {
                name = name,
                level = level or 0,
                class = class or "",
                rank = rank or "",
                rankIndex = rankIndex,
                publicNote = publicNote or "",
                officerNote = officerNote or "",
                online = online and true or false,
                zone = zone or "",
                status = status,
            })
        end
    end

    table.sort(members, function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end)

    MuklaOfficerSuiteDB.guilds[key] = {
        guildName = guildName,
        realmName = realmName,
        updatedAt = time(),
        updatedBy = UnitName("player"),
        members = members,
    }
    MOS.pendingScan = nil
    return true
end

local dashboard = CreateFrame("Frame", "MuklaOfficerSuiteDashboard", UIParent)
dashboard:SetWidth(620)
dashboard:SetHeight(420)
dashboard:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
dashboard:SetFrameStrata("DIALOG")
dashboard:SetMovable(true)
dashboard:EnableMouse(true)
dashboard:RegisterForDrag("LeftButton")
dashboard:SetScript("OnDragStart", function() this:StartMoving() end)
dashboard:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
dashboard:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
dashboard:Hide()

local title = dashboard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", dashboard, "TOP", 0, -18)
title:SetText("Mukla Officer Suite")

local subtitle = dashboard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
subtitle:SetText("Guild dashboard")

local closeButton = CreateFrame("Button", nil, dashboard, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", dashboard, "TOPRIGHT", -5, -5)

local statusText = dashboard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
statusText:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 28, -62)
statusText:SetWidth(560)
statusText:SetJustifyH("LEFT")

local function CreateColumnLabel(text, x, width, alignment)
    local label = dashboard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", dashboard, "TOPLEFT", x, -98)
    label:SetWidth(width)
    label:SetHeight(18)
    label:SetJustifyH(alignment or "LEFT")
    label:SetText(text)
    return label
end

CreateColumnLabel("Name", 28, 150)
CreateColumnLabel("Lvl", 183, 35, "RIGHT")
CreateColumnLabel("Class", 228, 90)
CreateColumnLabel("Rank", 328, 115)
CreateColumnLabel("Public / Officer note", 453, 130)

local rows = {}
local rowCount = 13
local rowHeight = 19
local i
for i = 1, rowCount do
    local row = CreateFrame("Frame", nil, dashboard)
    row:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 28, -100 - (i * rowHeight))
    row:SetWidth(555)
    row:SetHeight(rowHeight)

    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.name:SetWidth(150)
    row.name:SetHeight(18)
    row.name:SetJustifyH("LEFT")

    row.level = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.level:SetPoint("LEFT", row, "LEFT", 155, 0)
    row.level:SetWidth(35)
    row.level:SetHeight(18)
    row.level:SetJustifyH("RIGHT")

    row.class = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.class:SetPoint("LEFT", row, "LEFT", 200, 0)
    row.class:SetWidth(90)
    row.class:SetHeight(18)
    row.class:SetJustifyH("LEFT")

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.rank:SetPoint("LEFT", row, "LEFT", 300, 0)
    row.rank:SetWidth(115)
    row.rank:SetHeight(18)
    row.rank:SetJustifyH("LEFT")

    row.notes = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.notes:SetPoint("LEFT", row, "LEFT", 425, 0)
    row.notes:SetWidth(130)
    row.notes:SetHeight(18)
    row.notes:SetJustifyH("LEFT")

    rows[i] = row
end

local rosterScrollFrame = CreateFrame("ScrollFrame", "MuklaOfficerSuiteRosterScrollFrame", dashboard, "FauxScrollFrameTemplate")
rosterScrollFrame:SetPoint("TOPLEFT", dashboard, "TOPLEFT", 20, -115)
rosterScrollFrame:SetPoint("BOTTOMRIGHT", dashboard, "BOTTOMRIGHT", -26, 59)

local function Short(text, length)
    text = tostring(text or "")
    if string.len(text) > length then
        return string.sub(text, 1, length - 1) .. "~"
    end
    return text
end

local function RefreshDashboard()
    EnsureDatabase()
    local key, guildName = GuildKey()
    local data = key and MuklaOfficerSuiteDB.guilds[key]
    if not key then
        statusText:SetText("No guild found. Log in with a character who belongs to a guild.")
    elseif not data then
        statusText:SetText(guildName .. " - no saved roster. Click Scan or Scan & Reload.")
    else
        statusText:SetText(guildName .. " - saved members: " .. table.getn(data.members) .. " | last scan: " .. date("%Y-%m-%d %H:%M", data.updatedAt))
    end

    local memberCount = data and table.getn(data.members) or 0
    FauxScrollFrame_Update(rosterScrollFrame, memberCount, rowCount, rowHeight)
    local offset = FauxScrollFrame_GetOffset(rosterScrollFrame)

    for i = 1, rowCount do
        local member = data and data.members[offset + i]
        if member then
            local notes = member.publicNote
            if member.officerNote ~= "" then
                notes = notes .. " / " .. member.officerNote
            end
            rows[i].name:SetText(Short(member.name, 20))
            rows[i].level:SetText(member.level)
            rows[i].class:SetText(Short(member.class, 12))
            rows[i].rank:SetText(Short(member.rank, 16))
            rows[i].notes:SetText(Short(notes, 21))
            rows[i]:Show()
        else
            rows[i]:Hide()
        end
    end
end


rosterScrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(rowHeight, RefreshDashboard)
end)

local function RequestRosterScan(scanMode)
    EnsureDatabase()
    if not IsInGuild() then
        Print("This character is not in a guild.")
        return
    end
    MOS.pendingScan = scanMode or "manual"
    GuildRoster()
    if MOS.pendingScan == "reload" then
        Print("Requesting guild roster. The UI will reload after the scan completes...")
    else
        Print("Requesting guild roster...")
    end
end

local scanButton = CreateFrame("Button", nil, dashboard, "UIPanelButtonTemplate")
scanButton:SetWidth(85)
scanButton:SetHeight(24)
scanButton:SetPoint("BOTTOMLEFT", dashboard, "BOTTOMLEFT", 28, 24)
scanButton:SetText("Scan")
scanButton:SetScript("OnClick", function() RequestRosterScan("manual") end)

local scanReloadButton = CreateFrame("Button", nil, dashboard, "UIPanelButtonTemplate")
scanReloadButton:SetWidth(125)
scanReloadButton:SetHeight(24)
scanReloadButton:SetPoint("LEFT", scanButton, "RIGHT", 8, 0)
scanReloadButton:SetText("Scan & Reload")
scanReloadButton:SetScript("OnClick", function() RequestRosterScan("reload") end)

local infoText = dashboard:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
infoText:SetPoint("LEFT", scanReloadButton, "RIGHT", 12, 0)
infoText:SetWidth(315)
infoText:SetJustifyH("LEFT")
infoText:SetText("Use Scan & Reload to save the roster to disk.")

dashboard:SetScript("OnShow", RefreshDashboard)

local function ToggleDashboard()
    if dashboard:IsVisible() then
        dashboard:Hide()
    else
        dashboard:Show()
        RefreshDashboard()
    end
end

local minimapButton = CreateFrame("Button", "MuklaOfficerSuiteMinimapButton", Minimap)
minimapButton:SetWidth(32)
minimapButton:SetHeight(32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")

local minimapIcon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapIcon:SetWidth(20)
minimapIcon:SetHeight(20)
minimapIcon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")

local minimapBorder = minimapButton:CreateTexture(nil, "OVERLAY")
minimapBorder:SetWidth(52)
minimapBorder:SetHeight(52)
minimapBorder:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
minimapBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local function PositionMinimapButton()
    EnsureDatabase()
    local angle = MuklaOfficerSuiteDB.minimap.angle or 220
    local radians = math.rad(angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(radians), 80 * math.sin(radians))
end

minimapButton:SetScript("OnClick", function()
    ToggleDashboard()
end)
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Mukla Officer Suite")
    GameTooltip:AddLine("Click to open the dashboard", 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
minimapButton:SetScript("OnDragStart", function() this:SetScript("OnUpdate", function()
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    x = x / scale - mx
    y = y / scale - my
    MuklaOfficerSuiteDB.minimap.angle = math.deg(math.atan2(y, x))
    PositionMinimapButton()
end) end)
minimapButton:SetScript("OnDragStop", function() this:SetScript("OnUpdate", nil) end)

SLASH_MUKLAOFFICERSUITE1 = "/mos"
SLASH_MUKLAOFFICERSUITE2 = "/mukla"
SlashCmdList["MUKLAOFFICERSUITE"] = function(message)
    local command = string.lower(message or "")
    command = string.gsub(command, "^%s*(.-)%s*$", "%1")
    if command == "scan" then
        if not dashboard:IsVisible() then dashboard:Show() end
        RefreshDashboard()
        Print("Click 'Scan' or 'Scan & Reload' on the dashboard.")
    elseif command == "show" or command == "open" or command == "" then
        ToggleDashboard()
    elseif command == "hide" then
        dashboard:Hide()
    elseif command == "minimap" then
        MuklaOfficerSuiteDB.minimap.hidden = not MuklaOfficerSuiteDB.minimap.hidden
        if MuklaOfficerSuiteDB.minimap.hidden then minimapButton:Hide() else minimapButton:Show() end
    elseif command == "status" then
        Print("Saved members: " .. CountSavedMembers())
    else
        Print("Commands: /mos, /mos status, /mos minimap, /mos hide")
    end
end

MOS:RegisterEvent("VARIABLES_LOADED")
MOS:RegisterEvent("GUILD_ROSTER_UPDATE")
MOS:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        EnsureDatabase()
        PositionMinimapButton()
        if MuklaOfficerSuiteDB.minimap.hidden then minimapButton:Hide() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        local scanMode = MOS.pendingScan
        if MOS.pendingScan and SaveGuildRoster() then
            RefreshDashboard()
            if scanMode == "reload" then
                Print("Roster scanned. Reloading UI to save it to disk...")
                ReloadUI()
            elseif scanMode ~= "quiet" then
                Print("Roster scanned. Members: " .. CountSavedMembers())
            end
        end
    end
end)

Print("v" .. VERSION .. " loaded. Type /mos")
