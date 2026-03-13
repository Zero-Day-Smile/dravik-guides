import 'dart:async';

import 'package:geolocator/geolocator.dart';

typedef PositionFetcher = Future<Position> Function(
  LocationSettings locationSettings,
);
typedef PositionStreamFactory = Stream<Position> Function(
  LocationSettings locationSettings,
);
typedef PermissionChecker = Future<LocationPermission> Function();
typedef PermissionRequester = Future<LocationPermission> Function();

/// Represents the outcome of a permission request.
/// [granted] — permission is granted
/// [denied] — permission was denied by user
/// [deniedForever] — permission was denied and user disabled future prompts
enum PermissionStatus {
  granted,
  denied,
  deniedForever,
}

class LocationSensorAdapter {
  LocationSensorAdapter({
    PositionFetcher? currentPositionFetcher,
    PositionStreamFactory? positionStreamFactory,
    PermissionChecker? permissionChecker,
    PermissionRequester? permissionRequester,
  })  : _currentPositionFetcher =
            currentPositionFetcher ??
                ((locationSettings) => Geolocator.getCurrentPosition(
                      locationSettings: locationSettings,
                    )),
        _positionStreamFactory =
            positionStreamFactory ??
                ((locationSettings) => Geolocator.getPositionStream(
                      locationSettings: locationSettings,
                    )),
        _permissionChecker =
            permissionChecker ?? (() => Geolocator.checkPermission()),
        _permissionRequester =
            permissionRequester ?? (() => Geolocator.requestPermission());

  final PositionFetcher _currentPositionFetcher;
  final PositionStreamFactory _positionStreamFactory;
  final PermissionChecker _permissionChecker;
  final PermissionRequester _permissionRequester;
  StreamSubscription<Position>? _subscription;

  bool get isTracking => _subscription != null;

  Future<Position> getCurrentPosition({
    required LocationSettings locationSettings,
  }) {
    return _currentPositionFetcher(locationSettings);
  }

  Future<void> startTracking({
    required LocationSettings locationSettings,
    required FutureOr<void> Function(Position position) onPosition,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    await stopTracking();

    _subscription = _positionStreamFactory(locationSettings).listen(
      (position) {
        final callbackResult = onPosition(position);
        if (callbackResult is Future<void>) {
          unawaited(callbackResult);
        }
      },
      onError: onError,
      onDone: onDone,
    );
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Checks the current location permission status.
  /// Returns [PermissionStatus.granted] if already granted.
  /// Returns [PermissionStatus.denied] if not yet requested or explicitly denied.
  /// Returns [PermissionStatus.deniedForever] if denied and user disabled future prompts.
  Future<PermissionStatus> checkPermission() async {
    try {
      final permission = await _permissionChecker();
      return _mapGeolocationPermission(permission);
    } catch (e) {
      // If permission check fails (e.g., on platforms without permission system),
      // assume granted to not block functionality.
      return PermissionStatus.granted;
    }
  }

  /// Requests location permission if not already granted.
  /// Returns [PermissionStatus.granted] if the user grants permission.
  /// Returns [PermissionStatus.denied] if the user denies permission.
  /// Returns [PermissionStatus.deniedForever] if user has disabled future prompts.
  Future<PermissionStatus> requestPermission() async {
    try {
      final currentStatus = await _permissionChecker();
      if (currentStatus != LocationPermission.denied) {
        return _mapGeolocationPermission(currentStatus);
      }

      final requestedStatus = await _permissionRequester();
      return _mapGeolocationPermission(requestedStatus);
    } catch (e) {
      // If request fails, assume granted as fallback.
      return PermissionStatus.granted;
    }
  }

  /// Ensures location permission is granted, requesting if necessary.
  /// Returns true if permission is available, false otherwise.
  Future<bool> ensurePermission() async {
    final status = await checkPermission();
    if (status == PermissionStatus.granted) {
      return true;
    }
    if (status == PermissionStatus.denied) {
      final requested = await requestPermission();
      return requested == PermissionStatus.granted;
    }
    // deniedForever — user must enable in settings
    return false;
  }

  static PermissionStatus _mapGeolocationPermission(
    LocationPermission geoPermission,
  ) {
    if (geoPermission == LocationPermission.denied) {
      return PermissionStatus.denied;
    }
    if (geoPermission == LocationPermission.deniedForever) {
      return PermissionStatus.deniedForever;
    }
    // All other cases (granted, whileInUse, unableToDetermine, etc.) treated as granted
    return PermissionStatus.granted;
  }
}
