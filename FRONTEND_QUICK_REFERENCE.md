# Dravik Frontend - Quick Reference Guide

## 🚀 Quick Start

### Setup
```bash
cd /Users/amishkumar/Projects/dravik
flutter pub get
cp .env.example .env
# Edit .env with Supabase credentials
```

### Run
```bash
# Web
flutter run -d chrome

# Android (requires emulator)
flutter emulators --launch pixel_7
flutter run

# macOS
flutter run -d macos

# iOS (requires Mac + Xcode)
flutter run -d ios
```

---

## 📱 Screen Navigation Map

```
HomeScreen (Entry point)
├── MapScreen
├── GuideScreen → GuideDetailScreen
├── GearScreen → ChecklistDetailScreen
├── SettingsScreen
│
├── Mobile-Only Navigation
│   ├── TripPlannerScreen
│   ├── CountryExplorerScreen
│   ├── PlaceGuideScreen
│   ├── WeatherForecastScreen
│   ├── AnalyticsScreen
│   ├── EmergencyGuidesScreen
│   ├── UltimateGuideScreen
│   │
│   └── Advanced Mobile Features (FeatureFlags gated)
│       ├── ArTrailScannerScreen (AR)
│       ├── GroupSyncScreen (Bluetooth + GPS)
│       ├── EmergencyContactScreen (SOS)
│       └── OfflineRegionsScreen (Map downloads)
```

---

## 🎯 Platform-Specific Behavior

### Web Edition
- **Focus**: Discover & Plan
- **Features**: 
  - All core features (maps, guides, gear, trips, weather, countries, analytics)
  - Read-only activities
  - Plan trips & research
- **Hidden**: AR, offline maps, emergency features, group sync, activity tracking

### Mobile Edition (iOS/Android)
- **Focus**: Execute & Track
- **All Features**: 
  - Core + Advanced (AR, offline, emergency, group ops)
  - Real-time GPS tracking
  - Sensor integration
  - Full editing capabilities

---

## 🔧 File Structure Reference

### Key Entry Points
- **lib/main.dart** - App initialization, error handling, Supabase setup
- **lib/theme_provider.dart** - Dark/light mode state
- **lib/constants.dart** - App-wide constants

### Configuration Must-Know
```dart
// How to check platform
import 'config/platform_capabilities.dart';
if (PlatformCapabilities.isWeb) { /* web only */ }
if (PlatformCapabilities.isMobile) { /* mobile only */ }

// How to check feature availability
import 'config/feature_flags.dart';
if (FeatureFlags.isEnabled(AppFeature.arScanner)) { /* AR available */ }

// How to get platform-specific copy
import 'config/edition_copy.dart';
final text = EditionCopy.forScreen(EditionScreen.map);
// returns EditionText with title/subtitle for current platform
```

### Service Usage Examples

**Get weather forecasts**:
```dart
final weather = await WeatherService().getWeatherForecast(lat, lng);
```

**Manage trips**:
```dart
final service = TripPlannerService();
await service.createTrip(trip);
await service.updateTrip(tripId, updatedTrip);
```

**Track activity**:
```dart
if (FeatureFlags.isEnabled(AppFeature.activityTracking)) {
  ActivityTrackerService.instance.startTracking();
}
```

**Sync with team** (mobile only):
```dart
if (FeatureFlags.isEnabled(AppFeature.groupSync)) {
  await GroupSyncService().startSync();
}
```

---

## 🎨 Theme Usage

```dart
// Light/Dark mode toggle
themeNotifier.value = !themeNotifier.value; // Triggers rebuild with new theme

// Theme colors
Color primary = Theme.of(context).primaryColor; // #1A73E8
Color secondary = Theme.of(context).colorScheme.secondary; // #34A853
Color accent = Theme.of(context).colorScheme.tertiary; // #EA4335
```

---

## 📦 Dependencies Quick Lookup

