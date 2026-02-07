import { useEffect, useMemo, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'
import type { ExamSession } from '../types/sailor'

export function ResultsPage() {
  const { examId } = useParams()
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

  const filtered = useMemo(() => sessions.filter((s) => s.exam?.id === examId), [sessions, examId])

  return (
    <div className="container stack">
      <div className="row" style={{ justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ margin: 0 }}>Results</h2>
          <div className="muted">Per exam attempt. Full exam attempts persist; mock attempts may be disposable.</div>
        </div>
        <Link className="btn secondary" to="/dashboard">
          Back to dashboard
        </Link>
      </div>

      <div className="card stack">
        {loading ? (
          <div className="muted">Loading…</div>
        ) : filtered.length === 0 ? (
          <div className="muted">No attempts recorded for this exam.</div>
        ) : (
          <div className="stack">
            {filtered.map((s) => (
              <div key={s.id} className="row" style={{ justifyContent: 'space-between' }}>
                <div className="stack" style={{ gap: 2 }}>
                  <div style={{ fontWeight: 800 }}>
                    {s.exam?.name ?? 'Exam'} · {s.mode ?? 'FULL'}
                  </div>
                  <div className="muted" style={{ fontSize: 13 }}>
                    Status: {s.status} · Started: {s.startedAt ? new Date(s.startedAt).toLocaleString() : '—'} · Ended:{' '}
                    {s.endsAt ? new Date(s.endsAt).toLocaleString() : '—'}
                  </div>
                </div>
                <Link className="btn secondary" to={`/sessions/${s.id}`}>
                  View session
                </Link>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

