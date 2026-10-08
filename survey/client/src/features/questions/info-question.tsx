import { MarkdownContent } from '@/components/markdown'
import { SubmitBar, type QuestionProps } from '@/features/questions/shared'

export function InfoQuestion({ question, step, submitting, onSubmit }: QuestionProps) {
  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <MarkdownContent language={step.language}>{question.prompt}</MarkdownContent>
      <SubmitBar
        canSubmit
        submitting={submitting}
        label="Continuar"
        showHint={false}
        next
        onSubmit={() => onSubmit({ questionId: question.id })}
      />
    </div>
  )
}
