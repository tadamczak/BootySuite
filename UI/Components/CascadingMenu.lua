local UI = MuklaOfficerSuite.UI.Components
local serial = 0
local DEPTH_LIMIT, ROW_HEIGHT, GAP = 4, 20, 2
local ICON_PATH = "Interface\\AddOns\\MuklaOfficerSuite\\Assets\\Skins\\Classic\\Icons\\"

local function SetRowText(row, text) row.label:SetText(text) end
local function GetRowText(row) return row.label:GetText() end

-- Presentation data only: text, enabled, children, action/data, checked,
-- optional gold icon key and keepOpen. One pooled popup per depth.
function UI.CreateCascadingMenu(onChoose, options)
    options = options or {}
    serial = serial + 1
    local menu = {panels = {}, onChoose = onChoose}
    local fontSize = options.fontSize or 11
    local function ClearAfter(depth)
        for index = table.getn(menu.panels), depth + 1, -1 do
            local panel = menu.panels[index]
            if panel.entries or panel:IsShown() then
                panel:Hide(); panel.entries, panel.parentRow = nil, nil
                for _, row in ipairs(panel.options) do row.entry = nil; row:Hide() end
            end
        end
    end
    function menu:Close()
        if self.closing then return end
        self.closing = true; ClearAfter(0)
        if self.panels[1] then self.panels[1].dismiss:Hide() end
        if UI.openDropdownPanel == self.panels[1] then UI.openDropdownPanel = nil end
        self.anchor = nil; self.closing = false
    end
    local function Click()
        local row = this.menuRow or this
        if not row.entry or row.entry.enabled == false then return end
        if row.entry.children then menu:OpenBranch(row); return end
        local action, data, keepOpen = row.entry.action, row.entry.data, row.entry.keepOpen
        if not keepOpen then menu:Close() end
        if action then menu.onChoose(action, data) end
        if keepOpen then menu:RefreshVisible() end
    end
    local function Enter()
        local row = this.menuRow or this
        if not row.entry or row.entry.enabled == false then return end
        if row.entry.children then menu:OpenBranch(row) else ClearAfter(row.menuDepth) end
    end
    local function EnsurePanel(depth)
        local panel = menu.panels[depth]
        if panel then return panel end
        panel = UI.CreateDropdownPanel(UIParent, UIParent, 110, 32, 100)
        panel:SetFrameStrata("FULLSCREEN_DIALOG"); panel:SetFrameLevel(201 + depth * 5)
        if options.backgroundTexture then
            panel.art = UI.CreateAspectImage(panel, options.backgroundTexture, options.backgroundAspect or 1,
                options.backgroundAlpha or 0.16, options.backgroundUVBottom or 1)
        else panel.art = UI.CreatePerformanceBackground(panel, 0.12) end
        panel.host = UI.CreateContainer(nil, panel)
        panel.canvas = UI.CreateResponsiveCanvas(panel.host, "MOSQuickMenuCanvas" .. serial .. "Depth" .. depth)
        panel:SetScript("OnShow", function() end)
        panel:SetScript("OnHide", function()
            if depth == 1 then menu:Close() else ClearAfter(depth) end
        end)
        panel.dismiss:SetFrameStrata("FULLSCREEN_DIALOG"); panel.dismiss:SetFrameLevel(200)
        panel.dismiss:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        panel.dismiss:SetScript("OnClick", function() menu:Close() end)
        table.insert(menu.panels, panel)
        return panel
    end
    local function EnsureRow(panel, depth, index)
        local row = panel.options[index]
        if row then return row end
        row = UI.CreateMenuItem(panel.canvas, "", 102, ROW_HEIGHT)
        row.SetText, row.GetText = SetRowText, GetRowText
        row.menuDepth, row.menuIndex = depth, index
        row:SetScript("OnClick", Click); row:SetScript("OnEnter", Enter)
        row.icon = UI.CreateTexture(row, nil, "OVERLAY")
        row.icon:SetWidth(10); row.icon:SetHeight(10)
        row.icon:SetVertexColor(unpack(UI.Theme.colors.goldIcon))
        row.icon:Hide()
        row.arrow = UI.CreateTexture(row, nil, "OVERLAY")
        row.arrow:SetTexture(ICON_PATH .. "chevron_right.tga")
        row.arrow:SetVertexColor(unpack(UI.Theme.colors.goldIcon)); row.arrow:SetWidth(10); row.arrow:SetHeight(10)
        row.arrow:SetPoint("RIGHT", row, "RIGHT", -5, 0)
        row.check = UI.CreateCheckButton(nil, row, "UICheckButtonTemplate")
        row.check:SetWidth(16); row.check:SetHeight(16); row.check:SetPoint("LEFT", row, "LEFT", 3, 0)
        row.check.menuRow = row; row.check:SetScript("OnClick", Click); row.check:SetScript("OnEnter", Enter)
        if row.label.SetWordWrap then row.label:SetWordWrap(true) end
        if row.label.SetNonSpaceWrap then row.label:SetNonSpaceWrap(true) end
        table.insert(panel.options, row)
        return row
    end
    local function Present(row)
        local entry = row.entry
        local text, icon = entry.text or "", entry.icon
        local geometryChanged = row.presentedText ~= text or row.presentedIcon ~= icon
            or row.presentedChecked ~= (entry.checked ~= nil) or row.presentedBranch ~= (entry.children ~= nil)
        if row.presentedText ~= text then row:SetText(text); row.presentedText = text end
        if row.presentedIcon ~= icon then
            if icon then row.icon:SetTexture(ICON_PATH .. icon .. ".tga"); row.icon:Show() else row.icon:Hide() end
            row.presentedIcon = icon
        end
        if row.presentedEnabled ~= (entry.enabled ~= false) then
            local enabled = entry.enabled ~= false
            if enabled then row:Enable(); row.check:Enable() else row:Disable(); row.check:Disable() end
            row.label:SetTextColor(unpack(enabled and UI.TextColors.gold or UI.TextColors.gray))
            row.icon:SetAlpha(enabled and 1 or 0.35); row.arrow:SetAlpha(enabled and 1 or 0.35)
            row.presentedEnabled = enabled
        end
        if entry.checked ~= nil then row.check:SetChecked(entry.checked and 1 or nil); row.check:Show() else row.check:Hide() end
        if entry.children then row.arrow:Show() else row.arrow:Hide() end
        row.presentedChecked, row.presentedBranch = entry.checked ~= nil, entry.children ~= nil
        row.captionLeft = 6 + (entry.checked ~= nil and 18 or 0) + (icon and 14 or 0)
        row.captionRight = entry.children and 20 or 6
        row.icon:ClearAllPoints(); row.icon:SetPoint("LEFT", row, "LEFT", 6 + (entry.checked ~= nil and 18 or 0), 0)
        return geometryChanged
    end
    local function LayoutRows(width, _, panel)
        local y = 0
        for index = 1, table.getn(panel.entries) do
            local row = panel.options[index]
            local label = row.label
            local font, _, flags = label:GetFont(); label:SetFont(font, fontSize, flags)
            local captionWidth = math.max(1, width - row.captionLeft - row.captionRight)
            label:ClearAllPoints(); label:SetPoint("TOPLEFT", row, "TOPLEFT", row.captionLeft, -3)
            label:SetWidth(captionWidth); label:SetHeight(0); label:SetJustifyH("LEFT"); label:SetJustifyV("TOP")
            local measured = UI.MeasureTextHeight(label, captionWidth, true)
            local height = math.max(ROW_HEIGHT, measured + 6)
            label:SetHeight(height - 6)
            row.menuOffset = y
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", panel.canvas, "TOPLEFT", 0, -y)
            row:SetWidth(width); row:SetHeight(height)
            y = y + height + GAP
        end
        panel.contentHeight = math.max(1, y - GAP)
        return panel.contentHeight
    end
    local function LayoutArt(panel, width, height)
        if options.backgroundTexture then
            local aspect = panel.art.mosImageAspect
            local shownWidth, shownHeight = math.min(1, width / (height * aspect)), math.min(1, height * aspect / width)
            local right, bottom = options.backgroundUVRight or 1, options.backgroundUVBottom or 1
            panel.art:ClearAllPoints(); panel.art:SetPoint("CENTER", panel, "CENTER", 0, 0)
            panel.art:SetWidth(width); panel.art:SetHeight(height)
            panel.art:SetTexCoord((1 - shownWidth) * right / 2, (1 + shownWidth) * right / 2,
                (1 - shownHeight) * bottom / 2, (1 + shownHeight) * bottom / 2)
        else UI.LayoutPerformanceBackground(panel.art, panel, width, height) end
    end
    local function LayoutPanel(panel, depth, left, top)
        local count = table.getn(panel.entries)
        local screenWidth, screenHeight = UI.GetFrameSpan(UIParent)
        local width = options.minimumWidth or 110
        for index = 1, count do
            local row, label = panel.options[index], panel.options[index].label
            local font, _, flags = label:GetFont(); label:SetFont(font, fontSize, flags); label:SetWidth(0)
            width = math.max(width, (label:GetStringWidth() + row.captionLeft + row.captionRight + 8) / 2)
        end
        width = math.max(80, math.min(options.maximumWidth or 180, screenWidth - 16, width))
        LayoutRows(width - 8, 0, panel)
        local height = math.max(32, math.min(panel.contentHeight + 8, screenHeight - 16))
        if depth > 1 and left + width > screenWidth - 8 then left = menu.panels[depth - 1].menuLeft - width + 2 end
        left = math.max(8, math.min(screenWidth - width - 8, left))
        top = math.max(height + 8, math.min(screenHeight - 8, top))
        panel.menuLeft, panel.menuTop = left, top
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        panel:SetWidth(width); panel:SetHeight(height)
        panel.host:ClearAllPoints(); panel.host:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
        panel.host:SetWidth(width - 8); panel.host:SetHeight(height - 8)
        UI.LayoutResponsiveCanvas(panel.canvas, LayoutRows, panel, width - 8, height - 8)
        LayoutArt(panel, width, height)
    end
    function menu:RefreshVisible()
        for depth, panel in ipairs(self.panels) do
            if panel:IsShown() and panel.entries then
                local changed = false
                for index = 1, table.getn(panel.entries) do
                    local row = panel.options[index]
                    if Present(row) then changed = true end
                end
                if changed then LayoutPanel(panel, depth, panel.menuLeft, panel.menuTop) end
            end
        end
    end
    UI.RegisterSkinCallback(function()
        for depth, panel in ipairs(menu.panels) do
            if panel:IsShown() and panel.entries then LayoutPanel(panel, depth, panel.menuLeft, panel.menuTop) end
        end
    end)
    function menu:ShowPanel(depth, entries, left, top)
        if depth > DEPTH_LIMIT then return false end
        ClearAfter(depth)
        local panel = EnsurePanel(depth)
        if panel.entries ~= entries then panel.canvas.layoutViewport:SetVerticalScroll(0) end
        panel.entries = entries
        local count = table.getn(entries)
        for index = 1, count do
            local row = EnsureRow(panel, depth, index)
            row.entry = entries[index]; Present(row); row:Show()
        end
        for index = count + 1, table.getn(panel.options) do panel.options[index].entry = nil; panel.options[index]:Hide() end
        LayoutPanel(panel, depth, left, top)
        panel:Show(); panel.dismiss:Hide()
        return true
    end
    function menu:OpenBranch(row)
        if not row.entry or row.entry.enabled == false or not row.entry.children then return false end
        if row.menuDepth >= DEPTH_LIMIT then return false end
        local child = self.panels[row.menuDepth + 1]
        if child and child:IsShown() and child.parentRow == row and child.entries == row.entry.children then return true end
        local parent = self.panels[row.menuDepth]
        local scroll = parent.canvas.layoutViewport:GetVerticalScroll()
        local opened = self:ShowPanel(row.menuDepth + 1, row.entry.children,
            parent.menuLeft + parent:GetWidth() - 2, parent.menuTop - 4 - row.menuOffset + scroll)
        if opened then self.panels[row.menuDepth + 1].parentRow = row end
        return opened
    end
    function menu:IsOpen() return self.panels[1] and self.panels[1]:IsShown() or false end
    function menu:Open(anchor, entries)
        self:Close()
        if UI.openDropdownPanel then UI.openDropdownPanel:Hide() end
        self.anchor = anchor
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale() or 1
        self:ShowPanel(1, entries, x / scale + 8, y / scale)
        local root = self.panels[1]
        UI.openDropdownPanel = root; root.dismiss:Show()
    end
    return menu
end
