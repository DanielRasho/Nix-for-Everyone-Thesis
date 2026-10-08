import { ErrorState } from '@/components/page-state'
import { ChoiceCodeQuestion } from '@/features/questions/choice-code-question'
import { ChoiceTextQuestion } from '@/features/questions/choice-text-question'
import { FreeCodeQuestion } from '@/features/questions/free-code-question'
import { FreeTextQuestion } from '@/features/questions/free-text-question'
import { InfoQuestion } from '@/features/questions/info-question'
import { LikertQuestion } from '@/features/questions/likert-question'
import type { QuestionProps } from '@/features/questions/shared'

/** Renders a question by kind. Mount it with `key={question.id}` so state resets per question. */
export function QuestionView(props: QuestionProps) {
  switch (props.question.kind) {
    case 'info':
      return <InfoQuestion {...props} />
    case 'choice_code':
      return <ChoiceCodeQuestion {...props} />
    case 'choice_text':
      return <ChoiceTextQuestion {...props} />
    case 'free_code':
      return <FreeCodeQuestion {...props} />
    case 'free_text':
      return <FreeTextQuestion {...props} />
    case 'likert':
      return <LikertQuestion {...props} />
    default:
      return (
        <ErrorState
          title="Tipo de pregunta desconocido"
          error={new Error(`La pregunta ${props.question.id} tiene un tipo no soportado.`)}
        />
      )
  }
}
