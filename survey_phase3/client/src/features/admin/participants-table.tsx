import { useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { KeyRoundIcon, MoreHorizontalIcon, Trash2Icon } from 'lucide-react'
import { toast } from 'sonner'
import { StatusBadge } from '@/components/status-badge'
import { PasswordReveal } from '@/features/admin/password-reveal'
import { participantSurveySteps } from '@/features/admin/survey-order'
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { Spinner } from '@/components/ui/spinner'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { api } from '@/lib/api'
import { formatDate } from '@/lib/format'
import { keys } from '@/lib/query-client'
import type { Participant, Step } from '@/lib/types'

type Confirm = { action: 'password' | 'delete'; participant: Participant }

export function ParticipantsTable({ participants }: { participants: Participant[] }) {
  const queryClient = useQueryClient()
  const [confirm, setConfirm] = useState<Confirm | null>(null)
  const [revealed, setRevealed] = useState<{ username: string; password: string } | null>(null)

  const regenerate = useMutation({
    mutationFn: (p: Participant) => api.regeneratePassword(p.id),
    onSuccess: ({ password }, p) => {
      setConfirm(null)
      setRevealed({ username: p.username, password })
    },
  })

  const remove = useMutation({
    mutationFn: (p: Participant) => api.deleteParticipant(p.id),
    onSuccess: (_, p) => {
      setConfirm(null)
      toast.success(`Se eliminó a ${p.username}`)
      void queryClient.invalidateQueries({ queryKey: keys.participants })
      void queryClient.invalidateQueries({ queryKey: keys.grading })
    },
  })

  const pending = regenerate.isPending || remove.isPending

  if (participants.length === 0) {
    return (
      <p className="rounded-lg border border-dashed p-10 text-center text-sm text-muted-foreground">
        Todavía no hay participantes. Crea el primero con «Nuevo participante».
      </p>
    )
  }

  return (
    <>
      <div className="overflow-hidden rounded-lg border">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Usuario</TableHead>
              <TableHead>Orden</TableHead>
              <TableHead>Progreso</TableHead>
              <TableHead>Creado</TableHead>
              <TableHead className="w-10">
                <span className="sr-only">Acciones</span>
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {participants.map((p) => (
              <TableRow key={p.id}>
                <TableCell className="font-medium">{p.username}</TableCell>
                <TableCell className="text-muted-foreground">
                  {participantSurveySteps(p)
                    .map((s) => s.title)
                    .join(' → ')}
                </TableCell>
                <TableCell>
                  <div className="flex flex-col gap-1.5">
                    {p.steps.map((s) => (
                      <StepProgress key={s.id} step={s} />
                    ))}
                  </div>
                </TableCell>
                <TableCell className="text-muted-foreground">{formatDate(p.createdAt)}</TableCell>
                <TableCell>
                  <DropdownMenu modal={false}>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon-sm" aria-label={`Acciones para ${p.username}`}>
                        <MoreHorizontalIcon />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onSelect={() => setConfirm({ action: 'password', participant: p })}>
                        <KeyRoundIcon />
                        Regenerar contraseña
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      <DropdownMenuItem
                        variant="destructive"
                        onSelect={() => setConfirm({ action: 'delete', participant: p })}
                      >
                        <Trash2Icon />
                        Eliminar
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      <AlertDialog open={confirm !== null} onOpenChange={(open) => !open && !pending && setConfirm(null)}>
        <AlertDialogContent>
          {confirm?.action === 'password' && (
            <AlertDialogHeader>
              <AlertDialogTitle>¿Regenerar la contraseña de {confirm.participant.username}?</AlertDialogTitle>
              <AlertDialogDescription>
                La contraseña actual dejará de funcionar y se cerrará su sesión. Sus respuestas se
                conservan.
              </AlertDialogDescription>
            </AlertDialogHeader>
          )}
          {confirm?.action === 'delete' && (
            <AlertDialogHeader>
              <AlertDialogTitle>¿Eliminar a {confirm.participant.username}?</AlertDialogTitle>
              <AlertDialogDescription>
                Se borrarán el participante y todas sus respuestas y tiempos. Esta acción no se puede
                deshacer.
              </AlertDialogDescription>
            </AlertDialogHeader>
          )}
          <AlertDialogFooter>
            <AlertDialogCancel disabled={pending}>Cancelar</AlertDialogCancel>
            {confirm?.action === 'password' && (
              <Button disabled={pending} onClick={() => regenerate.mutate(confirm.participant)}>
                {regenerate.isPending && <Spinner />}
                Regenerar
              </Button>
            )}
            {confirm?.action === 'delete' && (
              <Button variant="destructive" disabled={pending} onClick={() => remove.mutate(confirm.participant)}>
                {remove.isPending && <Spinner />}
                Eliminar
              </Button>
            )}
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <Dialog open={revealed !== null} onOpenChange={(open) => !open && setRevealed(null)}>
        <DialogContent className="sm:max-w-md" onInteractOutside={(e) => e.preventDefault()}>
          <DialogHeader>
            <DialogTitle>Nueva contraseña</DialogTitle>
            <DialogDescription>La contraseña anterior ya no funciona.</DialogDescription>
          </DialogHeader>
          {revealed && <PasswordReveal username={revealed.username} password={revealed.password} />}
          <DialogFooter>
            <Button onClick={() => setRevealed(null)}>Listo, ya la copié</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  )
}

function StepProgress({ step }: { step: Step }) {
  const dates = [
    step.startedAt && `Inicio: ${formatDate(step.startedAt)}`,
    step.completedAt && `Fin: ${formatDate(step.completedAt)}`,
  ]
    .filter(Boolean)
    .join(' · ')

  return (
    <div className="flex items-center gap-2 text-xs whitespace-nowrap" title={dates || undefined}>
      <span className="w-24 truncate text-muted-foreground">{step.title}</span>
      <StatusBadge status={step.status} />
      <span className="tabular-nums">
        {step.answered}/{step.total}
      </span>
    </div>
  )
}
