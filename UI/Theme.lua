local MOS = MuklaOfficerSuite
local UI = MOS.UI

UI.Theme = {
    classColors = {
        WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
        MAGE = { r = 0.41, g = 0.80, b = 0.94 },
        ROGUE = { r = 1, g = 0.96, b = 0.41 },
        DRUID = { r = 1, g = 0.49, b = 0.04 },
        HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
        SHAMAN = { r = 0, g = 0.44, b = 0.87 },
        PRIEST = { r = 1, g = 1, b = 1 },
        WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
        PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    },
    colors = {
        goldText = { 0.82, 0.70, 0.43 },
        button = { 0.08, 0.07, 0.05, 0.96 },
        buttonBorder = { 0.48, 0.38, 0.20, 1 },
        highlight = { 1, 0.72, 0.12, 0.10 },
        rowAlternate = { 1, 0.78, 0.25, 0.075 },
        rowSelected = { 0.16, 0.20, 0.17, 0.82 },
        rowSelectedBorder = { 0.46, 0.55, 0.47, 0.90 },
    },
    sizes = {
        buttonHeight = 22,
        rowHeight = 20,
        contentMargin = 3,
    },
}

function UI.StyleButton(button, text)
    local colors = UI.Theme.colors
    local backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 9,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }
    button:SetBackdrop(backdrop)
    button:SetBackdropColor(colors.button[1], colors.button[2], colors.button[3], colors.button[4])
    button:SetBackdropBorderColor(colors.buttonBorder[1], colors.buttonBorder[2], colors.buttonBorder[3], colors.buttonBorder[4])
    if not button.label then
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.label:SetAllPoints(button)
    end
    button.label:SetText(text or "")
    button.SetText = function(self, value) self.label:SetText(value) end
    if not button.mosHighlight then
        button.mosHighlight = button:CreateTexture(nil, "HIGHLIGHT")
        button.mosHighlight:SetAllPoints(button)
        button.mosHighlight:SetTexture(colors.highlight[1], colors.highlight[2], colors.highlight[3], colors.highlight[4])
    end
    UI.RegisterSkinnedControl(button, backdrop, { colors.button[1], colors.button[2], colors.button[3], colors.button[4] }, { colors.buttonBorder[1], colors.buttonBorder[2], colors.buttonBorder[3], colors.buttonBorder[4] }, { colors.highlight[1], colors.highlight[2], colors.highlight[3], colors.highlight[4] })
    return button
end

function UI.CreateButton(parent, name, text, width, height)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(width or 120)
    button:SetHeight(height or UI.Theme.sizes.buttonHeight)
    return UI.StyleButton(button, text)
end
