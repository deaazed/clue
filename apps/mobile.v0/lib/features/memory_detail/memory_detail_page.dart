import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../config.dart';
import '../../models/memory.dart';
import '../../theme/spacing.dart';
import '../../widgets/memory_card.dart';

class MemoryDetailPage extends StatefulWidget {
  const MemoryDetailPage({super.key, required this.memory});
  final Memory memory;

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  double? _distanceMeters;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    if (widget.memory.lat != null) _startPositionStream();
  }

  void _startPositionStream() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final userLL = LatLng(pos.latitude, pos.longitude);
        final d = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          widget.memory.lat!,
          widget.memory.lng!,
        );
        setState(() {
          _userPosition = userLL;
          _distanceMeters = d;
        });
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _share() {
    final m = widget.memory;
    final typeLabel = switch (m.iconType) {
      'item' => 'Item',
      'place' => 'Place',
      'parking' => 'Parking',
      'gate' => 'Gate',
      'outlet' => 'Outlet',
      'restroom' => 'Restroom',
      _ => 'Other',
    };
    final lines = <String>[
      m.label,
      '$typeLabel · ${_fmtDate(m.timestamp)}',
    ];
    if (m.note != null) {
      lines.add('');
      lines.add(m.note!);
    }
    if (m.lat != null) {
      lines.add('');
      lines.add('https://maps.google.com/?q=${m.lat},${m.lng}');
    }
    SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(m.iconType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _share,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header: Hero icon + label + type
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'memory_icon_${m.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.iconRadius),
                    ),
                    child: Icon(memoryIcon(m.iconType), color: color, size: 26),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.label,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _typeLabel(m.iconType),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map — OSM raster at zoom 17 for indoor detail; polyline + live dot
          if (m.lat != null)
            SizedBox(
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(m.lat!, m.lng!),
                  initialZoom: 17.0,
                  minZoom: 3,
                  maxZoom: 20,
                ),
                children: [
                  TileLayer(
                    // OSM Standard tiles render indoor room geometry at zoom 17-18.
                    // Dark mode falls back to CARTO Dark Matter (no OSM dark variant).
                    urlTemplate: isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : kOsmTilesUrl,
                    subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                    maxNativeZoom: 19,
                    userAgentPackageName: 'com.clue',
                  ),
                  // Recorded path breadcrumbs
                  if (m.path != null && m.path!.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: m.path!,
                          color: color,
                          strokeWidth: 4,
                          borderColor: Colors.white,
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // Memory pin
                      Marker(
                        point: LatLng(m.lat!, m.lng!),
                        width: 56,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(blurRadius: 8, color: Colors.black26),
                            ],
                          ),
                          child: Icon(memoryIcon(m.iconType),
                              color: Colors.white, size: 22),
                        ),
                      ),
                      // Live user position dot
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
            )
          else
            Container(
              height: 120,
              color: cs.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off, size: 32, color: cs.outlineVariant),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No location saved',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Info rows
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_distanceMeters != null)
                  _InfoRow(
                    icon: Icons.near_me,
                    iconColor: cs.primary,
                    label: _fmtDistance(_distanceMeters!),
                  )
                else if (m.lat != null)
                  _InfoRow(
                    icon: Icons.near_me,
                    iconColor: cs.outlineVariant,
                    label: 'Getting distance…',
                  ),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  iconColor: cs.onSurfaceVariant,
                  label: _fmtDate(m.timestamp),
                ),
                if (m.path != null && m.path!.length > 1)
                  _InfoRow(
                    icon: Icons.route,
                    iconColor: color,
                    label: '${m.path!.length} path points recorded',
                  ),
                if (m.bleDevices.isNotEmpty)
                  _InfoRow(
                    icon: Icons.bluetooth,
                    iconColor: color,
                    label:
                        '${m.bleDevices.length} Bluetooth beacon${m.bleDevices.length == 1 ? '' : 's'} nearby when saved',
                  ),
                if (m.note != null)
                  _InfoRow(
                    icon: Icons.notes_outlined,
                    iconColor: cs.onSurfaceVariant,
                    label: m.note!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'item' => 'Item',
        'place' => 'Place',
        'parking' => 'Parking',
        'gate' => 'Gate',
        'outlet' => 'Outlet',
        'restroom' => 'Restroom',
        _ => 'Other',
      };

  String _fmtDistance(double m) {
    if (m < 1000) return '${m.toStringAsFixed(0)} m away';
    return '${(m / 1000).toStringAsFixed(1)} km away';
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm - 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
