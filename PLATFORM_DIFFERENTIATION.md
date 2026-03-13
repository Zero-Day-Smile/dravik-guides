# Dravik Platform Differentiation System

## Overview

Dravik delivers **the same brand, different platform experiences**:
- 🌐 **Web**: Discover and Plan
- 📱 **iOS**: Polished Mobile Experience  
- 🏕️ **Android/Mobile**: Full Field Operations

---

## Core Components

### 1. Platform Detection (`platform_capabilities.dart`)

```dart
class PlatformCapabilities {
  // Detects platform at runtime
  static bool get isWeb => kIsWeb;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);
}
```

**Usage**:
```dart
if (PlatformCapabilities.isWeb) {
  // Show web-specific layout
} else if (PlatformCapabilities.isMobile) {
  // Show mobile-specific features
}
```

### 2. Feature Flags (`feature_flags.dart`)

Controls which advanced features are available per platform:

```dart
enum AppFeature {
  arScanner,          // 📱 Mobile-only
  groupSync,          // 👥 Mobile-only (Bluetooth)
  offlineRegions,     // 🗺️ Mobile-only (storage)
  emergencyContacts,  // 🚨 Mobile-only
  activityTracking,   // 📊 Mobile-only (GPS)
  bluetoothTools,     // 🔵 Mobile-only
  biometrics,         // 🔐 Mobile-only
}

class FeatureFlags {
  static bool isEnabled(AppFeature feature) {
    // Mobile-only features
    return PlatformCapabilities.isMobile;
  }
}
```

**Usage**:
```dart
if (FeatureFlags.isEnabled(AppFeature.arScanner)) {
  // Show AR scanner option
} else {
  // Show platform unavailable message
}
```

### 3. Edition Copy (`edition_copy.dart`)

**Centralized platform-specific messaging** for consistent user experience.

```dart
enum EditionScreen {
  home, map, guide, gear, trip, weather,
  country, placeGuide, emergency, analytics,
  settings, guideDetail, ultimateGuide, // ... 15+ screens
}

class EditionText {
  final String webTitle;
  final String webSubtitle;
  final String iosTitle;
  final String iosSubtitle;
  final String mobileTitle;
  final String mobileSubtitle;

  EditionText({
    required this.webTitle,
    required this.webSubtitle,
    required this.iosTitle,
    required this.iosSubtitle,
    required this.mobileTitle,
    required this.mobileSubtitle,
  });
}

class EditionCopy {
  static const Map<EditionScreen, EditionText> _copy = {
    EditionScreen.map: EditionText(
      webTitle: 'Explore Trails',
      webSubtitle: 'Research trekking routes and destinations',
      iosTitle: 'Trail Maps',
      iosSubtitle: 'Navigate your adventure',
      mobileTitle: 'Track Adventure',
      mobileSubtitle: 'Real-time GPS tracking and navigation',
    ),
    // ... 14+ more screens
  };

  static EditionText forScreen(EditionScreen screen) {
    return _copy[screen] ?? EditionText.default();
  }

  static String? getTitleForPlatform(EditionScreen screen) {
    final text = forScreen(screen);
    if (PlatformCapabilities.isWeb) return text.webTitle;
    if (PlatformCapabilities.isIOS) return text.iosTitle;
    return text.mobileTitle;
  }

  static String? getSubtitleForPlatform(EditionScreen screen) {
    final text = forScreen(screen);
    if (PlatformCapabilities.isWeb) return text.webSubtitle;
    if (PlatformCapabilities.isIOS) return text.iosSubtitle;
    return text.mobileSubtitle;
  }
}
```

---

## Edition Banner System

### Visual Component (`edition_banner.dart`)

Shows a beautiful badge indicating platform experience:

```dart
EditionBanner(
  editionType: EditionType.web,  // or .ios, .mobile
  title: 'Discover & Plan',
  subtitle: 'Research destinations and trips',
)
```

**Visual Design**:
```
┌─────────────────────────────────┐
│ 🌐 WEB   Discover & Plan        │
│ Research destinations and trips  │
└─────────────────────────────────┘
```