| Feature | Package | Version |
|---------|---------|---------|
| State Management | get | 4.6.6 |
| Storage | hive + hive_flutter | 2.2.3, 1.1.0 |
| Backend | supabase_flutter | 2.9.1 |
| Maps | maplibre_gl, flutter_map | 0.24.1, 8.1.1 |
| Location | geolocator, flutter_compass | 14.0.2, 0.8.0 |
| Camera | camera | 0.11.0+2 |
| Audio | audioplayers, flutter_tts | 6.5.0, 4.2.0 |
| Animations | lottie | 3.3.1 |
| Bluetooth | flutter_blue_plus | 1.32.11 |
| Permissions | permission_handler, local_auth | 12.0.1, 3.0.0 |
| Secure Storage | flutter_secure_storage | 10.0.0 |
| PDF | printing, pdf | 5.13.1, 3.11.0 |
| Sensors | sensors_plus, battery_plus | 7.0.0, 7.0.0 |

---

## 🔐 Security Checklist

- [x] API credentials in .env only (never commit)
- [x] Supabase RLS policies enabled
- [x] Sensitive data not logged in release builds
- [x] Secure storage for auth tokens & API keys
- [x] HTTPS for all API calls (Supabase auto)
- [x] Runtime permissions checked before access
- [x] No hardcoded secrets in source code

---

## 🐛 Common Debugging

**Hot Reload Issues**:
```bash
# If hot reload fails, rebuild
r  # hot reload
R  # hot restart (full rebuild)
```

**Missing Permissions on Android**:
- Grant at runtime using `permission_handler`
- Check AndroidManifest.xml for declarations

**Map Not Loading**:
- Verify `maplibre_gl` has API key in pubspec defaults
- Check offline tile cache is valid

**AR Not Working**:
- Verify device has camera (not emulator-safe)
- Check `FeatureFlags.isEnabled(AppFeature.arScanner)`

**Supabase Connection Failed**:
- Verify .env file exists and is loaded
- Check internet connectivity
- Confirm Supabase project is running

---

## 📊 Widget Tree Overview

```
MaterialApp (theme via ValueListenableBuilder)
└── HomeScreen (StatefulWidget)
    ├── AppBar with title
    ├── [Dynamic Content based on _selectedIndex]
    │   ├── MapScreen
    │   ├── GuideScreen
    │   ├── GearScreen (or TripPlanner on web)
    │   └── SettingsScreen
    ├── BottomNavigationBar (4-5 items)
    └── FloatingActionButton (context-dependent)
```

Every screen wraps key content with:
```dart
EditionBannerForScreen(
  screen: EditionScreen.map,  // e.g., EditionScreen.map
  child: // ... screen content
)
```

---

## 🔄 Data Flow

**Local Data** (Hive):
- User preferences (theme, notifications)
- Cached guides & offline data
- Activity logs (optional local backup)

**Remote Data** (Supabase):
- Trips & itineraries
- Gear configurations
- Weather forecasts
- User profiles & team data
- Analytics events

**Real-Time Sync**:
- GPS position updates (group sync)
- Activity metrics (to dashboard)
- Emergency alerts (broadcast)

---

## 📈 Monitoring & Debugging

**Enable Debug Logging**:
```dart
// In main.dart, these functions already exist:
debugPrint('Message'); // Only in debug builds
```

**Check Platform Detection**:
```dart
print('Is Web: ${PlatformCapabilities.isWeb}');
print('Is Mobile: ${PlatformCapabilities.isMobile}');
print('Is iOS: ${PlatformCapabilities.isIOS}');
```

**View Hive Data** (debug):
```dart
final box = Hive.box('guides');
print(box.length); // Number of items
```

---

## ✅ Pre-Release Checklist

- [ ] All screens tested on target platforms
- [ ] Offline functionality verified
- [ ] Platform-specific features working:
  - [ ] AR on mobile/Android only
  - [ ] Bluetooth on mobile only
  - [ ] Emergency contacts accessible
  - [ ] Offline maps downloadable
- [ ] Theme switch works (dark/light)
- [ ] Permissions prompt correctly
- [ ] No hardcoded values or test data
- [ ] .env configured with production credentials
- [ ] Privacy policy/ToS up to date
- [ ] Error messages user-friendly
- [ ] Crash reporting enabled (optional)
- [ ] Analytics baseline set

---

## 📚 Additional Resources

**Dart Docs**: https://dart.dev/guides
**Flutter Docs**: https://flutter.dev/docs
**GetX Guide**: https://github.com/jonataslaw/getx/wiki
**Supabase Flutter**: https://supabase.com/docs/reference/flutter/introduction
**Material Design 3**: https://m3.material.io

---

**Last Updated**: March 9, 2026
**Status**: ✅ Production Ready
