import { useEffect, useMemo, useState } from 'react'
import type { HighlighterCore } from 'shiki/core'
import { getHighlighter, highlight, loadedHighlighter } from '@/lib/highlighter'

/**
 * Shiki HTML of `code`, or undefined while shiki loads (or if it fails):
 * show the plain text meanwhile.
 */
export function useHighlightedHtml(code: string, language?: string, focusable = true): string | undefined {
  const [highlighter, setHighlighter] = useState<HighlighterCore | undefined>(loadedHighlighter)

  useEffect(() => {
    if (highlighter) return
    let alive = true
    getHighlighter()
      .then((h) => alive && setHighlighter(h))
      .catch((err: unknown) => console.error('shiki failed to load', err))
    return () => {
      alive = false
    }
  }, [highlighter])

  return useMemo(() => {
    if (!highlighter) return undefined
    try {
      return highlight(highlighter, code, language, focusable)
    } catch (err) {
      console.error('shiki failed to highlight', err)
      return undefined
    }
  }, [highlighter, code, language, focusable])
}
