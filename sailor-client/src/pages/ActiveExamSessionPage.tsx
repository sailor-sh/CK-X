import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api, ApiError } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'
import type { ExamSession } from '../types/sailor'

const API_BASE = (import.meta as any).env?.VITE_SAILOR_API_BASE ?? 'http://localhost:4000'

function msToClock(ms: number) {
  const s = Math.max(0, Math.floor(ms / 1000))
  const hh = Math.floor(s / 3600)
  const mm = Math.floor((s % 3600) / 60)
  const ss = s % 60
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${pad(hh)}:${pad(mm)}:${pad(ss)}`
}

export function ActiveExamSessionPage() {
  const { examSessionId } = useParams()
  const nav = useNavigate()
  const { state } = useAuth()
  const token = state.status === 'authenticated' ? state.token : ''

  const [session, setSession] = useState<ExamSession | null>(null)
  const [allowed, setAllowed] = useState<boolean | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [now, setNow] = useState<number>(() => Date.now())
  const [iframeToken, setIframeToken] = useState<string | null>(null)
  const [iframeTokenError, setIframeTokenError] = useState<string | null>(null)

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(t)
  }, [])

  useEffect(() => {
    if (!examSessionId) return
    const run = async () => {
      setError(null)
      setAllowed(null)
      setIframeTokenError(null)
      try {
        const s = await api.get<{ session: ExamSession }>(`/exam-sessions/${encodeURIComponent(examSessionId)}`, {
          token,
        })
        setSession(s.session)

        // Safe resume: always re-validate access right before connecting
        await api.get(`/exam-sessions/${encodeURIComponent(examSessionId)}/access`, { token })
        setAllowed(true)

        // Fetch iframe token for VNC access
        if (s.session.ckxSessionId) {
          try {
            const tokenResponse = await api.get<{ iframeToken: string; expiresIn: number }>(
              `/exam-sessions/${encodeURIComponent(examSessionId)}/iframe-token`,
              { token }
            )
            setIframeToken(tokenResponse.iframeToken)
            setIframeTokenError(null)
          } catch (e) {
            setIframeTokenError(e instanceof ApiError ? e.message : 'Failed to get iframe token')
            console.error('Iframe token fetch failed:', e)
          }
        }
      } catch (e) {
        setAllowed(false)
        setError(e instanceof ApiError ? e.message : 'Unexpected error')
      }
    }
    run()
  }, [examSessionId, token])

  const endsAtMs = useMemo(() => {
    if (!session?.endsAt) return null
    return new Date(session.endsAt).getTime()
  }, [session?.endsAt])

  const remainingMs = endsAtMs == null ? null : Math.max(0, endsAtMs - now)

  const ckxSessionId = session?.ckxSessionId ?? null
  const vncSrc = useMemo(() => {
    if (!ckxSessionId || !iframeToken) return null
    const params = new URLSearchParams({
      iframeToken: iframeToken,
      autoconnect: 'true',
      resize: 'scale',
      show_dot: 'true',
      reconnect: 'true',
    })
    return `${API_BASE}/ckx/sessions/${encodeURIComponent(ckxSessionId)}/vnc-proxy/?${params.toString()}`
  }, [ckxSessionId, iframeToken])

  return (
    <div className="container stack">
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <div className="stack" style={{ gap: 4 }}>
          <h2 style={{ margin: 0 }}>{session?.exam?.name ?? 'Exam session'}</h2>
          <div className="muted">
            Mode: {session?.mode ?? 'FULL'} · Status: {session?.status ?? '—'}
          </div>
        </div>

        <div className="row">
          {remainingMs != null && (
            <div className="card" style={{ padding: '10px 12px' }}>
              <div className="muted" style={{ fontSize: 12 }}>
                Time remaining
              </div>
              <div style={{ fontWeight: 900, fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas' }}>
                {msToClock(remainingMs)}
              </div>
            </div>
          )}

          {session?.exam?.id && (
            <Link className="btn secondary" to={`/results/${session.exam.id}`}>
              Results
            </Link>
          )}
        </div>
      </div>

      {error && (
        <div className="card" style={{ borderColor: '#fecaca', background: '#fef2f2' }}>
          <div style={{ color: '#991b1b', fontWeight: 800 }}>Access blocked</div>
          <div style={{ color: '#991b1b' }}>{error}</div>
          <div className="muted" style={{ marginTop: 8 }}>
            If your time expired or entitlement ended, access is revoked automatically.
          </div>
        </div>
      )}

      <div className="card stack">
        <div className="row" style={{ justifyContent: 'space-between' }}>
          <div style={{ fontWeight: 800 }}>Remote desktop (VNC)</div>
          <div className="row">
            <button
              className="btn secondary"
              disabled={!examSessionId}
              onClick={async () => {
                if (!examSessionId) return
                await api.post(`/exam-sessions/${encodeURIComponent(examSessionId)}/end`, {}, { token })
                nav('/dashboard')
              }}
            >
              End session
            </button>
          </div>
        </div>

        {allowed !== true ? (
          <div className="muted">Validating access…</div>
        ) : !ckxSessionId ? (
          <div className="muted">
            No CKX session id attached. This usually means provisioning failed or the session is not active.
          </div>
        ) : iframeTokenError ? (
          <div className="card" style={{ borderColor: '#fecaca', background: '#fef2f2' }}>
            <div style={{ color: '#991b1b', fontWeight: 800 }}>Failed to load VNC</div>
            <div style={{ color: '#991b1b' }}>{iframeTokenError}</div>
            <button
              className="btn secondary"
              style={{ marginTop: 8 }}
              onClick={async () => {
                if (!examSessionId) return
                try {
                  const tokenResponse = await api.get<{ iframeToken: string }>(
                    `/exam-sessions/${encodeURIComponent(examSessionId)}/iframe-token`,
                    { token }
                  )
                  setIframeToken(tokenResponse.iframeToken)
                  setIframeTokenError(null)
                } catch (e) {
                  setIframeTokenError(e instanceof ApiError ? e.message : 'Failed to get iframe token')
                }
              }}
            >
              Retry
            </button>
          </div>
        ) : !iframeToken ? (
          <div className="muted">Loading VNC access token…</div>
        ) : !vncSrc ? (
          <div className="muted">Preparing VNC connection…</div>
        ) : (
          <>
            <div className="muted" style={{ fontSize: 13 }}>
              This iframe loads the lab environment through <b>Sailor API only</b>. It must proxy to CKX; the client
              never calls CKX directly.
            </div>
            <iframe
              title="Exam environment"
              src={vncSrc}
              style={{
                width: '100%',
                height: '70vh',
                border: '1px solid #e2e8f0',
                borderRadius: 12,
                background: '#0b1220',
              }}
            />
            <div className="muted" style={{ fontSize: 12 }}>
              If you refresh, we re-check `/exam-sessions/:id/access` before reconnecting (safe resume).
            </div>
          </>
        )}
      </div>

      <div className="card stack">
        <div style={{ fontWeight: 800 }}>Terminal</div>
        <div className="muted">
          Terminal access must also be proxied via Sailor API (never CKX directly). Hook this up to a Sailor API WebSocket
          proxy for CKX `/ssh` once available.
        </div>
      </div>
    </div>
  )
}

