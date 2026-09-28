local MOS = MuklaOfficerSuite

MOS.ModuleRegistry = MOS.ModuleRegistry or { ordered = {}, byName = {} }
local Registry = MOS.ModuleRegistry

function Registry.Register(name, module)
    if not Registry.byName[name] then table.insert(Registry.ordered, name) end
    Registry.byName[name] = module
end

function Registry.Get(name)
    return Registry.byName[name]
end

function Registry.HideAll()
    local index
    for index = 1, table.getn(Registry.ordered) do
        local module = Registry.byName[Registry.ordered[index]]
        if module and module.Hide then module:Hide() end
    end
end

function Registry.Show(name)
    local module = Registry.Get(name)
    if not module then return false end
    Registry.HideAll()
    if module.Show then module:Show() end
    return true
end

function Registry.Refresh(name)
    local module = Registry.Get(name)
    if module and module.Refresh then module:Refresh() end
end

function Registry.Resize(name)
    local module = Registry.Get(name)
    if module and module.OnResize then module:OnResize() end
end
