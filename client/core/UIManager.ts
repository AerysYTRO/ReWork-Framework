/**
 * ReWork Framework - UI Manager
 * Coordonator pentru componente Vue și React pe client-side
 * 
 * Caracteristici:
 * - Component registry și lifecycle management
 * - Integrare RPC cu backend
 * - Performance optimization pentru UI rendering
 * - Suport pentru multiple UI frameworks
 */

interface UIComponent {
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

interface UIManagerConfig {
    autoInitialize?: boolean;
    renderDelay?: number;
    enableLogging?: boolean;
}

class UIManager {
    private static instance: UIManager;
    private components: Map<string, UIComponent> = new Map();
    private renderQueue: string[] = [];
    private config: UIManagerConfig;
    private logger: Console;
    private rpcService: any; // Would be the RPC service from Framework.ts

    private constructor(config: UIManagerConfig = {}) {
        this.config = {
            autoInitialize: true,
            renderDelay: 16, // ~60fps
            enableLogging: false,
            ...config
        };

        this.logger = console;

        if (this.config.enableLogging) {
            this.log('UIManager inițializat', 'info');
        }

        this.setupListeners();
    }

    /**
     * Singleton pattern
     */
    public static getInstance(config?: UIManagerConfig): UIManager {
        if (!UIManager.instance) {
            UIManager.instance = new UIManager(config);
        }
        return UIManager.instance;
    }

    private setupListeners(): void {
        // Listener pentru UI updates din server
        on('ReWork:UI:Update', (componentName: string, data: Record<string, any>) => {
            this.updateComponent(componentName, data);
        });

        // Listener pentru hide/show
        on('ReWork:UI:Show', (componentName: string) => {
            this.showComponent(componentName);
        });

        on('ReWork:UI:Hide', (componentName: string) => {
            this.hideComponent(componentName);
        });
    }

    /**
     * Registrare component Vue
     */
    public registerVueComponent(
        name: string,
        component: any,
        props?: Record<string, any>
    ): boolean {
        if (this.components.has(name)) {
            this.log(`Component '${name}' este deja registrat`, 'warn');
            return false;
        }

        const container = document.createElement('div');
        container.id = `vue-${name}`;
        container.style.display = 'none';
        document.body.appendChild(container);

        this.components.set(name, {
            name,
            framework: 'vue',
            element: container,
            props: props || {},
            visible: false
        });

        this.log(`Component Vue '${name}' registrat`, 'info');
        return true;
    }

    /**
     * Registrare component React
     */
    public registerReactComponent(
        name: string,
        component: any,
        props?: Record<string, any>
    ): boolean {
        if (this.components.has(name)) {
            this.log(`Component '${name}' este deja registrat`, 'warn');
            return false;
        }

        const container = document.createElement('div');
        container.id = `react-${name}`;
        container.style.display = 'none';
        document.body.appendChild(container);

        this.components.set(name, {
            name,
            framework: 'react',
            element: container,
            props: props || {},
            visible: false
        });

        this.log(`Component React '${name}' registrat`, 'info');
        return true;
    }

    /**
     * Initializare component cu rendering
     */
    public async initializeComponent(name: string): Promise<boolean> {
        const comp = this.components.get(name);

        if (!comp) {
            this.log(`Component '${name}' nu a fost găsit`, 'error');
            return false;
        }

        try {
            if (comp.initialize) {
                await comp.initialize();
            }

            // Render component dacă este necesar
            if (comp.framework === 'vue') {
                // Vue rendering logic
                this.log(`Vue component '${name}' render-ul inițiat`, 'debug');
            } else if (comp.framework === 'react') {
                // React rendering logic
                this.log(`React component '${name}' render-ul inițiat`, 'debug');
            }

            return true;
        } catch (error) {
            this.log(`Inițializare eșuată pentru '${name}': ${error}`, 'error');
            return false;
        }
    }

