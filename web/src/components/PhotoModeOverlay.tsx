import { useCallback, useEffect, useRef, useState } from 'react'
import type { Character, PosePreset, ScenePreset } from '@/types'
import { fetchNui, getFullName } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { notifyError } from '@/lib/toast'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectItem,
  SelectPopup,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  CameraIcon,
  EyeOffIcon,
  RotateCcwIcon,
} from 'lucide-react'

interface PhotoModeOverlayProps {
  active: boolean
  character?: Character
  slotIndex: number
  posePresets: PosePreset[]
  scenePresets: ScenePreset[]
  activeSceneId?: string
  onClose: () => void
  onPoseSaved: (citizenid: string, poseId: string, sceneId?: string) => void
  onUiHiddenChange?: (hidden: boolean) => void
  onSceneChange?: (sceneId: string) => void
}

export function PhotoModeOverlay({
  active,
  character,
  slotIndex,
  posePresets,
  scenePresets,
  activeSceneId = '',
  onClose,
  onPoseSaved,
  onUiHiddenChange,
  onSceneChange,
}: PhotoModeOverlayProps) {
  const { t } = useLocale()
  const dragRef = useRef<{ x: number; y: number } | null>(null)
  const [selectedPose, setSelectedPose] = useState(
    character?.scene_data?.poseId ?? posePresets[0]?.id ?? '',
  )
  const [selectedScene, setSelectedScene] = useState(
    activeSceneId || character?.scene_data?.sceneId || scenePresets[0]?.id || '',
  )
  const [saving, setSaving] = useState(false)
  const [uiHidden, setUiHidden] = useState(false)
  const [switchingScene, setSwitchingScene] = useState(false)

  const resolveSceneSelection = useCallback(() => {
    const saved = character?.scene_data?.sceneId
    const savedValid = saved && scenePresets.some((preset) => preset.id === saved)
    // Always prefer the live loaded scene so the dropdown matches what you see.
    if (activeSceneId && scenePresets.some((preset) => preset.id === activeSceneId)) {
      return activeSceneId
    }
    if (savedValid) return saved
    return scenePresets[0]?.id ?? ''
  }, [activeSceneId, character, scenePresets])

  useEffect(() => {
    if (!active) {
      setUiHidden(false)
      onUiHiddenChange?.(false)
      return
    }
    setSelectedPose(character?.scene_data?.poseId ?? posePresets[0]?.id ?? '')
    setSelectedScene(resolveSceneSelection())
  }, [active, character, posePresets, resolveSceneSelection, onUiHiddenChange])

  useEffect(() => {
    if (!active || !activeSceneId) return
    setSelectedScene(activeSceneId)
  }, [active, activeSceneId])

  const handleClose = useCallback(() => {
    setUiHidden(false)
    onUiHiddenChange?.(false)
    fetchNui('photoMode', { enabled: false, slotIndex }).catch(() => {})
    onClose()
  }, [onClose, onUiHiddenChange, slotIndex])

  const toggleUiHidden = useCallback(() => {
    setUiHidden((prev) => {
      const next = !prev
      onUiHiddenChange?.(next)
      return next
    })
  }, [onUiHiddenChange])

  const handleReset = useCallback(() => {
    fetchNui('photoModeReset').catch(() => {})
  }, [])

  useEffect(() => {
    if (!active) return

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'h' || e.key === 'H') {
        e.preventDefault()
        toggleUiHidden()
        return
      }
      if (e.key === 'r' || e.key === 'R') {
        const target = e.target as HTMLElement | null
        const tag = target?.tagName.toLowerCase()
        if (tag === 'input' || tag === 'textarea' || target?.isContentEditable) return
        e.preventDefault()
        handleReset()
        return
      }
      if (e.key === 'Escape') {
        e.preventDefault()
        if (uiHidden) {
          setUiHidden(false)
          onUiHiddenChange?.(false)
          return
        }
        handleClose()
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [active, handleClose, handleReset, onUiHiddenChange, toggleUiHidden, uiHidden])

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

  const handlePoseChange = (poseId: string) => {
    setSelectedPose(poseId)
    if (!character || !poseId) return
    fetchNui('previewPose', {
      citizenid: character.citizenid,
      poseId,
      sceneId: selectedScene || undefined,
    }).catch(() => {})
  }

  const handleSceneChange = async (sceneId: string) => {
    if (!sceneId || sceneId === activeSceneId) {
      setSelectedScene(sceneId)
      return
    }
    setSelectedScene(sceneId)
    setSwitchingScene(true)
    try {
      const result = await fetchNui<{ success?: boolean; activeScene?: string }>('setScene', {
        sceneId,
        slotIndex,
      })
      if (result?.success) {
        onSceneChange?.(result.activeScene ?? sceneId)
        setSelectedScene(result.activeScene ?? sceneId)
      } else {
        // Revert dropdown if the world did not switch.
        setSelectedScene(activeSceneId || resolveSceneSelection())
      }
    } finally {
      setSwitchingScene(false)
    }
  }

  const handleSavePose = async () => {
    if (!character || !selectedPose) return
    setSaving(true)
    try {
      // Persist the live scene, not a stale dropdown value that never switched.
      const sceneToSave = activeSceneId || selectedScene || undefined
      const result = await fetchNui<{ success: boolean; scene_data?: { poseId?: string; sceneId?: string } }>('saveScenePose', {
        citizenid: character.citizenid,
        poseId: selectedPose,
        sceneId: sceneToSave,
      })
      if (result?.success) {
        onPoseSaved(character.citizenid, selectedPose, sceneToSave)
      } else {
        notifyError(t('poseSaveFailed'), t('poseSaveFailedDesc'))
      }
    } catch {
      notifyError(t('poseSaveFailed'), t('poseSaveFailedDesc'))
    } finally {
      setSaving(false)
    }
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

      <aside
        className={cn(
          'ryn-side-panel ryn-side-panel--right ryn-photo-panel',
          uiHidden && 'ryn-side-panel--hidden',
        )}
      >
        <div className="ryn-side-panel__heading">
          <span className="ryn-side-panel__icon" aria-hidden>
            <CameraIcon className="size-3.5" strokeWidth={2.25} />
          </span>
          <div>
            <p className="ryn-side-panel__title">{t('photoMode')}</p>
            <p className="ryn-side-panel__hint">{t('photoModeHint')}</p>
          </div>
        </div>

        {character && (
          <div className="ryn-info-identity">
            <h2 className="ryn-info-identity__name">{getFullName(character.charinfo)}</h2>
            <p className="ryn-info-identity__meta">{t('photoModeSubject')}</p>
          </div>
        )}

        <div className="ryn-photo-fields">
          {scenePresets.length > 0 && (
            <div className="ryn-photo-panel__field">
              <label className="ryn-field-label">{t('sceneSelect')}</label>
              <Select
                value={selectedScene}
                onValueChange={(value) => handleSceneChange(value ?? '')}
                disabled={switchingScene}
              >
                <SelectTrigger>
                  <SelectValue placeholder={switchingScene ? t('switchingScene') : t('selectPlaceholder')} />
                </SelectTrigger>
                <SelectPopup>
                  {scenePresets.map((preset) => (
                    <SelectItem key={preset.id} value={preset.id}>
                      {preset.label}
                    </SelectItem>
                  ))}
                </SelectPopup>
              </Select>
            </div>
          )}

          {character && posePresets.length > 0 && (
            <div className="ryn-photo-panel__field">
              <label className="ryn-field-label">{t('poseSelect')}</label>
              <Select value={selectedPose} onValueChange={(value) => handlePoseChange(value ?? '')}>
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
        </div>

        <div className="ryn-info-actions">
          {character && posePresets.length > 0 && (
            <Button className="ryn-btn-play" size="lg" onClick={handleSavePose} disabled={saving || !selectedPose}>
              {saving ? t('saving') : t('savePose')}
            </Button>
          )}
          <div className="ryn-info-actions__row">
            <Button
              variant="outline"
              size="icon-lg"
              onClick={toggleUiHidden}
              aria-label={t('hideUi')}
              title={`${t('hideUi')} (H)`}
            >
              <EyeOffIcon />
            </Button>
            <Button variant="outline" size="icon-lg" onClick={handleReset} aria-label={t('resetCamera')} title={`${t('resetCamera')} (R)`}>
              <RotateCcwIcon />
            </Button>
            <Button variant="outline" size="lg" className="flex-1" onClick={handleClose}>
              {t('exitPhotoMode')}
            </Button>
          </div>
          <p className="ryn-photo-panel__hotkey">{t('hideUiHint')}</p>
        </div>
      </aside>
    </>
  )
}
