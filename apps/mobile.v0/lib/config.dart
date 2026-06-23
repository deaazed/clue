// Physical device: set to your machine's LAN IP (e.g. http://192.168.1.42:3000)
// Android emulator: use http://10.0.2.2:3000
// Deployed server: http://37.27.255.248 (via Caddy) or http://37.27.255.248:3000 (direct)
const String kBackendUrl = 'http://37.27.255.248:3000';

// PMTiles file served by the backend. Run scripts/setup-tiles.sh on the VPS first.
const String kTilesUrl = 'http://37.27.255.248:3000/tiles/tiles.pmtiles';
