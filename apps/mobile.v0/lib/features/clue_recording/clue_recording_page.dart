import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config.dart';
import '../../models/place.dart';
import '../../services/pdr_service.dart';
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
  final _pdr = PdrService();
  final List<LatLng> _gpsPath = [];
  LatLng? _current;
  double? _posAccuracy;

  // GPS
  StreamSubscription<Position>? _positionSub;
  // IMU
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime? _lastGyroTime;

  Timer? _timer;
  int _seconds = 0;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _startGps();
    _startImu();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _seconds++); },
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── Sensors ───────────────────────────────────────────────────────────────

  void _startGps() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final ll = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _gpsPath.add(ll);
          _current = ll;
          _posAccuracy = pos.accuracy;
        });
        // Anchor/correct PDR whenever GPS accuracy is reasonable
        if (pos.accuracy < 40) {
          _pdr.setGpsAnchor(ll);
        }
        try {
          _mapController.move(ll, _mapController.camera.zoom);
        } catch (_) {}
      },
      onError: (_) {},
    );
  }

  void _startImu() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50), // 20 Hz
    ).listen((e) {
      if (!mounted) return;
      if (_pdr.updateAccel(e.x, e.y, e.z)) {
        setState(() {}); // redraw PDR path on step
      }
    });

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      if (!mounted) return;
      final now = DateTime.now();
      final dt = _lastGyroTime != null
          ? now.difference(_lastGyroTime!).inMicroseconds / 1e6
          : 0.05;
      _lastGyroTime = now;
      _pdr.updateGyro(e.z, dt);
    });
  }

  // ── BLE scan at endpoint ──────────────────────────────────────────────────

  Future<List<String>> _bleScan() async {
    final devices = <String>{};
    StreamSubscription? sub;
    try {
      sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          devices.add(r.device.remoteId.str);
        }
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

  // ── Mark endpoint ─────────────────────────────────────────────────────────

  Future<void> _handleMark() async {
    if (_current == null) return;
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _timer?.cancel();
    final endpoint = _current!;
    final gpsSnap  = List<LatLng>.unmodifiable(_gpsPath);
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
        path: gpsSnap,
        bleDevices: ble,
      ),
    );

    if (mounted) Navigator.of(context).pop(saved == true);
  }

  // ── Timer label ───────────────────────────────────────────────────────────

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final pdrPath = _pdr.path;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
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
                subdomains:
                    isDark ? const ['a', 'b', 'c', 'd'] : const [],
                maxNativeZoom: 19,
                userAgentPackageName: 'com.clue',
              ),

              // GPS accuracy radius
              if (_current != null && _posAccuracy != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _current!,
                      radius: _posAccuracy!,
                      useRadiusInMeter: true,
                      color: ClueColors.userDot.withValues(alpha: 0.08),
                      borderColor:
                          ClueColors.userDot.withValues(alpha: 0.25),
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),

              // GPS breadcrumb trail (amber)
              if (_gpsPath.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _gpsPath,
                      color: ClueColors.amber,
                      strokeWidth: 4,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // PDR dead-reckoning trail (teal)
              if (pdrPath.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pdrPath,
                      color: const Color(0xFF26A69A), // teal
                      strokeWidth: 3,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.0,
                      pattern: StrokePattern.dashed(
                        segments: const [8, 6],
                      ),
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
                        border: Border.all(
                            color: ClueColors.amber, width: 1.5),
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
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: ClueColors.userDot
                                  .withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar ─────────────────────────────────────────────────────
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
                              color:
                                  Colors.black.withValues(alpha: 0.08),
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
                  // Timer + step counter
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopBtn(
                        color: ClueColors.ink,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _timerLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (_pdr.stepCount > 0)
                              Text(
                                '${_pdr.stepCount} steps',
                                style: const TextStyle(
                                  color: Color(0xFFB0A794),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Legend (shown when PDR path exists) ─────────────────────────
          if (pdrPath.length > 1)
            Positioned(
              top: 100,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(blurRadius: 6, color: Colors.black12)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendRow(
                        color: ClueColors.amber,
                        dashed: false,
                        label: 'GPS'),
                    const SizedBox(height: 4),
                    _LegendRow(
                        color: const Color(0xFF26A69A),
                        dashed: true,
                        label: 'Dead reckoning'),
                  ],
                ),
              ),
            ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
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
                              'Walk to the item, then mark your\nlocation when you arrive.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark
                                    ? const Color(0xFF8A7F74)
                                    : const Color(0xFF8A8172),
                              ),
                            ),
                            // Accuracy indicator
                            if (_posAccuracy != null) ...[
                              const SizedBox(height: 8),
                              _AccuracyChip(accuracy: _posAccuracy!),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _current != null
                                    ? _handleMark
                                    : null,
                                child: const Text(
                                    "I'm here — mark location"),
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

// ── Small reusable widgets ────────────────────────────────────────────────────

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

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.dashed, required this.label});
  final Color color;
  final bool dashed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(24, 3),
          painter: _LinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ClueColors.ink.withValues(alpha: 0.75))),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), p);
    } else {
      double x = 0;
      bool on = true;
      while (x < size.width) {
        final end = (x + (on ? 5 : 4)).clamp(0, size.width).toDouble();
        if (on) canvas.drawLine(Offset(x, 0), Offset(end, 0), p);
        x = end;
        on = !on;
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.color != color || old.dashed != dashed;
}

class _AccuracyChip extends StatelessWidget {
  const _AccuracyChip({required this.accuracy});
  final double accuracy;

  Color get _color {
    if (accuracy < 20) return const Color(0xFF34A853);
    if (accuracy < 60) return ClueColors.amber;
    return const Color(0xFFE53935);
  }

  String get _label {
    if (accuracy < 20) return '±${accuracy.round()} m — good';
    if (accuracy < 60) return '±${accuracy.round()} m — fair';
    return '±${accuracy.round()} m — poor (move outdoors)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed, size: 12, color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
