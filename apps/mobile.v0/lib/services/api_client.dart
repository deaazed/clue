import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/memory.dart';
import '../models/place.dart';
import '../models/session.dart';
import 'auth_service.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);

  /// JSON headers, with the bearer token when signed in so public uploads
  /// are attributed to the user.
  static Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        if (AuthService.token != null)
          'Authorization': 'Bearer ${AuthService.token}',
      };

  static Future<void> uploadSession(Session session) async {
    final res = await http
        .post(
          Uri.parse('$kBackendUrl/api/sessions'),
          headers: {'Content-Type': 'application/json'},
          body: session.encode(),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  // ── Places ────────────────────────────────────────────────────────────────

  static Future<void> uploadPlace(Place place) async {
    await http
        .post(
          Uri.parse('$kBackendUrl/api/places'),
          headers: _jsonHeaders(),
          body: jsonEncode(place.toJson()),
        )
        .timeout(_timeout);
  }

  static Future<void> deletePlace(String id) async {
    await http
        .delete(Uri.parse('$kBackendUrl/api/places/$id'))
        .timeout(_timeout);
  }

  static Future<List<Place>> fetchPlaces() async {
    final res = await http
        .get(Uri.parse('$kBackendUrl/api/places'))
        .timeout(_timeout);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Memories ──────────────────────────────────────────────────────────────

  static Future<void> uploadMemory(Memory memory) async {
    await http
        .post(
          Uri.parse('$kBackendUrl/api/memories'),
          headers: _jsonHeaders(),
          body: jsonEncode(memory.toJson()),
        )
        .timeout(_timeout);
  }

  static Future<void> deleteMemory(String id) async {
    await http
        .delete(Uri.parse('$kBackendUrl/api/memories/$id'))
        .timeout(_timeout);
  }

  static Future<List<Memory>> fetchMemories() async {
    final res = await http
        .get(Uri.parse('$kBackendUrl/api/memories'))
        .timeout(_timeout);
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Memory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Community ─────────────────────────────────────────────────────────────

  /// {contributors: [{user_id, display_name, contributions}],
  ///  anonymous_contributions: int} — null on any failure.
  static Future<Map<String, dynamic>?> fetchCommunityTop() async {
    try {
      final res = await http
          .get(Uri.parse('$kBackendUrl/api/community/top'))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
