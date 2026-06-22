# syntax=docker/dockerfile:1

# ── Build ──────────────────────────────────────────────────────────────────────
FROM rust:slim AS builder

WORKDIR /app

# OpenSSL headers needed by sqlx tls-native-tls on Linux
RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
COPY backend/ backend/

# Cache cargo registry and build artifacts across rebuilds (requires BuildKit)
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release -p backend \
    && cp target/release/backend /backend

# ── Runtime ────────────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -s /bin/false app

COPY --from=builder /backend /backend

USER app
EXPOSE 3000
ENV PORT=3000

ENTRYPOINT ["/backend"]
