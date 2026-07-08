import 'package:latlong2/latlong.dart';

class Memory {
  final String id;
  final String label;
  final String iconType;
  final String? note;
  final double? lat;
  final double? lng;
  final List<String> bleDevices;
  final DateTime timestamp;
  final List<LatLng>? path;
  final String? placeId;
  /// Traced shape — only meaningful for 'place'-type clues.
  final List<LatLng>? boundary;
  /// Private (false) items never leave the device.
  final bool isPublic;

  const Memory({
    required this.id,
    required this.label,
    required this.iconType,
    this.note,
    this.lat,
    this.lng,
    this.bleDevices = const [],
    required this.timestamp,
    this.path,
    this.placeId,
    this.boundary,
    this.isPublic = true,
  });

  Memory copyWith({
    String? label,
    String? iconType,
    String? note,
    List<LatLng>? boundary,
    bool? isPublic,
  }) =>
      Memory(
        id: id,
        label: label ?? this.label,
        iconType: iconType ?? this.iconType,
        note: note ?? this.note,
        lat: lat,
        lng: lng,
        bleDevices: bleDevices,
        timestamp: timestamp,
        path: path,
        placeId: placeId,
        boundary: boundary ?? this.boundary,
        isPublic: isPublic ?? this.isPublic,
      );

  factory Memory.fromJson(Map<String, dynamic> json) => Memory(
        id: json['id'] as String,
        label: json['label'] as String,
        iconType: json['icon_type'] as String? ?? 'other',
        note: json['note'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        bleDevices: (json['ble_devices'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            json['timestamp_ms'] as int),
        path: (json['path'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return LatLng(
            (m['lat'] as num).toDouble(),
            (m['lng'] as num).toDouble(),
          );
        }).toList(),
        placeId: json['place_id'] as String?,
        boundary: (json['boundary'] as List<dynamic>?)?.map((e) {
          final m = e as Map<String, dynamic>;
          return LatLng(
            (m['lat'] as num).toDouble(),
            (m['lng'] as num).toDouble(),
          );
        }).toList(),
        isPublic: json['is_public'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'icon_type': iconType,
        if (note != null) 'note': note,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'ble_devices': bleDevices,
        'timestamp_ms': timestamp.millisecondsSinceEpoch,
        if (path != null && path!.length >= 2)
          'path': path!
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        if (placeId != null) 'place_id': placeId,
        if (boundary != null && boundary!.length >= 3)
          'boundary': boundary!
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
        'is_public': isPublic,
      };
}
