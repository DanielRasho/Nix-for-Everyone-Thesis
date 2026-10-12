// Shapes of the API contract (see CLAUDE.md, "API contract"). JSON is camelCase.

export type Role = 'admin' | 'participant'

export interface User {
  id: string
  username: string
  role: Role
}

export type StepStatus = 'locked' | 'available' | 'in_progress' | 'completed'

/** A roadmap step: "background" or a survey id. Dates only come in admin views. */
export interface Step {
  id: 'background' | (string & {})
  title: string
  position?: number
  status: StepStatus
  answered: number
  total: number
  startedAt?: string
  completedAt?: string
}

export interface Participant {
  id: string
  username: string
  createdAt: string
  steps: Step[]
}

export type Language = 'nix' | 'typescript'

export interface CurrentStep {
  id: string
  title: string
  tool?: string
  language?: Language
  codespace?: string
}

export interface Progress {
  answered: number
  total: number
}

/** The current (first unanswered) question of a step. `question: null` = step finished. */
export interface Current {
  step: CurrentStep
  progress: Progress
  question: Question | null
}

export type QuestionKind =
  | 'info'
  | 'choice_code'
  | 'choice_text'
  | 'free_code'
  | 'free_text'
  | 'likert'

export type Section = 'background' | 'tasks' | 'feedback'

export interface QuestionOption {
  id: string
  /** Markdown, choice_text only. */
  text?: string
  /** Code, choice_code only. */
  code?: string
}

export interface LikertItem {
  id: string
  label?: string
  left: string
  right: string
}

export interface Question {
  id: string
  kind: QuestionKind
  section: Section
  /** Markdown. */
  prompt: string
  /** Reference snippet, or the starter code of a free_code question. */
  code?: string
  options?: QuestionOption[]
  scale?: 5 | 7
  items?: LikertItem[]
  /** Can be skipped ("Saltar"). Never set on info screens. */
  optional?: boolean
}

export type Answer =
  | { questionId: string } // info
  | { questionId: string; optionId: string } // choice_code / choice_text
  | { questionId: string; value: string } // free_code / free_text (empty ok if optional)
  | { questionId: string; likert: Record<string, number> } // every item, 1..scale
  | { questionId: string; skipped: true } // optional questions of any kind: nothing is stored

export interface GradingAnswer {
  userId: string
  username: string
  questionId: string
  prompt: string
  value: string
  isCorrect: boolean | null
  answeredAt: string
}

export interface SurveySummary {
  id: string
  title: string
}

/** Every error response: `{ message, errors?: { field: reason } }`. */
export interface ApiErrorBody {
  message: string
  errors?: Record<string, string>
}
