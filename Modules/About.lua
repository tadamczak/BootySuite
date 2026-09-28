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
    artwork:SetWidth(382)
    artwork:SetHeight(382)
    artwork:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\AboutArtwork")
    artwork:SetTexCoord(0.066, 0.934, 0, 1)
    artwork:SetAlpha(0.88)
    local name = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("CENTER", page, "LEFT", 105, 34)
    name:SetText("Mukla Officer Suite")
    local versionLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -14); versionLabel:SetText("Current version:")
    local versionText = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionText:SetPoint("LEFT", versionLabel, "RIGHT", 8, 0); versionText:SetText(version)
    local statusLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusLabel:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -12); statusLabel:SetText("Update status:")
    local updateStatus = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    updateStatus:SetPoint("LEFT", statusLabel, "RIGHT", 8, 0); updateStatus:SetWidth(310); updateStatus:SetJustifyH("LEFT")
    updateStatus:SetText("Failed to check for update. Check GitHub for latest version.")
    local lastCheckLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lastCheckLabel:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -12); lastCheckLabel:SetText("Last check:")
    local lastCheck = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lastCheck:SetPoint("LEFT", lastCheckLabel, "RIGHT", 8, 0); lastCheck:SetText("Never")
    local checkButton = MOS.UI.CreateButton(page, nil, "Check for updates!", 142, 22)
    checkButton:SetPoint("TOPLEFT", lastCheckLabel, "BOTTOMLEFT", 0, -14)
    checkButton:SetScript("OnClick", function() if options and options.checkVersion then options.checkVersion() end end)
    local author = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    author:SetPoint("BOTTOM", page, "BOTTOM", 0, 28)
    author:SetTextColor(1, 0.82, 0.18)
    author:SetText("Created by Bootybaker")
    local rights = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rights:SetPoint("TOP", author, "BOTTOM", 0, -5); rights:SetText("Mukla Officer Suite™ - All rights reserved.")
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
            updateStatus:SetText(value or "Failed to check for update. Check GitHub for latest version.")
            lastCheck:SetText(FormatLastCheck(timestamp))
        end,
    }
    return module
end
