import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/colors.dart';

/// Full-screen map where the user drags to place a pin. Returns the selected
/// [LatLng] when they confirm with "Set here".
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initialPosition});
  final LatLng? initialPosition;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final _mapController = MapController();
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        if (mounted) {
          setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.of(context).pop(_mapController.camera.center);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cartoUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose location'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  widget.initialPosition ?? const LatLng(48.8566, 2.3522),
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                urlTemplate: cartoUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.clue',
              ),
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPosition!,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(blurRadius: 6, color: Colors.black26),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Center pin — icon tip points at map center
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: ClueColors.amber,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
            ),
          ),

          // Instruction label
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(blurRadius: 6, color: Colors.black12),
                    ],
                  ),
                  child: Text(
                    'Drag the map to position the pin',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface),
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
          if (_userPosition != null)
            FloatingActionButton.small(
              heroTag: 'locate_me',
              backgroundColor: cs.surface,
              foregroundColor: cs.primary,
              elevation: 2,
              onPressed: () => _mapController.move(_userPosition!, 16),
              child: const Icon(Icons.my_location),
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'confirm',
            onPressed: _confirm,
            backgroundColor: ClueColors.ink,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check),
            label: const Text('Set here'),
          ),
        ],
      ),
    );
  }
}
