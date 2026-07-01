import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/home/home_page.dart';
import 'features/timeline/timeline_page.dart';
import 'features/search/search_page.dart';
import 'features/logger/logger_page.dart';
import 'features/sessions/sessions_page.dart';
import 'features/session_detail/session_detail_page.dart';
import 'features/memory_detail/memory_detail_page.dart';
import 'models/memory.dart';
import 'models/session.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomePage()),
        GoRoute(path: '/timeline', builder: (c, s) => const TimelinePage()),
        GoRoute(path: '/search', builder: (c, s) => const SearchPage()),
        GoRoute(path: '/places', builder: (c, s) => const _PlacesPlaceholder()),
        GoRoute(path: '/dev/logger', builder: (c, s) => const LoggerPage()),
        GoRoute(path: '/dev/sessions', builder: (c, s) => const SessionsPage()),
      ],
    ),
    GoRoute(
      path: '/memory',
      builder: (_, state) => MemoryDetailPage(memory: state.extra as Memory),
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
    final index = switch (path) {
      String p when p.startsWith('/timeline') => 1,
      String p when p.startsWith('/search') => 2,
      String p when p.startsWith('/places') => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/timeline');
            case 2:
              context.go('/search');
            case 3:
              context.go('/places');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Clues',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Places',
          ),
        ],
      ),
    );
  }
}

// Placeholder for the Places tab — full venue list comes in #24
class _PlacesPlaceholder extends StatelessWidget {
  const _PlacesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 52, color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Coming soon',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
