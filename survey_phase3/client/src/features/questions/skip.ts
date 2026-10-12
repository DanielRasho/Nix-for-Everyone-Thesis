import type { QuestionProps } from '@/features/questions/shared'

/** Skips an optional question without answering it; undefined for required ones. */
export function skipHandler({ question, onSubmit }: Pick<QuestionProps, 'question' | 'onSubmit'>) {
  return question.optional ? () => onSubmit({ questionId: question.id, skipped: true }) : undefined
}