    /**
     * Actualizare component data
     */
    public updateComponent(
        name: string,
        data: Record<string, any>
    ): boolean {
        const comp = this.components.get(name);

        if (!comp) {
            this.log(`Component '${name}' nu a fost găsit`, 'error');
            return false;
        }

        try {
            if (comp.setData) {
                comp.setData(data);
            } else {
                // Update component instance data direct
                if (comp.instance && comp.instance.$data) {
                    Object.assign(comp.instance.$data, data);
                } else if (comp.instance && comp.instance.state) {
                    // React
                    comp.instance.setState(data);
                }
            }

            this.renderQueue.push(name);
            this.processRenderQueue();

            return true;
        } catch (error) {
            this.log(`Update eșuat pentru '${name}': ${error}`, 'error');
            return false;
        }
    }

    /**
     * Arată component
     */
    public showComponent(name: string): boolean {
        const comp = this.components.get(name);

        if (!comp) {
            this.log(`Component '${name}' nu a fost găsit`, 'error');
            return false;
        }

        if (comp.element) {
            comp.element.style.display = 'block';
        }

        comp.visible = true;
        this.log(`Component '${name}' afișat`, 'debug');
        return true;
    }

    /**
     * Ascunde component
     */
    public hideComponent(name: string): boolean {
        const comp = this.components.get(name);

        if (!comp) {
            this.log(`Component '${name}' nu a fost găsit`, 'error');
            return false;
        }

        if (comp.element) {
            comp.element.style.display = 'none';
        }

        comp.visible = false;
        this.log(`Component '${name}' ascuns`, 'debug');
        return true;
    }

    /**
     * Cleanup component
     */
    public async destroyComponent(name: string): Promise<boolean> {
        const comp = this.components.get(name);

        if (!comp) {
            this.log(`Component '${name}' nu a fost găsit`, 'error');
            return false;
        }

        try {
            if (comp.cleanup) {
                await comp.cleanup();
            }

            if (comp.element) {
                comp.element.remove();
            }

            this.components.delete(name);
            this.log(`Component '${name}' distrus`, 'info');
            return true;
        } catch (error) {
            this.log(`Distrugere eșuată pentru '${name}': ${error}`, 'error');
            return false;
        }
    }

    /**
     * Process render queue în batch
     */
    private processRenderQueue(): void {
        if (this.renderQueue.length === 0) return;

        setTimeout(() => {
            const toRender = [...this.renderQueue];
            this.renderQueue = [];

            toRender.forEach(name => {
                const comp = this.components.get(name);
                if (comp && comp.visible) {
                    // Trigger render
                    this.log(`Rendering component: ${name}`, 'debug');
                }
            });
        }, this.config.renderDelay);
    }

    /**
     * Get component status
     */
    public getComponentStatus(): Record<string, any> {
        const status: Record<string, any> = {};

        this.components.forEach((comp, name) => {
            status[name] = {
                framework: comp.framework,
                visible: comp.visible,
                initialized: comp.instance !== undefined
            };
        });

        return status;
    }

    /**
     * Cleanup all components
     */
    public async cleanup(): Promise<void> {
        const names = Array.from(this.components.keys());

        for (const name of names) {
            await this.destroyComponent(name);
        }

        this.log('UIManager cleanup complet', 'info');
    }

    /**
     * Internal logging
     */
    private log(message: string, level: 'debug' | 'info' | 'warn' | 'error' = 'info'): void {
        if (!this.config.enableLogging && level === 'debug') return;

        const timestamp = new Date().toLocaleTimeString();
        const prefix = `[ReWork UI - ${timestamp}]`;

        switch (level) {
            case 'debug':
                console.log(`%c${prefix} ${message}`, 'color: gray');
                break;
            case 'info':
                console.log(`%c${prefix} ${message}`, 'color: blue');
                break;
            case 'warn':
                console.warn(`%c${prefix} ${message}`, 'color: orange');
                break;
            case 'error':
                console.error(`%c${prefix} ${message}`, 'color: red');
                break;
        }
    }
}

export default UIManager;
