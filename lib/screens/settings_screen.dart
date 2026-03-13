import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:dravik/theme_provider.dart';
import 'map_screen.dart'; // Added import for MapScreen
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

// Enums
enum TrailColorScheme { difficultyBased, uniform }

enum HapticStrength { low, medium, high }

enum AlertSound { defaultSound, customSound }

enum LocationAccuracy { low, medium, high }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = supabase.Supabase.instance.client;
  final _localAuth = LocalAuthentication();

  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _offlineMapsDownloaded = false;
  bool _locationSharingEnabled = true;
  bool _sosModeEnabled = true;
  bool _gearChecklistAutoUpdate = true;
  bool _biometricAuthEnabled = false;
  bool _lowBatteryMode = false;
  bool _tripPlannerSync = true;
  bool _offlineGuideSync = true;
  String _offlineDownloadStatus = 'Checking...';
  String _selectedLanguage = 'English';
  HapticStrength _hapticStrength = HapticStrength.medium;
  String _trailDiaryInterval = '10 minutes';
  String _weatherAlertSensitivity = 'High';
  AlertSound _alertSound = AlertSound.defaultSound;
  LocationAccuracy _locationAccuracy = LocationAccuracy.medium;
  TrailColorScheme _trailColorScheme = TrailColorScheme.difficultyBased;
  double _transportBudget = 10.0;
  Map<String, bool> _featureFlags = {'showSplashSettings': false};
  bool _isOnline = true;

  supabase.User? _user;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _secondaryContactController = TextEditingController();

  Box? settingsBox;
  Box? userBox;
  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;
  String _appVersion = '1.0.0';
  String? _savedContact;
  String? _savedSecondaryContact;

  bool get isPremium => _user?.userMetadata?['isPremium'] == true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      setState(() => _isOnline =
          result.isNotEmpty && result.any((r) => r != ConnectivityResult.none));
    });
    _supabase.auth.onAuthStateChange.listen((_) => _checkUser());
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _secondaryContactController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      await Hive.initFlutter();
      settingsBox = await Hive.openBox('settings');
      userBox = await Hive.openBox('user');
      _loadSettings();
      _checkUser();
      _checkOfflineStatus();
      _loadAppInfo();
      if (!settingsBox!.containsKey('language')) {
        _selectedLanguage =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
                    'hi'
                ? 'Hindi'
                : 'English';
      }
    } catch (e) {
      _showSnack('Failed to load settings', true);
    }
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _loadSettings() async {
    if (settingsBox == null) return;
    setState(() {
      _isDarkMode = settingsBox!.get('darkMode', defaultValue: false);
      _notificationsEnabled =
          settingsBox!.get('notifications', defaultValue: true);
      _locationSharingEnabled =
          settingsBox!.get('locationSharing', defaultValue: true);
      _sosModeEnabled = settingsBox!.get('sosModeEnabled', defaultValue: true);
      _gearChecklistAutoUpdate =
          settingsBox!.get('gearChecklistAutoUpdate', defaultValue: true);
      _biometricAuthEnabled =
          settingsBox!.get('biometricAuthEnabled', defaultValue: false);
      _lowBatteryMode = settingsBox!.get('lowBatteryMode', defaultValue: false);
      _tripPlannerSync =
          settingsBox!.get('tripPlannerSync', defaultValue: true);
      _offlineGuideSync =
          settingsBox!.get('offlineGuideSync', defaultValue: true);
      _selectedLanguage =
          settingsBox!.get('language', defaultValue: _selectedLanguage);
      _hapticStrength = HapticStrength.values[settingsBox!
          .get('hapticStrength', defaultValue: HapticStrength.medium.index)];
      _trailDiaryInterval =
          settingsBox!.get('trailDiaryInterval', defaultValue: '10 minutes');
      _weatherAlertSensitivity =
          settingsBox!.get('weatherAlertSensitivity', defaultValue: 'High');
      _alertSound = AlertSound.values[settingsBox!
          .get('alertSound', defaultValue: AlertSound.defaultSound.index)];
      _locationAccuracy = LocationAccuracy.values[settingsBox!.get(
          'locationAccuracy',
          defaultValue: LocationAccuracy.medium.index)];
      _trailColorScheme = TrailColorScheme.values[settingsBox!.get(
          'trailColorScheme',
          defaultValue: TrailColorScheme.difficultyBased.index)];
      _transportBudget =
          settingsBox!.get('transportBudget', defaultValue: 10.0);
      _featureFlags = settingsBox!
          .get('featureFlags', defaultValue: {'showSplashSettings': false});
      _savedContact = settingsBox!.get('emergency_contact');
      _savedSecondaryContact = settingsBox!.get('secondary_emergency_contact');
    });
  }

  Future<void> _checkUser() async {
    setState(() => _user = _supabase.auth.currentUser);
    if (_user != null && userBox != null) {
      await userBox!.put('email', _user!.email);
      await userBox!
          .put('isPremium', _user!.userMetadata?['isPremium'] ?? false);
    }
  }

  Future<void> _checkOfflineStatus() async {
    final store = FMTCStore('DravikMaps');
    try {
      final stats = await store.stats.size;
      setState(() {
        _offlineMapsDownloaded = stats > 0;
        _offlineDownloadStatus = _offlineMapsDownloaded
            ? 'Maps Downloaded ($stats tiles)'
            : 'No Maps Downloaded';
      });
    } catch (e) {
      setState(() => _offlineDownloadStatus = 'Error checking offline status');
    }
  }

  void _vibrate() {
    switch (_hapticStrength) {
      case HapticStrength.low:
        Vibration.vibrate(duration: 10);
        break;
      case HapticStrength.medium:
        Vibration.vibrate(duration: 30);
        break;
      case HapticStrength.high:
        Vibration.vibrate(duration: 70);
        break;
    }
  }

  Future<void> _toggleTheme(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('darkMode', value);
    setState(() => _isDarkMode = value);
    themeNotifier.value = value;
    _vibrate();
  }

  Future<void> _toggleNotifications(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('notifications', value);
    setState(() => _notificationsEnabled = value);
    _vibrate();
  }

  Future<void> _toggleLocationSharing(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('locationSharing', value);
    setState(() => _locationSharingEnabled = value);
    _vibrate();
  }

  Future<void> _toggleSosMode(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('sosModeEnabled', value);
    setState(() => _sosModeEnabled = value);
    _vibrate();
  }

  Future<void> _toggleGearChecklistAutoUpdate(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('gearChecklistAutoUpdate', value);
    setState(() => _gearChecklistAutoUpdate = value);
    _vibrate();
  }

  Future<void> _toggleBiometricAuth(bool value) async {
    if (settingsBox == null) return;
    if (value) {
      final canUseBiometrics = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canUseBiometrics || !isSupported) {
        _showSnack('Biometric authentication not available', true);
        return;
      }
    }
    await settingsBox!.put('biometricAuthEnabled', value);
    setState(() => _biometricAuthEnabled = value);
    _vibrate();
  }

  Future<void> _toggleLowBatteryMode(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('lowBatteryMode', value);
    setState(() => _lowBatteryMode = value);
    _vibrate();
  }

  Future<void> _toggleTripPlannerSync(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('tripPlannerSync', value);
    setState(() => _tripPlannerSync = value);
    _vibrate();
  }

  Future<void> _toggleOfflineGuideSync(bool value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('offlineGuideSync', value);
    setState(() => _offlineGuideSync = value);
    _vibrate();
  }

  Future<void> _setTrailColorScheme(TrailColorScheme value) async {
    if (settingsBox == null) return;
    await settingsBox!.put('trailColorScheme', value.index);
    setState(() => _trailColorScheme = value);
    _vibrate();
  }

  Future<void> _clearCache() async {
    if (settingsBox == null) return;
    final guideBox = await Hive.openBox('guides');
    final searchBox = await Hive.openBox('search_cache');
    final recentBox = await Hive.openBox('recent_searches');
    await Future.wait([guideBox.clear(), searchBox.clear(), recentBox.clear()]);
    _vibrate();
    _showSnack('Cache cleared ✅');
  }

  Future<void> _resetSettings() async {
    if (settingsBox == null) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text('This will erase all settings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await settingsBox!.clear();
              await _loadSettings();
              if (mounted) {
                Navigator.pop(context);
              }
              _vibrate();
              _showSnack('All settings reset');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadOfflineMaps() async {
    if (!_isOnline) {
      _showSnack('⚠️ No internet connection', true, _downloadOfflineMaps);
      return;
    }
    setState(() => _offlineDownloadStatus =
        'Please navigate to Map Screen to download regions');
    _vibrate();
    _showSnack('Navigate to Map Screen to download regions');
  }

  Future<void> _requestPermissions() async {
    final status = await [Permission.location, Permission.sms].request();
    final ok = status[Permission.location]!.isGranted &&
        status[Permission.sms]!.isGranted;
    _showSnack(
        ok ? 'Permissions granted for SOS' : 'SOS limited without permissions',
        !ok);
    _vibrate();
  }

  Future<void> _login() async {
    if (!_isOnline) {
      _showSnack('⚠️ No internet connection', true, _login);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AuthDialogWidget(
        title: 'Login',
        emailController: _emailController,
        passwordController: _passwordController,
        onSubmit: (email, pw, setErr) async {
          try {
            await _supabase.auth.signInWithPassword(email: email, password: pw);
            _emailController.clear();
            _passwordController.clear();
            if (mounted) {
              Navigator.pop(context);
            }
            _checkUser();
            _showSnack('Logged in ✅');
          } catch (e) {
            setErr('Login failed: $e');
          }
        },
        onForgotPassword: _forgotPassword,
      ),
    );
  }

  Future<void> _register() async {
    if (!_isOnline) {
      _showSnack('⚠️ No internet connection', true);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AuthDialogWidget(
        title: 'Register',
        emailController: _emailController,
        passwordController: _passwordController,
        onSubmit: (email, pw, setErr) async {
          try {
            await _supabase.auth.signUp(email: email, password: pw);
            _emailController.clear();
            _passwordController.clear();
            if (mounted) {
              Navigator.pop(context);
            }
            _checkUser();
            _showSnack('Registered ✅');
          } catch (e) {
            setErr('Registration failed: $e');
          }
        },
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (!_isOnline) {
      _showSnack('⚠️ No internet connection', true, _forgotPassword);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AuthDialogWidget(
        title: 'Reset Password',
        emailController: _emailController,
        passwordController: _passwordController,
        onSubmit: (email, _, setErr) async {
          try {
            await _supabase.auth.resetPasswordForEmail(email);
            _emailController.clear();
            if (mounted) {
              Navigator.pop(context);
            }
            _showSnack('Reset link sent – check your inbox');
          } catch (e) {
            setErr('Reset failed: $e');
          }
        },
      ),
    );
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    setState(() => _user = null);
    _showSnack('Logged out');
  }

  void _showSnack(String msg, [bool isError = false, VoidCallback? retry]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
        action: retry != null
            ? SnackBarAction(label: 'Retry', onPressed: retry)
            : null,
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Premium Features'),
        content:
            const Text('Upgrade to unlock AI Guide, AR Compass, and more.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Theme(
          data: ThemeData(
            primarySwatch: Colors.green,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green[700],
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.all(Colors.greenAccent),
              trackColor: WidgetStateProperty.all(Colors.green[200]),
            ),
          ),
          child: Scaffold(
            backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
            appBar: AppBar(
              title: const Text('Settings'),
              backgroundColor:
                  _isDarkMode ? Colors.green[900] : Colors.green[700],
            ),
            body: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                const EditionBannerForScreen(screen: EditionScreen.settings),
                ExpansionTile(
                  title: Text('General',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    GeneralSettingsWidget(
                      isDarkMode: _isDarkMode,
                      notificationsEnabled: _notificationsEnabled,
                      locationSharingEnabled: _locationSharingEnabled,
                      offlineDownloadStatus: _offlineDownloadStatus,
                      offlineMapsDownloaded: _offlineMapsDownloaded,
                      transportBudget: _transportBudget,
                      toggleTheme: _toggleTheme,
                      toggleNotifications: _toggleNotifications,
                      toggleLocationSharing: _toggleLocationSharing,
                      clearCache: _clearCache,
                      downloadOfflineMaps: _downloadOfflineMaps,
                      setTransportBudget: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('transportBudget', val);
                          setState(() => _transportBudget = val);
                          _vibrate();
                        }
                      },
                      vibrate: _vibrate,
                      showSnack: _showSnack,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('Account',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    AccountSettingsWidget(
                      user: _user,
                      isDarkMode: _isDarkMode,
                      login: _login,
                      register: _register,
                      logout: _logout,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('Adventure Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    AdventureSettingsWidget(
                      isDarkMode: _isDarkMode,
                      sosModeEnabled: _sosModeEnabled,
                      gearChecklistAutoUpdate: _gearChecklistAutoUpdate,
                      biometricAuthEnabled: _biometricAuthEnabled,
                      lowBatteryMode: _lowBatteryMode,
                      tripPlannerSync: _tripPlannerSync,
                      offlineGuideSync: _offlineGuideSync,
                      selectedLanguage: _selectedLanguage,
                      hapticStrength: _hapticStrength,
                      trailDiaryInterval: _trailDiaryInterval,
                      weatherAlertSensitivity: _weatherAlertSensitivity,
                      alertSound: _alertSound,
                      locationAccuracy: _locationAccuracy,
                      trailColorScheme: _trailColorScheme,
                      isPremium: isPremium,
                      isOnline: _isOnline,
                      toggleSosMode: _toggleSosMode,
                      toggleGearChecklistAutoUpdate:
                          _toggleGearChecklistAutoUpdate,
                      toggleBiometricAuth: _toggleBiometricAuth,
                      toggleLowBatteryMode: _toggleLowBatteryMode,
                      toggleTripPlannerSync: _toggleTripPlannerSync,
                      toggleOfflineGuideSync: _toggleOfflineGuideSync,
                      setTrailColorScheme: _setTrailColorScheme,
                      requestPermissions: _requestPermissions,
                      setLanguage: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('language', val);
                          setState(() => _selectedLanguage = val);
                          _vibrate();
                        }
                      },
                      setHapticStrength: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('hapticStrength', val.index);
                          setState(() => _hapticStrength = val);
                          _vibrate();
                        }
                      },
                      setTrailDiaryInterval: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('trailDiaryInterval', val);
                          setState(() => _trailDiaryInterval = val);
                          _vibrate();
                        }
                      },
                      setWeatherAlertSensitivity: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!
                              .put('weatherAlertSensitivity', val);
                          setState(() => _weatherAlertSensitivity = val);
                          _vibrate();
                        }
                      },
                      setAlertSound: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('alertSound', val.index);
                          setState(() => _alertSound = val);
                          SystemSound.play(SystemSoundType.alert);
                          _vibrate();
                        }
                      },
                      setLocationAccuracy: (val) async {
                        if (settingsBox != null) {
                          await settingsBox!.put('locationAccuracy', val.index);
                          setState(() => _locationAccuracy = val);
                          _vibrate();
                        }
                      },
                      saveEmergencyContact: (primary, secondary) async {
                        if (settingsBox != null) {
                          if (primary.isNotEmpty &&
                              !RegExp(r'^\d{10}$').hasMatch(primary)) {
                            _showSnack('Enter a valid primary number', true);
                            return;
                          }
                          if (secondary.isNotEmpty &&
                              !RegExp(r'^\d{10}$').hasMatch(secondary)) {
                            _showSnack('Enter a valid secondary number', true);
                            return;
                          }
                          await settingsBox!.put('emergency_contact',
                              primary.isEmpty ? null : primary);
                          await settingsBox!.put('secondary_emergency_contact',
                              secondary.isEmpty ? null : secondary);
                          setState(() {
                            _savedContact = primary.isEmpty ? null : primary;
                            _savedSecondaryContact =
                                secondary.isEmpty ? null : secondary;
                          });
                          _contactController.clear();
                          _secondaryContactController.clear();
                          _vibrate();
                          _showSnack('Contacts saved');
                        }
                      },
                      showPremiumDialog: _showPremiumDialog,
                      contactController: _contactController,
                      secondaryContactController: _secondaryContactController,
                      savedContact: _savedContact,
                      savedSecondaryContact: _savedSecondaryContact,
                      showSnack: _showSnack,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('Map Settings',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    MapSettingsWidget(
                      isDarkMode: _isDarkMode,
                      offlineDownloadStatus: _offlineDownloadStatus,
                      offlineMapsDownloaded: _offlineMapsDownloaded,
                      trailColorScheme: _trailColorScheme,
                      navigateToMap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                      downloadOfflineMaps: _downloadOfflineMaps,
                      setTrailColorScheme: _setTrailColorScheme,
                      showSnack: _showSnack,
                      vibrate: _vibrate,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('Premium Features',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    PremiumSettingsWidget(
                      isDarkMode: _isDarkMode,
                      showPremiumDialog: _showPremiumDialog,
                    ),
                  ],
                ),
                ExpansionTile(
                  title: Text('About',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black)),
                  initiallyExpanded: true,
                  children: [
                    AboutSettingsWidget(
                      isDarkMode: _isDarkMode,
                      appVersion: _appVersion,
                      resetSettings: _resetSettings,
                      featureFlags: _featureFlags,
                      showSnack: _showSnack,
                      vibrate: _vibrate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Reusable Widgets
class GeneralSettingsWidget extends StatelessWidget {
  const GeneralSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.locationSharingEnabled,
    required this.offlineDownloadStatus,
    required this.offlineMapsDownloaded,
    required this.transportBudget,
    required this.toggleTheme,
    required this.toggleNotifications,
    required this.toggleLocationSharing,
    required this.clearCache,
    required this.downloadOfflineMaps,
    required this.setTransportBudget,
    required this.vibrate,
    required this.showSnack,
  });

  final bool isDarkMode,
      notificationsEnabled,
      locationSharingEnabled,
      offlineMapsDownloaded;
  final String offlineDownloadStatus;
  final double transportBudget;
  final void Function(bool) toggleTheme,
      toggleNotifications,
      toggleLocationSharing;
  final VoidCallback clearCache, downloadOfflineMaps, vibrate;
  final void Function(double) setTransportBudget;
  final void Function(String, [bool, VoidCallback?]) showSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Dark Mode',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          value: isDarkMode,
          onChanged: toggleTheme,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          title: Text('Notifications',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Weather, SOS, and group alerts'),
          value: notificationsEnabled,
          onChanged: toggleNotifications,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          title: Text('Location Sharing',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Share location with contacts / group'),
          value: locationSharingEnabled,
          onChanged: toggleLocationSharing,
          activeThumbColor: Colors.greenAccent,
        ),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.redAccent),
          title: Text('Clear Cache',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          onTap: clearCache,
        ),
        ListTile(
          title: Text('Offline Download Status',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(offlineDownloadStatus),
          trailing: offlineMapsDownloaded
              ? const Icon(Icons.check_circle, color: Colors.green)
              : ElevatedButton(
                  onPressed: downloadOfflineMaps,
                  child: const Text('Download Maps')),
        ),
        ListTile(
          leading: const Icon(Icons.directions_bus, color: Colors.green),
          title: Text('Transport Budget',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text('\$${transportBudget.toStringAsFixed(0)}'),
          onTap: () {
            double tempBudget = transportBudget;
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Set Transport Budget'),
                content: StatefulBuilder(
                  builder: (ctx, setStateSB) => Slider(
                    value: tempBudget,
                    min: 0,
                    max: 50,
                    divisions: 10,
                    label: '\$${tempBudget.toStringAsFixed(0)}',
                    onChanged: (val) => setStateSB(() => tempBudget = val),
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      setTransportBudget(tempBudget);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class AccountSettingsWidget extends StatelessWidget {
  const AccountSettingsWidget({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.login,
    required this.register,
    required this.logout,
  });

  final supabase.User? user;
  final bool isDarkMode;
  final VoidCallback login, register, logout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (user == null)
          ListTile(
            leading: const Icon(Icons.login, color: Colors.green),
            title: Text('Login',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: login,
          ),
        if (user == null)
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.green),
            title: Text('Register',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: register,
          ),
        if (user != null)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text('Logout',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: logout,
          ),
      ],
    );
  }
}

class MapSettingsWidget extends StatelessWidget {
  const MapSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.offlineDownloadStatus,
    required this.offlineMapsDownloaded,
    required this.trailColorScheme,
    required this.navigateToMap,
    required this.downloadOfflineMaps,
    required this.setTrailColorScheme,
    required this.showSnack,
    required this.vibrate,
  });

  final bool isDarkMode, offlineMapsDownloaded;
  final String offlineDownloadStatus;
  final TrailColorScheme trailColorScheme;
  final VoidCallback navigateToMap, downloadOfflineMaps, vibrate;
  final void Function(TrailColorScheme) setTrailColorScheme;
  final void Function(String, [bool, VoidCallback?]) showSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.map, color: Colors.green),
          title: Text('View Map',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          onTap: navigateToMap,
        ),
        ListTile(
          title: Text('Trail Color Scheme',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(trailColorScheme == TrailColorScheme.difficultyBased
              ? 'Difficulty-Based'
              : 'Uniform'),
          leading: const Icon(Icons.color_lens, color: Colors.green),
          onTap: () async {
            final selected = await showModalBottomSheet<TrailColorScheme>(
              context: context,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              builder: (_) => ListView(
                shrinkWrap: true,
                children: TrailColorScheme.values
                    .map((scheme) => ListTile(
                          title: Text(
                            scheme == TrailColorScheme.difficultyBased
                                ? 'Difficulty-Based'
                                : 'Uniform',
                            style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black),
                          ),
                          onTap: () => Navigator.pop(context, scheme),
                        ))
                    .toList(),
              ),
            );
            if (selected != null) {
              setTrailColorScheme(selected);
              showSnack('Trail color scheme updated');
            }
          },
        ),
      ],
    );
  }
}

