# Dravik: Embedded-Grade Architecture Blueprint

## High-Level Layers

```
┌─────────────────────────────────────┐
│        UI Layer (Screens)           │
│  (home, map, emergency, fallback)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Mission Engine & State Machine   │
│   (Navigation, Emergency, Routes)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Fusion Layer (Smoothing, Drift)   │
│   + Health Monitor & Watchdog       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│    Sensor Layer (GPS/Compass/IMU)   │
│    + Sensing Profile Manager        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Platform Adapters (Native Plugins) │
└─────────────────────────────────────┘

Data Layer (Offline Cache, Sync Queue, Local Storage)
  Built-in: Hive, Supabase Sync
```

---

## Module Breakdown (File Structure)

### 1. **Core: Mission Engine** → `lib/services/mission_engine/`

**Purpose:** Single source of truth for navigation, route tracking, and emergency logic.

**Files:**
- `mission_engine.dart` - Master orchestrator
- `mission_state.dart` - State definitions (enum + data classes)
- `mission_event.dart` - Event definitions (user actions, sensor inputs)
- `mission_state_machine.dart` - Transition logic + matchers

**Key Classes:**

```dart
enum MissionState {
  idle,           // Awaiting user action
  acquiringFix,   // GPS lock attempt
  tracking,       // Active navigation
  rerouting,      // Recalculating path
  emergencyMode,  // Safety fallback
  degraded,       // Limited functionality
}

enum SensingProfile {
  activeNav,      // High frequency (1s GPS, 0.5s heading)
  patrol,         // Medium (5s GPS, 2s heading)
  lowPower,       // Sparse (30s GPS, 10s heading)
}

class MissionEngine extends GetxService {
  late StreamSubscription<MissionEvent> _eventBus;
  final RxValue<MissionState> currentState = RxValue(MissionState.idle);
  final RxValue<NavigationContext> navContext = RxValue(...);
  
  Future<void> acceptEvent(MissionEvent evt) async {
    // Validate transition
    // Execute side effects (sensor start, UI update, alert)
    // Log state change
    // Update observables
  }
}

class MissionEvent {
  final String id;
  final DateTime timestamp;
  // Subclasses: GpsFixAcquired, RouteSelected, EmergencyTriggered, etc.
}

class NavigationContext {
  final Trip? activeTrip;
  final Position? lastKnownPosition;
  final double? confidenceLevel; // GPS quality
  final Duration timeSinceLastFix;
  final bool isOffline;
}
```

### 2. **Sensor Layer** → `lib/services/sensor_layer/`

**Purpose:** Abstract sensor I/O, handle permissions, retry, and watchdog recovery.

**Files:**
- `sensor_layer.dart` - Master sensor coordinator
- `location_adapter.dart` - GPS provider (Geolocator)
- `compass_adapter.dart` - Heading provider (Flutter Compass)
- `motion_adapter.dart` - IMU/accelerometer provider (Sensors Plus)
- `sensor_watchdog.dart` - Detection + recovery logic
- `sensor_fault_handler.dart` - Graceful degradation

**Key Classes:**

```dart
abstract class SensorAdapter<T> {
  Stream<T> get stream;
  Future<void> start();
  Future<void> stop();
  Future<Health> diagnose(); // Returns signal strength, permission status
}

class LocationAdapter extends SensorAdapter<Position> {
  @override
  Stream<Position> get stream => _controller.stream;
  
  Future<Health> diagnose() async {
    // Check GPS enabled, permission granted, fix acquired
    // Return: {healthy: bool, signal: int, age: Duration, error: String?}
  }
}

class SensorWatchdog {
  final Map<Type, DateTime> _lastGoodValue = {};
  final Map<Type, int> _failureCount = {};
  
  void monitor<T extends SensorAdapter>(T adapter, Duration timeout) {
    // If no value for >timeout, trigger circuit breaker
    // Auto-restart on repeated failure
    // Log fault to event queue
  }
}

class SensorFaultHandler {
  Future<void> handleLocationTimeout() async {
    // Fallback: use cached position + warn stale
    // Trigger degraded mode if critical
  }
}
```

### 3. **Fusion & Health** → `lib/services/fusion_layer/`

**Purpose:** Smooth sensor data, detect anomalies, and provide unified health status.

**Files:**
- `position_fuser.dart` - Kalman filter or simple averaging
- `heading_fuser.dart` - Compass + gyro integration
- `health_monitor.dart` - Aggregate sensor health
- `degradation_policy.dart` - When to trigger low-power mode

**Key Classes:**

