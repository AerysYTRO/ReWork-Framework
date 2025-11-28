--[[
    ReWork Framework - Server Entry Point
    Inițializează și configurează framework-ul pe server
]]

-- NOTE: Core modules (Framework, RPC, Database, Security, PluginManager)
-- are loaded by fxmanifest.yaml in the correct order BEFORE this file
-- They are available as globals in the current context

-- Verify all modules are loaded
if not Framework then
    error("Framework module not loaded! Check fxmanifest.yaml order")
end
if not RPC then
    error("RPC module not loaded! Check fxmanifest.yaml order")
end
if not Database then
    error("Database module not loaded! Check fxmanifest.yaml order")
end
if not Security then
    error("Security module not loaded! Check fxmanifest.yaml order")
end
if not PluginManager then
    error("PluginManager module not loaded! Check fxmanifest.yaml order")
end

-- Optional: Make them available as shorter globals if preferred
_G.ReWork = Framework
_G.ReWorkRPC = RPC
_G.ReWorkDB = Database
_G.ReWorkSecurity = Security
_G.ReWorkPlugins = PluginManager

--[[
    Configurare bază de date
]]
function InitializeDatabase()
    Database:Initialize({
        HOST = "127.0.0.1",
        USER = "rework",
        PASSWORD = "rework",
        DATABASE = "rework"
    })
    
    -- Exemplu migrație - creare tabel users
    Database:ExecuteMigration("create_users_table", function(db)
        local query = [[
            CREATE TABLE IF NOT EXISTS users (
                id INT PRIMARY KEY AUTO_INCREMENT,
                username VARCHAR(255) UNIQUE NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]]
        db:Query(query, {}, function(result)
            if result then
                print("^2[ReWork]^7 Tabel users creat/verificat")
            end
        end)
    end)
end

--[[
    Setup RPC handlers de bază
]]
function SetupRPCHandlers()
    -- Handler pentru test RPC call din client
    RPC:On("TestRPC", function(data, respond)
        print("^2[ReWork RPC]^7 Test call din client: " .. json.encode(data))
        respond({ success = true, message = "Răspuns din server" })
    end)
    
    -- Handler pentru database query din client
    RPC:On("QueryDatabase", function(data, respond)
        if not data.query then
            respond({ success = false, error = "Query not provided" })
            return
        end
        
        local isValid, validationMsg = ReWorkSecurity:ValidateInput(data, {
            query = { type = "string", maxLength = 1000, required = true }
        })
        
        if not isValid then
            respond({ success = false, error = validationMsg })
            return
        end
        
        ReWorkDB:Query(data.query, data.params or {}, function(result)
            respond({ success = true, data = result })
        end)
    end)
end

--[[
    Inițializare server tick pentru cleanup-uri periodice
]]
function StartServerTick()
    -- FiveM uses SetTimeout for repeating tasks
    local function TickCleanup()
        -- Cleanup expired RPC requests
        RPC:CleanupExpiredRequests()
        
        -- Cleanup old rate limit entries
        ReWorkSecurity:CleanupRateLimits()
        
        -- Schedule next cleanup in 5 seconds
        SetTimeout(5000, TickCleanup)
    end
    
    -- Start the cleanup loop
    SetTimeout(5000, TickCleanup)
end

--[[
    Main initialization
]]
function Initialize()
    print("^2========================================^7")
    print("^2  ReWork Framework v1.0.0 Inițializare^7")
    print("^2========================================^7")
    
    -- Inițializare framework
    if not Framework:Initialize() then
        print("^1[ReWork]^7 Eroare la inițializare framework")
        return false
    end
    
    -- Inițializare bază de date
    InitializeDatabase()
    
    -- Setup RPC handlers
    SetupRPCHandlers()
    
    -- Start server tick
    StartServerTick()
    
    print("^2[ReWork]^7 Inițializare completă!")
    return true
end

-- Apelă inițializare
Initialize()

-- Export pentru alte resurse
return {
    Framework = Framework,
    RPC = RPC,
    Database = Database,
    Security = Security,
    PluginManager = PluginManager
}
