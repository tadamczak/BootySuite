local MOS = MuklaOfficerSuite
MOS.UI = MOS.UI or {}
MOS.UI.Components = MOS.UI.Components or {}
local Components = MOS.UI.Components

-- Native construction is confined to this package. Feature modules compose
-- instances and attach domain callbacks; factories never reach into a module.
function Components.CreateContainer(name, parent, template)
    return CreateFrame("Frame", name, parent, template)
end

function Components.CreateControl(name, parent, template)
    return CreateFrame("Button", name, parent, template)
end

function Components.CreateCheckButton(name, parent, template)
    return CreateFrame("CheckButton", name, parent, template)
end

function Components.CreateScrollFrame(name, parent, template)
    return CreateFrame("ScrollFrame", name, parent, template)
end

function Components.CreateSliderFrame(name, parent, template)
    return CreateFrame("Slider", name, parent, template)
end

function Components.CreateEditField(name, parent, template)
    return CreateFrame("EditBox", name, parent, template)
end

function Components.CreateStatusFrame(name, parent, template)
    return CreateFrame("StatusBar", name, parent, template)
end

function Components.CreateLabel(parent, name, layer, template)
    return parent:CreateFontString(name, layer, template)
end

function Components.CreateTexture(parent, name, layer, template)
    return parent:CreateTexture(name, layer, template)
end
