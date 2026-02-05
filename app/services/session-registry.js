/**
 * Session Registry — persistent store for session runtime config.
 * No user identity or payment data. sessionId is the only key.
 * Used to route VNC, terminal, and API requests to the correct isolated runtime.
 * 
 * Supports both in-memory (development) and Redis (production) backends.
 */

const crypto = require('crypto');

const SESSION_STATES = Object.freeze({
    REQUESTED: 'requested',
    PROVISIONING: 'provisioning',
    READY: 'ready',
    ACTIVE: 'active',
    ENDING: 'ending',
    RELEASED: 'released',
    FAILED: 'failed',
    CANCELLED: 'cancelled',
    EXPIRED: 'expired'
});

const SESSION_KEY_PREFIX = 'ckx:session:';
const SESSION_TTL_SECONDS = 24 * 60 * 60; // 24 hours

class SessionRegistry {
    constructor() {
        /** @type {Map<string, SessionRecord>} In-memory cache */
        this._cache = new Map();
        /** @type {import('../utils/redis-client')|null} */
        this._redis = null;
        this._useRedis = false;
    }

    /**
     * Initialize with Redis client (optional)
     * @param {import('../utils/redis-client')} redisClient
     */
    async initialize(redisClient = null) {
        if (redisClient && !redisClient.isMemoryFallback()) {
            this._redis = redisClient;
            this._useRedis = true;
            console.log('[SessionRegistry] Using Redis backend');
            
            // Load existing sessions from Redis into cache
            await this._loadFromRedis();
        } else {
            console.log('[SessionRegistry] Using in-memory backend');
        }
    }

    /**
     * Load sessions from Redis into cache
     */
    async _loadFromRedis() {
        if (!this._useRedis) return;
        
        try {
            const keys = await this._redis.keys(`${SESSION_KEY_PREFIX}*`);
            if (keys.length > 0) {
                const sessions = await this._redis.mget(keys);
                sessions.forEach((session, i) => {
                    if (session) {
                        this._cache.set(session.sessionId, session);
                    }
                });
                console.log(`[SessionRegistry] Loaded ${this._cache.size} sessions from Redis`);
            }
        } catch (error) {
            console.error('[SessionRegistry] Failed to load from Redis:', error.message);
        }
    }

    /**
     * Generate session-specific credentials
     * @param {string} sessionId
     * @returns {SessionCredentials}
     */
    static generateCredentials(sessionId) {
        const shortId = sessionId.slice(0, 8);
        return {
            vnc: {
                password: crypto.randomBytes(16).toString('hex'),
            },
            ssh: {
                username: `user-${shortId}`,
                password: crypto.randomBytes(16).toString('hex'),
            },
            kubernetes: {
                namespace: `exam-${shortId}`,
                serviceAccount: `sa-${shortId}`,
            }
        };
    }

    /**
     * @param {string} sessionId
     * @param {SessionRecord} record
     * @param {object} options
     * @param {boolean} options.generateCredentials - Auto-generate session credentials
     */
    async set(sessionId, record, options = {}) {
        if (!sessionId || typeof sessionId !== 'string') {
            throw new Error('sessionId is required and must be a non-empty string');
        }
        const normalized = sessionId.trim();
        if (!normalized) throw new Error('sessionId cannot be blank');

        // Generate credentials if requested and not provided
        let credentials = {};
        if (options.generateCredentials) {
            credentials = SessionRegistry.generateCredentials(normalized);
        }

        const entry = {
            sessionId: normalized,
            state: record.state ?? SESSION_STATES.READY,
            vnc: {
                ...credentials.vnc,
                ...record.vnc,
            },
            ssh: {
                ...credentials.ssh,
                ...record.ssh,
            },
            kubernetes: {
                ...credentials.kubernetes,
                ...record.kubernetes,
            },
            ownerId: record.ownerId || null, // User ID who owns this session
            examSessionId: record.examSessionId || null, // Sailor exam session ID
            createdAt: record.createdAt ?? new Date().toISOString(),
            expiresAt: record.expiresAt ?? null,
        };

        // Store in cache
        this._cache.set(normalized, entry);

        // Persist to Redis
        if (this._useRedis) {
            try {
                await this._redis.set(
                    `${SESSION_KEY_PREFIX}${normalized}`,
                    entry,
                    SESSION_TTL_SECONDS
                );
            } catch (error) {
                console.error('[SessionRegistry] Failed to persist to Redis:', error.message);
            }
        }

        return entry;
    }

    /**
     * Synchronous set for backward compatibility
     * @deprecated Use async set() instead
     */
    setSync(sessionId, record) {
        if (!sessionId || typeof sessionId !== 'string') {
            throw new Error('sessionId is required and must be a non-empty string');
        }
        const normalized = sessionId.trim();
        if (!normalized) throw new Error('sessionId cannot be blank');
        
        const entry = {
            sessionId: normalized,
            state: record.state ?? SESSION_STATES.READY,
            vnc: record.vnc || {},
            ssh: record.ssh || {},
            kubernetes: record.kubernetes || {},
            ownerId: record.ownerId || null,
            examSessionId: record.examSessionId || null,
            createdAt: record.createdAt ?? new Date().toISOString(),
            expiresAt: record.expiresAt ?? null,
            ...record
        };
        
        this._cache.set(normalized, entry);
        
        // Fire and forget Redis persist
        if (this._useRedis) {
            this._redis.set(`${SESSION_KEY_PREFIX}${normalized}`, entry, SESSION_TTL_SECONDS)
                .catch(err => console.error('[SessionRegistry] Redis persist failed:', err.message));
        }
        
        return entry;
    }

