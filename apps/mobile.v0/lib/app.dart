import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/home/home_page.dart';
import 'features/timeline/timeline_page.dart';
import 'features/search/search_page.dart';
import 'features/logger/logger_page.dart';
import 'features/sessions/sessions_page.dart';
import 'features/session_detail/session_detail_page.dart';
import 'features/memory_detail/memory_detail_page.dart';
import 'models/memory.dart';
import 'models/session.dart';
import 'theme/spacing.dart';

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/timeline',
          builder: (context, state) => const TimelinePage(),
        ),
        GoRoute(
          path: '/dev/logger',
          builder: (context, state) => const LoggerPage(),
        ),
        GoRoute(
          path: '/dev/sessions',
          builder: (context, state) => const SessionsPage(),
        ),
      ],
    ),
    // Outside shell — no bottom nav
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/memory',
      builder: (context, state) =>
          MemoryDetailPage(memory: state.extra as Memory),
    ),
    GoRoute(
      path: '/sessions/:id',
      builder: (context, state) =>
          SessionDetailPage(session: state.extra as Session),
    ),
  ],
);

ThemeData _buildTheme(Brightness brightness) {
  final cs = ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C3AED),
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: cs,
    useMaterial3: true,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.sheetRadius),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: cs.outlineVariant,
      dragHandleSize: const Size(32, 4),
    ),
    navigationBarTheme: const NavigationBarThemeData(height: 64),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
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
    final location = GoRouterState.of(context).uri.path;
    final index = location.startsWith('/timeline') ? 1 : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/timeline');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted_outlined),
            selectedIcon: Icon(Icons.format_list_bulleted),
            label: 'Memories',
          ),
        ],
      ),
    );
  }
}
