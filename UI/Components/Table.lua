local MOS = MuklaOfficerSuite
local UI = MOS.UI.Components

UI.Table = UI.Table or {}
local Table = UI.Table

local function OnHeaderEnter()
    UI.AnchorTooltipRightOfCursor(this)
    GameTooltip:AddLine("Sort by " .. this.baseText)
    GameTooltip:AddLine("Click again to reverse the order", 1, 1, 1)
    GameTooltip:Show()
end

local function OnHeaderLeave() GameTooltip:Hide() end
local function OnHeaderClick() this.headerController.onSort(this.sortKey) end

function Table.CreateHeader(parent, controller, text, x, y, width, key, sortable)
    local button = UI.CreateControl(nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); button:SetWidth(width); button:SetHeight(22)
    button.baseText = text; button.sortKey = key; button.headerController = controller
    button.label = UI.CreateColumnLabel(button, "", "orange")
    button.label:SetAllPoints(button); button.label:SetJustifyH("LEFT"); button.label:SetText(text)
    local highlight = UI.CreateTexture(button, nil, "HIGHLIGHT")
    highlight:SetAllPoints(button); highlight:SetTexture(1, 0.72, 0.12, 0.12)
    button:SetScript("OnEnter", OnHeaderEnter); button:SetScript("OnLeave", OnHeaderLeave)
    if sortable then button:SetScript("OnClick", OnHeaderClick) end
    return button
end

function Table.Create(options)
    local parent, rows = options.parent, {}
    local scroll = UI.CreateScrollFrame(options.name, parent, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", options.x - 4, options.scrollTop)
    scroll:SetWidth(options.width); scroll:SetHeight(options.scrollHeight)
    scroll.refreshCallback = options.refresh
    scroll:SetScript("OnVerticalScroll", options.onScroll)
    UI.RegisterSkinnedScrollBar(getglobal(options.name .. "ScrollBar"))
    local index, columnIndex
    for index = 1, options.rowCount do
        local row = UI.CreateControl(nil, parent)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", options.x, options.rowTop - ((index - 1) * options.rowStep))
        row:SetWidth(options.width - 16); row:SetHeight(options.rowHeight)
        local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 2, right = 2, top = 2, bottom = 2 } }
        row:SetBackdrop(backdrop); row:SetBackdropColor(0, 0, 0, 0); row:SetBackdropBorderColor(0, 0, 0, 0)
        UI.RegisterSkinnedSurface(row, "row", backdrop, { 0, 0, 0, 0 }, { 0, 0, 0, 0 })
        for columnIndex = 1, table.getn(options.columns) do
            local column = options.columns[columnIndex]
            local region
            if column.texture then region = UI.CreateTexture(row, nil, "ARTWORK")
            else region = UI.CreateLabel(row, nil, "OVERLAY", column.font or "GameFontHighlightSmall") end
            region:SetPoint(column.side, row, column.side, column.x, 0); region:SetWidth(column.width)
            if column.height then region:SetHeight(column.height) end
            if not column.texture then region:SetJustifyH(column.side) end
            row[column.key] = region
        end
        if options.bindRow then options.bindRow(row) end
        row:Hide(); rows[index] = row
    end
    scroll:Hide()
    return { scroll = scroll, rows = rows }
end

function UI.CalculateVisibleRows(containerHeight, reservedHeight, rowHeight, rowPoolSize, minimum)
    return math.max(minimum or 3, math.min(rowPoolSize, math.floor((containerHeight - reservedHeight) / rowHeight)))
end

function UI.SetScrollBarVisible(slider, shown)
    if not slider then return end
    local sliderName = slider:GetName()
    local upButton = sliderName and getglobal(sliderName .. "ScrollUpButton")
    local downButton = sliderName and getglobal(sliderName .. "ScrollDownButton")
    if shown then
        slider:Show(); if upButton then upButton:Show() end; if downButton then downButton:Show() end
    else
        slider:Hide(); if upButton then upButton:Hide() end; if downButton then downButton:Hide() end
    end
end

function UI.UpdateScrollFrame(scrollFrame, totalRows, visibleRows, rowHeight)
    local offset = math.max(0, math.min(FauxScrollFrame_GetOffset(scrollFrame) or 0, math.max(0, totalRows - visibleRows)))
    scrollFrame.offset = offset
    FauxScrollFrame_Update(scrollFrame, totalRows, visibleRows, rowHeight)
    local slider = scrollFrame:GetName() and getglobal(scrollFrame:GetName() .. "ScrollBar")
    if slider and slider:GetValue() ~= offset * rowHeight then slider:SetValue(offset * rowHeight) end
    if totalRows > visibleRows then
        scrollFrame:Show()
        UI.SetScrollBarVisible(slider, true)
    else
        scrollFrame:Hide()
        -- In the 1.12 templates the named slider may be parented beside the
        -- logical scroll frame, so hiding only the frame can leave its arrows.
        UI.SetScrollBarVisible(slider, false)
    end
    return offset
end

function UI.ApplyRowBackground(row, absoluteIndex, selected)
    local colors = UI.Theme.colors
    if selected then
        row:SetBackdropColor(colors.rowSelected[1], colors.rowSelected[2], colors.rowSelected[3], colors.rowSelected[4])
        row:SetBackdropBorderColor(colors.rowSelectedBorder[1], colors.rowSelectedBorder[2], colors.rowSelectedBorder[3], colors.rowSelectedBorder[4])
    elseif math.mod(absoluteIndex, 2) == 0 then
        row:SetBackdropColor(colors.rowAlternate[1], colors.rowAlternate[2], colors.rowAlternate[3], colors.rowAlternate[4])
        row:SetBackdropBorderColor(0, 0, 0, 0)
    else
        row:SetBackdropColor(0, 0, 0, 0); row:SetBackdropBorderColor(0, 0, 0, 0)
    end
end
