# CLAUDE.md — Clue Project Context

> **Session continuity instruction:** When your context window is approaching its limit (~60%), save any new decisions, discoveries, or structural changes back into this file before they are lost. Update the relevant section rather than appending blindly. Also update docs/PROJECT_AUDIT.md and tick completed items in docs/roadmap.md. Do not wait to be reminded. This file is the single source of truth across all sessions.

---

## What Is Clue

Clue is a crowdsourced indoor localization system built by a solo engineer as a side project.

Users contribute motion trajectories, raw sensor recordings, and indoor markers. The system learns indoor layouts over time and lets users locate items and points of interest inside buildings.

Examples: find milk in a supermarket, Gate B12 in an airport, a shop in a mall, a conference room in an office.

Target localization accuracy: **2–5 meters**. Perfect positioning is not required.

---

## Core Philosophy

Always prioritize in this order:

1. Data collection
2. Visualization
3. Reproducibility
4. Simplicity

Before AI, machine learning, or optimization.

Never introduce machine learning until data collection, replay, visualization, and a baseline implementation exist.

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

**Active milestone: [CLUE - Sensor Logger (Clue SL)](https://github.com/deaazed/clue/milestone/1)** (due 2026-07-31)

Issues: [#1](https://github.com/deaazed/clue/issues/1) ✅ · [#2](https://github.com/deaazed/clue/issues/2) ✅ · [#3](https://github.com/deaazed/clue/issues/3) ✅ · [#4](https://github.com/deaazed/clue/issues/4) ✅ · [#5 CI](https://github.com/deaazed/clue/issues/5) · [#6 Backend deploy](https://github.com/deaazed/clue/issues/6) · [#7 App deploy](https://github.com/deaazed/clue/issues/7) · [#8 Usability](https://github.com/deaazed/clue/issues/8)

---

## Current State (as of 2026-06-19)

**Current phase:** Phase 1 — Sensor Logger. Issues #1–#4 closed. Open: #5 CI, #6 Backend deployment, #7 App deployment, #8 Usability enhancements.

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

### apps/mobile.v0 — Clue SL sensor logger (active)

Package: `clue_sl` · Org: `com.clue` · Android + iOS only

| File | Notes |
|------|-------|
| `lib/main.dart` | Entry point → ClueApp |
| `lib/app.dart` | MaterialApp.router + GoRouter + shell nav + `/sessions/:id` route outside shell |
| `lib/config.dart` | `kBackendUrl` constant — change to LAN IP or Hetzner URL |
| `lib/models/session.dart` | Session, Vec3, Sample\<T\>, BleDevice — mirrors Rust types |
| `lib/services/session_repository.dart` | Save/load/delete sessions as JSON in Documents/clue_sessions/ |
| `lib/services/api_client.dart` | `ApiClient.uploadSession()` — POST /api/sessions, 30 s timeout |
| `lib/features/logger/logger_controller.dart` | ChangeNotifier — start/stop, IMU streams, BLE scan loop |
| `lib/features/logger/logger_page.dart` | Record/stop UI + live sensor readout + elapsed timer |
| `lib/features/sessions/sessions_page.dart` | Session list, per-tile upload icon, Upload All button with slide-out animation |
| `lib/features/session_detail/session_detail_page.dart` | Replay tab (scrubber + live values) + Charts tab (magnitude line charts) |
| `android/app/src/main/AndroidManifest.xml` | Location + BLE permissions declared |

Dependencies: `go_router`, `sensors_plus`, `flutter_blue_plus`, `path_provider`, `http`

Sensor recording design:
- IMU at 20 Hz (50 ms period) via `sensors_plus` — accel, gyro, mag
- BLE scan every 5 s (4 s timeout) via `flutter_blue_plus`; skipped gracefully if BT off or permissions denied
- UI refreshes at 10 Hz (100 ms timer) — sensor data accumulates independently at full rate
- Sessions stored as `Documents/clue_sessions/<startedAtMs>.json` (one file per session)

Upload design:
- `ApiClient.uploadSession()` POSTs session JSON to `kBackendUrl/api/sessions`
- On success: local file deleted, tile animates out (`SizeTransition` + `FadeTransition`, 350 ms)
- Backend accepts missing `baro` field (`#[serde(default)]` on `Session.baro`)
- `kBackendUrl` in `lib/config.dart` — set to machine LAN IP for physical device testing

Session detail (issue #3):
- Tap any session tile → `SessionDetailPage` (pushed outside shell, back button in AppBar)
- **Replay tab**: MM:SS.t timer, scrubber slider, play/pause (100 ms ticks), binary-search sample lookup, live accel/gyro/mag/BLE tiles
- **Charts tab**: accel / gyro / mag magnitude (√x²+y²+z²) over time, drawn with `CustomPainter` (no extra dep)

### Infrastructure

- Mono-repo structure in place: `apps/`, `crates/`, `backend/`, `data/`
- Rust workspace configured at `Cargo.toml` (root), 5 crates + backend stub
- `crates/sensors` has real types: `Session`, `Vec3`, `Sample<T>`, all sensor aliases, 3 unit tests
- `crates/pdr`, `fingerprint`, `mapping`, `localization` are stubs (depend on `sensors`)
- `backend/` is a real Axum server: health check + session CRUD, SQLx + PostgreSQL, auto-migrations
- Rust installed (GNU toolchain `x86_64-pc-windows-gnu`). Run `cargo build` from the repo root.
- PostgreSQL database installed. Ran `cargo run -p backend` from the repo root and ran `Invoke-RestMethod http://localhost:3000/health` resulting `ok`.

---

## Development Phases

| Phase | Name | Duration | Status |
|-------|------|----------|--------|
| 0 | Project Setup | 1 week | **Done** |
| 1 | Sensor Logger | 2 weeks | **In progress** (core done, pending: CI, deploy, usability) |
| 2 | Replay System | 2 weeks | Not started |
| 3 | Dead Reckoning | 4 weeks | Not started |
| 4 | Indoor Visualization | 2 weeks | Not started |
| 5 | Collaborative Mapping | 4 weeks | Not started |
| 6 | Item Tagging | 4 weeks | Not started |
| 7 | Fingerprinting | 4 weeks | Not started |
| 8 | Advanced Localization | 4 weeks | Not started |

**First milestone:** A deployed app that records sensor sessions, uploads them, and replays them.

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
| Hosting | Hetzner Cloud (~€8/month) |

Budget constraint: **€15/month**, max €250/year.

---

## Sensor Logger (Phase 1) — Target Deliverables

Working from `apps/mobile.v0` (package `clue_sl`):

- Accelerometer recording
- Gyroscope recording
- Magnetometer recording
- BLE scanning
- Session recording (start / stop / persist locally)

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

### Never (until 100+ sessions exist and replay + mapping work)

- User accounts / social features / gamification
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
