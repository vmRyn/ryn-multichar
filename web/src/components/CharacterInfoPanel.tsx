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
  BriefcaseIcon,
  CameraIcon,
  InfoIcon,
  PlayIcon,
  PlusIcon,
  SparklesIcon,
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
  const jobLabel = character?.job?.label ?? t('unemployed')
  const gradeLabel = character?.job?.grade?.name
  const isUnemployed = !character?.job?.label || character.job.label.toLowerCase() === 'unemployed'

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
            <p className="ryn-info-identity__meta">{character.citizenid}</p>
          </div>

          <div className={cn('ryn-role-card', isUnemployed && 'ryn-role-card--muted')}>
            <span className="ryn-role-card__icon" aria-hidden>
              <BriefcaseIcon className="size-3.5" strokeWidth={2.25} />
            </span>
            <div className="ryn-role-card__body">
              <span className="ryn-role-card__label">{t('role')}</span>
              <span className="ryn-role-card__title">{jobLabel}</span>
              {gradeLabel ? <span className="ryn-role-card__grade">{gradeLabel}</span> : null}
            </div>
          </div>

          <div className="ryn-stat-grid">
            <Stat label={t('slotLabel')} value={String(slotIndex).padStart(2, '0')} />
            <Stat
              label={t('cash')}
              value={`$${(character.money?.cash ?? 0).toLocaleString()}`}
            />
            <Stat
              label={t('bank')}
              value={`$${(character.money?.bank ?? 0).toLocaleString()}`}
            />
            <Stat label={t('played')} value={formatPlaytime(character.playtime)} />
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
          <div className="ryn-empty-hero">
            <span className="ryn-empty-hero__mark" aria-hidden>
              <SparklesIcon className="size-5" strokeWidth={1.75} />
            </span>
            <h2 className="ryn-empty-hero__title">{t('emptySlotTitle')}</h2>
            <p className="ryn-empty-hero__copy">{t('emptySlotBody')}</p>
            <p className="ryn-empty-hero__meta">{t('createSlotMeta', { slot: slotIndex })}</p>
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
