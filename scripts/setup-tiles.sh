#!/usr/bin/env bash
# Run this script on the VPS to download the PMTiles basemap.
# The file is served by the backend at /tiles/tiles.pmtiles.
#
# The docker-compose tiles_data volume must exist:
#   docker compose up -d          (creates the volume)
#   bash scripts/setup-tiles.sh   (populates it)
#
# Re-run to update the basemap. Download size ~1 GB for Europe.

set -euo pipefail

VOLUME_PATH=$(docker inspect clue_tiles_data_1 2>/dev/null \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['Mountpoint'])" 2>/dev/null \
  || docker volume inspect clue_tiles_data \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['Mountpoint'])")

echo "Tiles volume path: $VOLUME_PATH"

# Download region from Protomaps public build (CC0 licensed).
# Full planet: https://build.protomaps.com/20260623.pmtiles (~110 GB)
# Adjust the URL / region to match your use case.
PMTILES_URL="${PMTILES_URL:-https://build.protomaps.com/20260623.pmtiles}"
DEST="$VOLUME_PATH/tiles.pmtiles"

echo "Downloading $PMTILES_URL -> $DEST"
curl -L --progress-bar -o "$DEST" "$PMTILES_URL"
echo "Done. Restart backend to serve the new file:"
echo "  docker compose restart backend"
