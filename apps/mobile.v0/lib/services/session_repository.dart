import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/session.dart';

class SessionRepository {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/clue_sessions');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> save(Session session) async {
    final dir = await _dir();
    final file = File('${dir.path}/${session.id}.json');
    await file.writeAsString(session.encode());
  }

  static Future<void> delete(String id) async {
    final dir = await _dir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
  }

  static Future<List<Session>> loadAll() async {
    final dir = await _dir();
    final entities = await dir.list().toList();
    final sessions = <Session>[];
    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final content = await entity.readAsString();
        sessions.add(Session.fromJson(jsonDecode(content) as Map<String, dynamic>));
      } catch (_) {}
    }
    sessions.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return sessions;
  }
}
