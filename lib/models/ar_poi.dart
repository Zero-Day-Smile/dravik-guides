// AR Point of Interest Model for Trail Scanner
class ArPoi {
  final String id;
  final String name;
  final String type; // 'water', 'shelter', 'landmark', 'hazard', 'cultural'
  final double latitude;
  final double longitude;
  final double? elevation;
  final String description;
  final Map<String, dynamic>? metadata;

  ArPoi({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.elevation,
    required this.description,
    this.metadata,
  });

  factory ArPoi.fromMap(Map<String, dynamic> map) {
    return ArPoi(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      type: map['type'] ?? 'landmark',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      elevation: map['elevation'] != null
          ? (map['elevation'] as num).toDouble()
          : null,
      description: map['description'] ?? '',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'description': description,
      'metadata': metadata,
    };
  }

  String getIcon() {
    switch (type) {
      case 'water':
        return '💧';
      case 'shelter':
        return '🏕️';
      case 'landmark':
        return '🗿';
      case 'hazard':
        return '⚠️';
      case 'cultural':
        return '🏛️';
      default:
        return '📍';
    }
  }

  String getTypeLabel() {
    switch (type) {
      case 'water':
        return 'Water Source';
      case 'shelter':
        return 'Shelter';
      case 'landmark':
        return 'Landmark';
      case 'hazard':
        return 'Hazard';
      case 'cultural':
        return 'Cultural Site';
      default:
        return 'Point of Interest';
    }
  }
}