    /**
     * @param {string} sessionId
     * @returns {SessionRecord | undefined}
     */
    get(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return undefined;
        return this._cache.get(sessionId.trim());
    }

    /**
     * Async get with Redis fallback
     * @param {string} sessionId
     * @returns {Promise<SessionRecord | undefined>}
     */
    async getAsync(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return undefined;
        const normalized = sessionId.trim();

        // Check cache first
        let session = this._cache.get(normalized);
        if (session) return session;

        // Try Redis
        if (this._useRedis) {
            try {
                session = await this._redis.get(`${SESSION_KEY_PREFIX}${normalized}`);
                if (session) {
                    this._cache.set(normalized, session);
                    return session;
                }
            } catch (error) {
                console.error('[SessionRegistry] Redis get failed:', error.message);
            }
        }

        return undefined;
    }

    /**
     * @param {string} sessionId
     * @returns {boolean}
     */
    has(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return false;
        return this._cache.has(sessionId.trim());
    }

    /**
     * Remove session from registry. Idempotent.
     * @param {string} sessionId
     */
    async delete(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return false;
        const normalized = sessionId.trim();
        
        const existed = this._cache.delete(normalized);

        // Remove from Redis
        if (this._useRedis) {
            try {
                await this._redis.del(`${SESSION_KEY_PREFIX}${normalized}`);
            } catch (error) {
                console.error('[SessionRegistry] Redis delete failed:', error.message);
            }
        }

        return existed;
    }

    /**
     * Synchronous delete for backward compatibility
     * @deprecated Use async delete() instead
     */
    deleteSync(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return false;
        const normalized = sessionId.trim();
        
        const existed = this._cache.delete(normalized);
        
        // Fire and forget Redis delete
        if (this._useRedis) {
            this._redis.del(`${SESSION_KEY_PREFIX}${normalized}`)
                .catch(err => console.error('[SessionRegistry] Redis delete failed:', err.message));
        }
        
        return existed;
    }

    /**
     * Update session state.
     * @param {string} sessionId
     * @param {string} state
     */
    async setState(sessionId, state) {
        const s = this.get(sessionId);
        if (!s) return false;
        
        s.state = state;
        s.updatedAt = new Date().toISOString();

        // Persist to Redis
        if (this._useRedis) {
            try {
                await this._redis.set(
                    `${SESSION_KEY_PREFIX}${sessionId}`,
                    s,
                    SESSION_TTL_SECONDS
                );
            } catch (error) {
                console.error('[SessionRegistry] Redis setState failed:', error.message);
            }
        }

        return true;
    }

    /**
     * Update session with partial data
     * @param {string} sessionId
     * @param {Partial<SessionRecord>} updates
     */
    async update(sessionId, updates) {
        const s = this.get(sessionId);
        if (!s) return null;

        Object.assign(s, updates, { updatedAt: new Date().toISOString() });

        // Persist to Redis
        if (this._useRedis) {
            try {
                await this._redis.set(
                    `${SESSION_KEY_PREFIX}${sessionId}`,
                    s,
                    SESSION_TTL_SECONDS
                );
            } catch (error) {
                console.error('[SessionRegistry] Redis update failed:', error.message);
            }
        }

        return s;
    }

    /**
     * @returns {string[]} sessionIds
     */
    listSessionIds() {
        return Array.from(this._cache.keys());
    }

    /**
     * Get all sessions (for admin/debugging)
     * @returns {SessionRecord[]}
     */
    listSessions() {
        return Array.from(this._cache.values());
    }

    /**
     * Get sessions by owner
     * @param {string} ownerId
     * @returns {SessionRecord[]}
     */
    getByOwner(ownerId) {
        return Array.from(this._cache.values()).filter(s => s.ownerId === ownerId);
    }

    /**
     * Session is valid for routing (ready or active).
     * @param {string} sessionId
     * @returns {boolean}
     */
    isRoutable(sessionId) {
        const s = this.get(sessionId);
        if (!s) return false;
        return s.state === SESSION_STATES.READY || s.state === SESSION_STATES.ACTIVE;
    }

    /**
     * Check if session is owned by user
     * @param {string} sessionId
     * @param {string} userId
     * @returns {boolean}
     */
    isOwnedBy(sessionId, userId) {
        const s = this.get(sessionId);
        if (!s) return false;
        return s.ownerId === userId;
    }

    /**
     * Cleanup expired sessions
     */
    async cleanupExpired() {
        const now = new Date();
        const expired = [];

        for (const [sessionId, session] of this._cache) {
            if (session.expiresAt && new Date(session.expiresAt) < now) {
                expired.push(sessionId);
            }
        }

        for (const sessionId of expired) {
            await this.delete(sessionId);
            console.log(`[SessionRegistry] Cleaned up expired session: ${sessionId}`);
        }

        return expired.length;
    }
}

/** @typedef {{
 *   sessionId: string;
 *   state?: string;
 *   vnc: { host: string; port: number; password?: string };
 *   ssh: { host: string; port: number; username: string; password: string };
 *   kubernetes?: { namespace: string; serviceAccount: string };
 *   ownerId?: string;
 *   examSessionId?: string;
 *   createdAt?: string;
 *   updatedAt?: string;
 *   expiresAt?: string | null;
 * }} SessionRecord */

/** @typedef {{
 *   vnc: { password: string };
 *   ssh: { username: string; password: string };
 *   kubernetes: { namespace: string; serviceAccount: string };
 * }} SessionCredentials */

module.exports = { SessionRegistry, SESSION_STATES };
