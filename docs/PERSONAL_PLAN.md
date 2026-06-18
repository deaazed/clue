# PERSONAL_PLAN.md

# Indoor Item Finder & Crowdsourced Indoor Mapping

## Vision

Build a crowdsourced indoor positioning system that allows users to locate items, products, services, gates, or points of interest inside buildings.

Examples:

* Find milk in a supermarket
* Find Gate B12 in an airport
* Find a specific shop in a mall
* Find a conference room in an office

The system should improve automatically as more users contribute trajectories and sensor data.

---

# Core Principle

The project is NOT an indoor GPS.

The project is:

1. Sensor collection
2. Path reconstruction
3. Collaborative mapping
4. Fingerprinting
5. Item discovery

Localization is only one component.

---

# Success Criteria

## Version 0.1

Record sensor sessions.

User can:

* Start recording
* Walk
* Stop recording
* Upload session

---

## Version 0.2

Replay recorded sessions.

User can:

* View paths
* View sensor streams
* Inspect sessions

---

## Version 0.3

Generate approximate indoor maps.

System can:

* Cluster trajectories
* Detect walkable areas
* Detect entrances

---

## Version 0.4

Item tagging.

Users can:

* Drop markers
* Upload photos
* Name locations

---

## Version 0.5

Indoor positioning.

System estimates:

* Current location
* Nearby items
* Suggested route

Target accuracy:

2–5 meters

---

# Budget

## First Year Target

Maximum budget:

€250

Target monthly cost:

€15

---

## Infrastructure

### Hosting

Hetzner Cloud

Estimated:

€8/month

---

### Domain

Estimated:

€10-15/year

---

### Storage

Cloudflare R2 or local object storage

Estimated:

€0-5/month

---

# Technology Stack

## Mobile

Flutter

Reason:

* Fast iteration
* Android
* iOS
* Easy Rust integration

---

## Core Engine

Rust

Responsibilities:

* Sensor processing
* PDR
* Localization
* Fingerprinting
* Mapping

---

## Backend

Rust

Framework:

* Axum
* Tokio

Database:

* PostgreSQL

---

# Development Schedule

Estimated effort:

8-12 hours per week

---

# Phase 0

## Project Setup

Duration:

1 week

Tasks:

* Create repository
* Create Flutter application
* Create Rust core library
* Create backend
* Configure PostgreSQL
* Configure CI

Deliverable:

Application compiles and deploys.

---

# Phase 1

## Sensor Logger

Duration:

2 weeks

Tasks:

* Accelerometer
* Gyroscope
* Magnetometer
* Barometer
* BLE scan
* Wi-Fi scan
* Session recording

Deliverable:

Raw sensor logs.

---

# Phase 2

## Replay System

Duration:

2 weeks

Tasks:

* Session browser
* Replay controls
* Timeline view
* Export data

Deliverable:

Sensor sessions can be replayed.

---

# Phase 3

## Dead Reckoning

Duration:

4 weeks

Tasks:

* Step detection
* Heading estimation
* Path reconstruction
* Trajectory rendering

Deliverable:

Approximate user path.

---

# Phase 4

## Indoor Visualization

Duration:

2 weeks

Tasks:

* 2D canvas
* Session rendering
* Marker rendering

Deliverable:

Paths displayed visually.

---

# Phase 5

## Collaborative Mapping

Duration:

4 weeks

Tasks:

* Upload trajectories
* Trajectory clustering
* Walkable graph generation
* Path density maps

Deliverable:

Emerging indoor map.

---

# Phase 6

## Item Tagging

Duration:

4 weeks

Tasks:

* Drop marker
* Add photo
* Add description
* Search markers

Deliverable:

Items discoverable by users.

---

# Phase 7

## Fingerprinting

Duration:

4 weeks

Tasks:

* Wi-Fi fingerprints
* BLE fingerprints
* Magnetic fingerprints
* kNN localization

Deliverable:

Approximate location estimate.

---

# Phase 8

## Advanced Localization

Duration:

4 weeks

Tasks:

* Particle filter
* Hidden Markov Model
* Map matching

Deliverable:

Stable location tracking.

---

# Weekly Routine

Monday

Architecture and planning.

Tuesday

Backend.

Wednesday

Rust algorithms.

Thursday

Flutter UI.

Friday

Testing.

Weekend

Real-world data collection.

---

# Research Topics

Priority order:

1. Pedestrian Dead Reckoning
2. Indoor Positioning
3. Magnetic Fingerprinting
4. Particle Filters
5. Hidden Markov Models
6. Graph Optimization
7. SLAM

---

# Things To Avoid

Do NOT build:

* User accounts
* Social feeds
* Gamification
* Deep learning
* Recommendation systems

until:

* 100+ recorded sessions exist
* Replay system exists
* Mapping works

---

# First Major Milestone

A deployed logger app that:

* Records sessions
* Uploads sessions
* Replays sessions

This milestone reduces the highest project risk.