class AdventureSettingsWidget extends StatelessWidget {
  const AdventureSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.sosModeEnabled,
    required this.gearChecklistAutoUpdate,
    required this.biometricAuthEnabled,
    required this.lowBatteryMode,
    required this.tripPlannerSync,
    required this.offlineGuideSync,
    required this.selectedLanguage,
    required this.hapticStrength,
    required this.trailDiaryInterval,
    required this.weatherAlertSensitivity,
    required this.alertSound,
    required this.locationAccuracy,
    required this.trailColorScheme,
    required this.isPremium,
    required this.isOnline,
    required this.toggleSosMode,
    required this.toggleGearChecklistAutoUpdate,
    required this.toggleBiometricAuth,
    required this.toggleLowBatteryMode,
    required this.toggleTripPlannerSync,
    required this.toggleOfflineGuideSync,
    required this.setTrailColorScheme,
    required this.requestPermissions,
    required this.setLanguage,
    required this.setHapticStrength,
    required this.setTrailDiaryInterval,
    required this.setWeatherAlertSensitivity,
    required this.setAlertSound,
    required this.setLocationAccuracy,
    required this.saveEmergencyContact,
    required this.showPremiumDialog,
    required this.contactController,
    required this.secondaryContactController,
    required this.savedContact,
    required this.savedSecondaryContact,
    required this.showSnack,
  });

  final bool isDarkMode,
      sosModeEnabled,
      gearChecklistAutoUpdate,
      biometricAuthEnabled,
      lowBatteryMode,
      tripPlannerSync,
      offlineGuideSync,
      isPremium,
      isOnline;
  final String selectedLanguage, trailDiaryInterval, weatherAlertSensitivity;
  final HapticStrength hapticStrength;
  final AlertSound alertSound;
  final LocationAccuracy locationAccuracy;
  final TrailColorScheme trailColorScheme;
  final void Function(bool) toggleSosMode,
      toggleGearChecklistAutoUpdate,
      toggleBiometricAuth,
      toggleLowBatteryMode,
      toggleTripPlannerSync,
      toggleOfflineGuideSync;
  final void Function(TrailColorScheme) setTrailColorScheme;
  final VoidCallback requestPermissions, showPremiumDialog;
  final void Function(String) setLanguage,
      setTrailDiaryInterval,
      setWeatherAlertSensitivity;
  final void Function(HapticStrength) setHapticStrength;
  final void Function(AlertSound) setAlertSound;
  final void Function(LocationAccuracy) setLocationAccuracy;
  final void Function(String, String) saveEmergencyContact;
  final TextEditingController contactController, secondaryContactController;
  final String? savedContact, savedSecondaryContact;
  final void Function(String, [bool, VoidCallback?]) showSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Manage Emergency Contacts',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          leading: const Icon(Icons.contacts, color: Colors.green),
          subtitle: savedContact != null
              ? Text(
                  'Primary: $savedContact${savedSecondaryContact != null ? '\nSecondary: $savedSecondaryContact' : ''}')
              : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Add Emergency Contacts'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: contactController,
                      decoration: const InputDecoration(
                          labelText: 'Primary Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: secondaryContactController,
                      decoration: const InputDecoration(
                          labelText: 'Secondary Phone Number (Optional)'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      saveEmergencyContact(contactController.text,
                          secondaryContactController.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
        ListTile(
          title: Text('SOS Permissions',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          leading: const Icon(Icons.security, color: Colors.green),
          onTap: requestPermissions,
        ),
        SwitchListTile(
          title: Text('Emergency SOS Mode',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Enable offline SOS alerts'),
          value: sosModeEnabled,
          onChanged: toggleSosMode,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          title: Text('Gear Checklist Auto-Update',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Update based on weather/location'),
          value: gearChecklistAutoUpdate,
          onChanged: toggleGearChecklistAutoUpdate,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          title: Text('Biometric Authentication',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Use fingerprint/face for login'),
          value: biometricAuthEnabled,
          onChanged: toggleBiometricAuth,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          title: Text('Low Battery Mode',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Reduce GPS polling and animations'),
          value: lowBatteryMode,
          onChanged: toggleLowBatteryMode,
          activeThumbColor: Colors.greenAccent,
        ),
        SwitchListTile(
          secondary: Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.red,
          ),
          title: Text('Trip Planner Sync',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Sync trip plans with Supabase'),
          value: tripPlannerSync,
          onChanged: isOnline ? toggleTripPlannerSync : null,
          activeThumbColor: Colors.greenAccent,
          inactiveTrackColor: Colors.grey,
        ),
        SwitchListTile(
          secondary: Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.red,
          ),
          title: Text('Offline Guide Sync',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('Sync survival guides for offline use'),
          value: offlineGuideSync,
          onChanged: isOnline ? toggleOfflineGuideSync : null,
          activeThumbColor: Colors.greenAccent,
          inactiveTrackColor: Colors.grey,
        ),
        ListTile(
          title: Text('AI Language',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(selectedLanguage),
          leading: const Icon(Icons.language, color: Colors.green),
          onTap: isPremium
              ? () async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor:
                        isDarkMode ? Colors.grey[900] : Colors.white,
                    builder: (_) => ListView(
                      shrinkWrap: true,
                      children: ['English', 'Spanish', 'French', 'Hindi']
                          .map((lang) => ListTile(
                                title: Text(lang,
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black)),
                                onTap: () => Navigator.pop(context, lang),
                              ))
                          .toList(),
                    ),
                  );
                  if (selected != null) setLanguage(selected);
                }
              : showPremiumDialog,
        ),
        ListTile(
          title: Text('Survival Guide Categories',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          leading: const Icon(Icons.book, color: Colors.green),
          onTap: () => showSnack('Guide categories coming soon'),
        ),
        ListTile(
          title: Text('Haptic Feedback Strength',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(hapticStrength.toString().split('.').last),
          leading: const Icon(Icons.vibration, color: Colors.green),
          onTap: () async {
            final selected = await showModalBottomSheet<HapticStrength>(
              context: context,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              builder: (_) => ListView(
                shrinkWrap: true,
                children: HapticStrength.values
                    .map((strength) => ListTile(
                          title: Text(strength.toString().split('.').last,
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                          onTap: () => Navigator.pop(context, strength),
                        ))
                    .toList(),
              ),
            );
            if (selected != null) setHapticStrength(selected);
          },
        ),
        ListTile(
          title: Text('Trail Diary Auto-Save',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(trailDiaryInterval),
          leading: const Icon(Icons.save, color: Colors.green),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              builder: (_) => ListView(
                shrinkWrap: true,
                children: ['5 minutes', '10 minutes', '15 minutes']
                    .map((interval) => ListTile(
                          title: Text(interval,
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                          onTap: () => Navigator.pop(context, interval),
                        ))
                    .toList(),
              ),
            );
            if (selected != null) setTrailDiaryInterval(selected);
          },
        ),
        ListTile(
          title: Text('Weather Alert Sensitivity',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(weatherAlertSensitivity),
          leading: const Icon(Icons.cloud, color: Colors.green),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              builder: (_) => ListView(
                shrinkWrap: true,
                children: ['Low', 'Medium', 'High']
                    .map((sensitivity) => ListTile(
                          title: Text(sensitivity,
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                          onTap: () => Navigator.pop(context, sensitivity),
                        ))
                    .toList(),
              ),
            );
            if (selected != null) setWeatherAlertSensitivity(selected);
          },
        ),
        ListTile(
          title: Text('Location Accuracy',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text(locationAccuracy.toString().split('.').last),
          leading: const Icon(Icons.gps_fixed, color: Colors.green),
          onTap: () async {
            final selected = await showModalBottomSheet<LocationAccuracy>(
              context: context,
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              builder: (_) => ListView(
                shrinkWrap: true,
                children: LocationAccuracy.values
                    .map((accuracy) => ListTile(
                          title: Text(accuracy.toString().split('.').last,
                              style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black)),
                          onTap: () => Navigator.pop(context, accuracy),
                        ))
                    .toList(),
              ),
            );
            if (selected != null) setLocationAccuracy(selected);
          },
        ),
      ],
    );
  }
}

class PremiumSettingsWidget extends StatelessWidget {
  const PremiumSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.showPremiumDialog,
  });

  final bool isDarkMode;
  final VoidCallback showPremiumDialog;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.star, color: Colors.amber),
      title: Text('Upgrade to Premium',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
      subtitle: const Text('Unlock AI Guide, AR Compass & more'),
      onTap: showPremiumDialog,
    );
  }
}

class AboutSettingsWidget extends StatelessWidget {
  const AboutSettingsWidget({
    super.key,
    required this.isDarkMode,
    required this.appVersion,
    required this.resetSettings,
    required this.featureFlags,
    required this.showSnack,
    required this.vibrate,
  });

  final bool isDarkMode;
  final String appVersion;
  final VoidCallback resetSettings, vibrate;
  final Map<String, bool> featureFlags;
  final void Function(String, [bool, VoidCallback?]) showSnack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('App Info',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: Text('Dravik v$appVersion'),
        ),
        ListTile(
          title: Text('Created by',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          subtitle: const Text('ZeroDaySmile / Amish'),
        ),
        if (featureFlags['showSplashSettings'] ?? false)
          ListTile(
            leading: const Icon(Icons.animation, color: Colors.green),
            title: Text('Splash Screen Settings',
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
            onTap: () {
              showSnack('Splash settings coming soon');
              vibrate();
            },
          ),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.redAccent),
          title: Text('Reset All Settings',
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
          onTap: resetSettings,
        ),
      ],
    );
  }
}

