import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/session.dart';

class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(session.startedAtMs);
    final title =
        '${dt.year}-${_p(dt.month)}-${_p(dt.day)}  ${_p(dt.hour)}:${_p(dt.minute)}';
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Replay'),
            Tab(icon: Icon(Icons.show_chart), text: 'Charts'),
          ]),
        ),
        body: TabBarView(children: [
          _ReplayTab(session: session),
          _ChartsTab(session: session),
        ]),
      ),
    );
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}

// ─── Replay tab ───────────────────────────────────────────────────────────────

class _ReplayTab extends StatefulWidget {
  const _ReplayTab({required this.session});
  final Session session;

  @override
  State<_ReplayTab> createState() => _ReplayTabState();
}

class _ReplayTabState extends State<_ReplayTab> {
  double _posMs = 0;
  bool _playing = false;
  Timer? _timer;

  Session get s => widget.session;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (s.durationMs == 0) return;
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
    } else {
      if (_posMs >= s.durationMs) setState(() => _posMs = 0);
      setState(() => _playing = true);
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {
          _posMs = (_posMs + 100).clamp(0, s.durationMs.toDouble());
          if (_posMs >= s.durationMs) {
            _playing = false;
            _timer?.cancel();
          }
        });
      });
    }
  }

  Vec3? _vec3At(List<Sample<Vec3>> samples) {
    if (samples.isEmpty) return null;
    final target = s.startedAtMs + _posMs.round();
    if (samples.first.tsMs > target) return null;
    int lo = 0, hi = samples.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      samples[mid].tsMs <= target ? lo = mid : hi = mid - 1;
    }
    return samples[lo].value;
  }

  List<BleDevice> _bleAt() {
    final target = s.startedAtMs + _posMs.round();
    for (int i = s.ble.length - 1; i >= 0; i--) {
      if (s.ble[i].tsMs <= target) return s.ble[i].value;
    }
    return [];
  }

  String _fmt(double ms) {
    final totalS = ms ~/ 1000;
    final m = totalS ~/ 60;
    final sec = totalS % 60;
    final tenth = ms % 1000 ~/ 100;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.$tenth';
  }

  @override
  Widget build(BuildContext context) {
    if (s.durationMs == 0) {
      return const Center(
          child: Text('Empty session',
              style: TextStyle(color: Colors.black54)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(_fmt(_posMs),
              style: const TextStyle(
                  fontSize: 38,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w300)),
          Text('/ ${_fmt(s.durationMs.toDouble())}',
              style: const TextStyle(color: Colors.black38, fontSize: 13)),
          const SizedBox(height: 4),
          Slider(
            value: _posMs,
            min: 0,
            max: s.durationMs.toDouble(),
            onChanged: (v) {
              _timer?.cancel();
              setState(() {
                _posMs = v;
                _playing = false;
              });
            },
          ),
          IconButton(
            iconSize: 56,
            icon: Icon(_playing
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _togglePlay,
          ),
          const SizedBox(height: 8),
          _Vec3Card('Accelerometer (m/s²)', _vec3At(s.accel)),
          const SizedBox(height: 8),
          _Vec3Card('Gyroscope (rad/s)', _vec3At(s.gyro)),
          const SizedBox(height: 8),
          _Vec3Card('Magnetometer (µT)', _vec3At(s.mag)),
          const SizedBox(height: 8),
          _BleCard(_bleAt()),
        ],
      ),
    );
  }
}

// ─── Charts tab ───────────────────────────────────────────────────────────────

class _ChartsTab extends StatelessWidget {
  const _ChartsTab({required this.session});
  final Session session;

  List<Offset> _magnitudes(List<Sample<Vec3>> samples) {
    if (samples.isEmpty) return [];
    final startMs = session.startedAtMs;
    return samples.map((s) {
      final t = (s.tsMs - startMs) / 1000.0;
      final mag = sqrt(s.value.x * s.value.x +
          s.value.y * s.value.y +
          s.value.z * s.value.z);
      return Offset(t, mag);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SensorChart('Accelerometer — magnitude (m/s²)', Colors.blue,
            _magnitudes(session.accel)),
        const SizedBox(height: 8),
        _SensorChart('Gyroscope — magnitude (rad/s)', Colors.orange,
            _magnitudes(session.gyro)),
        const SizedBox(height: 8),
        _SensorChart('Magnetometer — magnitude (µT)', Colors.purple,
            _magnitudes(session.mag)),
      ],
    );
  }
}

class _SensorChart extends StatelessWidget {
  const _SensorChart(this.title, this.color, this.points);
  final String title;
  final Color color;
  final List<Offset> points; // x = seconds, y = magnitude

  @override
  Widget build(BuildContext context) {
    final hasData = points.length >= 2;
    final maxY = hasData ? points.map((p) => p.dy).reduce(max) : 0.0;
    final minY = hasData ? points.map((p) => p.dy).reduce(min) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            if (!hasData)
              const SizedBox(
                  height: 80,
                  child: Center(
                      child: Text('No data',
                          style: TextStyle(color: Colors.black26))))
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
                    height: 90,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(maxY.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black38)),
                        Text(minY.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black38)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SizedBox(
                      height: 90,
                      child: CustomPaint(
                          painter: _LinePainter(points, color)),
                    ),
                  ),
                ],
              ),
            if (hasData)
              Padding(
                padding: const EdgeInsets.only(left: 46, top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0 s',
                        style:
                            TextStyle(fontSize: 9, color: Colors.black38)),
                    Text('${points.last.dx.toStringAsFixed(1)} s',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.black38)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points, this.color);
  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxX = points.last.dx;
    double maxY = double.negativeInfinity, minY = double.infinity;
    for (final p in points) {
      if (p.dy > maxY) maxY = p.dy;
      if (p.dy < minY) minY = p.dy;
    }
    final rangeY = (maxY - minY).clamp(1e-9, double.infinity);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (points[i].dx / maxX) * size.width;
      final y = size.height * (1 - (points[i].dy - minY) / rangeY);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LinePainter old) => false;
}

// ─── Shared tile widgets ──────────────────────────────────────────────────────

class _Vec3Card extends StatelessWidget {
  const _Vec3Card(this.label, this.v);
  final String label;
  final Vec3? v;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              v == null
                  ? '—'
                  : 'X ${v!.x.toStringAsFixed(3).padLeft(9)}  '
                      'Y ${v!.y.toStringAsFixed(3).padLeft(9)}  '
                      'Z ${v!.z.toStringAsFixed(3).padLeft(9)}',
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _BleCard extends StatelessWidget {
  const _BleCard(this.devices);
  final List<BleDevice> devices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              devices.isEmpty
                  ? Icons.bluetooth_disabled
                  : Icons.bluetooth_searching,
              size: 18,
              color: devices.isEmpty ? Colors.black26 : Colors.indigo,
            ),
            const SizedBox(width: 8),
            Text(
              'BLE: ${devices.length} device${devices.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
