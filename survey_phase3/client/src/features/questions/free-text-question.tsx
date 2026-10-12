import { useState } from 'react'
import { MarkdownContent } from '@/components/markdown'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { SubmitBar, type QuestionProps } from '@/features/questions/shared'
import { skipHandler } from '@/features/questions/skip'

export function FreeTextQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const [value, setValue] = useState('')
  const empty = value.trim() === ''

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>

      <div className="grid gap-2">
        <Label htmlFor="free-text-answer">
          Tu respuesta
          {question.optional && <span className="font-normal text-muted-foreground">(opcional)</span>}
        </Label>
        <Textarea
          id="free-text-answer"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="Escribe tu respuesta…"
          className="min-h-36"
        />
      </div>

      <SubmitBar
        // Whitespace-only counts as empty.
        canSubmit={!empty}
        submitting={submitting}
        onSubmit={() => onSubmit({ questionId: question.id, value })}
        onSkip={skipHandler({ question, onSubmit })}
      />
    </div>
  )
}
