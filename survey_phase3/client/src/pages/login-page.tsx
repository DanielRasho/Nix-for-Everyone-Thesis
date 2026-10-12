import { useState, type FormEvent } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Navigate, useNavigate } from 'react-router'
import { toast } from 'sonner'
import { LoadingState } from '@/components/page-state'
import { ThemeToggle } from '@/components/theme-toggle'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Spinner } from '@/components/ui/spinner'
import { homeFor, useMe } from '@/hooks/use-me'
import { api, isApiError } from '@/lib/api'
import { setSessionUser, toastError } from '@/lib/query-client'

export function LoginPage() {
  const me = useMe()
  const navigate = useNavigate()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')

  const login = useMutation({
    mutationKey: ['login'],
    mutationFn: () => api.login(username.trim(), password),
    meta: { silent: true },
    onSuccess: ({ user }) => {
      setSessionUser(user)
      navigate(homeFor(user), { replace: true })
    },
    onError: (err) => {
      if (isApiError(err, 401)) {
        toast.error('Usuario o contraseña incorrectos', { description: err.message })
      } else {
        toastError(err)
      }
    },
  })

  if (me.isPending) return <LoadingState className="min-h-svh" />
  if (me.data) return <Navigate to={homeFor(me.data)} replace />

  const fieldErrors = isApiError(login.error, 400) ? (login.error.errors ?? {}) : {}
  const wrongCredentials = isApiError(login.error, 401)

  const onSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!username.trim() || !password) return
    login.mutate()
  }

  return (
    <div className="relative flex min-h-svh items-center justify-center px-4 py-10">
      <div className="absolute top-3 right-3">
        <ThemeToggle />
      </div>
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-xl">Encuesta Nixty</CardTitle>
          <CardDescription>
            Ingresa con el usuario y la contraseña que te dio el equipo de investigación.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="grid gap-4" noValidate>
            <div className="grid gap-2">
              <Label htmlFor="username">Usuario</Label>
              <Input
                id="username"
                autoComplete="username"
                autoCapitalize="none"
                spellCheck={false}
                autoFocus
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                aria-invalid={Boolean(fieldErrors.username) || wrongCredentials || undefined}
              />
              {fieldErrors.username && (
                <p className="text-sm text-destructive">{fieldErrors.username}</p>
              )}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="password">Contraseña</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                aria-invalid={Boolean(fieldErrors.password) || wrongCredentials || undefined}
              />
              {fieldErrors.password && (
                <p className="text-sm text-destructive">{fieldErrors.password}</p>
              )}
            </div>
            <Button
              type="submit"
              size="lg"
              disabled={login.isPending || !username.trim() || !password}
            >
              {login.isPending && <Spinner />}
              Iniciar sesión
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
