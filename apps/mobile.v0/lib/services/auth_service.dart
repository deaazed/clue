import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config.dart';
import '../models/app_user.dart';

/// Optional sign-in (Google SSO or email+password). The whole app works
/// signed out — being signed in only attributes public uploads to you and
/// puts you on the community leaderboard.
class AuthService {
  static String? _token;
  static AppUser? _user;

  static String? get token => _token;
  static AppUser? get user => _user;
  static bool get isSignedIn => _token != null;
  static bool get googleConfigured => kGoogleServerClientId.isNotEmpty;

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/clue_auth.json');
  }

  /// Load the persisted session at startup. Never throws.
  static Future<void> init() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      _token = json['token'] as String?;
      final u = json['user'];
      if (u is Map<String, dynamic>) _user = AppUser.fromJson(u);
    } catch (_) {}
  }

  static Future<void> _persist() async {
    final f = await _file();
    await f.writeAsString(jsonEncode({
      'token': _token,
      'user': _user?.toJson(),
    }));
  }

  static Future<AppUser> _postAuth(
      String path, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('$kBackendUrl/api/auth/$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw switch (res.statusCode) {
        401 => Exception('Wrong email or password'),
        409 => Exception('An account with this email already exists'),
        400 => Exception(
            'Check your details — password needs at least 8 characters'),
        _ => Exception('Sign-in failed (HTTP ${res.statusCode})'),
      };
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    _token = json['token'] as String;
    _user = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    await _persist();
    return _user!;
  }

  static Future<AppUser> signInWithGoogle() async {
    final gsi = GoogleSignIn(
      scopes: const ['email'],
      serverClientId: googleConfigured ? kGoogleServerClientId : null,
    );
    final account = await gsi.signIn();
    if (account == null) throw Exception('Sign-in cancelled');
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
          'Google returned no ID token — check the OAuth client setup');
    }
    return _postAuth('google', {'id_token': idToken});
  }

  static Future<AppUser> register(
          String email, String password, String displayName) =>
      _postAuth('register', {
        'email': email,
        'password': password,
        'display_name': displayName,
      });

  static Future<AppUser> login(String email, String password) =>
      _postAuth('login', {'email': email, 'password': password});

  static Future<void> signOut() async {
    _token = null;
    _user = null;
    try {
      final f = await _file();
      if (await f.exists()) await f.delete();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }
}
