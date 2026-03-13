enum MissionStatus {
  idle,
  acquiringFix,
  tracking,
  rerouting,
  degraded,
  emergencyMode,
}

enum SensingProfile {
  activeNavigation,
  patrol,
  lowPower,
}

enum MissionHealth {
  unknown,
  healthy,
  limited,
  critical,
}

enum DegradedReason {
  none,
  gpsTimeout,
  gpsUnavailable,
  permissionDenied,
  lowBattery,
  networkUnavailable,
  routeUnavailable,
  sensorFault,
  manualEmergency,
}

class MissionCoordinates {
  const MissionCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.altitudeMeters,
    this.headingDegrees,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? altitudeMeters;
  final double? headingDegrees;
}

class MissionFix {
  const MissionFix({
    required this.coordinates,
    required this.recordedAt,
    this.isMock = false,
    this.confidence = 0,
  });

  final MissionCoordinates coordinates;
  final DateTime recordedAt;
  final bool isMock;
  final double confidence;
}

class MissionContext {
  const MissionContext({
    this.activeTripId,
    this.routeId,
    this.routeName,
    this.lastFix,
    this.target,
    this.profile = SensingProfile.patrol,
    this.health = MissionHealth.unknown,
    this.degradedReason = DegradedReason.none,
    this.batteryPercent,
    this.isOffline = false,
    this.gpsConfidence = 0,
    this.headingConfidence = 0,
    this.altitudeMeters = 0,
    this.speedMetersPerSecond = 0,
    this.slopePercent = 0,
    this.lastError,
  });

  final String? activeTripId;
  final String? routeId;
  final String? routeName;
  final MissionFix? lastFix;
  final MissionCoordinates? target;
  final SensingProfile profile;
  final MissionHealth health;
  final DegradedReason degradedReason;
  final int? batteryPercent;
  final bool isOffline;
  final double gpsConfidence;
  final double headingConfidence;
  final double altitudeMeters;
  final double speedMetersPerSecond;
  final double slopePercent;
  final String? lastError;

  factory MissionContext.initial() => const MissionContext();

  MissionContext copyWith({
    String? activeTripId,
    bool clearActiveTripId = false,
    String? routeId,
    bool clearRouteId = false,
    String? routeName,
    bool clearRouteName = false,
    MissionFix? lastFix,
    bool clearLastFix = false,
    MissionCoordinates? target,
    bool clearTarget = false,
    SensingProfile? profile,
    MissionHealth? health,
    DegradedReason? degradedReason,
    int? batteryPercent,
    bool clearBatteryPercent = false,
    bool? isOffline,
    double? gpsConfidence,
    double? headingConfidence,
    double? altitudeMeters,
    double? speedMetersPerSecond,
    double? slopePercent,
    String? lastError,
    bool clearLastError = false,
  }) {
    return MissionContext(
      activeTripId: clearActiveTripId ? null : (activeTripId ?? this.activeTripId),
      routeId: clearRouteId ? null : (routeId ?? this.routeId),
      routeName: clearRouteName ? null : (routeName ?? this.routeName),
      lastFix: clearLastFix ? null : (lastFix ?? this.lastFix),
      target: clearTarget ? null : (target ?? this.target),
      profile: profile ?? this.profile,
      health: health ?? this.health,
      degradedReason: degradedReason ?? this.degradedReason,
      batteryPercent: clearBatteryPercent
          ? null
          : (batteryPercent ?? this.batteryPercent),
      isOffline: isOffline ?? this.isOffline,
      gpsConfidence: gpsConfidence ?? this.gpsConfidence,
      headingConfidence: headingConfidence ?? this.headingConfidence,
      altitudeMeters: altitudeMeters ?? this.altitudeMeters,
      speedMetersPerSecond: speedMetersPerSecond ?? this.speedMetersPerSecond,
      slopePercent: slopePercent ?? this.slopePercent,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}

class MissionRuntimeState {
  const MissionRuntimeState({
    required this.status,
    required this.context,
    required this.enteredAt,
  });

  final MissionStatus status;
  final MissionContext context;
  final DateTime enteredAt;

  factory MissionRuntimeState.initial({DateTime? now}) {
    return MissionRuntimeState(
      status: MissionStatus.idle,
      context: MissionContext.initial(),
      enteredAt: now ?? DateTime.now(),
    );
  }

  MissionRuntimeState copyWith({
    MissionStatus? status,
    MissionContext? context,
    DateTime? enteredAt,
  }) {
    return MissionRuntimeState(
      status: status ?? this.status,
      context: context ?? this.context,
      enteredAt: enteredAt ?? this.enteredAt,
    );
  }
}
