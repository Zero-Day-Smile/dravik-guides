# Dravik Embedded Architecture: Quick Start Checklist

## Phase 1: Scaffold Module Structure

Run these commands to create the new module directories:

```bash
cd /Users/amishkumar/Projects/dravik/lib

# Mission Engine & State
mkdir -p services/mission_engine
touch services/mission_engine/mission_engine.dart
touch services/mission_engine/mission_state.dart
touch services/mission_engine/mission_event.dart
touch services/mission_engine/mission_state_machine.dart

# Sensor Layer
mkdir -p services/sensor_layer
touch services/sensor_layer/sensor_layer.dart
touch services/sensor_layer/location_adapter.dart
touch services/sensor_layer/compass_adapter.dart
touch services/sensor_layer/sensor_watchdog.dart
touch services/sensor_layer/sensor_fault_handler.dart

# Fusion & Health
mkdir -p services/fusion_layer
touch services/fusion_layer/position_fuser.dart
touch services/fusion_layer/heading_fuser.dart
touch services/fusion_layer/health_monitor.dart
touch services/fusion_layer/degradation_policy.dart

# Power Manager
mkdir -p services/power_manager
touch services/power_manager/power_manager.dart
touch services/power_manager/sensing_profile_manager.dart
touch services/power_manager/battery_watchdog.dart

# Data Layer
mkdir -p data/offline_cache
touch data/offline_cache/offline_cache_manager.dart
touch data/offline_cache/sync_queue.dart
touch data/offline_cache/data_freshness.dart
touch data/offline_cache/crash_recovery.dart

# Observability
mkdir -p services/observability
touch services/observability/event_logger.dart
touch services/observability/health_exporter.dart
touch services/observability/crash_snapshot.dart

# Emergency UX
mkdir -p screens/emergency
mkdir -p screens/fallback
touch screens/emergency/emergency_screen.dart
touch screens/fallback/fallback_map_screen.dart
touch screens/fallback/degraded_nav_screen.dart
```

---

## Phase 2: Dependencies Audit

Ensure `pubspec.yaml` has these key packages (already likely present):

```yaml
dependencies:
  # State Management
  get: ^4.x
  
  # Sensors
  geolocator: ^11.x          # GPS
  flutter_compass: ^0.x      # Heading
  sensors_plus: ^1.x         # IMU/Accelerometer
  battery_plus: ^1.x         # Battery monitoring
  connectivity_plus: ^6.x    # Network status
  
  # Storage & Sync
  hive_flutter: ^1.x
  supabase_flutter: ^2.x
  
  # Logging & Crashes
  firebase_crashlytics: ^3.x (optional but recommended)
  
  # Maps
  maplibre_gl: ^0.x
```

If any are missing:

```bash
flutter pub add PACKAGE_NAME
```

---

## Phase 3: Priority Implementation Order

### First: State Machine + Event Bus (Day 1-2)

**Why first?** Everything else depends on MissionEngine being the single source of truth.

1. Define `mission_state.dart` with enums and data classes
2. Define `mission_event.dart` with all event types
3. Build `mission_state_machine.dart` with transition validation
4. Create `mission_engine.dart` skeleton with GetX RxValue observables
5. **Test thoroughly**: all valid transitions, invalid edge cases, timeout logic

**Validation:**
```bash
# Run state machine unit tests (write tests in test/mission_state_machine_test.dart)
flutter test test/mission_state_machine_test.dart -v
```

### Second: Sensor Layer Adapters (Day 3-5)

**Why second?** Sensors feed the mission engine with real data.

1. Build `location_adapter.dart` wrapping `geolocator`
2. Build `compass_adapter.dart` wrapping `flutter_compass`
3. Add `sensor_watchdog.dart` to monitor both
4. Create `sensor_fault_handler.dart` for graceful failures
5. Wire adapter streams → MissionEngine event bus

**Validation:**
```bash
# Test on device or emulator with mock location
flutter run -d emulator-5554
# Manually trigger: Settings → Location → Mock location
```

