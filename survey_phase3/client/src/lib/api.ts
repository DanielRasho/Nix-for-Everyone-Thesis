import type {
  Answer,
  ApiErrorBody,
  Current,
  GradingAnswer,
  Participant,
  Step,
  SurveySummary,
  User,
} from '@/lib/types'

/**
 * Every call goes to a relative /api URL: nginx (prod) and the Vite proxy (dev)
 * strip the prefix and forward it to the Go server, so the session cookie is
 * first-party and there is no CORS.
 */
const BASE = '/api'

export const EXPORT_CSV_URL = `${BASE}/admin/export.csv`
export const EXPORT_CODE_URL = `${BASE}/admin/export-code.zip`

/** A failed request. `status` 0 means the server could not be reached. */
export class ApiError extends Error {
  readonly status: number
  readonly errors?: Record<string, string>

  constructor(status: number, message: string, errors?: Record<string, string>) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.errors = errors
  }
}

export function isApiError(err: unknown, status?: number): err is ApiError {
  return err instanceof ApiError && (status === undefined || err.status === status)
}

type Method = 'GET' | 'POST' | 'PUT' | 'DELETE'

async function request<T>(method: Method, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (body !== undefined) headers['Content-Type'] = 'application/json'

  let res: Response
  try {
    res = await fetch(BASE + path, {
      method,
      headers,
      credentials: 'same-origin',
      body: body === undefined ? undefined : JSON.stringify(body),
    })
  } catch {
    throw new ApiError(0, 'No se pudo conectar con el servidor.')
  }

  const text = res.status === 204 ? '' : await res.text()
  let data: unknown
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = undefined
    }
  }

  if (!res.ok) {
    const err = (data ?? {}) as Partial<ApiErrorBody>
    const message =
      typeof err.message === 'string' && err.message ? err.message : res.statusText || `HTTP ${res.status}`
    throw new ApiError(res.status, message, err.errors)
  }
  return data as T
}

const enc = encodeURIComponent

export const api = {
  // Auth
  login: (username: string, password: string) =>
    request<{ user: User }>('POST', '/auth/login', { username, password }),
  logout: () => request<void>('POST', '/auth/logout'),
  me: () => request<{ user: User }>('GET', '/auth/me'),

  // Participant
  roadmap: () => request<{ steps: Step[] }>('GET', '/me/roadmap'),
  current: (stepId: string) => request<Current>('GET', `/me/steps/${enc(stepId)}/current`),
  answer: (answer: Answer) => request<Current>('POST', '/me/answers', answer),
  heartbeat: (questionId: string) => request<void>('POST', '/me/heartbeat', { questionId }),

  // Admin
  surveys: () => request<{ surveys: SurveySummary[] }>('GET', '/admin/surveys'),
  participants: () => request<{ participants: Participant[] }>('GET', '/admin/participants'),
  createParticipant: (username: string, surveyOrder: string[]) =>
    request<{ participant: Participant; password: string }>('POST', '/admin/participants', {
      username,
      surveyOrder,
    }),
  regeneratePassword: (id: string) =>
    request<{ password: string }>('POST', `/admin/participants/${enc(id)}/password`),
  deleteParticipant: (id: string) => request<void>('DELETE', `/admin/participants/${enc(id)}`),
  grading: () => request<{ answers: GradingAnswer[] }>('GET', '/admin/grading'),
  grade: (userId: string, questionId: string, isCorrect: boolean | null) =>
    request<void>('PUT', '/admin/grading', { userId, questionId, isCorrect }),
}

/** Spanish title for a failed request; the server's own `message` goes below it. */
export function errorTitle(err: unknown): string {
  if (!(err instanceof ApiError)) return 'Ocurrió un error inesperado'
  if (err.status === 0) return 'Sin conexión con el servidor'
  if (err.status === 400) return 'Datos inválidos'
  if (err.status === 401) return 'Sesión no válida'
  if (err.status === 403) return 'No permitido'
  if (err.status === 404) return 'No encontrado'
  if (err.status === 409) return 'Conflicto'
  if (err.status >= 500) return 'Error del servidor'
  return `Error ${err.status}`
}

/** The server message plus the per-field reasons, if any. */
export function errorDetail(err: unknown): string {
  if (!(err instanceof Error)) return String(err)
  if (!(err instanceof ApiError) || !err.errors) return err.message
  const fields = Object.entries(err.errors).map(([field, reason]) => `${field}: ${reason}`)
  return [err.message, ...fields].join('\n')
}
