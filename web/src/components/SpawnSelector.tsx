import { useEffect, useMemo, useRef, useState } from 'react'
import type { SpawnLocation } from '@/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
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
  showFilters?: boolean
  onConfirm: (locationId: string) => void
  onCancel: () => void
}

type SpawnCategory = 'last' | 'housing' | 'public' | 'job'
type FilterId = 'all' | SpawnCategory

const iconMap: Record<string, React.ReactNode> = {
  'map-pin': <MapPinIcon className="size-4" strokeWidth={2} />,
  home: <HomeIcon className="size-4" strokeWidth={2} />,
  history: <HistoryIcon className="size-4" strokeWidth={2} />,
  shield: <ShieldIcon className="size-4" strokeWidth={2} />,
  building: <HomeIcon className="size-4" strokeWidth={2} />,
}

function getCategory(location: SpawnLocation): SpawnCategory {
  if (location.group === 'last' || location.group === 'housing' || location.group === 'public' || location.group === 'job') {
    return location.group
  }
  if (location.id === 'lastLocation') return 'last'
  if (location.id.startsWith('housing:')) return 'housing'
  return 'public'
}

const categoryOrder: SpawnCategory[] = ['last', 'housing', 'job', 'public']

export function SpawnSelector({
  locations,
  showFilters = true,
  onConfirm,
  onCancel,
}: SpawnSelectorProps) {
  const { t } = useLocale()
  const rootRef = useRef<HTMLDivElement>(null)
  const choiceRefs = useRef<Map<string, HTMLButtonElement>>(new Map())
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState<FilterId>('all')

  const availableFilters = useMemo(() => {
    const present = new Set<SpawnCategory>()
    for (const loc of locations) present.add(getCategory(loc))
    return (['all', ...categoryOrder.filter((id) => present.has(id))] as FilterId[])
  }, [locations])

  useEffect(() => {
    if (!availableFilters.includes(filter)) setFilter('all')
  }, [availableFilters, filter])

  const filtered = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return locations.filter((loc) => {
      if (filter !== 'all' && getCategory(loc) !== filter) return false
      if (!needle) return true
      const haystack = `${loc.label} ${loc.description ?? ''}`.toLowerCase()
      return haystack.includes(needle)
    })
  }, [locations, query, filter])

  const [selectedId, setSelectedId] = useState<string | null>(filtered[0]?.id ?? null)

  const selected = useMemo(
    () => filtered.find((loc) => loc.id === selectedId) ?? null,
    [filtered, selectedId],
  )

  const groups = useMemo(() => {
    const labels: Record<SpawnCategory, string> = {
      last: t('spawnGroupLast'),
      housing: t('spawnGroupHousing'),
      public: t('spawnGroupPublic'),
      job: t('spawnGroupJobs'),
    }

    return categoryOrder
      .map((category) => ({
        category,
        label: labels[category],
        items: filtered.filter((loc) => getCategory(loc) === category),
      }))
      .filter((group) => group.items.length > 0)
  }, [filtered, t])

  useEffect(() => {
    if (!selectedId && filtered[0]) setSelectedId(filtered[0].id)
    if (selectedId && !filtered.some((loc) => loc.id === selectedId)) {
      setSelectedId(filtered[0]?.id ?? null)
    }
  }, [filtered, selectedId])

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
    if (!selectedId) return
    const el = choiceRefs.current.get(selectedId)
    el?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }, [selectedId])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      const tag = target?.tagName.toLowerCase()
      const isTyping = tag === 'input' || tag === 'textarea' || target?.isContentEditable

      if (e.key === 'Escape') {
        e.preventDefault()
        onCancel()
        return
      }

      if (isTyping || filtered.length === 0) return
      const index = Math.max(0, filtered.findIndex((loc) => loc.id === selectedId))

      if (e.key === 'ArrowDown') {
        e.preventDefault()
        const next = filtered[(index + 1) % filtered.length]
        setSelectedId(next.id)
        playUiSound('slotSelect')
        const el = choiceRefs.current.get(next.id)
        if (el) animateSpawnChoiceSelect(el)
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        const prev = filtered[(index - 1 + filtered.length) % filtered.length]
        setSelectedId(prev.id)
        playUiSound('slotSelect')
        const el = choiceRefs.current.get(prev.id)
        if (el) animateSpawnChoiceSelect(el)
      } else if (e.key === 'Enter' && selectedId) {
        e.preventDefault()
        onConfirm(selectedId)
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [filtered, selectedId, onConfirm, onCancel])

  const selectLocation = (id: string) => {
    setSelectedId(id)
    playUiSound('slotSelect')
    const el = choiceRefs.current.get(id)
    if (el) animateSpawnChoiceSelect(el)
  }

  const filterLabel = (id: FilterId) => {
    if (id === 'all') return t('spawnFilterAll')
    if (id === 'last') return t('spawnGroupLast')
    if (id === 'housing') return t('spawnGroupHousing')
    if (id === 'job') return t('spawnGroupJobs')
    return t('spawnGroupPublic')
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
            <p className="ryn-spawn-rail__hint-top">
              {t('spawnSubtitle')}
              {' · '}
              {t('spawnCount', { count: locations.length })}
            </p>
          </div>
        </div>

        {showFilters && availableFilters.length > 2 && (
          <div className="ryn-spawn-filters" role="tablist" aria-label={t('spawnFilters')}>
            {availableFilters.map((id) => (
              <button
                key={id}
                type="button"
                role="tab"
                aria-selected={filter === id}
                className={cn('ryn-spawn-filter', filter === id && 'ryn-spawn-filter--active')}
                onClick={() => {
                  setFilter(id)
                  playUiSound('slotSelect')
                }}
              >
                {filterLabel(id)}
              </button>
            ))}
          </div>
        )}

        {locations.length > 3 && (
          <div className="ryn-spawn-rail__search">
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder={t('searchSpawns')}
              autoComplete="off"
            />
          </div>
        )}

        <div className="ryn-spawn-rail__list">
          {groups.length === 0 ? (
            <div className="ryn-spawn-empty-state">
              <span className="ryn-spawn-empty-state__mark" aria-hidden>
                <MapPinIcon className="size-5" strokeWidth={1.75} />
              </span>
              <p className="ryn-spawn-empty-state__title">
                {locations.length === 0 ? t('noSpawnLocationsTitle') : t('noSpawnResultsTitle')}
              </p>
              <p className="ryn-spawn-empty-state__copy">
                {locations.length === 0 ? t('noSpawnLocationsBody') : t('noSpawnResultsBody')}
              </p>
            </div>
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
