import 'package:clue/components/navbar_component.dart';
import 'package:clue/services/router.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Clue App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, router) {
        return Scaffold(
          body: FutureBuilder(
            future: Permission.location.request(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data == PermissionStatus.granted) {
                return router!;
              } else {
                return const Center(
                  child: Text("Location permission is required to show the map."),
                );
              }
            },
          ),
          bottomNavigationBar: const NavbarComponent(),
        );
      },
    );
  }
}
