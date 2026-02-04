export type Exam = {
  id: string
  slug: string
  name: string
  description?: string | null
  durationMinutes: number
  mockDurationMinutes?: number
  maxAttempts?: number | null
  productId?: string | null
  product?: {
    id: string
    name: string
    type: string
    priceCents: number
  } | null
  questionCount?: number
}

export type ExamSession = {
  id: string
  examId: string
  ckxSessionId?: string | null
  status: 'CREATED' | 'PROVISIONING' | 'ACTIVE' | 'ENDED' | 'EXPIRED' | 'REVOKED'
  mode?: 'MOCK' | 'FULL'
  disposable?: boolean
  startedAt?: string | null
  endsAt?: string | null
  submittedAt?: string | null
  exam?: {
    id: string
    slug: string
    name: string
    durationMinutes: number
  }
}

