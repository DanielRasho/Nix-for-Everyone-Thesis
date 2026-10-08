import { createContext } from 'react'

export type Theme = 'light' | 'dark' | 'system'
export type ResolvedTheme = 'light' | 'dark'

/** Must match the key read by the inline script in index.html. */
export const STORAGE_KEY = 'survey-theme'

export interface ThemeContextValue {
  theme: Theme
  resolvedTheme: ResolvedTheme
  setTheme: (theme: Theme) => void
}

export const ThemeContext = createContext<ThemeContextValue | null>(null)

// localStorage can throw (private mode, blocked storage): the app must work without it.
export function readStoredTheme(): Theme {
  try {
    const value = localStorage.getItem(STORAGE_KEY)
    if (value === 'light' || value === 'dark' || value === 'system') return value
  } catch {
    // ignore
  }
  return 'system'
}

export function storeTheme(theme: Theme) {
  try {
    localStorage.setItem(STORAGE_KEY, theme)
  } catch {
    // ignore
  }
}

export const darkQuery = '(prefers-color-scheme: dark)'

export function systemTheme(): ResolvedTheme {
  return window.matchMedia(darkQuery).matches ? 'dark' : 'light'
}
