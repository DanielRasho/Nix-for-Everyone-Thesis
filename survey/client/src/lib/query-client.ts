import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { errorDetail, errorTitle, isApiError } from '@/lib/api'
import type { User } from '@/lib/types'

declare module '@tanstack/react-query' {
  interface Register {
    /** `silent`: the caller shows the error itself, no automatic toast. */
    queryMeta: { silent?: boolean }
    mutationMeta: { silent?: boolean }
  }
}

export const keys = {
  me: ['me'] as const,
  roadmap: ['roadmap'] as const,
  current: (stepId: string) => ['current', stepId] as const,
  surveys: ['admin', 'surveys'] as const,
  participants: ['admin', 'participants'] as const,
  grading: ['admin', 'grading'] as const,
}

export function toastError(err: unknown) {
  toast.error(errorTitle(err), { description: errorDetail(err) })
}

/** Any 401 outside the login form means the session is gone: the guards go to /login. */
export function sessionExpired() {
  if (queryClient.getQueryData<User | null>(keys.me) === null) return
  queryClient.setQueryData(keys.me, null)
  toast.warning('Tu sesión terminó', { description: 'Vuelve a iniciar sesión para continuar.' })
}

/** Sets the session user, dropping every cached answer of a previous one. */
export function setSessionUser(user: User | null) {
  queryClient.removeQueries({ predicate: (q) => q.queryKey[0] !== keys.me[0] })
  queryClient.setQueryData(keys.me, user)
}

export const queryClient: QueryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (err, query) => {
      if (isApiError(err, 401) && query.queryKey[0] !== keys.me[0]) return sessionExpired()
      if (!query.meta?.silent) toastError(err)
    },
  }),
  mutationCache: new MutationCache({
    onError: (err, _vars, _ctx, mutation) => {
      if (isApiError(err, 401) && mutation.options.mutationKey?.[0] !== 'login') return sessionExpired()
      if (!mutation.meta?.silent) toastError(err)
    },
  }),
  defaultOptions: {
    queries: {
      // 4xx answers won't change by retrying.
      retry: (failureCount, err) =>
        !(isApiError(err) && err.status >= 400 && err.status < 500) && failureCount < 2,
    },
    mutations: { retry: false },
  },
})
