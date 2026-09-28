local MOS = MuklaOfficerSuite

MOS.Modules.VersionCheck = MOS.Modules.VersionCheck or {}
local VersionCheck = MOS.Modules.VersionCheck

local TOPIC = "VERSION"
local QUERY = "QUERY"
local RESPONSE = "RESPONSE"
local QUERY_COOLDOWN = 60
local DOWNLOAD_URL = "https://github.com/tadamczak/MuklaOfficerSuite/releases/latest"

function VersionCheck.Create(options)
    local releaseVersion = options.releaseVersion
    local frame = CreateFrame("Frame", nil, UIParent)
    local channels = {}
    local lastQueryAt = -QUERY_COOLDOWN
    local responseTimes = {}
    local shownVersions = {}

    StaticPopupDialogs["MUKLA_OFFICER_SUITE_UPDATE_AVAILABLE"] = {
        text = "A newer Mukla Officer Suite version is available: %s\nInstalled production release: %s\nDownload it from GitHub Releases.",
        button1 = "Close",
        OnAccept = function() StaticPopup_Hide("MUKLA_OFFICER_SUITE_UPDATE_AVAILABLE") end,
        OnShow = function()
            local editBox = getglobal(this:GetName() .. "WideEditBox")
            editBox:SetText(DOWNLOAD_URL)
            editBox:SetWidth(320)
            editBox:HighlightText()
            editBox:ClearFocus()
        end,
        hasEditBox = true,
        hasWideEditBox = true,
        maxLetters = 120,
        timeout = 0,
        whileDead = 1,
        hideOnEscape = 1,
    }

    local function Notify(remoteVersion)
        if shownVersions[remoteVersion] then return end
        shownVersions[remoteVersion] = true
        MOS.Database.Ensure()
        MuklaOfficerSuiteDB.latestKnownVersion = MOS.Services.Version.SelectLatest(MuklaOfficerSuiteDB.latestKnownVersion, remoteVersion)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Mukla Officer Suite:|r New version " .. remoteVersion .. " is available. Installed production release: " .. releaseVersion .. ".")
        StaticPopup_Show("MUKLA_OFFICER_SUITE_UPDATE_AVAILABLE", remoteVersion, releaseVersion)
    end

    local function SendQuery(force)
        local now = GetTime()
        if not force and now - lastQueryAt < QUERY_COOLDOWN then return 0 end
        lastQueryAt = now
        MOS.Services.AddonMessage.GetAvailableChannels(channels)
        local index
        for index = 1, table.getn(channels) do
            MOS.Services.AddonMessage.Send(TOPIC, QUERY, releaseVersion, channels[index])
        end
        return table.getn(channels)
    end

    local function HandleMessage(prefix, message, channel)
        local topic, action, remoteVersion = MOS.Services.AddonMessage.Decode(prefix, message)
        if topic ~= TOPIC or not MOS.Services.Version.Parse(remoteVersion) then return end
        if action == QUERY and MOS.Services.Version.IsNewer(releaseVersion, remoteVersion) then
            local responseKey = tostring(channel) .. ":" .. remoteVersion
            local now = GetTime()
            if not responseTimes[responseKey] or now - responseTimes[responseKey] >= QUERY_COOLDOWN then
                responseTimes[responseKey] = now
                MOS.Services.AddonMessage.Send(TOPIC, RESPONSE, releaseVersion, channel)
            end
        elseif action == RESPONSE and MOS.Services.Version.IsNewer(remoteVersion, releaseVersion) then
            Notify(remoteVersion)
        end
    end

    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then HandleMessage(arg1, arg2, arg3) else SendQuery(false) end
    end)

    return {
        CheckNow = function()
            local sent = SendQuery(true)
            if sent > 0 then
                options.printMessage("Checking for newer Mukla Officer Suite releases among online guild and group members.")
            else
                options.printMessage("Version check needs an online guild, party, or raid channel.")
            end
            return sent
        end,
        GetLatestKnownVersion = function() return MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.latestKnownVersion end,
        HandleMessage = HandleMessage,
        frame = frame,
    }
end
