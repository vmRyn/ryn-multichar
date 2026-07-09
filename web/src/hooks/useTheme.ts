import { useEffect } from 'react'
import type { UITheme } from '@/types'
import { applyThemeToDocument, clearThemeFromDocument } from '@/lib/applyTheme'
import { configureSounds, preloadUiSounds } from '@/lib/sounds'

export function useTheme(theme: UITheme | null) {
  useEffect(() => {
    if (!theme?.colors) return
    applyThemeToDocument(theme)
    configureSounds(theme.sounds)
    preloadUiSounds()
    return () => {
      clearThemeFromDocument()
      configureSounds({ enabled: false })
    }
  }, [theme])
}
