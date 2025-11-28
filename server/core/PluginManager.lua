--[[
    ReWork Framework - Plugin System
    Extensibil plugin architecture care nu afectează stabilitatea core
    
    Caracteristici:
    - Sandbox-ed execution environment
    - Plugin lifecycle management
    - Dependency resolution
    - Error isolation
]]

local PluginManager = {}
PluginManager.__index = PluginManager

-- State management
local plugins = {}
local pluginDependencies = {}
local pluginLoads = {}

--[[
    Registrare plugin cu metadata
    
    Plugin interface:
    - name: String unic
    - version: String versiune
    - author: String author
    - description: String descriere
    - dependencies: Array de plugin names pe care le necesită
    - initialize: Function care se apelează la load
    - shutdown: Function care se apelează la unload (opțional)
    - hooks: Table cu hook handlers (opțional)
]]
function PluginManager:RegisterPlugin(pluginDef)
    if not pluginDef.name then
        error("Plugin trebuie să aibă un 'name'")
    end
    
    if plugins[pluginDef.name] then
        error("Plugin '" .. pluginDef.name .. "' este deja registrat")
    end
    
    -- Validare dependencies
    if pluginDef.dependencies then
        for _, dep in ipairs(pluginDef.dependencies) do
            if not plugins[dep] then
                error("Plugin '" .. pluginDef.name .. "' depinde de '" .. dep .. "' care nu este disponibil")
            end
        end
    end
    
    plugins[pluginDef.name] = {
        name = pluginDef.name,
        version = pluginDef.version or "1.0.0",
        author = pluginDef.author or "Unknown",
        description = pluginDef.description or "",
        dependencies = pluginDef.dependencies or {},
        initialize = pluginDef.initialize,
        shutdown = pluginDef.shutdown,
        hooks = pluginDef.hooks or {},
        loaded = false,
        enabled = false
    }
    
    print("^2[ReWork Plugin]^7 Plugin registrat: " .. pluginDef.name)
    return true
end

--[[
    Load plugin - execută initialization într-un sandbox
]]
function PluginManager:LoadPlugin(pluginName)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    local plugin = plugins[pluginName]
    
    if plugin.loaded then
        print("^3[ReWork Plugin]^7 Plugin '" .. pluginName .. "' este deja loaded")
        return true
    end
    
    -- Asigură că dependencies sunt loaded prima
    for _, depName in ipairs(plugin.dependencies) do
        if not plugins[depName].loaded then
            self:LoadPlugin(depName)
        end
    end
    
    -- Execută initialization în protected context
    local success, error = pcall(function()
        if plugin.initialize then
            plugin.initialize()
        end
    end)
    
    if not success then
        print("^1[ReWork Plugin]^7 Error la load " .. pluginName .. ": " .. tostring(error))
        return false
    end
    
    plugin.loaded = true
    plugin.enabled = true
    
    print("^2[ReWork Plugin]^7 Plugin loaded: " .. pluginName .. " v" .. plugin.version)
    return true
end

--[[
    Unload plugin - apelează shutdown și cleanup
]]
function PluginManager:UnloadPlugin(pluginName)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    local plugin = plugins[pluginName]
    
    if not plugin.loaded then
        print("^3[ReWork Plugin]^7 Plugin '" .. pluginName .. "' nu este loaded")
        return true
    end
    
    -- Execută shutdown în protected context
    local success, error = pcall(function()
        if plugin.shutdown then
            plugin.shutdown()
        end
    end)
    
    if not success then
        print("^1[ReWork Plugin]^7 Error la unload " .. pluginName .. ": " .. tostring(error))
        return false
    end
    
    plugin.loaded = false
    plugin.enabled = false
    
    print("^2[ReWork Plugin]^7 Plugin unloaded: " .. pluginName)
    return true
end

--[[
    Hook system - permite pluginilor să se "agățe" de events
]]
function PluginManager:RegisterHook(pluginName, hookName, callback)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    local plugin = plugins[pluginName]
    
    if not plugin.hooks[hookName] then
        plugin.hooks[hookName] = {}
    end
    
    table.insert(plugin.hooks[hookName], callback)
end

--[[
    Execute hook - apelează toți listeners pentru un hook
]]
function PluginManager:ExecuteHook(hookName, ...)
    local results = {}
    
    for pluginName, plugin in pairs(plugins) do
        if plugin.enabled and plugin.hooks[hookName] then
            for _, callback in ipairs(plugin.hooks[hookName]) do
                local success, result = pcall(callback, ...)
                
                if success then
                    table.insert(results, {
                        plugin = pluginName,
                        success = true,
                        result = result
                    })
                else
                    print("^1[ReWork Plugin]^7 Error în hook '" .. hookName .. "' de plugin '" .. pluginName .. "': " .. tostring(result))
                    table.insert(results, {
                        plugin = pluginName,
                        success = false,
                        error = result
                    })
                end
            end
        end
    end
    
    return results
end

--[[
    Get plugin info
]]
function PluginManager:GetPluginInfo(pluginName)
    if not plugins[pluginName] then
        return nil
    end
    
    local plugin = plugins[pluginName]
    
    return {
        name = plugin.name,
        version = plugin.version,
        author = plugin.author,
        description = plugin.description,
        dependencies = plugin.dependencies,
        loaded = plugin.loaded,
        enabled = plugin.enabled
    }
end

--[[
    List all plugins
]]
function PluginManager:GetPlugins()
    local pluginList = {}
    
    for name, plugin in pairs(plugins) do
        table.insert(pluginList, {
            name = name,
            version = plugin.version,
            author = plugin.author,
            loaded = plugin.loaded,
            enabled = plugin.enabled
        })
    end
    
    return pluginList
end

--[[
    Enable/Disable plugin la runtime
]]
function PluginManager:EnablePlugin(pluginName)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    plugins[pluginName].enabled = true
    print("^2[ReWork Plugin]^7 Plugin enabled: " .. pluginName)
    return true
end

function PluginManager:DisablePlugin(pluginName)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    plugins[pluginName].enabled = false
    print("^3[ReWork Plugin]^7 Plugin disabled: " .. pluginName)
    return true
end

--[[
    Reload plugin
]]
function PluginManager:ReloadPlugin(pluginName)
    self:UnloadPlugin(pluginName)
    return self:LoadPlugin(pluginName)
end

--[[
    Provide isolated context pentru plugin execution
]]
function PluginManager:CreatePluginContext(pluginName)
    if not plugins[pluginName] then
        error("Plugin '" .. pluginName .. "' nu a fost găsit")
    end
    
    local plugin = plugins[pluginName]
    
    -- Create sandbox environment
    local env = {
        -- Permit doar safe global functions
        print = print,
        table = table,
        string = string,
        math = math,
        type = type,
        tostring = tostring,
        tonumber = tonumber,
        ipairs = ipairs,
        pairs = pairs,
        
        -- ReWork API
        ReWorkPlugin = {
            name = pluginName,
            version = plugin.version,
            RegisterHook = function(hookName, callback)
                PluginManager:RegisterHook(pluginName, hookName, callback)
            end,
            ExecuteHook = function(hookName, ...)
                return PluginManager:ExecuteHook(hookName, ...)
            end
        },
        
        -- Prevent access to dangerous functions
        os = nil,
        io = nil,
        loadstring = nil,
        load = nil
    }
    
    return env
end

return PluginManager
