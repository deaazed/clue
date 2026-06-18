# Clue

Crowdsourced indoor localization system.

Users contribute sensor traces, trajectories, and location markers while moving through indoor environments. Clue reconstructs indoor spaces from this collective data and helps users find items and points of interest inside buildings — supermarkets, airports, malls, offices.

## Requirements

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Android or iOS device / emulator

## Setup

```sh
git clone https://github.com/deaazed/clue.git
cd clue/apps/mobile
flutter pub get
flutter run
```

## Project structure

```
clue/
├── apps/
│   └── mobile/          # Flutter app (Android + iOS)
├── crates/              # Rust core (sensors, PDR, fingerprinting, mapping, localization)
├── backend/             # Rust/Axum server
├── data/                # Raw sensor recordings
└── docs/                # Vision, roadmap, project audit
```

## Roadmap

See [docs/roadmap.md](docs/roadmap.md).

## License

MIT
