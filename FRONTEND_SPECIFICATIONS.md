# Dravik Frontend - Complete Specifications

## 🎯 Project Overview
**Dravik** is a multi-platform Flutter travel/trekking app with platform-differentiated experiences:
- **Web**: Discover & Plan (research-focused)
- **iOS**: Polished Mobile UX
- **Android**: Full Field Operations (advanced features)

---

## 📋 Environment Setup

### Prerequisites
```bash
Flutter 3.0+
Dart 3.0+
Xcode 14+ (for iOS/macOS)
Android SDK (for Android)
```

### Configuration Files

#### `.env` (Required)
```bash
# Supabase Backend Configuration
SUPABASE_URL=https://doiamxmhtbejfylbioky.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvaWFteG1odGJlamZ5bGJpb2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NDcyOTAsImV4cCI6MjA2NzIyMzI5MH0.qewM7z1o5YPViUSArsvLTJnYvGL-pKq0bTybxD3gTHw
```

#### `pubspec.yaml` (Dependencies)
```yaml
name: dravik
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  # Framework & UI
  flutter:
    sdk: flutter
  get: ^4.6.6                      # State management
  
  # Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^10.0.0  # Encrypted credentials
  
  # Backend
  supabase_flutter: ^2.9.1         # Backend as a service
  http: ^1.4.0                     # HTTP requests
  
  # Maps & Location
  maplibre_gl: ^0.24.1             # Professional maps
  flutter_map: ^8.1.1              # Alternative mapping
  flutter_map_tile_caching: ^10.1.1 # Offline maps
  latlong2: ^0.9.1                 # Coordinates
  geolocator: ^14.0.2              # GPS
  flutter_compass: ^0.8.0          # Compass sensor
  
  # UI Components
  lottie: ^3.3.1                   # Animations
  flutter_html: ^3.0.0             # HTML rendering
  flutter_typeahead: ^5.2.0        # Smart search
  markdown: ^7.2.2                 # Markdown parsing
  
  # Media
  camera: ^0.11.0+2                # Photo/video (AR)
  audioplayers: ^6.5.0             # Sound effects
  flutter_tts: ^4.2.0              # Text to speech
  printing: ^5.13.1                # Print/PDF
  pdf: ^3.11.0                     # PDF generation
  
  # Sensors & Hardware
  sensors_plus: ^7.0.0             # Accelerometer/Gyro
  battery_plus: ^7.0.0             # Battery info
  flutter_blue_plus: 1.32.11       # Bluetooth
  vibration: ^3.1.3                # Haptic feedback
  
  # Connectivity
  connectivity_plus: ^7.0.0        # Network status
  
  # Permissions & Security
  permission_handler: ^12.0.1      # System permissions
  local_auth: ^3.0.0               # Biometric auth
  
  # Utilities
  path_provider: ^2.1.2            # File paths
  package_info_plus: ^8.3.1        # App info
  flutter_dotenv: ^6.0.0           # Environment loading
  uuid: ^4.5.1                     # ID generation
  intl: ^0.20.1                    # Localization
  url_launcher: ^6.3.1             # Open URLs
  vector_math: ^2.1.4              # Math utilities
```

---

## 🎨 Architecture Overview

