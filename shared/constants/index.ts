/**
 * ReWork Framework - Constante Globale
 * Constante utilizate în întregul framework
 */

// RPC Configuration
export const RPC_CONFIG = {
    REQUEST_TIMEOUT: 5000,
    MAX_PAYLOAD_SIZE: 65536,
    BATCH_INTERVAL: 10,
    COMPRESSION_THRESHOLD: 4096
} as const;

// Database Configuration
export const DB_CONFIG = {
    DEFAULT_HOST: 'localhost',
    DEFAULT_USER: 'rework',
    DEFAULT_PASSWORD: 'rework',
    DEFAULT_DATABASE: 'rework',
    DEFAULT_CHARSET: 'utf8mb4',
    DEFAULT_POOL_SIZE: 5,
    DEFAULT_QUERY_TIMEOUT: 30000
} as const;

// Security Configuration
export const SECURITY_CONFIG = {
    MAX_STRING_LENGTH: 5000,
    MAX_ARRAY_LENGTH: 1000,
    RATE_LIMIT_WINDOW: 1000, // ms
    RATE_LIMIT_REQUESTS: 100, // per window
    ENABLE_SQL_LOG: false
} as const;

// SQL Injection Sensitive Keywords
export const SQL_KEYWORDS = [
    'DROP',
    'DELETE',
    'INSERT',
    'UPDATE',
    'EXEC',
    'EXECUTE',
    'SCRIPT',
    'UNION',
    'SELECT',
    'FROM',
    'WHERE',
    'CREATE',
    'ALTER',
    'GRANT',
    'REVOKE'
] as const;

// Event Names
export const EVENT_NAMES = {
    // RPC Events
    RPC_CALL: 'ReWork:RPC:Call',
    RPC_RESPONSE: 'ReWork:RPC:Response',
    RPC_CLIENT_CALL: 'ReWork:RPC:ClientCall',
    RPC_CLIENT_RESPONSE: 'ReWork:RPC:ClientResponse',
    RPC_BATCH_EVENTS: 'ReWork:RPC:BatchEvents',
    
    // UI Events
    UI_UPDATE: 'ReWork:UI:Update',
    UI_SHOW: 'ReWork:UI:Show',
    UI_HIDE: 'ReWork:UI:Hide',
    
    // Auth Events
    AUTH_LOGIN: 'auth:login',
    AUTH_LOGOUT: 'auth:logout',
    AUTH_REGISTER: 'auth:register',
    AUTH_LOGGED_IN: 'auth:loggedIn',
    AUTH_LOGGED_OUT: 'auth:loggedOut',
    
    // Database Events
    DB_QUERY: 'db:query',
    DB_INSERT: 'db:insert',
    DB_UPDATE: 'db:update',
    DB_DELETE: 'db:delete'
} as const;

// Default Module Names
export const MODULE_NAMES = {
    AUTH: 'auth',
    DATABASE: 'database',
    UI: 'ui',
    CACHE: 'cache',
    LOGGER: 'logger'
} as const;

// HTTP Status Codes
export const HTTP_STATUS = {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    INTERNAL_ERROR: 500,
    SERVICE_UNAVAILABLE: 503
} as const;

// Validation Patterns
export const VALIDATION_PATTERNS = {
    EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    USERNAME: /^[a-zA-Z0-9_]{3,20}$/,
    PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$/,
    URL: /^(https?:\/\/)([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/[a-zA-Z0-9-._~:/?#[\]@!$&'()*+,;=]*)?$/,
    UUID: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i,
    PHONE: /^\+?[1-9]\d{1,14}$/
} as const;

// Error Messages
export const ERROR_MESSAGES = {
    INVALID_CREDENTIALS: 'Credențiale invalide',
    USER_NOT_FOUND: 'Utilizator nu a fost găsit',
    USER_ALREADY_EXISTS: 'Utilizatorul există deja',
    UNAUTHORIZED: 'Neautorizat',
    FORBIDDEN: 'Acces interzis',
    INVALID_INPUT: 'Input invalid',
    DATABASE_ERROR: 'Eroare bază de date',
    RPC_TIMEOUT: 'RPC call timeout',
    RATE_LIMIT_EXCEEDED: 'Prea multe cereri',
    UNKNOWN_ERROR: 'Eroare necunoscută'
} as const;

// Time Constants (în milisecunde)
export const TIME = {
    SECOND: 1000,
    MINUTE: 60 * 1000,
    HOUR: 60 * 60 * 1000,
    DAY: 24 * 60 * 60 * 1000
} as const;

// Default Timeouts
export const TIMEOUTS = {
    RPC: 5000,
    DATABASE: 30000,
    HTTP: 10000,
    RATE_LIMIT_WINDOW: 1000
} as const;
