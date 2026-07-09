import { useEffect, useState } from 'react'
import type { Screen } from '@/types'
import {
  demoCharacters,
  demoCreationFields,
  demoSpawnLocations,
  demoSlotLimit,
  demoTheme,
  demoPosePresets,
} from './demoData'
import { getDemoCharacters, getLastNuiCall, resetDemoState } from './mockNui'
import { Button } from '@/components/ui/button'

const screens: { id: Screen; label: string }[] = [
  { id: 'characterSelect', label: 'Characters' },
  { id: 'creation', label: 'Creation' },
  { id: 'spawnSelect', label: 'Spawn' },
  { id: 'deleteConfirm', label: 'Delete' },
  { id: 'info', label: 'Info' },
  { id: 'adminSlots', label: 'Admin' },
]

export function DevPanel() {
  const [collapsed, setCollapsed] = useState(false)
  const [lastCall, setLastCall] = useState(getLastNuiCall())

  useEffect(() => {
    const interval = setInterval(() => setLastCall(getLastNuiCall()), 300)
    return () => clearInterval(interval)
  }, [])

  const openScreen = (screen: Screen) => {
    if (screen === 'adminSlots') {
      window.postMessage({ action: 'openAdmin' }, '*')
      return
    }

    const data: Record<string, unknown> = {
      theme: demoTheme,
      creationFields: demoCreationFields,
      characters: demoCharacters,
      slotLimit: demoSlotLimit,
      features: { photoMode: true, scenePoses: true },
      posePresets: demoPosePresets,
    }

    if (screen === 'spawnSelect') {
      data.locations = demoSpawnLocations
      data.citizenid = demoCharacters[0]?.citizenid
    }

    window.postMessage({ action: 'open', screen, data }, '*')
  }

  const reopen = () => {
    resetDemoState()
    window.postMessage({
      action: 'open',
      screen: 'characterSelect',
      data: {
        theme: demoTheme,
        creationFields: demoCreationFields,
        characters: getDemoCharacters(),
        slotLimit: demoSlotLimit,
        features: { photoMode: true, scenePoses: true },
        posePresets: demoPosePresets,
      },
    }, '*')
  }

  const close = () => {
    window.postMessage({ action: 'close' }, '*')
  }

  if (collapsed) {
    return (
      <button
        type="button"
        className="ryn-dev-panel--collapsed ryn-dev__chip"
        onClick={() => setCollapsed(false)}
      >
        Dev
      </button>
    )
  }

  return (
    <div className="ryn-dev-panel ryn-dev">
      <div className="mb-3 flex items-center justify-between">
        <span className="ryn-dev__title">Dev tools</span>
        <button
          type="button"
          className="ryn-dev__chip px-2 py-0.5"
          onClick={() => setCollapsed(true)}
        >
          —
        </button>
      </div>

      <div className="mb-3 flex flex-wrap gap-1">
        {screens.map((s) => (
          <button
            key={s.id}
            type="button"
            className="ryn-dev__chip"
            onClick={() => openScreen(s.id)}
          >
            {s.label}
          </button>
        ))}
      </div>

      <div className="flex gap-1.5">
        <Button className="flex-1 uppercase" size="xs" onClick={reopen}>Reset</Button>
        <Button className="flex-1 uppercase" size="xs" variant="outline" onClick={close}>Close</Button>
      </div>

      {lastCall && (
        <p className="ryn-dev__log truncate">
          {lastCall.at} · {lastCall.event}
        </p>
      )}
    </div>
  )
}
