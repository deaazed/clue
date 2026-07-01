import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../config.dart';
import '../../models/place.dart';
import '../../theme/colors.dart';
import '../home/save_memory_sheet.dart';

class CluePinRecordingPage extends StatefulWidget {
  const CluePinRecordingPage({super.key, required this.place});
  final Place place;

  @override
  State<CluePinRecordingPage> createState() => _CluePinRecordingPageState();
}

class _CluePinRecordingPageState extends State<CluePinRecordingPage> {
  final _mapController = MapController();
  final List<LatLng> _path = [];
  LatLng? _current;
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  int _seconds = 0;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _startGps();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _seconds++); },
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startGps() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final ll = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _path.add(ll);
          _current = ll;
        });
        try {
          _mapController.move(ll, _mapController.camera.zoom);
        } catch (_) {}
      },
      onError: (_) {},
    );
  }

  Future<List<String>> _bleScan() async {
    final devices = <String>{};
    StreamSubscription? sub;
    try {
      sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) { devices.add(r.device.remoteId.str); }
      });
      await FlutterBluePlus.startScan(
          timeout: const Duration(milliseconds: 1500));
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (_) {
    } finally {
      await sub?.cancel();
      try { await FlutterBluePlus.stopScan(); } catch (_) {}
    }
    return devices.toList();
  }

  Future<void> _handleMark() async {
    if (_current == null) return;
    _positionSub?.cancel();
    _timer?.cancel();
    final endpoint = _current!;
    final pathSnap = List<LatLng>.unmodifiable(_path);
    setState(() => _marked = true);

    final ble = await _bleScan();
    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => SaveMemorySheet(
        place: widget.place,
        endpoint: endpoint,
        path: pathSnap,
        bleDevices: ble,
      ),
    );

    if (mounted) Navigator.of(context).pop(saved == true);
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor = isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.place.lat, widget.place.lng),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : kOsmTilesUrl,
                subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                maxNativeZoom: 19,
                userAgentPackageName: 'com.clue',
              ),
              if (_path.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _path,
                      color: ClueColors.amber,
                      strokeWidth: 4,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Place centre reference dot
                  Marker(
                    point: LatLng(widget.place.lat, widget.place.lng),
                    width: 12,
                    height: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ClueColors.amber.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: ClueColors.amber, width: 1.5),
                      ),
                    ),
                  ),
                  if (_current != null)
                    Marker(
                      point: _current!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ClueColors.userDot,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: ClueColors.userDot.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top bar: close | place name | timer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _TopBtn(
                    onTap: () => Navigator.of(context).pop(false),
                    child: const Icon(Icons.close, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8),
                        ],
                      ),
                      child: Text(
                        widget.place.name,
                        style: TextStyle(
                          fontFamily:
                              GoogleFonts.bricolageGrotesque().fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: ClueColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _TopBtn(
                    color: ClueColors.ink,
                    child: Text(
                      _timerLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: _marked
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Scanning nearby beacons…',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF8A7F74)
                                    : const Color(0xFF8A8172),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Walk to the item, then mark\nyour location when you arrive.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFF8A7F74)
                                    : const Color(0xFF8A8172),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed:
                                    _current != null ? _handleMark : null,
                                child:
                                    const Text("I'm here — mark location"),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBtn extends StatelessWidget {
  const _TopBtn({required this.child, this.onTap, this.color});
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: IconTheme(
            data: IconThemeData(
                color: color != null ? Colors.white : ClueColors.ink),
            child: child,
          ),
        ),
      ),
    );
  }
}
