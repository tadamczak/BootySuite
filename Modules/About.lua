local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local About = {}
MOS.Modules.About = About

function About.Create(page, version, options)
    local title = MOS.UI.Components.CreateHeading(page, "", 1, "orange")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    title:SetText("About")
    title:Hide()
    local artwork = MOS.UI.Components.CreateTexture(page, nil, "ARTWORK")
    artwork:SetPoint("RIGHT", page, "RIGHT", -4, 0)
    artwork:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Textures\\AboutArtwork")
    artwork:SetTexCoord(0.066, 0.934, 0, 1)
    artwork:SetAlpha(0.88)
    local function ResizeArtwork()
        local pageWidth, pageHeight = page:GetWidth() or 840, page:GetHeight() or 400
        local height = math.max(1, math.min(382, pageHeight - 12, pageWidth * 0.46))
        artwork:SetHeight(height); artwork:SetWidth(height * 0.868)
    end
    page:SetScript("OnSizeChanged", ResizeArtwork)
    ResizeArtwork()
    local name = MOS.UI.Components.CreateHeading(page, "", 1, "orange")
    name:SetPoint("CENTER", page, "LEFT", 105, 34)
    name:SetText("Mukla Officer Suite")
    local versionLabel = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
    versionLabel:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -14); versionLabel:SetText("Current version:")
    local versionText = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlight")
    versionText:SetPoint("LEFT", versionLabel, "RIGHT", 8, 0); versionText:SetText(version)
    local statusLabel = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
    statusLabel:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -12); statusLabel:SetText("Update status:")
    local updateStatus = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlight")
    updateStatus:SetPoint("LEFT", statusLabel, "RIGHT", 8, 0); updateStatus:SetWidth(310); updateStatus:SetJustifyH("LEFT")
    updateStatus:SetText("Failed to check for update. Check GitHub for latest version.")
    local lastCheckLabel = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormal")
    lastCheckLabel:SetPoint("TOPLEFT", statusLabel, "BOTTOMLEFT", 0, -12); lastCheckLabel:SetText("Last check:")
    local lastCheck = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlight")
    lastCheck:SetPoint("LEFT", lastCheckLabel, "RIGHT", 8, 0); lastCheck:SetText("Never")
    local checkButton = MOS.UI.Components.CreateButton(page, nil, "Check for updates!", 142, 22)
    checkButton:SetPoint("TOPLEFT", lastCheckLabel, "BOTTOMLEFT", 0, -14)
    checkButton:SetScript("OnClick", function() if options and options.checkVersion then options.checkVersion() end end)
    local author = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontHighlight")
    author:SetPoint("BOTTOM", page, "BOTTOM", 0, 28)
    author:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    author:SetText("Created by Bootybaker")
    local rights = MOS.UI.Components.CreateLabel(page, nil, "OVERLAY", "GameFontNormalSmall")
    rights:SetPoint("TOP", author, "BOTTOM", 0, -5); rights:SetText("Mukla Officer Suite™ - All rights reserved.")
    rights:SetTextColor(unpack(MOS.UI.Components.Theme.colors.goldText))
    local function FormatLastCheck(timestamp)
        if not timestamp then return "Never" end
        return date("%Y-%m-%d %H:%M", timestamp)
    end
    local module = {
        Hide = function(self) page:Hide() end,
        Show = function(self)
            if options and options.getVersionStatus then self:SetUpdateStatus(options.getVersionStatus(), options.getLastSuccessfulCheck and options.getLastSuccessfulCheck()) end
            ResizeArtwork()
            page:Show()
        end,
        SetUpdateStatus = function(self, value, timestamp)
            updateStatus:SetText(value or "Failed to check for update. Check GitHub for latest version.")
            lastCheck:SetText(FormatLastCheck(timestamp))
        end,
    }
    return module
end
