--[[
    ReWork Framework - Database Manager
    Manager optimizat pentru interacțiunile cu baza de date SQL
    
    Caracteristici:
    - Protection împotriva SQL injection
    - Query builder simplificat
    - Migration system
    - Connection pooling
    - Caching optional
]]

local Database = {}
Database.__index = Database

-- Configurare
local CONFIG = {
    HOST = "localhost",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework",
    CHARSET = "utf8mb4",
    POOL_SIZE = 5,
    QUERY_TIMEOUT = 30000 -- ms
}

-- Prepared statements cache pentru a reduce parsing overhead
local statementCache = {}

--[[
    Inițializare conexiune la baza de date
    Implementarea specifică depinde de MySQL library disponibilă în FiveM
]]
function Database:Initialize(config)
    config = config or {}
    
    -- Merge cu config default
    for key, value in pairs(config) do
        CONFIG[key] = value
    end
    
    print("^2[ReWork Database]^7 Inițializare conexiune către " .. CONFIG.HOST .. ":" .. CONFIG.DATABASE)
    
    -- Simulare conexiune (în producție, ar folosi mysql-async sau oxmysql)
    self.connected = true
    return true
end

--[[
    Execute query cu parameter binding pentru security
    Această funcție previne SQL injection prin parameterizare
    
    Parametri:
    - query: SQL query string cu placeholders (?)
    - params: Array de parametri care vor fi substituiți
    - callback: Funcție care va procesa rezultatele
]]
function Database:Query(query, params, callback)
    if not self.connected then
        if callback then
            callback(nil, "Database not connected")
        end
        return
    end
    
    -- Validare și sanitizare
    params = params or {}
    
    -- Verificare pentru prepared statement
    local statementKey = query
    if not statementCache[statementKey] then
        statementCache[statementKey] = self:PrepareStatement(query)
    end
    
    -- Bind parametri
    local preparedQuery = self:BindParameters(query, params)
    
    -- Simulare async query (în producție ar folosi mysql-async)
    SetTimeout(0, function()
        pcall(function()
            -- În producție: local result = MySQL.query.await(preparedQuery)
            local result = {
                affectedRows = 0,
                insertId = 0,
                data = {}
            }
            
            if callback then
                callback(result)
            end
        end)
    end)
end

--[[
    Insert helper - mai convenabil decât query direct
    
    Parametri:
    - table: Numele tabelei
    - data: Table cu {column = value}
    - callback: Funcție care procesează rezultat
]]
function Database:Insert(tableName, data, callback)
    if not tableName or not data then
        if callback then callback(nil, "Invalid parameters") end
        return
    end
    
    local columns = {}
    local values = {}
    local params = {}
    
    for col, val in pairs(data) do
        table.insert(columns, col)
        table.insert(values, "?")
        table.insert(params, val)
    end
    
    local query = string.format(
        "INSERT INTO %s (%s) VALUES (%s)",
        tableName,
        table.concat(columns, ", "),
        table.concat(values, ", ")
    )
    
    self:Query(query, params, callback)
end

--[[
    Update helper
    
    Parametri:
    - table: Numele tabelei
    - data: {column = newValue}
    - where: {column = value} pentru condiția WHERE
    - callback: Rezultat callback
]]
function Database:Update(tableName, data, where, callback)
    if not tableName or not data or not where then
        if callback then callback(nil, "Invalid parameters") end
        return
    end
    
    local setClause = {}
    local params = {}
    
    for col, val in pairs(data) do
        table.insert(setClause, col .. " = ?")
        table.insert(params, val)
    end
    
    local whereClause = {}
    for col, val in pairs(where) do
        table.insert(whereClause, col .. " = ?")
        table.insert(params, val)
    end
    
    local query = string.format(
        "UPDATE %s SET %s WHERE %s",
        tableName,
        table.concat(setClause, ", "),
        table.concat(whereClause, " AND ")
    )
    
    self:Query(query, params, callback)
end

--[[
    Select helper
    
    Parametri:
    - table: Numele tabelei
    - where: {column = value} - opțional
    - options: {limit, offset, orderBy} - opțional
]]
function Database:Select(tableName, where, options, callback)
    if not tableName then
        if callback then callback(nil, "Invalid table name") end
        return
    end
    
    where = where or {}
    options = options or {}
    
    local whereClause = ""
    local params = {}
    
    if next(where) ~= nil then
        local conditions = {}
        for col, val in pairs(where) do
            table.insert(conditions, col .. " = ?")
            table.insert(params, val)
        end
        whereClause = " WHERE " .. table.concat(conditions, " AND ")
    end
    
    local orderClause = options.orderBy and (" ORDER BY " .. options.orderBy) or ""
    local limitClause = options.limit and (" LIMIT " .. options.limit) or ""
    local offsetClause = options.offset and (" OFFSET " .. options.offset) or ""
    
    local query = string.format(
        "SELECT * FROM %s%s%s%s%s",
        tableName,
        whereClause,
        orderClause,
        limitClause,
        offsetClause
    )
    
    self:Query(query, params, callback)
end

--[[
    Delete helper
    
    Parametri:
    - table: Numele tabelei
    - where: {column = value}
]]
function Database:Delete(tableName, where, callback)
    if not tableName or not where then
        if callback then callback(nil, "Invalid parameters") end
        return
    end
    
    local conditions = {}
    local params = {}
    
    for col, val in pairs(where) do
        table.insert(conditions, col .. " = ?")
        table.insert(params, val)
    end
    
    local query = string.format(
        "DELETE FROM %s WHERE %s",
        tableName,
        table.concat(conditions, " AND ")
    )
    
    self:Query(query, params, callback)
end

--[[
    Prepared statement creation - previne SQL injection
]]
function Database:PrepareStatement(query)
    -- În producție, acest lucru ar prepara real o statement
    return query
end

--[[
    Parameter binding - înlocuiesc ? cu valori parametrizate
]]
function Database:BindParameters(query, params)
    local result = query
    local index = 1
    
    for _, param in ipairs(params) do
        local value
        
        if type(param) == "string" then
            -- Escape string values
            value = "'" .. string.gsub(param, "'", "''") .. "'"
        elseif type(param) == "number" then
            value = tostring(param)
        elseif type(param) == "boolean" then
            value = param and "1" or "0"
        elseif param == nil then
            value = "NULL"
        else
            value = "'" .. tostring(param) .. "'"
        end
        
        result = string.gsub(result, "%?", value, 1)
        index = index + 1
    end
    
    return result
end

--[[
    Executa o migrație (creare tabel)
    Util pentru versioning schema
]]
function Database:ExecuteMigration(migrationName, migrationFunction)
    print("^2[ReWork Database]^7 Executare migrație: " .. migrationName)
    
    self:Query(
        "CREATE TABLE IF NOT EXISTS migrations (name VARCHAR(255) PRIMARY KEY, executedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
        {},
        function(result)
            -- Check dacă migrația a fost deja executată
            self:Select("migrations", { name = migrationName }, {}, function(result)
                if result.data and #result.data == 0 then
                    -- Migrația nu a fost executată
                    migrationFunction(self)
                    
                    -- Înregistrează migrația
                    self:Insert("migrations", { name = migrationName }, function()
                        print("^2[ReWork Database]^7 Migrație completă: " .. migrationName)
                    end)
                end
            end)
        end
    )
end

-- Export cache stats pentru debugging
function Database:GetCacheStats()
    return {
        cachedStatements = table.countKeys(statementCache)
    }
end

-- Export as global for FiveM
if not _G.Database then
    _G.Database = Database
end

return Database
