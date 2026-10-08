import { useMutation } from '@tanstack/react-query'
import { LogOutIcon, ShieldIcon, UserIcon } from 'lucide-react'
import { Link, Outlet, useNavigate } from 'react-router'
import { ThemeToggle } from '@/components/theme-toggle'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { homeFor, useMe } from '@/hooks/use-me'
import { api } from '@/lib/api'
import { isClarityLoaded } from '@/lib/clarity'
import { setSessionUser } from '@/lib/query-client'

export function AppShell() {
  const { data: user } = useMe()
  const navigate = useNavigate()

  const logout = useMutation({
    mutationFn: api.logout,
    onSuccess: () => {
      // Clarity can't be unloaded: a full reload stops the recording.
      if (isClarityLoaded()) {
        window.location.assign('/login')
        return
      }
      setSessionUser(null)
      navigate('/login', { replace: true })
    },
  })

  return (
    <div className="flex min-h-svh flex-col">
      <header className="sticky top-0 z-30 border-b bg-background/90 backdrop-blur supports-backdrop-filter:bg-background/70">
        <div className="mx-auto flex h-14 max-w-7xl items-center gap-3 px-4">
          <Link to={user ? homeFor(user) : '/'} className="font-heading font-semibold tracking-tight">
            Encuesta Nixty
          </Link>
          <div className="ml-auto flex items-center gap-1 sm:gap-2">
            {user && (
              <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                {user.role === 'admin' ? (
                  <ShieldIcon className="size-4" />
                ) : (
                  <UserIcon className="size-4" />
                )}
                <span className="max-w-[10rem] truncate font-medium text-foreground">{user.username}</span>
                {user.role === 'admin' && (
                  <Badge variant="secondary" className="hidden sm:inline-flex">
                    Admin
                  </Badge>
                )}
              </span>
            )}
            <ThemeToggle />
            <Button
              variant="ghost"
              size="sm"
              onClick={() => logout.mutate()}
              disabled={logout.isPending}
              aria-label="Cerrar sesión"
            >
              <LogOutIcon />
              <span className="hidden sm:inline">Salir</span>
            </Button>
          </div>
        </div>
      </header>
      <main className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:py-8">
        <Outlet />
      </main>
    </div>
  )
}
