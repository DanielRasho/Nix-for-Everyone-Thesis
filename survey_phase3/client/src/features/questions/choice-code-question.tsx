import { useState } from 'react'
import { MousePointerClickIcon } from 'lucide-react'
import { CodeBlock } from '@/components/code-block'
import { MarkdownContent } from '@/components/markdown'
import { RadioGroup } from '@/components/ui/radio-group'
import { optionLetter } from '@/features/questions/options'
import { OptionCard, SectionLabel, SubmitBar, type QuestionProps } from '@/features/questions/shared'
import { skipHandler } from '@/features/questions/skip'

/**
 * Options are code. LEFT: prompt, reference code and every option in full
 * (highlighted) inside a scrollable container. RIGHT: the selected option.
 */
export function ChoiceCodeQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const [selected, setSelected] = useState<string>()
  const options = question.options ?? []
  const selectedIndex = options.findIndex((o) => o.id === selected)
  const selectedOption = selectedIndex >= 0 ? options[selectedIndex] : undefined

  return (
    <div className="space-y-6">
      <div className="grid gap-6 lg:grid-cols-2 lg:items-start">
        <div className="min-w-0 space-y-5">
          <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>

          {question.code && (
            <div>
              <SectionLabel>Código de referencia</SectionLabel>
              <CodeBlock code={question.code} language={step.language} />
            </div>
          )}

          <div>
            <SectionLabel>Opciones · desplázate para ver todas</SectionLabel>
            <RadioGroup
              value={selected ?? ''}
              onValueChange={setSelected}
              aria-label="Opciones"
              className="grid-cols-1 gap-3 md:max-h-[calc(100svh-16rem)] md:overflow-y-auto md:rounded-lg md:border md:bg-muted/20 md:p-3"
            >
              {options.map((option, i) => (
                <OptionCard
                  key={option.id}
                  id={`option-${option.id}`}
                  value={option.id}
                  letter={optionLetter(i)}
                  selected={selected === option.id}
                  className="bg-background"
                >
                  <CodeBlock code={option.code ?? ''} language={step.language} />
                </OptionCard>
              ))}
            </RadioGroup>
          </div>
        </div>

        <div className="min-w-0 lg:sticky lg:top-20 lg:max-h-[calc(100svh-6rem)] lg:overflow-y-auto">
          {selectedOption ? (
            <div>
              <SectionLabel>Opción {optionLetter(selectedIndex)})</SectionLabel>
              <CodeBlock code={selectedOption.code ?? ''} language={step.language} />
            </div>
          ) : (
            <div className="flex min-h-48 flex-col items-center justify-center gap-2 rounded-lg border border-dashed p-6 text-center text-sm text-muted-foreground">
              <MousePointerClickIcon className="size-5" />
              Selecciona una opción para verla aquí.
            </div>
          )}
        </div>
      </div>

      <SubmitBar
        canSubmit={selected !== undefined}
        submitting={submitting}
        onSubmit={() => selected && onSubmit({ questionId: question.id, optionId: selected })}
        onSkip={skipHandler({ question, onSubmit })}
      />
    </div>
  )
}
