import { useState } from 'react'
import { CodeBlock } from '@/components/code-block'
import { MarkdownContent, MarkdownInline } from '@/components/markdown'
import { RadioGroup } from '@/components/ui/radio-group'
import { optionLetter } from '@/features/questions/options'
import { OptionCard, SubmitBar, type QuestionProps } from '@/features/questions/shared'
import { cn } from '@/lib/utils'

/**
 * LEFT: the code. RIGHT: prompt and the text options.
 * On narrow screens: prompt, code, options.
 */
export function ChoiceTextQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  const [selected, setSelected] = useState<string>()
  const options = question.options ?? []
  const hasCode = Boolean(question.code)

  return (
    <div className="space-y-6">
      <div
        className={cn(
          'grid gap-6',
          hasCode ? 'lg:grid-cols-2 lg:grid-rows-[auto_1fr] lg:items-start' : 'mx-auto max-w-3xl',
        )}
      >
        <div className={cn('min-w-0', hasCode && 'lg:col-start-2 lg:row-start-1')}>
          <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>
        </div>

        {question.code && (
          <div className="min-w-0 lg:sticky lg:top-20 lg:col-start-1 lg:row-span-2 lg:row-start-1 lg:max-h-[calc(100svh-6rem)] lg:overflow-y-auto">
            <CodeBlock code={question.code} language={step.language} />
          </div>
        )}

        <RadioGroup
          value={selected ?? ''}
          onValueChange={setSelected}
          aria-label="Opciones"
          className={cn('min-w-0 grid-cols-1 content-start', hasCode && 'lg:col-start-2 lg:row-start-2')}
        >
          {options.map((option, i) => (
            <OptionCard
              key={option.id}
              id={`option-${option.id}`}
              value={option.id}
              letter={optionLetter(i)}
              selected={selected === option.id}
            >
              <MarkdownInline language={step.language}>{option.text ?? ''}</MarkdownInline>
            </OptionCard>
          ))}
        </RadioGroup>
      </div>

      <SubmitBar
        canSubmit={selected !== undefined}
        submitting={submitting}
        onSubmit={() => selected && onSubmit({ questionId: question.id, optionId: selected })}
      />
    </div>
  )
}
