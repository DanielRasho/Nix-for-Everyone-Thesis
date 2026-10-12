import { useQuery } from '@tanstack/react-query'
import { CheckCircle2Icon, LockIcon } from 'lucide-react'
import { Link } from 'react-router'
import { ErrorState, LoadingState } from '@/components/page-state'
import { StatusBadge } from '@/components/status-badge'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'
import { Button } from '@/components/ui/button'
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import { api } from '@/lib/api'
import { keys } from '@/lib/query-client'
import type { Step } from '@/lib/types'
import { cn } from '@/lib/utils'

export function RoadmapPage() {
  const roadmap = useQuery({ queryKey: keys.roadmap, queryFn: api.roadmap, meta: { silent: true } })

  if (roadmap.isPending) return <LoadingState />
  if (roadmap.isError) return <ErrorState error={roadmap.error} onRetry={() => void roadmap.refetch()} />

  const steps = roadmap.data.steps
  const allDone = steps.length > 0 && steps.every((s) => s.status === 'completed')

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="space-y-1">
        <h1 className="font-heading text-2xl font-semibold tracking-tight">Tu recorrido</h1>
        <p className="text-muted-foreground">
          Completa los pasos en orden. Puedes salir cuando quieras y continuar después donde lo dejaste;
          las respuestas enviadas no se pueden modificar.
        </p>
      </div>

      {allDone && (
        <Alert>
          <CheckCircle2Icon />
          <AlertTitle>¡Terminaste todos los pasos!</AlertTitle>
          <AlertDescription>Muchas gracias por participar en el estudio.</AlertDescription>
        </Alert>
      )}

      <ol className="space-y-4">
        {steps.map((step, i) => (
          <li key={step.id}>
            <StepCard step={step} index={i + 1} />
          </li>
        ))}
      </ol>
    </div>
  )
}

function StepCard({ step, index }: { step: Step; index: number }) {
  const percent = step.total > 0 ? Math.round((step.answered / step.total) * 100) : 0
  const locked = step.status === 'locked'

  return (
    <Card className={cn(locked && 'opacity-70')}>
      <CardHeader>
        <CardTitle className="flex items-center gap-3 text-lg">
          <span
            className={cn(
              'flex size-7 shrink-0 items-center justify-center rounded-full border text-sm font-semibold',
              step.status === 'completed' && 'border-success bg-success text-background',
            )}
          >
            {index}
          </span>
          {step.title}
        </CardTitle>
        <CardDescription>
          {step.id === 'background'
            ? 'Preguntas sobre tu experiencia previa. Se responden una sola vez.'
            : 'Ejercicios y, al final, un cuestionario sobre tu experiencia con la herramienta.'}
        </CardDescription>
        <CardAction>
          <StatusBadge status={step.status} />
        </CardAction>
      </CardHeader>
      <CardContent className="flex flex-col gap-4 sm:flex-row sm:items-center">
        <div className="flex-1 space-y-1.5">
          <Progress value={percent} aria-label={`Progreso de ${step.title}`} />
          <p className="text-xs text-muted-foreground">
            {step.answered} de {step.total} respondidas
          </p>
        </div>
        <StepButton step={step} />
      </CardContent>
    </Card>
  )
}

function StepButton({ step }: { step: Step }) {
  switch (step.status) {
    case 'locked':
      return (
        <Button variant="outline" disabled title="Se desbloquea al completar el paso anterior">
          <LockIcon />
          Bloqueado
        </Button>
      )
    case 'completed':
      return (
        <Button variant="outline" disabled>
          <CheckCircle2Icon />
          Completado
        </Button>
      )
    default:
      return (
        <Button asChild>
          <Link to={`/steps/${encodeURIComponent(step.id)}`}>
            {step.status === 'in_progress' ? 'Continuar' : 'Comenzar'}
          </Link>
        </Button>
      )
  }
}
