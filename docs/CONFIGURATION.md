# ReWork Framework Configuration Examples

## Server Configuration

### Default Server Config

```lua
-- server/init.lua configuration example

-- Database Configuration
local DB_CONFIG = {
    HOST = "127.0.0.1",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework",
    CHARSET = "utf8mb4",
    POOL_SIZE = 5,
    QUERY_TIMEOUT = 30000
}

-- RPC Configuration
local RPC_CONFIG = {
    REQUEST_TIMEOUT = 5000,
    MAX_PAYLOAD_SIZE = 65536,
    BATCH_INTERVAL = 10,
    COMPRESSION_THRESHOLD = 4096
}

-- Security Configuration
local SECURITY_CONFIG = {
    MAX_STRING_LENGTH = 5000,
    MAX_ARRAY_LENGTH = 1000,
    RATE_LIMIT_WINDOW = 1000,
    RATE_LIMIT_REQUESTS = 100,
    ENABLE_SQL_LOG = false
}

-- Framework Initialization
Database:Initialize(DB_CONFIG)

-- Custom RPC Handlers
RPC:On("GetServerTime", function(data, respond)
    respond({ time = os.time() })
end)

RPC:On("GetPlayersOnline", function(data, respond)
    local players = GetPlayers()
    respond({ count = #players, players = players })
end)

-- Plugin Management
PluginManager:RegisterPlugin({
    name = "example-plugin",
    version = "1.0.0",
    initialize = function()
        print("Example plugin initialized")
    end
})
```

## Client Configuration

### TypeScript Configuration

```typescript
// client/init.ts configuration example

import ReWorkFramework from './core/Framework';
import UIManager from './core/UIManager';
import AuthModule from '../../modules/auth/client';

// Framework initialization
const framework = ReWorkFramework.getInstance({
    debug: true,
    logLevel: 'INFO',
    performanceMonitoring: true
});

// UI Manager initialization
const uiManager = UIManager.getInstance({
    autoInitialize: true,
    renderDelay: 16,
    enableLogging: true
});

// Register modules
framework.registerModule('auth', new AuthModule());
framework.registerModule('database', new DatabaseModule());
framework.registerModule('ui', new UIModule());

// Auto-enable modules on start
async function initializeModules() {
    const modules = ['auth', 'database', 'ui'];
    
    for (const moduleName of modules) {
        const success = await framework.enableModule(moduleName);
        console.log(`Module ${moduleName}: ${success ? 'initialized' : 'failed'}`);
    }
}

// Call on resource start
on('onClientResourceStart', (resourceName: string) => {
    if (resourceName === GetCurrentResourceName()) {
        initializeModules();
    }
});
```

## Database Migrations

### Example Migration File

```lua
-- database/migrations/001_create_users_table.lua

local Migration = {}

function Migration:up(db)
    local createUsersTable = [[
        CREATE TABLE IF NOT EXISTS users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(255) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            role ENUM('admin', 'moderator', 'user') DEFAULT 'user',
            balance DECIMAL(10, 2) DEFAULT 0.00,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_username (username),
            INDEX idx_email (email)
        )
    ]]
    
    db:Query(createUsersTable, {}, function(result)
        if result then
            print("^2[Migration]^7 Users table created")
        else
            print("^1[Migration]^7 Failed to create users table")
        end
    end)
end

function Migration:down(db)
    db:Query("DROP TABLE IF EXISTS users", {}, function()
        print("^2[Migration]^7 Users table dropped")
    end)
end

return Migration
```

### Run Migrations

```lua
-- In server/init.lua
local usersMigration = require("database.migrations.001_create_users_table")

Database:ExecuteMigration("create_users_table", function(db)
    usersMigration:up(db)
end)
```

## Module Examples

### Custom Server Module

```lua
-- modules/economy/server.lua

local EconomyModule = {}
EconomyModule.__index = EconomyModule

function EconomyModule:new()
    return setmetatable({}, EconomyModule)
end

function EconomyModule:Initialize()
    print("^2[Economy Module]^7 Initializing economy system")
    
    local RPC = _G.ReWorkRPC
    local Database = _G.ReWorkDB
    
    -- Add money handler
    RPC:On("AddMoney", function(data, respond)
        Database:Update("users",
            { balance = "balance + " .. data.amount },
            { id = data.userId },
            function(result)
                respond({ success = true, newBalance = result.data[1].balance })
            end
        )
    end)
    
    -- Get balance handler
    RPC:On("GetBalance", function(data, respond)
        Database:Select("users", { id = data.userId }, {}, function(result)
            if result and result.data then
                respond({ success = true, balance = result.data[1].balance })
            else
                respond({ success = false, error = "User not found" })
            end
        end)
    end)
    
    return true
end

function EconomyModule:Cleanup()
    print("^2[Economy Module]^7 Cleaning up economy system")
end

return EconomyModule
```

