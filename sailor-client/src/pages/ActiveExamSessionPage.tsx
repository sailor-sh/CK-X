import { useCallback, useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api, ApiError } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'
import type { ExamSession } from '../types/sailor'

function msToClock(ms: number) {
  const s = Math.max(0, Math.floor(ms / 1000))
  const hh = Math.floor(s / 3600)
  const mm = Math.floor((s % 3600) / 60)
  const ss = s % 60
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${pad(hh)}:${pad(mm)}:${pad(ss)}`
}

type LaunchState = 'idle' | 'loading' | 'launched' | 'error'

export function ActiveExamSessionPage() {
  const { examSessionId } = useParams()
  const nav = useNavigate()
  const { state } = useAuth()
  const token = state.status === 'authenticated' ? state.token : ''

  const [session, setSession] = useState<ExamSession | null>(null)
  const [allowed, setAllowed] = useState<boolean | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [now, setNow] = useState<number>(() => Date.now())

  // New-tab launch state
  const [launchState, setLaunchState] = useState<LaunchState>('idle')
  const [launchError, setLaunchError] = useState<string | null>(null)
  const [labWindowRef, setLabWindowRef] = useState<Window | null>(null)

  // Timer for countdown
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000)
    return () => clearInterval(t)
  }, [])

  // Load session data
  useEffect(() => {
    if (!examSessionId) return
    const run = async () => {
      setError(null)
      setAllowed(null)
      try {
        const s = await api.get<{ session: ExamSession }>(`/exam-sessions/${encodeURIComponent(examSessionId)}`, {
          token,
        })
        setSession(s.session)

        // Safe resume: always re-validate access right before connecting
        await api.get(`/exam-sessions/${encodeURIComponent(examSessionId)}/access`, { token })
        setAllowed(true)
      } catch (e) {
        setAllowed(false)
        setError(e instanceof ApiError ? e.message : 'Unexpected error')
      }
    }
    run()
  }, [examSessionId, token])

  // Poll session status to update UI if session ends
  useEffect(() => {
    if (!examSessionId || !allowed) return
    const poll = setInterval(async () => {
      try {
        const s = await api.get<{ session: ExamSession }>(`/exam-sessions/${encodeURIComponent(examSessionId)}`, {
          token,
        })
        setSession(s.session)
        
        // If session is no longer active, update UI
        if (s.session.status !== 'ACTIVE') {
          setAllowed(false)
          setError(`Session ${s.session.status.toLowerCase()}`)
        }
      } catch (e) {
        // Don't update error on poll failure - might just be network hiccup
        console.warn('Session poll failed:', e)
      }
    }, 10000) // Poll every 10 seconds
    
    return () => clearInterval(poll)
  }, [examSessionId, token, allowed])

  const endsAtMs = useMemo(() => {
    if (!session?.endsAt) return null
    return new Date(session.endsAt).getTime()
  }, [session?.endsAt])

  const remainingMs = endsAtMs == null ? null : Math.max(0, endsAtMs - now)

  const ckxSessionId = session?.ckxSessionId ?? null

  /**
   * Open the lab in a new browser tab.
   * 1. Request a launch token from Sailor API
   * 2. Open the launch URL in a new tab
   * 3. CKX validates the token and establishes a session
   */
  const openLabInNewTab = useCallback(async () => {
    if (!examSessionId || !ckxSessionId) return

    setLaunchState('loading')
    setLaunchError(null)

    try {
      // Get launch token from Sailor API
      const response = await api.post<{ launchUrl: string; launchToken: string; expiresIn: number }>(
        `/exam-sessions/${encodeURIComponent(examSessionId)}/launch-token`,
        {},
        { token }
      )

      // Open the launch URL in a new tab
      const newWindow = window.open(response.launchUrl, '_blank', 'noopener')
      
      if (newWindow) {
        setLabWindowRef(newWindow)
        setLaunchState('launched')
      } else {
        // Pop-up was blocked
        setLaunchError('Pop-up blocked. Please allow pop-ups for this site and try again.')
        setLaunchState('error')
      }
    } catch (e) {
      const message = e instanceof ApiError ? e.message : 'Failed to open lab'
      setLaunchError(message)
      setLaunchState('error')
      console.error('Lab launch failed:', e)
    }
  }, [examSessionId, ckxSessionId, token])

  /**
   * Check if the lab window is still open.
   */
  const isLabWindowOpen = useMemo(() => {
    return labWindowRef !== null && !labWindowRef.closed
  }, [labWindowRef])

  // Periodically check if lab window is still open
  useEffect(() => {
    if (!labWindowRef) return
    const check = setInterval(() => {
      if (labWindowRef.closed) {
        setLabWindowRef(null)
        setLaunchState('idle')
      }
    }, 1000)
    return () => clearInterval(check)
  }, [labWindowRef])

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
          <div style={{ fontWeight: 800 }}>Lab Environment</div>
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
            No lab session attached. This usually means provisioning failed or the session is not active.
          </div>
        ) : (
          <div className="stack" style={{ gap: 16 }}>
            {/* Launch status */}
            {launchState === 'launched' && isLabWindowOpen && (
              <div className="card" style={{ borderColor: '#bbf7d0', background: '#f0fdf4' }}>
                <div style={{ color: '#166534', fontWeight: 800 }}>Lab is open in another tab</div>
                <div style={{ color: '#166534' }}>
                  Your lab environment is running in a separate browser tab.
                  You can switch between this dashboard and the lab tab freely.
                </div>
              </div>
            )}

            {launchState === 'error' && launchError && (
              <div className="card" style={{ borderColor: '#fecaca', background: '#fef2f2' }}>
                <div style={{ color: '#991b1b', fontWeight: 800 }}>Failed to open lab</div>
                <div style={{ color: '#991b1b' }}>{launchError}</div>
              </div>
            )}

            {/* Launch buttons */}
            <div className="row" style={{ gap: 12 }}>
              <button
                className="btn primary"
                disabled={launchState === 'loading'}
                onClick={openLabInNewTab}
                style={{ minWidth: 160 }}
              >
                {launchState === 'loading' ? 'Opening…' : 
                 isLabWindowOpen ? 'Open Lab Again' : 'Open Lab'}
              </button>

              {isLabWindowOpen && (
                <button
                  className="btn secondary"
                  onClick={() => labWindowRef?.focus()}
                >
                  Focus Lab Tab
                </button>
              )}
            </div>

            {/* Instructions */}
            <div className="muted" style={{ fontSize: 13 }}>
              <p style={{ margin: 0 }}>
                Click <strong>Open Lab</strong> to launch the lab environment in a new browser tab.
                The lab runs independently — you can switch between this dashboard and the lab freely.
              </p>
              <ul style={{ margin: '8px 0 0 0', paddingLeft: 20 }}>
                <li>Your session persists even if you close the lab tab</li>
                <li>You can re-open the lab any time before the timer expires</li>
                <li>This dashboard shows your remaining time and session status</li>
              </ul>
            </div>
          </div>
        )}
      </div>

      <div className="card stack">
        <div style={{ fontWeight: 800 }}>Session Info</div>
        <div className="muted" style={{ fontSize: 13 }}>
          <div><strong>Session ID:</strong> {examSessionId ?? '—'}</div>
          <div><strong>Lab ID:</strong> {ckxSessionId ?? '—'}</div>
          <div><strong>Started:</strong> {session?.startedAt ? new Date(session.startedAt).toLocaleString() : '—'}</div>
          <div><strong>Ends:</strong> {session?.endsAt ? new Date(session.endsAt).toLocaleString() : '—'}</div>
        </div>
      </div>
    </div>
  )
}
