import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react'
import { api } from '../../utils/api'
import type { AuthState, AuthUser } from './types'

type AuthContextValue = {
  state: AuthState
  login: (email: string, password: string) => Promise<void>
  signup: (email: string, password: string, name?: string) => Promise<void>
  logout: () => void
}

const STORAGE_KEY = 'sailor.auth.v1'

export const AuthContext = createContext<AuthContextValue | undefined>(undefined)

function loadFromStorage(): AuthState {
  const raw = localStorage.getItem(STORAGE_KEY)
  if (!raw) return { status: 'anonymous', token: null, user: null }
  try {
    const parsed = JSON.parse(raw) as { token: string; user: AuthUser }
    if (parsed?.token && parsed?.user?.id) {
      return { status: 'authenticated', token: parsed.token, user: parsed.user }
    }
  } catch {
    // ignore
  }
  return { status: 'anonymous', token: null, user: null }
}

function saveToStorage(state: AuthState) {
  if (state.status === 'authenticated') {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ token: state.token, user: state.user }))
  } else {
    localStorage.removeItem(STORAGE_KEY)
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>(() => loadFromStorage())

  // Best-effort token validation on mount (supports safe resume)
  useEffect(() => {
    const run = async () => {
      if (state.status !== 'authenticated') return
      try {
        const me = await api.get<{ user: AuthUser }>('/auth/me', { token: state.token })
        setState({ status: 'authenticated', token: state.token, user: me.user })
      } catch {
        setState({ status: 'anonymous', token: null, user: null })
      }
    }
    run()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => saveToStorage(state), [state])

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.post<{ user: AuthUser; token: string }>('/auth/login', {
      email,
      password,
    })
    setState({ status: 'authenticated', token: res.token, user: res.user })
  }, [])

  const signup = useCallback(async (email: string, password: string, name?: string) => {
    const res = await api.post<{ user: AuthUser; token: string }>('/auth/register', {
      email,
      password,
      name,
    })
    setState({ status: 'authenticated', token: res.token, user: res.user })
  }, [])

  const logout = useCallback(() => {
    setState({ status: 'anonymous', token: null, user: null })
  }, [])

  const value = useMemo<AuthContextValue>(() => ({ state, login, signup, logout }), [state, login, signup, logout])

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