class AuthDialogWidget extends StatefulWidget {
  const AuthDialogWidget({
    super.key,
    required this.title,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.onForgotPassword,
  });

  final String title;
  final TextEditingController emailController, passwordController;
  final void Function(
          String email, String password, void Function(String? err) setErr)
      onSubmit;
  final VoidCallback? onForgotPassword;

  @override
  State<AuthDialogWidget> createState() => _AuthDialogWidgetState();
}

class _AuthDialogWidgetState extends State<AuthDialogWidget> {
  bool _isLoading = false;
  String? _authError;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    widget.emailController.addListener(() => setState(() => _authError = null));
    widget.passwordController
        .addListener(() => setState(() => _authError = null));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: widget.emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: [AutofillHints.email],
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              autofillHints: [AutofillHints.password],
              validator: (value) => widget.title != 'Reset Password' &&
                      (value == null || value.length < 6)
                  ? 'Password too short'
                  : null,
            ),
            if (_authError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_authError!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
      actions: [
        if (widget.onForgotPassword != null)
          TextButton(
              onPressed: widget.onForgotPassword, child: const Text('Forgot?')),
        TextButton(
          onPressed: () {
            widget.emailController.clear();
            widget.passwordController.clear();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (widget.emailController.text.isEmpty ||
                      !widget.emailController.text.contains('@')) {
                    setState(() => _authError = 'Enter a valid email');
                    return;
                  }
                  if (widget.title != 'Reset Password' &&
                      widget.passwordController.text.length < 6) {
                    setState(() => _authError = 'Password too short');
                    return;
                  }
                  setState(() => _isLoading = true);
                  widget.onSubmit(widget.emailController.text,
                      widget.passwordController.text, (err) {
                    setState(() {
                      _isLoading = false;
                      _authError = err;
                    });
                  });
                },
          child: Text(widget.title),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.emailController
        .removeListener(() => setState(() => _authError = null));
    widget.passwordController
        .removeListener(() => setState(() => _authError = null));
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
