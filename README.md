# ReWork Framework - FiveM Advanced Modular Framework

## 🎯 Descriere

**ReWork** este un framework FiveM complet, modular și optimizat pentru performanță, conceput pentru a facilita dezvoltarea scripturilor cu arhitectură profesională. Include suport complet pentru Lua (server), TypeScript (client), Vue, React, și SQL cu protecție completă împotriva exploatărilor.

## ✨ Caracteristici Principale

### 🏗️ Arhitectura Modulară
- **Module Manager**: Adaugă sau elimină module dinamice fără a afecta stabilitatea
- **Plugin System**: Extensii cu izolare completă și dependency resolution
- **Event Emitter**: Comunicare eficientă între componente

### 🔒 Securitate Avansată
- **SQL Injection Prevention**: Parameterizare query-uri și escape string values
- **XSS Protection**: Sanitizare HTML output
- **Input Validation**: Schema-based validation cu suport custom validators
- **Rate Limiting**: Protecție împotriva spam RPC calls
- **CSRF Protection**: Token validation pentru operații sensitive

### 📡 Comunicare Optimizată
- **RPC System**: Remote Procedure Calls cu timeout management
- **Batch Processing**: Grup event-uri pentru reducere overhead
- **Request Pooling**: Gestionare eficientă a request-urilor
- **Error Handling**: Wrapped callbacks cu error propagation

### 💾 Database Management
- **SQL Wrapper**: Query builder simplificat cu prepared statements
- **Migration System**: Versionare schema cu auto-execution
- **CRUD Helpers**: Insert, Update, Select, Delete helper functions
- **Connection Pooling**: Suport pentru multiple conexiuni simultane

### 🎨 UI Framework
- **Vue Integration**: Suport complet pentru componente Vue
- **React Support**: Compatibilitate cu React components
- **Component Registry**: Lifecycle management și dynamic rendering
- **Performance Optimized**: Batch rendering și lazy loading

### ⚡ Performanță
- **Code Optimization**: Minimă latență și overhead
- **Caching System**: Prepared statement caching
- **Async Operations**: Non-blocking operations pe client-side
- **Memory Management**: Proper cleanup și garbage collection

## 📁 Structura Proiectului

```
ReWork-Framework/
├── server/
│   ├── core/
│   │   ├── Framework.lua          # Core server module manager
│   │   ├── RPC.lua                # Server-side RPC system
│   │   ├── Database.lua           # Database manager
│   │   ├── Security.lua           # Security & validation
│   │   └── PluginManager.lua      # Plugin system
│   ├── utils/
│   └── init.lua                   # Server entry point
├── client/
│   ├── core/
│   │   ├── Framework.ts           # Core client module manager
│   │   ├── UIManager.ts           # UI component manager
│   │   └── RPC.ts                 # Client RPC wrapper
│   ├── services/
│   └── init.ts                    # Client entry point
├── shared/
│   ├── types/                     # TypeScript interfaces
│   └── constants/                 # Shared constants
├── ui/
│   ├── vue/                       # Vue components
│   └── react/                     # React components
├── database/
│   └── migrations/                # SQL migrations
├── modules/
│   ├── auth/                      # Authentication module
│   ├── database/                  # Database utilities
│   └── ui/                        # UI utilities
└── docs/                          # Documentation
```

## 🚀 Quick Start

### Server Inițializare

```lua
-- server/init.lua
local Framework = require("server.core.Framework")
local Database = require("server.core.Database")

-- Inițialize framework
Framework:Initialize()

-- Setup database
Database:Initialize({
    HOST = "localhost",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework"
})

-- Registru modul
Framework:RegisterModule("myModule", MyModuleClass)
Framework:EnableModule("myModule")
```

### Client Inițializare

```typescript
// client/init.ts
import ReWorkFramework from './core/Framework';

const framework = ReWorkFramework.getInstance({
    logLevel: 'INFO'
});

// Registru modul client
framework.registerModule('myModule', {
    name: 'myModule',
    enabled: false,
    initialize: async () => {
        console.log('Module initialized');
    }
});

// Activare modul
await framework.enableModule('myModule');
```

## 📚 Utilizare Framework

### RPC Communication

**Server call din client:**
```typescript
const framework = window.ReWork;

// Simple call
const response = await framework.rpcCall('ServerEvent', { 
    message: 'Hello' 
});

// Cu handler
framework.rpcOn('ClientEvent', (data, respond) => {
    console.log('Data din server:', data);
    respond({ success: true });
});
```

