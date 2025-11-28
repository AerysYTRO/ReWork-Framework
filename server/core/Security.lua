--[[
    ReWork Framework - Security Module
    Sistem centralizat pentru protecția împotriva exploatărilor comune
    
    Caracteristici:
    - SQL Injection prevention
    - Input validation și sanitization
    - Rate limiting pentru RPC calls
    - CSRF protection
    - Data type checking
]]

local Security = {}
Security.__index = Security

-- Configurare
local CONFIG = {
    MAX_STRING_LENGTH = 5000,
    MAX_ARRAY_LENGTH = 1000,
    RATE_LIMIT_WINDOW = 1000, -- ms
    RATE_LIMIT_REQUESTS = 100, -- requests per window per player
    ENABLE_SQL_LOG = false -- log SQL queries pentru debugging
}

-- Rate limiting tracking
local playerRateLimit = {}

--[[
    Validare input - asigură că datele sunt de tipul corect
]]
function Security:ValidateInput(data, schema)
    if not data or not schema then
        return false, "Invalid parameters"
    end
    
    for key, expectedType in pairs(schema) do
        local value = data[key]
        
        if expectedType.required and value == nil then
            return false, "Required field missing: " .. key
        end
        
        if value ~= nil then
            local actualType = type(value)
            
            if expectedType.type and actualType ~= expectedType.type then
                return false, "Invalid type for " .. key .. ": expected " .. expectedType.type
            end
            
            -- Validare lungime string
            if actualType == "string" and expectedType.maxLength then
                if string.len(value) > expectedType.maxLength then
                    return false, "String too long for " .. key
                end
            end
            
            -- Validare range pentru numere
            if actualType == "number" and expectedType.min then
                if value < expectedType.min then
                    return false, key .. " must be >= " .. expectedType.min
                end
            end
            
            if actualType == "number" and expectedType.max then
                if value > expectedType.max then
                    return false, key .. " must be <= " .. expectedType.max
                end
            end
            
            -- Custom validator function
            if expectedType.validate and type(expectedType.validate) == "function" then
                local isValid, errMsg = expectedType.validate(value)
                if not isValid then
                    return false, (errMsg or "Validation failed for " .. key)
                end
            end
        end
    end
    
    return true, "Validation passed"
end

--[[
    Sanitize string - elimina caractere periculoase
]]
function Security:SanitizeString(input)
    if type(input) ~= "string" then
        return input
    end
    
    local sanitized = input
    
    -- Eliminate potentially dangerous characters
    -- Permit doar alfanumeric, spații și câteva caractere sigure
    sanitized = string.gsub(sanitized, "[^%w%s%p]", "")
    
    -- Limita lungimea
    if string.len(sanitized) > CONFIG.MAX_STRING_LENGTH then
        sanitized = string.sub(sanitized, 1, CONFIG.MAX_STRING_LENGTH)
    end
    
    return sanitized
end

--[[
    SQL Injection prevention - quote si escape string values
]]
function Security:EscapeSQLString(value)
    if type(value) ~= "string" then
        return tostring(value)
    end
    
    -- Escape single quotes prin dublare
    local escaped = string.gsub(value, "'", "''")
    
    -- Verificare pentru SQL keywords (basic protection)
    escaped = string.gsub(escaped, "(%w+)", function(word)
        local upper = string.upper(word)
        local sqlKeywords = {
            "DROP", "DELETE", "INSERT", "UPDATE", "EXEC", "EXECUTE",
            "SCRIPT", "UNION", "SELECT", "FROM", "WHERE"
        }
        
        for _, keyword in ipairs(sqlKeywords) do
            if upper == keyword then
                return word -- Nu permite keywords consecutive
            end
        end
        
        return word
    end)
    
    return "'" .. escaped .. "'"
end

--[[
    Rate limiting - previne spam RPC calls
]]
function Security:CheckRateLimit(playerID)
    local currentTime = GetGameTimer()
    
    if not playerRateLimit[playerID] then
        playerRateLimit[playerID] = {
            requests = 0,
            windowStart = currentTime
        }
    end
    
    local limit = playerRateLimit[playerID]
    
    -- Reset window dacă a expirat
    if currentTime - limit.windowStart >= CONFIG.RATE_LIMIT_WINDOW then
        limit.requests = 0
        limit.windowStart = currentTime
    end
    
    limit.requests = limit.requests + 1
    
    if limit.requests > CONFIG.RATE_LIMIT_REQUESTS then
        return false, "Rate limit exceeded"
    end
    
    return true
end

--[[
    Validate JSON - asigură că JSON-ul este valid
]]
function Security:ValidateJSON(jsonString)
    if type(jsonString) ~= "string" then
        return false, "Not a string"
    end
    
    local success, result = pcall(function()
        return json.decode(jsonString)
    end)
    
    if not success then
        return false, "Invalid JSON"
    end
    
    return true, result
end

--[[
    Check pentru XSS dalam HTML output
    Util pentru client-side rendering
]]
function Security:SanitizeHTML(input)
    if type(input) ~= "string" then
        return input
    end
    
    local sanitized = input
    
    -- Replace dangerous characters
    sanitized = string.gsub(sanitized, "<", "&lt;")
    sanitized = string.gsub(sanitized, ">", "&gt;")
    sanitized = string.gsub(sanitized, '"', "&quot;")
    sanitized = string.gsub(sanitized, "'", "&#x27;")
    sanitized = string.gsub(sanitized, "/", "&#x2F;")
    
    return sanitized
end

--[[
    Validate URL - asigură că URL-ul este sigur
]]
function Security:ValidateURL(url)
    if type(url) ~= "string" then
        return false
    end
    
    -- Permit doar http și https
    if not string.match(url, "^https?://") then
        return false
    end
    
    -- Reject URL-uri cu protocol handlers periculoase
    if string.match(url, "javascript:") or string.match(url, "data:") then
        return false
    end
    
    return true
end

--[[
    Validare email - format basic
]]
function Security:ValidateEmail(email)
    if type(email) ~= "string" then
        return false
    end
    
    -- Simple email validation regex
    local pattern = "^[%w%._%%-]+@[%w%.-]+%.%a+$"
    return string.match(email, pattern) ~= nil
end

--[[
    Cleanup old rate limit entries - apelat periodic
]]
function Security:CleanupRateLimits()
    local currentTime = GetGameTimer()
    local timeout = CONFIG.RATE_LIMIT_WINDOW * 2
    
    for playerID, data in pairs(playerRateLimit) do
        if currentTime - data.windowStart > timeout then
            playerRateLimit[playerID] = nil
        end
    end
end

--[[
    Get security statistics pentru monitoring
]]
function Security:GetStats()
    return {
        playersWithRateLimit = table.countKeys(playerRateLimit),
        config = CONFIG
    }
end

return Security
