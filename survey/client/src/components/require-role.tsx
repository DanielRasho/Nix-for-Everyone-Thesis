import type { ReactNode } from 'react'
import { Navigate } from 'react-router'
import { ErrorState, LoadingState } from '@/components/page-state'
import { homeFor, useMe } from '@/hooks/use-me'
import type { Role } from '@/lib/types'

/** Renders children only for a logged-in user with `role`; others are redirected. */
export function RequireRole({ role, children }: { role: Role; children: ReactNode }) {
  const me = useMe()

  if (me.isPending) return <LoadingState className="min-h-svh" />
  if (me.isError) {
    return <ErrorState error={me.error} onRetry={() => void me.refetch()} className="min-h-svh" />
  }
  if (!me.data) return <Navigate to="/login" replace />
  if (me.data.role !== role) return <Navigate to={homeFor(me.data)} replace />
  return children
}
