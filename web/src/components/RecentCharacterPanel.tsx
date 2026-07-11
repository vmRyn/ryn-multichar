import type { Character } from '@/types'
import { getFullName } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { StarIcon } from 'lucide-react'

interface RecentCharacterPanelProps {
  character?: Character | null
  hidden?: boolean
  onSelect: (character: Character) => void
}

function initials(character: Character) {
  const first = character.charinfo.firstname?.[0] ?? ''
  const last = character.charinfo.lastname?.[0] ?? ''
  return `${first}${last}`.toUpperCase() || '?'
}

export function RecentCharacterPanel({ character, hidden = false, onSelect }: RecentCharacterPanelProps) {
  const { t } = useLocale()

  if (!character) return null

  return (
    <aside
      className={cn('ryn-side-panel ryn-side-panel--left', hidden && 'ryn-side-panel--hidden')}
      data-animate="side-left"
    >
      <div className="ryn-side-panel__heading">
        <span className="ryn-side-panel__icon" aria-hidden>
          <StarIcon className="size-3.5" strokeWidth={2.25} />
        </span>
        <div>
          <p className="ryn-side-panel__title">{t('recentCharacter')}</p>
          <p className="ryn-side-panel__hint">{t('recentCharacterHint')}</p>
        </div>
      </div>

      <button
        type="button"
        className="ryn-recent-card"
        onClick={() => onSelect(character)}
        aria-label={`${t('lastPlayed')}: ${getFullName(character.charinfo)}`}
      >
        <span className="ryn-avatar" aria-hidden>
          {initials(character)}
        </span>
        <span className="ryn-recent-card__text">
          <span className="ryn-recent-card__name">{getFullName(character.charinfo)}</span>
          <span className="ryn-recent-card__id">{character.citizenid}</span>
        </span>
      </button>
    </aside>
  )
}
