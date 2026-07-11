import type { Character } from '@/types'
import { getFullName, formatPlaytime } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { Button } from '@/components/ui/button'
import { InfoIcon, PlayIcon, XIcon } from 'lucide-react'

interface CharacterInfoModalProps {
  character: Character
  onPlay: () => void
  onClose: () => void
}

function genderLabel(gender: Character['charinfo']['gender'], male: string, female: string) {
  if (gender === 1 || gender === 'female') return female
  if (gender === 0 || gender === 'male') return male
  return '—'
}

function initials(character: Character) {
  const first = character.charinfo.firstname?.[0] ?? ''
  const last = character.charinfo.lastname?.[0] ?? ''
  return `${first}${last}`.toUpperCase() || '?'
}

export function CharacterInfoModal({ character, onPlay, onClose }: CharacterInfoModalProps) {
  const { t } = useLocale()

  return (
    <div className="ryn-modal-body">
      <div className="ryn-side-panel__heading">
        <span className="ryn-side-panel__icon" aria-hidden>
          <InfoIcon className="size-3.5" strokeWidth={2.25} />
        </span>
        <div className="min-w-0 flex-1">
          <p className="ryn-side-panel__title">{t('characterInfo')}</p>
          <p className="ryn-side-panel__hint">{t('characterInfoHint')}</p>
        </div>
        <button type="button" className="ryn-modal-close" onClick={onClose} aria-label={t('close')}>
          <XIcon className="size-4" />
        </button>
      </div>

      <div className="ryn-modal-identity">
        <span className="ryn-avatar ryn-avatar--lg" aria-hidden>
          {initials(character)}
        </span>
        <div className="min-w-0">
          <h2 className="ryn-info-identity__name">{getFullName(character.charinfo)}</h2>
          <p className="ryn-info-identity__meta">
            {character.job?.label ?? t('unemployed')}
            {character.job?.grade?.name ? ` · ${character.job.grade.name}` : ''}
          </p>
          <p className="ryn-modal-identity__id">{character.citizenid}</p>
        </div>
      </div>

      <div className="ryn-stat-grid">
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('citizenId')}</span>
          <span className="ryn-stat__value">{character.citizenid}</span>
        </div>
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('gender')}</span>
          <span className="ryn-stat__value">
            {genderLabel(character.charinfo.gender, t('genderMale'), t('genderFemale'))}
          </span>
        </div>
        {character.charinfo.birthdate && (
          <div className="ryn-stat">
            <span className="ryn-stat__label">{t('birthdate')}</span>
            <span className="ryn-stat__value">{character.charinfo.birthdate}</span>
          </div>
        )}
        {character.charinfo.nationality && (
          <div className="ryn-stat">
            <span className="ryn-stat__label">{t('nationality')}</span>
            <span className="ryn-stat__value">{character.charinfo.nationality}</span>
          </div>
        )}
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('job')}</span>
          <span className="ryn-stat__value">{character.job?.label ?? t('unemployed')}</span>
        </div>
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('grade')}</span>
          <span className="ryn-stat__value">{character.job?.grade?.name ?? '—'}</span>
        </div>
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('cash')}</span>
          <span className="ryn-stat__value">${(character.money?.cash ?? 0).toLocaleString()}</span>
        </div>
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('bank')}</span>
          <span className="ryn-stat__value">${(character.money?.bank ?? 0).toLocaleString()}</span>
        </div>
        {character.last_played && (
          <div className="ryn-stat">
            <span className="ryn-stat__label">{t('lastPlayed')}</span>
            <span className="ryn-stat__value">{character.last_played}</span>
          </div>
        )}
        <div className="ryn-stat">
          <span className="ryn-stat__label">{t('played')}</span>
          <span className="ryn-stat__value">{formatPlaytime(character.playtime)}</span>
        </div>
      </div>

      <div className="ryn-modal-actions">
        <Button className="ryn-btn-play" size="lg" onClick={onPlay}>
          <PlayIcon className="size-4" strokeWidth={2.5} />
          {t('playCharacter')}
        </Button>
        <Button size="lg" variant="outline" onClick={onClose}>
          {t('close')}
        </Button>
      </div>
    </div>
  )
}
