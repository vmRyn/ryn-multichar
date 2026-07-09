import type { Character } from '../types'
import {
  demoCharacters,
  demoSpawnLocations,
  demoSlotLimit,
} from './demoData'

let characters = [...demoCharacters]
let slotEntries = [
  { license: 'license2:abc123def456', slots: 5, source: 'admin', updated_at: new Date().toISOString() },
]
let lastNuiCall: { event: string; data?: unknown; at: string } | null = null

export function getLastNuiCall() {
  return lastNuiCall
}

export function resetDemoState() {
  characters = [...demoCharacters]
  lastNuiCall = null
}

export function getDemoCharacters() {
  return characters
}

function logCall(event: string, data?: unknown) {
  lastNuiCall = { event, data, at: new Date().toLocaleTimeString() }
  console.log(`[ryn-multichar dev] fetchNui("${event}")`, data ?? {})
}

function dispatchOpen(screen: string, data: Record<string, unknown> = {}) {
  window.postMessage({ action: 'open', screen, data }, '*')
}

export async function mockFetchNui<T = unknown>(event: string, data?: unknown): Promise<T> {
  logCall(event, data)

  await new Promise((r) => setTimeout(r, 120))

  switch (event) {
    case 'getCharacters':
      return { characters, slotLimit: demoSlotLimit } as T

    case 'selectSlot':
      return 'ok' as T

    case 'playCharacter': {
      const payload = data as { citizenid: string }
      dispatchOpen('spawnSelect', {
        locations: demoSpawnLocations,
        citizenid: payload.citizenid,
      })
      return { success: true } as T
    }

    case 'deleteCharacter': {
      const payload = data as { citizenid: string; confirmName?: string }
      const target = characters.find((c) => c.citizenid === payload.citizenid)
      const fullName = target ? `${target.charinfo.firstname} ${target.charinfo.lastname}`.trim() : ''
      if (payload.confirmName && payload.confirmName.trim() !== fullName) {
        return { success: false, error: 'name_mismatch' } as T
      }
      characters = characters.filter((c) => c.citizenid !== payload.citizenid)
      return { success: true } as T
    }

    case 'createCharacter': {
      const payload = data as Record<string, string> & { slotIndex: number }
      const newChar: Character = {
        cid: payload.slotIndex,
        citizenid: `RYN00${characters.length + 1}`,
        charinfo: {
          firstname: payload.firstname ?? 'New',
          lastname: payload.lastname ?? 'Character',
          gender: payload.gender === 'female' ? 1 : 0,
        },
        job: { label: 'Unemployed', grade: { name: 'Freelancer' } },
        money: { cash: 500, bank: 5000 },
        last_played: new Date().toISOString(),
        playtime: 0,
      }
      characters = [...characters, newChar]
      return { success: true, character: newChar } as T
    }

    case 'selectSpawn':
      console.log('[ryn-multichar dev] Spawn selected:', data)
      window.postMessage({ action: 'close' }, '*')
      return { success: true } as T

    case 'previewSpawn':
      console.log('[ryn-multichar dev] Spawn preview:', data)
      return 'ok' as T

    case 'photoMode':
      console.log('[ryn-multichar dev] Photo mode:', data)
      return { success: true, active: !!(data as { enabled?: boolean }).enabled } as T

    case 'photoModeInput':
      console.log('[ryn-multichar dev] Photo input:', data)
      return 'ok' as T

    case 'photoModeReset':
      return 'ok' as T

    case 'saveScenePose': {
      const payload = data as { citizenid: string; poseId: string }
      characters = characters.map((character) =>
        character.citizenid === payload.citizenid
          ? { ...character, scene_data: { ...(character.scene_data ?? {}), poseId: payload.poseId } }
          : character,
      )
      return { success: true, scene_data: { poseId: payload.poseId } } as T
    }

    case 'adminListEntries': {
      const payload = data as { search?: string }
      const search = payload.search?.trim().toLowerCase() ?? ''
      const entries = search
        ? slotEntries.filter((entry) => entry.license.toLowerCase().includes(search))
        : slotEntries
      return { entries } as T
    }

    case 'adminGetOnlinePlayers':
      return {
        players: [
          { source: 1, name: 'Ryan Mitchell', license: 'license2:abc123def456', slots: 5 },
        ],
      } as T

    case 'adminSetEntry': {
      const payload = data as { license: string; slots: number }
      slotEntries = [
        {
          license: payload.license,
          slots: payload.slots,
          source: 'admin',
          updated_at: new Date().toISOString(),
        },
        ...slotEntries.filter((entry) => entry.license !== payload.license),
      ]
      return { success: true } as T
    }

    case 'adminDeleteEntry': {
      const payload = data as { license: string }
      slotEntries = slotEntries.filter((entry) => entry.license !== payload.license)
      return { success: true } as T
    }

    case 'adminClose':
      window.postMessage({ action: 'closeAdmin' }, '*')
      return 'ok' as T

    case 'openCreation':
      return 'ok' as T

    case 'close':
      window.postMessage({ action: 'close' }, '*')
      return 'ok' as T

    default:
      console.warn(`[ryn-multichar dev] Unhandled NUI event: ${event}`)
      return {} as T
  }
}
