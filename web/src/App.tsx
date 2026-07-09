import { useState, useEffect, useRef, useCallback, useMemo } from 'react'
import { CharacterDock } from '@/components/CharacterDock'
import { CharacterChrome } from '@/components/CharacterChrome'
import { CreationForm } from '@/components/CreationForm'
import { SpawnSelector } from '@/components/SpawnSelector'
import { PhotoModeOverlay } from '@/components/PhotoModeOverlay'
import { AdminSlotPanel } from '@/components/AdminSlotPanel'
import { SceneVignette } from '@/components/SceneVignette'
import { RynModal } from '@/components/RynModal'
import { fetchNui, useNuiEvent, getFullName, formatPlaytime, isDevMode } from '@/hooks/useNui'
import { useLocale, LocaleProvider } from '@/hooks/useLocale'
import { useTheme } from '@/hooks/useTheme'
import { useKeyboardNav } from '@/hooks/useKeyboardNav'
import { DevPanel } from '@/dev/DevPanel'
import { demoCharacters, demoCreationFields, demoSlotLimit, demoSpawnLocations, demoTheme, demoPosePresets } from '@/dev/demoData'
import { getLastPlayedCitizenId, getCharacterForSlot } from '@/lib/characters'
import { notifyError, notifySuccess, notifyInfo } from '@/lib/toast'
import { playUiSound } from '@/lib/sounds'
import type { Character, CreationField, FeatureFlags, PosePreset, SpawnLocation, UITheme } from '@/types'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Field, FieldLabel } from '@/components/ui/field'
import { InfoRow } from '@/components/InfoRow'
import { PanelHeader } from '@/components/PanelHeader'
import { LoadingOverlay } from '@/components/LoadingOverlay'
import { getErrorMessage, getErrorTitle } from '@/lib/errors'
import { animateCharacterEntrance, animateSpawnConfirm, animateUiClose } from '@/lib/animations'

type Screen = 'characterSelect' | 'creation' | 'spawnSelect' | 'deleteConfirm' | 'info'

const dev = isDevMode()

