import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../config.dart';
import '../../models/place.dart';
import '../../services/pdr_service.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';

enum _TraceState { recording, preview, saving }

class TraceShapeRecordingPage extends StatefulWidget {
  const TraceShapeRecordingPage({super.key, required this.place});
  final Place place;

  @override
  State<TraceShapeRecordingPage> createState() =>
      _TraceShapeRecordingPageState();
}

class _TraceShapeRecordingPageState extends State<TraceShapeRecordingPage> {
  final _mapController = MapController();
  final _pdr = PdrService();
  final List<LatLng> _gpsPath = [];
  LatLng? _current;
  double? _posAccuracy;
  _TraceState _state = _TraceState.recording;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime? _lastGyroTime;

  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startSensors();
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

  void _startSensors() {
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
        if (pos.accuracy < 40) _pdr.setGpsAnchor(ll);
        try {
          _mapController.move(ll, _mapController.camera.zoom);
        } catch (_) {}
      },
      onError: (_) {},
    );

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      if (!mounted) return;
      if (_pdr.updateAccel(e.x, e.y, e.z)) setState(() {});
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

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _seconds++);
      },
    );
  }

  void _stopSensors() {
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _timer?.cancel();
    _positionSub = null;
    _accelSub = null;
    _gyroSub = null;
    _timer = null;
  }

  void _closeShape() {
    if (_gpsPath.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Walk more of the perimeter before closing')),
      );
      return;
    }
    _stopSensors();
    setState(() => _state = _TraceState.preview);
    try {
      final bounds = LatLngBounds.fromPoints(_gpsPath);
      _mapController.fitCamera(
        CameraFit.bounds(
            bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {}
  }

  void _redo() {
    _pdr.reset();
    _gpsPath.clear();
    _current = null;
    _posAccuracy = null;
    _seconds = 0;
    _lastGyroTime = null;
    setState(() => _state = _TraceState.recording);
    _startSensors();
  }

  Future<void> _saveShape() async {
    setState(() => _state = _TraceState.saving);
    final updated =
        widget.place.copyWith(boundary: List.unmodifiable(_gpsPath));
    await PlaceRepository.save(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  String get _timerLabel {
    final m = _seconds ~/ 60;
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final isPreview = _state != _TraceState.recording;
    final isSaving = _state == _TraceState.saving;
    final pdrPath = _pdr.path;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
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

              // Accuracy circle (recording only)
              if (_current != null && _posAccuracy != null && !isPreview)
                CircleLayer(circles: [
                  CircleMarker(
                    point: _current!,
                    radius: _posAccuracy!,
                    useRadiusInMeter: true,
                    color: ClueColors.userDot.withValues(alpha: 0.08),
                    borderColor:
                        ClueColors.userDot.withValues(alpha: 0.25),
                    borderStrokeWidth: 1.0,
                  ),
                ]),

              // GPS breadcrumb trail
              if (_gpsPath.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _gpsPath,
                    color: ClueColors.amber,
                    strokeWidth: 4,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ]),

              // Preview: filled polygon
              if (isPreview && _gpsPath.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: _gpsPath,
                    color: ClueColors.amber.withValues(alpha: 0.18),
                    borderColor: ClueColors.amber,
                    borderStrokeWidth: 2.5,
                  ),
                ]),

              // PDR trail (recording only)
              if (!isPreview && pdrPath.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: pdrPath,
                    color: const Color(0xFF26A69A),
                    strokeWidth: 3,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.0,
                    pattern: StrokePattern.dashed(
                        segments: const [8, 6]),
                  ),
                ]),

              // User dot (recording only)
              if (_current != null && !isPreview)
                MarkerLayer(markers: [
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
                ]),
            ],
          ),

          // ── Top bar ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _TopBtn(
                    onTap: () => Navigator.of(context).pop(),
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
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        isPreview
                            ? 'Shape preview'
                            : 'Trace — ${widget.place.name}',
                        style: TextStyle(
                          fontFamily:
                              GoogleFonts.bricolageGrotesque().fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: ClueColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (!isPreview) ...[
                    const SizedBox(width: 10),
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
                  child: isPreview
                      ? _PreviewPanel(
                          pointCount: _gpsPath.length,
                          isSaving: isSaving,
                          onSave: _saveShape,
                          onRedo: _redo,
                          isDark: isDark,
                        )
                      : _RecordingPanel(
                          accuracy: _posAccuracy,
                          pointCount: _gpsPath.length,
                          onClose: _closeShape,
                          isDark: isDark,
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

// ── Panels ────────────────────────────────────────────────────────────────────

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.accuracy,
    required this.pointCount,
    required this.onClose,
    required this.isDark,
  });
  final double? accuracy;
  final int pointCount;
  final VoidCallback onClose;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Walk around the perimeter of the place.\nTap "Close shape" when you\'re back at the start.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.45, color: muted),
        ),
        if (accuracy != null) ...[
          const SizedBox(height: 8),
          _AccuracyChip(accuracy: accuracy!),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: pointCount >= 3 ? onClose : null,
            child: const Text('Close shape'),
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.pointCount,
    required this.isSaving,
    required this.onSave,
    required this.onRedo,
    required this.isDark,
  });
  final int pointCount;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onRedo;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pointCount GPS points recorded.\nDoes the shape look right?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.45, color: muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onRedo,
                child: const Text('Redo'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save shape'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

class _AccuracyChip extends StatelessWidget {
  const _AccuracyChip({required this.accuracy});
  final double accuracy;

  Color get _color {
    if (accuracy < 20) return const Color(0xFF34A853);
    if (accuracy < 60) return ClueColors.amber;
    return const Color(0xFFE53935);
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
            '±${accuracy.round()} m',
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
