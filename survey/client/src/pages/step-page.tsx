import { useCallback, useEffect } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { MapIcon, PartyPopperIcon } from 'lucide-react'
import { Link, useParams } from 'react-router'
import { toast } from 'sonner'
import { ErrorState, LoadingState } from '@/components/page-state'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { QuestionView } from '@/features/questions/question-view'
import { useHeartbeat } from '@/hooks/use-heartbeat'
import { useMe } from '@/hooks/use-me'
import { api, isApiError } from '@/lib/api'
import { trackSurvey } from '@/lib/clarity'
import { keys, toastError } from '@/lib/query-client'
import type { Answer, Current, Section } from '@/lib/types'

const sectionLabel: Record<Section, string> = {
  background: 'Antecedentes',
  tasks: 'Ejercicios',
  feedback: 'Evaluación',
}

/**
 * Runs a step forward-only: shows the current (first unanswered) question and
 * replaces it with the next one the server returns after each answer.
 */
export function StepPage() {
  const { stepId = '' } = useParams()
  const queryClient = useQueryClient()
  const { data: user } = useMe()

  const current = useQuery({
    queryKey: keys.current(stepId),
    queryFn: () => api.current(stepId),
    refetchOnWindowFocus: false,
    meta: { silent: true },
  })

  const reload = useCallback(
    () => void queryClient.invalidateQueries({ queryKey: keys.current(stepId) }),
    [queryClient, stepId],
  )

  const submit = useMutation({
    mutationFn: (answer: Answer) => api.answer(answer),
    meta: { silent: true },
    onSuccess: (next: Current) => {
      queryClient.setQueryData(keys.current(stepId), next)
      void queryClient.invalidateQueries({ queryKey: keys.roadmap })
      window.scrollTo({ top: 0 })
    },
    onError: (err) => {
      if (isApiError(err, 401)) return // handled globally
      if (isApiError(err, 409)) {
        toast.info('Esta pregunta ya no es la actual', {
          description: 'Se cargó la pregunta en curso.',
        })
      } else {
        toastError(err)
      }
      if (isApiError(err, 409) || isApiError(err, 403) || isApiError(err, 404)) reload()
    },
  })

  const question = current.data?.question ?? undefined
  useHeartbeat(question?.id, reload)

  // Clarity records only the surveys (not the background questions).
  const isSurvey = stepId !== 'background'
  const loaded = current.isSuccess
  useEffect(() => {
    if (isSurvey && loaded && user) trackSurvey(user.username, stepId)
  }, [isSurvey, loaded, user, stepId])

  if (current.isPending) return <LoadingState />
  if (current.isError) {
    const err = current.error
    const title = isApiError(err, 403)
      ? 'Este paso todavía está bloqueado'
      : isApiError(err, 404)
        ? 'Este paso no existe o no te fue asignado'
        : undefined
    return (
      <ErrorState error={err} title={title} onRetry={() => void current.refetch()}>
        <Button asChild>
          <Link to="/">Volver al recorrido</Link>
        </Button>
      </ErrorState>
    )
  }

  const { step, progress } = current.data
  const percent = progress.total > 0 ? Math.round((progress.answered / progress.total) * 100) : 0

  return (
    <div className="space-y-6">
      <div className="space-y-3">
        <div className="flex flex-wrap items-center gap-x-3 gap-y-2">
          <Button asChild variant="ghost" size="sm" className="-ml-2">
            <Link to="/">
              <MapIcon />
              Recorrido
            </Link>
          </Button>
          <h1 className="font-heading text-xl font-semibold tracking-tight">{step.title}</h1>
          {question && <Badge variant="secondary">{sectionLabel[question.section] ?? question.section}</Badge>}
          <span className="ml-auto text-sm text-muted-foreground tabular-nums">
            {question
              ? `Pregunta ${Math.min(progress.answered + 1, progress.total)} de ${progress.total}`
              : `${progress.answered} de ${progress.total}`}
          </span>
        </div>
        <Progress value={percent} aria-label="Progreso del paso" />
      </div>

      {question ? (
        <QuestionView
          key={question.id}
          question={question}
          step={step}
          submitting={submit.isPending}
          onSubmit={(answer) => submit.mutate(answer)}
        />
      ) : (
        <div className="mx-auto flex max-w-md flex-col items-center gap-4 py-12 text-center">
          <PartyPopperIcon className="size-10 text-success" />
          <h2 className="font-heading text-2xl font-semibold">¡Completaste {step.title}!</h2>
          <p className="text-muted-foreground">
            Tus respuestas quedaron guardadas. Vuelve al recorrido para continuar con el siguiente paso.
          </p>
          <Button asChild size="lg">
            <Link to="/">Volver al recorrido</Link>
          </Button>
        </div>
      )}
    </div>
  )
}
