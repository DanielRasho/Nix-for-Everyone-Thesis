import type { ReactNode } from 'react'
import { AlertTriangleIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Spinner } from '@/components/ui/spinner'
import { errorDetail, errorTitle } from '@/lib/api'
import { cn } from '@/lib/utils'

export function LoadingState({ label = 'Cargando…', className }: { label?: string; className?: string }) {
  return (
    <div className={cn('flex items-center justify-center gap-2 py-16 text-muted-foreground', className)}>
      <Spinner />
      <span className="text-sm">{label}</span>
    </div>
  )
}

interface ErrorStateProps {
  error: unknown
  title?: string
  onRetry?: () => void
  children?: ReactNode
  className?: string
}

export function ErrorState({ error, title, onRetry, children, className }: ErrorStateProps) {
  return (
    <div className={cn('mx-auto flex max-w-md flex-col items-center gap-3 py-16 text-center', className)}>
      <AlertTriangleIcon className="size-8 text-destructive" />
      <h2 className="font-heading text-lg font-semibold">{title ?? errorTitle(error)}</h2>
      <p className="text-sm whitespace-pre-line text-muted-foreground">{errorDetail(error)}</p>
      <div className="flex flex-wrap justify-center gap-2">
        {onRetry && (
          <Button variant="outline" onClick={onRetry}>
            Reintentar
          </Button>
        )}
        {children}
      </div>
    </div>
  )
}
