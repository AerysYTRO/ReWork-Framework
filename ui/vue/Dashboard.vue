<template>
    <div class="dashboard-container">
        <div class="dashboard-header">
            <h1>📊 Dashboard</h1>
            <p class="subtitle">Welcome {{ username }}</p>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">💰</div>
                <div class="stat-info">
                    <h3>Balance</h3>
                    <p class="stat-value">${{ balance }}</p>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">⭐</div>
                <div class="stat-info">
                    <h3>Level</h3>
                    <p class="stat-value">{{ level }}</p>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">🎯</div>
                <div class="stat-info">
                    <h3>Experience</h3>
                    <p class="stat-value">{{ experience }}%</p>
                </div>
            </div>

            <div class="stat-card">
                <div class="stat-icon">🏆</div>
                <div class="stat-info">
                    <h3>Rank</h3>
                    <p class="stat-value">{{ rank }}</p>
                </div>
            </div>
        </div>

        <div class="actions">
            <button @click="refreshData" class="btn btn-primary">
                🔄 Refresh
            </button>
            <button @click="logout" class="btn btn-danger">
                🚪 Logout
            </button>
        </div>

        <div v-if="error" class="error-box">
            {{ error }}
        </div>

        <div v-if="success" class="success-box">
            {{ success }}
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
    name: 'Dashboard',
    data() {
        return {
            username: 'Player',
            balance: 0,
            level: 1,
            experience: 0,
            rank: 'Newbie',
            error: '',
            success: ''
        };
    },
    methods: {
        async refreshData() {
            try {
                // Fetch data from server
                this.success = 'Data refreshed!';
                setTimeout(() => {
                    this.success = '';
                }, 3000);
            } catch (err) {
                this.error = 'Failed to refresh data';
            }
        },
        async logout() {
            try {
                // Call logout RPC
                this.success = 'Logging out...';
            } catch (err) {
                this.error = 'Logout failed';
            }
        }
    },
    mounted() {
        console.log('[Dashboard] Component mounted');
    }
});
</script>

<style scoped>
.dashboard-container {
    background: white;
    border-radius: 10px;
    padding: 30px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.dashboard-header {
    text-align: center;
    margin-bottom: 30px;
    border-bottom: 2px solid #667eea;
    padding-bottom: 20px;
}

.dashboard-header h1 {
    color: #333;
    font-size: 2rem;
    margin-bottom: 10px;
}

.subtitle {
    color: #666;
    font-size: 1.1rem;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.stat-card {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 10px;
    padding: 20px;
    color: white;
    display: flex;
    align-items: center;
    gap: 15px;
    transition: transform 0.3s ease;
}

.stat-card:hover {
    transform: translateY(-5px);
}

.stat-icon {
    font-size: 2rem;
}

.stat-info h3 {
    font-size: 0.9rem;
    opacity: 0.9;
    margin-bottom: 5px;
}

.stat-value {
    font-size: 1.8rem;
    font-weight: bold;
}

.actions {
    display: flex;
    gap: 10px;
    justify-content: center;
    margin-bottom: 20px;
}

.btn {
    padding: 10px 20px;
    border: none;
    border-radius: 5px;
    font-size: 1rem;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: bold;
}

.btn-primary {
    background: #667eea;
    color: white;
}

.btn-primary:hover {
    background: #5568d3;
    transform: scale(1.05);
}

.btn-danger {
    background: #f44336;
    color: white;
}

.btn-danger:hover {
    background: #da190b;
    transform: scale(1.05);
}

.error-box {
    background: #f44336;
    color: white;
    padding: 15px;
    border-radius: 5px;
    margin-top: 20px;
}

.success-box {
    background: #4caf50;
    color: white;
    padding: 15px;
    border-radius: 5px;
    margin-top: 20px;
}

@media (max-width: 768px) {
    .dashboard-container {
        padding: 20px;
    }

    .stats-grid {
        grid-template-columns: 1fr;
    }

    .actions {
        flex-direction: column;
    }
}
</style>