```
lib/
├── main.dart                          # App initialization & error handling
├── theme_provider.dart                # Dark/Light mode state
├── constants.dart                     # App-wide constants
│
├── config/                           # Platform & Feature Configuration
│   ├── platform_capabilities.dart     # isWeb, isIOS, isAndroid, isMobile
│   ├── feature_flags.dart             # Feature availability by platform
│   └── edition_copy.dart              # Platform-specific messaging (15+ screens)
│
├── theme/
│   └── app_theme.dart                 # Material Design 3 themes (light/dark)
│
├── models/                           # Data Models (12 files)
│   ├── trip.dart                      # Trip itineraries & routes
│   ├── gear.dart                      # Equipment checklists
│   ├── weather.dart                   # Weather conditions
│   ├── weather_forecast.dart          # 7-day forecasts
│   ├── place_guide.dart               # AI travel guides
│   ├── country.dart                   # Country travel info
│   ├── emergency_contact.dart         # Emergency contacts
│   ├── achievement.dart               # User achievements
│   ├── ar_poi.dart                    # AR points of interest
│   ├── sync_member.dart               # Group members
│   ├── nominatim_result.dart          # Search results
│   └── enums.dart                     # Shared enumerations
│
├── services/                         # Business Logic (17 services)
│   ├── trip_planner_service.dart      # Trip/itinerary CRUD
│   ├── gear_service.dart              # Gear checklist management
│   ├── gear_service_pro.dart          # Advanced gear features
│   ├── weather_service.dart           # OpenWeather API integration
│   ├── weather_alert_service.dart     # Weather monitoring & alerts
│   ├── offline_weather_service.dart   # Cached weather predictions
│   ├── country_service.dart           # Country data & travel info
│   ├── place_guide_service.dart       # AI-powered tour guides
│   ├── group_sync_service.dart        # Real-time team coordination
│   ├── emergency_contact_service.dart # Emergency check-ins & alerts
│   ├── offline_guides_service.dart    # Cached guide content
│   ├── offline_region_service.dart    # Offline map management
│   ├── activity_tracker_service.dart  # GPS activity tracking
│   ├── analytics_service.dart         # Analytics events
│   ├── search_service.dart            # Global search (Nominatim)
│   ├── overpass_service.dart          # Overpass API for POIs
│   ├── secure_storage_service.dart    # Encrypted credential storage
│
├── screens/                          # 21 Screens (Platform-Aware)
│   ├── home_screen.dart               # Dashboard with bottom nav
│   │
│   ├── map_screen.dart                # Interactive trail maps
│   │   └── EditionBannerForScreen
│   │
│   ├── guide_screen.dart              # Trek guides library
│   ├── guide_screen_new.dart          # Alternative guide layout (Sliver-based)
│   ├── guide_detail_screen.dart       # Full guide reading view
│   │   ├── Markdown rendering
│   │   └── EditionBannerForScreen
│   │
│   ├── trip_planner_screen.dart       # Create & manage trips
│   ├── trip_detail_screen.dart        # Single trip editor
│   │   ├── Itinerary builder
│   │   ├── Route planning
│   │   └── EditionBannerForScreen
│   │
│   ├── gear_screen.dart               # Equipment checklists
│   ├── gear_screen_new.dart           # Tabbed gear interface
│   ├── checklist_detail_screen.dart   # Detailed checklist editor
│   │   └── EditionBannerForScreen
│   │
│   ├── weather_forecast_screen.dart   # 7-day forecasts & alerts
│   │   └── EditionBannerForScreen
│   │
│   ├── country_explorer_screen.dart   # World travel research
│   │   ├── Country cards & tabs
│   │   └── EditionBannerForScreen
│   │
│   ├── place_guide_screen.dart        # AI-powered tour assistant
│   │   ├── Chat interface
│   │   └── EditionBannerForScreen
│   │
│   ├── analytics_screen.dart          # Activity dashboards
│   │   ├── Stats & achievements
│   │   └── EditionBannerForScreen
│   │
│   ├── settings_screen.dart           # App configuration
│   │   ├── Theme, notifications, permissions
│   │   └── EditionBannerForScreen
│   │
│   ├── ultimate_guide_screen.dart     # Master guide library
│   │   └── EditionBannerForScreen
│   │
│   ├── emergency_guides_screen.dart   # First aid, survival, navigation
│   │   └── EditionBannerForScreen
│   │
│   ├── MOBILE-ONLY Screens (Protected by PlatformCapabilities)
│   ├── ar_trail_scanner_screen.dart   # AR trail visualization
│   ├── ar_trail_scanner_screen_v2.dart
│   ├── ar_trail_scanner_pro.dart      # Advanced AR with routing
│   │
│   ├── group_sync_screen.dart         # Real-time team tracking
│   │   (Requires Bluetooth + Sensors)
│   │
│   ├── emergency_contact_screen.dart  # Emergency SOS system
│   │   (Requires GPS + Phone capabilities)
│   │
│   ├── offline_regions_screen.dart    # Download maps for offline use
│   │   (Requires persistent storage)
│
├── widgets/                           # Reusable Components (5+)
│   ├── edition_banner.dart            # Visual platform badge component
│   │   ├── Gradient blue/green/orange
│   │   ├── Platform chip ("WEB"/"IOS"/"APP")
│   │   ├── Title & Subtitle
│   │   └── Configurable styling
│   │
│   ├── edition_banner_for_screen.dart # Smart banner wrapper
│   │   ├── Auto-detects platform (Web/iOS/Mobile)
│   │   ├── Auto-selects from EditionCopy config
│   │   ├── Replaces manual if/else platform checks
│   │   └── Used in 14 screens
│   │
│   ├── platform_unavailable_screen.dart # Mobile-only fallback UI
│   │   ├── Large icon display
│   │   ├── Feature explanation
│   │   ├── Platform recommendation
│   │   └── Upgrade prompt
│   │
│   ├── guide_card.dart                # Trek guide preview card
│   │   ├── Image, title, difficulty, duration
│   │   └── Tap to view detail
│   │
│   ├── search_bar.dart                # Global search input
│   │   ├── Suggestions support
│   │   └── Debounced search
│
├── utils/
│   └── supabase_utils.dart           # Backend connection helpers
│
└── data/                             # Optional: Local data files
```

