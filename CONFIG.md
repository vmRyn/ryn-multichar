# Configuration reference

All config lives under `config/`. Restart the resource after changes.

---

## `shared.lua`

### `Config.Framework`
`'auto'` | `'qb'` | `'esx'` | `'qbox'`

Auto-detects from started resources.

### `Config.Slots`
| Key | Description |
|-----|-------------|
| `default` | Default character slots per license |
| `max` | `nil` = unlimited cap |
| `overrides` | Per-license overrides |
| `tebex.enabled` | Enable Tebex integration |
| `tebex.packages` | `[packageId] = slotsToAdd` |

### `Config.UI`
| Key | Description |
|-----|-------------|
| `locale` | `'en'` or `'es'` (NUI + server notifications) |
| `colors` | Theme CSS variables |
| `logo` | Optional server logo URL |
| `sounds` | Kenney UI audio paths |

### `Config.ESX`
| Key | Description |
|-----|-------------|
| `mode` | `'legacy'` (full insert) or `'minimal'` (core columns only) |
| `identifierFormat` | Default `char%d:%s` |

### `Config.Spawns` / `Config.SpawnOptions`
Public spawn locations and toggles for last location / housing.

### `Config.Housing.providers`
Enabled housing script names. Use `Config.Housing.custom.getOwned` for custom integrations.

### `Config.StarterItems`
Items granted on create. Disabled automatically when framework handles starter items (QBox).

---

## `scenes.lua`

```lua
Config.ActiveScene = 'apartment' -- apartment | studio | rooftop | void
```

Each preset defines:
- `coords` — scene center (hidden player position)
- `ipl` — optional IPL name
- `slots[n].ped` — preview ped `vector4`
- `slots[n].camera` — `{ pos, rot, fov }`
- `slots[n].posePreset` — default pose from `premium.lua`
- `slots[n].idleAnim` — fallback animation
- `weather`, `time`, `lighting`

Use `/ryn_scene_pos` and `/ryn_scene_cam` in-game to tune coordinates.

---

## `appearance.lua`

Set `provider = 'auto'` to detect illenium-appearance → fivem-appearance → qb-clothing → skinchanger.

Use `Config.CustomAppearance` hooks when `provider = 'custom'`.

---

## `premium.lua`

| Section | Description |
|---------|-------------|
| `Config.PhotoMode` | Orbit camera limits |
| `Config.SceneSync` | Override weather/time in multichar |
| `Config.ScenePoses` | Per-character pose presets (anim/props/vehicles) |
| `Config.AdminPanel` | `/charslots` UI settings |

---

## Locales

- NUI: `web/src/locales/en.json`, `es.json`
- Server: `config/locales/en.lua`, `es.lua` (selected via `Config.UI.locale`)

---

## Validation

On resource start, `shared/validate.lua` logs warnings for missing framework, empty Discord webhooks when enabled, invalid scene preset, etc. Enable `Config.Debug = true` for verbose output.
