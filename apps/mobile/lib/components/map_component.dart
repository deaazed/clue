import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapComponent extends StatefulWidget {
  const MapComponent({super.key});

  @override
  State<MapComponent> createState() => _MapComponentState();
}

class _MapComponentState extends State<MapComponent> {
  final _mapController = MapController();
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final location = LatLng(position.latitude, position.longitude);

    if (!mounted) return;
    setState(() => _currentLocation = location);
    _mapController.move(location, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentLocation ?? const LatLng(0, 0);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.clue',
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