---

## 🖥️ Screen Details (21 Screens)

### Core Navigation (Bottom Bar)
1. **HomeScreen** - Dashboard with 5+ quick-access cards
   - **Web Mode**: Discover trip ideas, research destinations
   - **Mobile Mode**: Daily activity summary, quick access to advanced features
   - Real-time activity metrics, weather alerts
   - Navigation to all major features

### Maps & Location
2. **MapScreen** - Interactive trail visualization
   - MapLibre GL + Flutter Map dual support
   - Real-time GPS tracking
   - Trail layers, POI markers, offline caching
   - EditionBannerForScreen: "Explore Trails" (web) vs "Track Adventure" (app)

### Guides & Learning
3. **GuideScreen** - Trek guides library with search
   - Markdown guide rendering
   - Difficulty/duration filtering
   - Web: discovery focus
   - EditionBannerForScreen: "Discover Treks" (web) vs "Learn Trails" (app)

4. **GuideScreenNew** - Sliver-based alternative with better performance
   - Same features with optimized scrolling

5. **GuideDetailScreen** - Full guide reading experience
   - Navigation steps, map embedding
   - Safety tips, estimated duration
   - EditionBannerForScreen: "Planning" (web) vs "Execution" (app)

6. **UltimateGuideScreen** - Master guide library
   - All guides in one searchable database
   - EditionBannerForScreen: "Master Library" (web) vs "Field Reference" (app)

7. **EmergencyGuidesScreen** - Critical knowledge
   - First Aid, Survival, Navigation guides
   - High-visibility design for emergencies
   - EditionBannerForScreen: "Safety Knowledge" (web) vs "Emergency Reference" (app)

### Trip Planning
8. **TripPlannerScreen** - Create & manage trips
   - Multi-day itinerary builder
   - Route optimization, duration calculations
   - EditionBannerForScreen: "Plan Trips" (web) vs "Organize Adventures" (app)

9. **TripDetailScreen** - Single trip editor
   - Per-day activity planning
   - Gear association, route mapping
   - Real-time sync to Supabase

### Gear Management
10. **GearScreen** - Equipment checklists
    - Categorized gear lists
    - Condition tracking, weight calculations
    - Trip association
    - EditionBannerForScreen: "Prepare" (web) vs "Pack Smart" (app)

11. **GearScreenNew** - Tabbed gear interface
    - Alternative layout with better UX

12. **ChecklistDetailScreen** - Detailed checklist editor
    - Item-by-item configuration
    - Condition ratings (new, good, worn, damaged)

### Weather
13. **WeatherForecastScreen** - Week forecasts & alerts
    - 7-day outlook with hourly details
    - Storm alerts, temperature trends
    - EditionBannerForScreen: "Weather Planning" (web) vs "Trail Conditions" (app)

### Travel Research
14. **CountryExplorerScreen** - World travel database
    - Country cards: climate, visa, culture, best season
    - Tabbed interface (Map, List, Details)
    - EditionBannerForScreen: "Discover Nations" (web) vs "Explore Countries" (app)

15. **PlaceGuideScreen** - AI travel assistant
    - Chat-based tour information
    - Location-based recommendations
    - EditionBannerForScreen: "Research Destinations" (web) vs "Get Tour Guide" (app)

### Analytics & Progress
16. **AnalyticsScreen** - Activity dashboards
    - Distance, elevation, time tracked
    - Achievement badges
    - Trend analysis
    - EditionBannerForScreen: "Your Stats" (web, read-only) vs "Performance Dashboard" (app)

