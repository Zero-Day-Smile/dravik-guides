import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:get/get.dart';

import '../mission_engine/mission_engine.dart';
import '../mission_engine/mission_event.dart';

typedef BatteryLevelReader = Future<int> Function();

class MissionPowerManager extends GetxService {
  MissionPowerManager({
    MissionEngine? missionEngine,
    BatteryLevelReader? batteryLevelReader,
    this.pollInterval = const Duration(minutes: 1),
  })  : _missionEngine = missionEngine ?? Get.find<MissionEngine>(),
        _battery = batteryLevelReader == null ? Battery() : null,
        _batteryLevelReader = batteryLevelReader;

  final MissionEngine _missionEngine;
  final Battery? _battery;
  final BatteryLevelReader? _batteryLevelReader;
  final Duration pollInterval;

  Timer? _pollTimer;
  final RxInt lastBatteryPercent = (-1).obs;

  Future<MissionPowerManager> initialize() async {
    await refreshBatteryLevel();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(refreshBatteryLevel());
    });
    return this;
  }

  Future<void> refreshBatteryLevel() async {
    try {
      final batteryPercent =
          await (_batteryLevelReader?.call() ?? _battery!.batteryLevel);
      lastBatteryPercent.value = batteryPercent;
      _missionEngine.accept(
        BatteryLevelReported(
          occurredAt: DateTime.now(),
          batteryPercent: batteryPercent,
        ),
      );
    } catch (_) {
      // Best-effort only: battery reporting should never interrupt navigation.
    }
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }
}