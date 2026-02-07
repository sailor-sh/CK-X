import React from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../state/auth/useAuth'

export function ProtectedRoute({ children }: { children: React.ReactElement }) {
  const { state } = useAuth()
  if (state.status !== 'authenticated') {
    return <Navigate to="/login" replace />
  }
  return children
}

