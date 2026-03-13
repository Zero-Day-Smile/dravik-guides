import 'package:flutter_test/flutter_test.dart';
import 'package:dravik/services/mission_engine/mission_engine.dart';
import 'package:dravik/services/mission_engine/mission_event.dart';
import 'package:dravik/services/mission_engine/mission_state.dart';
import 'package:dravik/services/mission_engine/mission_state_machine.dart';
import 'package:dravik/services/power_manager/mission_power_manager.dart';

void main() {
  test('MissionPowerManager publishes battery level into mission engine', () async {
    final engine = MissionEngine(
      stateMachine: const MissionStateMachine(lowBatteryThreshold: 20),
    );

    final now = DateTime(2026, 3, 11, 9);
    engine.accept(StartMission(occurredAt: now, routeId: 'ridge-route'));
    engine.accept(
      MissionFixAcquired(
        occurredAt: now.add(const Duration(seconds: 2)),
        fix: MissionFix(
          coordinates: const MissionCoordinates(latitude: 12, longitude: 77),
          recordedAt: now.add(const Duration(seconds: 2)),
          confidence: 0.95,
        ),
      ),
    );

    final manager = MissionPowerManager(
      missionEngine: engine,
      batteryLevelReader: () async => 14,
      pollInterval: const Duration(hours: 1),
    );

    await manager.refreshBatteryLevel();

    expect(manager.lastBatteryPercent.value, 14);
    expect(engine.context.batteryPercent, 14);
    expect(engine.status, MissionStatus.degraded);
    expect(engine.context.degradedReason, DegradedReason.lowBattery);
  });
}