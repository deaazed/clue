# Project Audit

*Update this file at the end of each work session or after any significant structural change.*

Last updated: 2026-06-24 (end of session)

---

## Current Phase

**Between milestones.** Both Milestone 1 (Sensor Logger) and Milestone 2 (Memory App MVP) are fully complete. Next: Phase 3 (Dead Reckoning) or dogfooding the app as-is.

---

## Milestone 1 — CLUE Sensor Logger (Clue SL) ✅ COMPLETE

All issues closed: #1 · #2 · #3 · #4 · #5 · #6 · #7 · #8

| Task | Status |
|------|--------|
| Flutter app skeleton (mobile.v0) | ✅ |
| Rust core setup | ✅ |
| Axum + PostgreSQL backend | ✅ |
| Accelerometer / gyroscope / magnetometer | ✅ |
| BLE scan | ✅ |
| Session recording (start/stop/persist) | ✅ |
| Session upload to backend (POST /api/sessions) | ✅ |
| Session browser + replay + magnitude charts | ✅ |
| Background foreground service + notifications | ✅ |
| Runtime permissions | ✅ |
| CI (GitHub Actions — test + analyze) | ✅ |
| CD (GitHub Actions — SSH deploy to Hetzner) | ✅ |
| Backend deployed to Hetzner CX23 (Docker Compose) | ✅ |
| App deployed to Pixel 6 (debug APK) | ✅ |

---

## Milestone 2 — Memory App MVP ✅ COMPLETE

All issues closed: #9 · #10 · #11 · #12 · #13 · #14

| Issue | Feature | Status |
|-------|---------|--------|
| #9 | App vision / rebrand to "Clue" | ✅ |
| #10 | Save Memory (GPS + BLE + icon picker + label/note) | ✅ |
| #11 | Timeline (chronological list, swipe-to-delete) | ✅ |
| #12 | Search (live filter on label/note) | ✅ |
| #13 | Return to Memory (detail page: map pin, live distance, navigate) | ✅ |
| #14 | Share Memory (native share sheet from detail AppBar) | ✅ |

---

## apps/mobile.v0 (Clue — active)

**Status:** Both sensor logger (dev routes) and Memory App MVP features fully implemented.

Package: `clue_sl` · Org: `com.clue` · Android + iOS

### Navigation

Three user-facing tabs (NavigationBar):
- **Home** (`/home`) — full-screen CARTO map with memory pins, search bar overlay, locate-me FAB, Save Memory extended FAB
- **Timeline** (`/timeline`) — chronological memory list, swipe-to-delete, tap → detail
- **Search** (`/search`) — live filter on label/note, tap → detail

Dev-only routes (no nav entry):
- `/dev/logger` — sensor recorder (record/stop, live IMU readout)
- `/dev/sessions` — session browser + upload + replay

Outside shell (no nav bar):
- `/memory` — MemoryDetailPage (map, distance, BLE context, note, Open in Maps, Share)
- `/sessions/:id` — SessionDetailPage (replay tab + charts tab)

