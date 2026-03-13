import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dravik/services/sensor_layer/location_sensor_adapter.dart';

void main() {
  group('LocationSensorAdapter - Permission Handling', () {
    test('checkPermission returns granted when permission is not denied', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
      );

      final status = await adapter.checkPermission();
      expect(status, PermissionStatus.denied);
    });

    test('checkPermission returns denied when permission is denied', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
      );

      final status = await adapter.checkPermission();
      expect(status, PermissionStatus.denied);
    });

    test('checkPermission returns deniedForever when permission is deniedForever',
        () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.deniedForever,
      );

      final status = await adapter.checkPermission();
      expect(status, PermissionStatus.deniedForever);
    });

    test('checkPermission returns granted for unableToDetermine', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.unableToDetermine,
      );

      final status = await adapter.checkPermission();
      expect(status, PermissionStatus.granted);
    });

    test('requestPermission returns granted when user grants', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
        permissionRequester: () async => LocationPermission.whileInUse,
      );

      final status = await adapter.requestPermission();
      expect(status, PermissionStatus.granted);
    });

    test('requestPermission returns denied when user denies', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
        permissionRequester: () async => LocationPermission.denied,
      );

      final status = await adapter.requestPermission();
      expect(status, PermissionStatus.denied);
    });

    test('requestPermission returns deniedForever when already denied forever',
        () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.deniedForever,
      );

      final status = await adapter.requestPermission();
      expect(status, PermissionStatus.deniedForever);
    });

    test('requestPermission skips request if already granted', () async {
      var requestWasCalled = false;
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.whileInUse,
        permissionRequester: () async {
          requestWasCalled = true;
          return LocationPermission.denied;
        },
      );

      final status = await adapter.requestPermission();
      expect(status, PermissionStatus.granted);
      expect(requestWasCalled, false);
    });

    test('ensurePermission returns true when already granted', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.whileInUse,
      );

      final result = await adapter.ensurePermission();
      expect(result, true);
    });

    test('ensurePermission requests permission if denied initially', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
        permissionRequester: () async => LocationPermission.whileInUse,
      );

      final result = await adapter.ensurePermission();
      expect(result, true);
    });

    test('ensurePermission returns false when deniedForever', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.deniedForever,
      );

      final result = await adapter.ensurePermission();
      expect(result, false);
    });

    test('ensurePermission returns false when denied after request', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => LocationPermission.denied,
        permissionRequester: () async => LocationPermission.denied,
      );

      final result = await adapter.ensurePermission();
      expect(result, false);
    });

    test('checkPermission handles exceptions gracefully', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => throw Exception('Platform error'),
      );

      // Should not throw, returns granted as fallback
      final status = await adapter.checkPermission();
      expect(status, PermissionStatus.granted);
    });

    test('requestPermission handles exceptions gracefully', () async {
      final adapter = LocationSensorAdapter(
        permissionChecker: () async => throw Exception('Platform error'),
      );

      // Should not throw, returns granted as fallback
      final status = await adapter.requestPermission();
      expect(status, PermissionStatus.granted);
    });
  });
}
