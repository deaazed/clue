import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';

/// Optional sign-in: Google SSO (when configured) + email/password.
/// Signing in attributes your public clues to you — everything else in the
/// app works without an account.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<AppUser> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _submitEmail() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (_registering) {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Pick a display name');
        return;
      }
      _run(() => AuthService.register(email, password, name));
    } else {
      _run(() => AuthService.login(email, password));
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    await AuthService.signOut();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
        children: AuthService.isSignedIn
            ? _signedIn(inkColor, mutedColor, cardBg, borderColor)
            : _signedOut(inkColor, mutedColor, cardBg, borderColor, cs),
      ),
    );
  }

  List<Widget> _signedIn(
      Color inkColor, Color mutedColor, Color cardBg, Color borderColor) {
    final u = AuthService.user!;
    return [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: ClueColors.amber.withValues(alpha: 0.15),
              child: Text(
                u.displayName.isNotEmpty
                    ? u.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ClueColors.amber,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.displayName,
                    style: TextStyle(
                      fontFamily:
                          GoogleFonts.bricolageGrotesque().fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: inkColor,
                    ),
                  ),
                  Text(u.email,
                      style: TextStyle(fontSize: 12.5, color: mutedColor)),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Your public clues and places are credited to you on the community page. Private ones stay on this device.',
        style: TextStyle(fontSize: 12.5, height: 1.5, color: mutedColor),
      ),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: _busy ? null : _signOut,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE53935),
          side: const BorderSide(color: Color(0xFFE53935)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('Sign out'),
      ),
    ];
  }

  List<Widget> _signedOut(Color inkColor, Color mutedColor, Color cardBg,
      Color borderColor, ColorScheme cs) {
    return [
      Text(
        'Get credit for your clues',
        style: TextStyle(
          fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.4,
          color: inkColor,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Optional — Clue works fine without an account. Sign in so your public clues count towards the community leaderboard and stay yours.',
        style: TextStyle(fontSize: 13, height: 1.5, color: mutedColor),
      ),
      const SizedBox(height: 22),

      if (AuthService.googleConfigured) ...[
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                _busy ? null : () => _run(AuthService.signInWithGoogle),
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: inkColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: TextStyle(fontSize: 12, color: mutedColor)),
            ),
            Expanded(child: Divider(color: borderColor)),
          ],
        ),
        const SizedBox(height: 18),
      ],

      if (_registering)
        _field('DISPLAY NAME', _nameCtrl, cardBg, borderColor, inkColor,
            mutedColor,
            hint: 'How you appear on the leaderboard'),
      _field('EMAIL', _emailCtrl, cardBg, borderColor, inkColor, mutedColor,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress),
      _field(
          'PASSWORD', _passwordCtrl, cardBg, borderColor, inkColor, mutedColor,
          hint: _registering ? 'At least 8 characters' : '••••••••',
          obscure: true),

      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFFE53935))),
      ],
      const SizedBox(height: 18),

      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _busy ? null : _submitEmail,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_registering ? 'Create account' : 'Sign in'),
        ),
      ),
      const SizedBox(height: 14),
      Center(
        child: GestureDetector(
          onTap: _busy
              ? null
              : () => setState(() {
                    _registering = !_registering;
                    _error = null;
                  }),
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: mutedColor),
              children: [
                TextSpan(
                    text: _registering
                        ? 'Already have an account? '
                        : 'New here? '),
                TextSpan(
                  text: _registering ? 'Sign in' : 'Create an account',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: inkColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _field(String label, TextEditingController ctrl, Color cardBg,
      Color borderColor, Color inkColor, Color mutedColor,
      {String? hint, bool obscure = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: Color(0xFFB0A794),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              obscureText: obscure,
              keyboardType: keyboardType,
              autocorrect: false,
              style: TextStyle(
                  fontSize: 15,
                  color: inkColor,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration.collapsed(
                hintText: hint ?? '',
                hintStyle: TextStyle(
                    fontSize: 15,
                    color: mutedColor,
                    fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