function MulticharApp({
  setLocaleCode,
}: {
  setLocaleCode: (locale: 'en' | 'es') => void
}) {
  const { t } = useLocale()
  const [visible, setVisible] = useState(dev)
  const [screen, setScreen] = useState<Screen>('characterSelect')
  const [characters, setCharacters] = useState<Character[]>(dev ? demoCharacters : [])
  const [slotLimit, setSlotLimit] = useState(dev ? demoSlotLimit : 3)
  const [activeSlot, setActiveSlot] = useState(1)
  const [loadingCharacters, setLoadingCharacters] = useState(false)
  const [creationFields, setCreationFields] = useState<CreationField[]>(dev ? demoCreationFields : [])
  const [spawnLocations, setSpawnLocations] = useState<SpawnLocation[]>(dev ? demoSpawnLocations : [])
  const [selectedCitizenId, setSelectedCitizenId] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Character | null>(null)
  const [deleteConfirmName, setDeleteConfirmName] = useState('')
  const [infoCharacter, setInfoCharacter] = useState<Character | null>(null)
  const [theme, setTheme] = useState<UITheme | null>(dev ? demoTheme : null)
  const [features, setFeatures] = useState<FeatureFlags>(dev ? { photoMode: true, scenePoses: true } : {})
  const [posePresets, setPosePresets] = useState<PosePreset[]>(dev ? demoPosePresets : [])
  const [photoModeActive, setPhotoModeActive] = useState(false)
  const [adminOpen, setAdminOpen] = useState(false)
  const [spawning, setSpawning] = useState(false)
  const appRef = useRef<HTMLDivElement>(null)

  const deleteOpen = !!deleteTarget
  const infoOpen = !!infoCharacter

  useTheme(theme)

  const lastPlayedCitizenId = useMemo(
    () => getLastPlayedCitizenId(characters),
    [characters],
  )

  const loadCharacters = useCallback(async () => {
    setLoadingCharacters(true)
    try {
      const result = await fetchNui<{ characters: Character[]; slotLimit: number }>('getCharacters')
      setCharacters(result.characters ?? [])
      setSlotLimit(result.slotLimit ?? 3)
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    } finally {
      setLoadingCharacters(false)
    }
  }, [t])

  const playEntrance = useCallback(() => {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (appRef.current) animateCharacterEntrance(appRef.current)
      })
    })
  }, [])

  useNuiEvent<{ screen?: Screen; data?: Record<string, unknown> }>('open', (payload) => {
    setVisible(true)
    if (payload.screen) setScreen(payload.screen)
    if (payload.data?.theme) {
      const uiTheme = payload.data.theme as UITheme
      setTheme(uiTheme)
      if (uiTheme.locale === 'en' || uiTheme.locale === 'es') {
        setLocaleCode(uiTheme.locale)
      }
    }
    if (payload.data?.creationFields) setCreationFields(payload.data.creationFields as CreationField[])
    if (payload.data?.locations) setSpawnLocations(payload.data.locations as SpawnLocation[])
    if (payload.data?.citizenid) setSelectedCitizenId(payload.data.citizenid as string)
    if (payload.data?.characters) setCharacters(payload.data.characters as Character[])
    if (payload.data?.slotLimit) setSlotLimit(payload.data.slotLimit as number)
    if (payload.data?.features) setFeatures(payload.data.features as FeatureFlags)
    if (payload.data?.posePresets) setPosePresets(payload.data.posePresets as PosePreset[])
    if (payload.screen === 'spawnSelect' || payload.screen === 'creation') {
      playUiSound('transition')
    }
    if (payload.screen === 'characterSelect') loadCharacters()
    if (payload.screen === 'deleteConfirm' && dev) {
      setDeleteTarget(demoCharacters[0])
      setDeleteConfirmName('')
      setScreen('characterSelect')
    }
    if (payload.screen === 'info' && dev) {
      setInfoCharacter(demoCharacters[0])
      setScreen('characterSelect')
    }
  })

  useNuiEvent('close', () => {
    if (appRef.current) animateUiClose(appRef.current)
    setPhotoModeActive(false)
    setTimeout(() => setVisible(false), 200)
  })

  useNuiEvent('openAdmin', () => {
    setAdminOpen(true)
    setVisible(true)
  })

  useNuiEvent('closeAdmin', () => {
    setAdminOpen(false)
  })

  useEffect(() => {
    if (!dev) return
    document.body.classList.add('dev-preview')
  }, [])

  useEffect(() => {
    if (visible && screen === 'characterSelect') loadCharacters()
  }, [visible, screen, loadCharacters])

  useEffect(() => {
    if (!visible || screen !== 'characterSelect' || loadingCharacters) return
    playEntrance()
  }, [visible, screen, loadingCharacters, playEntrance])

  const handleSelectSlot = useCallback((slotIndex: number) => {
    setActiveSlot(slotIndex)
    playUiSound('slotSelect')
    fetchNui('selectSlot', { slotIndex })
  }, [])

  const handlePlay = useCallback(async (character: Character) => {
    setInfoCharacter(null)
    setSelectedCitizenId(character.citizenid)
    try {
      const result = await fetchNui<{ success: boolean }>('playCharacter', { citizenid: character.citizenid })
      if (result?.success) {
        playUiSound('confirm')
      } else {
        notifyError(t('toastError'), t('toastErrorDesc'))
      }
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }, [t])

  const handleDelete = useCallback((character: Character) => {
    setDeleteTarget(character)
    setDeleteConfirmName('')
    playUiSound('transition')
  }, [])

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return
    const fullName = getFullName(deleteTarget.charinfo)
    if (deleteConfirmName.trim() !== fullName) return

    try {
      const result = await fetchNui<{ success: boolean; error?: string }>('deleteCharacter', {
        citizenid: deleteTarget.citizenid,
        confirmName: deleteConfirmName.trim(),
      })
      if (result?.success) {
        playUiSound('confirm')
        notifySuccess(t('toastDeleted'), t('toastDeletedDesc'))
        setDeleteTarget(null)
        await loadCharacters()
      } else if (result?.error === 'name_mismatch') {
        notifyError(t('toastDeleteNameMismatch'), t('toastDeleteNameMismatchDesc'))
      } else {
        notifyError(getErrorTitle(result?.error, t), getErrorMessage(result?.error, t))
      }
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }

  const handleInfo = useCallback((character: Character) => {
    setInfoCharacter(character)
    playUiSound('transition')
  }, [])

  const handleCreate = useCallback((slotIndex: number) => {
    setActiveSlot(slotIndex)
    playUiSound('transition')
    setScreen('creation')
  }, [])

  const handleCreationSubmit = async (data: Record<string, string>) => {
    try {
      const result = await fetchNui<{ success: boolean; error?: string }>('createCharacter', {
        ...data,
        slotIndex: activeSlot,
      })
      if (result?.success) {
        playUiSound('confirm')
        notifySuccess(t('toastCreated'), t('toastCreatedDesc'))
        setScreen('characterSelect')
        await loadCharacters()
      } else {
        notifyError(getErrorTitle(result?.error, t), getErrorMessage(result?.error, t))
      }
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }

  const handleSpawnSelect = async (locationId: string) => {
    setSpawning(true)
    const panel = appRef.current?.querySelector('[data-animate="spawn-panel"]')
    if (panel) await animateSpawnConfirm(panel)
    playUiSound('confirm')
    notifyInfo(t('toastSpawn'), t('toastSpawnDesc'))
    try {
      await fetchNui('selectSpawn', { locationId, citizenid: selectedCitizenId })
      setVisible(false)
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    } finally {
      setSpawning(false)
    }
  }

  const activeCharacter = useMemo(
    () => getCharacterForSlot(characters, activeSlot),
    [characters, activeSlot],
  )

  const handlePhotoMode = useCallback(async () => {
    if (!activeCharacter) return
    playUiSound('transition')
    try {
      await fetchNui('photoMode', { enabled: true, slotIndex: activeSlot })
      setPhotoModeActive(true)
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }, [activeCharacter, activeSlot, t])

  const handlePhotoModeClose = useCallback(() => {
    setPhotoModeActive(false)
    playUiSound('transition')
  }, [])

  const handlePoseSaved = useCallback((citizenid: string, poseId: string) => {
    setCharacters((current) =>
      current.map((character) =>
        character.citizenid === citizenid
          ? { ...character, scene_data: { ...(character.scene_data ?? {}), poseId } }
          : character,
      ),
    )
    notifySuccess(t('poseSaved'), t('poseSavedDesc'))
  }, [t])

  const handleBack = useCallback(() => {
    if (photoModeActive) {
      fetchNui('photoMode', { enabled: false, slotIndex: activeSlot }).catch(() => {})
      setPhotoModeActive(false)
      playUiSound('transition')
      return
    }
    if (deleteTarget) {
      setDeleteTarget(null)
      playUiSound('transition')
      return
    }
    if (infoCharacter) {
      setInfoCharacter(null)
      playUiSound('transition')
      return
    }
    if (screen !== 'characterSelect') {
      playUiSound('transition')
      setScreen('characterSelect')
    }
  }, [screen, deleteTarget, infoCharacter, photoModeActive, activeSlot])

  useKeyboardNav({
    enabled: visible && screen === 'characterSelect' && !deleteOpen && !infoOpen && !photoModeActive,
    escapeEnabled: visible,
    screen,
    activeSlot,
    slotLimit,
    characters,
    onSelectSlot: handleSelectSlot,
    onPlay: handlePlay,
    onCreate: handleCreate,
    onBack: handleBack,
  })

  if (!visible && !adminOpen) {
    if (!dev) return null
    return (
      <div className="relative h-screen w-screen">
        <DevPanel />
        <div className="ryn-empty-state absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
          <p className="ryn-empty-state__title">{t('uiClosed')}</p>
          <p className="ryn-empty-state__hint">{t('uiClosedHint')}</p>
        </div>
      </div>
    )
  }

  return (
    <div ref={appRef} className="relative h-screen w-screen overflow-hidden">
      <SceneVignette />
      {dev && <DevPanel />}

      {(screen === 'characterSelect' || deleteOpen || infoOpen) && (
        <>
          {!photoModeActive && (
            <CharacterChrome
              characterCount={characters.length}
              slotLimit={slotLimit}
              logo={theme?.logo}
            />
          )}
          <CharacterDock
            characters={characters}
            slotLimit={slotLimit}
            activeSlot={activeSlot}
            loading={loadingCharacters}
            lastPlayedCitizenId={lastPlayedCitizenId}
            photoModeEnabled={features.photoMode}
            hidden={photoModeActive}
            onSelectSlot={handleSelectSlot}
            onPlay={handlePlay}
            onDelete={handleDelete}
            onInfo={handleInfo}
            onCreate={handleCreate}
            onPhotoMode={handlePhotoMode}
          />
        </>
      )}

      <PhotoModeOverlay
        active={photoModeActive && screen === 'characterSelect'}
        character={activeCharacter}
        slotIndex={activeSlot}
        posePresets={posePresets}
        onClose={handlePhotoModeClose}
        onPoseSaved={handlePoseSaved}
      />

      <AdminSlotPanel open={adminOpen} onClose={() => setAdminOpen(false)} />

      {spawning && <LoadingOverlay label={t('spawningWorld')} />}

      {screen === 'creation' && (
        <CreationForm
          slotIndex={activeSlot}
          fields={creationFields}
          onSubmit={handleCreationSubmit}
          onCancel={handleBack}
        />
      )}

      {screen === 'spawnSelect' && (
        <SpawnSelector
          locations={spawnLocations}
          onSelect={handleSpawnSelect}
          onCancel={handleBack}
        />
      )}

      <RynModal open={deleteOpen} onClose={handleBack} animationKey="delete">
        <PanelHeader
          eyebrow={t('confirmDeletion')}
          title={t('deleteForever')}
          subtitle={
            deleteTarget ? (
              <>
                Type <strong className="text-foreground">{getFullName(deleteTarget.charinfo)}</strong> to confirm.
              </>
            ) : undefined
          }
        />
        <Field>
          <FieldLabel className="ryn-field-label">{t('characterName')}</FieldLabel>
          <Input
            value={deleteConfirmName}
            onChange={(e) => setDeleteConfirmName(e.target.value)}
            placeholder={t('characterName')}
          />
        </Field>
        <div className="ryn-modal-actions">
          <Button
            size="lg"
            variant="destructive"
            disabled={!deleteTarget || deleteConfirmName.trim() !== getFullName(deleteTarget.charinfo)}
            onClick={handleConfirmDelete}
          >
            {t('deleteForever')}
          </Button>
          <Button size="lg" variant="outline" onClick={handleBack}>
            {t('cancel')}
          </Button>
        </div>
      </RynModal>

      <RynModal open={infoOpen} onClose={handleBack} animationKey="info">
        <PanelHeader
          eyebrow={t('character')}
          title={infoCharacter ? getFullName(infoCharacter.charinfo) : ''}
        />
        {infoCharacter && (
          <div className="mb-4">
            <InfoRow label={t('citizenId')} value={infoCharacter.citizenid} />
            <InfoRow label={t('job')} value={infoCharacter.job?.label ?? t('unemployed')} />
            <InfoRow
              label={t('cash')}
              value={`$${infoCharacter.money?.cash?.toLocaleString() ?? 0}`}
            />
            <InfoRow
              label={t('bank')}
              value={`$${infoCharacter.money?.bank?.toLocaleString() ?? 0}`}
            />
            {infoCharacter.last_played && (
              <InfoRow label={t('lastPlayed')} value={infoCharacter.last_played} />
            )}
            <InfoRow
              label={t('played')}
              value={formatPlaytime(infoCharacter.playtime)}
              showSeparator={false}
            />
          </div>
        )}
        <div className="ryn-modal-actions">
          {infoCharacter && (
            <Button size="lg" onClick={() => handlePlay(infoCharacter)}>
              {t('play')}
            </Button>
          )}
          <Button size="lg" variant="outline" onClick={handleBack}>
            {t('close')}
          </Button>
        </div>
      </RynModal>
    </div>
  )
}

export default function App() {
  const [localeCode, setLocaleCode] = useState<'en' | 'es'>('en')

  return (
    <LocaleProvider locale={localeCode}>
      <MulticharApp setLocaleCode={setLocaleCode} />
    </LocaleProvider>
  )
}
