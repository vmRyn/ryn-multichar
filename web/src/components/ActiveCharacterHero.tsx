import type { Character } from '@/types'
import { getFullName } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'

interface ActiveCharacterHeroProps {
  character?: Character
  slotIndex: number
}

export function ActiveCharacterHero({ character, slotIndex }: ActiveCharacterHeroProps) {
  const { t } = useLocale()

  if (!character) {
    return (
      <div className="ryn-command-deck__hero">
        <p className="ryn-hero-name">{t('newCharacter')}</p>
        <p className="ryn-subtitle mt-1">{t('createSubtitle')}</p>
      </div>
    )
  }

  const grade = character.job?.grade?.name
  const job = character.job?.label ?? t('unemployed')

  return (
    <div className="ryn-command-deck__hero">
      <h2 className="ryn-hero-name">{getFullName(character.charinfo)}</h2>
      <div className="ryn-hero-meta">
        <span>{job}</span>
        {grade && (
          <>
            <span className="ryn-hero-meta-sep" aria-hidden />
            <span>{grade}</span>
          </>
        )}
        <span className="ryn-hero-meta-sep" aria-hidden />
        <span>{t('slot', { index: String(slotIndex).padStart(2, '0') })}</span>
      </div>
    </div>
  )
}
