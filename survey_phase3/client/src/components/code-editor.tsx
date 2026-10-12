import type { ComponentProps } from 'react'
import { useHighlightedHtml } from '@/hooks/use-highlighted-html'
import { cn } from '@/lib/utils'

interface CodeEditorProps extends Omit<ComponentProps<'textarea'>, 'value' | 'onChange'> {
  value: string
  onChange: (value: string) => void
  /** Survey language (`nix` | `typescript`); anything else renders as plain text. */
  language?: string
}

/**
 * Textarea with syntax highlighting: its text is transparent and it sits over a
 * shiki <pre> of the same text, laid out identically (see `.code-editor` in
 * index.css). The <pre> sets the size, so the textarea never scrolls and the
 * container scrolls both together.
 */
export function CodeEditor({ value, onChange, language, className, ...props }: CodeEditorProps) {
  // The <pre> drops an empty last line, which the textarea does show.
  const shown = value.endsWith('\n') ? `${value} ` : value
  const html = useHighlightedHtml(shown, language, false)

  return (
    <div className={cn('code-editor', className)} data-language={language}>
      <div className="code-editor-content">
        {html ? (
          // shiki escapes the code, the HTML only contains its own spans.
          <div aria-hidden dangerouslySetInnerHTML={{ __html: html }} />
        ) : (
          <pre aria-hidden className="shiki">
            {shown}
          </pre>
        )}
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          spellCheck={false}
          autoCapitalize="off"
          autoCorrect="off"
          autoComplete="off"
          wrap="off"
          {...props}
        />
      </div>
    </div>
  )
}
