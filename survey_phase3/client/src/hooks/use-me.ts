import { useQuery } from '@tanstack/react-query'
import { api, isApiError } from '@/lib/api'
import { keys } from '@/lib/query-client'
import type { User } from '@/lib/types'

/** The logged-in user, `null` when there is no session (401). */
export function useMe() {
  return useQuery({
    queryKey: keys.me,
    queryFn: async (): Promise<User | null> => {
      try {
        return (await api.me()).user
      } catch (err) {
        if (isApiError(err, 401)) return null
        throw err
      }
    },
    staleTime: Infinity,
    meta: { silent: true },
  })
}

export function homeFor(user: User): string {
  return user.role === 'admin' ? '/admin' : '/'
}
