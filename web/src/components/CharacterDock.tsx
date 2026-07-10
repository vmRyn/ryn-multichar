import type { Character } from '@/types'
import { getCharacterForSlot } from '@/lib/characters'
import { ActiveCharacterHero } from './ActiveCharacterHero'
import { CharacterCard } from './CharacterCard'
import { CharacterActions } from './CharacterActions'
import { KeyboardHints } from './KeyboardHints'
import { SlotSkeleton } from './SlotSkeleton'
import { cn } from '@/lib/utils'

interface CharacterDockProps {
  characters: Character[]
  slotLimit: number
  activeSlot: number
  loading?: boolean
  lastPlayedCitizenId?: string | null
  photoModeEnabled?: boolean
  hidden?: boolean
  onSelectSlot: (slotIndex: number) => void
  onPlay: (character: Character) => void
  onDelete: (character: Character) => void
  onInfo: (character: Character) => void
  onCreate: (slotIndex: number) => void
  onPhotoMode?: () => void
}

export function CharacterDock({
  characters,
  slotLimit,
  activeSlot,
  loading = false,
  lastPlayedCitizenId,
  photoModeEnabled = false,
  hidden = false,
  onSelectSlot,
  onPlay,
  onDelete,
  onInfo,
  onCreate,
  onPhotoMode,
}: CharacterDockProps) {
  const slots = Array.from({ length: slotLimit }, (_, i) => i + 1)
  const activeCharacter = getCharacterForSlot(characters, activeSlot)

  return (
    <div className={cn('ryn-dock-wrap', hidden && 'ryn-dock-wrap--hidden')}>
      <div className="ryn-command-deck" data-animate="dock">
        <div className="ryn-command-deck__surface">
          <div className="ryn-command-deck__accent" aria-hidden />
          <ActiveCharacterHero character={activeCharacter} slotIndex={activeSlot} />
          <div className="ryn-command-deck__rail">
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
          <div className="ryn-command-deck__divider" aria-hidden />
          <div className="ryn-command-deck__actions">
            <CharacterActions
              character={activeCharacter}
              photoModeEnabled={photoModeEnabled}
              onPlay={activeCharacter ? () => onPlay(activeCharacter) : undefined}
              onCreate={() => onCreate(activeSlot)}
              onInfo={activeCharacter ? () => onInfo(activeCharacter) : undefined}
              onDelete={activeCharacter ? () => onDelete(activeCharacter) : undefined}
              onPhotoMode={onPhotoMode}
            />
          </div>
        </div>
        <KeyboardHints />
      </div>
    </div>
  )
}
