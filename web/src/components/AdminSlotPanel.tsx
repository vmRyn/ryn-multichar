import { useCallback, useEffect, useState } from 'react'
import type { AdminSlotEntry, OnlinePlayerSlot } from '@/types'
import { fetchNui } from '@/hooks/useNui'
import { useLocale } from '@/hooks/useLocale'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { AnimatedPanel } from './AnimatedPanel'
import { notifyError, notifySuccess } from '@/lib/toast'
import {
  PencilIcon,
  SaveIcon,
  SearchIcon,
  ShieldIcon,
  Trash2Icon,
  UsersIcon,
  XIcon,
} from 'lucide-react'

interface AdminSlotPanelProps {
  open: boolean
  onClose: () => void
}

function playerInitials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (!parts.length) return '?'
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return `${parts[0][0]}${parts[1][0]}`.toUpperCase()
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-6">
      <button
        type="button"
        className="ryn-modal-backdrop absolute inset-0"
        onClick={handleClose}
        aria-label={t('close')}
      />

      <AnimatedPanel className="relative w-full max-w-xl" animationKey="admin">
        <div className="ryn-panel ryn-admin-panel">
          <div className="ryn-modal-body">
            <div className="ryn-side-panel__heading">
              <span className="ryn-side-panel__icon" aria-hidden>
                <ShieldIcon className="size-3.5" strokeWidth={2.25} />
              </span>
              <div className="min-w-0 flex-1">
                <p className="ryn-side-panel__title">{t('adminSlotTitle')}</p>
                <p className="ryn-side-panel__hint">{t('adminSlotSubtitle')}</p>
              </div>
              <button
                type="button"
                className="ryn-modal-close"
                onClick={handleClose}
                aria-label={t('close')}
              >
                <XIcon className="size-4" />
              </button>
            </div>

            <div className="ryn-admin-search">
              <SearchIcon className="ryn-admin-search__icon" aria-hidden />
              <Input
                className="ryn-admin-search__input"
                placeholder={t('adminSearchLicense')}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') handleSearch()
                }}
              />
              <Button size="sm" onClick={handleSearch} disabled={loading}>
                {t('adminSearch')}
              </Button>
            </div>

            {onlinePlayers.length > 0 && (
              <section className="ryn-admin-block">
                <div className="ryn-admin-block__heading">
                  <span className="ryn-side-panel__icon ryn-side-panel__icon--sm" aria-hidden>
                    <UsersIcon className="size-3" strokeWidth={2.25} />
                  </span>
                  <div>
                    <p className="ryn-side-panel__title">{t('adminOnlinePlayers')}</p>
                    <p className="ryn-side-panel__hint">
                      {t('adminOnlineCount', { count: onlinePlayers.length })}
                    </p>
                  </div>
                </div>

                <div className="ryn-admin-list">
                  {onlinePlayers.map((player) => (
                    <div key={player.source} className="ryn-admin-card">
                      <span className="ryn-avatar" aria-hidden>
                        {playerInitials(player.name)}
                      </span>
                      <div className="ryn-admin-card__text">
                        <p className="ryn-admin-card__name">{player.name}</p>
                        <p className="ryn-admin-card__meta">{player.license}</p>
                      </div>
                      <span className="ryn-admin-badge">{player.slots}</span>
                      <Button size="sm" variant="outline" onClick={() => handleApplyOnline(player)}>
                        <PencilIcon className="size-3.5" />
                        {t('adminEdit')}
                      </Button>
                    </div>
                  ))}
                </div>
              </section>
            )}

            <section className="ryn-admin-block ryn-admin-block--scroll">
              <div className="ryn-admin-block__heading">
                <span className="ryn-side-panel__icon ryn-side-panel__icon--sm" aria-hidden>
                  <SaveIcon className="size-3" strokeWidth={2.25} />
                </span>
                <div>
                  <p className="ryn-side-panel__title">{t('adminSavedEntries')}</p>
                  <p className="ryn-side-panel__hint">{t('adminSavedHint')}</p>
                </div>
              </div>

              {entries.length === 0 ? (
                <div className="ryn-info-empty">
                  <p>{loading ? t('adminLoading') : t('adminNoEntries')}</p>
                </div>
              ) : (
                <div className="ryn-admin-list">
                  {entries.map((entry) => (
                    <div key={entry.license} className="ryn-admin-card ryn-admin-card--entry">
                      <div className="ryn-admin-card__text">
                        <p className="ryn-admin-card__name ryn-admin-card__name--mono">{entry.license}</p>
                        <p className="ryn-admin-card__meta">
                          {entry.source}
                          {' · '}
                          {entry.updated_at ? new Date(entry.updated_at).toLocaleString() : '—'}
                        </p>
                      </div>
                      <Input
                        className="ryn-admin-slots-input"
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
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleDelete(entry.license)}
                        aria-label={t('adminReset')}
                      >
                        <Trash2Icon className="size-3.5" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </section>

            <div className="ryn-modal-actions">
              <Button size="lg" variant="outline" onClick={handleClose}>
                {t('close')}
              </Button>
            </div>
          </div>
        </div>
      </AnimatedPanel>
    </div>
  )
}
