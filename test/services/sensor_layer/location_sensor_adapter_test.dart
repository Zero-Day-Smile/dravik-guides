import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dravik/services/sensor_layer/location_sensor_adapter.dart';

void main() {
  test('getCurrentPosition delegates to injected fetcher', () async {
    final expected = Position(
      longitude: 77.3,
      latitude: 12.9,
      timestamp: DateTime(2026, 3, 11, 10),
      accuracy: 5,
      altitude: 100,
      altitudeAccuracy: 1,
      heading: 45,
      headingAccuracy: 3,
      speed: 1.2,
      speedAccuracy: 0.4,
    );

    final adapter = LocationSensorAdapter(
      currentPositionFetcher: (_) async => expected,
      positionStreamFactory: (_) => const Stream<Position>.empty(),
    );

    final current = await adapter.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    expect(current.latitude, expected.latitude);
    expect(current.longitude, expected.longitude);
  });

  test('startTracking emits positions and stopTracking cancels stream', () async {
    final controller = StreamController<Position>.broadcast();
    final seen = <Position>[];

    final adapter = LocationSensorAdapter(
      currentPositionFetcher: (_) async => Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime(2026, 3, 11, 10),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
      positionStreamFactory: (_) => controller.stream,
    );

    await adapter.startTracking(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      onPosition: (position) => seen.add(position),
    );

    controller.add(
      Position(
        longitude: 77.0,
        latitude: 12.0,
        timestamp: DateTime(2026, 3, 11, 10, 1),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(adapter.isTracking, isTrue);
    expect(seen.length, 1);

    await adapter.stopTracking();
    expect(adapter.isTracking, isFalse);

    controller.add(
      Position(
        longitude: 78.0,
        latitude: 13.0,
        timestamp: DateTime(2026, 3, 11, 10, 2),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(seen.length, 1);

    await controller.close();
  });
}
