import { CheckIcon, CircleDotIcon, LockIcon, PlayIcon } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'
import type { StepStatus } from '@/lib/types'

const statusLabel: Record<StepStatus, string> = {
  locked: 'Bloqueado',
  available: 'Disponible',
  in_progress: 'En progreso',
  completed: 'Completado',
}

const statusIcon = {
  locked: LockIcon,
  available: PlayIcon,
  in_progress: CircleDotIcon,
  completed: CheckIcon,
} satisfies Record<StepStatus, unknown>

const statusClass: Record<StepStatus, string> = {
  locked: 'bg-muted text-muted-foreground',
  available: 'border-border bg-background text-foreground',
  in_progress: 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
  completed: 'bg-success/15 text-success',
}

export function StatusBadge({ status, className }: { status: StepStatus; className?: string }) {
  const Icon = statusIcon[status]
  return (
    <Badge variant="outline" className={cn('border-transparent', statusClass[status], className)}>
      <Icon data-icon="inline-start" />
      {statusLabel[status]}
    </Badge>
  )
}
