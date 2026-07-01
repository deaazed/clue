class Place {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final DateTime timestamp;

  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp_ms'] as int),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lng': lng,
        'timestamp_ms': timestamp.millisecondsSinceEpoch,
      };
}
