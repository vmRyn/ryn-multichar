import type { UITheme } from '@/types'

export function applyThemeToDocument(theme: UITheme | null) {
  const root = document.documentElement
  if (!theme?.colors) return

  const { colors } = theme
  root.style.setProperty('--nui-primary', colors.primary)
  root.style.setProperty('--nui-background', colors.background)
  root.style.setProperty('--nui-surface', colors.surface)
  root.style.setProperty('--nui-border', colors.border)
  root.style.setProperty('--nui-text', colors.text)
  root.style.setProperty('--nui-text-muted', colors.textMuted)
  root.style.setProperty('--nui-danger', colors.danger)

  if (colors.success) {
    root.style.setProperty('--nui-success', colors.success)
  }
  if (colors.warning) {
    root.style.setProperty('--nui-warning', colors.warning)
  }
}

export function clearThemeFromDocument() {
  const root = document.documentElement
  const props = [
    '--nui-primary',
    '--nui-background',
    '--nui-surface',
    '--nui-border',
    '--nui-text',
    '--nui-text-muted',
    '--nui-danger',
    '--nui-success',
    '--nui-warning',
  ]
  for (const prop of props) root.style.removeProperty(prop)
}
