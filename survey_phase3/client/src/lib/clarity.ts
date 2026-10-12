// Microsoft Clarity, loaded only once a participant enters a survey step (not in
// the background questions nor the admin panel). Skipped when no project id is set.

type ClarityFn = ((...args: unknown[]) => void) & { q?: unknown[][] }

declare global {
  interface Window {
    clarity?: ClarityFn
  }
}

let loaded = false

/** Whether the Clarity script was injected in this page load. */
export function isClarityLoaded() {
  return loaded
}

function load(projectId: string) {
  if (loaded) return
  loaded = true

  // Same as the official snippet: queue calls until the script arrives.
  if (!window.clarity) {
    const queue: ClarityFn = (...args: unknown[]) => {
      ;(queue.q ??= []).push(args)
    }
    window.clarity = queue
  }

  const script = document.createElement('script')
  script.async = true
  script.src = `https://www.clarity.ms/tag/${encodeURIComponent(projectId)}`
  document.head.appendChild(script)
}

/** Starts (or keeps) recording and tags the session with the participant and survey. */
export function trackSurvey(username: string, surveyId: string) {
  const projectId = import.meta.env.VITE_CLARITY_PROJECT_ID
  if (!projectId) return

  load(projectId)
  window.clarity?.('identify', username)
  window.clarity?.('set', 'survey', surveyId)
}