### Third: Power & Profile Switching (Day 4)

**Why parallel?** Sensing profiles affect battery drain immediately.

1. Build `power_manager.dart` listening to battery level
2. Create `sensing_profile_manager.dart` to switch GPS/compass intervals
3. Add `degradation_policy.dart` to select profile based on battery + health
4. Wire to MissionEngine: profile change → adjustment of sensor streams

**Validation:**
```bash
# Simulate low battery scenario
adb shell dumpsys battery set level 15
# Check logs: verify profile switches to lowPower
```

### Fourth: Data Layer & Offline Cache (Day 6-7)

**Why fourth?** Caching stabilizes the system; sync queue enables resilience.

1. Build `offline_cache_manager.dart` with TTL policies
2. Create `sync_queue.dart` for append-only, idempotent sync
3. Implement `data_freshness.dart` enum + CacheEntry wrapper
4. Add `crash_recovery.dart` to detect/repair incomplete writes
5. Refactor existing services to use OfflineCacheManager

**Validation:**
```bash
# Turn off network, use app: verify graceful fallback
adb shell svc wifi disable
adb shell svc data disable

# Turn network back on: verify sync replays correctly
adb shell svc wifi enable
adb shell svc data enable
```

### Fifth: Emergency & Fallback UX (Day 8)

**Why fifth?** Safety flows exercise offline mode end-to-end.

1. Build `emergency_screen.dart` (100% offline, SOS, compass, last position)
2. Build `fallback_map_screen.dart` (cached tiles, no API calls)
3. Build `degraded_nav_screen.dart` (health badges, limited UI)
4. Wire MissionEngine state changes → screen navigation

**Validation:**
```bash
# Test without network: tap Emergency → confirm compass works
# Verify: no network calls logged, local-only operation
```

### Sixth: Observability & Logging (Day 9)

**Why last?** Observability should wrap everything; retrofit after core works.

1. Build `event_logger.dart` (rolling buffer of structured events)
2. Build `crash_snapshot.dart` (on exception: capture state + logs)
3. Build `health_exporter.dart` (generate report from logs)
4. Wire all layers to emit LogEvent on state change, sensor update, error

**Validation:**
```bash
# Trigger an error, check crash snapshot is persisted
# Export logs from app settings, verify human-readable JSON
```

---

## Phase 4: Integration Checkpoint (Day 9-10)

### Unit Test Coverage Target: >80%

```bash
# Run all tests and check coverage
flutter test --coverage

# View coverage report
lcov --list coverage/lcov.info
```

### Soak Test Scenario (Day 10)

**4-hour active tracking:**
1. Start app, select route
2. Hit "Start Navigation"
3. Let run for 4 hours (or accelerated test: 1 hour at 4x simulation)
4. Monitor:
   - Battery drain (target: <20%/hour)
   - GPS acquisition time (target: <30s on first fix)
   - Sync queue depth over time (should drain on reconnect)
   - Memory usage (no unbounded growth)

**Offline resilience:**
1. Start navigation
2. Disable network (adb shell svc wifi disable)
3. Walk 1 km (or simulate GPS movement)
4. Verify:
   - Map renders (cached tiles)
   - Position updates (local sensor fusion)
   - No UI hangs
   - No crash logs in EventLogger
5. Re-enable network
6. Verify sync queue replays all track events

---

## Phase 5: Refactor Existing Services

Once core modules are stable, refactor incrementally:

1. **weather_service.dart** → Use OfflineCacheManager, emit DataFreshness
2. **offline_guides_service.dart** → Pre-cache critical guides in OfflineCacheManager
3. **activity_tracker_service.dart** → Enqueue events into SyncQueue
4. **group_sync_service.dart** → Use SyncQueue for idempotent sync

---

## File Tree After Scaffolding

