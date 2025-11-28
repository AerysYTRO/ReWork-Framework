/**
 * ReWork Framework - Core Client Module
 * Manager de module și coordonator pentru client-side
 * 
 * Caracteristici:
 * - Module management system
 * - Event emitter pattern
 * - RPC communication wrapper
 * - Performance monitoring
 */

interface ModuleInterface {
    name: string;
    enabled: boolean;
    initialize?(): Promise<void>;
    cleanup?(): Promise<void>;
}

interface EventListener {
    callback: (...args: any[]) => void;
    once?: boolean;
}

interface ReWorkConfig {
    debug?: boolean;
    logLevel?: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
    performanceMonitoring?: boolean;
}

/**
 * Logger utility cu suport pentru niveluri de severitate
 */
class Logger {
    private level: { [key: string]: number } = {
        DEBUG: 0,
        INFO: 1,
        WARN: 2,
        ERROR: 3
    };

    private currentLevel: number = 1;

    constructor(logLevel: string = 'INFO') {
        this.currentLevel = this.level[logLevel] || 1;
    }

    private formatMessage(level: string, message: string, args: any[]): string {
        const timestamp = new Date().toLocaleTimeString();
        let formattedMsg = message;

        if (args.length > 0) {
            formattedMsg = this.sprintf(message, ...args);
        }

        return `[ReWork - ${timestamp}] [${level}] ${formattedMsg}`;
    }

    private sprintf(format: string, ...args: any[]): string {
        let i = 0;
        return format.replace(/%[ds]/g, () => {
            const arg = args[i++];
            return typeof arg === 'string' ? arg : String(arg);
        });
    }

    public debug(msg: string, ...args: any[]): void {
        if (this.level.DEBUG >= this.currentLevel) {
            console.log(`%c${this.formatMessage('DEBUG', msg, args)}`, 'color: gray');
        }
    }

    public info(msg: string, ...args: any[]): void {
        if (this.level.INFO >= this.currentLevel) {
            console.log(`%c${this.formatMessage('INFO', msg, args)}`, 'color: blue');
        }
    }

    public warn(msg: string, ...args: any[]): void {
        if (this.level.WARN >= this.currentLevel) {
            console.warn(`%c${this.formatMessage('WARN', msg, args)}`, 'color: orange');
        }
    }

    public error(msg: string, ...args: any[]): void {
        if (this.level.ERROR >= this.currentLevel) {
            console.error(`%c${this.formatMessage('ERROR', msg, args)}`, 'color: red');
        }
    }
}

/**
 * RPC Service - comunicare cu server-side Lua
 */
class RPCService {
    private requestID: number = 0;
    private pendingRequests: Map<
        number,
        { resolve: Function; reject: Function; timeout: NodeJS.Timeout }
    > = new Map();
    private eventListeners: Map<string, Array<EventListener>> = new Map();
    private logger: Logger;

    constructor(logger: Logger) {
        this.logger = logger;
        this.setupListeners();
    }

    private setupListeners(): void {
        // Listener pentru RPC calls din server
        on('ReWork:RPC:Call', (payload: any) => {
            this.handleRPCCall(payload);
        });

        // Listener pentru RPC responses
        on('ReWork:RPC:Response', (payload: any) => {
            this.handleRPCResponse(payload);
        });

        // Listener pentru batch events
        on('ReWork:RPC:BatchEvents', (payload: any) => {
            this.handleBatchEvents(payload);
        });
    }

    /**
     * Apel RPC la server cu timeout și error handling
     */
    public async call(
        eventName: string,
        data?: any,
        timeout: number = 5000
    ): Promise<any> {
        return new Promise((resolve, reject) => {
            const requestID = ++this.requestID;
            const timeoutHandle = setTimeout(() => {
                this.pendingRequests.delete(requestID);
                reject(new Error(`RPC call timeout: ${eventName}`));
            }, timeout);

            this.pendingRequests.set(requestID, {
                resolve,
                reject,
                timeout: timeoutHandle
            });

            // Trimite RPC call la server
            emit('ReWork:RPC:ClientCall', {
                id: requestID,
                event: eventName,
                data: data || {},
                timestamp: Date.now()
            });
        });
    }

    /**
     * Handle RPC call de la server
     */
    private handleRPCCall(payload: any): void {
        const listeners = this.eventListeners.get(payload.event);

        if (!listeners) {
            this.logger.warn(`Nu exista listener pentru event: ${payload.event}`);
            return;
        }

        listeners.forEach(listener => {
            try {
                listener.callback(payload.data, (response: any) => {
                    this.sendResponse(payload.id, response);
                });
            } catch (error) {
                this.logger.error(`Error in RPC listener: ${error}`);
            }
        });
    }

    /**
     * Handle RPC response de la server
     */
    private handleRPCResponse(payload: any): void {
        const request = this.pendingRequests.get(payload.id);

        if (!request) {
            this.logger.warn(`RPC response pentru request necunoscut: ${payload.id}`);
            return;
        }

        clearTimeout(request.timeout);
        request.resolve(payload.response);
        this.pendingRequests.delete(payload.id);
    }

    /**
     * Handle batch events din server
     */
    private handleBatchEvents(payload: any): void {
        if (!payload.batch || !Array.isArray(payload.batch)) {
            return;
        }

        payload.batch.forEach((event: any) => {
            const listeners = this.eventListeners.get(event.event);
            if (listeners) {
                listeners.forEach(listener => {
                    try {
                        listener.callback(event.data);
                    } catch (error) {
                        this.logger.error(`Error in batch event listener: ${error}`);
                    }
                });
            }
        });
    }

