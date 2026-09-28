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
    local welcomeShown = false
    local checkDeadline = nil
    local status = "Failed to check for update. Check GitHub for latest version."

    local function SetStatus(value, successful)
        status = value
        if successful then
            MOS.Database.Ensure()
            MuklaOfficerSuiteDB.lastSuccessfulVersionCheck = time()
        end
        if options.onStatusChanged then options.onStatusChanged(value, MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.lastSuccessfulVersionCheck) end
    end

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
        SetStatus("New version available!", true)
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
        if table.getn(channels) > 0 then
            SetStatus("Checking online MOS users for newer releases...")
            checkDeadline = now + 5
            frame:SetScript("OnUpdate", function()
                if checkDeadline and GetTime() >= checkDeadline then
                    checkDeadline = nil
                    this:SetScript("OnUpdate", nil)
                    if status ~= "New version available!" then SetStatus("Up to date!", true) end
                end
            end)
        else
            SetStatus("Failed to check for update. Check GitHub for latest version.", false)
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
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            HandleMessage(arg1, arg2, arg3)
        elseif event == "PLAYER_ENTERING_WORLD" then
            if not welcomeShown then
                welcomeShown = true
                MOS.Database.Ensure()
                if not MuklaOfficerSuiteDB.suppressLoginMessage then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Mukla Officer Suite " .. options.addonVersion .. " loaded.|r Type |cffffffff/mos|r to open the addon.")
                end
            end
            SendQuery(false)
        end
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
        GetStatus = function() return status end,
        GetLastSuccessfulCheck = function() return MuklaOfficerSuiteDB and MuklaOfficerSuiteDB.lastSuccessfulVersionCheck end,
        HandleMessage = HandleMessage,
        frame = frame,
    }
end
