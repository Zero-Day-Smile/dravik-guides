import 'platform_capabilities.dart';

enum AppFeature {
  arScanner,
  groupSync,
  offlineRegions,
  emergencyContacts,
  activityTracking,
  bluetoothTools,
  biometrics,
}

class FeatureFlags {
  const FeatureFlags._();

  static bool isEnabled(AppFeature feature) {
    switch (feature) {
      case AppFeature.arScanner:
      case AppFeature.groupSync:
      case AppFeature.offlineRegions:
      case AppFeature.emergencyContacts:
      case AppFeature.activityTracking:
      case AppFeature.bluetoothTools:
      case AppFeature.biometrics:
        return PlatformCapabilities.isMobile;
    }
  }
}
