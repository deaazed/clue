# AGENT.md

# Project Context

You are assisting with the development of an indoor mapping and item-finding platform.

Your role is to help implement software efficiently while minimizing complexity and technical debt.

The project is developed by a solo engineer as a side project.

Time and simplicity are critical constraints.

---

# Mission

Build a crowdsourced indoor localization system.

Users contribute:

* Motion trajectories
* Sensor recordings
* Indoor markers

The system learns indoor layouts and helps locate items and points of interest.

---

# Product Goals

Primary goal:

Allow users to find an item inside a building.

Examples:

* Products in supermarkets
* Gates in airports
* Shops in malls
* Rooms in offices

Target localization accuracy:

2–5 meters

Perfect positioning is not required.

---

# Core Philosophy

Always prioritize:

1. Data collection
2. Visualization
3. Reproducibility
4. Simplicity

Before:

* AI
* Machine learning
* Optimization

---

# Technical Stack

## Mobile

Flutter

## Shared Core

Rust

## Backend

Rust

Framework:

Axum

Database:

PostgreSQL

---

# Architecture

Raw Sensors

↓

Features

↓

Trajectories

↓

Indoor Graph

↓

Localization

↓

Item Discovery

All work should fit inside this pipeline.

---

# Repository Structure

mobile/
backend/
rust-core/
docs/
experiments/

---

# Development Priorities

Priority 1

Sensor collection.

Priority 2

Session replay.

Priority 3

Trajectory reconstruction.

Priority 4

Collaborative mapping.

Priority 5

Item tagging.

Priority 6

Localization.

Priority 7

Optimization.

---

# Current Milestones

## M1

Sensor Logger

Deliverables:

* Accelerometer
* Gyroscope
* Magnetometer
* Barometer
* BLE scanning
* Wi-Fi scanning

---

## M2

Replay System

Deliverables:

* Session storage
* Session browser
* Session playback

---

## M3

Dead Reckoning

Deliverables:

* Step detection
* Heading estimation
* Trajectory reconstruction

---

## M4

Visualization

Deliverables:

* 2D map rendering
* Marker rendering
* Session overlays

---

## M5

Collaborative Mapping

Deliverables:

* Trajectory clustering
* Walkable graph generation

---

## M6

Item Discovery

Deliverables:

* Marker creation
* Search
* Photos

---

## M7

Localization

Deliverables:

* Fingerprinting
* kNN matching
* Particle filters
* HMM smoothing

---

# Rules

Always prefer:

* Simple implementation
* Small commits
* Incremental delivery
* Testable components

Avoid:

* Premature optimization
* Overengineering
* Deep learning
* Distributed systems

unless explicitly requested.

---

# Data Policy

Always preserve raw data.

Never delete original observations.

Store raw recordings separately from processed outputs.

Derived data can be regenerated.

Raw data cannot.

---

# Coding Standards

## Rust

Requirements:

* Strong typing
* Small modules
* Unit tests
* Clear documentation

Avoid:

* Global mutable state
* Large files
* Complex abstractions

---

## Flutter

Requirements:

* Feature-based folders
* Stateless widgets when possible
* Clear separation of UI and business logic

---

# Visualization Requirement

Before proposing a new algorithm:

Verify that recorded data can be visualized.

If data cannot be visualized:

Build visualization first.

---

# Machine Learning Policy

Do not introduce machine learning until:

* Data collection exists
* Replay exists
* Visualization exists
* Baseline implementation exists

Preferred progression:

1. Rules
2. Statistics
3. kNN
4. HMM
5. Particle filters
6. Deep learning

---

# Success Metric

The project succeeds when:

A user enters a building.

The application estimates location.

The application guides the user to a tagged item.

Accuracy:

2–5 meters.

---

# Agent Behavior

When implementing features:

1. Propose the smallest working solution.
2. Explain tradeoffs.
3. Keep infrastructure inexpensive.
4. Assume a monthly budget under €20.
5. Prefer local-first development.
6. Prioritize data collection over model sophistication.
7. Maintain a clear path toward collaborative mapping.

When uncertain:

Choose the simplest solution that enables collecting more real-world data.
