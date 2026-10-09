import { useState } from 'react'
import { ChevronRightIcon, ExternalLinkIcon } from 'lucide-react'
import { CodeBlock } from '@/components/code-block'
import { CodeEditor } from '@/components/code-editor'
import { MarkdownContent } from '@/components/markdown'
import { Button } from '@/components/ui/button'
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from '@/components/ui/collapsible'
import { Label } from '@/components/ui/label'
import { SubmitBar, type QuestionProps } from '@/features/questions/shared'

/** Solved in Codespaces, the resulting code is pasted back here. */
export function FreeCodeQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const [value, setValue] = useState('')
  const empty = value.trim() === ''
  const canSubmit = question.optional || !empty
  const lines = question.code ? question.code.replace(/\s+$/, '').split('\n').length : 0

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>

      {step.codespace && (
        <Button asChild size="lg">
          <a href={step.codespace} target="_blank" rel="noopener noreferrer">
            <ExternalLinkIcon />
            Abrir Codespace
          </a>
        </Button>
      )}

      {question.code && (
        <Collapsible className="space-y-2">
          <CollapsibleTrigger asChild>
            <Button variant="outline" className="group">
              <ChevronRightIcon className="transition-transform group-data-[state=open]:rotate-90" />
              Código inicial
              <span className="text-muted-foreground">({lines} líneas)</span>
            </Button>
          </CollapsibleTrigger>
          <CollapsibleContent>
            <CodeBlock code={question.code} language={step.language} copyable />
          </CollapsibleContent>
        </Collapsible>
      )}

      <div className="grid gap-2">
        <Label htmlFor="free-code-answer">
          Tu solución{question.optional && <span className="font-normal text-muted-foreground">(opcional)</span>}
        </Label>
        <p className="text-sm text-muted-foreground">
          Cuando estés conforme con tu solución, copia el código solicitado y pégalo aquí.
        </p>
        <CodeEditor
          id="free-code-answer"
          value={value}
          onChange={setValue}
          language={step.language}
          placeholder="Pega aquí tu código…"
          className="min-h-80"
        />
      </div>

      <SubmitBar
        canSubmit={canSubmit}
        submitting={submitting}
        label={question.optional && empty ? 'Omitir' : 'Enviar respuesta'}
        variant={question.optional && empty ? 'outline' : 'default'}
        onSubmit={() => onSubmit({ questionId: question.id, value: empty ? '' : value })}
      />
    </div>
  )
}
