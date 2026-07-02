import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/memory.dart';
import 'api_client.dart';

class MemoryRepository {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/clue_memories');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _saveLocally(Memory memory) async {
    final dir = await _dir();
    final file = File('${dir.path}/${memory.id}.json');
    await file.writeAsString(jsonEncode(memory.toJson()));
  }

  static Future<void> save(Memory memory) async {
    await _saveLocally(memory);
    ApiClient.uploadMemory(memory).catchError((_) {});
  }

  static Future<List<Memory>> loadAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) =>
          b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.map((f) {
      try {
        return Memory.fromJson(
            jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Memory>().toList();
  }

  static Future<void> delete(String id) async {
    final dir = await _dir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
    ApiClient.deleteMemory(id).catchError((_) {});
  }

  static Future<void> deleteByPlaceId(String placeId) async {
    final all = await loadAll();
    for (final m in all.where((m) => m.placeId == placeId)) {
      await delete(m.id);
    }
  }

  /// Called once at startup — if local cache is empty, pull from backend.
  /// Silently no-ops on network failure.
  static Future<void> restoreFromServer() async {
    try {
      final existing = await loadAll();
      if (existing.isNotEmpty) return;
      final memories = await ApiClient.fetchMemories();
      for (final m in memories) {
        await _saveLocally(m);
      }
    } catch (_) {}
  }
}
