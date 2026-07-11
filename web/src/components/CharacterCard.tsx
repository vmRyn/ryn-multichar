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
import { PlayIcon, Trash2Icon, InfoIcon, PlusIcon, UserRoundPlusIcon } from 'lucide-react'

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

function initials(character: Character) {
  const first = character.charinfo.firstname?.[0] ?? ''
  const last = character.charinfo.lastname?.[0] ?? ''
  return `${first}${last}`.toUpperCase() || '?'
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
            className={cn('ryn-slot w-full', isActive && 'ryn-slot-active', isEmpty && 'ryn-slot-empty')}
            onClick={() => onSelect(slotIndex)}
            onDoubleClick={handleDoubleClick}
          >
            {isLastPlayed && !isEmpty && (
              <span className="ryn-slot-recent" title={t('lastPlayed')} aria-label={t('lastPlayed')} />
            )}

            {character ? (
              <>
                <span className="ryn-slot-avatar" aria-hidden>
                  {initials(character)}
                </span>
                <span className="ryn-slot-body">
                  <span className="ryn-slot-num">{slotLabel}</span>
                  <p className="ryn-slot-name">{getFullName(character.charinfo)}</p>
                  <p className="ryn-slot-job">{character.job?.label ?? t('unemployed')}</p>
                  <p className="ryn-slot-id">{character.citizenid}</p>
                </span>
              </>
            ) : (
              <>
                <span className="ryn-slot-empty-icon" aria-hidden>
                  <UserRoundPlusIcon className="size-6" strokeWidth={1.75} />
                </span>
                <span className="ryn-slot-body">
                  <span className="ryn-slot-num">{slotLabel}</span>
                  <p className="ryn-slot-name">{t('newCharacter')}</p>
                  <p className="ryn-slot-job">{t('emptySlotClick')}</p>
                </span>
              </>
            )}
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
