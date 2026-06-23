#!/usr/bin/env bash
# Run this script on the VPS to set up the PMTiles basemap.
#
# Uses `pmtiles extract` to download only the tiles for the target region via
# HTTP byte-range — the full planet file (~110 GB) is never downloaded locally.
# France extract is ~2-3 GB, well within the CX23 40 GB disk.
#
# Usage:
#   bash scripts/setup-tiles.sh              # France (default)
#   BBOX="-5.1,41.3,9.6,51.1" bash scripts/setup-tiles.sh   # explicit bbox
#   BBOX="2.2,48.7,2.5,49.0" bash scripts/setup-tiles.sh    # Paris only (~50 MB)
#
# Run `docker compose up -d` at least once first so the tiles_data volume exists.

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
PLANET_URL="${PLANET_URL:-https://build.protomaps.com/20260623.pmtiles}"
BBOX="${BBOX:--5.1,41.3,9.6,51.1}"   # France
# ─────────────────────────────────────────────────────────────────────────────

# Resolve Docker volume mount path
VOLUME_PATH=$(docker volume inspect clue_tiles_data \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['Mountpoint'])")
echo "Tiles volume: $VOLUME_PATH"

# Install pmtiles CLI if not present
if ! command -v pmtiles &>/dev/null; then
  echo "Installing pmtiles CLI..."
  PMTILES_VERSION=$(curl -s https://api.github.com/repos/protomaps/go-pmtiles/releases/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")
  curl -L -o /tmp/pmtiles.tar.gz \
    "https://github.com/protomaps/go-pmtiles/releases/download/${PMTILES_VERSION}/go-pmtiles_${PMTILES_VERSION#v}_Linux_x86_64.tar.gz"
  tar -xzf /tmp/pmtiles.tar.gz -C /usr/local/bin pmtiles
  rm /tmp/pmtiles.tar.gz
  echo "pmtiles $(pmtiles --version) installed"
fi

DEST="$VOLUME_PATH/tiles.pmtiles"
echo "Extracting bbox $BBOX from $PLANET_URL -> $DEST"
pmtiles extract "$PLANET_URL" "$DEST" --bbox="$BBOX"

echo "Done. Restart backend:"
echo "  docker compose restart backend"
