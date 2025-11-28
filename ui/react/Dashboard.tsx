import React, { useState, useEffect } from 'react';

interface DashboardProps {
    user?: {
        id: number;
        username: string;
        level: number;
    };
}

const Dashboard: React.FC<DashboardProps> = ({ user }) => {
    const [balance, setBalance] = useState<number>(0);
    const [level, setLevel] = useState<number>(1);
    const [experience, setExperience] = useState<number>(0);
    const [rank, setRank] = useState<string>('Newbie');
    const [error, setError] = useState<string>('');
    const [success, setSuccess] = useState<string>('');
    const [loading, setLoading] = useState<boolean>(false);

    useEffect(() => {
        console.log('[Dashboard] Component mounted');
        loadDashboardData();
    }, []);

    const loadDashboardData = async () => {
        setLoading(true);
        try {
            // In a real implementation, this would call the framework's RPC
            // const response = await window.ReWork.rpcCall('GetDashboardData', {});
            // Process response...
            setLoading(false);
        } catch (err) {
            setError('Failed to load dashboard data');
            setLoading(false);
        }
    };

    const refreshData = async () => {
        try {
            setSuccess('Data refreshed!');
            setTimeout(() => setSuccess(''), 3000);
        } catch (err) {
            setError('Failed to refresh data');
        }
    };

    const logout = async () => {
        try {
            setSuccess('Logging out...');
        } catch (err) {
            setError('Logout failed');
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.header}>
                <h1>📊 Dashboard</h1>
                <p style={styles.subtitle}>
                    Welcome {user?.username || 'Player'}
                </p>
            </div>

            <div style={styles.statsGrid}>
                <div style={styles.statCard}>
                    <div style={styles.statIcon}>💰</div>
                    <div style={styles.statInfo}>
                        <h3>Balance</h3>
                        <p style={styles.statValue}>${balance}</p>
                    </div>
                </div>

                <div style={styles.statCard}>
                    <div style={styles.statIcon}>⭐</div>
                    <div style={styles.statInfo}>
                        <h3>Level</h3>
                        <p style={styles.statValue}>{level}</p>
                    </div>
                </div>

                <div style={styles.statCard}>
                    <div style={styles.statIcon}>🎯</div>
                    <div style={styles.statInfo}>
                        <h3>Experience</h3>
                        <p style={styles.statValue}>{experience}%</p>
                    </div>
                </div>

                <div style={styles.statCard}>
                    <div style={styles.statIcon}>🏆</div>
                    <div style={styles.statInfo}>
                        <h3>Rank</h3>
                        <p style={styles.statValue}>{rank}</p>
                    </div>
                </div>
            </div>

            <div style={styles.actions}>
                <button 
                    style={styles.btnPrimary}
                    onClick={refreshData}
                    disabled={loading}
                >
                    🔄 Refresh
                </button>
                <button 
                    style={styles.btnDanger}
                    onClick={logout}
                >
                    🚪 Logout
                </button>
            </div>

            {error && (
                <div style={styles.errorBox}>
                    {error}
                </div>
            )}

            {success && (
                <div style={styles.successBox}>
                    {success}
                </div>
            )}
        </div>
    );
};

const styles: { [key: string]: React.CSSProperties } = {
    container: {
        background: 'white',
        borderRadius: '10px',
        padding: '30px',
        boxShadow: '0 10px 30px rgba(0, 0, 0, 0.2)'
    },
    header: {
        textAlign: 'center',
        marginBottom: '30px',
        borderBottom: '2px solid #667eea',
        paddingBottom: '20px'
    },
    title: {
        color: '#333',
        fontSize: '2rem',
        marginBottom: '10px'
    },
    subtitle: {
        color: '#666',
        fontSize: '1.1rem'
    },
    statsGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '20px',
        marginBottom: '30px'
    },
    statCard: {
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        borderRadius: '10px',
        padding: '20px',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        gap: '15px',
        cursor: 'pointer',
        transition: 'transform 0.3s ease'
    },
    statIcon: {
        fontSize: '2rem'
    },
    statInfo: {
        flex: 1
    },
    statValue: {
        fontSize: '1.8rem',
        fontWeight: 'bold',
        marginTop: '5px'
    },
    actions: {
        display: 'flex',
        gap: '10px',
        justifyContent: 'center',
        marginBottom: '20px'
    },
    btnPrimary: {
        padding: '10px 20px',
        background: '#667eea',
        color: 'white',
        border: 'none',
        borderRadius: '5px',
        fontSize: '1rem',
        cursor: 'pointer',
        fontWeight: 'bold',
        transition: 'all 0.3s ease'
    },
    btnDanger: {
        padding: '10px 20px',
        background: '#f44336',
        color: 'white',
        border: 'none',
        borderRadius: '5px',
        fontSize: '1rem',
        cursor: 'pointer',
        fontWeight: 'bold',
        transition: 'all 0.3s ease'
    },
    errorBox: {
        background: '#f44336',
        color: 'white',
        padding: '15px',
        borderRadius: '5px',
        marginTop: '20px'
    },
    successBox: {
        background: '#4caf50',
        color: 'white',
        padding: '15px',
        borderRadius: '5px',
        marginTop: '20px'
    }
};

export default Dashboard;
