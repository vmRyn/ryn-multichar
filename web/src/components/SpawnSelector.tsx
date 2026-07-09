import { useEffect, useMemo, useRef, useState } from 'react'
import type { SpawnLocation } from '@/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { fetchNui } from '@/hooks/useNui'
import {
  ChevronRightIcon,
  HistoryIcon,
  HomeIcon,
  MapPinIcon,
  SearchIcon,
  ShieldIcon,
} from 'lucide-react'
import { ScreenPanel } from './ScreenPanel'
import { PanelHeader } from './PanelHeader'
import { useLocale } from '@/hooks/useLocale'
import { cn } from '@/lib/utils'

interface SpawnSelectorProps {
  locations: SpawnLocation[]
  onSelect: (locationId: string) => void
  onCancel: () => void
}

type SpawnCategory = 'last' | 'housing' | 'public'

const iconMap: Record<string, React.ReactNode> = {
  'map-pin': <MapPinIcon className="size-4" strokeWidth={2} />,
  home: <HomeIcon className="size-4" strokeWidth={2} />,
  history: <HistoryIcon className="size-4" strokeWidth={2} />,
  shield: <ShieldIcon className="size-4" strokeWidth={2} />,
  building: <HomeIcon className="size-4" strokeWidth={2} />,
}

function getSpawnCategory(location: SpawnLocation): SpawnCategory {
  if (location.id === 'lastLocation') return 'last'
  if (location.id.startsWith('housing:')) return 'housing'
  return 'public'
}

const categoryOrder: SpawnCategory[] = ['last', 'housing', 'public']

export function SpawnSelector({ locations, onSelect, onCancel }: SpawnSelectorProps) {
  const { t } = useLocale()
  const [query, setQuery] = useState('')
  const [highlightIndex, setHighlightIndex] = useState(0)
  const listRef = useRef<HTMLDivElement>(null)
  const itemRefs = useRef<Array<HTMLButtonElement | null>>([])

  const filteredGroups = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    const filtered = normalized
      ? locations.filter((loc) => loc.label.toLowerCase().includes(normalized))
      : locations

    const labels: Record<SpawnCategory, string> = {
      last: t('spawnGroupLast'),
      housing: t('spawnGroupHousing'),
      public: t('spawnGroupPublic'),
    }

    return categoryOrder
      .map((category) => ({
        category,
        label: labels[category],
        items: filtered.filter((loc) => getSpawnCategory(loc) === category),
      }))
      .filter((group) => group.items.length > 0)
  }, [locations, query, t])

  const flatItems = useMemo(
    () => filteredGroups.flatMap((group) => group.items),
    [filteredGroups],
  )

  useEffect(() => {
    setHighlightIndex(0)
    itemRefs.current = []
  }, [query, locations])

  useEffect(() => {
    if (highlightIndex >= flatItems.length) {
      setHighlightIndex(Math.max(0, flatItems.length - 1))
    }
  }, [flatItems.length, highlightIndex])

  useEffect(() => {
    const highlighted = itemRefs.current[highlightIndex]
    highlighted?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }, [highlightIndex])

  useEffect(() => {
    const item = flatItems[highlightIndex]
    if (!item?.coords) return

    const timer = window.setTimeout(() => {
      fetchNui('previewSpawn', { coords: item.coords }).catch(() => {})
    }, 220)

    return () => window.clearTimeout(timer)
  }, [flatItems, highlightIndex])

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (flatItems.length === 0) return

      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setHighlightIndex((i) => (i + 1) % flatItems.length)
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setHighlightIndex((i) => (i - 1 + flatItems.length) % flatItems.length)
      } else if (e.key === 'Enter') {
        const item = flatItems[highlightIndex]
        if (item) {
          e.preventDefault()
          onSelect(item.id)
        }
      }
    }

    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [flatItems, highlightIndex, onSelect])

  let flatIndex = 0

  return (
    <ScreenPanel animationKey="spawn" maxWidth="lg" bodyClassName="flex max-h-[80vh] flex-col" onBackdropClick={onCancel}>
      <PanelHeader
        eyebrow={t('spawn')}
        title={t('chooseLocation')}
        subtitle={t('spawnCount', { count: flatItems.length })}
        className="mb-4 shrink-0"
      />

      <div className="ryn-search shrink-0">
        <SearchIcon className="ryn-search__icon" aria-hidden />
        <Input
          className="ryn-search__input"
          placeholder={t('searchSpawns')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <div ref={listRef} className="ryn-spawn-list mt-4 min-h-0 flex-1 overflow-y-auto pr-1">
        {filteredGroups.length === 0 ? (
          <p className="ryn-spawn-empty">{t('noSpawnResults')}</p>
        ) : (
          filteredGroups.map((group) => (
            <div key={group.category} className="ryn-spawn-group">
              <p className="ryn-group-label">{group.label}</p>
              <div className="flex flex-col gap-1">
                {group.items.map((loc) => {
                  const index = flatIndex
                  flatIndex += 1
                  const isHighlighted = index === highlightIndex
                  const isFeatured = loc.id === 'lastLocation'

                  return (
                    <button
                      key={loc.id}
                      ref={(el) => {
                        itemRefs.current[index] = el
                      }}
                      type="button"
                      className={cn(
                        'ryn-spawn-item',
                        isFeatured && 'ryn-spawn-item--featured',
                        isHighlighted && 'ryn-spawn-item--active',
                      )}
                      onMouseEnter={() => setHighlightIndex(index)}
                      onFocus={() => setHighlightIndex(index)}
                      onClick={() => onSelect(loc.id)}
                    >
                      <span className="ryn-spawn-icon">
                        {iconMap[loc.icon] ?? <MapPinIcon className="size-4" strokeWidth={2} />}
                      </span>
                      <span className="min-w-0 flex-1 truncate">{loc.label}</span>
                      <ChevronRightIcon className="ryn-spawn-chevron" aria-hidden />
                    </button>
                  )
                })}
              </div>
            </div>
          ))
        )}
      </div>

      <div className="ryn-screen-footer mt-4 shrink-0">
        <p className="ryn-spawn-hint">{t('spawnKeyboardHint')}</p>
        <Button className="shrink-0 uppercase" variant="outline" size="lg" type="button" onClick={onCancel}>
          {t('back')}
        </Button>
      </div>
    </ScreenPanel>
  )
}