```dart
class PositionFuser {
  Position fuse(Position raw, PosisionContext ctx) {
    // Apply Kalman or moving average filter
    // Detect jump (likely false GPS fix)
    // Return smoothed position with confidence
  }
}

class HealthMonitor {
  final RxMap<String, HealthMetric> metrics = RxMap();
  
  void updateMetric(String sensorName, HealthMetric metric) {
    // metric: {signal: 1-5, available: bool, lastUpdate: Duration}
    // Compute overall health band
    // If overall < threshold, switch to degraded
  }
}

class DegradationPolicy {
  SensingProfile selectProfile(BatteryLevel batt, HealthStatus health) {
    // activeNav if battery > 50% and health > 75%
    // patrol if battery 20-50% or health 50-75%
    // lowPower if battery < 20% or health < 50%
  }
}
```

### 4. **Power Manager** → `lib/services/power_manager/`

**Purpose:** Adaptive sensing, battery budgeting, graceful shutdown.

**Files:**
- `power_manager.dart` - Battery monitor + profile selector
- `sensing_profile_manager.dart` - Activate/switch profiles
- `battery_watchdog.dart` - Emergency low-battery flow

**Key Classes:**

```dart
class PowerManager extends GetxService {
  final RxValue<SensingProfile> activeProfile = RxValue(SensingProfile.activeNav);
  final RxInt batteryPercent = RxInt(100);
  
  void onBatteryChanged(int newPercent) {
    final policy = DegradationPolicy();
    final newProfile = policy.selectProfile(newPercent, _healthStatus);
    if (newProfile != activeProfile.value) {
      _switchProfile(newProfile);
      _eventBus.send(ProfileSwitched(newProfile));
    }
  }
  
  void _switchProfile(SensingProfile p) {
    switch(p) {
      case SensingProfile.activeNav:
        _sensorLayer.setGpsInterval(Duration(seconds: 1));
        _sensorLayer.setHeadingInterval(Duration(milliseconds: 500));
      case SensingProfile.patrol:
        _sensorLayer.setGpsInterval(Duration(seconds: 5));
        _sensorLayer.setHeadingInterval(Duration(seconds: 2));
      case SensingProfile.lowPower:
        _sensorLayer.setGpsInterval(Duration(seconds: 30));
        _sensorLayer.setHeadingInterval(Duration(seconds: 10));
        _disableBackgroundSync(); // Pause non-critical tasks
    }
  }
}
```

### 5. **Data & Offline Cache** → `lib/data/offline_cache/`

**Purpose:** Crash-safe offline-first storage with sync queue and data freshness.

**Files:**
- `offline_cache_manager.dart` - Unified cache policy (TTL, eviction)
- `sync_queue.dart` - Append-only, idempotent sync journal
- `data_freshness.dart` - Cache stale/fresh indicators
- `crash_recovery.dart` - Detect incomplete writes, repair

**Key Classes:**

```dart
class OfflineCacheManager extends GetxService {
  // Pre-cache critical assets on app start
  Future<void> cacheAssetsOnBoot() async {
    // Download maps for last used region
    // Cache emergency guides
    // Cache critical POIs (hospitals, shelters)
    // Set 30-day TTL
  }
  
  Future<T?> getCachedWithFallback<T>(String key, {Duration ttl = Duration(days: 7)}) async {
    final cached = await _hiveBox.get(key);
    if (cached != null && isNotExpired(cached, ttl)) {
      return cached as T;
    }
    return null; // Return null and show "offline, stale data"
  }
}

class SyncQueue {
  final _queue = <SyncEvent>[];
  
  void enqueueEvent(SyncEvent evt) {
    // Append with idempotency key
    // Persist to Hive
    // Wake background sync if online
  }
  
  Future<void> sync() async {
    for (var evt in _queue) {
      try {
        await _supabaseClient.rpc(...evt.toRPC());
        evt.status = SyncStatus.synced;
      } on Exception catch (e) {
        evt.status = SyncStatus.pending;
        evt.retryCount++;
        if (evt.retryCount > 3) evt.status = SyncStatus.deadLetter;
      }
    }
  }
}

enum DataFreshness { fresh, stale, expired }

class CacheEntry<T> {
  final T value;
  final DateTime cachedAt;
  final Duration ttl;
  
  DataFreshness freshness() {
    final age = DateTime.now().difference(cachedAt);
    if (age < ttl) return DataFreshness.fresh;
    if (age < ttl * 2) return DataFreshness.stale;
    return DataFreshness.expired;
  }
}
```

### 6. **Observability & Logging** → `lib/services/observability/`

