import { useMemo } from 'react'
import { CopyButton } from '@/components/copy-button'
import { useHighlightedHtml } from '@/hooks/use-highlighted-html'
import { cn } from '@/lib/utils'

interface CodeBlockProps {
  code: string
  /** Survey language (`nix` | `typescript`); anything else renders as plain text. */
  language?: string
  lineNumbers?: boolean
  /** Shows a copy button in the top right corner. */
  copyable?: boolean
  className?: string
}

/** Syntax-highlighted, read-only code. Shows plain text until shiki has loaded. */
export function CodeBlock({ code, language, lineNumbers = true, copyable = false, className }: CodeBlockProps) {
  const source = useMemo(() => code.replace(/\s+$/, ''), [code])
  const html = useHighlightedHtml(source, language)

  return (
    <div
      className={cn('code-block', lineNumbers && 'line-numbers', copyable && 'relative', className)}
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
      {copyable && <CopyButton text={code} className="absolute top-2 right-2" />}
    </div>
  )
}
