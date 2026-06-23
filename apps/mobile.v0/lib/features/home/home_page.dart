import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
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

  @override
  void initState() {
    super.initState();
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
    try { _mapController.move(ll, 16); } catch (_) {}
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
    final pinned = _memories.where((m) => m.lat != null).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.clue',
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
                          border:
                              Border.all(color: Colors.white, width: 3),
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

          // Search bar overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => context.go('/search'),
                child: Material(
                  elevation: 3,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: cs.onSurfaceVariant, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Search memories…',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 15),
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
            onPressed: _userPosition != null
                ? () => _mapController.move(_userPosition!, 16)
                : _locateUser,
            child: Icon(
              _userPosition != null
                  ? Icons.my_location
                  : Icons.location_searching,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'save',
            onPressed: _showSave,
            icon: const Icon(Icons.add),
            label: const Text('Save Memory'),
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
      userPosition!.latitude, userPosition!.longitude,
      memory.lat!, memory.lng!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(memory.iconType);
    final dist = _dist;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(memoryIcon(memory.iconType),
                    color: color, size: 24),
              ),
              const SizedBox(width: 14),
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
            const SizedBox(height: 10),
            Text(
              memory.note!,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(
                        'https://maps.google.com/?q=${memory.lat},${memory.lng}');
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDist(double m) =>
      m < 1000 ? '${m.toStringAsFixed(0)} m away' : '${(m / 1000).toStringAsFixed(1)} km away';
}