    /**
     * Trimite response la server
     */
    private sendResponse(requestID: number, data: any): void {
        emit('ReWork:RPC:ClientResponse', {
            id: requestID,
            response: data,
            timestamp: Date.now()
        });
    }

    /**
     * Registreaza listener pentru RPC events din server
     */
    public on(eventName: string, callback: Function): void {
        if (!this.eventListeners.has(eventName)) {
            this.eventListeners.set(eventName, []);
        }

        this.eventListeners.get(eventName)!.push({
            callback: callback as (data: any, respond: Function) => void
        });

        this.logger.debug(`RPC listener registrat: ${eventName}`);
    }

    /**
     * Cleanup - deconectare listeners
     */
    public cleanup(): void {
        this.eventListeners.clear();
        this.pendingRequests.forEach(request => clearTimeout(request.timeout));
        this.pendingRequests.clear();
    }
}

/**
 * Core ReWork Framework - main entry point client-side
 */
class ReWorkFramework {
    private static instance: ReWorkFramework;
    private modules: Map<string, ModuleInterface> = new Map();
    private eventListeners: Map<string, Array<EventListener>> = new Map();
    private rpc: RPCService;
    private logger: Logger;
    private config: ReWorkConfig;

    private constructor(config: ReWorkConfig = {}) {
        this.config = {
            debug: false,
            logLevel: 'INFO',
            performanceMonitoring: false,
            ...config
        };

        this.logger = new Logger(this.config.logLevel);
        this.rpc = new RPCService(this.logger);

        this.logger.info('ReWork Framework v1.0.0 inițializat');
    }

    /**
     * Singleton pattern
     */
    public static getInstance(config?: ReWorkConfig): ReWorkFramework {
        if (!ReWorkFramework.instance) {
            ReWorkFramework.instance = new ReWorkFramework(config);
        }
        return ReWorkFramework.instance;
    }

    /**
     * Registrare modul
     */
    public registerModule(name: string, module: ModuleInterface): boolean {
        if (this.modules.has(name)) {
            this.logger.warn(`Modulul '${name}' este deja registrat`);
            return false;
        }

        this.modules.set(name, {
            name,
            enabled: false,
            ...module
        });

        this.logger.info(`Modul '${name}' registrat`);
        return true;
    }

    /**
     * Activare modul
     */
    public async enableModule(name: string): Promise<boolean> {
        const module = this.modules.get(name);

        if (!module) {
            this.logger.error(`Modulul '${name}' nu a fost găsit`);
            return false;
        }

        if (module.enabled) {
            this.logger.warn(`Modulul '${name}' este deja activ`);
            return false;
        }

        try {
            if (module.initialize) {
                await module.initialize();
            }

            module.enabled = true;
            this.logger.info(`Modul '${name}' activat`);
            return true;
        } catch (error) {
            this.logger.error(`Activare eșuată pentru modulul '${name}': ${error}`);
            return false;
        }
    }

    /**
     * Dezactivare modul
     */
    public async disableModule(name: string): Promise<boolean> {
        const module = this.modules.get(name);

        if (!module) {
            this.logger.error(`Modulul '${name}' nu a fost găsit`);
            return false;
        }

        if (!module.enabled) {
            this.logger.warn(`Modulul '${name}' nu este activ`);
            return false;
        }

        try {
            if (module.cleanup) {
                await module.cleanup();
            }

            module.enabled = false;
            this.logger.info(`Modul '${name}' dezactivat`);
            return true;
        } catch (error) {
            this.logger.error(`Dezactivare eșuată pentru modulul '${name}': ${error}`);
            return false;
        }
    }

    /**
     * Obține modul
     */
    public getModule(name: string): ModuleInterface | undefined {
        return this.modules.get(name);
    }

    /**
     * Event system
     */
    public on(eventName: string, callback: Function): void {
        if (!this.eventListeners.has(eventName)) {
            this.eventListeners.set(eventName, []);
        }

        this.eventListeners.get(eventName)!.push({
            callback: callback as any
        });
    }

    /**
     * Emit event local (nu la server)
     */
    public emit(eventName: string, ...args: any[]): void {
        const listeners = this.eventListeners.get(eventName);

        if (!listeners) return;

        listeners.forEach(listener => {
            try {
                listener.callback(...args);
            } catch (error) {
                this.logger.error(`Error in event listener: ${error}`);
            }
        });
    }

    /**
     * RPC call la server
     */
    public rpcCall(eventName: string, data?: any): Promise<any> {
        return this.rpc.call(eventName, data);
    }

    /**
     * Registrare RPC handler din server
     */
    public rpcOn(eventName: string, callback: Function): void {
        this.rpc.on(eventName, callback);
    }

    /**
     * Get status tuturor modulelor
     */
    public getModulesStatus(): Record<string, { name: string; enabled: boolean }> {
        const status: Record<string, any> = {};

        this.modules.forEach((module, name) => {
            status[name] = {
                name: module.name,
                enabled: module.enabled
            };
        });

        return status;
    }

    /**
     * Cleanup
     */
    public async cleanup(): Promise<void> {
        // Dezactivare toți modulii
        const moduleNames = Array.from(this.modules.keys());
        for (const name of moduleNames) {
            await this.disableModule(name);
        }

        // Cleanup RPC
        this.rpc.cleanup();

        // Clear event listeners
        this.eventListeners.clear();

        this.logger.info('ReWork Framework cleanup complet');
    }
}

// Export
export default ReWorkFramework;
export { RPCService, Logger, ReWorkConfig };
