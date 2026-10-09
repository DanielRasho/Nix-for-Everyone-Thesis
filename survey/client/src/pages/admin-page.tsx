import { useQuery } from '@tanstack/react-query'
import { DownloadIcon, FileArchiveIcon } from 'lucide-react'
import { ErrorState, LoadingState } from '@/components/page-state'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { GradingList } from '@/features/admin/grading-list'
import { NewParticipantDialog } from '@/features/admin/new-participant-dialog'
import { ParticipantsTable } from '@/features/admin/participants-table'
import { api, EXPORT_CODE_URL, EXPORT_CSV_URL } from '@/lib/api'
import { keys } from '@/lib/query-client'

export function AdminPage() {
  const participants = useQuery({
    queryKey: keys.participants,
    queryFn: api.participants,
    meta: { silent: true },
  })
  const grading = useQuery({ queryKey: keys.grading, queryFn: api.grading, meta: { silent: true } })

  const list = participants.data?.participants ?? []
  const pendingGrades = grading.data?.answers.filter((a) => a.isCorrect === null).length ?? 0

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end gap-3">
        <div className="mr-auto space-y-1">
          <h1 className="font-heading text-2xl font-semibold tracking-tight">Panel de administración</h1>
          <p className="text-muted-foreground">
            {participants.isSuccess ? `${list.length} participantes` : 'Participantes, calificación y exportación.'}
          </p>
        </div>
        <Button variant="outline" asChild>
          <a href={EXPORT_CSV_URL} download>
            <DownloadIcon />
            Exportar CSV
          </a>
        </Button>
        <Button variant="outline" asChild>
          <a href={EXPORT_CODE_URL} download title="Respuestas de código, una carpeta por participante">
            <FileArchiveIcon />
            Exportar código
          </a>
        </Button>
        <NewParticipantDialog participants={list} />
      </div>

      <Tabs defaultValue="participants" className="gap-4">
        <TabsList>
          <TabsTrigger value="participants">Participantes</TabsTrigger>
          <TabsTrigger value="grading">
            Calificación
            {pendingGrades > 0 && (
              <Badge variant="secondary" className="ml-1 tabular-nums">
                {pendingGrades}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="participants">
          {participants.isPending ? (
            <LoadingState />
          ) : participants.isError ? (
            <ErrorState error={participants.error} onRetry={() => void participants.refetch()} />
          ) : (
            <ParticipantsTable participants={list} />
          )}
        </TabsContent>

        <TabsContent value="grading">
          {grading.isPending ? (
            <LoadingState />
          ) : grading.isError ? (
            <ErrorState error={grading.error} onRetry={() => void grading.refetch()} />
          ) : (
            <GradingList answers={grading.data.answers} />
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}
