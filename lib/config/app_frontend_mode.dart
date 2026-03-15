class AppFrontendMode {
  const AppFrontendMode._();

  // Exact mode: render the original web frontend in-app via WebView.
  // This gives true UI/behavior parity with the attached frontend.
  static const bool useExactWebFrontend = true;

  // Safe migration switch for the Flutter app frontend.
  // false => current stable frontend in lib/screens
  // true  => new frontend in lib/app_frontend_v2
  static const bool useV2 = true;
}
