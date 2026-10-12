import { useEffect, useMemo, useState, useSyncExternalStore, type ReactNode } from 'react'
import {
  darkQuery,
  readStoredTheme,
  storeTheme,
  systemTheme,
  ThemeContext,
  type Theme,
} from '@/lib/theme'

function subscribeSystem(onChange: () => void) {
  const media = window.matchMedia(darkQuery)
  media.addEventListener('change', onChange)
  return () => media.removeEventListener('change', onChange)
}

/** Light / dark / system theme, applied as a class on <html> (Tailwind `dark:` variant). */
export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setThemeState] = useState<Theme>(readStoredTheme)
  const system = useSyncExternalStore(subscribeSystem, systemTheme)
  const resolvedTheme = theme === 'system' ? system : theme

  useEffect(() => {
    const root = document.documentElement
    root.classList.remove('light', 'dark')
    root.classList.add(resolvedTheme)
    root.style.colorScheme = resolvedTheme
  }, [resolvedTheme])

  const value = useMemo(
    () => ({
      theme,
      resolvedTheme,
      setTheme: (next: Theme) => {
        storeTheme(next)
        setThemeState(next)
      },
    }),
    [theme, resolvedTheme],
  )

  return <ThemeContext value={value}>{children}</ThemeContext>
}
