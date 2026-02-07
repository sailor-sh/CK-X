/**
 * Redis Client for CKX Session Management
 * 
 * Provides Redis connectivity for session storage in production.
 * Falls back to in-memory storage for development/testing.
 */

const Redis = require('ioredis');

class RedisClient {
    constructor() {
        this._client = null;
        this._connected = false;
        this._useMemoryFallback = false;
        this._memoryStore = new Map();
    }

    /**
     * Initialize Redis connection
     */
    async connect() {
        const redisUrl = process.env.REDIS_URL;
        const redisHost = process.env.REDIS_HOST || 'localhost';
        const redisPort = parseInt(process.env.REDIS_PORT || '6379', 10);

        // Skip Redis in development if not configured
        if (process.env.NODE_ENV !== 'production' && !redisUrl && !process.env.REDIS_HOST) {
            console.log('[Redis] No Redis configured, using in-memory fallback');
            this._useMemoryFallback = true;
            return;
        }

        try {
            if (redisUrl) {
                this._client = new Redis(redisUrl);
            } else {
                this._client = new Redis({
                    host: redisHost,
                    port: redisPort,
                    retryStrategy: (times) => {
                        if (times > 3) {
                            console.warn('[Redis] Max retries reached, using in-memory fallback');
                            this._useMemoryFallback = true;
                            return null; // Stop retrying
                        }
                        return Math.min(times * 100, 3000);
                    }
                });
            }

            this._client.on('connect', () => {
                console.log('[Redis] Connected successfully');
                this._connected = true;
            });

            this._client.on('error', (err) => {
                console.error('[Redis] Connection error:', err.message);
                if (!this._connected) {
                    this._useMemoryFallback = true;
                }
            });

            this._client.on('close', () => {
                console.log('[Redis] Connection closed');
                this._connected = false;
            });

            // Test connection
            await this._client.ping();
            this._connected = true;

        } catch (error) {
            console.warn('[Redis] Failed to connect:', error.message);
            console.log('[Redis] Using in-memory fallback');
            this._useMemoryFallback = true;
        }
    }

    /**
     * Check if using memory fallback
     */
    isMemoryFallback() {
        return this._useMemoryFallback;
    }

    /**
     * Get a value by key
     */
    async get(key) {
        if (this._useMemoryFallback) {
            return this._memoryStore.get(key) || null;
        }
        const value = await this._client.get(key);
        return value ? JSON.parse(value) : null;
    }

    /**
     * Set a value with optional TTL (in seconds)
     */
    async set(key, value, ttlSeconds = null) {
        if (this._useMemoryFallback) {
            this._memoryStore.set(key, value);
            if (ttlSeconds) {
                setTimeout(() => this._memoryStore.delete(key), ttlSeconds * 1000);
            }
            return 'OK';
        }
        const serialized = JSON.stringify(value);
        if (ttlSeconds) {
            return this._client.setex(key, ttlSeconds, serialized);
        }
        return this._client.set(key, serialized);
    }

    /**
     * Delete a key
     */
    async del(key) {
        if (this._useMemoryFallback) {
            return this._memoryStore.delete(key) ? 1 : 0;
        }
        return this._client.del(key);
    }

    /**
     * Check if key exists
     */
    async exists(key) {
        if (this._useMemoryFallback) {
            return this._memoryStore.has(key) ? 1 : 0;
        }
        return this._client.exists(key);
    }

    /**
     * Get all keys matching pattern
     */
    async keys(pattern) {
        if (this._useMemoryFallback) {
            const regex = new RegExp('^' + pattern.replace('*', '.*') + '$');
            return Array.from(this._memoryStore.keys()).filter(k => regex.test(k));
        }
        return this._client.keys(pattern);
    }

    /**
     * Get multiple values
     */
    async mget(keys) {
        if (this._useMemoryFallback) {
            return keys.map(k => this._memoryStore.get(k) || null);
        }
        const values = await this._client.mget(keys);
        return values.map(v => v ? JSON.parse(v) : null);
    }

    /**
     * Close connection
     */
    async close() {
        if (this._client && !this._useMemoryFallback) {
            await this._client.quit();
        }
    }
}

// Singleton instance
const redisClient = new RedisClient();

module.exports = redisClient;
