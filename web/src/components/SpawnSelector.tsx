import { useEffect, useMemo, useRef, useState } from 'react'
import type { SpawnLocation } from '@/types'
import { Button } from '@/components/ui/button'
import { fetchNui } from '@/hooks/useNui'
import {
  HistoryIcon,
  HomeIcon,
  MapPinIcon,
  ShieldIcon,
} from 'lucide-react'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'
import { playUiSound } from '@/lib/sounds'
import { animateSpawnChoiceSelect, animateSpawnEntrance } from '@/lib/animations'

interface SpawnSelectorProps {
  locations: SpawnLocation[]
  onConfirm: (locationId: string) => void
  onCancel: () => void
}

type SpawnCategory = 'housing' | 'public'

const iconMap: Record<string, React.ReactNode> = {
  'map-pin': <MapPinIcon className="size-4" strokeWidth={2} />,
  home: <HomeIcon className="size-4" strokeWidth={2} />,
  history: <HistoryIcon className="size-4" strokeWidth={2} />,
  shield: <ShieldIcon className="size-4" strokeWidth={2} />,
  building: <HomeIcon className="size-4" strokeWidth={2} />,
}

function getCategory(location: SpawnLocation): SpawnCategory | 'skip' {
  if (location.id === 'lastLocation') return 'skip'
  if (location.id.startsWith('housing:')) return 'housing'
  return 'public'
}

const categoryOrder: SpawnCategory[] = ['housing', 'public']

export function SpawnSelector({ locations, onConfirm, onCancel }: SpawnSelectorProps) {
  const { t } = useLocale()
  const rootRef = useRef<HTMLDivElement>(null)
  const choiceRefs = useRef<Map<string, HTMLButtonElement>>(new Map())

  const choices = useMemo(
    () => locations.filter((loc) => getCategory(loc) !== 'skip'),
    [locations],
  )

  const [selectedId, setSelectedId] = useState<string | null>(choices[0]?.id ?? null)

  const selected = useMemo(
    () => choices.find((loc) => loc.id === selectedId) ?? null,
    [choices, selectedId],
  )

  const groups = useMemo(() => {
    const labels: Record<SpawnCategory, string> = {
      housing: t('spawnGroupHousing'),
      public: t('spawnGroupPublic'),
    }

    return categoryOrder
      .map((category) => ({
        category,
        label: labels[category],
        items: choices.filter((loc) => getCategory(loc) === category),
      }))
      .filter((group) => group.items.length > 0)
  }, [choices, t])

  useEffect(() => {
    if (!selectedId && choices[0]) setSelectedId(choices[0].id)
    if (selectedId && !choices.some((loc) => loc.id === selectedId)) {
      setSelectedId(choices[0]?.id ?? null)
    }
  }, [choices, selectedId])

  useEffect(() => {
    if (!rootRef.current) return
    const frame = requestAnimationFrame(() => {
      if (rootRef.current) animateSpawnEntrance(rootRef.current)
    })
    return () => cancelAnimationFrame(frame)
  }, [])

  useEffect(() => {
    if (!selected?.coords) return
    const timer = window.setTimeout(() => {
      fetchNui('previewSpawn', { coords: selected.coords }).catch(() => {})
    }, 0)
    return () => window.clearTimeout(timer)
  }, [selected])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (choices.length === 0) return
      const index = Math.max(0, choices.findIndex((loc) => loc.id === selectedId))

      if (e.key === 'ArrowDown') {
        e.preventDefault()
        const next = choices[(index + 1) % choices.length]
        setSelectedId(next.id)
        playUiSound('slotSelect')
        const el = choiceRefs.current.get(next.id)
        if (el) animateSpawnChoiceSelect(el)
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        const prev = choices[(index - 1 + choices.length) % choices.length]
        setSelectedId(prev.id)
        playUiSound('slotSelect')
        const el = choiceRefs.current.get(prev.id)
        if (el) animateSpawnChoiceSelect(el)
      } else if (e.key === 'Enter' && selectedId) {
        e.preventDefault()
        onConfirm(selectedId)
      } else if (e.key === 'Escape') {
        e.preventDefault()
        onCancel()
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [choices, selectedId, onConfirm, onCancel])

  const selectLocation = (id: string) => {
    setSelectedId(id)
    playUiSound('slotSelect')
    const el = choiceRefs.current.get(id)
    if (el) animateSpawnChoiceSelect(el)
  }

  return (
    <div ref={rootRef} className="ryn-spawn-screen" data-animate="spawn-panel">
      <header className="ryn-spawn-title" data-animate="spawn-title">
        <span className="ryn-spawn-title__spawn">{t('spawnTitleSpawn')}</span>
        <span className="ryn-spawn-title__selector">{t('spawnTitleSelector')}</span>
      </header>

      <aside className="ryn-spawn-rail" data-animate="spawn-rail">
        <div className="ryn-spawn-rail__heading">
          <span className="ryn-spawn-rail__icon" aria-hidden>
            <MapPinIcon className="size-3.5" strokeWidth={2.25} />
          </span>
          <div>
            <p className="ryn-spawn-rail__title">{t('chooseLocation')}</p>
            <p className="ryn-spawn-rail__hint-top">{t('spawnSubtitle')}</p>
          </div>
        </div>

        <div className="ryn-spawn-rail__list">
          {groups.length === 0 ? (
            <p className="ryn-spawn-empty">{t('noSpawnResults')}</p>
          ) : (
            groups.map((group) => (
              <div key={group.category} className="ryn-spawn-rail__group">
                <p className="ryn-spawn-rail__label">{group.label}</p>
                {group.items.map((loc) => {
                  const active = loc.id === selectedId
                  return (
                    <button
                      key={loc.id}
                      ref={(el) => {
                        if (el) choiceRefs.current.set(loc.id, el)
                        else choiceRefs.current.delete(loc.id)
                      }}
                      type="button"
                      data-animate="spawn-choice"
                      className={cn('ryn-spawn-choice', active && 'ryn-spawn-choice--active')}
                      onClick={() => selectLocation(loc.id)}
                      aria-pressed={active}
                    >
                      <span className="ryn-spawn-choice__icon">
                        {iconMap[loc.icon] ?? <MapPinIcon className="size-4" strokeWidth={2} />}
                      </span>
                      <span className="ryn-spawn-choice__text">
                        <span className="ryn-spawn-choice__title">{loc.label}</span>
                        {loc.description && (
                          <span className="ryn-spawn-choice__meta">{loc.description}</span>
                        )}
                      </span>
                    </button>
                  )
                })}
              </div>
            ))
          )}
        </div>

        <div className="ryn-spawn-rail__actions" data-animate="spawn-actions">
          <button
            type="button"
            className="ryn-spawn-here"
            disabled={!selectedId}
            onClick={() => selectedId && onConfirm(selectedId)}
          >
            {t('spawnHere')}
          </button>
          <Button
            type="button"
            variant="outline"
            size="lg"
            className="ryn-spawn-back"
            onClick={onCancel}
          >
            {t('back')}
          </Button>
          <p className="ryn-spawn-rail__hint">{t('spawnKeyboardHint')}</p>
        </div>
      </aside>
    </div>
  )
}
