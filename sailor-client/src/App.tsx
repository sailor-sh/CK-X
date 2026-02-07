import { Navigate, Route, Routes } from 'react-router-dom'
import { Layout } from './components/Layout'
import { ProtectedRoute } from './components/ProtectedRoute'
import { LoginPage } from './pages/LoginPage'
import { SignupPage } from './pages/SignupPage'
import { DashboardPage } from './pages/DashboardPage'
import { ExamSelectionPage } from './pages/ExamSelectionPage'
import { ActiveExamSessionPage } from './pages/ActiveExamSessionPage'
import { ResultsPage } from './pages/ResultsPage'
import { useAuth } from './state/auth/useAuth'

export default function App() {
  const { state } = useAuth()

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route
          path="/"
          element={<Navigate to={state.status === 'authenticated' ? '/dashboard' : '/login'} replace />}
        />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />

        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/exams"
          element={
            <ProtectedRoute>
              <ExamSelectionPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/sessions/:examSessionId"
          element={
            <ProtectedRoute>
              <ActiveExamSessionPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/results/:examId"
          element={
            <ProtectedRoute>
              <ResultsPage />
            </ProtectedRoute>
          }
        />
      </Route>
    </Routes>
  )
}
