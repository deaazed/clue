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
          path: '/search',
          builder: (context, state) => const SearchPage(),
        ),
        // Dev-only routes — not in nav; access via /dev/logger and /dev/sessions
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

class ClueApp extends StatelessWidget {
  const ClueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Clue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
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
    final index = location.startsWith('/timeline')
        ? 1
        : location.startsWith('/search')
            ? 2
            : 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/home');
          if (i == 1) context.go('/timeline');
          if (i == 2) context.go('/search');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
