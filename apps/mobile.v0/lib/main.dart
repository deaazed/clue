import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/memory_repository.dart';
import 'services/place_repository.dart';

bool kIsFirstLaunch = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  final dir = await getApplicationDocumentsDirectory();
  kIsFirstLaunch = !File('${dir.path}/clue_onboarded').existsSync();

  // Load any persisted sign-in session, then restore from backend if the
  // local cache is empty (e.g., after reinstall). Fast no-op when local
  // data exists; silently swallows network failures.
  await AuthService.init();
  await PlaceRepository.restoreFromServer();
  await MemoryRepository.restoreFromServer();

  runApp(const ClueApp());
}
