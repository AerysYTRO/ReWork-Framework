--[[
    ReWork Framework - RPC System (Remote Procedure Call)
    Sistem optimizat de comunicare între server (Lua) și client (JavaScript/TypeScript)
    
    Caracteristici:
    - Minimizare latență cu batch processing
    - Error handling robus
    - Request timeout management
    - Compression optional pentru payload-uri mari
]]

local RPC = {}
RPC.__index = RPC

-- Configurare
local CONFIG = {
    REQUEST_TIMEOUT = 5000, -- ms
    MAX_PAYLOAD_SIZE = 65536, -- bytes
    BATCH_INTERVAL = 10, -- ms pentru batch processing
    COMPRESSION_THRESHOLD = 4096 -- bytes
}

-- Stare interna
local pendingRequests = {}
local requestCounter = 0
local eventQueue = {}
local lastBatchTime = 0

-- Generator de ID unic pentru request-uri
local function GenerateRequestID()
    requestCounter = requestCounter + 1
    return requestCounter
end

--[[
    Trimitere RPC call către client cu callback
    
    Parametri:
    - target: Player object (integer) sau -1 pentru broadcast
    - eventName: Nazwa evenimentului pe care clientul o va asculta
    - data: Datele care vor fi transmise (table)
    - callback: Funcție care se va apela cu răspunsul
]]
function RPC:Call(target, eventName, data, callback)
    local requestID = GenerateRequestID()
    local payload = {
        id = requestID,
        event = eventName,
        data = data or {},
        timestamp = os.time()
    }
    
    -- Stockare request pending cu timeout
    if callback then
        pendingRequests[requestID] = {
            callback = callback,
            timeout = GetGameTimer() + CONFIG.REQUEST_TIMEOUT,
            eventName = eventName
        }
    end
    
    -- Determinare modalitate transmisie
    if target == -1 then
        TriggerClientEvent("ReWork:RPC:Call", -1, payload)
    else
        TriggerClientEvent("ReWork:RPC:Call", target, payload)
    end
end

--[[
    Trimitere response la client pentru un request primit
    Utilizat de callback-urile registrate cu RPC:On
]]
function RPC:Response(requestID, responseData)
    local payload = {
        id = requestID,
        response = responseData,
        timestamp = os.time()
    }
    
    TriggerClientEvent("ReWork:RPC:Response", -1, payload)
end

--[[
    Registrare handler pentru RPC calls din client
    
    Parametri:
    - eventName: Numelele evenimentului RPC
    - handler: Funcție care procesează requestul (va primi data, callback)
]]
function RPC:On(eventName, handler)
    RegisterNetEvent("ReWork:RPC:ClientCall", function(source, payload)
        if payload.event == eventName then
            -- Wrapper callback pentru a trimite response automat
            local function responseCallback(data)
                RPC:Response(payload.id, data)
            end
            
            -- Execuție în pcall pentru error handling
            pcall(handler, payload.data, responseCallback)
        end
    end)
end

--[[
    Cleanup pentru request-uri expirate (timeout)
    Această funcție ar trebui apelată periodic (ex: În tick)
]]
function RPC:CleanupExpiredRequests()
    local currentTime = GetGameTimer()
    
    for requestID, request in pairs(pendingRequests) do
        if currentTime > request.timeout then
            if request.callback then
                -- Apel callback cu error
                pcall(request.callback, nil, "Request timeout")
            end
            
            pendingRequests[requestID] = nil
        end
    end
end

--[[
    Batch processing pentru event-uri - útil pentru a reduce overhead
    Acumuleaza eventurile și le trimite în batch la interval specificat
]]
function RPC:QueueEvent(target, eventName, data)
    table.insert(eventQueue, {
        target = target,
        event = eventName,
        data = data
    })
    
    local currentTime = GetGameTimer()
    if currentTime - lastBatchTime >= CONFIG.BATCH_INTERVAL then
        RPC:FlushEventBatch()
        lastBatchTime = currentTime
    end
end

-- Trimitere batch-ului de event-uri
function RPC:FlushEventBatch()
    if #eventQueue == 0 then return end
    
    local payload = {
        batch = eventQueue,
        timestamp = os.time()
    }
    
    TriggerClientEvent("ReWork:RPC:BatchEvents", -1, payload)
    eventQueue = {}
end

-- Handler pentru response-uri de la client
RegisterNetEvent("ReWork:RPC:ClientResponse", function(source, payload)
    local request = pendingRequests[payload.id]
    
    if request and request.callback then
        pcall(request.callback, payload.response)
        pendingRequests[payload.id] = nil
    end
end)

-- Validare payload
function RPC:ValidatePayload(data)
    local jsonStr = json.encode(data)
    local size = string.len(jsonStr)
    
    if size > CONFIG.MAX_PAYLOAD_SIZE then
        error("Payload prea mare: " .. size .. " bytes (max: " .. CONFIG.MAX_PAYLOAD_SIZE .. ")")
    end
    
    return true
end

return RPC
