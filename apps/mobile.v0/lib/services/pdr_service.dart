import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

// Mirrors the algorithm in crates/pdr/src/lib.rs.
// Used in-app until Rust FFI is wired up in a future phase.

const _peakThreshold  = 11.2;  // m/s² — smoothed magnitude triggers a step
const _valleyThreshold = 9.0;  // m/s² — must drop here before next peak
const _strideLen       = 0.75; // metres per step
const _earthR          = 6371000.0; // metres

class PdrService {
  double _lat = 0;
  double _lng = 0;
  double _headingRad = 0;
  int _stepCount = 0;
  bool _anchored = false;
  double _smoothedMag = 9.8; // start near resting gravity
  bool _inPeak = false;

  final List<LatLng> _path = [];

  // ── Public getters ────────────────────────────────────────────────────────

  List<LatLng> get path => List.unmodifiable(_path);
  int get stepCount => _stepCount;
  LatLng? get position =>
      _anchored ? LatLng(_lat, _lng) : null;

  // ── GPS anchor ────────────────────────────────────────────────────────────

  /// Anchor (or correct) the DR position to a known GPS fix.
  void setGpsAnchor(LatLng pos) {
    _lat = pos.latitude;
    _lng = pos.longitude;
    if (!_anchored) {
      // First anchor — seed the path start
      _path.add(pos);
    }
    _anchored = true;
  }

  // ── IMU updates ───────────────────────────────────────────────────────────

  /// Feed accelerometer axes in m/s². Returns `true` when a step fires.
  bool updateAccel(double ax, double ay, double az) {
    final mag = math.sqrt(ax * ax + ay * ay + az * az);
    _smoothedMag = 0.8 * _smoothedMag + 0.2 * mag;

    if (!_inPeak && _smoothedMag > _peakThreshold) {
      _inPeak = true;
      if (_anchored) {
        _stepCount++;
        final dNorth = _strideLen * math.cos(_headingRad);
        final dEast  = _strideLen * math.sin(_headingRad);
        _lat += (dNorth / _earthR) * (180 / math.pi);
        final cosLat = math.cos(_lat * math.pi / 180);
        _lng += (dEast / (_earthR * cosLat)) * (180 / math.pi);
        _path.add(LatLng(_lat, _lng));
        return true;
      }
    }

    if (_inPeak && _smoothedMag < _valleyThreshold) {
      _inPeak = false;
    }
    return false;
  }

  /// Feed gyroscope z-axis [gz] in rad/s and time delta [dtSeconds].
  void updateGyro(double gz, double dtSeconds) {
    _headingRad += gz * dtSeconds;
  }

  /// Update absolute heading from magnetometer horizontal components.
  void updateMag(double mx, double my) {
    _headingRad = math.atan2(mx, my);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void reset() {
    _lat = 0; _lng = 0; _headingRad = 0; _stepCount = 0;
    _anchored = false; _smoothedMag = 9.8; _inPeak = false;
    _path.clear();
  }
}
