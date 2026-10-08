import { useEffect, useRef } from 'react'
import { api, isApiError } from '@/lib/api'
import { sessionExpired } from '@/lib/query-client'

export const HEARTBEAT_MS = 15_000

/**
 * Tells the server a question is on screen: right away, every 15 s and again
 * when the tab becomes visible. It keeps running while the tab is hidden, since
 * participants work in Codespaces in another tab (browsers throttle hidden timers
 * to ~1/min, the server tolerates gaps up to 90 s). Stops when the question
 * changes or the component unmounts.
 *
 * `onStale` runs on 409 (the question is no longer the current one, e.g. it was
 * answered in another tab) so the caller can reload the current question.
 */
export function useHeartbeat(questionId: string | undefined, onStale: () => void) {
  const onStaleRef = useRef(onStale)
  useEffect(() => {
    onStaleRef.current = onStale
  })

  useEffect(() => {
    if (!questionId) return
    let active = true

    const beat = () => {
      api.heartbeat(questionId).catch((err: unknown) => {
        if (!active) return
        if (isApiError(err, 409)) onStaleRef.current()
        else if (isApiError(err, 401)) sessionExpired()
        else console.warn('heartbeat failed', err)
      })
    }

    const onVisibility = () => {
      if (document.visibilityState === 'visible') beat()
    }

    beat()
    const timer = window.setInterval(beat, HEARTBEAT_MS)
    document.addEventListener('visibilitychange', onVisibility)

    return () => {
      active = false
      window.clearInterval(timer)
      document.removeEventListener('visibilitychange', onVisibility)
    }
  }, [questionId])
}
