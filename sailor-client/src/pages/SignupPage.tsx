import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ApiError } from '../utils/api'
import { useAuth } from '../state/auth/useAuth'

export function SignupPage() {
  const { signup } = useAuth()
  const nav = useNavigate()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const canSubmit = useMemo(() => email.trim() && password.length >= 8, [email, password])

  return (
    <div className="container" style={{ maxWidth: 520 }}>
      <div className="card stack">
        <div>
          <h2 style={{ margin: 0 }}>Create account</h2>
          <div className="muted">Start with a mock exam for free, upgrade for full exam access.</div>
        </div>

        <div className="stack">
          <label className="stack" style={{ gap: 6 }}>
            <div style={{ fontWeight: 600 }}>Name (optional)</div>
            <input className="input" value={name} onChange={(e) => setName(e.target.value)} autoComplete="name" />
          </label>

          <label className="stack" style={{ gap: 6 }}>
            <div style={{ fontWeight: 600 }}>Email</div>
            <input className="input" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email" />
          </label>

          <label className="stack" style={{ gap: 6 }}>
            <div style={{ fontWeight: 600 }}>Password</div>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="new-password"
              placeholder="Min 8 characters"
            />
          </label>
        </div>

        {error && (
          <div className="card" style={{ borderColor: '#fecaca', background: '#fef2f2' }}>
            <div style={{ color: '#991b1b', fontWeight: 700 }}>Signup failed</div>
            <div style={{ color: '#991b1b' }}>{error}</div>
          </div>
        )}

        <div className="row" style={{ justifyContent: 'space-between' }}>
          <div className="muted" style={{ fontSize: 14 }}>
            Already have an account? <Link to="/login" style={{ textDecoration: 'underline' }}>Log in</Link>
          </div>
          <button
            className="btn"
            disabled={!canSubmit || loading}
            onClick={async () => {
              setError(null)
              setLoading(true)
              try {
                await signup(email, password, name || undefined)
                nav('/dashboard')
              } catch (e) {
                const msg = e instanceof ApiError ? e.message : 'Unexpected error'
                setError(msg)
              } finally {
                setLoading(false)
              }
            }}
          >
            {loading ? 'Creating…' : 'Sign up'}
          </button>
        </div>
      </div>
    </div>
  )
}

