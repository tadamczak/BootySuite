local UI = MuklaOfficerSuite.UI.Components
local serial = 0
local DEPTH_LIMIT, ROW_HEIGHT, GAP = 4, 26, 2

-- One pooled popup per depth; a single outside catcher owns the whole tree.
-- Entries are presentation data: text, enabled, children, action/data, checked.
function UI.CreateCascadingMenu(onChoose)
    serial = serial + 1
    local menu = {panels = {}, onChoose = onChoose}
    local function ClearAfter(depth)
        for index = table.getn(menu.panels), depth + 1, -1 do
            local panel = menu.panels[index]
            panel:Hide();panel.entries = nil
            for _, row in ipairs(panel.options) do row.entry = nil;row:Hide() end
        end
    end
    function menu:Close()
        if self.closing then return end
        self.closing = true;ClearAfter(0)
        if self.panels[1] then self.panels[1].dismiss:Hide() end
        if UI.openDropdownPanel == self.panels[1] then UI.openDropdownPanel = nil end
        self.anchor = nil;self.closing = false
    end
    local function Click()
        local row = this.menuRow or this
        if not row.entry or row.entry.enabled == false then return end
        if row.entry.children then menu:OpenBranch(row);return end
        local action, data = row.entry.action, row.entry.data
        menu:Close()
        if action then menu.onChoose(action, data) end
    end
    local function Enter()
        local row = this.menuRow or this
        if not row.entry or row.entry.enabled == false then return end
        if row.entry.children then menu:OpenBranch(row) else ClearAfter(row.menuDepth) end
    end
    local function EnsurePanel(depth)
        local panel = menu.panels[depth]
        if panel then return panel end
        panel = UI.CreateDropdownPanel(UIParent, UIParent, 220, 32, 100)
        panel:SetFrameStrata("FULLSCREEN_DIALOG");panel:SetFrameLevel(201 + depth * 5)
        panel.host = UI.CreateContainer(nil, panel)
        panel.canvas = UI.CreateResponsiveCanvas(panel.host, "MOSQuickMenuCanvas" .. serial .. "Depth" .. depth)
        panel:SetScript("OnShow", function() end)
        panel:SetScript("OnHide", function()
            if depth == 1 then menu:Close() else ClearAfter(depth) end
        end)
        panel.dismiss:SetFrameStrata("FULLSCREEN_DIALOG");panel.dismiss:SetFrameLevel(200)
        panel.dismiss:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        panel.dismiss:SetScript("OnClick", function() menu:Close() end)
        table.insert(menu.panels, panel)
        return panel
    end
    local function EnsureRow(panel, depth, index)
        local row = panel.options[index]
        if row then return row end
        row = UI.CreateButton(panel.canvas, nil, "", 212, ROW_HEIGHT)
        UI.StyleActionButton(row);row.mosLabelJustify = "LEFT"
        row.menuDepth, row.menuIndex = depth, index
        row:SetScript("OnClick", Click)
        local hover = row:GetScript("OnEnter")
        row:SetScript("OnEnter", function() if hover then hover() end;Enter() end)
        row.arrow = UI.CreateTexture(row, nil, "OVERLAY")
        row.arrow:SetTexture("Interface\\AddOns\\MuklaOfficerSuite\\Assets\\Skins\\Classic\\Icons\\chevron_right.tga")
        row.arrow:SetVertexColor(unpack(UI.Theme.colors.goldIcon));row.arrow:SetWidth(12);row.arrow:SetHeight(12)
        row.arrow:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.check = UI.CreateCheckButton(nil, row, "UICheckButtonTemplate")
        row.check:SetWidth(20);row.check:SetHeight(20);row.check:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.check.menuRow = row;row.check:SetScript("OnClick", Click);row.check:SetScript("OnEnter", Enter)
        table.insert(panel.options, row)
        return row
    end
    local function LayoutRows(width, _, panel)
        for index = 1, table.getn(panel.entries) do
            local row = panel.options[index]
            local checked = row.entry.checked ~= nil
            local left, right = checked and 28 or 8, row.entry.children and 24 or 8
            row:ClearAllPoints();row:SetPoint("TOPLEFT", panel.canvas, "TOPLEFT", 0, -(index - 1) * (ROW_HEIGHT + GAP))
            row:SetWidth(width);row:SetHeight(ROW_HEIGHT)
            row.label:ClearAllPoints();row.label:SetPoint("LEFT", row, "LEFT", left, 0)
            UI.FitButtonLabel(row, math.max(1, width - left - right));row.label:SetJustifyH("LEFT")
        end
        return panel.contentHeight
    end
    UI.RegisterSkinCallback(function()
        for _, panel in ipairs(menu.panels) do
            if panel:IsShown() and panel.entries then LayoutRows(panel.canvas:GetWidth(), 0, panel) end
        end
    end)
    function menu:ShowPanel(depth, entries, left, top)
        if depth > DEPTH_LIMIT then return false end
        ClearAfter(depth)
        local panel = EnsurePanel(depth)
        if panel.entries ~= entries then panel.canvas.layoutViewport:SetVerticalScroll(0) end
        panel.entries = entries
        local count = table.getn(entries)
        local screenWidth, screenHeight = UI.GetFrameSpan(UIParent)
        local width = 220
        for index = 1, count do
            local entry, row = entries[index], EnsureRow(panel, depth, index)
            row.entry = entry;row:SetText(entry.text or "")
            local font, _, flags = row.label:GetFont();row.label:SetFont(font, 13, flags);row.mosFitFontSize = 13
            row.label:SetWidth(0)
            width = math.max(width, row.label:GetStringWidth() + (entry.checked ~= nil and 44 or 24) + (entry.children and 16 or 0))
            UI.SetButtonEnabled(row, entry.enabled ~= false);UI.SetButtonEnabled(row.check, entry.enabled ~= false)
            if entry.checked ~= nil then row.check:SetChecked(entry.checked and 1 or nil);row.check:Show() else row.check:Hide() end
            if entry.children then row.arrow:SetAlpha(entry.enabled == false and 0.35 or 1);row.arrow:Show() else row.arrow:Hide() end
            row:Show()
        end
        for index = count + 1, table.getn(panel.options) do panel.options[index].entry = nil;panel.options[index]:Hide() end
        panel.contentHeight = math.max(1, count * (ROW_HEIGHT + GAP) - GAP)
        width = math.max(80, math.min(360, screenWidth - 16, width))
        local height = math.max(32, math.min(panel.contentHeight + 8, screenHeight - 16))
        if depth > 1 and left + width > screenWidth - 8 then left = self.panels[depth - 1].menuLeft - width + 2 end
        left = math.max(8, math.min(screenWidth - width - 8, left))
        top = math.max(height + 8, math.min(screenHeight - 8, top))
        panel.menuLeft, panel.menuTop = left, top
        panel:ClearAllPoints();panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        panel:SetWidth(width);panel:SetHeight(height)
        panel.host:ClearAllPoints();panel.host:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
        panel.host:SetWidth(width - 8);panel.host:SetHeight(height - 8)
        UI.LayoutResponsiveCanvas(panel.canvas, LayoutRows, panel, width - 8, height - 8)
        panel:Show();panel.dismiss:Hide()
        return true
    end
    function menu:OpenBranch(row)
        if not row.entry or row.entry.enabled == false or not row.entry.children then return false end
        local parent = self.panels[row.menuDepth]
        local scroll = parent.canvas.layoutViewport:GetVerticalScroll()
        return self:ShowPanel(row.menuDepth + 1, row.entry.children,
            parent.menuLeft + parent:GetWidth() - 2, parent.menuTop - 4 - (row.menuIndex - 1) * (ROW_HEIGHT + GAP) + scroll)
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
        UI.openDropdownPanel = root;root.dismiss:Show()
    end
    return menu
end
