import 'dart:convert';

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  factory Vec3.fromJson(Map<String, dynamic> j) => Vec3(
        (j['x'] as num).toDouble(),
        (j['y'] as num).toDouble(),
        (j['z'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};
}

class BleDevice {
  final String id;
  final String? name;
  final int rssi;
  const BleDevice({required this.id, this.name, required this.rssi});

  factory BleDevice.fromJson(Map<String, dynamic> j) => BleDevice(
        id: j['id'] as String,
        name: j['name'] as String?,
        rssi: j['rssi'] as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'rssi': rssi};
}

class Sample<T> {
  final int tsMs;
  final T value;
  const Sample(this.tsMs, this.value);
}

typedef AccelSample = Sample<Vec3>;
typedef GyroSample = Sample<Vec3>;
typedef MagSample = Sample<Vec3>;
typedef BleSample = Sample<List<BleDevice>>;

class Session {
  final String id;
  final int startedAtMs;
  final List<AccelSample> accel;
  final List<GyroSample> gyro;
  final List<MagSample> mag;
  final List<BleSample> ble;

  const Session({
    required this.id,
    required this.startedAtMs,
    required this.accel,
    required this.gyro,
    required this.mag,
    required this.ble,
  });

  int get durationMs {
    int latest = 0;
    for (final s in accel) {
      if (s.tsMs > latest) latest = s.tsMs;
    }
    for (final s in gyro) {
      if (s.tsMs > latest) latest = s.tsMs;
    }
    for (final s in mag) {
      if (s.tsMs > latest) latest = s.tsMs;
    }
    for (final s in ble) {
      if (s.tsMs > latest) latest = s.tsMs;
    }
    return latest == 0 ? 0 : latest - startedAtMs;
  }

  int get sampleCount => accel.length + gyro.length + mag.length + ble.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at_ms': startedAtMs,
        'accel': accel
            .map((s) => {'ts_ms': s.tsMs, 'value': s.value.toJson()})
            .toList(),
        'gyro': gyro
            .map((s) => {'ts_ms': s.tsMs, 'value': s.value.toJson()})
            .toList(),
        'mag': mag
            .map((s) => {'ts_ms': s.tsMs, 'value': s.value.toJson()})
            .toList(),
        'ble': ble
            .map((s) => {
                  'ts_ms': s.tsMs,
                  'value': s.value.map((d) => d.toJson()).toList(),
                })
            .toList(),
      };

  factory Session.fromJson(Map<String, dynamic> j) {
    Vec3 v3(Map<String, dynamic> m) => Vec3.fromJson(m);
    return Session(
      id: j['id'] as String,
      startedAtMs: j['started_at_ms'] as int,
      accel: (j['accel'] as List)
          .map((e) => Sample<Vec3>(
              e['ts_ms'] as int, v3(e['value'] as Map<String, dynamic>)))
          .toList(),
      gyro: (j['gyro'] as List)
          .map((e) => Sample<Vec3>(
              e['ts_ms'] as int, v3(e['value'] as Map<String, dynamic>)))
          .toList(),
      mag: (j['mag'] as List)
          .map((e) => Sample<Vec3>(
              e['ts_ms'] as int, v3(e['value'] as Map<String, dynamic>)))
          .toList(),
      ble: (j['ble'] as List)
          .map((e) => Sample<List<BleDevice>>(
                e['ts_ms'] as int,
                (e['value'] as List)
                    .map((d) =>
                        BleDevice.fromJson(d as Map<String, dynamic>))
                    .toList(),
              ))
          .toList(),
    );
  }

  String encode() => jsonEncode(toJson());
}