```
lib/
├── services/
│   ├── mission_engine/
│   │   ├── mission_engine.dart
│   │   ├── mission_state.dart
│   │   ├── mission_event.dart
│   │   └── mission_state_machine.dart
│   ├── sensor_layer/
│   │   ├── sensor_layer.dart
│   │   ├── location_adapter.dart
│   │   ├── compass_adapter.dart
│   │   ├── sensor_watchdog.dart
│   │   └── sensor_fault_handler.dart
│   ├── fusion_layer/
│   │   ├── position_fuser.dart
│   │   ├── heading_fuser.dart
│   │   ├── health_monitor.dart
│   │   └── degradation_policy.dart
│   ├── power_manager/
│   │   ├── power_manager.dart
│   │   ├── sensing_profile_manager.dart
│   │   └── battery_watchdog.dart
│   ├── observability/
│   │   ├── event_logger.dart
│   │   ├── health_exporter.dart
│   │   └── crash_snapshot.dart
│   └── (existing services refactored)
├── data/
│   └── offline_cache/
│       ├── offline_cache_manager.dart
│       ├── sync_queue.dart
│       ├── data_freshness.dart
│       └── crash_recovery.dart
├── screens/
│   ├── emergency/
│   │   └── emergency_screen.dart
│   ├── fallback/
│   │   ├── fallback_map_screen.dart
│   │   └── degraded_nav_screen.dart
│   └── (existing screens)
├── models/
│   ├── mission_state.dart (extends enum + data)
│   └── (existing models)
└── (unchanged: theme/, utils/, widgets/, constants.dart, main.dart)
```

---

## Key Milestones & Sign-Offs

| Milestone | Success Criteria | Day |
|-----------|-----------------|-----|
| State Machine MVP | All transitions tested, no hanging states | 1-2 |
| Sensor Integration | Location + Compass streams flowing to MissionEngine | 3-4 |
| Power Switching | Profile changes visible in logs, GPS interval updates | 4 |
| Offline Cache | Cached data served, no network calls during offline | 6-7 |
| Emergency Flow | SOS screen works 100% offline, compass accurate | 8 |
| Observability | Logs exported, crash snapshot captured | 9 |
| Soak Test Pass | 4-hour tracking, <20%/hour battery drain, zero crashes | 10 |

---

## Common Implementation Gotchas

1. **State transitions not validated**
   - Don't skip the state machine test phase; invalid transitions are insidious bugs.

2. **Sensor adapters not wrapped with retry**
   - Always add retry + exponential backoff in sensor stream setup.

3. **Cache TTL not checked consistently**
   - Create a helper: `cachedOrFresh<T>(key, ttl)` that all services use.

4. **Sync queue not idempotent**
   - Assign every event a deterministic ID; server must de-dup by ID, not just timestamp.

5. **Emergency screen has network dependency**
   - Audit: no Supabase calls, no API calls; only local reads + local sensor streams.

6. **Logs not persisted atomically**
   - Use Hive transaction or single-file append; a crash mid-write corrupt logs.

7. **Health monitor always shows degraded**
   - Check sensor adapter `diagnose()` is returning correct signal metrics.

---

## Quick Debug Commands

```bash
# Tail logs for MissionEngine state changes
flutter logs | grep "MissionEngine"

# Check Hive cache size
adb shell "du -sh /data/data/com.dravik/lib_hive"

# Mock GPS location
adb emu geo fix -122.0840 37.4220

# Simulate network drop
adb shell svc wifi disable
adb shell svc data disable

# Check battery level simulation
adb shell dumpsys battery
adb shell dumpsys battery set level 15

# Export logs from app (if using EventLogger)
# Navigate to Settings → Export Logs → Share
```

---

## Next Immediate Action

1. **Copy-paste the scaffold commands** above into terminal
2. **Review EMBEDDED_ARCHITECTURE.md** (especially state machine and data flow sections)
3. **Start with mission_state.dart**: define the 6 states + data classes
4. **Write unit tests first**, then fill in implementations
5. **Post progress** once state machine is tested and green

You have a solid 2-week runway. Let me know when you're ready to dive into any specific module!
