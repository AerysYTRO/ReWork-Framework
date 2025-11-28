/**
 * ReWork Framework - Client Entry Point
 * Inițializează framework-ul pe client-side
 */

import ReWorkFramework, { RPCService, Logger } from './core/Framework';
import UIManager from './core/UIManager';

// Initialize framework
const framework = ReWorkFramework.getInstance({
    debug: true,
    logLevel: 'INFO',
    performanceMonitoring: true
});

const uiManager = UIManager.getInstance({
    autoInitialize: true,
    enableLogging: true
});

// Make global
declare global {
    interface Window {
        ReWork: typeof framework;
        ReWorkUI: typeof uiManager;
    }
}

window.ReWork = framework;
window.ReWorkUI = uiManager;

console.log('%c[ReWork] Framework v1.0.0 inițializat pe client', 'color: green; font-weight: bold;');

/**
 * Exemplu - Test RPC call la server
 */
async function testRPC() {
    try {
        const response = await framework.rpcCall('TestRPC', {
            message: 'Hello from client'
        });
        
        console.log('[ReWork] Răspuns din server:', response);
    } catch (error) {
        console.error('[ReWork] RPC Error:', error);
    }
}

/**
 * Exemplu - Registrare RPC handler din server
 */
framework.rpcOn('PlayerUpdate', (data, respond) => {
    console.log('[ReWork] PlayerUpdate din server:', data);
    // Răspunde la server
    respond({ received: true });
});

// Setup initial listeners
on('onClientResourceStart', async (resourceName: string) => {
    if (resourceName === GetCurrentResourceName()) {
        console.log('[ReWork] Resource started:', resourceName);
        
        // Exemplu: Test RPC la 2 secunde
        setTimeout(() => {
            testRPC();
        }, 2000);
    }
});

on('onClientResourceStop', async (resourceName: string) => {
    if (resourceName === GetCurrentResourceName()) {
        console.log('[ReWork] Cleanup...');
        await framework.cleanup();
        await uiManager.cleanup();
    }
});

export { framework, uiManager };