**Purpose:** Structured event logging, health export, crash snapshots.

**Files:**
- `event_logger.dart` - Append-only event queue
- `health_exporter.dart` - Generate health report from logs
- `crash_snapshot.dart` - Capture last 30s state on exception

**Key Classes:**

```dart
class EventLogger extends GetxService {
  final _eventBuffer = <LogEvent>[];
  
  void log(LogEvent evt) {
    // {id, timestamp, level, message, context, stateSnapshot}
    _eventBuffer.add(evt);
    if (_eventBuffer.length > 1000) _eventBuffer.removeAt(0); // Rolling buffer
    _persistToDisk(); // Atomic write
  }
  
  Future<String> exportLogs() async {
    return _eventBuffer.map((e) => e.toJson()).join('\n');
  }
}

class CrashSnapshot {
  final String appVersion;
  final MissionState missionState;
  final SensingProfile profile;
  final Position? lastKnownPosition;
  final HealthStatus healthStatus;
  final List<LogEvent> lastThirtySecs;
  final StackTrace stackTrace;
  
  Future<void> persistAndUpload() async {
    // Save locally for manual user export
    // Attempt upload with backoff if online
  }
}
```

### 7. **Emergency & Fallback UX** → `lib/screens/emergency/` & `lib/screens/fallback/`

**Purpose:** Offline-first, network-independent safety features.

**Files:**
- `emergency_screen.dart` - Triggers SOS, compass, last position
- `fallback_map_screen.dart` - No-internet map using cached tiles
- `degraded_nav_screen.dart` - Minimal UI with health badges

**Key Classes:**

```dart
class EmergencyScreen extends StatelessWidget {
  // Works 100% offline: compass, cached position, cached guides
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCompassWidget(), // No network required
          _buildEmergencyContactsCached(), // From local cache
          _buildSOS(context),
          _buildLastKnownPosition(),
        ],
      ),
    );
  }
}

class FallbackMapScreen extends StatelessWidget {
  // When map provider fails or no internet
  // Render cached tiles + simple position dot
  @override
  Widget build(BuildContext context) {
    return MaplibreMap(
      styleString: 'file://path/to/cached/style.json', // Offline style
      initialCameraPosition: ..., // Last known
      // Simple marker layer, no API calls
    );
  }
}

class DegradedNavScreen extends StatelessWidget {
  // Show: GPS confidence, battery, sync status, data freshness
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HealthBadge(), // GPS: weak | Battery: 15% | Offline
          SimpleCompass(),
          'Last position from 5 min ago',
        ],
      ),
    );
  }
}
```

---

## State Machine Diagram

```
                 ┌─────────────────────────────────┐
                 │   idle (awaiting user action)   │
                 └────────────┬────────────────────┘
                              │ startNavigation()
                              ▼
    ┌──────────────────────────────────────────────────────┐
    │   acquiringFix (GPS lock attempt, timeout 20s)      │
    │   • Emit GpsAcquiring event                          │
    │   • Start SensorWatchdog with 20s timeout           │
    └──────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        │ (timeout)           │ (fix acquired)
        ▼                     ▼
    degraded              tracking
        ↕                   ↕
    rerouting          (GPS updates drive position)
        │                   │
        │                   │ (on exception: sensor failed)
        └───────────────────┴──► degraded
                                   │
                                   │ (user triggers SOS)
                                   ▼
                              emergencyMode
                               (persistent until manual clear)
```

**Valid Transitions:**
- `idle` → `acquiringFix` (startNavigation)
- `acquiringFix` → `tracking` (gpsAcquired)
- `acquiringFix` → `degraded` (timeout after 20s)
- `tracking` ↔ `rerouting` (routeRecalc triggered)
- `tracking` → `degraded` (GPS loss, health < threshold)
- `tracking`, `degraded`, `rerouting` → `emergencyMode` (sosTriggered)
- `degraded` → `tracking` (health recovered, GPS reacquired)
- Any state → `idle` (stopNavigation, tripCompleted)

---

## Implementation Roadmap

### Week 1: Control Plane & Reliability

| Day | Task | Output |
|-----|------|--------|
| 1 | Define and test state machine (unit tests) | `mission_state_machine.dart` + tests |
| 2 | Build MissionEngine skeleton + event bus | `mission_engine.dart` with GetX Rx observables |
| 3 | Wrap location/compass into SensorAdapter | `location_adapter.dart`, `compass_adapter.dart` |
| 4 | Build SensingProfileManager | `power_manager.dart` + profile switching logic |
| 5 | Add SensorWatchdog + fault handler | `sensor_watchdog.dart`, auto-recovery on timeout |

