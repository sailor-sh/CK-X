export type AuthUser = {
  id: string
  email: string
  name?: string | null
}

export type AuthState =
  | { status: 'anonymous'; token: null; user: null }
  | { status: 'authenticated'; token: string; user: AuthUser }

