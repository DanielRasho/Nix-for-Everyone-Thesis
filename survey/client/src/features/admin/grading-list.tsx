import { useMemo, useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { CheckIcon, ChevronRightIcon, MinusIcon, XIcon } from 'lucide-react'
import { CodeBlock } from '@/components/code-block'
import { MarkdownContent } from '@/components/markdown'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { api } from '@/lib/api'
import { formatDate } from '@/lib/format'
import { guessLanguage } from '@/lib/highlighter'
import { keys } from '@/lib/query-client'
import type { GradingAnswer } from '@/lib/types'
import { cn } from '@/lib/utils'

type Filter = 'pending' | 'graded' | 'all'

interface GradeVars {
  userId: string
  questionId: string
  isCorrect: boolean | null
}

const answerKey = (a: { userId: string; questionId: string }) => `${a.userId}/${a.questionId}`

export function GradingList({ answers }: { answers: GradingAnswer[] }) {
  const queryClient = useQueryClient()
  const [filter, setFilter] = useState<Filter>('pending')

  const grade = useMutation({
    mutationFn: (v: GradeVars) => api.grade(v.userId, v.questionId, v.isCorrect),
    onSuccess: (_, v) => {
      queryClient.setQueryData<{ answers: GradingAnswer[] }>(keys.grading, (old) =>
        old
          ? {
              answers: old.answers.map((a) =>
                answerKey(a) === answerKey(v) ? { ...a, isCorrect: v.isCorrect } : a,
              ),
            }
          : old,
      )
    },
  })

  const sorted = useMemo(
    () =>
      [...answers].sort(
        (a, b) => a.questionId.localeCompare(b.questionId) || a.answeredAt.localeCompare(b.answeredAt),
      ),
    [answers],
  )
  const pendingCount = answers.filter((a) => a.isCorrect === null).length
  const visible = sorted.filter((a) =>
    filter === 'all' ? true : filter === 'pending' ? a.isCorrect === null : a.isCorrect !== null,
  )
  const busyKey = grade.isPending && grade.variables ? answerKey(grade.variables) : undefined

  return (
    <div className="space-y-4">
      <Tabs value={filter} onValueChange={(v) => setFilter(v as Filter)}>
        <TabsList>
          <TabsTrigger value="pending">Sin calificar ({pendingCount})</TabsTrigger>
          <TabsTrigger value="graded">Calificadas ({answers.length - pendingCount})</TabsTrigger>
          <TabsTrigger value="all">Todas ({answers.length})</TabsTrigger>
        </TabsList>
      </Tabs>

      {visible.length === 0 ? (
        <p className="rounded-lg border border-dashed p-10 text-center text-sm text-muted-foreground">
          {filter === 'pending' ? 'No hay respuestas pendientes de calificar.' : 'No hay respuestas.'}
        </p>
      ) : (
        visible.map((a) => (
          <GradingCard
            key={answerKey(a)}
            answer={a}
            busy={busyKey === answerKey(a)}
            onGrade={(isCorrect) => grade.mutate({ userId: a.userId, questionId: a.questionId, isCorrect })}
          />
        ))
      )}
    </div>
  )
}

function GradeBadge({ isCorrect }: { isCorrect: boolean | null }) {
  if (isCorrect === null) return <Badge variant="secondary">Sin calificar</Badge>
  return (
    <Badge
      variant="outline"
      className={cn(
        'border-transparent',
        isCorrect ? 'bg-success/15 text-success' : 'bg-destructive/10 text-destructive',
      )}
    >
      {isCorrect ? 'Correcto' : 'Incorrecto'}
    </Badge>
  )
}

interface GradingCardProps {
  answer: GradingAnswer
  busy: boolean
  onGrade: (isCorrect: boolean | null) => void
}

function GradingCard({ answer, busy, onGrade }: GradingCardProps) {
  const choices: { value: boolean | null; label: string; icon: typeof CheckIcon }[] = [
    { value: true, label: 'Correcto', icon: CheckIcon },
    { value: false, label: 'Incorrecto', icon: XIcon },
    { value: null, label: 'Sin calificar', icon: MinusIcon },
  ]

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex flex-wrap items-center gap-2">
          {answer.username}
          <span className="font-mono text-sm font-normal text-muted-foreground">{answer.questionId}</span>
        </CardTitle>
        <CardDescription>Respondida: {formatDate(answer.answeredAt)}</CardDescription>
        <CardAction>
          <GradeBadge isCorrect={answer.isCorrect} />
        </CardAction>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex flex-wrap gap-2">
          {choices.map(({ value, label, icon: Icon }) => {
            const active = answer.isCorrect === value
            return (
              <Button
                key={label}
                size="sm"
                variant={active ? (value === false ? 'destructive' : 'default') : 'outline'}
                className={cn(active && value === true && 'bg-success text-background hover:bg-success/90')}
                aria-pressed={active}
                disabled={busy}
                onClick={() => !active && onGrade(value)}
              >
                <Icon />
                {label}
              </Button>
            )
          })}
        </div>

        <Collapsible>
          <CollapsibleTrigger asChild>
            <Button variant="ghost" size="sm" className="group -ml-2">
              <ChevronRightIcon className="transition-transform group-data-[state=open]:rotate-90" />
              Ver enunciado
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent className="mt-2 rounded-lg border p-4">
            <MarkdownContent className="prose-sm">{answer.prompt}</MarkdownContent>
          </CollapsibleContent>
        </Collapsible>

        {answer.value.trim() ? (
          <CodeBlock
            code={answer.value}
            language={guessLanguage(answer.value)}
            className="max-h-[32rem] overflow-y-auto"
          />
        ) : (
          <p className="text-sm text-muted-foreground italic">(respuesta vacía)</p>
        )}
      </CardContent>
    </Card>
  )
}
