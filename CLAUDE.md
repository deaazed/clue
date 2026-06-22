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

**Active milestone: [CLUE - Sensor Logger (Clue SL)](https://github.com/deaazed/clue/milestone/1)** (due 2026-07-31) — finishing deployment

**Next milestone: [Clue — Memory App MVP](https://github.com/deaazed/clue/milestone/2)** (due 2027-03-31) — user-facing memory features

Milestone 1 issues: [#1](https://github.com/deaazed/clue/issues/1) ✅ · [#2](https://github.com/deaazed/clue/issues/2) ✅ · [#3](https://github.com/deaazed/clue/issues/3) ✅ · [#4](https://github.com/deaazed/clue/issues/4) ✅ · [#5 CI](https://github.com/deaazed/clue/issues/5) ✅ · [#6 Backend deploy](https://github.com/deaazed/clue/issues/6) · [#7 App deploy](https://github.com/deaazed/clue/issues/7) · [#8 Usability](https://github.com/deaazed/clue/issues/8) ✅

Milestone 2 issues: [#9 Vision](https://github.com/deaazed/clue/issues/9) · [#10 Save Memory](https://github.com/deaazed/clue/issues/10) · [#11 Timeline](https://github.com/deaazed/clue/issues/11) · [#12 Search](https://github.com/deaazed/clue/issues/12) · [#13 Return](https://github.com/deaazed/clue/issues/13) · [#14 Share](https://github.com/deaazed/clue/issues/14)

---

## Current State (as of 2026-06-22)

**Current phase:** Phase 1 — Sensor Logger. Issues #1–#5 and #8 closed. Open: #6 Backend deployment, #7 App deployment.

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
| `lib/services/foreground_task.dart` | `foregroundEntryPoint` + `_RecordingTaskHandler` — runs in foreground service isolate |
| `lib/features/sessions/sessions_page.dart` | Session list, per-tile upload icon, Upload All button, upload reminder MaterialBanner |
| `lib/features/session_detail/session_detail_page.dart` | Replay tab (scrubber + live values) + Charts tab (magnitude line charts) |
| `android/app/src/main/AndroidManifest.xml` | Location + BLE + foreground service permissions + ForegroundTaskService |

Dependencies: `go_router`, `sensors_plus`, `flutter_blue_plus`, `path_provider`, `http`, `permission_handler`, `flutter_foreground_task`

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

Usability (issue #8):
- **Permissions**: `permission_handler` requests location + BLE scan/connect + notifications on first recording
- **Foreground service**: `flutter_foreground_task` keeps recording alive when app is backgrounded; persistent notification shows elapsed time + Stop action button
- **Notification Stop button**: handled via `_RecordingTaskHandler.onNotificationButtonPressed` → `sendDataToMain('stop')` → `LoggerController._onTaskData` calls `stop()`
- **Upload reminder**: `MaterialBanner` shown on Sessions page if any session > 5 min is pending upload
- **Live sample count**: `accelCount` / `gyroCount` / `magCount` getters on `LoggerController`, shown as a compact row during recording

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
| 1 | Sensor Logger | 2 weeks | **In progress** (core done, pending: deploy #6 #7) |
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
| Hosting | Hetzner CX23 (~€4.55/month incl. backups) |

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
- Product direction: personal indoor memory app — sensor data collected silently; never exposed in UI
- Memory App MVP (#10–#14) starts after backend (#6) and app (#7) are deployed

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
