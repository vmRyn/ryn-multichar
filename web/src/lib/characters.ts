import type { Character } from '@/types'

export function getCharacterForSlot(characters: Character[], slotIndex: number): Character | undefined {
  const byCid = characters.find((c) => (c.cid ?? c.slot) === slotIndex)
  if (byCid) return byCid
  return characters[slotIndex - 1]
}

export function getLastPlayedCitizenId(characters: Character[]): string | null {
  return getLastPlayedCharacter(characters)?.citizenid ?? null
}

export function getLastPlayedCharacter(characters: Character[]): Character | null {
  let latest: Character | null = null
  let latestTime = 0

  for (const character of characters) {
    if (!character.last_played) continue
    const raw = character.last_played
    const time = typeof raw === 'number' ? raw : Date.parse(raw) || Number(raw) || 0
    if (!Number.isNaN(time) && time >= latestTime) {
      latestTime = time
      latest = character
    }
  }

  return latest
}

export type LastOnlineBadge = { kind: 'new' } | { kind: 'relative'; key: string; count: number }

/** Relative last-online badge for dock slots. */
export function getLastOnlineBadge(character?: Character): LastOnlineBadge | null {
  if (!character) return null

  const playtime = character.playtime ?? 0
  if (!character.last_played && playtime <= 0) {
    return { kind: 'new' }
  }

  if (!character.last_played) return null

  const raw = character.last_played
  const time = typeof raw === 'number' ? raw : Date.parse(String(raw).replace(' ', 'T'))
  if (!Number.isFinite(time)) {
    return playtime <= 0 ? { kind: 'new' } : null
  }

  const diffMs = Math.max(0, Date.now() - time)
  const minute = 60_000
  const hour = 60 * minute
  const day = 24 * hour
  const week = 7 * day

  if (diffMs < hour) return { kind: 'relative', key: 'badgeJustNow', count: 0 }
  if (diffMs < day) {
    return { kind: 'relative', key: 'badgeHoursAgo', count: Math.max(1, Math.floor(diffMs / hour)) }
  }
  if (diffMs < week) {
    return { kind: 'relative', key: 'badgeDaysAgo', count: Math.max(1, Math.floor(diffMs / day)) }
  }
  return { kind: 'relative', key: 'badgeWeeksAgo', count: Math.max(1, Math.floor(diffMs / week)) }
}