### Settings
17. **SettingsScreen** - App configuration
    - Theme toggle, notification preferences
    - Permission management
    - Account, privacy, about
    - EditionBannerForScreen: always visible

---

### Mobile-Only Screens (Protected by FeatureFlags)

18. **ArTrailScannerScreen** - Real-time AR trail overlay
    - Camera-based trail visualization
    - GPS overlay on video feed
    - Waypoint markers in AR space

19. **ArTrailScannerScreenV2** - Improved AR implementation
    - Better performance, optimized for arm64

20. **ArTrailScannerPro** - Advanced AR with routing
    - Route planning in AR
    - Next-waypoint highlighting
    - Distance/bearing calculations

21. **GroupSyncScreen** - Real-time team tracking
    - Bluetooth mesh networking
    - Live team member positions
    - Group check-in system
    - Emergency contact broadcasting

22. **EmergencyContactScreen** - SOS system
    - One-tap emergency alerts
    - Automatic location sharing
    - SMS/phone integration
    - Health check-ins

23. **OfflineRegionsScreen** - Map downloading
    - Select & download regions
    - Storage management
    - Verification of offline data

---

## 🔧 Configuration System

### Platform Capabilities (`platform_capabilities.dart`)
```dart
class PlatformCapabilities {
  static bool get isWeb => kIsWeb;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);
}
```

### Feature Flags (`feature_flags.dart`)
```dart
enum AppFeature {
  arScanner,          // Mobile-only
  groupSync,          // Mobile-only
  offlineRegions,     // Mobile-only
  emergencyContacts,  // Mobile-only
  activityTracking,   // Mobile-only
  bluetoothTools,     // Mobile-only
  biometrics,         // Mobile-only
}

class FeatureFlags {
  static bool isEnabled(AppFeature feature) {
    // All mobile-only features return: 
    // PlatformCapabilities.isMobile
  }
}
```

### Edition Copy (`edition_copy.dart`)
Centralized platform-specific messaging for all screens:
```dart
enum EditionScreen {
  home, map, guide, gear, trip, weather,
  country, place, emergency, analytics, settings,
  // ... 15+ screens total
}

class EditionCopy {
  static EditionText forScreen(EditionScreen screen) {
    // Returns title/subtitle for Web/iOS/Mobile platform
  }
}
```

---

## 🎨 Theme System

### App Theme (`app_theme.dart`)
**Colors**:
- Primary: `#1A73E8` (Google Blue)
- Secondary: `#34A853` (Google Green)
- Accent/Warning: `#EA4335` (Google Red), `#FBBC04` (Yellow)
- Dark: `#0F1419`, Cards: `#1E1F26`

**Responsive Design**:
- Web: 1200px+ wide layouts, hover states
- Tablet: 600-1200px, multi-column
- Mobile: <600px, single column

**Material Design 3**:
- Dynamic color support (on Android 12+)
- Proper contrast ratios (WCAG AA)
- Dark mode with reduced motion support

---

## 📱 State Management

### GetX Framework
- Simple GetBuilder for local state
- GetxController for services
- Reactive properties with Obx()

### Local Storage
- **Hive**: Trip data, guides, offline cache
- **Secure Storage**: API credentials, auth tokens
- **Settings Box**: User preferences, tracking config

### Backend
- **Supabase**: Real-time sync, Auth, Storage
- Automatic conflict resolution
- Offline queuing built-in

---

## 🔐 Security Implementation

### Authentication
- Supabase JWT with auto-refresh
- Biometric unlock (local_auth)
- 2FA ready (in settings)

### Data Protection
- Encrypted Secure Storage (native platform vaults)
- SSL/TLS for all API calls
- No sensitive data in logs (release mode)

### Permissions
- Runtime permission requests (Android 6+, iOS 13+)
- Minimal permission footprint:
  - Location: GPS tracking only
  - Camera: AR features only
  - Bluetooth: Group sync only
  - Microphone: TTS feedback only

### Privacy
- No analytics collection by default
- User controls for crash reporting
- GDPR-ready data deletion

---

## 📊 Services Architecture

### Data Services
- **TripPlannerService**: CRUD operations, validation
- **GearService**: Checklist management, weight tracking
- **WeatherService**: Real-time + forecast API integration
- **CountryService**: Static country database

