import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';

const apiKey = "bYT3LzSnPtEGqyGhC0iZ";
const styleUrl = "https://api.maptiler.com/maps/streets-v2-light/style.json";

class MapComponent extends StatelessWidget {
  const MapComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Map();
  }
}

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State createState() => MapState();
}

class MapState extends State<Map> {
  LatLng _currentLocation = const LatLng(0.0, 0.0);
  MapLibreMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    if (_mapController != null) {
      _mapController!.moveCamera(CameraUpdate.newLatLng(_currentLocation));

      _mapController!.addSymbol(SymbolOptions(
        geometry: _currentLocation,
        iconSize: 1.5, // Adjust the icon size
        textField: "Your Location", // Optional: Add a label
        textSize: 14.0,
        textOffset: const Offset(0, 1.5), // Adjust label position
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        styleString: "$styleUrl?key=$apiKey",
        myLocationEnabled: true,
        myLocationTrackingMode: MyLocationTrackingMode.tracking,
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
          zoom: 14.0,
        ),
        trackCameraPosition: true,
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}