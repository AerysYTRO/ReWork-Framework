/**
 * ReWork Framework - TypeScript Interfaces și Types
 * Definițiile tipurilor utilizate în întregul framework
 */

// RPC System Types
export interface RPCPayload {
    id: number;
    event: string;
    data: any;
    timestamp: number;
}

export interface RPCRequest {
    resolve: Function;
    reject: Function;
    timeout: NodeJS.Timeout;
}

export interface BatchEventPayload {
    event: string;
    data: any;
}

// Module Types
export interface ModuleInterface {
    name: string;
    enabled: boolean;
    initialize?(): Promise<void>;
    cleanup?(): Promise<void>;
}

export interface ModuleStatus {
    name: string;
    enabled: boolean;
    hasInstance: boolean;
}

// Database Types
export interface DatabaseConfig {
    HOST: string;
    USER: string;
    PASSWORD: string;
    DATABASE: string;
    CHARSET?: string;
    POOL_SIZE?: number;
    QUERY_TIMEOUT?: number;
}

export interface QueryResult {
    affectedRows: number;
    insertId: number;
    data: any[];
}

export interface QueryOptions {
    limit?: number;
    offset?: number;
    orderBy?: string;
}

// Security Types
export interface ValidationSchema {
    [key: string]: {
        type?: string;
        required?: boolean;
        maxLength?: number;
        min?: number;
        max?: number;
        validate?: (value: any) => [boolean, string?];
    };
}

export interface RateLimitData {
    requests: number;
    windowStart: number;
}

// UI Types
export interface UIComponent {
    name: string;
    framework: 'vue' | 'react';
    element?: HTMLElement;
    instance?: any;
    props?: Record<string, any>;
    visible: boolean;
    initialize?(): Promise<void>;
    cleanup?(): Promise<void>;
    setData?(data: Record<string, any>): void;
}

export interface UIManagerConfig {
    autoInitialize?: boolean;
    renderDelay?: number;
    enableLogging?: boolean;
}

export interface ComponentStatus {
    framework: 'vue' | 'react';
    visible: boolean;
    initialized: boolean;
}

// Plugin Types
export interface PluginDefinition {
    name: string;
    version: string;
    author: string;
    description: string;
    dependencies?: string[];
    initialize(): Promise<void> | void;
    shutdown?(): Promise<void> | void;
    hooks?: {
        [hookName: string]: Function[];
    };
}

export interface HookResult {
    plugin: string;
    success: boolean;
    result?: any;
    error?: string;
}

// Event Types
export interface EventListener {
    callback: (...args: any[]) => void;
    once?: boolean;
}

// Logger Types
export enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3
}

// Framework Config
export interface ReWorkConfig {
    debug?: boolean;
    logLevel?: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
    performanceMonitoring?: boolean;
}

// User/Player Types
export interface PlayerData {
    id: number;
    username: string;
    email: string;
    createdAt?: string;
    updatedAt?: string;
}

export interface AuthCredentials {
    username: string;
    password: string;
}

export interface AuthResponse {
    success: boolean;
    token?: string;
    player?: PlayerData;
    error?: string;
}
