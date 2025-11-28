--[[
    Example Authentication Module - Server Side
    Demonstrează cum să se creeze handlers de autentificare pe server
]]

local AuthModule = {}
AuthModule.__index = AuthModule

function AuthModule:new()
    local self = setmetatable({}, AuthModule)
    self.sessionManager = {}
    return self
end

function AuthModule:Initialize()
    print("^2[Auth Module]^7 Initializing server authentication")
    
    -- Setup RPC handlers
    local RPC = _G.ReWorkRPC
    local Security = _G.ReWorkSecurity
    local Database = _G.ReWorkDB
    
    RPC:On("auth:validateCredentials", function(data, respond)
        self:ValidateCredentials(data, respond)
    end)
    
    RPC:On("auth:register", function(data, respond)
        self:RegisterUser(data, respond)
    end)
    
    RPC:On("auth:changePassword", function(data, respond)
        self:ChangePassword(data, respond)
    end)
    
    print("^2[Auth Module]^7 Authentication initialized")
    return true
end

function AuthModule:Cleanup()
    print("^2[Auth Module]^7 Cleaning up authentication")
    self.sessionManager = {}
end

--[[
    Validare credențiale - simulare
    În producție, ar folosi bcrypt sau argon2 pentru hash
]]
function AuthModule:ValidateCredentials(data, respond)
    local Security = _G.ReWorkSecurity
    local Database = _G.ReWorkDB
    
    -- Validare input
    local isValid, error = Security:ValidateInput(data, {
        username = { type = "string", maxLength = 50, required = true },
        password = { type = "string", maxLength = 255, required = true }
    })
    
    if not isValid then
        respond({ success = false, error = error })
        return
    end
    
    -- Query database for user
    Database:Select("users", { username = data.username }, {}, function(result)
        if not result or not result.data or #result.data == 0 then
            respond({ success = false, error = "User not found" })
            return
        end
        
        local user = result.data[1]
        
        -- Verificare password (în producție: bcrypt.compare)
        if user.password_hash == data.password then
            -- Generate session token
            local sessionToken = string.format("%x", os.time()) .. string.format("%x", math.random(1, 1000000))
            
            self.sessionManager[sessionToken] = {
                userId = user.id,
                username = user.username,
                createdAt = os.time()
            }
            
            respond({
                success = true,
                token = sessionToken,
                player = {
                    id = user.id,
                    username = user.username,
                    email = user.email
                }
            })
        else
            respond({ success = false, error = "Invalid password" })
        end
    end)
end

--[[
    Registru utilizator nou
]]
function AuthModule:RegisterUser(data, respond)
    local Security = _G.ReWorkSecurity
    local Database = _G.ReWorkDB
    
    -- Validare input
    local isValid, error = Security:ValidateInput(data, {
        username = { type = "string", maxLength = 50, required = true },
        email = { type = "string", required = true, validate = function(val)
            return Security:ValidateEmail(val)
        end },
        password = { type = "string", maxLength = 255, required = true }
    })
    
    if not isValid then
        respond({ success = false, error = error })
        return
    end
    
    -- Check if user already exists
    Database:Select("users", { username = data.username }, {}, function(result)
        if result and result.data and #result.data > 0 then
            respond({ success = false, error = "Username already taken" })
            return
        end
        
        -- Hash password (simulare - în producție folosiți bcrypt)
        local hashedPassword = string.upper(string.sub(data.password, 1, 20))
        
        -- Insert new user
        Database:Insert("users", {
            username = data.username,
            email = data.email,
            password_hash = hashedPassword
        }, function(insertResult)
            if insertResult and insertResult.insertId then
                respond({
                    success = true,
                    message = "User registered successfully",
                    userId = insertResult.insertId
                })
            else
                respond({ success = false, error = "Registration failed" })
            end
        end)
    end)
end

--[[
    Schimbare parolă
]]
function AuthModule:ChangePassword(data, respond)
    local Security = _G.ReWorkSecurity
    local Database = _G.ReWorkDB
    
    -- Validare input
    local isValid, error = Security:ValidateInput(data, {
        userId = { type = "number", required = true },
        oldPassword = { type = "string", required = true },
        newPassword = { type = "string", maxLength = 255, required = true }
    })
    
    if not isValid then
        respond({ success = false, error = error })
        return
    end
    
    -- Verifica parola veche
    Database:Select("users", { id = data.userId }, {}, function(result)
        if not result or not result.data or #result.data == 0 then
            respond({ success = false, error = "User not found" })
            return
        end
        
        local user = result.data[1]
        
        if user.password_hash ~= data.oldPassword then
            respond({ success = false, error = "Invalid password" })
            return
        end
        
        -- Update cu parola nouă
        local hashedNewPassword = string.upper(string.sub(data.newPassword, 1, 20))
        
        Database:Update("users", 
            { password_hash = hashedNewPassword },
            { id = data.userId },
            function(updateResult)
                if updateResult and updateResult.affectedRows > 0 then
                    respond({ success = true, message = "Password changed successfully" })
                else
                    respond({ success = false, error = "Password change failed" })
                end
            end
        )
    end)
end

return AuthModule
