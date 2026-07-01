import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import '../../config.dart';
import '../../models/place.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'create_place_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Place> _places = [];
  LatLng? _userPosition;
  final _mapController = MapController();
  late final Future<PmTilesVectorTileProvider> _tileProviderFuture;
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
    final all = await PlaceRepository.loadAll();
    if (mounted) setState(() => _places = all);
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

  Future<void> _showAddPlace() async {
    final place = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreatePlaceSheet(),
    );
    if (place != null && mounted) {
      _load();
      context.push('/place', extra: place);
    }
  }

  void _onPlaceTap(Place p) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (_) => _PlaceSheet(
        place: p,
        onView: () {
          Navigator.pop(context);
          context.push('/place', extra: p);
        },
        onAddClue: () {
          Navigator.pop(context);
          context.push('/record', extra: p);
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
                  ..._places.map(
                    (p) => Marker(
                      point: LatLng(p.lat, p.lng),
                      width: 100,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _onPlaceTap(p),
                        child: _PlacePin(name: p.name),
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
                          color: ClueColors.userDot,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color:
                                  ClueColors.userDot.withValues(alpha: 0.35),
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
                            'Search clues…',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (_places.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_places.length}',
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
          SizedBox(
            width: 58,
            height: 58,
            child: FloatingActionButton(
              heroTag: 'add_place',
              onPressed: _showAddPlace,
              backgroundColor: ClueColors.ink,
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

class _PlacePin extends StatelessWidget {
  const _PlacePin({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ClueColors.ink,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
          child: const Icon(Icons.storefront, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 60),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: ClueColors.ink,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({
    required this.place,
    required this.onView,
    required this.onAddClue,
  });

  final Place place;
  final VoidCallback onView;
  final VoidCallback onAddClue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;
    final mutedColor = isDark
        ? const Color(0xFF8A7F74)
        : const Color(0xFF8A8172);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E6D5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.storefront, size: 22,
                    color: ClueColors.amber),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        fontFamily:
                            GoogleFonts.bricolageGrotesque().fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: inkColor,
                      ),
                    ),
                    Text(
                      'Tap to see clues or add a new one',
                      style: TextStyle(fontSize: 12.5, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onView,
                  child: const Text('View place'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddClue,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add clue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
