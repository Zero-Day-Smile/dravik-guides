import 'package:flutter/foundation.dart';

class PlatformCapabilities {
  const PlatformCapabilities._();

  static bool get isWeb => kIsWeb;
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);
}
