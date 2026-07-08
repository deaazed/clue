// Physical device: set to your machine's LAN IP (e.g. http://192.168.1.42:3000)
// Android emulator: use http://10.0.2.2:3000
// Deployed server: http://37.27.255.248 (via Caddy) or http://37.27.255.248:3000 (direct)
const String kBackendUrl = 'http://37.27.255.248:3000';

// PMTiles file served by the backend. Run scripts/setup-tiles.sh on the VPS first.
const String kTilesUrl = 'http://37.27.255.248:3000/tiles/tiles.pmtiles';

// OSM Standard raster — free, no API key, shows indoor room detail at zoom 17-18.
const String kOsmTilesUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

// Google Sign-In: the *Web application* OAuth client ID from Google Cloud
// Console (used as serverClientId so Android returns an ID token the backend
// can verify). Leave empty until configured — the Google button hides itself
// and email sign-in still works. See docs/GOOGLE_SIGNIN_SETUP.md.
const String kGoogleServerClientId = '';
