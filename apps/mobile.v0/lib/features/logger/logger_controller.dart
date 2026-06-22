import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../models/session.dart';
import '../../services/session_repository.dart';
import '../../services/foreground_task.dart';

enum RecordingState { idle, recording, saving }

class LoggerController extends ChangeNotifier {
  LoggerController() {
    _initForegroundTask();
  }

  RecordingState state = RecordingState.idle;

  Vec3? lastAccel;
  Vec3? lastGyro;
  Vec3? lastMag;
  List<BleDevice> lastBle = [];
  bool bleAvailable = false;

  int _startMs = 0;
  int _elapsedMs = 0;
  int _notifTick = 0;
  int get elapsedMs => _elapsedMs;

  int get accelCount => _accel.length;
  int get gyroCount => _gyro.length;
  int get magCount => _mag.length;

  final List<AccelSample> _accel = [];
  final List<GyroSample> _gyro = [];
  final List<MagSample> _mag = [];
  final List<BleSample> _ble = [];

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<List<ScanResult>>? _bleSub;
  Timer? _uiTimer;
  Timer? _bleScanTimer;

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'clue_sl_recording',
        channelName: 'Clue SL',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
      ),
    );
  }

  Future<void> start() async {
    if (state != RecordingState.idle) return;

    await _requestPermissions();

    _startMs = DateTime.now().millisecondsSinceEpoch;
    _accel.clear();
    _gyro.clear();
    _mag.clear();
    _ble.clear();
    lastAccel = null;
    lastGyro = null;
    lastMag = null;
    lastBle = [];
    _notifTick = 0;

    state = RecordingState.recording;
    notifyListeners();

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      lastAccel = Vec3(e.x, e.y, e.z);
      _accel.add(Sample(DateTime.now().millisecondsSinceEpoch, lastAccel!));
    });

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      lastGyro = Vec3(e.x, e.y, e.z);
      _gyro.add(Sample(DateTime.now().millisecondsSinceEpoch, lastGyro!));
    });

    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((e) {
      lastMag = Vec3(e.x, e.y, e.z);
      _mag.add(Sample(DateTime.now().millisecondsSinceEpoch, lastMag!));
    });

    await _initBle();

    await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Clue SL',
      notificationText: 'Recording — 00:00 elapsed',
      notificationButtons: [
        const NotificationButton(id: 'btn_stop', text: 'Stop'),
      ],
      callback: foregroundEntryPoint,
    );
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    // UI updates at 10 Hz — sensor data accumulates independently at 20 Hz
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedMs = DateTime.now().millisecondsSinceEpoch - _startMs;
      notifyListeners();
      // Update notification text once per second (every 10 ticks)
      if (++_notifTick >= 10) {
        _notifTick = 0;
        FlutterForegroundTask.updateService(
          notificationText: 'Recording — ${_fmtMs(_elapsedMs)} elapsed',
        );
      }
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();
  }

  void _onTaskData(Object data) {
    if (data == 'stop' && state == RecordingState.recording) {
      stop();
    }
  }

  String _fmtMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _initBle() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) return;

      _bleSub = FlutterBluePlus.scanResults.listen((results) {
        if (results.isEmpty) return;
        final ts = DateTime.now().millisecondsSinceEpoch;
        final devices = results
            .map((r) => BleDevice(
                  id: r.device.remoteId.str,
                  name: r.device.platformName.isEmpty
                      ? null
                      : r.device.platformName,
                  rssi: r.rssi,
                ))
            .toList();
        lastBle = devices;
        _ble.add(Sample(ts, List.unmodifiable(devices)));
      });

      await _doBleScan();
      // Repeat scan every 5 s (each scan lasts 4 s with 1 s gap)
      _bleScanTimer = Timer.periodic(const Duration(seconds: 5), (_) => _doBleScan());
      bleAvailable = true;
    } catch (_) {
      bleAvailable = false;
    }
  }

  Future<void> _doBleScan() async {
    if (FlutterBluePlus.isScanningNow) return;
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<Session?> stop() async {
    if (state != RecordingState.recording) return null;
    state = RecordingState.saving;
    notifyListeners();

    _uiTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _bleScanTimer?.cancel();
    _bleSub?.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    await FlutterForegroundTask.stopService();

    final session = Session(
      id: _startMs.toString(),
      startedAtMs: _startMs,
      accel: List.unmodifiable(_accel),
      gyro: List.unmodifiable(_gyro),
      mag: List.unmodifiable(_mag),
      ble: List.unmodifiable(_ble),
    );

    await SessionRepository.save(session);

    state = RecordingState.idle;
    _elapsedMs = 0;
    bleAvailable = false;
    notifyListeners();

    return session;
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _bleScanTimer?.cancel();
    _bleSub?.cancel();
    super.dispose();
  }
}
