import { useLocale } from '@/hooks/useLocale'
import type { Character } from '@/types'
import { Button } from '@/components/ui/button'
import {
  Tooltip,
  TooltipPopup,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import { CameraIcon, InfoIcon, PlayIcon, PlusIcon, Trash2Icon } from 'lucide-react'

interface CharacterActionsProps {
  character?: Character
  photoModeEnabled?: boolean
  onPlay?: () => void
  onCreate?: () => void
  onInfo?: () => void
  onDelete?: () => void
  onPhotoMode?: () => void
}

export function CharacterActions({
  character,
  photoModeEnabled = false,
  onPlay,
  onCreate,
  onInfo,
  onDelete,
  onPhotoMode,
}: CharacterActionsProps) {
  const { t } = useLocale()

  return (
    <div className="ryn-actions">
      {character ? (
        <>
          <Button className="ryn-btn-play" size="lg" onClick={onPlay}>
            <PlayIcon className="size-4" strokeWidth={2.5} />
            {t('play')}
          </Button>
          {photoModeEnabled && (
            <Tooltip>
              <TooltipTrigger
                render={
                  <Button variant="outline" size="icon-lg" onClick={onPhotoMode} aria-label={t('photoMode')}>
                    <CameraIcon />
                  </Button>
                }
              />
              <TooltipPopup>{t('photoMode')}</TooltipPopup>
            </Tooltip>
          )}
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
          <Tooltip>
            <TooltipTrigger
              render={
                <Button
                  variant="destructive-outline"
                  size="icon-lg"
                  onClick={onDelete}
                  aria-label={t('delete')}
                >
                  <Trash2Icon />
                </Button>
              }
            />
            <TooltipPopup>{t('delete')}</TooltipPopup>
          </Tooltip>
        </>
      ) : (
        <Button className="ryn-btn-play" size="lg" onClick={onCreate}>
          <PlusIcon className="size-4" strokeWidth={2.25} />
          {t('createCharacter')}
        </Button>
      )}
    </div>
  )
}
