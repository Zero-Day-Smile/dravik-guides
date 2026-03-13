import 'mission_state.dart';

abstract class MissionEvent {
  const MissionEvent({required this.occurredAt});

  final DateTime occurredAt;
}

class StartMission extends MissionEvent {
  const StartMission({
    required super.occurredAt,
    this.tripId,
    this.routeId,
    this.routeName,
    this.target,
  });

  final String? tripId;
  final String? routeId;
  final String? routeName;
  final MissionCoordinates? target;
}

class StopMission extends MissionEvent {
  const StopMission({required super.occurredAt});
}

class TickMission extends MissionEvent {
  const TickMission({required super.occurredAt});
}

class MissionFixAcquired extends MissionEvent {
  const MissionFixAcquired({
    required super.occurredAt,
    required this.fix,
  });

  final MissionFix fix;
}

class MissionFixLost extends MissionEvent {
  const MissionFixLost({
    required super.occurredAt,
    this.reason,
  });

  final String? reason;
}

class RerouteRequested extends MissionEvent {
  const RerouteRequested({required super.occurredAt, this.reason});

  final String? reason;
}

class RerouteResolved extends MissionEvent {
  const RerouteResolved({required super.occurredAt});
}

class EmergencyTriggered extends MissionEvent {
  const EmergencyTriggered({
    required super.occurredAt,
    this.reason,
  });

  final String? reason;
}

class RecoveryRequested extends MissionEvent {
  const RecoveryRequested({required super.occurredAt});
}

class LocationPermissionDenied extends MissionEvent {
  const LocationPermissionDenied({required super.occurredAt});
}

class BatteryLevelReported extends MissionEvent {
  const BatteryLevelReported({
    required super.occurredAt,
    required this.batteryPercent,
  });

  final int batteryPercent;
}

class HeadingReported extends MissionEvent {
  const HeadingReported({
    required super.occurredAt,
    required this.headingDegrees,
    required this.confidencePercent,
  });

  final double headingDegrees; // 0-360
  final double confidencePercent; // 0-100
}

class AltitudeReported extends MissionEvent {
  const AltitudeReported({
    required super.occurredAt,
    required this.altitudeMeters,
    this.accuracyMeters,
  });

  final double altitudeMeters; // meters above sea level
  final double? accuracyMeters; // vertical accuracy if available
}

class SpeedReported extends MissionEvent {
  const SpeedReported({
    required super.occurredAt,
    required this.speedMetersPerSecond,
  });

  final double speedMetersPerSecond;
}

class SlopeReported extends MissionEvent {
  const SlopeReported({
    required super.occurredAt,
    required this.slopePercent,
  });

  final double slopePercent;
}

class ConnectivityChanged extends MissionEvent {
  const ConnectivityChanged({
    required super.occurredAt,
    required this.isOffline,
  });

  final bool isOffline;
}
