export interface Character {
  cid?: number
  slot?: number
  citizenid: string
  charinfo: {
    firstname: string
    lastname: string
    gender?: number
  }
  job?: {
    label: string
    grade?: { name: string }
  }
  money?: {
    cash: number
    bank: number
  }
  last_played?: string
  playtime?: number
  scene_data?: {
    poseId?: string
  }
}

export interface PosePreset {
  id: string
  label: string
}

export interface FeatureFlags {
  photoMode?: boolean
  scenePoses?: boolean
}

export interface AdminSlotEntry {
  license: string
  slots: number
  source: string
  updated_at?: string
}

export interface OnlinePlayerSlot {
  source: number
  name: string
  license: string
  slots: number
}

export interface CreationField {
  name: string
  label: string
  type: 'text' | 'date' | 'select' | 'autocomplete'
  required: boolean
  options?: string[]
}

export interface SpawnLocation {
  id: string
  label: string
  icon: string
  coords?: { x: number; y: number; z: number; w?: number }
}

export interface UISounds {
  enabled?: boolean
  slotSelect?: string
  transition?: string
  confirm?: string
  error?: string
  volume?: number
}

export interface UITheme {
  theme: string
  colors: {
    primary: string
    background: string
    surface: string
    border: string
    text: string
    textMuted: string
    danger: string
    success?: string
    warning?: string
  }
  logo?: string
  locale?: 'en' | 'es'
  sounds?: UISounds
}

export type Screen = 'characterSelect' | 'creation' | 'spawnSelect' | 'deleteConfirm' | 'info' | 'adminSlots'

export interface NuiMessage {
  action: 'open' | 'close' | 'openAdmin' | 'closeAdmin'
  screen?: Screen
  data?: Record<string, unknown>
}
