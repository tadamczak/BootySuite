local MOS = BootySuite

MOS.Modules.VersionCheck = MOS.Modules.VersionCheck or {}
local VersionCheck = MOS.Modules.VersionCheck

local TOPIC = "VERSION"
local QUERY = "QUERY"
local RESPONSE = "RESPONSE"
local QUERY_COOLDOWN = 60
local DOWNLOAD_URL = "https://github.com/tadamczak/BootySuite/releases/latest"

function VersionCheck.Create(options)
    local UI = MOS.UI.Components
    local releaseVersion = options.releaseVersion
    local peerVersion = options.addonVersion or releaseVersion
    local frame = UI.CreateContainer(nil, UIParent)
    local channels = {}
    local lastQueryAt = -QUERY_COOLDOWN
    local shownVersions = {}
    local welcomeShown = false
    local checkDeadline = nil
    local status = "Failed to check for update. Check GitHub for latest version."
    local updateDialog

    local function SetStatus(value, successful)
        status = value
        if successful then
            MOS.Database.Ensure()
            BootySuiteDB.lastSuccessfulVersionCheck = time()
        end
        if options.onStatusChanged then options.onStatusChanged(value, BootySuiteDB and BootySuiteDB.lastSuccessfulVersionCheck) end
    end

    local function ShowUpdate(remoteVersion)
        if not updateDialog then
            updateDialog = UI.CreateTextEditor("BootySuiteUpdateAvailable", "Booty Suite Update Available", 120)
            updateDialog.save:Hide()
            updateDialog.cancel:SetText("Close")
            updateDialog.edit:SetScript("OnTextChanged", nil)
            updateDialog.counter:ClearAllPoints()
            updateDialog.counter:SetPoint("TOPLEFT", updateDialog, "TOPLEFT", 16, -42)
            updateDialog.counter:SetWidth(398)
            updateDialog.counter:SetJustifyH("LEFT")
            updateDialog.counter:SetJustifyV("TOP")
            if UI.WindowStack then UI.WindowStack.SetOwner(updateDialog, options.owner) end
            UI.RegisterEscapeDialog(updateDialog)
        end
        local message = "A newer Booty Suite version is available: " .. remoteVersion .. "\nInstalled version: " .. peerVersion .. "\nDownload it from GitHub Releases."
        updateDialog.counter:SetText(message)
        local messageHeight = math.ceil(UI.MeasureTextHeight(updateDialog.counter, 398))
        updateDialog.counter:SetHeight(messageHeight)
        updateDialog.mosEditorTopInset = 42 + messageHeight + 12
        updateDialog:SetHeight(math.max(250, updateDialog.mosEditorTopInset + 52 + 50))
        updateDialog.scroll:ClearAllPoints()
        updateDialog.scroll:SetPoint("TOPLEFT", updateDialog, "TOPLEFT", 16, -updateDialog.mosEditorTopInset)
        updateDialog.scroll:SetPoint("BOTTOMRIGHT", updateDialog, "BOTTOMRIGHT", -32, 52)
        updateDialog:Open(DOWNLOAD_URL)
        updateDialog:SetMessage(message, false)
        updateDialog.counter:SetTextColor(1, 1, 1)
        updateDialog.edit:HighlightText()
        updateDialog.edit:ClearFocus()
    end

    local function Notify(remoteVersion)
        MOS.Database.Ensure()
        BootySuiteDB.latestKnownVersion = MOS.Services.Version.SelectLatest(BootySuiteDB.latestKnownVersion, remoteVersion)
        SetStatus("New version available!", true)
        if shownVersions[remoteVersion] then return end
        shownVersions[remoteVersion] = true
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Booty Suite:|r New version " .. remoteVersion .. " is available. Installed version: " .. peerVersion .. ".")
        ShowUpdate(remoteVersion)
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
