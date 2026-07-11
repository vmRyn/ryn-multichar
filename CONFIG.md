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
| `serverName` | Brand text (top-left); mark uses first letter |
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

### `Config.SceneTools`
In-game helpers for authoring scenes (`/ryn_scene_pos`, `/ryn_scene_cam`). Requires admin ACE by default.

---

## `scenes.lua`

```lua
Config.ActiveScene = 'yacht' -- apartment | yacht
```

Built-in presets: **`apartment`** (IPL interior) and **`yacht`** (exterior). Add more under `Config.ScenePresets` with the same shape.

Each preset defines:
- `coords` — scene streaming anchor (hidden player position)
- `ipl` — optional IPL name (`apa_v_mp_h_01_a` for apartment; works best with `bob74_ipl`)
- `slots[n].ped` — preview ped `vector4`
- `slots[n].camera` — `{ pos, rot, fov }` (place in front of the ped)
- `slots[n].idleAnim` — default look when the character has no saved pose
- `weather`, `time`, `lighting`

Players can switch presets live in photo mode. Use `/ryn_scene_pos` and `/ryn_scene_cam` in-game to tune coordinates.

Unknown saved `sceneId` values (e.g. removed presets) are ignored; the active scene stays as configured.

---

## `appearance.lua`

Set `provider = 'auto'` to detect illenium-appearance → fivem-appearance → qb-clothing → skinchanger.

Use `Config.CustomAppearance` hooks when `provider = 'custom'`.

---

## `premium.lua`

| Section | Description |
|---------|-------------|
| `Config.PhotoMode` | Orbit camera limits (FOV, distance, pitch) |
| `Config.SceneSync` | Override weather/time in multichar |
| `Config.ScenePoses` | Per-character pose presets (standing / lean / props) |
| `Config.AdminPanel` | `/charslots` UI settings |

Default pose presets: standing, crossed arms, lean wall, lean & phone, smoking, bong, coffee, beer. Prefer standing/leaning anims so peds don’t clip through furniture.

---

## Locales

- NUI: `web/src/locales/en.json`, `es.json`
- Server: `config/locales/en.lua`, `es.lua` (selected via `Config.UI.locale`)

---

## Validation

On resource start, `shared/validate.lua` logs warnings for missing framework, empty Discord webhooks when enabled, invalid scene preset, etc. Enable `Config.Debug = true` for verbose output.
