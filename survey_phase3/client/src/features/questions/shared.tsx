import { useState, type ReactNode } from 'react'
import { ArrowRightIcon, SendIcon, SkipForwardIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { RadioGroupItem } from '@/components/ui/radio-group'
import { Spinner } from '@/components/ui/spinner'
import type { Answer, CurrentStep, Question } from '@/lib/types'
import { cn } from '@/lib/utils'

export interface QuestionProps {
  question: Question
  step: CurrentStep
  submitting: boolean
  onSubmit: (answer: Answer) => void
}

interface SubmitBarProps {
  /** False until the answer is valid. */
  canSubmit: boolean
  submitting: boolean
  onSubmit: () => void
  /** Shows the "Saltar" button (optional questions, see `skipHandler`). */
  onSkip?: () => void
  label?: string
  /** Hidden for info screens: there is nothing to change. */
  showHint?: boolean
  /** Arrow instead of the "send" icon (info screens). */
  next?: boolean
  className?: string
}

export function SubmitBar({
  canSubmit,
  submitting,
  onSubmit,
  onSkip,
  label = 'Enviar respuesta',
  showHint = true,
  next = false,
  className,
}: SubmitBarProps) {
  // Which button was pressed, so the spinner shows on it.
  const [skipping, setSkipping] = useState(false)

  return (
    <div
      className={cn(
        'flex flex-col-reverse items-stretch gap-3 border-t pt-4 sm:flex-row sm:items-center sm:justify-end',
        className,
      )}
    >
      {showHint && (
        <p className="text-xs text-muted-foreground sm:mr-auto">
          Una vez enviada, la respuesta no se puede modificar.
        </p>
      )}
      {onSkip && (
        <Button
          size="lg"
          variant="warning"
          disabled={submitting}
          onClick={() => {
            setSkipping(true)
            onSkip()
          }}
          className="sm:min-w-28"
        >
          {submitting && skipping ? <Spinner /> : <SkipForwardIcon />}
          Saltar
        </Button>
      )}
      <Button
        size="lg"
        disabled={!canSubmit || submitting}
        onClick={() => {
          setSkipping(false)
          onSubmit()
        }}
        className="sm:min-w-40"
      >
        {submitting && !skipping ? <Spinner /> : next ? null : <SendIcon />}
        {label}
        {next && !submitting && <ArrowRightIcon />}
      </Button>
    </div>
  )
}

interface OptionCardProps {
  id: string
  value: string
  letter: string
  selected: boolean
  children: ReactNode
  className?: string
}

/** A clickable radio row (must be inside a RadioGroup). */
export function OptionCard({ id, value, letter, selected, children, className }: OptionCardProps) {
  return (
    <Label
      htmlFor={id}
      className={cn(
        'flex min-w-0 cursor-pointer items-start gap-3 rounded-lg border p-3 leading-relaxed font-normal transition-colors hover:bg-muted/50',
        selected && 'border-primary bg-muted/60 ring-1 ring-primary hover:bg-muted/60',
        className,
      )}
    >
      <RadioGroupItem id={id} value={value} className="mt-1 border-muted-foreground/50" />
      <span className="font-semibold">{letter})</span>
      <div className="min-w-0 flex-1">{children}</div>
    </Label>
  )
}

export function SectionLabel({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <p className={cn('mb-2 text-xs font-medium tracking-wide text-muted-foreground uppercase', className)}>
      {children}
    </p>
  )
}
