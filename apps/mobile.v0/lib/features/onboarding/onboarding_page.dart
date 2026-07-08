import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_client.dart';
import '../../services/memory_repository.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';
import '../../main.dart';

const _steps = [
  (
    icon: Icons.storefront_outlined,
    title: 'Add a place',
    desc: 'Step inside a venue and name it. Clue marks where you are.',
  ),
  (
    icon: Icons.location_on_outlined,
    title: 'Drop a clue',
    desc: 'Walk to an item, tap "I\'m here", and leave a quick note.',
  ),
  (
    icon: Icons.bookmark_border,
    title: 'Never forget',
    desc: 'Your clues stay on the map so you always know where to find things.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _loading = false;
  bool _restoring = false;
  // Live stats from the backend for the hive banner; null while loading/offline
  int? _placeCount;
  int? _clueCount;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final places = await ApiClient.fetchPlaces();
      final memories = await ApiClient.fetchMemories();
      if (mounted) {
        setState(() {
          _placeCount = places.length;
          _clueCount = memories.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestPermissionsAndFinish() async {
    await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();

    // Write marker so we skip onboarding next time
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/clue_onboarded').create(recursive: true);
    } catch (_) {}
    kIsFirstLaunch = false;

    if (mounted) context.go('/home');
  }

  Future<void> _getStarted() async {
    setState(() => _loading = true);
    await _requestPermissionsAndFinish();
  }

  /// "Restore my clues" — pulls all places and memories back from the
  /// backend (the reinstall path), then continues like Get started.
  Future<void> _restore() async {
    setState(() => _restoring = true);

    final places = await PlaceRepository.restoreFromServer(force: true);
    final clues = await MemoryRepository.restoreFromServer(force: true);

    if (mounted && places == 0 && clues == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to restore yet — start dropping clues!'),
        ),
      );
    }

    await _requestPermissionsAndFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? ClueColors.inkSurface : ClueColors.paper;
    final cardBg = isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor = isDark ? const Color(0xFF3A342C) : const Color(0xFFEBE2D3);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;
    final mutedColor = isDark ? const Color(0xFF8A7F74) : const Color(0xFF7A7163);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
          child: Column(
            children: [
              // Logo + title
              Column(
                children: [
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                          color: Colors.black.withValues(alpha: 0.14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/logo-clue.png',
                        fit: BoxFit.contain,
                        color: isDark ? ClueColors.paper : null,
                        colorBlendMode: isDark ? BlendMode.srcIn : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'clue',
                    style: TextStyle(
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      letterSpacing: -0.6,
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Never lose your place again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 27,
                      height: 1.16,
                      letterSpacing: -0.4,
                      color: inkColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clue remembers where things are inside the buildings you visit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Feature cards
              ...(_steps.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4E6D5),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(s.icon,
                                size: 22, color: ClueColors.amber),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: inkColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.desc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))),

              const SizedBox(height: 22),

              // Hive community banner
              Container(
                decoration: BoxDecoration(
                  color: ClueColors.ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo-clue.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Color(0xFFE9E1D4),
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'Every clue you drop teaches the hive. '),
                            if (_clueCount != null && _placeCount != null &&
                                (_clueCount! > 0 || _placeCount! > 0)) ...[
                              TextSpan(
                                text:
                                    '$_clueCount clue${_clueCount == 1 ? '' : 's'} across $_placeCount place${_placeCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF3B778),
                                ),
                              ),
                              const TextSpan(text: ' mapped so far.'),
                            ] else
                              const TextSpan(
                                  text:
                                      'Help map new places as you go.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // Get started button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _getStarted,
                  style: FilledButton.styleFrom(
                    backgroundColor: ClueColors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    shadowColor: ClueColors.amber.withValues(alpha: 0.5),
                    elevation: 10,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Get started'),
                ),
              ),

              const SizedBox(height: 14),

              // Restore link — pulls existing data back after a reinstall
              _restoring
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: mutedColor),
                    )
                  : GestureDetector(
                      onTap: _loading ? null : _restore,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Text.rich(
                          TextSpan(
                            style:
                                TextStyle(fontSize: 13.5, color: mutedColor),
                            children: [
                              const TextSpan(text: 'Already used Clue? '),
                              TextSpan(
                                text: 'Restore my clues',
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
            ],
          ),
        ),
      ),
    );
  }
}
