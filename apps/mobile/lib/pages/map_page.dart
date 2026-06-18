import 'package:flutter/material.dart';
import 'package:clue/components/map_component.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MapComponent(),
    );
  }
}