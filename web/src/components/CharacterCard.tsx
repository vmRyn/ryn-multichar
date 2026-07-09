import { useEffect, useRef } from 'react'
import type { Character } from '@/types'
import { getFullName } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { animateSlotSelect } from '@/lib/animations'
import {
  ContextMenu,
  ContextMenuItem,
  ContextMenuPopup,
  ContextMenuTrigger,
} from '@/components/ui/context-menu'
import { PlayIcon, Trash2Icon, InfoIcon, PlusIcon } from 'lucide-react'

interface CharacterCardProps {
  character?: Character
  slotIndex: number
  isActive: boolean
  isLastPlayed?: boolean
  onSelect: (slotIndex: number) => void
  onPlay?: () => void
  onDelete?: () => void
  onInfo?: () => void
  onCreate?: () => void
}

export function CharacterCard({
  character,
  slotIndex,
  isActive,
  isLastPlayed,
  onSelect,
  onPlay,
  onDelete,
  onInfo,
  onCreate,
}: CharacterCardProps) {
  const { t } = useLocale()
  const isEmpty = !character
  const cardRef = useRef<HTMLButtonElement>(null)
  const prevActive = useRef(false)

  useEffect(() => {
    if (isActive && !prevActive.current && cardRef.current) {
      animateSlotSelect(cardRef.current)
    }
    prevActive.current = isActive
  }, [isActive])

  const handleDoubleClick = () => {
    if (character && onPlay) onPlay()
    else if (isEmpty && onCreate) onCreate()
  }

  const slotLabel = String(slotIndex).padStart(2, '0')

  return (
    <div className="flex min-w-0 flex-1">
      <ContextMenu>
        <ContextMenuTrigger className="flex min-w-0 flex-1">
          <button
            ref={cardRef}
            type="button"
            aria-label={
              character
                ? `${getFullName(character.charinfo)}, ${t('slot', { index: slotIndex })}`
                : `${t('newCharacter')}, ${t('slot', { index: slotIndex })}`
            }
            aria-pressed={isActive}
            className={cn('ryn-slot w-full', isActive && 'ryn-slot-active')}
            onClick={() => onSelect(slotIndex)}
            onDoubleClick={handleDoubleClick}
          >
            {isLastPlayed && !isEmpty && (
              <span className="ryn-slot-recent" title={t('lastPlayed')} aria-label={t('lastPlayed')} />
            )}

            <span className="ryn-slot-num">{slotLabel}</span>
            <p className="ryn-slot-name">
              {character ? getFullName(character.charinfo) : t('newCharacter')}
            </p>
            <p className="ryn-slot-job">
              {character ? (character.job?.label ?? t('unemployed')) : t('createCharacter')}
            </p>
          </button>
        </ContextMenuTrigger>

        <ContextMenuPopup className="min-w-48 p-1">
          {character ? (
            <>
              <ContextMenuItem onClick={onPlay}>
                <PlayIcon />
                {t('play')}
              </ContextMenuItem>
              <ContextMenuItem onClick={onInfo}>
                <InfoIcon />
                {t('info')}
              </ContextMenuItem>
              <ContextMenuItem variant="destructive" onClick={onDelete}>
                <Trash2Icon />
                {t('delete')}
              </ContextMenuItem>
            </>
          ) : (
            <ContextMenuItem onClick={onCreate}>
              <PlusIcon />
              {t('createCharacter')}
            </ContextMenuItem>
          )}
        </ContextMenuPopup>
      </ContextMenu>
    </div>
  )
}