**Client call din server:**
```lua
RPC:Call(playerId, "GetPlayerData", {}, function(response)
    print("Răspuns din client:", json.encode(response))
end)
```

### Database Operations

```lua
-- Insert
Database:Insert("users", {
    username = "player",
    email = "player@example.com",
    password_hash = "hashed"
}, function(result)
    if result then
        print("User created with ID:", result.insertId)
    end
end)

-- Select
Database:Select("users", { username = "player" }, {
    orderBy = "created_at DESC",
    limit = 10
}, function(result)
    for _, user in ipairs(result.data) do
        print(user.username)
    end
end)

-- Update
Database:Update("users", 
    { email = "new@example.com" },
    { id = 1 },
    function(result)
        print("Affected rows:", result.affectedRows)
    end
)

-- Delete
Database:Delete("users", { id = 1 }, function(result)
    print("User deleted")
end)
```

### UI Management

```typescript
const uiManager = window.ReWorkUI;

// Registru Vue component
uiManager.registerVueComponent('dashboard', DashboardComponent, {
    user: null
});

// Inițialize și arată
await uiManager.initializeComponent('dashboard');
uiManager.showComponent('dashboard');

// Update component data din server
uiManager.updateComponent('dashboard', {
    user: { name: 'John', level: 50 }
});

// Hide
uiManager.hideComponent('dashboard');
```

### Security & Validation

```lua
-- Input validation
local isValid, error = Security:ValidateInput({
    username = "player",
    email = "player@example.com"
}, {
    username = { type = "string", maxLength = 50, required = true },
    email = { type = "string", required = true, validate = function(val)
        return Security:ValidateEmail(val)
    end }
})

-- SQL injection prevention (automatic în query bindings)
local name = "'; DROP TABLE users; --"
-- Nu are efect datorită escaping
Database:Select("users", { name = name })

-- XSS prevention
local safeHTML = Security:SanitizeHTML(userInput)

-- Rate limiting
local allowed, err = Security:CheckRateLimit(playerId)
if not allowed then
    print("Player exceeded rate limit:", err)
end
```

### Plugin System

```lua
-- Definiție plugin
local MyPlugin = {
    name = "myPlugin",
    version = "1.0.0",
    author = "Developer",
    description = "My awesome plugin",
    dependencies = {}, -- dependency names
    
    initialize = function()
        print("Plugin initialized")
    end,
    
    shutdown = function()
        print("Plugin shutting down")
    end,
    
    hooks = {
        ["player:joined"] = {
            function(playerId)
                print("Player joined:", playerId)
            end
        }
    }
}

-- Registru și load
PluginManager:RegisterPlugin(MyPlugin)
PluginManager:LoadPlugin("myPlugin")

-- Execută hook
PluginManager:ExecuteHook("player:joined", playerId)

-- Unload
PluginManager:UnloadPlugin("myPlugin")
```

## 🔧 Configuration

### Server Config

```lua
-- server/init.lua
Database:Initialize({
    HOST = "127.0.0.1",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework",
    CHARSET = "utf8mb4",
    POOL_SIZE = 5
})

-- Security settings
Security settings sunt in server/core/Security.lua:
- MAX_STRING_LENGTH = 5000
- RATE_LIMIT_REQUESTS = 100 per 1000ms
- ENABLE_SQL_LOG = false
```

### Client Config

```typescript
const framework = ReWorkFramework.getInstance({
    debug: true,
    logLevel: 'DEBUG',
    performanceMonitoring: true
});
```

## 📊 Performance Tips

1. **Batch RPC calls** - Grup multiple calls în one batch
2. **Use pagination** - Limit database results
3. **Cache frequently accessed data** - Minimize database hits
4. **Lazy load UI components** - Render only when visible
5. **Optimize query indexes** - DB performance essential

## 🐛 Debugging

```typescript
// Client debugging
const framework = window.ReWork;
console.log(framework.getModulesStatus());
console.log(window.ReWorkUI.getComponentStatus());
```

```lua
-- Server debugging
print(json.encode(Framework:GetModuleStatus()))
print(json.encode(PluginManager:GetPlugins()))
print(json.encode(Security:GetStats()))
```

## 📝 License

Licensed under MIT License - ReWork Team 2024

## 🤝 Contributing

Contribuții sunt binevenite! Fork repository-ul, creează o branch, și submit pull request.

## 📞 Support

Pentru suport, deschide o issue pe GitHub repository.

---

**Made with ❤️ for the FiveM Community**
