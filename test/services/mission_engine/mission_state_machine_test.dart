import 'package:flutter_test/flutter_test.dart';
import 'package:dravik/services/mission_engine/mission_engine.dart';
import 'package:dravik/services/mission_engine/mission_event.dart';
import 'package:dravik/services/mission_engine/mission_state.dart';
import 'package:dravik/services/mission_engine/mission_state_machine.dart';

void main() {
  group('MissionStateMachine', () {
    const machine = MissionStateMachine(
      acquiringFixTimeout: Duration(seconds: 20),
      minimumFixConfidence: 0.6,
      lowBatteryThreshold: 20,
    );

    final start = DateTime(2026, 3, 10, 12);

    test('starts in acquiringFix when mission starts', () {
      final current = MissionRuntimeState.initial(now: start);

      final transition = machine.apply(
        current,
        StartMission(
          occurredAt: start.add(const Duration(seconds: 1)),
          tripId: 'trip-1',
          routeId: 'route-1',
          routeName: 'North Ridge',
          target: const MissionCoordinates(latitude: 27.9878, longitude: 86.925),
        ),
      );

      expect(transition.isValid, isTrue);
      expect(transition.state.status, MissionStatus.acquiringFix);
      expect(transition.state.context.activeTripId, 'trip-1');
      expect(transition.state.context.routeId, 'route-1');
      expect(transition.state.context.routeName, 'North Ridge');
      expect(transition.state.context.target?.latitude, 27.9878);
    });

    test('times out into degraded when no GPS fix arrives', () {
      final current = MissionRuntimeState(
        status: MissionStatus.acquiringFix,
        context: MissionContext.initial(),
        enteredAt: start,
      );

      final transition = machine.apply(
        current,
        TickMission(occurredAt: start.add(const Duration(seconds: 21))),
      );

      expect(transition.isValid, isTrue);
      expect(transition.state.status, MissionStatus.degraded);
      expect(
        transition.state.context.degradedReason,
        DegradedReason.gpsTimeout,
      );
    });

    test('accepts healthy fix and enters tracking', () {
      final current = MissionRuntimeState(
        status: MissionStatus.acquiringFix,
        context: MissionContext.initial(),
        enteredAt: start,
      );

      final transition = machine.apply(
        current,
        MissionFixAcquired(
          occurredAt: start.add(const Duration(seconds: 4)),
          fix: MissionFix(
            coordinates: const MissionCoordinates(
              latitude: 34.1,
              longitude: -118.2,
              accuracyMeters: 4,
            ),
            recordedAt: start.add(const Duration(seconds: 4)),
            confidence: 0.91,
          ),
        ),
      );

      expect(transition.state.status, MissionStatus.tracking);
      expect(transition.state.context.lastFix, isNotNull);
      expect(transition.state.context.health, MissionHealth.healthy);
      expect(transition.state.context.gpsConfidence, 0.91);
    });

    test('moves tracking into rerouting and back again', () {
      final tracking = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: MissionContext.initial().copyWith(
          lastFix: MissionFix(
            coordinates: const MissionCoordinates(latitude: 1, longitude: 1),
            recordedAt: start,
            confidence: 0.9,
          ),
          health: MissionHealth.healthy,
        ),
        enteredAt: start,
      );

      final reroute = machine.apply(
        tracking,
        RerouteRequested(
          occurredAt: start.add(const Duration(seconds: 10)),
          reason: 'User deviated from route',
        ),
      );

      expect(reroute.state.status, MissionStatus.rerouting);
      expect(reroute.state.context.lastError, 'User deviated from route');

      final resolved = machine.apply(
        reroute.state,
        RerouteResolved(occurredAt: start.add(const Duration(seconds: 15))),
      );

      expect(resolved.state.status, MissionStatus.tracking);
      expect(resolved.state.context.lastError, isNull);
    });

    test('degrades on low battery and can recover after retry', () {
      final tracking = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: MissionContext.initial().copyWith(
          profile: SensingProfile.activeNavigation,
          health: MissionHealth.healthy,
        ),
        enteredAt: start,
      );

      final lowBattery = machine.apply(
        tracking,
        BatteryLevelReported(
          occurredAt: start.add(const Duration(minutes: 10)),
          batteryPercent: 12,
        ),
      );

      expect(lowBattery.state.status, MissionStatus.degraded);
      expect(lowBattery.state.context.profile, SensingProfile.lowPower);
      expect(
        lowBattery.state.context.degradedReason,
        DegradedReason.lowBattery,
      );

      final toppedUpContext = lowBattery.state.copyWith(
        context: lowBattery.state.context.copyWith(batteryPercent: 64),
      );

      final recovered = machine.apply(
        toppedUpContext,
        RecoveryRequested(occurredAt: start.add(const Duration(minutes: 20))),
      );

      expect(recovered.state.status, MissionStatus.tracking);
      expect(recovered.state.context.profile, SensingProfile.patrol);
      expect(recovered.state.context.degradedReason, DegradedReason.none);
    });

    test('emergency mode overrides tracking and only recovers to degraded', () {
      final tracking = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: MissionContext.initial().copyWith(
          health: MissionHealth.healthy,
        ),
        enteredAt: start,
      );

      final emergency = machine.apply(
        tracking,
        EmergencyTriggered(
          occurredAt: start.add(const Duration(minutes: 1)),
          reason: 'SOS manually triggered',
        ),
      );

      expect(emergency.state.status, MissionStatus.emergencyMode);
      expect(
        emergency.state.context.degradedReason,
        DegradedReason.manualEmergency,
      );

      final acknowledged = machine.apply(
        emergency.state,
        RecoveryRequested(occurredAt: start.add(const Duration(minutes: 2))),
      );

      expect(acknowledged.state.status, MissionStatus.degraded);
      expect(acknowledged.state.context.health, MissionHealth.critical);
    });

    test('updates heading/altitude/speed/slope from global telemetry signals', () {
      final tracking = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: MissionContext.initial(),
        enteredAt: start,
      );

      final heading = machine.apply(
        tracking,
        HeadingReported(
          occurredAt: start.add(const Duration(seconds: 5)),
          headingDegrees: 187,
          confidencePercent: 66,
        ),
      );
      expect(heading.state.context.headingConfidence, 66);

      final altitude = machine.apply(
        heading.state,
        AltitudeReported(
          occurredAt: start.add(const Duration(seconds: 6)),
          altitudeMeters: 2843.4,
        ),
      );
      expect(altitude.state.context.altitudeMeters, closeTo(2843.4, 0.001));

      final speed = machine.apply(
        altitude.state,
        SpeedReported(
          occurredAt: start.add(const Duration(seconds: 7)),
          speedMetersPerSecond: 1.85,
        ),
      );
      expect(speed.state.context.speedMetersPerSecond, closeTo(1.85, 0.001));

      final slope = machine.apply(
        speed.state,
        SlopeReported(
          occurredAt: start.add(const Duration(seconds: 8)),
          slopePercent: 12.25,
        ),
      );
      expect(slope.state.context.slopePercent, closeTo(12.25, 0.001));
      expect(slope.state.status, MissionStatus.tracking);
    });

    test('battery low-power signal preserves latest telemetry metrics', () {
      final tracking = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: MissionContext.initial().copyWith(
          headingConfidence: 66,
          altitudeMeters: 1250,
          speedMetersPerSecond: 2.4,
          slopePercent: -4.5,
        ),
        enteredAt: start,
      );

      final lowBattery = machine.apply(
        tracking,
        BatteryLevelReported(
          occurredAt: start.add(const Duration(minutes: 1)),
          batteryPercent: 15,
        ),
      );

      expect(lowBattery.state.context.headingConfidence, 66);
      expect(lowBattery.state.context.altitudeMeters, 1250);
      expect(lowBattery.state.context.speedMetersPerSecond, 2.4);
      expect(lowBattery.state.context.slopePercent, -4.5);
      expect(lowBattery.state.status, MissionStatus.degraded);
    });
  });

  group('MissionEngine', () {
    test('stores transition results as runtime state', () {
      final engine = MissionEngine();
      final now = DateTime(2026, 3, 10, 13);

      final transition = engine.accept(
        StartMission(
          occurredAt: now,
          routeId: 'route-42',
        ),
      );

      expect(transition.state.status, MissionStatus.acquiringFix);
      expect(engine.status, MissionStatus.acquiringFix);
      expect(engine.context.routeId, 'route-42');
    });
  });
}
