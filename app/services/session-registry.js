/**
 * Session Registry — in-memory store for session runtime config.
 * No user identity or payment data. sessionId is the only key.
 * Used to route VNC, terminal, and API requests to the correct isolated runtime.
 */

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

class SessionRegistry {
    constructor() {
        /** @type {Map<string, SessionRecord>} */
        this._sessions = new Map();
    }

    /**
     * @param {string} sessionId
     * @param {SessionRecord} record
     */
    set(sessionId, record) {
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
            createdAt: record.createdAt ?? new Date().toISOString(),
            expiresAt: record.expiresAt ?? null,
            ...record
        };
        this._sessions.set(normalized, entry);
        return entry;
    }

    /**
     * @param {string} sessionId
     * @returns {SessionRecord | undefined}
     */
    get(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return undefined;
        return this._sessions.get(sessionId.trim());
    }

    /**
     * @param {string} sessionId
     * @returns {boolean}
     */
    has(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return false;
        return this._sessions.has(sessionId.trim());
    }

    /**
     * Remove session from registry. Idempotent.
     * @param {string} sessionId
     */
    delete(sessionId) {
        if (!sessionId || typeof sessionId !== 'string') return false;
        return this._sessions.delete(sessionId.trim());
    }

    /**
     * Update session state.
     * @param {string} sessionId
     * @param {string} state
     */
    setState(sessionId, state) {
        const s = this.get(sessionId);
        if (!s) return false;
        s.state = state;
        return true;
    }

    /**
     * @returns {string[]} sessionIds
     */
    listSessionIds() {
        return Array.from(this._sessions.keys());
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
}

/** @typedef {{
 *   sessionId: string;
 *   state?: string;
 *   vnc: { host: string; port: number; password?: string };
 *   ssh: { host: string; port: number; username: string; password: string };
 *   createdAt?: string;
 *   expiresAt?: string | null;
 * }} SessionRecord */

module.exports = { SessionRegistry, SESSION_STATES };
