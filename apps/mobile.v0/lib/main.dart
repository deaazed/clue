import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // vector_map_tiles cancels in-flight tile requests during map movement.
  // Flutter surfaces these as errors via the image resource service, but
  // they are expected and harmless. Suppress them to keep logs clean.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('Cancelled')) return;
    defaultOnError?.call(details);
  };

  runApp(const ClueApp());
}
