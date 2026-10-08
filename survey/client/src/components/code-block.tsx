import { useEffect, useMemo, useState } from 'react'
import type { HighlighterCore } from 'shiki/core'
import { cn } from '@/lib/utils'
import { getHighlighter, highlight, loadedHighlighter } from '@/lib/highlighter'

interface CodeBlockProps {
  code: string
  /** Survey language (`nix` | `typescript`); anything else renders as plain text. */
  language?: string
  lineNumbers?: boolean
  className?: string
}

/** Syntax-highlighted, read-only code. Shows plain text until shiki has loaded. */
export function CodeBlock({ code, language, lineNumbers = true, className }: CodeBlockProps) {
  const source = useMemo(() => code.replace(/\s+$/, ''), [code])
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

  const html = useMemo(() => {
    if (!highlighter) return undefined
    try {
      return highlight(highlighter, source, language)
    } catch (err) {
      console.error('shiki failed to highlight', err)
      return undefined
    }
  }, [highlighter, source, language])

  return (
    <div
      className={cn('code-block', lineNumbers && 'line-numbers', className)}
      data-language={language}
    >
      {html ? (
        // shiki escapes the code, the HTML only contains its own spans.
        <div dangerouslySetInnerHTML={{ __html: html }} />
      ) : (
        <pre className="shiki" tabIndex={0}>
          <code>
            {source.split('\n').map((line, i) => (
              <span key={i} className="line">
                {line}
                {'\n'}
              </span>
            ))}
          </code>
        </pre>
      )}
    </div>
  )
}
