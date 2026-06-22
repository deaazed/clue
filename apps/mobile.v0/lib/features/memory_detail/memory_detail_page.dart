import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/memory.dart';
import '../../widgets/memory_card.dart';

class MemoryDetailPage extends StatefulWidget {
  const MemoryDetailPage({super.key, required this.memory});
  final Memory memory;

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  double? _distanceMeters;

  @override
  void initState() {
    super.initState();
    if (widget.memory.lat != null) _fetchDistance();
  }

  Future<void> _fetchDistance() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.memory.lat!,
        widget.memory.lng!,
      );
      if (mounted) setState(() => _distanceMeters = d);
    } catch (_) {}
  }

  Future<void> _openInMaps() async {
    final m = widget.memory;
    final uri = Uri.parse(
        'https://maps.google.com/?q=${m.lat},${m.lng}&ll=${m.lat},${m.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.memory;
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(m.iconType);

    return Scaffold(
      appBar: AppBar(
        title: Text(m.label),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          if (m.lat != null)
            SizedBox(
              height: 280,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(m.lat!, m.lng!),
                  initialZoom: 17.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.clue',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(m.lat!, m.lng!),
                        width: 56,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  blurRadius: 8, color: Colors.black26)
                            ],
                          ),
                          child: Icon(memoryIcon(m.iconType),
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              height: 160,
              color: cs.surfaceContainerHighest,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off,
                        size: 40, color: cs.outlineVariant),
                    const SizedBox(height: 8),
                    Text('No location saved',
                        style:
                            TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distance (live)
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

                // Timestamp
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  iconColor: cs.onSurfaceVariant,
                  label: _fmtDate(m.timestamp),
                ),

                // BLE context
                if (m.bleDevices.isNotEmpty)
                  _InfoRow(
                    icon: Icons.bluetooth,
                    iconColor: color,
                    label:
                        '${m.bleDevices.length} Bluetooth beacon${m.bleDevices.length == 1 ? '' : 's'} nearby when saved',
                  ),

                // Note
                if (m.note != null)
                  _InfoRow(
                    icon: Icons.notes_outlined,
                    iconColor: cs.onSurfaceVariant,
                    label: m.note!,
                  ),

                if (m.lat != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.directions),
                      label: const Text('Open in Maps'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
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