### Custom Client Module

```typescript
// modules/economy/client.ts

import { ModuleInterface } from '@/core/Framework';

class EconomyModule implements ModuleInterface {
    name = 'economy';
    enabled = false;
    private balance: number = 0;

    async initialize(): Promise<void> {
        const framework = window.ReWork;
        
        // Listen for balance updates
        framework.rpcOn('balance:update', (data) => {
            this.balance = data.balance;
            framework.emit('economy:balanceUpdated', data.balance);
        });

        // Get initial balance
        try {
            const response = await framework.rpcCall('GetBalance', {});
            if (response.success) {
                this.balance = response.balance;
            }
        } catch (error) {
            console.error('Failed to get balance:', error);
        }
    }

    async cleanup(): Promise<void> {
        this.balance = 0;
    }

    public async addMoney(amount: number): Promise<boolean> {
        const framework = window.ReWork;
        
        try {
            const response = await framework.rpcCall('AddMoney', { amount });
            if (response.success) {
                this.balance = response.newBalance;
                framework.emit('economy:moneyAdded', amount);
                return true;
            }
        } catch (error) {
            console.error('Failed to add money:', error);
        }
        
        return false;
    }

    public getBalance(): number {
        return this.balance;
    }
}

export default EconomyModule;
```

## Plugin Examples

### Simple Plugin

```lua
-- plugins/notification-plugin.lua

local NotificationPlugin = {
    name = "notifications",
    version = "1.0.0",
    author = "ReWork",
    description = "In-game notification system",
    dependencies = {},
    
    initialize = function()
        print("^2[Notifications Plugin]^7 Initializing...")
        
        local RPC = _G.ReWorkRPC
        
        RPC:On("ShowNotification", function(data, respond)
            -- Send notification to client
            TriggerClientEvent("notify:show", -1, data.message, data.type)
            respond({ success = true })
        end)
    end,
    
    shutdown = function()
        print("^2[Notifications Plugin]^7 Shutting down...")
    end,
    
    hooks = {
        ["player:joined"] = {
            function(playerId)
                TriggerClientEvent("notify:show", playerId, 
                    "Welcome to the server!", "success")
            end
        }
    }
}

return NotificationPlugin
```

## Performance Optimization

### Batch RPC Calls

```lua
-- Example: Send multiple updates in batch
local batch = {
    { event = "player:update", data = { id = 1, level = 50 } },
    { event = "player:update", data = { id = 2, level = 45 } },
    { event = "player:update", data = { id = 3, level = 40 } }
}

for _, event in ipairs(batch) do
    RPC:QueueEvent(-1, event.event, event.data)
end

RPC:FlushEventBatch()
```

### Query Optimization

```lua
-- Bad: Multiple queries
Database:Select("users", { role = "admin" }, {}, function(result) end)
Database:Select("users", { role = "moderator" }, {}, function(result) end)

-- Good: Single query with condition
Database:Select("users", 
    { role = "admin" },
    { orderBy = "username ASC", limit = 100 },
    function(result)
        -- Process all results at once
    end
)
```

## Security Configuration

### Input Validation Schema

```lua
local userSchema = {
    username = {
        type = "string",
        maxLength = 50,
        required = true,
        validate = function(val)
            if string.len(val) < 3 then
                return false, "Username must be at least 3 characters"
            end
            if string.find(val, "[^%w_%-]") then
                return false, "Username contains invalid characters"
            end
            return true
        end
    },
    email = {
        type = "string",
        required = true,
        validate = function(val)
            return Security:ValidateEmail(val), "Invalid email format"
        end
    },
    password = {
        type = "string",
        maxLength = 255,
        required = true,
        validate = function(val)
            if string.len(val) < 8 then
                return false, "Password must be at least 8 characters"
            end
            return true
        end
    }
}
```

---

**Configuration examples și best practices pentru ReWork Framework**
