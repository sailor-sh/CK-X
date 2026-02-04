import { Link, Outlet } from 'react-router-dom'
import { useAuth } from '../state/auth/useAuth'

export function Layout() {
  const { state, logout } = useAuth()

  return (
    <div>
      <div
        style={{
          position: 'sticky',
          top: 0,
          zIndex: 10,
          background: 'rgba(248,250,252,0.9)',
          backdropFilter: 'blur(8px)',
          borderBottom: '1px solid #e2e8f0',
        }}
      >
        <div className="container row" style={{ justifyContent: 'space-between' }}>
          <div className="row" style={{ gap: 16 }}>
            <Link to="/" style={{ fontWeight: 800 }}>
              Sailor
            </Link>
            {state.status === 'authenticated' && (
              <>
                <Link to="/dashboard" className="muted">
                  Dashboard
                </Link>
                <Link to="/exams" className="muted">
                  Exams
                </Link>
              </>
            )}
          </div>

          <div className="row" style={{ gap: 10 }}>
            {state.status === 'authenticated' ? (
              <>
                <span className="muted" style={{ fontSize: 14 }}>
                  {state.user.email}
                </span>
                <button className="btn secondary" onClick={logout}>
                  Log out
                </button>
              </>
            ) : (
              <>
                <Link className="btn secondary" to="/login">
                  Log in
                </Link>
                <Link className="btn" to="/signup">
                  Sign up
                </Link>
              </>
            )}
          </div>
        </div>
      </div>

      <Outlet />
    </div>
  )
}

