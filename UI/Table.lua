local MOS = MuklaOfficerSuite
local UI = MOS.UI

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
