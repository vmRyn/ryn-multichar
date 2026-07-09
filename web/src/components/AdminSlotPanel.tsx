import { useCallback, useEffect, useState } from 'react'
import type { AdminSlotEntry, OnlinePlayerSlot } from '@/types'
import { fetchNui } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { ScreenPanel } from './ScreenPanel'
import { PanelHeader } from './PanelHeader'
import { notifyError, notifySuccess } from '@/lib/toast'
import { SearchIcon, Trash2Icon } from 'lucide-react'

interface AdminSlotPanelProps {
  open: boolean
  onClose: () => void
}

export function AdminSlotPanel({ open, onClose }: AdminSlotPanelProps) {
  const { t } = useLocale()
  const [search, setSearch] = useState('')
  const [entries, setEntries] = useState<AdminSlotEntry[]>([])
  const [onlinePlayers, setOnlinePlayers] = useState<OnlinePlayerSlot[]>([])
  const [drafts, setDrafts] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(false)

  const loadData = useCallback(async (query = search) => {
    setLoading(true)
    try {
      const [entriesResult, playersResult] = await Promise.all([
        fetchNui<{ entries: AdminSlotEntry[] }>('adminListEntries', { search: query }),
        fetchNui<{ players: OnlinePlayerSlot[] }>('adminGetOnlinePlayers'),
      ])
      setEntries(entriesResult.entries ?? [])
      setOnlinePlayers(playersResult.players ?? [])
      const nextDrafts: Record<string, string> = {}
      for (const entry of entriesResult.entries ?? []) {
        nextDrafts[entry.license] = String(entry.slots)
      }
      setDrafts(nextDrafts)
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    } finally {
      setLoading(false)
    }
  }, [search, t])

  useEffect(() => {
    if (!open) return
    loadData('')
  }, [open, loadData])

  const handleSearch = async () => {
    await loadData(search)
  }

  const handleSave = async (license: string) => {
    const slots = Number(drafts[license])
    if (!license || !slots || slots < 1) return

    try {
      const result = await fetchNui<{ success: boolean }>('adminSetEntry', { license, slots })
      if (result?.success) {
        notifySuccess(t('adminSaved'), t('adminSavedDesc'))
        await loadData(search)
      } else {
        notifyError(t('toastError'), t('toastErrorDesc'))
      }
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }

  const handleDelete = async (license: string) => {
    try {
      const result = await fetchNui<{ success: boolean }>('adminDeleteEntry', { license })
      if (result?.success) {
        notifySuccess(t('adminDeleted'), t('adminDeletedDesc'))
        await loadData(search)
      } else {
        notifyError(t('toastError'), t('toastErrorDesc'))
      }
    } catch {
      notifyError(t('toastError'), t('toastErrorDesc'))
    }
  }

  const handleClose = () => {
    fetchNui('adminClose').catch(() => {})
    onClose()
  }

  const handleApplyOnline = (player: OnlinePlayerSlot) => {
    setDrafts((current) => ({ ...current, [player.license]: String(player.slots) }))
    setEntries((current) => {
      const exists = current.some((entry) => entry.license === player.license)
      if (exists) return current
      return [
        {
          license: player.license,
          slots: player.slots,
          source: 'config',
          updated_at: new Date().toISOString(),
        },
        ...current,
      ]
    })
  }

  if (!open) return null

  return (
    <ScreenPanel animationKey="admin" maxWidth="lg" bodyClassName="flex max-h-[85vh] flex-col" onBackdropClick={handleClose}>
      <PanelHeader
        eyebrow={t('adminPanel')}
        title={t('adminSlotTitle')}
        subtitle={t('adminSlotSubtitle')}
        className="mb-4 shrink-0"
      />

      <div className="ryn-search shrink-0 flex items-center gap-2">
        <SearchIcon className="ryn-search__icon" aria-hidden />
        <Input
          className="ryn-search__input"
          placeholder={t('adminSearchLicense')}
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') handleSearch()
          }}
        />
        <Button className="shrink-0" size="sm" onClick={handleSearch} disabled={loading}>
          {t('adminSearch')}
        </Button>
      </div>

      {onlinePlayers.length > 0 && (
        <div className="ryn-admin-section mt-4 shrink-0">
          <p className="ryn-group-label">{t('adminOnlinePlayers')}</p>
          <div className="flex flex-col gap-1">
            {onlinePlayers.map((player) => (
              <div key={player.source} className="ryn-admin-row">
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{player.name}</p>
                  <p className="truncate text-xs text-muted-foreground">{player.license}</p>
                </div>
                <span className="ryn-admin-badge">{player.slots}</span>
                <Button size="sm" variant="outline" onClick={() => handleApplyOnline(player)}>
                  {t('adminEdit')}
                </Button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="ryn-admin-table mt-4 min-h-0 flex-1 overflow-y-auto pr-1">
        <p className="ryn-group-label">{t('adminSavedEntries')}</p>
        {entries.length === 0 ? (
          <p className="ryn-spawn-empty">{loading ? t('adminLoading') : t('adminNoEntries')}</p>
        ) : (
          <div className="flex flex-col gap-1">
            {entries.map((entry) => (
              <div key={entry.license} className="ryn-admin-row">
                <div className="min-w-0 flex-1">
                  <p className="truncate font-mono text-xs">{entry.license}</p>
                  <p className="text-xs text-muted-foreground">
                    {entry.source} · {entry.updated_at ? new Date(entry.updated_at).toLocaleString() : '—'}
                  </p>
                </div>
                <Input
                  className="w-20"
                  type="number"
                  min={1}
                  value={drafts[entry.license] ?? entry.slots}
                  onChange={(e) =>
                    setDrafts((current) => ({ ...current, [entry.license]: e.target.value }))
                  }
                />
                <Button size="sm" onClick={() => handleSave(entry.license)}>
                  {t('adminSave')}
                </Button>
                <Button size="sm" variant="outline" onClick={() => handleDelete(entry.license)} aria-label={t('adminReset')}>
                  <Trash2Icon className="size-4" />
                </Button>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="ryn-screen-footer mt-4 shrink-0">
        <Button variant="outline" size="lg" onClick={handleClose}>
          {t('close')}
        </Button>
      </div>
    </ScreenPanel>
  )
}
