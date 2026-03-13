# Dravik Frontend Developer Workflow Guide

## 📋 Before You Start

### Prerequisites
- Flutter 3.0+ installed
- Dart 3.0+ installed
- Xcode 14+ (for iOS/macOS)
- Android SDK (for Android)
- Supabase account with project initialized
- Chrome browser (for web testing)

### Initial Setup (One-Time)
```bash
# Clone/enter project
cd /Users/amishkumar/Projects/dravik

# Install dependencies
flutter pub get

# Create .env file from template
cp .env.example .env

# Edit .env with your Supabase credentials
nano .env
# OR set them:
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
```

---

## 🔄 Daily Development Workflow

### 1. Start Development Server

**Option A: Web (Recommended for UI work)**
```bash
flutter run -d chrome
```
- Opens Chrome window with hot reload
- Edit code, save file
- Hot reload (R) or hot restart (F5)
- Press Q to quit

**Option B: Android**
```bash
# First time: launch emulator
flutter emulators --launch pixel_7

# Then in another terminal
flutter run
```

**Option C: iOS (macOS only)**
```bash
flutter run -d ios
```

### 2. Edit Code
- All source files in `lib/`
- Changes auto-reload on save (hot reload)
- Large structural changes may need full rebuild (R)

### 3. Common Development Tasks

#### Adding a Screen
```bash
# 1. Create new file in lib/screens/
# 2. Import EditionBannerForScreen
# 3. Wrap content with:
EditionBannerForScreen(
  screen: EditionScreen.myNewScreen,  // Add to enum
  child: yourContent,
)

# 4. Update HomeScreen._buildScreensForPlatform()
# 5. Update bottom nav items
```

#### Adding a Service
```bash
# 1. Create lib/services/my_service.dart
# 2. Implement business logic
# 3. Consider singleton pattern for shared state
# 4. Use try-catch for error handling
# 5. Emit to Supabase if data needs syncing
```

#### Adding a Model
```bash
# 1. Create lib/models/my_model.dart
# 2. Add fromJson/toJson for Supabase sync
# 3. Add equality operators
# 4. Add copyWith method for immutability
```

#### Updating Copy (Platform Messages)
```dart
// In lib/config/edition_copy.dart
EditionScreen.myScreen: EditionText(
  webTitle: 'Research...',
  webSubtitle: '...',
  iosTitle: 'Use...',
  iosSubtitle: '...',
  mobileTitle: 'Track...',
  mobileSubtitle: '...',
),
```

#### Adding a Mobile-Only Feature
```dart
// In feature_flags.dart, add to enum:
enum AppFeature {
  // ... existing
  myNewFeature,  // Add here (auto mobile-only)
}

// In screen:
if (FeatureFlags.isEnabled(AppFeature.myNewFeature)) {
  // Feature code
} else {
  // Fallback for web
}
```

---

## 🔍 Debugging

### Enable Debug Logging
```dart
// Already configured in main.dart
// In development, use:
debugPrint('Message here');

// Logs appear in Flutter console, NOT in release builds
```

### Check Platform Detection
```dart
// Add to any widget's build method:
print('Is Web: ${PlatformCapabilities.isWeb}');
print('Is Mobile: ${PlatformCapabilities.isMobile}');
print('Platform: ${defaultTargetPlatform}');
```

### Inspect Local Storage
```dart
// In code or console:
final box = Hive.box('guides');
print('Guides count: ${box.length}');

final settingsBox = Hive.box('settings');
settingsBox.getAll().forEach((k, v) => print('$k: $v'));
```

### Test Feature Flags
```dart
// Temporarily override for testing:
// (Don't commit this!)
final isArAvailable = true; // Force override

// Check everywhere it's used:
if (FeatureFlags.isEnabled(AppFeature.arScanner)) { }
```

### Troubleshoot Supabase Connection
```dart
// In main.dart, Supabase init logs connection
// Check console for:
// "Supabase initialized" = success
// "Error" = check credentials in .env
```

---

## 🧪 Testing Approach

### Manual Testing Checklist (Per Screen)
```
Screen: MapScreen
☐ Loads on web
☐ Loads on iOS
☐ Loads on Android
☐ EditionBanner shows correct platform message
☐ Bottom nav works
☐ Back button works
☐ Permissions request works
☐ Offline fallback displays
☐ No console errors
```

### Test on Each Platform
```bash
# Web
flutter run -d chrome
# Test in Chrome DevTools (F12)
# Check responsive (toggle device toolbar)

# Android
flutter run
# Use logcat: flutter logs

# iOS (macOS only)
flutter run -d ios
# Console shows in Xcode
```

### Look for Warnings
```bash
# Yellow/orange messages during hot reload
# Blue messages are informational
# Red = errors that will crash
```

---

## 🚢 Build & Deploy

### Web
```bash
# Build for production
flutter build web --release

# Output: build/web/
# Deploy to Firebase Hosting, Netlify, etc.
```

### Android
```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
# Upload to Google Play Console
```

### iOS (macOS only)
```bash
# Build IPA
flutter build ipa --release

# Output: build/ios/ipa/
# Upload to TestFlight or App Store Connect
```

---

## 📁 File Organization Tips

