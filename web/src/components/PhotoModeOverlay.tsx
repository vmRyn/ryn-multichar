import { useCallback, useEffect, useRef, useState } from 'react'
import type { Character, PosePreset } from '@/types'
import { fetchNui } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectItem,
  SelectPopup,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { CameraIcon, RotateCcwIcon, XIcon } from 'lucide-react'

interface PhotoModeOverlayProps {
  active: boolean
  character?: Character
  slotIndex: number
  posePresets: PosePreset[]
  onClose: () => void
  onPoseSaved: (citizenid: string, poseId: string) => void
}

export function PhotoModeOverlay({
  active,
  character,
  slotIndex,
  posePresets,
  onClose,
  onPoseSaved,
}: PhotoModeOverlayProps) {
  const { t } = useLocale()
  const dragRef = useRef<{ x: number; y: number } | null>(null)
  const [selectedPose, setSelectedPose] = useState(
    character?.scene_data?.poseId ?? posePresets[0]?.id ?? '',
  )
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    setSelectedPose(character?.scene_data?.poseId ?? posePresets[0]?.id ?? '')
  }, [character, posePresets])

  useEffect(() => {
    if (!active) return

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [active, onClose])

  const sendInput = useCallback((payload: { yaw?: number; pitch?: number; zoom?: number; fov?: number }) => {
    fetchNui('photoModeInput', payload).catch(() => {})
  }, [])

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    dragRef.current = { x: e.clientX, y: e.clientY }
    e.currentTarget.setPointerCapture(e.pointerId)
  }

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!dragRef.current) return
    const deltaX = e.clientX - dragRef.current.x
    const deltaY = e.clientY - dragRef.current.y
    dragRef.current = { x: e.clientX, y: e.clientY }
    sendInput({ yaw: deltaX * 0.08, pitch: deltaY * 0.08 })
  }

  const handlePointerUp = (e: React.PointerEvent<HTMLDivElement>) => {
    dragRef.current = null
    e.currentTarget.releasePointerCapture(e.pointerId)
  }

  const handleWheel = (e: React.WheelEvent<HTMLDivElement>) => {
    e.preventDefault()
    sendInput({ zoom: e.deltaY > 0 ? 0.12 : -0.12 })
  }

  const handleReset = () => {
    fetchNui('photoModeReset').catch(() => {})
  }

  const handleSavePose = async () => {
    if (!character || !selectedPose) return
    setSaving(true)
    try {
      const result = await fetchNui<{ success: boolean; scene_data?: { poseId?: string } }>('saveScenePose', {
        citizenid: character.citizenid,
        poseId: selectedPose,
      })
      if (result?.success) {
        onPoseSaved(character.citizenid, selectedPose)
      }
    } finally {
      setSaving(false)
    }
  }

  const handleClose = () => {
    fetchNui('photoMode', { enabled: false, slotIndex }).catch(() => {})
    onClose()
  }

  if (!active) return null

  return (
    <>
      <div
        className="ryn-photo-drag"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        onPointerLeave={handlePointerUp}
        onWheel={handleWheel}
        aria-hidden
      />

      <div className="ryn-photo-panel">
        <div className="ryn-photo-panel__header">
          <div className="flex items-center gap-2">
            <CameraIcon className="size-4 text-primary" strokeWidth={2} />
            <span className="ryn-photo-panel__title">{t('photoMode')}</span>
          </div>
          <button type="button" className="ryn-photo-panel__close" onClick={handleClose} aria-label={t('close')}>
            <XIcon className="size-4" />
          </button>
        </div>

        <p className="ryn-photo-panel__hint">{t('photoModeHint')}</p>

        {character && posePresets.length > 0 && (
          <div className="ryn-photo-panel__field">
            <label className="ryn-field-label">{t('scenePose')}</label>
            <Select value={selectedPose} onValueChange={(value) => setSelectedPose(value ?? '')}>
              <SelectTrigger>
                <SelectValue placeholder={t('selectPlaceholder')} />
              </SelectTrigger>
              <SelectPopup>
                {posePresets.map((preset) => (
                  <SelectItem key={preset.id} value={preset.id}>
                    {preset.label}
                  </SelectItem>
                ))}
              </SelectPopup>
            </Select>
          </div>
        )}

        <div className="ryn-photo-panel__actions">
          {character && posePresets.length > 0 && (
            <Button size="sm" onClick={handleSavePose} disabled={saving || !selectedPose}>
              {saving ? t('saving') : t('savePose')}
            </Button>
          )}
          <Button size="sm" variant="outline" onClick={handleReset}>
            <RotateCcwIcon className="size-3.5" />
            {t('resetCamera')}
          </Button>
          <Button size="sm" variant="outline" onClick={handleClose}>
            {t('exitPhotoMode')}
          </Button>
        </div>
      </div>
    </>
  )
}
