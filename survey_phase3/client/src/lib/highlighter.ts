import type { HighlighterCore } from 'shiki/core'
import type { Language } from '@/lib/types'

// Fine-grained shiki bundle: only the two survey languages and two themes, with
// the JavaScript regex engine (no WASM). Loaded lazily the first time code is shown.
let highlighter: Promise<HighlighterCore> | undefined
let loaded: HighlighterCore | undefined

/** The highlighter if it already finished loading (to render synchronously). */
export function loadedHighlighter(): HighlighterCore | undefined {
  return loaded
}

export function getHighlighter(): Promise<HighlighterCore> {
  highlighter ??= (async () => {
    const [{ createHighlighterCore }, { createJavaScriptRegexEngine }] = await Promise.all([
      import('shiki/core'),
      import('shiki/engine/javascript'),
    ])
    loaded = await createHighlighterCore({
      themes: [import('shiki/themes/github-light.mjs'), import('shiki/themes/github-dark.mjs')],
      langs: [import('shiki/langs/nix.mjs'), import('shiki/langs/typescript.mjs')],
      engine: createJavaScriptRegexEngine(),
    })
    return loaded
  })()
  return highlighter
}

/** Shiki language for a survey language; anything else is shown as plain text. */
export function shikiLang(language?: string): string {
  if (language === 'nix') return 'nix'
  if (language === 'typescript' || language === 'ts') return 'typescript'
  return 'text'
}

/**
 * Both themes are emitted as CSS variables (--shiki-light / --shiki-dark) and
 * index.css picks one from the `dark` class, so code follows the app theme
 * without re-highlighting.
 * `focusable` keeps the <pre> in the tab order (to scroll it with the keyboard).
 */
export function highlight(h: HighlighterCore, code: string, language?: string, focusable = true): string {
  return h.codeToHtml(code, {
    lang: shikiLang(language),
    themes: { light: 'github-light', dark: 'github-dark' },
    defaultColor: false,
    tabindex: focusable ? 0 : false,
  })
}

/**
 * The admin grading view has no survey language, so it is guessed from the
 * pasted code: TypeScript markers that never appear in Nix.
 */
export function guessLanguage(code: string): Language {
  return /\b(const|export|interface|function)\s|=>|\bfrom\s+['"]/.test(code) ? 'typescript' : 'nix'
}