### Recommended Structure
```
lib/
├── main.dart                  # Only: initialization & error handling
├── theme_provider.dart        # Only: dark mode state
├── constants.dart             # Only: constants

├── config/
│   ├── platform_capabilities.dart
│   ├── feature_flags.dart
│   └── edition_copy.dart

├── models/
│   └── *.dart                 # One file per model

├── services/
│   └── *.dart                 # One file per service

├── screens/
│   └── *.dart                 # One file per screen

├── widgets/
│   └── *.dart                 # Reusable components

├── theme/
│   └── app_theme.dart

├── utils/
│   └── *.dart                 # Helper functions

└── data/
    └── *.dart or .json        # Local data files
```

---

## 🎯 Common Coding Patterns

### Adding a New Screen
```dart
// 1. Create file: lib/screens/new_screen.dart
import 'package:flutter/material.dart';
import 'package:dravik/config/edition_copy.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Screen')),
      body: EditionBannerForScreen(
        screen: EditionScreen.newScreen,  // Add to enum!
        child: // ... your content
      ),
    );
  }
}
```

### Calling a Service
```dart
import 'package:dravik/services/trip_planner_service.dart';

// In widget:
final trips = await TripPlannerService().getTrips();
```

### Checking Platform
```dart
import 'package:dravik/config/platform_capabilities.dart';
import 'package:dravik/config/feature_flags.dart';

if (PlatformCapabilities.isWeb) {
  // Web-only UI
} else if (PlatformCapabilities.isMobile) {
  // Mobile/Android/iOS UI
}

if (FeatureFlags.isEnabled(AppFeature.arScanner)) {
  // AR-enabled devices only
}
```

### Accessing Storage
```dart
import 'package:hive_flutter/hive_flutter.dart';

final box = Hive.box('settings');
box.put('theme_dark', true);
final isDark = box.get('theme_dark', defaultValue: false);
```

### Making Network Call
```dart
// Services already handle this!
final data = await WeatherService().getWeatherForecast(lat, lng);
// API call → Hive cache → return
```

---

## ⚠️ Common Issues & Fixes

### Hot Reload Not Working
```bash
# Solution: Hot restart
R  # Full rebuild, preserves app state
```

### Build Failures
```bash
# Clear build cache
flutter clean

# Get fresh dependencies
flutter pub get

# Rebuild
flutter run
```

### Supabase Connection Error
```
# Check:
1. .env file exists
2. Credentials are correct
3. Supabase project is active
4. Internet connection works
```

### Emulator Won't Start
```bash
# List emulators
flutter emulators

# Launch specific
flutter emulators --launch pixel_7

# Or use Android Studio
```

### iOS Build Issues (macOS only)
```bash
# Update pods
cd ios && pod repo update && cd ..

# Clean Xcode
flutter clean
rm ios/Podfile.lock

# Rebuild
flutter run -d ios
```

---

## 📊 Performance Tips

### Hot Reload Best Practices
- ✅ DO: Change UI properties, constants, strings
- ✅ DO: Modify widget build methods
- ❌ DON'T: Change main() or initState
- ❌ DON'T: Add/remove fields without restart
- ❌ DON'T: Modify async initializers

### Optimize Build Time
- Use `--target-platform` to build for one platform
- Use `flutter build --split-debug-info` for smaller APKs
- Consider using `--cached` flag for faster builds

### Monitor App Performance
- Use Flutter DevTools: `flutter pub global run devtools`
- Check Performance tab for frame drops
- Monitor memory with Memory tab

---

## 🔑 Tips & Tricks

### Keyboard Shortcuts (Chrome DevTools)
- `R` - Hot reload
- `F5` - Full rebuild
- `D` - Toggle debug flags
- `P` - Toggle performance overlay
- `I` - Toggle widget inspector

### Theme Toggle
```dart
// In SettingsScreen - one-liner
GestureDetector(
  onTap: () => themeNotifier.value = !themeNotifier.value,
  child: Icon(Icons.brightness_4),
)
```

### Quick Test Platform Message
```dart
// Add temporary debug widget:
Text(
  'Platform: ${PlatformCapabilities.isWeb ? "WEB" : "MOBILE"}',
  style: const TextStyle(color: Colors.red, fontSize: 20),
)
```

### View All Screens
```bash
# In lib/screens/, all 21+ screens are there:
ls -la lib/screens/ | grep ".dart"
```

---

## 📚 Resources

**Inside Project**:
- `FRONTEND_SPECIFICATIONS.md` - Complete feature docs
- `FRONTEND_QUICK_REFERENCE.md` - Code snippets & patterns
- `PLATFORM_DIFFERENTIATION.md` - Platform system details
- `FRONTEND_IMPLEMENTATION_CHECKLIST.md` - Status & features

**External**:
- Flutter Docs: https://flutter.dev/docs
- Dart Docs: https://dart.dev/guides
- Supabase Flutter: https://supabase.com/docs/reference/flutter
- GetX: https://github.com/jonataslaw/getx/wiki
- Material Design 3: https://m3.material.io

---

## 🚀 Deployment Checklist

Before deploying to production:

```bash
# 1. Clean build
flutter clean

# 2. Test on all platforms
flutter run -d chrome    # Web
flutter run               # Android
flutter run -d ios       # iOS (macOS)

# 3. Check for errors
flutter analyze

# 4. Build release
flutter build web/apk/ipa --release

# 5. Version bump
# Edit pubspec.yaml: version: 1.0.0+2

# 6. Commit & push
git add .
git commit -m "Release v1.0.0"
git push
```

---

**Frontend Development Guide Ready!**
Last updated: March 9, 2026
