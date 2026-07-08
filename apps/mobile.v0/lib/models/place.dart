import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final List<LatLng>? boundary;
  /// Private (false) items never leave the device.
  final bool isPublic;

  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.boundary,
    this.isPublic = true,
  });

  Place copyWith({
    String? name,
    double? lat,
    double? lng,
    List<LatLng>? boundary,
    bool? isPublic,
  }) =>
      Place(
        id: id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        timestamp: timestamp,
        boundary: boundary ?? this.boundary,
        isPublic: isPublic ?? this.isPublic,
      );

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            json['timestamp_ms'] as int),
        boundary: (json['boundary'] as List<dynamic>?)
            ?.map((e) => LatLng(
                  (e['lat'] as num).toDouble(),
                  (e['lng'] as num).toDouble(),
                ))
            .toList(),
        isPublic: json['is_public'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'timestamp_ms': timestamp.millisecondsSinceEpoch,
      'is_public': isPublic,
    };
    if (boundary != null && boundary!.length >= 3) {
      m['boundary'] = boundary!
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();
    }
    return m;
  }
}
