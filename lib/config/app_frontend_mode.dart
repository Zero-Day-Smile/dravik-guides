class AppFrontendMode {
  const AppFrontendMode._();

  // Safe migration switch for the Flutter app frontend.
  // false => current stable frontend in lib/screens
  // true  => new frontend in lib/app_frontend_v2
  static const bool useV2 = true;
}
