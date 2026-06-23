# CLAUDE.md — Clue Project Context

> **Session continuity instruction:** When your context window is approaching its limit (~60%), save any new decisions, discoveries, or structural changes back into this file before they are lost. Update the relevant section rather than appending blindly. Also update docs/PROJECT_AUDIT.md and tick completed items in docs/roadmap.md. Do not wait to be reminded. This file is the single source of truth across all sessions.

---

## What Is Clue

Clue is a **personal indoor memory and discovery app** built by a solo engineer as a side project.

Users save, search, and revisit indoor places and item locations — where they found the milk, where they parked, which gate to head to, which outlet was free. Clue remembers so the user doesn't have to.

Examples: milk on aisle 7, parking spot B3, Gate 42, quiet corner in the office, the power outlet by the window.

**Core user actions:** Save Memory · Search Memory · View Timeline · Return To Memory · Share Memory

The app provides standalone value through fast memory capture and retrieval. In the background it silently records motion trajectories, BLE and Wi-Fi fingerprints, and sensor data to progressively build indoor maps and improve localization over time.

**The user experience must remain valuable even if indoor localization is initially inaccurate.**

Target localization accuracy (long-term): **2–5 meters**. Not required for the memory features to be useful.

---

## Core Philosophy

**User experience first.** Every feature must have standalone value for the user before it generates data for the system.

For the user-facing app, prioritize in this order:
1. Fast capture
2. Fast retrieval
3. Daily usefulness
4. Simplicity

For the backend system, prioritize in this order:
1. Data collection
2. Visualization
3. Reproducibility
4. Simplicity

Before AI, machine learning, or optimization.

Never introduce machine learning until data collection, replay, visualization, and a baseline implementation exist.

### Product positioning rules (non-negotiable)

- **Never** present Clue as a sensor logger, localization research tool, or data collection platform in the UI
- **Never** use technical terms in user-facing screens: no "session", "trajectory", "fingerprint", "IMU", "sensor"
- **Never** expose sensor collection, recording state, or upload progress to users unless they are in a developer/debug mode
- Every screen must answer: *what does this do for the user right now?*

---

## Repository Structure (Current)

```
clue/
├── apps/
│   ├── mobile/          # Flutter app — map/home placeholder, built on flutter_map
│   ├── mobile.v0/       # Flutter app — Clue SL sensor logger (active development)
│   └── dashboard/       # Future web dashboard (empty)
│
├── crates/              # Rust core (empty scaffolds)
│   ├── sensors/
│   ├── pdr/
│   ├── fingerprint/
│   ├── mapping/
│   └── localization/
│
├── backend/             # Rust/Axum server (empty scaffolds)
│   ├── api/
│   └── workers/
│
├── docs/
│   ├── vision.md
│   ├── roadmap.md
│   ├── PROJECT_AUDIT.md
│   ├── research/        # empty
│   ├── AGENT.md
│   └── PERSONAL_PLAN.md
│
├── data/                # Raw sensor recordings — never deleted (empty)
├── .vscode/launch.json  # Run configs for both mobile and mobile.v0
└── .gitignore           # General + Rust rules only
```

---

## GitHub

Repository: https://github.com/deaazed/clue

