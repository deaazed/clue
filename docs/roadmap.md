# Roadmap

Effort: 8–12 hours/week. One solo engineer.

GitHub: https://github.com/deaazed/clue

---

## Milestone: CLUE - Sensor Logger (Clue SL)

**Due:** 2026-07-31 · GitHub issues: [#1 Infrastructure](https://github.com/deaazed/clue/issues/1) · [#2 Sensor Collection](https://github.com/deaazed/clue/issues/2) · [#3 Visualization](https://github.com/deaazed/clue/issues/3)

Three issue groups:

### Infrastructure

- [x] Repository cleanup
- [x] Flutter application
- [x] Rust core setup
- [x] Axum backend
- [x] PostgreSQL

### Sensor Collection

- [ ] Accelerometer
- [ ] Gyroscope
- [ ] Magnetometer
- [ ] BLE scan
- [ ] Session recording

### Visualization

- [ ] Session browser
- [ ] Session replay
- [ ] Trajectory rendering

---

## Phase 0 — Project Setup (1 week)

- [x] Create repository
- [x] Create Flutter application skeleton
- [x] Repository cleanup (remove unused platforms, update pubspec description)
- [x] Move Flutter app to `apps/mobile/`
- [x] Create Rust core library (`crates/`)
- [x] Create Axum backend (`backend/`)
- [x] Configure PostgreSQL
- [ ] Configure CI

**Deliverable:** application compiles and backend deploys.

---

## Phase 1 — Sensor Logger (2 weeks)

- [ ] Accelerometer stream
- [ ] Gyroscope stream
- [ ] Magnetometer stream
- [ ] BLE scan
- [ ] Session recording (start / stop / persist locally)
- [ ] Session upload to backend

**Deliverable:** raw sensor logs stored and uploadable.

---

## Phase 2 — Replay System (2 weeks)

- [ ] Session browser (list all sessions)
- [ ] Session replay (play / pause / scrub)
- [ ] Timeline view of sensor streams

**Deliverable:** sensor sessions can be replayed and inspected.

---

## Phase 3 — Dead Reckoning (4 weeks)

- [ ] Step detection from accelerometer
- [ ] Heading estimation from magnetometer + gyroscope
- [ ] Path reconstruction (PDR algorithm)
- [ ] Trajectory rendering on 2D canvas

**Deliverable:** approximate user path reconstructed from sensors.

---

## Phase 4 — Indoor Visualization (2 weeks)

- [ ] 2D canvas rendering
- [ ] Overlay session trajectories
- [ ] Render markers
- [ ] Basic zoom/pan

**Deliverable:** paths and markers displayed visually.

---

## Phase 5 — Collaborative Mapping (4 weeks)

- [ ] Upload trajectories to server
- [ ] Trajectory clustering
- [ ] Walkable area detection
- [ ] Walkable graph generation
- [ ] Path density map

**Deliverable:** emerging indoor map built from crowd data.

---

## Phase 6 — Item Tagging (4 weeks)

- [ ] Drop marker at current position
- [ ] Attach photo to marker
- [ ] Add name and description
- [ ] Search markers by name

**Deliverable:** items discoverable by all users.

---

## Phase 7 — Fingerprinting (4 weeks)

- [ ] Wi-Fi fingerprint collection
- [ ] BLE fingerprint collection
- [ ] Magnetic fingerprint collection
- [ ] kNN location matching

**Deliverable:** approximate position estimate from fingerprints.

---

## Phase 8 — Advanced Localization (4 weeks)

- [ ] Particle filter
- [ ] Hidden Markov Model
- [ ] Map matching
- [ ] Smooth real-time tracking

**Deliverable:** stable, continuous location tracking (2–5 m accuracy).

---

## Infrastructure Milestones

| Milestone | Target |
|-----------|--------|
| First real session uploaded | End of Phase 1 |
| First trajectory visualized | End of Phase 3 |
| First collaborative map | End of Phase 5 |
| First item found by a user | End of Phase 6 |
| Location estimate live | End of Phase 7 |