### Real-Time Services
- **GroupSyncService**: Bluetooth + Firebase sync
- **ActivityTrackerService**: GPS streaming, metrics aggregation
- **WeatherAlertService**: Push notifications for severe weather

### Offline Services
- **OfflineGuidesService**: Pre-cached markdown
- **OfflineWeatherService**: Cached historical data used for predictions
- **OfflineRegionService**: Map tile management

### Utility Services
- **SecureStorageService**: Wrapper for platform vaults
- **SearchService**: Nominatim geocoding + local cache
- **AnalyticsService**: Event tracking (Supabase or local)

---

## 🎁 Data Models (12 Models)

1. **Trip** (trip.dart)
   - Name, description, startDate, endDate
   - Route (coordinates), estimatedDuration
   - Gear list association, team members

2. **Gear** (gear.dart)
   - Name, category, weight, condition
   - Purchase date, estimated lifespan
   - Notes, photos, trip associations

3. **Weather** (weather.dart)
   - Temperature, humidity, pressure, wind
   - Conditions (sunny, rainy, cloudy, etc)
   - Visibility, UV index

4. **WeatherForecast** (weather_forecast.dart)
   - Hourly & daily forecasts
   - Alerts & warnings
   - Forecast generation timestamp

5. **PlaceGuide** (place_guide.dart)
   - Location coordinates
   - Description, highlights, best season
   - Estimated visit duration
   - AI-generated tour suggestions

6. **Country** (country.dart)
   - Name, boundaries (geojson)
   - Capital, population, languages, currency
   - Visa requirements, safety rating
   - Best trekking season, climate zone

7. **EmergencyContact** (emergency_contact.dart)
   - Name, phone, relationship
   - Primary vs backup designation
   - SOS active status

8. **Achievement** (achievement.dart)
   - Name, description, icon
   - Unlock criteria (distance, elevation, time)
   - Rarity level, points value

9. **ArPOI** (ar_poi.dart)
   - Latitude, longitude, altitude
   - Name, type (landmark, hazard, shelter)
   - Distance & bearing from user
   - AR visibility radius

10. **SyncMember** (sync_member.dart)
    - Member ID, name, connection status
    - Current GPS position, last update time
    - Battery level, signal strength

11. **NominatimResult** (nominatim_result.dart)
    - Display name, coordinates
    - Address components
    - Bounding box for maps

12. **Enums** (enums.dart)
    - GearCondition, TripDifficulty
    - WeatherCondition, CountryRegion
    - ArContainerType, EmergencyLevel

---

## 🚀 Running the App

```bash
# Install dependencies
flutter pub get

# Run on Web
flutter run -d chrome

# Run on Android (requires emulator/device)
flutter run

# Run on iOS (requires Mac + Xcode)
flutter run -d ios

# Run on macOS (desktop)
flutter run -d macos

# Build release
flutter build web
flutter build apk
flutter build ipa
```

---

## ✅ Checklist: Frontend Complete

- [x] All 21+ screens implemented
- [x] 17 services with full business logic
- [x] 12 data models with validation
- [x] Platform detection & capability gating
- [x] Feature flags for mobile-only features
- [x] Centralized edition copy (15+ screens)
- [x] 5+ reusable widgets
- [x] Material Design 3 theme system
- [x] Dark/light mode toggle
- [x] Offline support (maps, guides, weather)
- [x] Real-time sync (Supabase)
- [x] Secure credential storage
- [x] GPS activity tracking
- [x] Emergency features (mobile-only)
- [x] AR integration (mobile-only)
- [x] Group sync (mobile-only)
- [x] Analytics dashboard
- [x] Responsive design (web/mobile/tablet)
- [x] All dependencies installed
- [x] Environment configured (.env)
- [x] Error handling & logging
- [x] Permission management
- [x] Web build tested ✅
- [x] All compile errors fixed

---

## 📝 Notes

**Web Edition Focus**: Discovery and planning—research destinations, read guides, plan trips without field-specific tools.

**Mobile Edition Focus**: Full capabilities—track activities in real-time, use AR, share with team, respond to emergencies.

**iOS Edition**: Polished Apple-specific UX—native controls, haptic feedback, Bluetooth optimization.

---

**Frontend Status**: ✅ **PRODUCTION READY**
