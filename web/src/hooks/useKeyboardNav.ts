import { useEffect } from 'react'
import type { Character } from '@/types'
import { getCharacterForSlot } from '@/lib/characters'

type NavScreen = 'characterSelect' | 'creation' | 'spawnSelect' | 'deleteConfirm' | 'info'

interface UseKeyboardNavOptions {
  enabled: boolean
  escapeEnabled?: boolean
  screen: NavScreen
  activeSlot: number
  slotLimit: number
  characters: Character[]
  onSelectSlot: (slotIndex: number) => void
  onPlay: (character: Character) => void
  onCreate: (slotIndex: number) => void
  onBack: () => void
}

export function useKeyboardNav({
  enabled,
  escapeEnabled = true,
  screen,
  activeSlot,
  slotLimit,
  characters,
  onSelectSlot,
  onPlay,
  onCreate,
  onBack,
}: UseKeyboardNavOptions) {
  useEffect(() => {
    if (!enabled && !escapeEnabled) return

    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null
      const tag = target?.tagName.toLowerCase()
      const isTyping =
        tag === 'input' ||
        tag === 'textarea' ||
        tag === 'select' ||
        target?.isContentEditable

      // Escape always closes overlays/screens — even while typing in a modal field.
      if (escapeEnabled && event.key === 'Escape') {
        event.preventDefault()
        onBack()
        return
      }

      if (!enabled || screen !== 'characterSelect' || isTyping) return

      if (event.key === 'ArrowLeft') {
        event.preventDefault()
        const next = activeSlot <= 1 ? slotLimit : activeSlot - 1
        onSelectSlot(next)
        return
      }

      if (event.key === 'ArrowRight') {
        event.preventDefault()
        const next = activeSlot >= slotLimit ? 1 : activeSlot + 1
        onSelectSlot(next)
        return
      }

      if (event.key === 'Enter') {
        event.preventDefault()
        const character = getCharacterForSlot(characters, activeSlot)
        if (character) {
          onPlay(character)
        } else {
          onCreate(activeSlot)
        }
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [
    enabled,
    escapeEnabled,
    screen,
    activeSlot,
    slotLimit,
    characters,
    onSelectSlot,
    onPlay,
    onCreate,
    onBack,
  ])
}
