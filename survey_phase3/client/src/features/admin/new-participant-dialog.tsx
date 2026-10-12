import { useState, type FormEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { UserPlusIcon } from 'lucide-react'
import { PasswordReveal } from '@/features/admin/password-reveal'
import { participantOrderKey, surveyOrderOptions } from '@/features/admin/survey-order'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { Spinner } from '@/components/ui/spinner'
import { api, isApiError } from '@/lib/api'
import { keys } from '@/lib/query-client'
import type { Participant } from '@/lib/types'

export function NewParticipantDialog({ participants }: { participants: Participant[] }) {
  const [open, setOpen] = useState(false)
  // Remounting the form on every open resets it.
  const [formKey, setFormKey] = useState(0)

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        setOpen(next)
        if (next) setFormKey((k) => k + 1)
      }}
    >
      <DialogTrigger asChild>
        <Button>
          <UserPlusIcon />
          Nuevo participante
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md" onInteractOutside={(e) => e.preventDefault()}>
        <NewParticipantForm key={formKey} participants={participants} onDone={() => setOpen(false)} />
      </DialogContent>
    </Dialog>
  )
}

function NewParticipantForm({
  participants,
  onDone,
}: {
  participants: Participant[]
  onDone: () => void
}) {
  const queryClient = useQueryClient()
  const surveys = useQuery({ queryKey: keys.surveys, queryFn: api.surveys, staleTime: Infinity })
  const options = surveys.data ? surveyOrderOptions(surveys.data.surveys) : []

  // How many participants each order already has, to keep both groups balanced.
  const counts = new Map<string, number>()
  for (const p of participants) {
    const key = participantOrderKey(p)
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  const leastUsed = options.reduce<string | undefined>(
    (best, o) => (best === undefined || (counts.get(o.key) ?? 0) < (counts.get(best) ?? 0) ? o.key : best),
    undefined,
  )

  const [username, setUsername] = useState('')
  const [orderKey, setOrderKey] = useState<string>()
  const selectedKey = orderKey ?? leastUsed

  const create = useMutation({
    mutationFn: () => {
      const order = options.find((o) => o.key === selectedKey)?.order ?? []
      return api.createParticipant(username.trim(), order)
    },
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: keys.participants }),
  })

  if (create.isSuccess) {
    return (
      <>
        <DialogHeader>
          <DialogTitle>Participante creado</DialogTitle>
          <DialogDescription>Entrega estas credenciales al participante.</DialogDescription>
        </DialogHeader>
        <PasswordReveal username={create.data.participant.username} password={create.data.password} />
        <DialogFooter>
          <Button onClick={onDone}>Listo, ya la copié</Button>
        </DialogFooter>
      </>
    )
  }

  const fieldErrors = isApiError(create.error, 400) ? (create.error.errors ?? {}) : {}
  const usernameError = isApiError(create.error, 409)
    ? 'Ese usuario ya existe.'
    : fieldErrors.username
  const orderError = fieldErrors.surveyOrder

  const onSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!username.trim() || !selectedKey) return
    create.mutate()
  }

  return (
    <form onSubmit={onSubmit} className="grid gap-4" noValidate>
      <DialogHeader>
        <DialogTitle>Nuevo participante</DialogTitle>
        <DialogDescription>
          Se generará una contraseña que solo se mostrará una vez.
        </DialogDescription>
      </DialogHeader>

      <div className="grid gap-2">
        <Label htmlFor="new-username">Usuario</Label>
        <Input
          id="new-username"
          autoComplete="off"
          autoCapitalize="none"
          spellCheck={false}
          autoFocus
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          aria-invalid={Boolean(usernameError) || undefined}
        />
        {usernameError ? (
          <p className="text-sm text-destructive">{usernameError}</p>
        ) : (
          <p className="text-xs text-muted-foreground">2 a 32 caracteres: letras, números, «_» o «-».</p>
        )}
      </div>

      <div className="grid gap-2">
        <Label>Orden de las encuestas</Label>
        {surveys.isPending ? (
          <Spinner />
        ) : surveys.isError ? (
          <p className="text-sm text-destructive">No se pudieron cargar las encuestas.</p>
        ) : (
          <RadioGroup value={selectedKey ?? ''} onValueChange={setOrderKey} aria-label="Orden de las encuestas">
            {options.map((o) => (
              <Label
                key={o.key}
                htmlFor={`order-${o.key}`}
                className="flex cursor-pointer items-center gap-3 rounded-lg border p-3 font-normal has-[[data-state=checked]]:border-primary has-[[data-state=checked]]:bg-muted/60"
              >
                <RadioGroupItem id={`order-${o.key}`} value={o.key} />
                <span className="flex-1 font-medium">{o.label}</span>
                <span className="text-xs text-muted-foreground">
                  {counts.get(o.key) ?? 0} participantes
                </span>
              </Label>
            ))}
          </RadioGroup>
        )}
        {orderError && <p className="text-sm text-destructive">{orderError}</p>}
      </div>

      <DialogFooter>
        <Button type="submit" disabled={create.isPending || !username.trim() || !selectedKey}>
          {create.isPending && <Spinner />}
          Crear participante
        </Button>
      </DialogFooter>
    </form>
  )
}
