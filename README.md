# ryn-multichar

[![GitHub](https://img.shields.io/badge/GitHub-open%20source-blue?logo=github)](https://github.com/vmRyn/ryn-multichar)
[![Version](https://img.shields.io/badge/version-1.0.0-green)](https://github.com/vmRyn/ryn-multichar)
[![Frameworks](https://img.shields.io/badge/frameworks-QBox%20%7C%20QB%20%7C%20ESX-orange)](https://github.com/vmRyn/ryn-multichar)
[![License](https://img.shields.io/badge/license-no%20redistribution-lightgrey)](LICENSE)

A cinematic multicharacter and spawn selector for **QBox**, **QB-Core**, and **ESX**. One resource replaces the usual `qb-multicharacter` + `qb-spawn` stack with a single 3D scene, glassmorphic NUI, and config-driven setup.

**Free to download and use** on your own FiveM server — no purchase required. Redistribution is not allowed; get it from the official repo only.

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Scene tuning](#scene-tuning)
- [Commands](#commands)
- [Tebex](#tebex)
- [Exports](#exports)
- [Events](#events)
- [Project structure](#project-structure)
- [Development](#development)
- [Testing checklist](#testing-checklist)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Credits](#credits)
- [License](#license)

---

## Features

- **3D character preview** — apartment / studio / rooftop / void scene presets with scripted camera
- **Full character flow** — select, create, delete (type name to confirm), info panel, spawn picker
- **Framework bridge** — auto-detect or manual switch for QBox, QB, ESX
- **Appearance support** — auto-detect illenium-appearance, fivem-appearance, qb-clothing, skinchanger
- **Spawn options** — last location, public spawns, housing hooks (qb-houses, apartments, ps-housing)
- **Slot management** — default limits, per-license overrides, Tebex, admin UI
- **Extra features** — photo mode, per-character poses (props/vehicles), weather/time override
- **Locales** — English + Spanish (NUI and server notifications)
- **Optional** — Discord webhooks, playtime tracking, Kenney UI sounds

---

## Requirements

| Required | Optional |
|----------|----------|
| [ox_lib](https://github.com/overextended/ox_lib) | Appearance script (illenium-appearance recommended) |
| [oxmysql](https://github.com/overextended/oxmysql) | Housing scripts |
| `qbx_core`, `qb-core`, or `es_extended` | Weather sync, Discord, Tebex |

---

## Quick start

### 1. Database

Import the schema:

```bash
# Run on your MySQL server
sql/install.sql
```

If upgrading an existing install, ensure the `ryn_multichar_tebex_pending` table exists (included in the latest `install.sql`).

### 2. Install the resource

```bash
git clone https://github.com/vmRyn/ryn-multichar.git
```

Or download a ZIP from [github.com/vmRyn/ryn-multichar](https://github.com/vmRyn/ryn-multichar).

1. Place the **`ryn-multichar`** folder in your server's `resources` directory. The folder name must match the resource name in `fxmanifest.lua` so `ensure ryn-multichar` works.
2. Pre-built NUI is in `web/dist/`. Rebuild only if you edit the React source:

   ```bash
   cd web
   npm install
   npm run build
   ```

### 3. Server cfg

```cfg
ensure ox_lib
ensure oxmysql
ensure qbx_core          # or qb-core / es_extended
ensure illenium-appearance
ensure ryn-multichar
```

### 4. Framework config

**QBox (recommended)**

In `qbx_core` config, enable external characters:

```lua
useExternalCharacters = true
```

Disable conflicting resources (`qbx_spawn`, `qb-spawn`, built-in multichar).

In `config/shared.lua`:

```lua
Config.Framework = 'qbox'   -- or 'auto'
```

**QB-Core** — disable `qb-multicharacter`, set `Config.Framework = 'qb'`.

**ESX** — disable `esx_multicharacter`, set `Config.Framework = 'esx'`. Tune `Config.ESX.mode` if needed (`legacy` vs `minimal`).

---

## Configuration

| File | Purpose |
|------|---------|
| `config/shared.lua` | Framework, slots, spawns, UI theme, locale, Discord |
| `config/scenes.lua` | Scene preset (`apartment`, `studio`, `rooftop`, `void`) + slot layout |
| `config/appearance.lua` | Appearance provider detection |
| `config/premium.lua` | Photo mode, scene poses, admin panel, weather sync |
| `config/nationalities.lua` | Creation form nationality list |

Full reference: [CONFIG.md](CONFIG.md)

### Common settings

```lua
-- config/shared.lua
Config.Framework = 'auto'
Config.UI.locale = 'en'   -- 'en' | 'es'
Config.UI.serverName = 'RYN'  -- top-left brand; mark uses first letter

Config.Slots = {
    default = 3,
    max = nil,  -- nil = unlimited
    overrides = {
        -- ['license2:abc...'] = 5,
    },
}
```

```lua
-- config/scenes.lua
Config.ActiveScene = 'apartment'   -- apartment | studio | rooftop | void
```

---

## Scene tuning

Admins can capture in-game coordinates for custom slot layouts:

| Command | Description |
|---------|-------------|
| `/ryn_scene_pos` | Copy ped `vector4` to clipboard |
| `/ryn_scene_cam` | Copy camera pos/rot/fov block to clipboard |

Requires `Config.SceneTools.enabled = true` (default). Paste values into `config/scenes.lua`.

---

## Commands

| Command | Permission | Description |
|---------|------------|-------------|
| `/relog` | Configurable (`user` / `admin` / `none`) | Return to character selection |
| `/setslots [id] [amount]` | Admin | Set character slot limit |
| `/addslots [id] [amount]` | Admin | Add slots to a player |
| `/enablechar [id] [amount?]` | Admin | Enable extra slots (default +1) |
| `/charslots` | Admin | Open DB-backed slot management UI |

---

## Tebex

Map packages in `config/shared.lua`:

```lua
Config.Slots.tebex = {
    enabled = true,
    autoApplyOnConnect = true,
    packages = {
        ['YOUR_PACKAGE_ID'] = 2,
    },
}
```

**Tebex console commands** (package actions):

```
ryn_multichar_tebex {packageId} {license}
ryn_multichar_slots {license} {slotCount}
```

**Online grant** (player connected):

```
ryn_multichar_tebex_player {playerId} {packageId}
```

---

## Exports

```lua
exports['ryn-multichar']:OpenCharacterSelect()
exports['ryn-multichar']:OpenSpawnSelector(data)
exports['ryn-multichar']:GetSlotLimit(source)
exports['ryn-multichar']:SetSlotLimit(source, amount)
exports['ryn-multichar']:AddTebexSlots(license, amount)
exports['ryn-multichar']:GrantTebexPackage(license, packageId)
exports['ryn-multichar']:GrantTebexPackageToPlayer(source, packageId)
```

---

## Events

| Event | Side | Description |
|-------|------|-------------|
| `ryn-multichar:client:open` | Client | Open character select |
| `ryn-multichar:client:close` | Client | Close character select |
| `ryn-multichar:client:spawnSelected` | Client | Player chose spawn location |
| `ryn-multichar:server:characterLoaded` | Server | Character loaded into session |
| `ryn-multichar:server:characterDeleted` | Server | Character permanently deleted |

---

## Project structure

```
ryn-multichar/
├── config/          # Shared Lua configuration
├── bridge/          # QB / ESX / QBox adapters
├── client/          # Scene, camera, preview, NUI callbacks
├── server/          # Characters, slots, spawn, housing, Tebex
├── shared/          # Utils + config validation
├── web/             # React NUI (src + dist)
├── sql/             # Database schema
├── LICENSE
├── README.md
└── CONFIG.md
```

---

## Development

Run the NUI locally without FiveM:

```bash
cd web
npm run dev
```

Open `http://localhost:5173/` and use the **Dev** panel (top-right) to switch screens.

---

## Testing checklist

Primary validation path is QBox; QB and ESX should follow the same flow after framework config.

- [ ] SQL tables created
- [ ] Resource starts; framework detected in console
- [ ] Character select opens on connect
- [ ] Slot switch updates 3D preview + camera
- [ ] Create → appearance → spawn → fade in
- [ ] Last location + public spawns work
- [ ] Housing spawns appear (if applicable)
- [ ] Delete requires full name
- [ ] Info panel: job, cash, bank, playtime
- [ ] `/relog` works
- [ ] Photo mode + pose save
- [ ] Admin `/charslots` persists to DB
- [ ] Discord webhooks (if enabled)

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No framework detected | Set `Config.Framework` manually in `config/shared.lua` |
| UI blank / old | Run `cd web && npm run build`, restart resource |
| Characters not loading (QBox) | Confirm `useExternalCharacters = true` in qbx_core |
| Appearance not on preview ped | Check appearance resource is started; see `config/appearance.lua` |
| Housing spawns missing | Verify housing script + DB tables match `server/housing.lua` queries |
| Config warnings on start | Enable `Config.Debug = true` for details |

---

## Contributing

Bug reports, feature requests, and pull requests are welcome on [GitHub](https://github.com/vmRyn/ryn-multichar).

When opening a PR:

1. Describe the framework you tested against (QBox, QB, or ESX).
2. If you change the NUI, run `npm run build` in `web/` and include the updated `web/dist/` output.
3. Keep config changes documented in [CONFIG.md](CONFIG.md) when adding new options.

---

## Credits

- UI sound effects: [Kenney UI SFX Set](https://kenney.nl/assets/ui-audio) (CC0)

---

## License

Free for personal and commercial use on **your own server(s)**. You may modify it for your server. **Redistribution is not permitted** — do not re-upload, mirror, or resell this resource. See [LICENSE](LICENSE) for full terms. Official source: [github.com/vmRyn/ryn-multichar](https://github.com/vmRyn/ryn-multichar).
