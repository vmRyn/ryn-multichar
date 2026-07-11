import type { Character } from '@/types'
import { getCharacterForSlot } from '@/lib/characters'
import { CharacterCard } from './CharacterCard'
import { KeyboardHints } from './KeyboardHints'
import { SlotSkeleton } from './SlotSkeleton'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { LayoutListIcon } from 'lucide-react'

interface CharacterDockProps {
  characters: Character[]
  slotLimit: number
  activeSlot: number
  loading?: boolean
  lastPlayedCitizenId?: string | null
  hidden?: boolean
  onSelectSlot: (slotIndex: number) => void
  onPlay: (character: Character) => void
  onDelete: (character: Character) => void
  onInfo: (character: Character) => void
  onCreate: (slotIndex: number) => void
}

export function CharacterDock({
  characters,
  slotLimit,
  activeSlot,
  loading = false,
  lastPlayedCitizenId,
  hidden = false,
  onSelectSlot,
  onPlay,
  onDelete,
  onInfo,
  onCreate,
}: CharacterDockProps) {
  const { t } = useLocale()
  const slots = Array.from({ length: slotLimit }, (_, i) => i + 1)

  return (
    <div className={cn('ryn-dock-wrap', hidden && 'ryn-dock-wrap--hidden')}>
      <div className="ryn-slot-deck" data-animate="dock">
        <div className="ryn-slot-deck__heading">
          <span className="ryn-side-panel__icon" aria-hidden>
            <LayoutListIcon className="size-3.5" strokeWidth={2.25} />
          </span>
          <div>
            <p className="ryn-side-panel__title">{t('yourCharacters')}</p>
            <p className="ryn-side-panel__hint">{t('yourCharactersHint')}</p>
          </div>
        </div>

        <div className="ryn-slot-deck__rail">
          {loading
            ? slots.map((slotIndex) => <SlotSkeleton key={slotIndex} />)
            : slots.map((slotIndex) => {
                const character = getCharacterForSlot(characters, slotIndex)
                return (
                  <CharacterCard
                    key={slotIndex}
                    character={character}
                    slotIndex={slotIndex}
                    isActive={activeSlot === slotIndex}
                    isLastPlayed={!!character && character.citizenid === lastPlayedCitizenId}
                    onSelect={onSelectSlot}
                    onPlay={character ? () => onPlay(character) : undefined}
                    onDelete={character ? () => onDelete(character) : undefined}
                    onInfo={character ? () => onInfo(character) : undefined}
                    onCreate={() => onCreate(slotIndex)}
                  />
                )
              })}
        </div>

        <KeyboardHints />
      </div>
    </div>
  )
}
