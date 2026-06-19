# Project Audit

*Update this file at the end of each work session or after any significant structural change.*

Last updated: 2026-06-19

---

## Current Phase

**Phase 1 — Sensor Logger** (in progress)

Phase 0 complete. Issue #1 (Infrastructure) closed. Active issue: **#2 Sensor Collection** in `apps/mobile.v0`.

---

## Active Milestone

**[CLUE - Sensor Logger (Clue SL)](https://github.com/deaazed/clue/milestone/1)** · Due 2026-07-31

| Group | Task | Status |
|-------|------|--------|
| Infrastructure | Repository cleanup | ✅ Done |
| Infrastructure | Flutter application (apps/mobile.v0 created) | ✅ Done |
| Infrastructure | Rust core setup | ✅ Done |
| Infrastructure | Axum backend | ✅ Done |
| Infrastructure | PostgreSQL | ✅ Done |
| Sensor Collection | Accelerometer | ✅ Done |
| Sensor Collection | Gyroscope | ✅ Done |
| Sensor Collection | Magnetometer | ✅ Done |
| Sensor Collection | BLE scan | ✅ Done |
| Sensor Collection | Session recording | ✅ Done |
| Visualization | Session browser | ✅ Done |
| Visualization | Session replay | ✅ Done |
| Visualization | Trajectory rendering | ✅ Done |

---

## Repository Structure

```
clue/
├── apps/
│   ├── mobile/          # Map/home prototype — flutter_map, runs on device
│   ├── mobile.v0/       # Clue SL sensor logger — active development
│   └── dashboard/       # Placeholder
├── crates/              # sensors/ pdr/ fingerprint/ mapping/ localization/ — all empty
├── backend/             # api/ workers/ — empty
├── data/                # empty
└── docs/                # vision, roadmap, audit, research/ (empty)
```

---

## apps/mobile (map prototype)

**Status:** Builds and runs on Pixel 6 (Android 16, API 36).

| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^14.6.2 | Navigation |
| `flutter_map` | ^8.1.1 | Map (OSM raster tiles) |
| `latlong2` | ^0.9.1 | LatLng types for flutter_map |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `geolocator` | ^13.0.2 | Current location |
| `flutter_svg` | ^2.0.16 | SVG logo |

**Note:** `maplibre_gl` was removed — it uses the removed Flutter v1 Android embedding API (`PluginRegistry.Registrar`) and fails to build on Flutter 3.x / Android API 36.

AndroidManifest: `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` declared.

---

## apps/mobile.v0 (Clue SL — active)

**Status:** Sensor recording fully implemented. Runs and saves sessions locally on device.

Package name: `clue_sl` · Org: `com.clue` · Platforms: Android + iOS

| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^14.6.2 | Navigation |
| `sensors_plus` | ^6.1.1 | Accelerometer, gyroscope, magnetometer, barometer |
| `flutter_blue_plus` | ^1.35.3 | BLE scanning |
| `path_provider` | ^2.1.4 | Local session file paths |

Structure:
```
lib/
├── main.dart
├── app.dart                              # MaterialApp.router + shell nav
├── models/session.dart                   # Session, Vec3, Sample<T>, BleDevice
├── services/session_repository.dart      # Save/load sessions as JSON to Documents/
└── features/
    ├── logger/
    │   ├── logger_controller.dart        # Recording state (ChangeNotifier)
    │   └── logger_page.dart             # Record/stop UI + live sensor readout
    └── sessions/sessions_page.dart      # Saved session list with pull-to-refresh
```

AndroidManifest permissions:
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- `BLUETOOTH`, `BLUETOOTH_ADMIN` (≤API 30)
- `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (API 31+)

VS Code launch configs: `clue SL (debug/profile/release)` — `cwd: apps/mobile.v0`

---

## Rust crates

Workspace compiles. Run `cargo test -p sensors` to verify (3 tests).

| Crate | Path | Status |
|-------|------|--------|
| `sensors` | `crates/sensors/` | Types defined — `Session`, `AccelSample`, `GyroSample`, `MagSample`, `BaroSample`, `BleSample`, 3 unit tests |
| `pdr` | `crates/pdr/` | Stub — Phase 3 |
| `fingerprint` | `crates/fingerprint/` | Stub — Phase 7 |
| `mapping` | `crates/mapping/` | Stub — Phase 5 |
| `localization` | `crates/localization/` | Stub — Phase 8 |

## Backend

Axum + SQLx backend implemented. Awaiting PostgreSQL install (see `SETUP_BACKEND.md`).

Routes:
- `GET  /health` — liveness check
- `POST /api/sessions` — upload a `Session` (JSON body matching `crates/sensors::Session`)
- `GET  /api/sessions` — list sessions (id, timestamps, sample count)
- `GET  /api/sessions/:id` — retrieve full session JSON

Migration: `backend/migrations/0001_create_sessions.sql` — runs automatically on first boot.

Schema: `sessions(id UUID PK, started_at_ms, duration_ms, sample_count, data JSONB, recorded_at)`

## Database

Not provisioned.

## CI

Not configured.

---

## Decisions Made

| Decision | Reason |
|----------|--------|
| `maplibre_gl` → `flutter_map` | maplibre_gl 0.20.0 uses removed v1 Android plugin API |
| Sensor logger in `apps/mobile.v0` | Separate app keeps it clean from the map prototype |
| `sensors_plus` for IMU | Standard Flutter sensor package, covers all required streams |
| `flutter_blue_plus` for BLE | Most maintained BLE package for Flutter |
| Barometer + Wi-Fi not in Clue SL scope | Not in GitHub milestone issues |
| Local session format | JSON per session — one file per session in `Documents/clue_sessions/<id>.json` |

---

## Open Questions

- Local session storage format for `apps/mobile.v0` (SQLite? JSONL files? protobuf?)
- Trajectory rendering in visualization phase: Canvas 2D or MapLibre-style overlay?
- When to introduce Rust FFI — before or after first real session is recorded?
