import 'package:clue/pages/home_page.dart';
import 'package:clue/pages/map_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MyHomePage(title: 'Home Page');
      },
    ),
    GoRoute(
      path: '/map',
      builder: (BuildContext context, GoRouterState state) {
        return const MapPage();
      },
    ),
  ],
);