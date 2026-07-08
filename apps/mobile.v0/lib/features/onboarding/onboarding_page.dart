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
    desc: 'Name the venue, then walk or draw its shape on the map.',
  ),
  (
    icon: Icons.location_on_outlined,
    title: 'Drop clues inside',
    desc: 'Mark the spot where things are and leave a quick note.',
  ),
  (
    icon: Icons.lock_outline,
    title: 'Public or private',
    desc: 'Keep clues to yourself or share them with everyone.',
  ),
  (
    icon: Icons.emoji_events_outlined,
    title: 'Get credit',
    desc: 'Optional sign-in puts your clues on the hive leaderboard.',
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
      // Fits a single screen: compact header row, 2x2 feature grid, slim
      // banner. Spacers absorb extra height; the scroll view only ever
      // activates on screens too small to hold the minimum layout.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
                  child: Column(
                    children: [
                      // Logo + wordmark on one row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: cardBg,
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                  color:
                                      Colors.black.withValues(alpha: 0.12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/logo-clue.png',
                                fit: BoxFit.contain,
                                color: isDark ? ClueColors.paper : null,
                                colorBlendMode:
                                    isDark ? BlendMode.srcIn : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'clue',
                            style: TextStyle(
                              fontFamily: GoogleFonts.bricolageGrotesque()
                                  .fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              letterSpacing: -0.6,
                              color: inkColor,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      Text(
                        'Never lose your place again',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily:
                              GoogleFonts.bricolageGrotesque().fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 23,
                          height: 1.15,
                          letterSpacing: -0.4,
                          color: inkColor,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Clue remembers where things are inside the buildings you visit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: mutedColor,
                        ),
                      ),

                      const Spacer(),

                      // Feature grid — 2x2 compact cards
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _FeatureCard(
                                  step: _steps[0],
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  inkColor: inkColor,
                                  mutedColor: mutedColor)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _FeatureCard(
                                  step: _steps[1],
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  inkColor: inkColor,
                                  mutedColor: mutedColor)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                              child: _FeatureCard(
                                  step: _steps[2],
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  inkColor: inkColor,
                                  mutedColor: mutedColor)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _FeatureCard(
                                  step: _steps[3],
                                  cardBg: cardBg,
                                  borderColor: borderColor,
                                  inkColor: inkColor,
                                  mutedColor: mutedColor)),
                        ],
                      ),

                      const Spacer(),

                      // Hive community banner — slim
                      Container(
                        decoration: BoxDecoration(
                          color: ClueColors.ink,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/logo-clue.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: Color(0xFFE9E1D4),
                                  ),
                                  children: [
                                    const TextSpan(
                                        text:
                                            'Every clue you drop teaches the hive. '),
                                    if (_clueCount != null &&
                                        _placeCount != null &&
                                        (_clueCount! > 0 ||
                                            _placeCount! > 0)) ...[
                                      TextSpan(
                                        text:
                                            '$_clueCount clue${_clueCount == 1 ? '' : 's'} across $_placeCount place${_placeCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFF3B778),
                                        ),
                                      ),
                                      const TextSpan(
                                          text: ' mapped so far.'),
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

                      const SizedBox(height: 14),

                      // Get started button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _getStarted,
                          style: FilledButton.styleFrom(
                            backgroundColor: ClueColors.amber,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            shadowColor:
                                ClueColors.amber.withValues(alpha: 0.5),
                            elevation: 10,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Text('Get started'),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Restore link — pulls existing data back after a reinstall
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: _restoring
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
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
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: mutedColor),
                                        children: [
                                          const TextSpan(
                                              text:
                                                  'Already used Clue? '),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.step,
    required this.cardBg,
    required this.borderColor,
    required this.inkColor,
    required this.mutedColor,
  });

  final ({IconData icon, String title, String desc}) step;
  final Color cardBg;
  final Color borderColor;
  final Color inkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF4E6D5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(step.icon, size: 18, color: ClueColors.amber),
          ),
          const SizedBox(height: 8),
          Text(
            step.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: inkColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            step.desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
