# dravik_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


## Build & Run

```bash
flutter pub get
flutter run
```

## Security Hardening

- **HTTPS-only networking**: Android manifest sets `android:usesCleartextTraffic="false"` to block cleartext HTTP at the OS level.
- **Screenshot protection**: `FLAG_SECURE` enabled on MainActivity to prevent screenshots and screen recording of sensitive AR/map content.
- **Backups disabled**: `android:allowBackup="false"` to prevent OS backups of app data (sensitive tokens, GPS history, etc.).
- **Release config required**: In release builds, the app refuses to start without `.env` values for `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Copy `.env.example` to `.env` and provide production values.
- **Code shrinking**: Release builds enable R8 minification and resource shrinking. ProGuard rules at `android/app/proguard-rules.pro` keep essential Flutter, MapLibre, and Supabase entry points.
- **Secure storage**: `flutter_secure_storage` v10 is available via `SecureStorageService` for storing tokens securely with hardware-backed encryption on Android.
- **Permissions minimized**: Removed broad `WRITE_EXTERNAL_STORAGE`. App now uses scoped storage for all file operations.
- **Release logging disabled**: `debugPrint` is silenced in release builds to prevent leaking sensitive data (coordinates, user IDs, API keys) to logcat.

### Recommended secure release build

```bash
# Obfuscate Dart symbols and split debug info for smaller, harder-to-reverse APKs
flutter build apk --release \
	--obfuscate \
	--split-debug-info=build/symbols
```

Keep the generated `build/symbols` folder in a safe place to symbolicate crashes.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
