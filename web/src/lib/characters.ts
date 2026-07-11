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
