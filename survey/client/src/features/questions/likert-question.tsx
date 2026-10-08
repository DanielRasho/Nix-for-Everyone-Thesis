import { useState } from 'react'
import { MarkdownContent } from '@/components/markdown'
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group'
import { SubmitBar, type QuestionProps } from '@/features/questions/shared'
import type { LikertItem } from '@/lib/types'
import { cn } from '@/lib/utils'

/** One row per item: label, left word, 1..scale radios, right word. Every item is required. */
export function LikertQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const scale = question.scale ?? 5
  const items = question.items ?? []
  const [values, setValues] = useState<Record<string, number>>({})
  const answered = items.filter((item) => values[item.id] !== undefined).length
  const complete = items.length > 0 && answered === items.length

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>

      <p className="text-sm text-muted-foreground">
        Escala del 1 al {scale}. {answered} de {items.length} respondidas.
      </p>

      <div className="divide-y overflow-hidden rounded-lg border">
        {items.map((item) => (
          <LikertRow
            key={item.id}
            item={item}
            scale={scale}
            value={values[item.id]}
            onChange={(n) => setValues((prev) => ({ ...prev, [item.id]: n }))}
          />
        ))}
      </div>

      <SubmitBar
        canSubmit={complete}
        submitting={submitting}
        onSubmit={() => onSubmit({ questionId: question.id, likert: values })}
      />
    </div>
  )
}

interface LikertRowProps {
  item: LikertItem
  scale: number
  value: number | undefined
  onChange: (value: number) => void
}

function LikertRow({ item, scale, value, onChange }: LikertRowProps) {
  const points = Array.from({ length: scale }, (_, i) => i + 1)
  const name = item.label ? `${item.label}: ${item.left} – ${item.right}` : `${item.left} – ${item.right}`

  return (
    <div className={cn('space-y-2 p-4 transition-colors', value !== undefined && 'bg-muted/40')}>
      {item.label && <p className="font-medium">{item.label}</p>}
      {/* Narrow: words on one line, radios below. md+: left word | radios | right word. */}
      <div className="grid grid-cols-2 items-center gap-x-4 gap-y-2 md:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)]">
        <span className="text-sm md:text-right">{item.left}</span>
        <span className="text-right text-sm md:order-last md:text-left">{item.right}</span>
        <RadioGroup
          orientation="horizontal"
          value={value === undefined ? '' : String(value)}
          onValueChange={(v) => onChange(Number(v))}
          aria-label={name}
          className="col-span-2 flex w-full justify-between gap-1 md:col-span-1 md:w-auto md:justify-center md:gap-2"
        >
          {points.map((n) => (
            <label
              key={n}
              className="flex min-w-8 cursor-pointer flex-col items-center gap-1 rounded-md px-1 py-1 hover:bg-muted"
            >
              <RadioGroupItem
                value={String(n)}
                aria-label={`${n} de ${scale}`}
                className="size-5 border-muted-foreground/50"
              />
              <span className="text-xs text-muted-foreground tabular-nums">{n}</span>
            </label>
          ))}
        </RadioGroup>
      </div>
    </div>
  )
}
