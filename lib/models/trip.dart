// Trip Planning Models
class Trip {
  final String id;
  final String name;
  final String description;
  final TripType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> itinerary;
  final List<String> participants;
  final String countryCode;
  final double estimatedDistance;
  final double estimatedElevation;
  final List<String> gearChecklistIds;
  final TripStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double latitude; // For weather analysis
  final double longitude; // For weather analysis
  final String title; // Alias for name

  Trip({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.itinerary,
    required this.participants,
    required this.countryCode,
    required this.estimatedDistance,
    required this.estimatedElevation,
    required this.gearChecklistIds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.latitude = 0.0,
    this.longitude = 0.0,
  }) : title = name;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: TripType.values.firstWhere(
        (e) => e.toString() == 'TripType.${json['type']}',
        orElse: () => TripType.hiking,
      ),
      startDate:
          DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate:
          DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      itinerary: (json['itinerary'] as List?)
              ?.map((e) => TripDay.fromJson(e))
              .toList() ??
          [],
      participants: List<String>.from(json['participants'] ?? []),
      countryCode: json['countryCode'] ?? '',
      estimatedDistance: (json['estimatedDistance'] ?? 0).toDouble(),
      estimatedElevation: (json['estimatedElevation'] ?? 0).toDouble(),
      gearChecklistIds: List<String>.from(json['gearChecklistIds'] ?? []),
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${json['status']}',
        orElse: () => TripStatus.planning,
      ),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'itinerary': itinerary.map((e) => e.toJson()).toList(),
      'participants': participants,
      'countryCode': countryCode,
      'estimatedDistance': estimatedDistance,
      'estimatedElevation': estimatedElevation,
      'gearChecklistIds': gearChecklistIds,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

enum TripType { hiking, trekking, camping, mountaineering, touring, expedition }

enum TripStatus { planning, upcoming, active, completed, cancelled }

class TripDay {
  final int dayNumber;
  final String title;
  final String description;
  final double distanceKm;
  final double elevationGainM;
  final List<Waypoint> waypoints;
  final List<String> packingTips;
  final String weatherNote;

  TripDay({
    required this.dayNumber,
    required this.title,
    required this.description,
    required this.distanceKm,
    required this.elevationGainM,
    required this.waypoints,
    required this.packingTips,
    this.weatherNote = '',
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    return TripDay(
      dayNumber: json['dayNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      elevationGainM: (json['elevationGainM'] ?? 0).toDouble(),
      waypoints: (json['waypoints'] as List?)
              ?.map((e) => Waypoint.fromJson(e))
              .toList() ??
          [],
      packingTips: List<String>.from(json['packingTips'] ?? []),
      weatherNote: json['weatherNote'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'title': title,
      'description': description,
      'distanceKm': distanceKm,
      'elevationGainM': elevationGainM,
      'waypoints': waypoints.map((e) => e.toJson()).toList(),
      'packingTips': packingTips,
      'weatherNote': weatherNote,
    };
  }
}

class Waypoint {
  final String name;
  final double latitude;
  final double longitude;
  final double elevation;
  final WaypointType type;
  final String notes;

  Waypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.type,
    this.notes = '',
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      elevation: (json['elevation'] ?? 0).toDouble(),
      type: WaypointType.values.firstWhere(
        (e) => e.toString() == 'WaypointType.${json['type']}',
        orElse: () => WaypointType.poi,
      ),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
      'type': type.toString().split('.').last,
      'notes': notes,
    };
  }
}

enum WaypointType {
  start,
  end,
  camp,
  shelter,
  water,
  food,
  viewpoint,
  poi,
  emergency
}
