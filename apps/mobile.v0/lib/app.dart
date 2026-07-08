import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/home_page.dart';
import 'features/timeline/timeline_page.dart';
import 'features/search/search_page.dart';
import 'features/places/places_page.dart';
import 'features/place_detail/place_detail_page.dart';
import 'features/clue_recording/clue_recording_page.dart';
import 'features/clue_recording/trace_shape_recording_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/logger/logger_page.dart';
import 'features/sessions/sessions_page.dart';
import 'features/session_detail/session_detail_page.dart';
import 'features/memory_detail/memory_detail_page.dart';
import 'main.dart' show kIsFirstLaunch;
import 'models/memory.dart';
import 'models/place.dart';
import 'models/session.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';

final _router = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    if (kIsFirstLaunch && state.uri.path != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (c, s) => const OnboardingPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomePage()),
        GoRoute(path: '/timeline', builder: (c, s) => const TimelinePage()),
        GoRoute(
          path: '/search',
          builder: (c, s) => SearchPage(
              autofocus: s.uri.queryParameters['focus'] == '1'),
        ),
        GoRoute(path: '/places', builder: (c, s) => const PlacesPage()),
        GoRoute(path: '/dev/logger', builder: (c, s) => const LoggerPage()),
        GoRoute(path: '/dev/sessions', builder: (c, s) => const SessionsPage()),
      ],
    ),
    GoRoute(
      path: '/memory',
      builder: (_, state) => MemoryDetailPage(memory: state.extra as Memory),
    ),
    GoRoute(
      path: '/place',
      builder: (_, state) => PlaceDetailPage(place: state.extra as Place),
    ),
    GoRoute(
      path: '/record',
      builder: (_, state) => CluePinRecordingPage(place: state.extra as Place),
    ),
    GoRoute(
      path: '/trace',
      builder: (_, state) =>
          TraceShapeRecordingPage(place: state.extra as Place),
    ),
    GoRoute(
      path: '/sessions/:id',
      builder: (_, state) => SessionDetailPage(session: state.extra as Session),
    ),
  ],
);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final cs = ColorScheme.fromSeed(
    seedColor: ClueColors.amber,
    brightness: brightness,
  ).copyWith(
    primary: ClueColors.amber,
    secondary: ClueColors.clay,
    surface: isDark ? ClueColors.inkSurface : ClueColors.paper,
    surfaceContainerLowest: isDark ? ClueColors.inkCard : ClueColors.paperDeep,
    surfaceContainerLow: isDark ? ClueColors.inkCard : ClueColors.paperDeep,
    surfaceContainer: isDark ? ClueColors.inkCard : ClueColors.paperDeep,
    onSurface: isDark ? ClueColors.paper : ClueColors.ink,
    outlineVariant: isDark ? const Color(0xFF3A342C) : ClueColors.border,
  );

  final baseTextTheme = GoogleFonts.hankenGroteskTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );

  // Display and headline styles use Bricolage Grotesque
  final displayStyle = GoogleFonts.bricolageGrotesque();
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.merge(displayStyle),
    displayMedium: baseTextTheme.displayMedium?.merge(displayStyle),
    displaySmall: baseTextTheme.displaySmall?.merge(displayStyle),
    headlineLarge: baseTextTheme.headlineLarge?.merge(displayStyle),
    headlineMedium: baseTextTheme.headlineMedium?.merge(displayStyle),
    headlineSmall: baseTextTheme.headlineSmall?.merge(displayStyle),
    titleLarge: baseTextTheme.titleLarge?.merge(displayStyle),
  );

  return ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    scaffoldBackgroundColor: isDark ? ClueColors.inkSurface : ClueColors.paper,
    textTheme: textTheme,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? ClueColors.inkCard : ClueColors.paperDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: isDark ? const Color(0xFF4A4238) : ClueColors.borderStrong,
      dragHandleSize: const Size(42, 5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: isDark
          ? ClueColors.inkCard.withValues(alpha: 0.92)
          : ClueColors.paperDeep.withValues(alpha: 0.92),
      indicatorColor: ClueColors.amber.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? ClueColors.amber
                : ClueColors.muted,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected)
                ? ClueColors.amber
                : ClueColors.muted,
          )),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? ClueColors.inkCard : ClueColors.paperDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: isDark ? const Color(0xFF3A342C) : ClueColors.border,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ClueColors.amber,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: GoogleFonts.hankenGrotesk(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF3A342C) : ClueColors.border,
    ),
  );
}

class ClueApp extends StatelessWidget {
  const ClueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Clue',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    // Tab order: Map(0) · Search(1) · Clues(2) · Places(3)
    final index = switch (path) {
      String p when p.startsWith('/search') => 1,
      String p when p.startsWith('/timeline') => 2,
      String p when p.startsWith('/places') => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(
        index: index,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/search');
            case 2: context.go('/timeline');
            case 3: context.go('/places');
          }
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF1E1A16).withValues(alpha: 0.95)
        : const Color(0xFFFBF7F0).withValues(alpha: 0.95);
    final border = isDark ? const Color(0xFF3A342C) : const Color(0xFFE7DECF);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(top: BorderSide(color: border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _NavItem(icon: Icons.map, label: 'Map', selected: index == 0, onTap: () => onTap(0)),
                  _NavItem(icon: Icons.search, label: 'Search', selected: index == 1, onTap: () => onTap(1)),
                  _NavItem(icon: Icons.bookmark, label: 'Clues', selected: index == 2, onTap: () => onTap(2)),
                  _NavItem(icon: Icons.business, label: 'Places', selected: index == 3, onTap: () => onTap(3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ClueColors.amber : const Color(0xFFADA394);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: GoogleFonts.hankenGrotesk().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
