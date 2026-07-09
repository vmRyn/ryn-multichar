import { useEffect, useCallback } from 'react'
import type { NuiMessage } from '../types'
import { isDevMode } from '../dev/isDevMode'
import { mockFetchNui } from '../dev/mockNui'

const resourceName = (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? 'ryn-multichar'

export { isDevMode }

export function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T> {
  if (isDevMode()) {
    return mockFetchNui<T>(event, data)
  }

  return fetch(`https://${resourceName}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data ?? {}),
  }).then((res) => res.json())
}

export function useNuiEvent<T = NuiMessage>(action: string, handler: (data: T) => void) {
  const stableHandler = useCallback(handler, [handler])

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const { action: eventAction, ...rest } = event.data ?? {}
      if (eventAction === action) {
        stableHandler(rest as T)
      }
    }

    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action, stableHandler])
}

export function formatPlaytime(seconds?: number): string {
  if (!seconds || seconds <= 0) return '0h'
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  if (hours > 0) return `${hours}h ${minutes}m`
  return `${minutes}m`
}

export function formatMoney(amount?: number): string {
  return `$${(amount ?? 0).toLocaleString()}`
}

export function getFullName(charinfo?: { firstname: string; lastname: string }): string {
  if (!charinfo) return ''
  return `${charinfo.firstname} ${charinfo.lastname}`.trim()
}
