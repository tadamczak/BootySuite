local MOS = BootySuite

MOS.Modules.VersionCheck = MOS.Modules.VersionCheck or {}
local VersionCheck = MOS.Modules.VersionCheck

local TOPIC = "VERSION"
local QUERY = "QUERY"
local RESPONSE = "RESPONSE"
local QUERY_COOLDOWN = 60
local DOWNLOAD_URL = "https://github.com/tadamczak/BootySuite/releases/latest"

function VersionCheck.Create(options)
    local releaseVersion = options.releaseVersion
    local peerVersion = options.addonVersion or releaseVersion
    local frame = MOS.UI.Components.CreateContainer(nil, UIParent)
    local channels = {}
    local lastQueryAt = -QUERY_COOLDOWN
    local shownVersions = {}
    local welcomeShown = false
    local checkDeadline = nil
    local status = "Failed to check for update. Check GitHub for latest version."

    local function SetStatus(value, successful)
        status = value
        if successful then
            MOS.Database.Ensure()
            BootySuiteDB.lastSuccessfulVersionCheck = time()
        end
        if options.onStatusChanged then options.onStatusChanged(value, BootySuiteDB and BootySuiteDB.lastSuccessfulVersionCheck) end
    end

    StaticPopupDialogs["MUKLA_OFFICER_SUITE_UPDATE_AVAILABLE"] = {
        text = "A newer Booty Suite version is available: %s\nInstalled version: %s\nDownload it from GitHub Releases.",
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
        MOS.Database.Ensure()
        BootySuiteDB.latestKnownVersion = MOS.Services.Version.SelectLatest(BootySuiteDB.latestKnownVersion, remoteVersion)
        SetStatus("New version available!", true)
        if shownVersions[remoteVersion] then return end
        shownVersions[remoteVersion] = true
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Booty Suite:|r New version " .. remoteVersion .. " is available. Installed version: " .. peerVersion .. ".")
        StaticPopup_Show("MUKLA_OFFICER_SUITE_UPDATE_AVAILABLE", remoteVersion, peerVersion)
    end

    local function SendQuery(force)
        local now = GetTime()
        if not force and now - lastQueryAt < QUERY_COOLDOWN then return 0 end
        lastQueryAt = now
        MOS.Services.AddonMessage.GetAvailableChannels(channels)
        local index
        for index = 1, table.getn(channels) do
            MOS.Services.AddonMessage.Send(TOPIC, QUERY, peerVersion, channels[index])
        end
        if table.getn(channels) > 0 then
            SetStatus("Checking...", false)
            checkDeadline = now + 5
            frame:SetScript("OnUpdate", function()
                if checkDeadline and GetTime() >= checkDeadline then
                    checkDeadline = nil
                    this:SetScript("OnUpdate", nil)
                    if MOS.Services.Version.IsNewer(BootySuiteDB and BootySuiteDB.latestKnownVersion, peerVersion) then
                        SetStatus("New version available!", false)
                    elseif status ~= "New version available!" then SetStatus("Up to date!", true) end
                end
            end)
        else
            checkDeadline = nil; frame:SetScript("OnUpdate", nil)
            if MOS.Services.Version.IsNewer(BootySuiteDB and BootySuiteDB.latestKnownVersion, peerVersion) then
                SetStatus("New version available!", false)
            else SetStatus("Failed to check for update. Check GitHub for latest version.", false) end
        end
        return table.getn(channels)
    end

    local function HandleMessage(prefix, message, channel)
        local topic, action, remoteVersion = MOS.Services.AddonMessage.Decode(prefix, message)
        if topic ~= TOPIC or not MOS.Services.Version.Parse(remoteVersion) then return end
        if action == QUERY and MOS.Services.Version.IsNewer(peerVersion, remoteVersion) then
            MOS.Services.AddonMessage.Send(TOPIC, RESPONSE, peerVersion, channel)
        elseif action == RESPONSE and MOS.Services.Version.IsNewer(remoteVersion, peerVersion) then
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
                if not MOS.GetSetting("suppressLoginMessage") then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Booty Suite " .. options.addonVersion .. " loaded.|r Type |cffffffff/mos|r to open the addon.")
                end
            end
            SendQuery(false)
        end
    end)

    return {
        CheckNow = function()
            local sent = SendQuery(true)
            if sent > 0 then
                options.printMessage("Checking for newer Booty Suite releases among online guild and group members.")
            else
                options.printMessage("Version check needs an online guild, party, or raid channel.")
            end
            return sent
        end,
        GetLatestKnownVersion = function() return BootySuiteDB and BootySuiteDB.latestKnownVersion end,
        GetStatus = function() return status end,
        GetLastSuccessfulCheck = function() return BootySuiteDB and BootySuiteDB.lastSuccessfulVersionCheck end,
        HandleMessage = HandleMessage,
        frame = frame,
    }
end
