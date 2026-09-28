local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local About = {}
MOS.Modules.About = About

function About.Create(page, version, options)
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    title:SetText("About")
    title:Hide()
    local artwork = page:CreateTexture(nil, "ARTWORK")
    artwork:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, -4)
    artwork:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 4)
    artwork:SetWidth(382)
    artwork:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\AboutArtwork")
    artwork:SetTexCoord(0.066, 0.934, 0, 1)
    artwork:SetAlpha(0.88)
    local name = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("CENTER", page, "LEFT", 105, 34)
    name:SetText("Mukla Officer Suite")
    local versionText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionText:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -12)
    versionText:SetText("Current version: " .. version)
    local updateStatus = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    updateStatus:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT", 0, -12)
    updateStatus:SetWidth(280)
    updateStatus:SetJustifyH("LEFT")
    updateStatus:SetText("Update status: Failed to check for update. Check GitHub for latest version.")
    local lastCheck = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lastCheck:SetPoint("TOPLEFT", updateStatus, "BOTTOMLEFT", 0, -8)
    lastCheck:SetWidth(280); lastCheck:SetJustifyH("LEFT"); lastCheck:SetText("Last check: Never")
    local checkButton = MOS.UI.CreateButton(page, nil, "Check for updates!", 142, 22)
    checkButton:SetPoint("TOPLEFT", lastCheck, "BOTTOMLEFT", 0, -12)
    checkButton:SetScript("OnClick", function() if options and options.checkVersion then options.checkVersion() end end)
    local author = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    author:SetPoint("TOPLEFT", checkButton, "BOTTOMLEFT", 0, -24)
    author:SetText("Created by Bootybaker")
    local function FormatLastCheck(timestamp)
        if not timestamp then return "Never" end
        return date("%Y-%m-%d %H:%M", timestamp)
    end
    local module = {
        Hide = function(self) page:Hide() end,
        Show = function(self)
            if options and options.getVersionStatus then self:SetUpdateStatus(options.getVersionStatus(), options.getLastSuccessfulCheck and options.getLastSuccessfulCheck()) end
            page:Show()
        end,
        SetUpdateStatus = function(self, value, timestamp)
            updateStatus:SetText("Update status: " .. (value or "Failed to check for update. Check GitHub for latest version."))
            lastCheck:SetText("Last check: " .. FormatLastCheck(timestamp))
        end,
    }
    return module
end
