import type { UISounds } from '@/types'
import { prefersReducedMotion } from '@/lib/motion'

export type UiSoundId = 'slotSelect' | 'confirm' | 'error' | 'transition'

const DEFAULT_VOLUME = 0.28
const SOUND_BASE = `${import.meta.env.BASE_URL}sounds/kenney/`

/** Kenney UI Audio (CC0) — https://kenney.nl/assets/ui-audio */
const DEFAULT_SOUNDS: Record<UiSoundId, string> = {
  slotSelect: `${SOUND_BASE}rollover2.ogg`,
  transition: `${SOUND_BASE}switch33.ogg`,
  confirm: `${SOUND_BASE}switch20.ogg`,
  error: `${SOUND_BASE}switch9.ogg`,
}

let config: UISounds = { enabled: false, volume: DEFAULT_VOLUME }

const audioCache = new Map<string, HTMLAudioElement>()

function getAudio(url: string): HTMLAudioElement {
  const cached = audioCache.get(url)
  if (cached) return cached

  const audio = new Audio(url)
  audio.preload = 'auto'
  audioCache.set(url, audio)
  return audio
}

function resolveSoundUrl(id: UiSoundId): string | null {
  const custom = config[id]
  if (custom) return custom
  return DEFAULT_SOUNDS[id]
}

export function configureSounds(sounds?: UISounds) {
  config = {
    enabled: false,
    volume: DEFAULT_VOLUME,
    ...sounds,
  }
}

export function preloadUiSounds() {
  if (!config.enabled) return
  for (const id of Object.keys(DEFAULT_SOUNDS) as UiSoundId[]) {
    const url = resolveSoundUrl(id)
    if (url) getAudio(url)
  }
}

export function playUiSound(id: UiSoundId) {
  if (!config.enabled || prefersReducedMotion()) return

  const url = resolveSoundUrl(id)
  if (!url) return

  const volume = config.volume ?? DEFAULT_VOLUME
  const template = getAudio(url)
  const audio = template.cloneNode() as HTMLAudioElement
  audio.volume = volume
  void audio.play().catch(() => {
    // Ignore autoplay / missing file errors
  })
}
