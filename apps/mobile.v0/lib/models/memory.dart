class Memory {
  final String id;
  final String label;
  final String iconType;
  final String? note;
  final double? lat;
  final double? lng;
  final List<String> bleDevices;
  final DateTime timestamp;

  const Memory({
    required this.id,
    required this.label,
    required this.iconType,
    this.note,
    this.lat,
    this.lng,
    this.bleDevices = const [],
    required this.timestamp,
  });

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
      };
}
