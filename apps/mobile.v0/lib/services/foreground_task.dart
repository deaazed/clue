import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Runs in the foreground service isolate.
/// Must be top-level and annotated so the AOT compiler keeps it.
@pragma('vm:entry-point')
void foregroundEntryPoint() {
  FlutterForegroundTask.setTaskHandler(_RecordingTaskHandler());
}

class _RecordingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop') {
      FlutterForegroundTask.sendDataToMain('stop');
    }
  }
}
