import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'
import type { ExamSession } from '../types/sailor'

export function DashboardPage() {
  const { state } = useAuth()
  const token = state.status === 'authenticated' ? state.token : ''
  const [sessions, setSessions] = useState<ExamSession[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await api.get<{ sessions: ExamSession[] }>('/exam-sessions', { token })
        setSessions(res.sessions)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [token])

  const active = useMemo(() => sessions.filter((s) => s.status === 'ACTIVE'), [sessions])

  return (
    <div className="container stack">
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ margin: 0 }}>Dashboard</h2>
          <div className="muted">Resume safely: we re-check access before reconnecting.</div>
        </div>
        <Link className="btn" to="/exams">
          Choose an exam
        </Link>
      </div>

      <div className="card stack">
        <div className="row" style={{ justifyContent: 'space-between' }}>
          <div style={{ fontWeight: 800 }}>Active sessions</div>
          <div className="muted" style={{ fontSize: 14 }}>
            {active.length}
          </div>
        </div>
        {loading ? (
          <div className="muted">Loading…</div>
        ) : active.length === 0 ? (
          <div className="muted">No active sessions.</div>
        ) : (
          <div className="stack">
            {active.map((s) => (
              <div key={s.id} className="row" style={{ justifyContent: 'space-between' }}>
                <div className="stack" style={{ gap: 2 }}>
                  <div style={{ fontWeight: 700 }}>{s.exam?.name ?? 'Exam session'}</div>
                  <div className="muted" style={{ fontSize: 13 }}>
                    Mode: {s.mode ?? 'FULL'} · Ends: {s.endsAt ? new Date(s.endsAt).toLocaleString() : '—'}
                  </div>
                </div>
                <Link className="btn" to={`/sessions/${s.id}`}>
                  Resume
                </Link>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="card stack">
        <div style={{ fontWeight: 800 }}>Recent attempts</div>
        {loading ? (
          <div className="muted">Loading…</div>
        ) : sessions.length === 0 ? (
          <div className="muted">No attempts yet.</div>
        ) : (
          <div className="stack">
            {sessions.slice(0, 8).map((s) => (
              <div key={s.id} className="row" style={{ justifyContent: 'space-between' }}>
                <div className="stack" style={{ gap: 2 }}>
                  <div style={{ fontWeight: 700 }}>{s.exam?.name ?? 'Exam'}</div>
                  <div className="muted" style={{ fontSize: 13 }}>
                    {s.status} · {s.mode ?? 'FULL'} · Started:{' '}
                    {s.startedAt ? new Date(s.startedAt).toLocaleString() : '—'}
                  </div>
                </div>
                {s.exam?.id ? (
                  <Link className="btn secondary" to={`/results/${s.exam.id}`}>
                    Results
                  </Link>
                ) : (
                  <span className="muted">—</span>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