**Milestone 1: [CLUE - Sensor Logger (Clue SL)](https://github.com/deaazed/clue/milestone/1)** ✅ COMPLETE

Milestone 1 issues: [#1](https://github.com/deaazed/clue/issues/1) ✅ · [#2](https://github.com/deaazed/clue/issues/2) ✅ · [#3](https://github.com/deaazed/clue/issues/3) ✅ · [#4](https://github.com/deaazed/clue/issues/4) ✅ · [#5 CI](https://github.com/deaazed/clue/issues/5) ✅ · [#6 Backend deploy](https://github.com/deaazed/clue/issues/6) ✅ · [#7 App deploy](https://github.com/deaazed/clue/issues/7) ✅ · [#8 Usability](https://github.com/deaazed/clue/issues/8) ✅

**Milestone 2: [Clue — Memory App MVP](https://github.com/deaazed/clue/milestone/2)** ✅ COMPLETE

Milestone 2 issues: [#9 Vision](https://github.com/deaazed/clue/issues/9) ✅ · [#10 Save Memory](https://github.com/deaazed/clue/issues/10) ✅ · [#11 Timeline](https://github.com/deaazed/clue/issues/11) ✅ · [#12 Search](https://github.com/deaazed/clue/issues/12) ✅ · [#13 Return](https://github.com/deaazed/clue/issues/13) ✅ · [#14 Share](https://github.com/deaazed/clue/issues/14) ✅

**Milestone 3: [Clue — UX Polish + Indoor Maps](https://github.com/deaazed/clue/milestone/3)** ✅ COMPLETE

Milestone 3 issues: [#15 UX redesign](https://github.com/deaazed/clue/issues/15) ✅ · [#16 PMTiles indoor map](https://github.com/deaazed/clue/issues/16) ✅

---

## Current State (as of 2026-06-24)

**Current phase:** Milestone 3 complete. Next: Milestone 4 (Dead Reckoning / Phase 3).

### CI/CD

- CI: GitHub Actions — `flutter analyze` + `flutter test` on `apps/mobile.v0/**` changes
- CD: GitHub Actions on `backend/**` changes → SSH → `git pull` → `docker compose up --build -d` → health check
- Secrets: `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY` ✅

### apps/mobile — map/home prototype

Runs on device (Pixel 6, Android 16). Uses `flutter_map` with OSM tiles.

| File | Notes |
|------|-------|
| `lib/main.dart` | Entry point |
| `lib/services/router.dart` | go_router, home + map routes |
| `lib/pages/home_page.dart` | Homepage placeholder |
| `lib/pages/map_page.dart` | Map page |
| `lib/components/navbar_component.dart` | Bottom nav |
| `lib/components/map_component.dart` | flutter_map with geolocator |

Dependencies: `go_router`, `flutter_map`, `latlong2`, `permission_handler`, `geolocator`, `flutter_svg`

Note: `maplibre_gl` was replaced with `flutter_map` — maplibre_gl 0.20.0 uses the removed Flutter v1 Android embedding API and fails to build on current SDKs.

### apps/mobile.v0 — Clue (active)

Package: `clue_sl` · Org: `com.clue` · Android + iOS only

**Navigation (3 tabs):** Home (map) · Timeline · Search  
**Outside shell:** `/memory` (MemoryDetailPage) · `/sessions/:id` (SessionDetailPage)  
**Dev-only routes:** `/dev/logger` · `/dev/sessions`

| File | Notes |
|------|-------|
| `lib/main.dart` | Entry point → ClueApp |
| `lib/app.dart` | MaterialApp.router, GoRouter, dark + light theme (ThemeMode.system, 0xFF7C3AED seed) |
| `lib/config.dart` | `kBackendUrl = 'http://37.27.255.248:3000'` |
| `lib/models/memory.dart` | Memory model (id, label, iconType, note, lat, lng, bleDevices, timestamp) |
| `lib/models/session.dart` | Session, Vec3, Sample\<T\>, BleDevice |
| `lib/services/memory_repository.dart` | Save/loadAll/delete memories as JSON in Documents/clue_memories/ |
| `lib/services/session_repository.dart` | Save/load/delete sessions as JSON in Documents/clue_sessions/ |
| `lib/services/api_client.dart` | POST /api/sessions, 30 s timeout |
| `lib/widgets/memory_card.dart` | Shared MemoryCard, memoryIcon(), memoryColor() |
| `lib/features/home/home_page.dart` | Full-screen CARTO map, memory pins, search bar overlay, locate-me FAB, Save Memory FAB |
| `lib/features/home/save_memory_sheet.dart` | Bottom sheet: icon picker, label, note, GPS + 1.5 s BLE scan |
| `lib/features/timeline/timeline_page.dart` | Chronological memory list, swipe-to-delete |
| `lib/features/search/search_page.dart` | Live filter on label/note |
| `lib/features/memory_detail/memory_detail_page.dart` | CARTO map pin, live distance, BLE context, note, Open in Maps, Share |
| `lib/features/logger/logger_page.dart` | Dev: record/stop UI, live IMU readout, elapsed timer |
| `lib/services/foreground_task.dart` | Background recording isolate + notification Stop button |
| `lib/features/sessions/sessions_page.dart` | Dev: session list, upload, upload reminder banner |
| `lib/features/session_detail/session_detail_page.dart` | Dev: replay tab + magnitude charts |
| `android/app/src/main/AndroidManifest.xml` | Location + BLE + foreground service permissions |

Dependencies: `go_router`, `sensors_plus`, `flutter_blue_plus`, `path_provider`, `http`, `permission_handler`, `flutter_foreground_task`, `flutter_svg`, `geolocator`, `flutter_map`, `latlong2`, `url_launcher`, `share_plus`

Map tiles:
- Light: `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png` (CARTO Positron)
- Dark: `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png` (CARTO Dark Matter)
- Subdomains: `a,b,c,d` — no API key required

Memory model: icon types with colors — `item` (amber) · `place` (emerald) · `parking` (blue) · `gate` (orange) · `outlet` (yellow) · `restroom` (violet) · `other` (gray)

GPS strategy in save: `getLastKnownPosition()` (≤150 m, ≤15 min) → fallback `getCurrentPosition(medium, 5 s)` → null if all fail

Sensor recording (dev):
- IMU at 20 Hz via `sensors_plus`; BLE scan every 5 s (4 s timeout)
- Sessions stored as `Documents/clue_sessions/<startedAtMs>.json`
- Foreground service keeps recording alive; notification shows elapsed time + Stop button

### Infrastructure

- Mono-repo: `apps/`, `crates/`, `backend/`, `data/`
- `crates/sensors` has real types: `Session`, `Vec3`, `Sample<T>`, 3 unit tests; others are stubs
- `backend/` — Axum + SQLx + PostgreSQL: `GET /health`, `POST /api/sessions`, `GET /api/sessions`, `GET /api/sessions/:id`; `Session.baro` is `#[serde(default)]`
- **VPS**: Hetzner CX23, Helsinki. IPv4: `37.27.255.248`. SSH via `static.248.255.27.37.clients.your-server.de`. Ubuntu 24.04 LTS.
- **Docker**: `Dockerfile` + `docker-compose.yml` at root — multi-stage Rust build + postgres:16-alpine. Running on VPS.

---

## Development Phases

| Phase | Name | Duration | Status |
|-------|------|----------|--------|
| 0 | Project Setup | 1 week | **Done** |
| 1 | Sensor Logger | 2 weeks | **Done** (Milestone 1 closed) |
| 1.5 | Memory App MVP | — | **Done** (Milestone 2 closed) |
| 2 | Replay System | 2 weeks | **Done** (session detail + charts) |
| 2.5 | UX Polish + Indoor Maps | — | **Done** (Milestone 3 closed: #15 #16) |
| 3 | Dead Reckoning | 4 weeks | Not started |
| 4 | Indoor Visualization | 2 weeks | Not started |
| 5 | Collaborative Mapping | 4 weeks | Not started |
| 7 | Fingerprinting | 4 weeks | Not started |
| 8 | Advanced Localization | 4 weeks | Not started |

**Next priority:** Milestone 4 — Dead Reckoning (Phase 3): PDR crate, trajectory rendering, VPS tile setup.

---

## Data Pipeline

```
Raw Sensors → Features → Trajectories → Indoor Graph → Localization → Item Discovery
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Android + iOS) |
| Shared core | Rust (FFI into Flutter) |
| Backend | Rust + Axum + Tokio |
| Database | PostgreSQL |
| Object storage | Cloudflare R2 or Hetzner local |
| Hosting | Hetzner CX23 (~€4.55/month incl. backups) |

Budget constraint: **€15/month**, max €250/year.

---

## Key Decisions

- `maplibre_gl` dropped in favour of `flutter_map` (v1 Android embedding incompatibility)
- Sensor logger lives in `apps/mobile.v0` (separate app from the map prototype in `apps/mobile`)
- `sensors_plus` chosen for IMU; `flutter_blue_plus` for BLE; `http` for backend upload
- Local session format: one JSON file per session in `Documents/clue_sessions/<id>.json`
- Barometer and Wi-Fi scanning not in Clue SL milestone scope
- `Session.baro` is `#[serde(default)]` in Rust — backend accepts uploads without baro data
- Session detail page is a top-level GoRouter route (outside ShellRoute) so it has no bottom nav
- Trajectory rendering = sensor magnitude charts for now; spatial path deferred to Phase 3 (PDR)
- Commit style: `[#<issue>] - <message>` (dash after issue number)
- Product direction: personal indoor memory app — sensor data collected silently; never exposed in UI
- Memory App MVP (#10–#14) complete; both milestones closed as of 2026-06-24
- CARTO Positron (light) + Dark Matter (dark) tiles — no API key, subdomains a/b/c/d
- Share feature uses `share_plus` v10 API: `Share.share(text)` (not ShareParams, which is v11+)
- Multilanguage deferred to a future milestone
- Indoor map (#16): self-hosted PMTiles on VPS via Caddy static file + byte-range. Mapbox rejected (external dependency, API key). MapCache rejected (caching proxy only, doesn't add zoom or indoor data). MapServer rejected (heavy OGC stack, overkill). PMTiles uses same OSM indoor data as Mapbox, keeps flutter_map, zero running cost, Phase 4 floor plan overlays served from same VPS
- Vector tile stack: `vector_map_tiles: ^8.0.0` + `vector_map_tiles_pmtiles: ^1.5.0`; `PmTilesVectorTileProvider.fromSource(kTilesUrl)`; `ProtomapsThemes.lightV4()` / `darkV4()` (v4 schema); CARTO raster as FutureBuilder fallback while provider initialises
- AppSpacing: 4 px base grid — xs=4, sm=8, md=16, lg=24, xl=32, xxl=48; cardRadius=16, sheetRadius=24, iconRadius=12
- BottomSheetThemeData: global `showDragHandle: true`, `dragHandleSize: Size(32,4)`, `RoundedRectangleBorder(radius: 24)` — no per-sheet shape needed
- Hero animations: `hero_icon_${memory.id}` tag on MemoryCard icon container → MemoryDetailPage header icon (52×52)
- Search is a pushed full-screen route (`context.push('/search')`) outside ShellRoute — shows all memories when query empty (browse mode)

---

## Rules

### Always

- Prefer the smallest working solution
- Small commits, incremental delivery
- Testable components
- Preserve all raw sensor data — never delete originals
- Store raw recordings separately from processed outputs
- Visualize data before proposing new algorithms
- Keep infrastructure under €20/month

### Never (in UI)

- Research-oriented or technical terminology exposed to users
- Sensor collection details, recording state, or upload progress visible to users
- Gamification, complex social features

### Never (in system, until 100+ sessions exist and replay + mapping work)

- Deep learning / recommendation systems
- Distributed systems
- Premature optimization

### Rust standards

- Strong typing, small modules, unit tests
- No global mutable state, no large files, no complex abstractions

### Flutter standards

- Feature-based folder structure (`features/<name>/`)
- Stateless widgets where possible
- Clear UI / business logic separation

---

## ML Progression (when the time comes)

1. Rules → 2. Statistics → 3. kNN → 4. HMM → 5. Particle filters → 6. Deep learning

---

## Key Documents

- [docs/vision.md](docs/vision.md) — product goals and success criteria
- [docs/roadmap.md](docs/roadmap.md) — phase breakdown with GitHub milestone
- [docs/PROJECT_AUDIT.md](docs/PROJECT_AUDIT.md) — current state, updated each session
- [docs/AGENT.md](docs/AGENT.md) — agent behavior rules (authoritative)
- [docs/PERSONAL_PLAN.md](docs/PERSONAL_PLAN.md) — solo engineer personal plan
