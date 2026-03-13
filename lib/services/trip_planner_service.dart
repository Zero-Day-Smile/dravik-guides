import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dravik/models/trip.dart';

class TripPlannerService {
  static const String _boxName = 'trip_planner';
  final _uuid = const Uuid();

  Future<List<Trip>> getAllTrips() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('trips', defaultValue: []);

      if (data is List) {
        return data
            .map<Trip>((item) => Trip.fromJson(json.decode(item)))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Trip?> getTripById(String id) async {
    final trips = await getAllTrips();
    try {
      return trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<List<Trip>> getTripsByStatus(TripStatus status) async {
    final trips = await getAllTrips();
    return trips.where((t) => t.status == status).toList();
  }

  Future<List<Trip>> getUpcomingTrips() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    return trips
        .where((t) =>
            (t.status == TripStatus.upcoming ||
                t.status == TripStatus.planning) &&
            t.startDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  Future<Trip?> getActiveTrip() async {
    final trips = await getAllTrips();
    final now = DateTime.now();
    try {
      return trips.firstWhere((t) =>
          t.status == TripStatus.active ||
          (t.startDate.isBefore(now) && t.endDate.isAfter(now)));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveTrip(Trip trip) async {
    try {
      final box = await Hive.openBox(_boxName);
      final trips = await getAllTrips();

      final index = trips.indexWhere((t) => t.id == trip.id);
      if (index >= 0) {
        trips[index] = trip;
      } else {
        trips.add(trip);
      }

      final data = trips.map((t) => json.encode(t.toJson())).toList();
      await box.put('trips', data);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteTrip(String id) async {
    try {
      final box = await Hive.openBox(_boxName);
      final trips = await getAllTrips();
      trips.removeWhere((t) => t.id == id);

      final data = trips.map((t) => json.encode(t.toJson())).toList();
      await box.put('trips', data);
    } catch (e) {
      // Handle error
    }
  }

  Future<Trip> createTrip({
    required String name,
    required String description,
    required TripType type,
    required DateTime startDate,
    required DateTime endDate,
    required String countryCode,
    List<String>? participants,
  }) async {
    final trip = Trip(
      id: _uuid.v4(),
      name: name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      itinerary: [],
      participants: participants ?? [],
      countryCode: countryCode,
      estimatedDistance: 0,
      estimatedElevation: 0,
      gearChecklistIds: [],
      status: TripStatus.planning,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveTrip(trip);
    return trip;
  }

  Future<void> addDayToItinerary(String tripId, TripDay day) async {
    final trip = await getTripById(tripId);
    if (trip == null) return;

    final itinerary = List<TripDay>.from(trip.itinerary);
    itinerary.add(day);
    itinerary.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    final updated = Trip(
      id: trip.id,
      name: trip.name,
      description: trip.description,
      type: trip.type,
      startDate: trip.startDate,
      endDate: trip.endDate,
      itinerary: itinerary,
      participants: trip.participants,
      countryCode: trip.countryCode,
      estimatedDistance: trip.estimatedDistance + day.distanceKm,
      estimatedElevation: trip.estimatedElevation + day.elevationGainM,
      gearChecklistIds: trip.gearChecklistIds,
      status: trip.status,
      createdAt: trip.createdAt,
      updatedAt: DateTime.now(),
    );

    await saveTrip(updated);
  }

  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    final trip = await getTripById(tripId);
    if (trip == null) return;

    final updated = Trip(
      id: trip.id,
      name: trip.name,
      description: trip.description,
      type: trip.type,
      startDate: trip.startDate,
      endDate: trip.endDate,
      itinerary: trip.itinerary,
      participants: trip.participants,
      countryCode: trip.countryCode,
      estimatedDistance: trip.estimatedDistance,
      estimatedElevation: trip.estimatedElevation,
      gearChecklistIds: trip.gearChecklistIds,
      status: status,
      createdAt: trip.createdAt,
      updatedAt: DateTime.now(),
    );

    await saveTrip(updated);
  }

  Future<Trip> generateAIItinerary({
    required String destination,
    required TripType type,
    required DateTime startDate,
    required int durationDays,
    required double dailyDistanceKm,
    required String countryCode,
  }) async {
    // AI-powered trip generation
    // For now, create a basic template
    final endDate = startDate.add(Duration(days: durationDays));

    final trip = await createTrip(
      name: '$destination ${type.toString().split('.').last} Adventure',
      description: 'AI-generated $durationDays-day itinerary',
      type: type,
      startDate: startDate,
      endDate: endDate,
      countryCode: countryCode,
    );

    // Generate daily itinerary
    for (int i = 0; i < durationDays; i++) {
      final day = TripDay(
        dayNumber: i + 1,
        title: 'Day ${i + 1}: Trekking to Camp ${i + 1}',
        description: 'Trek through scenic trails with moderate elevation gain',
        distanceKm: dailyDistanceKm,
        elevationGainM: 500, // Average
        waypoints: [
          Waypoint(
            name: 'Start Point',
            latitude: 27.9881 + (i * 0.01),
            longitude: 86.9250 + (i * 0.01),
            elevation: 3000 + (i * 200),
            type: WaypointType.start,
          ),
          Waypoint(
            name: 'Camp ${i + 1}',
            latitude: 27.9881 + ((i + 1) * 0.01),
            longitude: 86.9250 + ((i + 1) * 0.01),
            elevation: 3500 + (i * 200),
            type: WaypointType.camp,
          ),
        ],
        packingTips: [
          'Extra water',
          'High-energy snacks',
          'Rain gear',
        ],
        weatherNote: 'Check forecast before departure',
      );

      await addDayToItinerary(trip.id, day);
    }

    return await getTripById(trip.id) ?? trip;
  }

  Future<void> linkGearChecklist(String tripId, String checklistId) async {
    final trip = await getTripById(tripId);
    if (trip == null) return;

    final checklists = List<String>.from(trip.gearChecklistIds);
    if (!checklists.contains(checklistId)) {
      checklists.add(checklistId);
    }

    final updated = Trip(
      id: trip.id,
      name: trip.name,
      description: trip.description,
      type: trip.type,
      startDate: trip.startDate,
      endDate: trip.endDate,
      itinerary: trip.itinerary,
      participants: trip.participants,
      countryCode: trip.countryCode,
      estimatedDistance: trip.estimatedDistance,
      estimatedElevation: trip.estimatedElevation,
      gearChecklistIds: checklists,
      status: trip.status,
      createdAt: trip.createdAt,
      updatedAt: DateTime.now(),
    );

    await saveTrip(updated);
  }
}
