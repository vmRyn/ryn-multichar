import type { Character } from '@/types'
import { getFullName, formatPlaytime } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import {
  Tooltip,
  TooltipPopup,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import {
  CameraIcon,
  InfoIcon,
  PlayIcon,
  PlusIcon,
  Trash2Icon,
} from 'lucide-react'

interface CharacterInfoPanelProps {
  character?: Character
  slotIndex: number
  photoModeEnabled?: boolean
  hidden?: boolean
  onPlay?: () => void
  onCreate?: () => void
  onDelete?: () => void
  onInfo?: () => void
  onPhotoMode?: () => void
}

function genderLabel(gender: Character['charinfo']['gender'], male: string, female: string) {
  if (gender === 1 || gender === 'female') return female
  if (gender === 0 || gender === 'male') return male
  return '—'
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="ryn-stat">
      <span className="ryn-stat__label">{label}</span>
      <span className="ryn-stat__value">{value}</span>
    </div>
  )
}

export function CharacterInfoPanel({
  character,
  slotIndex,
  photoModeEnabled = false,
  hidden = false,
  onPlay,
  onCreate,
  onDelete,
  onInfo,
  onPhotoMode,
}: CharacterInfoPanelProps) {
  const { t } = useLocale()

  return (
    <aside
      className={cn('ryn-side-panel ryn-side-panel--right', hidden && 'ryn-side-panel--hidden')}
      data-animate="side-right"
    >
      <div className="ryn-side-panel__heading">
        <span className="ryn-side-panel__icon" aria-hidden>
          <InfoIcon className="size-3.5" strokeWidth={2.25} />
        </span>
        <div>
          <p className="ryn-side-panel__title">{t('characterInfo')}</p>
          <p className="ryn-side-panel__hint">{t('characterInfoHint')}</p>
        </div>
      </div>

      {character ? (
        <>
          <div className="ryn-info-identity">
            <h2 className="ryn-info-identity__name">{getFullName(character.charinfo)}</h2>
            <p className="ryn-info-identity__meta">
              {character.job?.label ?? t('unemployed')}
              {character.job?.grade?.name ? ` · ${character.job.grade.name}` : ''}
            </p>
          </div>

          <div className="ryn-stat-grid">
            <Stat label={t('citizenId')} value={character.citizenid} />
            <Stat
              label={t('gender')}
              value={genderLabel(character.charinfo.gender, t('genderMale'), t('genderFemale'))}
            />
            {character.charinfo.birthdate && (
              <Stat label={t('birthdate')} value={character.charinfo.birthdate} />
            )}
            {character.charinfo.nationality && (
              <Stat label={t('nationality')} value={character.charinfo.nationality} />
            )}
            <Stat label={t('job')} value={character.job?.label ?? t('unemployed')} />
            <Stat label={t('grade')} value={character.job?.grade?.name ?? '—'} />
            <Stat
              label={t('cash')}
              value={`$${(character.money?.cash ?? 0).toLocaleString()}`}
            />
            <Stat
              label={t('bank')}
              value={`$${(character.money?.bank ?? 0).toLocaleString()}`}
            />
            <Stat label={t('played')} value={formatPlaytime(character.playtime)} />
            <Stat label={t('slotLabel')} value={String(slotIndex).padStart(2, '0')} />
          </div>

          <div className="ryn-info-actions">
            <Button className="ryn-btn-play" size="lg" onClick={onPlay}>
              <PlayIcon className="size-4" strokeWidth={2.5} />
              {t('playCharacter')}
            </Button>
            <div className="ryn-info-actions__row">
              {photoModeEnabled && (
                <Tooltip>
                  <TooltipTrigger
                    render={
                      <Button
                        variant="outline"
                        size="icon-lg"
                        onClick={onPhotoMode}
                        aria-label={t('photoMode')}
                      >
                        <CameraIcon />
                      </Button>
                    }
                  />
                  <TooltipPopup>{t('photoMode')}</TooltipPopup>
                </Tooltip>
              )}
              {onInfo && (
                <Tooltip>
                  <TooltipTrigger
                    render={
                      <Button variant="outline" size="icon-lg" onClick={onInfo} aria-label={t('info')}>
                        <InfoIcon />
                      </Button>
                    }
                  />
                  <TooltipPopup>{t('info')}</TooltipPopup>
                </Tooltip>
              )}
              <Button
                variant="destructive-outline"
                size="lg"
                className="flex-1"
                onClick={onDelete}
              >
                <Trash2Icon className="size-4" />
                {t('delete')}
              </Button>
            </div>
          </div>
        </>
      ) : (
        <>
          <div className="ryn-info-identity">
            <h2 className="ryn-info-identity__name">{t('newCharacter')}</h2>
            <p className="ryn-info-identity__meta">{t('createSubtitle')}</p>
          </div>
          <div className="ryn-info-empty">
            <p>{t('emptySlotHint')}</p>
            <p className="ryn-info-empty__slot">{t('createSlotMeta', { slot: slotIndex })}</p>
          </div>
          <div className="ryn-info-actions">
            <Button className="ryn-btn-play" size="lg" onClick={onCreate}>
              <PlusIcon className="size-4" strokeWidth={2.25} />
              {t('createCharacter')}
            </Button>
          </div>
        </>
      )}
    </aside>
  )
}
