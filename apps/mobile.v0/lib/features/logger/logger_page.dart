import 'package:flutter/material.dart';
import '../../models/session.dart';
import 'logger_controller.dart';

class LoggerPage extends StatefulWidget {
  const LoggerPage({super.key});

  @override
  State<LoggerPage> createState() => _LoggerPageState();
}

class _LoggerPageState extends State<LoggerPage> {
  final _ctrl = LoggerController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onUpdate);
  }

  void _onUpdate() => setState(() {});

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clue - Sensor Logger')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusRow(ctrl: _ctrl),
              const SizedBox(height: 20),
              if (_ctrl.state == RecordingState.recording) ...[
                _Vec3Tile('Accelerometer (m/s²)', _ctrl.lastAccel),
                const SizedBox(height: 8),
                _Vec3Tile('Gyroscope (rad/s)', _ctrl.lastGyro),
                const SizedBox(height: 8),
                _Vec3Tile('Magnetometer (µT)', _ctrl.lastMag),
                const SizedBox(height: 8),
                _BleTile(ctrl: _ctrl),
                const SizedBox(height: 8),
                _SampleCountRow(ctrl: _ctrl),
              ],
              const Spacer(),
              _ActionButton(ctrl: _ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.ctrl});
  final LoggerController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (ctrl.state) {
      RecordingState.idle => const Text(
          'Ready to record',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      RecordingState.recording => Row(
          children: [
            _PulsingDot(),
            const SizedBox(width: 10),
            Text(
              'REC  ${_fmt(ctrl.elapsedMs)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      RecordingState.saving => const Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Saving session...', style: TextStyle(fontSize: 18)),
          ],
        ),
    };
  }

  String _fmt(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

class _Vec3Tile extends StatelessWidget {
  const _Vec3Tile(this.label, this.v);
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
                    fontSize: 12,
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

class _BleTile extends StatelessWidget {
  const _BleTile({required this.ctrl});
  final LoggerController ctrl;

  @override
  Widget build(BuildContext context) {
    final n = ctrl.lastBle.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              ctrl.bleAvailable ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 18,
              color: ctrl.bleAvailable ? Colors.indigo : Colors.black38,
            ),
            const SizedBox(width: 8),
            Text(
              ctrl.bleAvailable
                  ? 'BLE: $n device${n == 1 ? '' : 's'} nearby'
                  : 'BLE: unavailable',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.ctrl});
  final LoggerController ctrl;

  @override
  Widget build(BuildContext context) {
    return switch (ctrl.state) {
      RecordingState.idle => FilledButton.icon(
          onPressed: ctrl.start,
          icon: const Icon(Icons.fiber_manual_record),
          label: const Text('Start Recording'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      RecordingState.recording => FilledButton.icon(
          onPressed: () async {
            final session = await ctrl.stop();
            if (context.mounted && session != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Session saved — ${session.sampleCount} samples, ${(session.durationMs / 1000).toStringAsFixed(1)} s'),
              ));
            }
          },
          icon: const Icon(Icons.stop),
          label: const Text('Stop Recording'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      RecordingState.saving => const FilledButton(
          onPressed: null,
          child: SizedBox(
            height: 52,
            child: Center(child: Text('Saving...')),
          ),
        ),
    };
  }
}

class _SampleCountRow extends StatelessWidget {
  const _SampleCountRow({required this.ctrl});
  final LoggerController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.data_usage, size: 14, color: Colors.black38),
        const SizedBox(width: 4),
        Text(
          '${_n(ctrl.accelCount)} accel  ·  ${_n(ctrl.gyroCount)} gyro  ·  ${_n(ctrl.magCount)} mag',
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }

  String _n(int count) =>
      count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.4 + 0.6 * _anim.value),
        ),
      ),
    );
  }
}
