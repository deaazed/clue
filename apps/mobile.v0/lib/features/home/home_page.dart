import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import '../../config.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/spacing.dart';
import '../../widgets/memory_card.dart';
import 'save_memory_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Memory> _memories = [];
  LatLng? _userPosition;
  final _mapController = MapController();
  late final Future<PmTilesVectorTileProvider> _tileProviderFuture;
  // Zoom threshold: switch to OSM raster above this for indoor room detail.
  static const _osmZoomThreshold = 14.0;
  bool _useOsmRaster = false;

  @override
  void initState() {
    super.initState();
    _tileProviderFuture = PmTilesVectorTileProvider.fromSource(kTilesUrl);
    _load();
    _locateUser();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) setState(() => _memories = all);
  }

  Future<void> _locateUser() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        _setPosition(LatLng(last.latitude, last.longitude));
      }
      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (mounted) _setPosition(LatLng(fresh.latitude, fresh.longitude));
    } catch (_) {}
  }

  void _setPosition(LatLng ll) {
    setState(() => _userPosition = ll);
    try {
      _mapController.move(ll, 16);
    } catch (_) {}
  }

  Future<void> _showSave() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SaveMemorySheet(),
    );
    _load();
  }

  void _onPinTap(Memory m) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => _PinSheet(
        memory: m,
        userPosition: _userPosition,
        onDetails: () {
          Navigator.pop(context);
          context.push('/memory', extra: m);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartoUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    final pinned = _memories.where((m) => m.lat != null).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522),
              initialZoom: 5,
              onMapEvent: (event) {
                final zoom = event.camera.zoom;
                final wantsOsm = zoom >= _osmZoomThreshold;
                if (wantsOsm != _useOsmRaster) {
                  setState(() => _useOsmRaster = wantsOsm);
                }
              },
            ),
            children: [
              if (_useOsmRaster)
                // OSM Standard shows indoor room geometry at zoom 17-18.
                // Dark mode uses CARTO Dark Matter (no OSM dark variant).
                TileLayer(
                  urlTemplate: isDark ? cartoUrl : kOsmTilesUrl,
                  subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                  maxNativeZoom: 19,
                  userAgentPackageName: 'com.clue',
                )
              else
                FutureBuilder<PmTilesVectorTileProvider>(
                  future: _tileProviderFuture,
                  builder: (context, snap) {
                    if (snap.hasData) {
                      return VectorTileLayer(
                        tileProviders:
                            TileProviders({'protomaps': snap.data!}),
                        theme: isDark
                            ? ProtomapsThemes.darkV4()
                            : ProtomapsThemes.lightV4(),
                        // Protomaps planet build tops out at zoom 15.
                        // VectorTileLayer overzooms above this, so the map
                        // keeps rendering without requesting non-existent tiles.
                        maximumZoom: 15,
                      );
                    }
                    return TileLayer(
                      urlTemplate: cartoUrl,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.clue',
                    );
                  },
                ),
              MarkerLayer(
                markers: [
                  ...pinned.map(
                    (m) => Marker(
                      point: LatLng(m.lat!, m.lng!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _onPinTap(m),
                        child: _Pin(iconType: m.iconType),
                      ),
                    ),
                  ),
                  if (_userPosition != null)
                    Marker(
                      point: _userPosition!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: cs.primary.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Floating search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm + 4,
                AppSpacing.md,
                0,
              ),
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Material(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: cs.onSurfaceVariant, size: 20),
                        const SizedBox(width: AppSpacing.sm + 4),
                        Expanded(
                          child: Text(
                            'Search memories…',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_memories.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_memories.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'locate',
            backgroundColor: Colors.white,
            foregroundColor: cs.primary,
            elevation: 2,
            onPressed: _userPosition != null
                ? () => _mapController.move(_userPosition!, 16)
                : _locateUser,
            child: Icon(
              _userPosition != null
                  ? Icons.my_location
                  : Icons.location_searching,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          // Dark ink rounded-square FAB matching the prototype
          SizedBox(
            width: 58,
            height: 58,
            child: FloatingActionButton(
              heroTag: 'save',
              onPressed: _showSave,
              backgroundColor: const Color(0xFF1A1714),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.iconType});
  final String iconType;

  @override
  Widget build(BuildContext context) {
    final color = memoryColor(iconType);
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Icon(memoryIcon(iconType), color: Colors.white, size: 20),
    );
  }
}

class _PinSheet extends StatelessWidget {
  const _PinSheet({
    required this.memory,
    required this.userPosition,
    required this.onDetails,
  });

  final Memory memory;
  final LatLng? userPosition;
  final VoidCallback onDetails;

  double? get _dist {
    if (userPosition == null) return null;
    return Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      memory.lat!,
      memory.lng!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(memory.iconType);
    final dist = _dist;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.iconRadius),
                ),
                child: Icon(memoryIcon(memory.iconType),
                    color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.label,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (dist != null)
                      Text(
                        _fmtDist(dist),
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (memory.note != null) ...[
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              memory.note!,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDist(double m) => m < 1000
      ? '${m.toStringAsFixed(0)} m away'
      : '${(m / 1000).toStringAsFixed(1)} km away';
}