### Key files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point |
| `lib/app.dart` | MaterialApp.router, GoRouter, dark + light theme (ThemeMode.system, 0xFF7C3AED seed) |
| `lib/config.dart` | `kBackendUrl = 'http://37.27.255.248:3000'` |
| `lib/models/memory.dart` | Memory model (id, label, iconType, note, lat, lng, bleDevices, timestamp) |
| `lib/models/session.dart` | Session, Vec3, Sample\<T\>, BleDevice |
| `lib/services/memory_repository.dart` | Save/loadAll/delete memories as JSON in Documents/clue_memories/ |
| `lib/services/session_repository.dart` | Save/load/delete sessions as JSON in Documents/clue_sessions/ |
| `lib/services/api_client.dart` | POST /api/sessions |
| `lib/features/home/home_page.dart` | Map-first home (CARTO tiles, pins, search bar, locate-me, save sheet) |
| `lib/features/home/save_memory_sheet.dart` | Bottom sheet: icon picker, label, note, GPS + BLE capture |
| `lib/features/timeline/timeline_page.dart` | Chronological memory list |
| `lib/features/search/search_page.dart` | Live search |
| `lib/features/memory_detail/memory_detail_page.dart` | Detail + Share |
| `lib/features/logger/logger_page.dart` | Dev sensor recorder UI |
| `lib/features/sessions/sessions_page.dart` | Dev session list + upload |
| `lib/features/session_detail/session_detail_page.dart` | Replay + charts |
| `lib/widgets/memory_card.dart` | Shared `MemoryCard`, `memoryIcon()`, `memoryColor()` |
| `lib/services/foreground_task.dart` | Background recording isolate |

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `go_router` | ^14.6.2 | Navigation |
| `sensors_plus` | ^6.1.1 | IMU (accel/gyro/mag) |
| `flutter_blue_plus` | ^1.35.3 | BLE scan |
| `path_provider` | ^2.1.4 | Local file paths |
| `http` | ^1.2.0 | Session upload |
| `permission_handler` | ^11.3.1 | Runtime permissions |
| `flutter_foreground_task` | ^8.0.0 | Background recording |
| `flutter_svg` | ^2.0.16 | SVG logo |
| `geolocator` | ^13.0.1 | GPS location |
| `flutter_map` | ^7.0.2 | Map tiles |
| `latlong2` | ^0.9.0 | LatLng types |
| `url_launcher` | ^6.3.0 | Open in Maps |
| `share_plus` | ^10.1.0 | Native share sheet |

### Map tile URLs

- Light: `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png` (CARTO Positron)
- Dark: `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png` (CARTO Dark Matter)
- Subdomains: `a, b, c, d` · No API key required

### Memory model

Stored in `Documents/clue_memories/<id>.json`. Fields:
- `id` (ms timestamp string), `label`, `iconType`, `note?`, `lat?`, `lng?`, `bleDevices[]`, `timestamp`
- Icon types: `item` (amber) · `place` (emerald) · `parking` (blue) · `gate` (orange) · `outlet` (yellow) · `restroom` (violet) · `other` (gray)

---

## Infrastructure

### Backend (Hetzner CX23)

- IPv4: `37.27.255.248` · SSH: `static.248.255.27.37.clients.your-server.de`
- Docker Compose: multi-stage Rust build + postgres:16-alpine
- Routes: `GET /health` · `POST /api/sessions` · `GET /api/sessions` · `GET /api/sessions/:id`
- Session `baro` field is `#[serde(default)]` — upload works without barometer data
- CD: GitHub Actions deploy on push to `backend/**` or `Dockerfile` paths

### CI/CD

- `.github/workflows/ci.yml` — `flutter analyze` + `flutter test` on `apps/mobile.v0/**` changes
- `.github/workflows/deploy.yml` — SSH to Hetzner on `backend/**` changes → git pull + docker compose up --build -d + health check

### Rust

- Workspace compiles. `cargo test -p sensors` passes (3 tests).
- `crates/sensors` — real types: `Session`, `Vec3`, `Sample<T>`, sensor aliases
- `crates/pdr`, `fingerprint`, `mapping`, `localization` — stubs (Phase 3+)

---

## Decisions

| Decision | Reason |
|----------|--------|
| `maplibre_gl` → `flutter_map` | maplibre uses removed v1 Android plugin API |
| Sensor logger in `apps/mobile.v0` | Separate from map prototype in `apps/mobile` |
| CARTO tiles (no API key) | Stadia requires account; CARTO Positron/Dark Matter free |
| Share via `share_plus` | Native platform share sheet, no custom UI needed |
| Session detail outside ShellRoute | No bottom nav on detail page |
| Charts with `CustomPainter` | No extra dependency |
| Commit style | `[#<issue>] - <message>` |
| Memory App MVP scope | GPS + BLE context at capture; no floor plans or PDR yet |
| Dev routes hidden at `/dev/*` | User-facing UI never shows sensor terminology |

---

## Open Questions / Next Steps

- **Dogfooding**: use the app in real indoor environments — find pain points before adding features
- **Phase 3 (Dead Reckoning)**: step detection from accelerometer, heading from gyro+mag, PDR path reconstruction — requires 100+ real sessions first
- **App distribution** (#7): still using `flutter run` / sideloaded APK; Play Store / TestFlight not set up
- **Multilanguage** (#9 comment): deferred to future milestone
