# ReWork Framework - Getting Started Guide

## 📦 Instalare

1. **Clone repository-ul**
   ```bash
   git clone https://github.com/AerysYTRO/ReWork-Framework.git
   cd ReWork-Framework
   ```

2. **Instalare dependencies**
   ```bash
   npm install
   ```

3. **Build TypeScript**
   ```bash
   npm run build
   ```

## 🔧 Setup Server

### 1. Copierea Framework-ului

Copiază folderul `ReWork-Framework` în directorul `resources` al serverului FiveM:
```
FiveM Server/
└── resources/
    └── ReWork-Framework/
        ├── server/
        ├── client/
        ├── fxmanifest.yaml
        └── ...
```

### 2. Database Setup

Creeaza baza de date și user:
```sql
CREATE DATABASE rework;
CREATE USER 'rework'@'localhost' IDENTIFIED BY 'rework';
GRANT ALL PRIVILEGES ON rework.* TO 'rework'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Update Server Config

În `server.cfg`, adaugă:
```
ensure ReWork-Framework
```

### 4. Configurare Framework

Editează `server/init.lua` pentru a configura database:
```lua
Database:Initialize({
    HOST = "localhost",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework"
})
```

## 💻 Utilizare Client

### Hello World Example

```typescript
// client/init.ts
import ReWorkFramework from './core/Framework';

const fw = ReWorkFramework.getInstance();

// Test RPC call
async function testRPC() {
    try {
        const response = await fw.rpcCall('TestEvent', {
            message: 'Hello Server'
        });
        console.log('Server response:', response);
    } catch (error) {
        console.error('Error:', error);
    }
}

// Call after 2 seconds
setTimeout(testRPC, 2000);
```

### Server-side Handler

```lua
-- server/init.lua
RPC:On("TestEvent", function(data, respond)
    print("Client message:", data.message)
    respond({
        success = true,
        message = "Hello Client!"
    })
end)
```

## 🔐 Exemplu Autentificare

### Client (TypeScript)

```typescript
import AuthModule from '../../modules/auth/client';

const framework = window.ReWork;

// Register auth module
framework.registerModule('auth', new AuthModule());
await framework.enableModule('auth');

// Login
const authModule = framework.getModule('auth');
try {
    const response = await framework.rpcCall('auth:validateCredentials', {
        username: 'player',
        password: 'password123'
    });
    
    if (response.success) {
        console.log('Logged in as:', response.player.username);
    }
} catch (error) {
    console.error('Login failed:', error);
}
```

### Server (Lua)

```lua
-- Registru auth module
local AuthModule = require("modules.auth.server")
Framework:RegisterModule("auth", AuthModule:new())
Framework:EnableModule("auth")
```

## 💾 Database Operations

### Insert
```lua
Database:Insert("players", {
    username = "john_doe",
    email = "john@example.com",
    level = 1
}, function(result)
    if result then
        print("Player created with ID:", result.insertId)
    end
end)
```

### Select
```lua
Database:Select("players", 
    { username = "john_doe" },
    { orderBy = "created_at DESC", limit = 10 },
    function(result)
        if result and result.data then
            for _, player in ipairs(result.data) do
                print("Player:", player.username, "Level:", player.level)
            end
        end
    end
)
```

### Update
```lua
Database:Update("players",
    { level = 50 },
    { id = 1 },
    function(result)
        print("Players updated:", result.affectedRows)
    end
)
```

### Delete
```lua
Database:Delete("players", { id = 1 }, function(result)
    print("Player deleted")
end)
```

## 🎨 UI Examples

### Register Vue Component

```typescript
import DashboardComponent from './components/Dashboard.vue';

const ui = window.ReWorkUI;

ui.registerVueComponent('dashboard', DashboardComponent, {
    user: null,
    stats: {}
});

// Initialize și show
await ui.initializeComponent('dashboard');
ui.showComponent('dashboard');

// Update data din server
ui.updateComponent('dashboard', {
    user: { name: 'John', level: 50 },
    stats: { kills: 100, deaths: 20 }
});
```

### React Component

```typescript
import Dashboard from './components/Dashboard.tsx';

const ui = window.ReWorkUI;

ui.registerReactComponent('dashboard', Dashboard, {
    user: null
});

await ui.initializeComponent('dashboard');
ui.showComponent('dashboard');
```

## 🔌 Plugin Development

### Creare Plugin

```lua
local MyPlugin = {
    name = "myAwesomePlugin",
    version = "1.0.0",
    author = "Your Name",
    description = "My awesome plugin",
    dependencies = {},
    
    initialize = function()
        print("Plugin initialized!")
    end,
    
    shutdown = function()
        print("Plugin shutting down!")
    end,
    
    hooks = {
        ["player:spawn"] = {
            function(playerId)
                print("Player spawned:", playerId)
            end
        }
    }
}

-- Register și load
PluginManager:RegisterPlugin(MyPlugin)
PluginManager:LoadPlugin("myAwesomePlugin")
```

## 🔒 Security

### Input Validation

```lua
local isValid, error = Security:ValidateInput({
    username = userInput.username,
    email = userInput.email
}, {
    username = {
        type = "string",
        maxLength = 50,
        required = true
    },
    email = {
        type = "string",
        required = true,
        validate = function(val)
            return Security:ValidateEmail(val)
        end
    }
})

if not isValid then
    print("Validation error:", error)
end
```

### Rate Limiting

```lua
local allowed, err = Security:CheckRateLimit(playerId)
if not allowed then
    print("Rate limit exceeded:", err)
    respond({ success = false, error = "Too many requests" })
    return
end
```

## 📊 Performance Tips

1. **Batch RPC calls** - Grup multiple calls
2. **Paginate results** - Limit SELECT queries
3. **Cache frequently used data**
4. **Use lazy loading** pentru UI components
5. **Monitor performance** cu built-in tools

## 🐛 Debugging

### Server Debug
```lua
-- Print module status
print(json.encode(Framework:GetModuleStatus()))

-- Print active plugins
print(json.encode(PluginManager:GetPlugins()))

-- Print security stats
print(json.encode(Security:GetStats()))
```

### Client Debug
```typescript
// Print modules
console.log(window.ReWork.getModulesStatus());

// Print UI components
console.log(window.ReWorkUI.getComponentStatus());
```

## 📚 Resurse Adiționale

- [Full Documentation](README.md)
- [API Reference](API.md)
- [Examples](examples/)
- [GitHub Issues](https://github.com/AerysYTRO/ReWork-Framework/issues)

## ❓ FAQ

**Q: Cum integrez framework-ul în scriptul meu existent?**
A: Import modulele necesare și utilizează exported functions.

**Q: Suportă framework-ul MySQL async?**
A: Da, puteți configura orice MySQL library (mysql-async, oxmysql, etc).

**Q: Cum cresc performanța?**
A: Folosiți caching, batch processing, și optimizați queries.

## 📞 Support

Pentru ajutor, contactează:
- Discord: https://discord.gg/bGe5SPYUgK
- GitHub Issues: [\[Issues page\]](https://github.com/AerysYTRO/ReWork-Framework/issues)

---

**Happy coding! 🚀**
