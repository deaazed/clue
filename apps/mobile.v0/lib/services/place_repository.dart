import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/place.dart';

class PlaceRepository {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/clue_places');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> save(Place place) async {
    final dir = await _dir();
    final file = File('${dir.path}/${place.id}.json');
    await file.writeAsString(jsonEncode(place.toJson()));
  }

  static Future<List<Place>> loadAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return [];
    final places = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) {
          try {
            return Place.fromJson(
                jsonDecode(f.readAsStringSync()) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<Place>()
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return places;
  }

  static Future<void> delete(String id) async {
    final dir = await _dir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) await file.delete();
  }
}
