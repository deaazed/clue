import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/logger/logger_page.dart';
import 'features/sessions/sessions_page.dart';

final _router = GoRouter(
  initialLocation: '/logger',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _Shell(child: child),
      routes: [
        GoRoute(
          path: '/logger',
          builder: (context, state) => const LoggerPage(),
        ),
        GoRoute(
          path: '/sessions',
          builder: (context, state) => const SessionsPage(),
        ),
      ],
    ),
  ],
);

class ClueApp extends StatelessWidget {
  const ClueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Clue SL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: location.startsWith('/sessions') ? 1 : 0,
        onDestinationSelected: (i) =>
            context.go(i == 0 ? '/logger' : '/sessions'),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Logger'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Sessions'),
        ],
      ),
    );
  }
}
