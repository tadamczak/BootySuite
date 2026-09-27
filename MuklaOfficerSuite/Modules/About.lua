local MOS = MuklaOfficerSuite

MOS.Modules = MOS.Modules or {}
local About = {}
MOS.Modules.About = About

function About.Create(page, version)
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
    versionText:SetText("Version " .. version)
    local author = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    author:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT", 0, -24)
    author:SetText("Created by Bootybaker")
    return {
        Hide = function(self) page:Hide() end,
        Show = function(self) page:Show() end,
    }
end
