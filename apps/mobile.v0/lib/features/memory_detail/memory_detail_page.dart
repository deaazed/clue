import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../config.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/memory_card.dart';
import '../../widgets/visibility_toggle.dart';
import '../clue_recording/trace_shape_recording_page.dart';

class MemoryDetailPage extends StatefulWidget {
  const MemoryDetailPage({super.key, required this.memory});
  final Memory memory;

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  late Memory _memory;
  double? _distanceMeters;
  LatLng? _userPosition;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
    if (widget.memory.lat != null) _startPositionStream();
  }

  Future<void> _editClue() async {
    final updated = await showModalBottomSheet<Memory>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditClueSheet(memory: _memory),
    );
    if (updated != null && mounted) {
      setState(() => _memory = updated);
    }
  }

  Future<void> _traceShape() async {
    final m = _memory;
    if (m.lat == null) return;
    final updated = await context.push<Object?>(
      '/trace',
      extra: TraceShapeArgs(
        center: LatLng(m.lat!, m.lng!),
        title: m.label,
        onSave: (pts, _) async {
          final u = m.copyWith(boundary: pts);
          await MemoryRepository.save(u);
          return u;
        },
      ),
    );
    if (updated is Memory && mounted) {
      setState(() => _memory = updated);
    }
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
    final m = _memory;
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
    final m = _memory;
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(m.iconType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit clue',
            onPressed: _editClue,
          ),
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
                  child: GestureDetector(
                    onTap: _editClue,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.iconRadius),
                      ),
                      child:
                          Icon(memoryIcon(m.iconType), color: color, size: 26),
                    ),
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
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(
                      const LatLng(-85.05112878, -180),
                      const LatLng(85.05112878, 180),
                    ),
                  ),
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
                  // Traced boundary — place-type clues
                  if (m.boundary != null && m.boundary!.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: m.boundary!,
                          color: color.withValues(alpha: 0.08),
                          borderColor: color.withValues(alpha: 0.4),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
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

          // Trace shape CTA — clues whose type is 'place' can be traced
          if (m.iconType == 'place' && m.lat != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: GestureDetector(
                onTap: _traceShape,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: ClueColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ClueColors.amber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pentagon_outlined,
                          size: 20, color: ClueColors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.boundary != null && m.boundary!.length >= 3
                              ? 'Update this place\'s shape'
                              : 'Trace this place\'s shape',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB0672C),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: ClueColors.amber),
                    ],
                  ),
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

const _iconTypes = [
  'item', 'place', 'parking', 'gate', 'outlet', 'restroom', 'other',
];
const _iconLabels = [
  'Item', 'Place', 'Parking', 'Gate', 'Outlet', 'Restroom', 'Other',
];

/// Bottom sheet to change a clue's type and visibility.
class _EditClueSheet extends StatefulWidget {
  const _EditClueSheet({required this.memory});
  final Memory memory;

  @override
  State<_EditClueSheet> createState() => _EditClueSheetState();
}

class _EditClueSheetState extends State<_EditClueSheet> {
  late String _selectedIcon;
  late bool _isPublic;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.memory.iconType;
    _isPublic = widget.memory.isPublic;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.memory.copyWith(
      iconType: _selectedIcon,
      isPublic: _isPublic,
    );
    await MemoryRepository.save(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit clue',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.4,
              color: inkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.memory.label,
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 18),

          // Type picker — same chips as the save sheet
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconTypes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final type = _iconTypes[i];
                final selected = _selectedIcon == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 70,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF4E6D5) : cardBg,
                      border: Border.all(
                        color: selected ? ClueColors.amber : borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(memoryIcon(type),
                            size: 18,
                            color:
                                selected ? ClueColors.amber : mutedColor),
                        const SizedBox(height: 4),
                        Text(
                          _iconLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                selected ? ClueColors.amber : mutedColor,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          VisibilityToggle(
            isPublic: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
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
