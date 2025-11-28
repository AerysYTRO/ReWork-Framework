/**
 * Example Authentication Module
 * Demonstrează cum să se creeze un modul reusable
 */

import { ModuleInterface } from '../core/Framework';

class AuthModule implements ModuleInterface {
    public name = 'auth';
    public enabled = false;

    private isAuthenticated = false;
    private playerData: any = null;

    async initialize(): Promise<void> {
        console.log('[Auth Module] Initializing authentication module');
        
        // Setup RPC handlers
        const framework = window.ReWork;
        
        framework.rpcOn('auth:login', (credentials, respond) => {
            this.handleLogin(credentials, respond);
        });

        framework.rpcOn('auth:logout', (data, respond) => {
            this.handleLogout(respond);
        });

        framework.rpcOn('auth:getPlayer', (data, respond) => {
            this.handleGetPlayer(respond);
        });

        console.log('[Auth Module] Authentication module ready');
    }

    async cleanup(): Promise<void> {
        console.log('[Auth Module] Cleaning up authentication module');
        this.isAuthenticated = false;
        this.playerData = null;
    }

    private async handleLogin(credentials: any, respond: Function): Promise<void> {
        try {
            const framework = window.ReWork;
            
            // Validate input
            if (!credentials.username || !credentials.password) {
                respond({ success: false, error: 'Missing credentials' });
                return;
            }

            // Call server authentication
            const response = await framework.rpcCall('auth:validateCredentials', credentials);

            if (response.success) {
                this.isAuthenticated = true;
                this.playerData = response.player;
                
                // Trigger local event
                framework.emit('auth:loggedIn', response.player);
                
                respond({ success: true, player: response.player });
            } else {
                respond({ success: false, error: response.error });
            }
        } catch (error) {
            console.error('[Auth Module] Login error:', error);
            respond({ success: false, error: 'Login failed' });
        }
    }

    private async handleLogout(respond: Function): Promise<void> {
        const framework = window.ReWork;
        
        this.isAuthenticated = false;
        this.playerData = null;
        
        framework.emit('auth:loggedOut');
        respond({ success: true });
    }

    private handleGetPlayer(respond: Function): void {
        if (this.isAuthenticated && this.playerData) {
            respond({ success: true, player: this.playerData });
        } else {
            respond({ success: false, error: 'Not authenticated' });
        }
    }

    public isLoggedIn(): boolean {
        return this.isAuthenticated;
    }

    public getPlayer(): any {
        return this.playerData;
    }
}

export default AuthModule;
