import 'mission_event.dart';
import 'mission_state.dart';

class MissionTransition {
  const MissionTransition({
    required this.state,
    required this.isValid,
    this.description,
  });

  final MissionRuntimeState state;
  final bool isValid;
  final String? description;
}

class MissionStateMachine {
  const MissionStateMachine({
    this.acquiringFixTimeout = const Duration(seconds: 20),
    this.minimumFixConfidence = 0.6,
    this.lowBatteryThreshold = 20,
  });

  final Duration acquiringFixTimeout;
  final double minimumFixConfidence;
  final int lowBatteryThreshold;

  MissionTransition apply(
    MissionRuntimeState current,
    MissionEvent event,
  ) {
    final updatedContext = _contextForGlobalSignals(current.context, event);

    if (event is StopMission) {
      return MissionTransition(
        state: MissionRuntimeState(
          status: MissionStatus.idle,
          context: MissionContext.initial(),
          enteredAt: event.occurredAt,
        ),
        isValid: current.status != MissionStatus.idle,
        description: 'Mission stopped',
      );
    }

    if (event is EmergencyTriggered) {
      return _transition(
        current,
        status: MissionStatus.emergencyMode,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.manualEmergency,
          lastError: event.reason,
        ),
        occurredAt: event.occurredAt,
        description: 'Emergency mode entered',
      );
    }

