--[[
    ReWork Framework - Core Server Module
    Gestioneaza inițializarea și coordonarea tuturor modulelor framework-ului
    
    Caracteristici:
    - Inițializare modulară a sistemelor
    - Gestionare de événemte global
    - Module manager cu suport pentru activate/deactivate
    - Sistema de logare optimizată
]]

local ReWork = {}
ReWork.__index = ReWork

-- Configurare globală
ReWork.version = "1.0.0"
ReWork.modules = {}
ReWork.events = {}
ReWork.config = {}

-- Logger privat cu suport pentru nivele de severitate
local Logger = {
    levels = {
        DEBUG = 0,
        INFO = 1,
        WARN = 2,
        ERROR = 3
    },
    currentLevel = 1 -- INFO by default
}

-- Funcție de logare optimizată cu evitarea formatării excesive
function Logger:log(level, message, ...)
    if level < self.currentLevel then return end
    
    local timestamp = os.date("%H:%M:%S")
    local levelName = ""
    
    for name, value in pairs(self.levels) do
        if value == level then levelName = name break end
    end
    
    local formattedMsg = message
    if select("#", ...) > 0 then
        formattedMsg = string.format(message, ...)
    end
    
    print(string.format("[ReWork - %s] [%s] %s", timestamp, levelName, formattedMsg))
end

-- Funcții publice ale logger-ului
function Logger:debug(msg, ...) self:log(self.levels.DEBUG, msg, ...) end
function Logger:info(msg, ...) self:log(self.levels.INFO, msg, ...) end
function Logger:warn(msg, ...) self:log(self.levels.WARN, msg, ...) end
function Logger:error(msg, ...) self:log(self.levels.ERROR, msg, ...) end

-- Inițializare framework
function ReWork:Initialize()
    Logger:info("Initializare ReWork Framework v%s", self.version)
    
    -- Inițializare tabele pentru event listeners
    self.eventListeners = {}
    
    Logger:info("Framework inițializat cu succes!")
    return true
end

-- Funcție pentru a registra un modul
function ReWork:RegisterModule(moduleName, moduleClass)
    if self.modules[moduleName] then
        Logger:warn("Modulul '%s' este deja registrat", moduleName)
        return false
    end
    
    self.modules[moduleName] = {
        name = moduleName,
        class = moduleClass,
        instance = nil,
        enabled = false
    }
    
    Logger:info("Modul '%s' registrat", moduleName)
    return true
end

-- Funcție pentru a activa un modul
function ReWork:EnableModule(moduleName)
    if not self.modules[moduleName] then
        Logger:error("Modulul '%s' nu a fost găsit", moduleName)
        return false
    end
    
    local module = self.modules[moduleName]
    
    if module.enabled then
        Logger:warn("Modulul '%s' este deja activ", moduleName)
        return false
    end
    
    -- Instanțiare modul
    module.instance = module.class:new()
    
    -- Apelarea metodei de inițializare dacă există
    if module.instance and type(module.instance.Initialize) == "function" then
        local success = module.instance:Initialize()
        if not success then
            Logger:error("Inițializare eșuată pentru modulul '%s'", moduleName)
            module.instance = nil
            return false
        end
    end
    
    module.enabled = true
    Logger:info("Modul '%s' activat", moduleName)
    return true
end

-- Funcție pentru a dezactiva un modul
function ReWork:DisableModule(moduleName)
    if not self.modules[moduleName] then
        Logger:error("Modulul '%s' nu a fost găsit", moduleName)
        return false
    end
    
    local module = self.modules[moduleName]
    
    if not module.enabled then
        Logger:warn("Modulul '%s' nu este activ", moduleName)
        return false
    end
    
    -- Apelarea metodei de cleanup dacă există
    if module.instance and type(module.instance.Cleanup) == "function" then
        module.instance:Cleanup()
    end
    
    module.instance = nil
    module.enabled = false
    Logger:info("Modul '%s' dezactivat", moduleName)
    return true
end

-- Funcție pentru a obține instanța unui modul
function ReWork:GetModule(moduleName)
    if not self.modules[moduleName] then
        Logger:error("Modulul '%s' nu a fost găsit", moduleName)
        return nil
    end
    
    return self.modules[moduleName].instance
end

-- Sistem de event emitter - o modalitate eficientă de a comunica între module
function ReWork:On(eventName, callback)
    if not self.eventListeners[eventName] then
        self.eventListeners[eventName] = {}
    end
    
    table.insert(self.eventListeners[eventName], callback)
    Logger:debug("Listener adăugat pentru event: %s", eventName)
end

-- Emitere event - optimizată pentru performanță
function ReWork:Emit(eventName, ...)
    if not self.eventListeners[eventName] then return end
    
    for _, callback in ipairs(self.eventListeners[eventName]) do
        pcall(callback, ...)
    end
end

-- Funcție pentru a dezabona de la un event
function ReWork:Off(eventName, callback)
    if not self.eventListeners[eventName] then return end
    
    for i, listener in ipairs(self.eventListeners[eventName]) do
        if listener == callback then
            table.remove(self.eventListeners[eventName], i)
            Logger:debug("Listener șters pentru event: %s", eventName)
            return true
        end
    end
    
    return false
end

-- Funcție pentru a obține status-ul tuturor modulelor
function ReWork:GetModuleStatus()
    local status = {}
    
    for moduleName, module in pairs(self.modules) do
        status[moduleName] = {
            enabled = module.enabled,
            hasInstance = module.instance ~= nil
        }
    end
    
    return status
end

-- Singleton pattern - asigură o singură instanță
if not _G.Framework then
    _G.Framework = ReWork
    ReWork:Initialize()
    Logger:info("ReWork Framework initialized as global")
end

return ReWork
