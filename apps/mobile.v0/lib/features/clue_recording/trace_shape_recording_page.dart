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

enum _TraceMode { walk, draw }

enum _TraceState { active, preview, saving }

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

  _TraceMode _mode = _TraceMode.walk;
  _TraceState _state = _TraceState.active;

  // Walk mode
  final List<LatLng> _gpsPath = [];
  LatLng? _current;
  double? _posAccuracy;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime? _lastGyroTime;
  Timer? _timer;
  int _seconds = 0;

  // Draw mode
  final List<LatLng> _drawn = [];

  // Shared — the finalised polygon handed to preview / save
  List<LatLng> get _activePoints =>
      _mode == _TraceMode.walk ? _gpsPath : _drawn;

  @override
  void initState() {
    super.initState();
    _startWalkSensors(); // default is walk mode
  }

  @override
  void dispose() {
    _stopWalkSensors();
    _mapController.dispose();
    super.dispose();
  }

  // ── Walk-mode sensors ─────────────────────────────────────────────────────

  void _startWalkSensors() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen(
      (pos) {
        if (!mounted || _state != _TraceState.active) return;
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

  void _stopWalkSensors() {
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _timer?.cancel();
    _positionSub = null;
    _accelSub = null;
    _gyroSub = null;
    _timer = null;
  }

  // ── Mode switch ───────────────────────────────────────────────────────────

  void _switchMode(Set<_TraceMode> modes) {
    final next = modes.first;
    if (next == _mode || _state != _TraceState.active) return;

    final hasPoints = _activePoints.isNotEmpty;
    if (!hasPoints) {
      _doSwitchMode(next);
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch mode?'),
        content: const Text(
            'Switching mode will clear the points you\'ve recorded so far.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Switch')),
        ],
      ),
    ).then((ok) {
      if (ok == true && mounted) _doSwitchMode(next);
    });
  }

  void _doSwitchMode(_TraceMode next) {
    _stopWalkSensors();
    _gpsPath.clear();
    _drawn.clear();
    _pdr.reset();
    _current = null;
    _posAccuracy = null;
    _seconds = 0;
    _lastGyroTime = null;
    setState(() => _mode = next);
    if (next == _TraceMode.walk) _startWalkSensors();
  }

  // ── Draw-mode actions ─────────────────────────────────────────────────────

  void _addVertex(LatLng ll) {
    if (_mode != _TraceMode.draw || _state != _TraceState.active) return;
    setState(() => _drawn.add(ll));
  }

  void _undoVertex() {
    if (_drawn.isEmpty) return;
    setState(() => _drawn.removeLast());
  }

  // ── Finish recording ──────────────────────────────────────────────────────

  void _finishActive() {
    final pts = _activePoints;
    if (pts.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _TraceMode.walk
                ? 'Walk more of the perimeter before closing'
                : 'Place at least 3 points to define a shape',
          ),
        ),
      );
      return;
    }
    if (_mode == _TraceMode.walk) _stopWalkSensors();
    setState(() => _state = _TraceState.preview);
    try {
      final bounds = LatLngBounds.fromPoints(pts);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {}
  }

  void _redo() {
    _gpsPath.clear();
    _drawn.clear();
    _pdr.reset();
    _current = null;
    _posAccuracy = null;
    _seconds = 0;
    _lastGyroTime = null;
    setState(() => _state = _TraceState.active);
    if (_mode == _TraceMode.walk) _startWalkSensors();
  }

  Future<void> _saveShape() async {
    setState(() => _state = _TraceState.saving);
    final pts = List<LatLng>.unmodifiable(
        _mode == _TraceMode.walk ? _gpsPath : _drawn);

    // Move place pin to the centroid of the boundary
    final centLat =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final centLng =
        pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;

    final updated = widget.place.copyWith(
      boundary: pts,
      lat: centLat,
      lng: centLng,
    );
    await PlaceRepository.save(updated);
    if (mounted) Navigator.of(context).pop(updated);
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
    final isPreview = _state != _TraceState.active;
    final isSaving = _state == _TraceState.saving;
    final pdrPath = _pdr.path;
    final previewPoints =
        isPreview ? (_mode == _TraceMode.walk ? _gpsPath : _drawn) : <LatLng>[];

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.place.lat, widget.place.lng),
              initialZoom: 18.0,
              minZoom: 14,
              maxZoom: 20,
              onTap: _mode == _TraceMode.draw && !isPreview
                  ? (_, ll) => _addVertex(ll)
                  : null,
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

              // Walk: GPS accuracy circle
              if (_mode == _TraceMode.walk &&
                  _current != null &&
                  _posAccuracy != null &&
                  !isPreview)
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

              // Walk: GPS trail
              if (_mode == _TraceMode.walk && _gpsPath.length > 1)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _gpsPath,
                    color: ClueColors.amber,
                    strokeWidth: 4,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ]),

              // Walk: PDR trail
              if (_mode == _TraceMode.walk && !isPreview && pdrPath.length > 1)
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

              // Walk: user dot
              if (_mode == _TraceMode.walk && _current != null && !isPreview)
                MarkerLayer(markers: [
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
                ]),

              // Draw: polygon fill + edge as points accumulate
              if (_mode == _TraceMode.draw && _drawn.length >= 3 && !isPreview)
                PolygonLayer(polygons: [
                  Polygon(
                    points: _drawn,
                    color: ClueColors.amber.withValues(alpha: 0.12),
                    borderColor: ClueColors.amber.withValues(alpha: 0.5),
                    borderStrokeWidth: 1.5,
                  ),
                ]),

              // Draw: connecting lines
              if (_mode == _TraceMode.draw && _drawn.length > 1 && !isPreview)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _drawn,
                    color: ClueColors.amber,
                    strokeWidth: 2.5,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.0,
                  ),
                ]),

              // Draw: vertex dots
              if (_mode == _TraceMode.draw && _drawn.isNotEmpty && !isPreview)
                MarkerLayer(
                  markers: _drawn.asMap().entries.map((e) {
                    final isFirst = e.key == 0;
                    return Marker(
                      point: e.value,
                      width: isFirst ? 20 : 14,
                      height: isFirst ? 20 : 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFirst
                              ? ClueColors.ink
                              : ClueColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black26),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Preview: filled polygon (both modes)
              if (isPreview && previewPoints.length >= 3)
                PolygonLayer(polygons: [
                  Polygon(
                    points: previewPoints,
                    color: ClueColors.amber.withValues(alpha: 0.18),
                    borderColor: ClueColors.amber,
                    borderStrokeWidth: 2.5,
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
                  // Walk: timer / Draw: undo
                  if (!isPreview) ...[
                    const SizedBox(width: 10),
                    if (_mode == _TraceMode.walk)
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
                      )
                    else
                      _TopBtn(
                        onTap: _drawn.isNotEmpty ? _undoVertex : null,
                        child: Icon(
                          Icons.undo,
                          size: 20,
                          color: _drawn.isNotEmpty
                              ? ClueColors.ink
                              : ClueColors.ink.withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                          pointCount: previewPoints.length,
                          isSaving: isSaving,
                          onSave: _saveShape,
                          onRedo: _redo,
                          isDark: isDark,
                        )
                      : _ActivePanel(
                          mode: _mode,
                          walkAccuracy: _posAccuracy,
                          walkPointCount: _gpsPath.length,
                          drawPointCount: _drawn.length,
                          onModeChanged: _switchMode,
                          onFinish: _finishActive,
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

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.mode,
    required this.walkAccuracy,
    required this.walkPointCount,
    required this.drawPointCount,
    required this.onModeChanged,
    required this.onFinish,
    required this.isDark,
  });
  final _TraceMode mode;
  final double? walkAccuracy;
  final int walkPointCount;
  final int drawPointCount;
  final void Function(Set<_TraceMode>) onModeChanged;
  final VoidCallback onFinish;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final readyToFinish =
        mode == _TraceMode.walk ? walkPointCount >= 3 : drawPointCount >= 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode toggle
        SegmentedButton<_TraceMode>(
          segments: const [
            ButtonSegment(
              value: _TraceMode.walk,
              label: Text('Walk'),
              icon: Icon(Icons.directions_walk, size: 16),
            ),
            ButtonSegment(
              value: _TraceMode.draw,
              label: Text('Draw'),
              icon: Icon(Icons.edit, size: 16),
            ),
          ],
          selected: {mode},
          onSelectionChanged: onModeChanged,
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Instruction text
        Text(
          mode == _TraceMode.walk
              ? 'Walk around the perimeter.\nTap "Close shape" when you\'re back at the start.'
              : 'Tap on the map to place the corners of the shape.\nThe first point (dark) is the anchor.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.45, color: muted),
        ),

        // Walk: GPS accuracy chip
        if (mode == _TraceMode.walk && walkAccuracy != null) ...[
          const SizedBox(height: 8),
          _AccuracyChip(accuracy: walkAccuracy!),
        ],

        // Draw: point count
        if (mode == _TraceMode.draw && drawPointCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$drawPointCount point${drawPointCount == 1 ? '' : 's'} placed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClueColors.amber,
            ),
          ),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: readyToFinish ? onFinish : null,
            child: Text(
              mode == _TraceMode.walk ? 'Close shape' : 'Done drawing',
            ),
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
          '$pointCount points — does the shape look right?',
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

// ── Small widgets ─────────────────────────────────────────────────────────────

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
                color: _color),
          ),
        ],
      ),
    );
  }
}
