import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/memory.dart';

class MemoryRepository {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/clue_memories');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> save(Memory memory) async {
    final dir = await _dir();
    final file = File('${dir.path}/${memory.id}.json');
    await file.writeAsString(jsonEncode(memory.toJson()));
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
  }
}