**Gradient Backgrounds**:
- Web: Blue gradient (#1A73E8)
- iOS: Green gradient (#34A853)
- Mobile/Android: Orange gradient (#EA4335)

### Smart Wrapper Widget (`edition_banner_for_screen.dart`)

Automatically selects and displays the correct banner for current platform:

```dart
EditionBannerForScreen(
  screen: EditionScreen.map,  // Just specify the screen
  child: mapContent,          // Banner + content wrapper
)
```

**What it does**:
1. Detects `PlatformCapabilities.isWeb/isIOS/isAndroid`
2. Looks up `EditionCopy.forScreen(EditionScreen.map)`
3. Gets platform-specific title/subtitle
4. Renders `EditionBanner` with correct styling
5. Wraps child content below banner

**Eliminates boilerplate**:
```dart
// ❌ OLD WAY (manual platform checks everywhere)
if (PlatformCapabilities.isWeb) {
  return EditionBanner(title: 'Explore Trails', ...);
} else if (PlatformCapabilities.isIOS) {
  return EditionBanner(title: 'Trail Maps', ...);
} else {
  return EditionBanner(title: 'Track Adventure', ...);
}

// ✅ NEW WAY (centralized, reusable)
return EditionBannerForScreen(screen: EditionScreen.map, child: content);
```

---

## Implementation in Screens

Every screen uses the same pattern:

```dart
class MapScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Maps')),
      body: EditionBannerForScreen(
        screen: EditionScreen.map,
        child: Column(
          children: [
            // ... map content
            if (FeatureFlags.isEnabled(AppFeature.arScanner)) {
              // AR option visible only on mobile
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArTrailScannerScreen()),
                ),
                child: Text('View in AR'),
              )
            }
          ],
        ),
      ),
    );
  }
}
```

---

## Screens with Edition Banners (14 Total)

| Screen | Web Message | iOS Message | Mobile Message |
|--------|-------------|-------------|----|
| **Map** | Explore Trails | Trail Maps | Track Adventure |
| **Guide** | Discover Treks | Learn Trails | Field Reference |
| **Gear** | Prepare Equipment | Pack Smart | Equipment Tracker |
| **Trip** | Plan Trips | Organize Adventures | Manage Expeditions |
| **Weather** | Weather Planning | Trail Conditions | Real-time Forecast |
| **Country** | Discover Nations | Explore Countries | Travel Database |
| **Place Guide** | Research Destinations | Get Tour Guide | Local Explorer |
| **Emergency** | Safety Knowledge | Emergency Reference | Critical Info |
| **Analytics** | Your Stats (read-only) | Performance Dashboard | Full Analytics |
| **Settings** | Preferences | App Settings | Full Configuration |
| **Guide Detail** | Planning | Reading | Execution |
| **Ultimate Guide** | Master Library | Field Reference | Complete Guide |

---

## Mobile-Only Features (Protected by FeatureFlags)

### AR Trail Scanner
```dart
if (FeatureFlags.isEnabled(AppFeature.arScanner)) {
  // Mobile only
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => ArTrailScannerScreen(),
  ));
} else {
  // Web users see this
  showDialog(context: context, builder: (_) => PlatformUnavailableScreen(
    featureName: 'AR Trail Scanner',
    message: 'Available on iOS and Android only',
  ));
}
```

### Group Sync (Bluetooth + GPS)
```dart
if (FeatureFlags.isEnabled(AppFeature.groupSync)) {
  // Requires Bluetooth + mobile sensors
  // Shows real-time team positions
} else {
  // Web: Feature unavailable
  // Shows why: Requires local Bluetooth hardware
}
```

### Emergency Contacts
```dart
if (FeatureFlags.isEnabled(AppFeature.emergencyContacts)) {
  // Mobile: One-tap SOS, automatic location sharing
} else {
  // Web: Manual contact list only
}
```

### Offline Maps
```dart
if (FeatureFlags.isEnabled(AppFeature.offlineRegions)) {
  // Mobile: Download & manage map regions
} else {
  // Web: Always requires internet connection
}
```

---

## Fallback UI for Web Users

### PlatformUnavailableScreen Widget

When web users try to access mobile-only features:

```dart
class PlatformUnavailableScreen extends StatelessWidget {
  final String featureName;
  final String message;
  final String? recommendation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smartphone, size: 80, color: Colors.grey),
          SizedBox(height: 24),
          Text(
            featureName,
            style: Theme.of(context).textTheme.headline5,
          ),
          SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
```

---

## HomeScreen: Smart Navigation

The HomeScreen adapts its bottom navigation bar:

```dart
List<Widget> _buildScreensForPlatform() {
  if (PlatformCapabilities.isWeb) {
    return [
      homeContent,
      MapScreen(),
      GuideScreen(),
      TripPlannerScreen(),      // Web has trip planning
      SettingsScreen(),
    ];
  }

  return [
    homeContent,
    MapScreen(),
    GuideScreen(),
    GearScreen(),                // Mobile has gear tracking
    SettingsScreen(),
  ];
}
```

---

## Data & Services Architecture

### What's Available Everywhere
- Trip planning (read on web, edit on mobile)
- Guide library
- Gear checklists
- Map viewing
- Weather forecasts
- Country explorer
- Analytics (read-only on web)

### Mobile-Only Services
- **ActivityTrackerService**: GPS tracking, metrics
- **GroupSyncService**: Bluetooth team sync
- **EmergencyContactService**: SOS alerts
- **OfflineRegionService**: Map downloads
- **OfflineWeatherService**: Cached predictions

---

## Configuration Example

To add a new screen with platform-aware messaging:

### Step 1: Add to EditionScreen enum
```dart
enum EditionScreen {
  // ... existing
  myNewScreen,  // Add here
}
```

### Step 2: Add copy to EditionCopy
```dart
EditionScreen.myNewScreen: EditionText(
  webTitle: 'Web-focused title',
  webSubtitle: 'Web-specific description',
  iosTitle: 'iOS-optimized title',
  iosSubtitle: 'iOS-specific description',
  mobileTitle: 'Mobile/Android title',
  mobileSubtitle: 'Mobile-specific description',
),
```

### Step 3: Wrap screen content
```dart
@override
Widget build(BuildContext context) {
  return EditionBannerForScreen(
    screen: EditionScreen.myNewScreen,
    child: myScreenContent,
  );
}
```

---

## Benefits of This System

✅ **Single Source of Truth**: All platform messaging in one config file
✅ **No Duplication**: EditionBannerForScreen eliminates repeated if/else blocks
✅ **Easy to Maintain**: Change messages in one place, reflected everywhere
✅ **Consistent UX**: All screens follow same pattern
✅ **Future-Proof**: Easy to add new editions (e.g., tablet, web-lite)
✅ **A/B Testing Ready**: Can swapEditionCopy implementations
✅ **Localizable**: EditionCopy can read from localization files

---

## Best Practices

### ❌ Don't
```dart
// Scattered platform checks throughout code
if (PlatformCapabilities.isWeb) {
  title = 'Research';
} else if (PlatformCapabilities.isIOS) {
  title = 'Navigate';
} else {
  title = 'Track';
}
```

### ✅ Do
```dart
// Centralized, reusable
EditionBannerForScreen(
  screen: EditionScreen.myScreen,
  child: content,
)
```

### ❌ Don't
```dart
// Feature checks scattered in multiple places
if (PlatformCapabilities.isMobile) {
  showAROption();
}
// ... later in code
if (!PlatformCapabilities.isWeb) {
  enableARScanner();
}
```

### ✅ Do
```dart
// Single gate per feature
if (FeatureFlags.isEnabled(AppFeature.arScanner)) {
  // All AR functionality here
}
```

---

## Testing Platform-Specific Behavior

### On Web
- Visit localhost:port (from `flutter run -d chrome`)
- Verify edition banners show "Web" message
- Verify mobile-only features show unavailable screen
- Verify offline features disabled

### On iOS
- Run on simulator or device
- Verify edition banners show "iOS" message
- Verify all features available
- Verify Touch ID/Face ID integration works

### On Android
- Run on emulator (pixel_7) or physical device
- Verify edition banners show "MOBILE"/"APP" message
- Verify all features available
- Verify GPS, Bluetooth working

---

## Future Enhancements

Possible edition variations:
- **tablet**: iPad-specific layouts
- **web-lite**: Simplified web version
- **beta**: Beta feature flags for testers
- **pro**: Premium tier with extra features

Just add to EditionScreen enum and EditionCopy!

---

**Status**: ✅ Implementation Complete
**Screens Configured**: 15 (all major screens)
**Runtime Detection**: Working
**Feature Gating**: Active
**Messaging**: Centralized