### Week 2: Offline & Safety Completion

| Day | Task | Output |
|-----|------|--------|
| 6 | Implement OfflineCacheManager + TTL logic | `offline_cache_manager.dart` + asset preload |
| 7 | Build SyncQueue (idempotent append) | `sync_queue.dart` + Hive integration |
| 8 | Create EmergencyScreen + Fallback Map | Offline-functional emergency UI |
| 9 | Add EventLogger + CrashSnapshot | `event_logger.dart`, exportable logs |
| 10 | Run soak tests + tune parameters | Battery budget validation, state transition coverage |

---

## Integration Points with Existing Code

### Existing Services (Refactor Into Fusion Layer)
- `weather_service.dart` → cache fetches with TTL, emit stale indicator
- `offline_guides_service.dart` → integrate with OfflineCacheManager
- `activity_tracker_service.dart` → enqueue events into SyncQueue
- `group_sync_service.dart` → use SyncQueue for idempotent sync

### Existing Screens (Adapt for Degraded Mode)
- `map_screen.dart` → detect offline, switch to FallbackMapScreen
- `home_screen.dart` → show health badges (GPS, battery, sync status)
- `emergency_contact_screen.dart` → use cached data, no network fallback

### Keep As-Is (Lightweight UI)
- `widgets/` → mostly unchanged
- `theme_provider.dart` → unchanged
- `models/` → extend with MissionState, HealthMetric, CacheEntry types

---

## Testing Strategy

### Unit Tests (Day 1-5)
- State machine: all transitions, invalid edges, timeouts
- SensorWatchdog: circuit breaker behavior, retry logic
- OfflineCacheManager: TTL expiry, concurrent reads

### Integration Tests (Day 6-10)
- Mission flow: start → acquiring → tracking → degraded → recovery
- Offline: cache hit on no network, stale/fresh indicators
- Power: profile switch on battery thresholds
- Sync: idempotent replay, deadletter handling

### Soak Tests (Day 10)
- 4-hour active tracking: battery drain, GPS hold-in time, restart count
- No network for 1 hour: cache performance, sync queue growth
- Permission revoke mid-flight: graceful degradation to fallback UI

---

## Success Criteria (Embedded-Grade v1)

✅ Navigation survives network loss, GPS jitter, permission changes without app restart.  
✅ Emergency flows (SOS, compass, last position) work offline with no backend call.  
✅ Battery drain in active tracking < 20%/hour on typical device.  
✅ State transitions are observable, logged, and test-covered.  
✅ Sync queue handles offline period (2 hours) and replays idempotently on reconnect.  
✅ Health monitor shows degradation path and recovery clearly.  
✅ Crash snapshot exported by user without developer involvement.

---

## Data Flow Example: "User Starts Navigation"

```
UI (map_screen.dart)
  ├─ tapStartNavigation() → MissionEngine.acceptEvent(StartNav)
  │
MissionEngine
  ├─ Validate: has route? → yes
  ├─ currentState := acquiringFix
  ├─ acceptEvent(GpsFixAcquiring)
  │
SensorLayer (LocationAdapter)
  ├─ Start GPS stream
  ├─ RequestPermission (if needed)
  ├─ SensorWatchdog watches for timeout
  │
GPS (platform)
  ├─ Emit position every 1s (activeNav profile)
  │
LocationAdapter receives Position
  ├─ PositionFuser smooths value
  ├─ HealthMonitor.updateMetric("gps", health=good)
  ├─ Emit GpsAcquired event
  │
MissionEngine
  ├─ Validate: confidence > 70%? → yes
  ├─ currentState := tracking
  ├─ acceptEvent(TrackingStarted)
  │
UI (map_screen.dart watches navContext)
  ├─ render: position dot, route line, distance-to-next-waypoint
  ├─ health badges: GPS signal, battery %, offline status
  │
SyncQueue (background)
  ├─ Enqueue TrackingStarted event with idempotency key
  ├─ If online: immediately upload to Supabase
  ├─ If offline: persist to Hive, mark pending, retry on reconnect
```

---

## Next Steps

1. **Read through this doc carefully** and note any adjustments to fit your trekking workflows.
2. **Create test cases first** for state machine transitions (ensure logic is correct before building UI).
3. **Scaffold the module tree** (create empty files with doc comments).
4. **Migrate one service at a time** (e.g., LocationAdapter first, then PowerManager).
5. **Validate with soak tests** before deploying to production.

This blueprint is the living contract for your embedded-grade Dravik. Update it as you discover new constraints or optimization opportunities during implementation.
