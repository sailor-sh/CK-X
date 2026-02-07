import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { api, ApiError } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'
import type { Exam } from '../types/sailor'

export function ExamSelectionPage() {
  const { state } = useAuth()
  const token = state.status === 'authenticated' ? state.token : ''
  const nav = useNavigate()

  const [exams, setExams] = useState<Exam[]>([])
  const [loading, setLoading] = useState(true)
  const [busyExamId, setBusyExamId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const run = async () => {
      setLoading(true)
      try {
        const res = await api.get<{ exams: Exam[] }>('/exams', { token })
        setExams(res.exams)
      } finally {
        setLoading(false)
      }
    }
    run()
  }, [token])

  const sorted = useMemo(() => [...exams].sort((a, b) => a.name.localeCompare(b.name)), [exams])

  return (
    <div className="container stack">
      <div>
        <h2 style={{ margin: 0 }}>Choose an exam</h2>
        <div className="muted">Mock exam is free and disposable. Full exam requires entitlement and persists results.</div>
      </div>

      {error && (
        <div className="card" style={{ borderColor: '#fecaca', background: '#fef2f2' }}>
          <div style={{ color: '#991b1b', fontWeight: 700 }}>Couldn’t start session</div>
          <div style={{ color: '#991b1b' }}>{error}</div>
        </div>
      )}

      {loading ? (
        <div className="muted">Loading…</div>
      ) : (
        <div className="stack">
          {sorted.map((e) => (
            <div key={e.id} className="card stack">
              <div className="row" style={{ justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div className="stack" style={{ gap: 4 }}>
                  <div style={{ fontWeight: 900, fontSize: 18 }}>{e.name}</div>
                  {e.description && <div className="muted">{e.description}</div>}
                  <div className="muted" style={{ fontSize: 13 }}>
                    Full: {e.durationMinutes} min · Mock: {(e.mockDurationMinutes ?? 30)} min · Attempts:{' '}
                    {e.maxAttempts ?? '∞'}
                  </div>
                </div>
                {e.product ? (
                  <div className="muted" style={{ fontSize: 13 }}>
                    Full exam product: {e.product.name} (${(e.product.priceCents / 100).toFixed(2)})
                  </div>
                ) : (
                  <div className="muted" style={{ fontSize: 13 }}>
                    No product configured (FULL will be blocked)
                  </div>
                )}
              </div>

              <div className="row" style={{ justifyContent: 'flex-end' }}>
                <button
                  className="btn secondary"
                  disabled={busyExamId === e.id}
                  onClick={async () => {
                    setError(null)
                    setBusyExamId(e.id)
                    try {
                      const res = await api.post<{ examSession: { id: string } }>(
                        '/exam-sessions',
                        { examId: e.id, mode: 'MOCK' },
                        { token }
                      )
                      nav(`/sessions/${res.examSession.id}`)
                    } catch (err) {
                      setError(err instanceof ApiError ? err.message : 'Unexpected error')
                    } finally {
                      setBusyExamId(null)
                    }
                  }}
                >
                  Start mock
                </button>

                <button
                  className="btn"
                  disabled={busyExamId === e.id}
                  onClick={async () => {
                    setError(null)
                    setBusyExamId(e.id)
                    try {
                      const res = await api.post<{ examSession: { id: string } }>(
                        '/exam-sessions',
                        { examId: e.id, mode: 'FULL' },
                        { token }
                      )
                      nav(`/sessions/${res.examSession.id}`)
                    } catch (err) {
                      setError(err instanceof ApiError ? err.message : 'Unexpected error')
                    } finally {
                      setBusyExamId(null)
                    }
                  }}
                >
                  Start full
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

