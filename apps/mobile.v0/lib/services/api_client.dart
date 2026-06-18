import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/session.dart';

class ApiClient {
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
}
