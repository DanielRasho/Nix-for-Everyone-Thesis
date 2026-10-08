import type { Participant, SurveySummary } from '@/lib/types'

export interface SurveyOrderOption {
  /** Survey ids joined with ",". */
  key: string
  order: string[]
  label: string
}

function permutations<T>(items: T[]): T[][] {
  if (items.length <= 1) return [items]
  return items.flatMap((item, i) =>
    permutations([...items.slice(0, i), ...items.slice(i + 1)]).map((rest) => [item, ...rest]),
  )
}

/** Every order of the surveys, e.g. "Nixty → Nix" and "Nix → Nixty". */
export function surveyOrderOptions(surveys: SurveySummary[]): SurveyOrderOption[] {
  // Only a handful of surveys exist; cap the factorial just in case.
  const list = surveys.length <= 4 ? permutations(surveys) : [surveys]
  return list.map((order) => ({
    key: order.map((s) => s.id).join(','),
    order: order.map((s) => s.id),
    label: order.map((s) => s.title).join(' → '),
  }))
}

/** The participant's surveys (not "background") in their assigned order. */
export function participantSurveySteps(p: Participant) {
  return p.steps
    .filter((s) => s.id !== 'background')
    .sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
}

export function participantOrderKey(p: Participant): string {
  return participantSurveySteps(p)
    .map((s) => s.id)
    .join(',')
}
