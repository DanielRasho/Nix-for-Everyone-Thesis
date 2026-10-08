import { useState } from 'react'
import { MarkdownContent } from '@/components/markdown'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { SubmitBar, type QuestionProps } from '@/features/questions/shared'

export function FreeTextQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const [value, setValue] = useState('')
  const empty = value.trim() === ''
  const skip = Boolean(question.optional) && empty

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
          placeholder={question.optional ? 'Puedes dejarlo en blanco y omitir la pregunta.' : 'Escribe tu respuesta…'}
          className="min-h-36"
        />
      </div>

      <SubmitBar
        canSubmit={question.optional || !empty}
        submitting={submitting}
        label={skip ? 'Omitir' : 'Enviar respuesta'}
        variant={skip ? 'outline' : 'default'}
        // Whitespace-only counts as empty.
        onSubmit={() => onSubmit({ questionId: question.id, value: empty ? '' : value })}
      />
    </div>
  )
}
