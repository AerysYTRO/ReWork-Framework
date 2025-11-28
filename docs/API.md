# ReWork Framework - API Reference

## 📋 Table of Contents

1. [Server API](#server-api)
2. [Client API](#client-api)
3. [RPC System](#rpc-system)
4. [Database API](#database-api)
5. [Security API](#security-api)
6. [Plugin Manager API](#plugin-manager-api)
7. [UI Manager API](#ui-manager-api)

---

## Server API

### Framework Class

#### `Framework:Initialize()`
Inițializează framework-ul server.

**Returns:** `boolean`

```lua
if Framework:Initialize() then
    print("Framework initialized")
end
```

---

#### `Framework:RegisterModule(moduleName, moduleClass)`
Registrează un modul nou.

**Parameters:**
- `moduleName` (string): Numele unic al modulului
- `moduleClass` (table): Clasa modulului cu Initialize și Cleanup methods

**Returns:** `boolean`

```lua
Framework:RegisterModule("myModule", MyModuleClass)
```

---

#### `Framework:EnableModule(moduleName)`
Activează un modul registrat.

**Parameters:**
- `moduleName` (string): Numele modulului

**Returns:** `boolean`

```lua
Framework:EnableModule("myModule")
```

---

#### `Framework:DisableModule(moduleName)`
Dezactivează un modul.

**Parameters:**
- `moduleName` (string): Numele modulului

**Returns:** `boolean`

---

#### `Framework:GetModule(moduleName)`
Obține instanța unui modul.

**Parameters:**
- `moduleName` (string): Numele modulului

**Returns:** `table` sau `nil`

```lua
local module = Framework:GetModule("myModule")
if module then
    -- Utilizare modul
end
```

---

#### `Framework:On(eventName, callback)`
Registrează listener pentru event.

**Parameters:**
- `eventName` (string): Numele evenimentului
- `callback` (function): Funcție callback

---

#### `Framework:Emit(eventName, ...)`
Emite un eveniment.

**Parameters:**
- `eventName` (string): Numele evenimentului
- `...` (any): Argumente pentru callback

---

#### `Framework:GetModuleStatus()`
Obține status-ul tuturor modulelor.

**Returns:** `table`

```lua
local status = Framework:GetModuleStatus()
-- { moduleName = { enabled = true, hasInstance = true } }
```

---

## RPC System

### RPC Class

#### `RPC:Call(target, eventName, data, callback)`
Trimite RPC call către client.

**Parameters:**
- `target` (number): Player ID sau -1 pentru broadcast
- `eventName` (string): Numele evenimentului
- `data` (table): Datele care vor fi transmise
- `callback` (function): Optional, callback pentru response

```lua
RPC:Call(playerId, "GetPlayerData", {}, function(response)
    print("Response:", json.encode(response))
end)
```

---

#### `RPC:On(eventName, handler)`
Registrează handler pentru RPC calls din client.

**Parameters:**
- `eventName` (string): Numele evenimentului
- `handler` (function): Function(data, responseCallback)

```lua
RPC:On("ClientRequest", function(data, respond)
    respond({ success = true, data = {} })
end)
```

---

#### `RPC:Response(requestID, responseData)`
Trimite response pentru RPC request.

**Parameters:**
- `requestID` (number): ID-ul requestului
- `responseData` (table): Datele response-ului

---

#### `RPC:QueueEvent(target, eventName, data)`
Adaugă eveniment în batch queue.

---

#### `RPC:FlushEventBatch()`
Trimite batch-ul de events.

---

## Database API

### Database Class

#### `Database:Initialize(config)`
Inițializează conexiunea la baza de date.

**Parameters:**
- `config` (table): Configurare conexiune

```lua
Database:Initialize({
    HOST = "localhost",
    USER = "rework",
    PASSWORD = "rework",
    DATABASE = "rework"
})
```

---

#### `Database:Query(query, params, callback)`
Execută query custom cu parameter binding.

**Parameters:**
- `query` (string): SQL query
- `params` (table): Parametri pentru query
- `callback` (function): Callback function(result)

```lua
Database:Query("SELECT * FROM users WHERE id = ?", {1}, function(result)
    if result and result.data then
        for _, user in ipairs(result.data) do
            print(user.username)
        end
    end
end)
```

---

#### `Database:Insert(tableName, data, callback)`
Insert helper.

**Parameters:**
- `tableName` (string): Numele tabelei
- `data` (table): {column = value}
- `callback` (function): Callback function(result)

```lua
Database:Insert("players", {
    username = "john",
    email = "john@example.com",
    level = 1
}, function(result)
    if result then
        print("Insert ID:", result.insertId)
    end
end)
```

---

#### `Database:Select(tableName, where, options, callback)`
Select helper.

**Parameters:**
- `tableName` (string): Numele tabelei
- `where` (table): Condiții WHERE
- `options` (table): {limit, offset, orderBy}
- `callback` (function): Callback function(result)

```lua
Database:Select("players", 
    { level = 50 },
    { orderBy = "username ASC", limit = 10 },
    function(result)
        -- Process result
    end
)
```

---

#### `Database:Update(tableName, data, where, callback)`
Update helper.

**Parameters:**
- `tableName` (string): Numele tabelei
- `data` (table): Noi valori
- `where` (table): Condiții WHERE
- `callback` (function): Callback function(result)

---

#### `Database:Delete(tableName, where, callback)`
Delete helper.

**Parameters:**
- `tableName` (string): Numele tabelei
- `where` (table): Condiții WHERE
- `callback` (function): Callback function(result)

---

## Security API

### Security Class

#### `Security:ValidateInput(data, schema)`
Validează input-ul conform schemei.

**Parameters:**
- `data` (table): Datele de validat
- `schema` (table): Schema de validare

**Returns:** `boolean, string`

```lua
local isValid, error = Security:ValidateInput(data, {
    username = { type = "string", maxLength = 50, required = true },
    email = { type = "string", validate = function(val)
        return Security:ValidateEmail(val)
    end }
})
```

---

#### `Security:ValidateEmail(email)`
Validează email format.

**Parameters:**
- `email` (string): Email pentru validare

**Returns:** `boolean`

---

#### `Security:ValidateURL(url)`
Validează URL-ul.

**Parameters:**
- `url` (string): URL pentru validare

**Returns:** `boolean`

---

#### `Security:SanitizeString(input)`
Sanitizează string-ul.

**Parameters:**
- `input` (string): String pentru sanitizare

**Returns:** `string`

---

#### `Security:SanitizeHTML(input)`
Sanitizează HTML output.

**Parameters:**
- `input` (string): HTML string

**Returns:** `string`

---

#### `Security:EscapeSQLString(value)`
Escapează SQL string.

**Parameters:**
- `value` (string): String pentru escape

**Returns:** `string`

---

#### `Security:CheckRateLimit(playerID)`
Verifica rate limit pentru player.

**Parameters:**
- `playerID` (number): Player ID

**Returns:** `boolean, string`

---

## Plugin Manager API

### PluginManager Class

#### `PluginManager:RegisterPlugin(pluginDef)`
Registrează plugin.

**Parameters:**
- `pluginDef` (table): Plugin definition

```lua
PluginManager:RegisterPlugin({
    name = "myPlugin",
    version = "1.0.0",
    author = "Author",
    initialize = function() end,
    hooks = {}
})
```

---

#### `PluginManager:LoadPlugin(pluginName)`
Încarcă plugin.

**Parameters:**
- `pluginName` (string): Numele pluginului

**Returns:** `boolean`

---

#### `PluginManager:UnloadPlugin(pluginName)`
Descarcă plugin.

**Parameters:**
- `pluginName` (string): Numele pluginului

**Returns:** `boolean`

---

#### `PluginManager:EnablePlugin(pluginName)`
Activează plugin.

---

#### `PluginManager:DisablePlugin(pluginName)`
Dezactivează plugin.

---

#### `PluginManager:ExecuteHook(hookName, ...)`
Execută hook pentru toți pluginii.

**Parameters:**
- `hookName` (string): Numele hook-ului
- `...` (any): Argumente hook

**Returns:** `table` cu HookResult objects

---

#### `PluginManager:RegisterHook(pluginName, hookName, callback)`
Registrează hook handler.

---

#### `PluginManager:GetPlugins()`
Obține lista pluginilor.

**Returns:** `table`

---

## Client API

### ReWorkFramework Class

#### `getInstance(config)`
Obține singleton instance.

**Parameters:**
- `config` (ReWorkConfig): Opțional, configurare

**Returns:** `ReWorkFramework`

```typescript
const framework = ReWorkFramework.getInstance({
    logLevel: 'DEBUG'
});
```

---

#### `registerModule(name, module)`
Registrează modul client.

**Parameters:**
- `name` (string): Numele modulului
- `module` (ModuleInterface): Obiectul modulului

**Returns:** `boolean`

---

#### `enableModule(name)`
Activează modul.

**Parameters:**
- `name` (string): Numele modulului

**Returns:** `Promise<boolean>`

---

#### `disableModule(name)`
Dezactivează modul.

**Parameters:**
- `name` (string): Numele modulului

**Returns:** `Promise<boolean>`

---

#### `getModule(name)`
Obține instanța modulului.

**Parameters:**
- `name` (string): Numele modulului

**Returns:** `ModuleInterface | undefined`

---

#### `rpcCall(eventName, data)`
Apel RPC la server.

**Parameters:**
- `eventName` (string): Numele evenimentului
- `data` (any): Datele RPC

**Returns:** `Promise<any>`

```typescript
try {
    const response = await framework.rpcCall('GetPlayerData', { id: 1 });
    console.log(response);
} catch (error) {
    console.error(error);
}
```

---

#### `rpcOn(eventName, callback)`
Registrează RPC handler din server.

**Parameters:**
- `eventName` (string): Numele evenimentului
- `callback` (function): Handler function

---

#### `on(eventName, callback)`
Registrează local event listener.

---

#### `emit(eventName, ...args)`
Emite local event.

---

## UI Manager API

### UIManager Class

#### `getInstance(config)`
Obține singleton instance.

**Parameters:**
- `config` (UIManagerConfig): Opțional, configurare

**Returns:** `UIManager`

---

#### `registerVueComponent(name, component, props)`
Registrează Vue component.

**Parameters:**
- `name` (string): Numele componentei
- `component` (any): Vue component
- `props` (object): Opțional, props default

**Returns:** `boolean`

---

#### `registerReactComponent(name, component, props)`
Registrează React component.

---

#### `initializeComponent(name)`
Inițializează component.

**Parameters:**
- `name` (string): Numele componentei

**Returns:** `Promise<boolean>`

---

#### `showComponent(name)`
Arată component.

**Parameters:**
- `name` (string): Numele componentei

**Returns:** `boolean`

---

#### `hideComponent(name)`
Ascunde component.

**Parameters:**
- `name` (string): Numele componentei

**Returns:** `boolean`

---

#### `updateComponent(name, data)`
Actualizează component data.

**Parameters:**
- `name` (string): Numele componentei
- `data` (object): Noi date

**Returns:** `boolean`

---

#### `destroyComponent(name)`
Distruge component.

**Parameters:**
- `name` (string): Numele componentei

**Returns:** `Promise<boolean>`

---

#### `getComponentStatus()`
Obține status tuturor componentelor.

**Returns:** `Record<string, ComponentStatus>`

---

## Constants

### Event Names

```typescript
EVENT_NAMES.RPC_CALL
EVENT_NAMES.RPC_RESPONSE
EVENT_NAMES.AUTH_LOGIN
EVENT_NAMES.UI_UPDATE
// ... more
```

### HTTP Status Codes

```typescript
HTTP_STATUS.OK // 200
HTTP_STATUS.CREATED // 201
HTTP_STATUS.BAD_REQUEST // 400
HTTP_STATUS.UNAUTHORIZED // 401
// ... more
```

### Validation Patterns

```typescript
VALIDATION_PATTERNS.EMAIL
VALIDATION_PATTERNS.USERNAME
VALIDATION_PATTERNS.PASSWORD
VALIDATION_PATTERNS.URL
VALIDATION_PATTERNS.UUID
VALIDATION_PATTERNS.PHONE
```

---

**API documentation completă a framework-ului ReWork**