    switch (current.status) {
      case MissionStatus.idle:
        return _handleIdle(current, event, updatedContext);
      case MissionStatus.acquiringFix:
        return _handleAcquiringFix(current, event, updatedContext);
      case MissionStatus.tracking:
        return _handleTracking(current, event, updatedContext);
      case MissionStatus.rerouting:
        return _handleRerouting(current, event, updatedContext);
      case MissionStatus.degraded:
        return _handleDegraded(current, event, updatedContext);
      case MissionStatus.emergencyMode:
        return _handleEmergency(current, event, updatedContext);
    }
  }

  MissionTransition _handleIdle(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is StartMission) {
      return _transition(
        current,
        status: MissionStatus.acquiringFix,
        context: updatedContext.copyWith(
          activeTripId: event.tripId,
          routeId: event.routeId,
          routeName: event.routeName,
          target: event.target,
          degradedReason: DegradedReason.none,
          health: MissionHealth.unknown,
          lastError: null,
          clearLastError: true,
        ),
        occurredAt: event.occurredAt,
        description: 'Mission started; acquiring GPS fix',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionTransition _handleAcquiringFix(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is MissionFixAcquired) {
      final nextStatus = event.fix.confidence >= minimumFixConfidence
          ? MissionStatus.tracking
          : MissionStatus.degraded;
      final nextReason = event.fix.confidence >= minimumFixConfidence
          ? DegradedReason.none
          : DegradedReason.gpsUnavailable;
      final nextHealth = event.fix.confidence >= minimumFixConfidence
          ? MissionHealth.healthy
          : MissionHealth.limited;

      return _transition(
        current,
        status: nextStatus,
        context: updatedContext.copyWith(
          lastFix: event.fix,
          gpsConfidence: event.fix.confidence,
          degradedReason: nextReason,
          health: nextHealth,
          lastError: nextStatus == MissionStatus.degraded
              ? 'GPS confidence below threshold'
              : null,
          clearLastError: nextStatus == MissionStatus.tracking,
        ),
        occurredAt: event.occurredAt,
        description: 'GPS fix processed',
      );
    }

    if (event is TickMission &&
        event.occurredAt.difference(current.enteredAt) >= acquiringFixTimeout) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.gpsTimeout,
          health: MissionHealth.limited,
          lastError: 'GPS fix acquisition timed out',
        ),
        occurredAt: event.occurredAt,
        description: 'GPS acquisition timed out',
      );
    }

    if (event is LocationPermissionDenied) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.permissionDenied,
          health: MissionHealth.critical,
          lastError: 'Location permission denied',
        ),
        occurredAt: event.occurredAt,
        description: 'Permission denied during fix acquisition',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionTransition _handleTracking(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is MissionFixAcquired) {
      return _transition(
        current,
        status: MissionStatus.tracking,
        context: updatedContext.copyWith(
          lastFix: event.fix,
          gpsConfidence: event.fix.confidence,
          degradedReason: DegradedReason.none,
          health: MissionHealth.healthy,
          lastError: null,
          clearLastError: true,
        ),
        occurredAt: event.occurredAt,
        description: 'Tracking fix refreshed',
      );
    }

    if (event is MissionFixLost) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.gpsUnavailable,
          health: MissionHealth.limited,
          lastError: event.reason ?? 'GPS fix lost during tracking',
        ),
        occurredAt: event.occurredAt,
        description: 'Tracking degraded after GPS loss',
      );
    }

    if (event is RerouteRequested) {
      return _transition(
        current,
        status: MissionStatus.rerouting,
        context: updatedContext.copyWith(
          lastError: event.reason,
        ),
        occurredAt: event.occurredAt,
        description: 'Reroute requested',
      );
    }

    if (event is BatteryLevelReported &&
        event.batteryPercent <= lowBatteryThreshold) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          profile: SensingProfile.lowPower,
          degradedReason: DegradedReason.lowBattery,
          health: MissionHealth.limited,
          lastError: 'Battery dropped below threshold',
        ),
        occurredAt: event.occurredAt,
        description: 'Tracking degraded for low battery',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionTransition _handleRerouting(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is RerouteResolved) {
      return _transition(
        current,
        status: MissionStatus.tracking,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.none,
          health: MissionHealth.healthy,
          lastError: null,
          clearLastError: true,
        ),
        occurredAt: event.occurredAt,
        description: 'Reroute resolved',
      );
    }

    if (event is MissionFixLost) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.routeUnavailable,
          health: MissionHealth.limited,
          lastError: event.reason ?? 'Route refresh failed',
        ),
        occurredAt: event.occurredAt,
        description: 'Reroute failed; mission degraded',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionTransition _handleDegraded(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is MissionFixAcquired && event.fix.confidence >= minimumFixConfidence) {
      return _transition(
        current,
        status: MissionStatus.tracking,
        context: updatedContext.copyWith(
          lastFix: event.fix,
          gpsConfidence: event.fix.confidence,
          degradedReason: DegradedReason.none,
          health: MissionHealth.healthy,
          lastError: null,
          clearLastError: true,
        ),
        occurredAt: event.occurredAt,
        description: 'Mission recovered from degraded mode',
      );
    }

    if (event is RecoveryRequested &&
        updatedContext.degradedReason == DegradedReason.lowBattery &&
        (updatedContext.batteryPercent ?? 0) > lowBatteryThreshold) {
      return _transition(
        current,
        status: MissionStatus.tracking,
        context: updatedContext.copyWith(
          profile: SensingProfile.patrol,
          degradedReason: DegradedReason.none,
          health: MissionHealth.healthy,
          lastError: null,
          clearLastError: true,
        ),
        occurredAt: event.occurredAt,
        description: 'Mission recovered after manual retry',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionTransition _handleEmergency(
    MissionRuntimeState current,
    MissionEvent event,
    MissionContext updatedContext,
  ) {
    if (event is RecoveryRequested) {
      return _transition(
        current,
        status: MissionStatus.degraded,
        context: updatedContext.copyWith(
          degradedReason: DegradedReason.manualEmergency,
          health: MissionHealth.critical,
        ),
        occurredAt: event.occurredAt,
        description: 'Emergency acknowledged; returning to degraded mode',
      );
    }

    return MissionTransition(state: current.copyWith(context: updatedContext), isValid: false);
  }

  MissionContext _contextForGlobalSignals(
    MissionContext context,
    MissionEvent event,
  ) {
    if (event is BatteryLevelReported) {
      return context.copyWith(
        batteryPercent: event.batteryPercent,
        profile: event.batteryPercent <= lowBatteryThreshold
            ? SensingProfile.lowPower
            : context.profile,
      );
    }

    if (event is HeadingReported) {
      return context.copyWith(
        headingConfidence: event.confidencePercent,
      );
    }

    if (event is AltitudeReported) {
      return context.copyWith(
        altitudeMeters: event.altitudeMeters,
      );
    }

    if (event is SpeedReported) {
      return context.copyWith(
        speedMetersPerSecond: event.speedMetersPerSecond,
      );
    }

    if (event is SlopeReported) {
      return context.copyWith(
        slopePercent: event.slopePercent,
      );
    }

    if (event is ConnectivityChanged) {
      return context.copyWith(
        isOffline: event.isOffline,
        degradedReason: event.isOffline
            ? DegradedReason.networkUnavailable
            : context.degradedReason,
      );
    }

    return context;
  }

  MissionTransition _transition(
    MissionRuntimeState current, {
    required MissionStatus status,
    required MissionContext context,
    required DateTime occurredAt,
    required String description,
  }) {
    final changed = current.status != status || current.context != context;
    return MissionTransition(
      state: MissionRuntimeState(
        status: status,
        context: context,
        enteredAt: changed ? occurredAt : current.enteredAt,
      ),
      isValid: true,
      description: description,
    );
  }
}
