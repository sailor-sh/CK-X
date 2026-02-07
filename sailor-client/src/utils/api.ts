export class ApiError extends Error {
  status: number
  body?: unknown
  constructor(message: string, status: number, body?: unknown) {
    super(message)
    this.status = status
    this.body = body
  }
}

const API_BASE = (import.meta as any).env?.VITE_SAILOR_API_BASE ?? 'http://localhost:4000'

type RequestOpts = {
  token?: string
  signal?: AbortSignal
}

async function request<T>(method: string, path: string, body?: unknown, opts: RequestOpts = {}): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(opts.token ? { Authorization: `Bearer ${opts.token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: opts.signal,
  })

  const contentType = res.headers.get('content-type') || ''
  const isJson = contentType.includes('application/json')
  const parsed = isJson ? await res.json().catch(() => undefined) : await res.text().catch(() => undefined)

  if (!res.ok) {
    const msg = (parsed as any)?.error || res.statusText || 'Request failed'
    throw new ApiError(msg, res.status, parsed)
  }

  return parsed as T
}

export const api = {
  get: <T>(path: string, opts?: RequestOpts) => request<T>('GET', path, undefined, opts),
  post: <T>(path: string, body?: unknown, opts?: RequestOpts) => request<T>('POST', path, body, opts),
}

