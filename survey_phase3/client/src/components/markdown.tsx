import Markdown, { type Components } from 'react-markdown'
import remarkGfm from 'remark-gfm'
import { CodeBlock } from '@/components/code-block'
import { cn } from '@/lib/utils'

const inlineCode = 'rounded bg-muted px-1 py-0.5 font-mono text-[0.9em] font-normal'

function components(language?: string): Components {
  return {
    // Fenced blocks: `pre` only wraps, `code` decides between block and inline.
    pre: ({ children }) => <div className="not-prose my-3">{children}</div>,
    code: ({ className, children }) => {
      const text = String(children ?? '')
      const lang = /language-(\w+)/.exec(className ?? '')?.[1]
      if (lang || text.includes('\n')) {
        return <CodeBlock code={text} language={lang ?? language} lineNumbers={false} />
      }
      return <code className={inlineCode}>{children}</code>
    },
    a: ({ children, href }) => (
      <a href={href} target="_blank" rel="noopener noreferrer">
        {children}
      </a>
    ),
  }
}

interface MarkdownProps {
  children: string
  /** Code language for fenced blocks without one. */
  language?: string
  className?: string
}

/** Block Markdown (prompts, info screens). */
export function MarkdownContent({ children, language, className }: MarkdownProps) {
  return (
    <div
      className={cn(
        'prose prose-neutral dark:prose-invert max-w-none prose-headings:font-heading prose-headings:font-semibold prose-code:before:content-none prose-code:after:content-none',
        className,
      )}
    >
      <Markdown remarkPlugins={[remarkGfm]} components={components(language)}>
        {children}
      </Markdown>
    </div>
  )
}

function inlineComponents(language?: string): Components {
  return {
    ...components(language),
    // Fenced blocks are kept (code options); the wrapper is a span to stay valid inside the option.
    pre: ({ children }) => <span className="my-1 block">{children}</span>,
    p: ({ children }) => <>{children}</>,
  }
}

/**
 * Inline Markdown (option texts): no paragraphs, just emphasis and code.
 * A fenced block (```nix ... ```) renders as a highlighted code block, keeping line breaks.
 */
export function MarkdownInline({ children, language, className }: MarkdownProps) {
  return (
    <span className={className}>
      <Markdown remarkPlugins={[remarkGfm]} components={inlineComponents(language)}>
        {children}
      </Markdown>
    </span>
  )
}
