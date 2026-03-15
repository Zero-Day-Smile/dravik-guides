import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dravik/screens/map_screen.dart';
import 'package:dravik/screens/guide_screen.dart';
import 'package:dravik/screens/gear_screen.dart';
import 'package:dravik/screens/trip_planner_screen.dart';
import 'package:dravik/screens/country_explorer_screen.dart';
import 'package:dravik/screens/ar_trail_scanner_pro.dart';
import 'package:dravik/screens/group_sync_screen.dart';
import 'package:dravik/screens/emergency_contact_screen.dart';
import 'package:dravik/services/activity_tracker_service.dart';
import 'package:dravik/services/emergency_contact_service.dart';
import 'package:dravik/services/weather_alert_service.dart';
import 'package:dravik/screens/weather_forecast_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dravik/screens/offline_regions_screen.dart';
import 'package:dravik/screens/settings_screen.dart' show SettingsScreen;
import 'package:dravik/screens/analytics_screen.dart';
import 'package:dravik/screens/place_guide_screen.dart';
import 'package:dravik/screens/emergency_guides_screen.dart';
import 'package:dravik/screens/ultimate_guide_screen.dart';
import 'package:dravik/app_frontend_v2/screens/community_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/quests_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/premium_v2_screen.dart';
import 'package:dravik/config/platform_capabilities.dart';
import 'package:dravik/config/feature_flags.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _weatherAlertService = WeatherAlertService();
  late final List<Widget> _screens;

  final ActivityTrackerService _activityTracker =
      ActivityTrackerService.instance;
  StreamSubscription<ActivityMetrics>? _activitySubscription;
  ActivityMetrics _activityMetrics = ActivityMetrics.zero();
  bool _trackingEnabled = false;
  bool _activityNotifications = true;
  bool _allowBackground = false;
  bool _activityBootstrapped = false;
  bool _screensInitialized = false;

  @override
  void initState() {
    super.initState();
    // Services that don't need context can start here
    EmergencyContactService().startCheckIn();
    _weatherAlertService.startWeatherMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize screens that may need Theme/context
    if (!_screensInitialized) {
      _screensInitialized = true;
      _screens = _buildScreensForPlatform();
    }

    if (!_activityBootstrapped) {
      _activityBootstrapped = true;
      if (FeatureFlags.isEnabled(AppFeature.activityTracking)) {
        _bootstrapActivityTracking();
      }
    }
  }

  List<Widget> _buildScreensForPlatform() {
    if (PlatformCapabilities.isWeb) {
      return [
        homeContent,
        const MapScreen(),
        const GuideScreen(),
        const TripPlannerScreen(),
        const SettingsScreen(),
      ];
    }

    return [
      homeContent,
      const MapScreen(),
      const GuideScreen(),
      const GearScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    _activityTracker.setNotificationHandler(null);
    _weatherAlertService.stopWeatherMonitoring();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _bootstrapActivityTracking() {
    _activityMetrics = _activityTracker.currentMetrics;
    final settingsBox = Hive.box('settings');
    _trackingEnabled =
        settingsBox.get('activity_tracking_enabled', defaultValue: true);
    _activityNotifications =
        settingsBox.get('activity_notifications_enabled', defaultValue: true);
    _allowBackground =
        settingsBox.get('activity_background_enabled', defaultValue: false);

    _activityTracker.setNotificationHandler(_handleActivityNotification);
    if (_trackingEnabled) {
      _activityTracker.startTracking(
        allowBackground: _allowBackground,
        enableNotifications: _activityNotifications,
      );
    }

    _activitySubscription = _activityTracker.metricsStream.listen((metrics) {
      if (!mounted) return;
      setState(() => _activityMetrics = metrics);
    });
  }

  void _handleActivityNotification(String title, String body) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_activityNotifications) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title: $body')),
      );
    });
  }

  void _toggleTracking(bool enabled) {
    final proceed =
        enabled ? _ensureActivityPermissionIfNeeded() : Future.value(true);
    proceed.then((ok) {
      if (!ok) return;
      final settingsBox = Hive.box('settings');
      settingsBox.put('activity_tracking_enabled', enabled);
      setState(() => _trackingEnabled = enabled);
      if (enabled) {
        _activityTracker.startTracking(
          allowBackground: _allowBackground,
          enableNotifications: _activityNotifications,
        );
      } else {
        _activityTracker.stopTracking();
      }
    });
  }

  void _toggleNotifications(bool enabled) {
    final settingsBox = Hive.box('settings');
    settingsBox.put('activity_notifications_enabled', enabled);
    setState(() => _activityNotifications = enabled);
    _activityTracker.notificationsEnabled = enabled;
  }

  void _toggleBackground(bool enabled) {
    _ensureActivityPermissionIfNeeded().then((ok) {
      if (!ok) return;
      final settingsBox = Hive.box('settings');
      settingsBox.put('activity_background_enabled', enabled);
      setState(() => _allowBackground = enabled);
      _activityTracker.startTracking(
        allowBackground: enabled,
        enableNotifications: _activityNotifications,
      );
    });
  }

  Future<bool> _ensureActivityPermissionIfNeeded() async {
    try {
      if (!PlatformCapabilities.isAndroid) {
        return true; // iOS doesn't require this perm for accelerometer
      }
      final status = await Permission.activityRecognition.status;
      if (status.isGranted) return true;
      final result = await Permission.activityRecognition.request();
      if (result.isGranted) return true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Activity permission denied. Enable it in Settings to track steps.'),
          ),
        );
      }
      return false;
    } catch (_) {
      return true; // fail-open: accelerometer may still work without this
    }
  }

  Widget get homeContent {
    if (PlatformCapabilities.isWeb) {
      return _buildWebHomeContent();
    }
    if (PlatformCapabilities.isIOS) {
      return _buildIOSHomeContent();
    }
    return _buildMobileHomeContent();
  }

  Widget _buildMobileHomeContent() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium header banner
            _buildHeaderBanner(),
            const SizedBox(height: 28),

            // Stats cards row
            _buildStatsRow(),
            const SizedBox(height: 28),

            // Main features section
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Featured cards (AR + Emergency)
            _buildFeaturedCards(),
            const SizedBox(height: 28),

            // Grid of quick actions
            const Text(
              'Explore',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            _buildFeatureGrid(),
            const SizedBox(height: 28),

            // Activity tracking section
            if (FeatureFlags.isEnabled(AppFeature.activityTracking))
              _buildActivitySection(),
          ],
        ),
      );

  Widget _buildIOSHomeContent() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'iOS edition: tuned for privacy-first permissions and native interactions.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            const Text(
              'Core Features',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _buildFeatureGrid(),
            const SizedBox(height: 24),
            const Text(
              'Advanced Mobile Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildFeaturedCards(),
            const SizedBox(height: 24),
            if (FeatureFlags.isEnabled(AppFeature.activityTracking))
              _buildActivitySection(),
          ],
        ),
      );

  Widget _buildWebHomeContent() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF34A853).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Web edition: fast planning and research tools. Advanced sensors and AR are available in the mobile app.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            const Text(
              'Community Highlights',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildWebRankedCollections(),
            const SizedBox(height: 24),
            const Text(
              'Curated Journeys',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildWebJourneyCards(),
            const SizedBox(height: 24),
            const Text(
              'Web Core Features',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _buildFeatureGrid(),
            const SizedBox(height: 24),
            const Text(
              'Mobile Advanced Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildLockedFeatureCard(
              title: 'AR Scanner Pro',
              subtitle: 'Live POI detection and trail overlays (mobile only).',
              icon: Icons.camera_alt,
            ),
            const SizedBox(height: 10),
            _buildLockedFeatureCard(
              title: 'Emergency + Group Sync',
              subtitle:
                  'Live group updates, emergency contacts, and offline safety flows.',
              icon: Icons.security,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Tip: Plan and discover on web, then switch to the mobile app for live AR, emergency SOS, and field tracking.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildWebRankedCollections() {
    final collections = [
      ('Top Mountain Escapes', 'Trending', Icons.terrain, const Color(0xFF2563EB)),
      ('Best Weekend Trails', 'Fast Plan', Icons.hiking, const Color(0xFF059669)),
      ('Culture + Trek Mix', 'Editor Pick', Icons.travel_explore, const Color(0xFFD97706)),
    ];

    return Column(
      children: collections
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: EdgeInsets.only(bottom: entry.key == collections.length - 1 ? 0 : 10),
                child: _buildWebCollectionTile(
                  rank: entry.key + 1,
                  title: entry.value.$1,
                  badge: entry.value.$2,
                  icon: entry.value.$3,
                  color: entry.value.$4,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildWebCollectionTile({
    required int rank,
    required String title,
    required String badge,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  badge,
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebJourneyCards() {
    final journeys = [
      ('3-Day Alpine Starter', 'Maps + checklist + weather windows'),
      ('Sacred Peaks Circuit', 'Route ideas with local culture stops'),
      ('Rain-Friendly Forest Loop', 'Low-risk weather-aware itinerary'),
    ];

    return Column(
      children: journeys
          .map((j) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j.$1,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        j.$2,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildActivitySection() {
    final flagText = _activityMetrics.flag;
    final Color flagColor;
    if (flagText.startsWith('Green')) {
      flagColor = const Color(0xFF34A853);
    } else if (flagText.startsWith('Yellow') || flagText.startsWith('Amber')) {
      flagColor = const Color(0xFFFBBC04);
    } else {
      flagColor = const Color(0xFFEA4335);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              flagColor.withValues(alpha: 0.08),
              flagColor.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: flagColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: flagColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adventure Vitality',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Your activity status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: flagColor.withValues(alpha: 0.2),
                      border: Border.all(
                        color: flagColor.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      flagText,
                      style: TextStyle(
                        color: flagColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActivityStat(
                      'Steps', _activityMetrics.steps.toString()),
                  _buildActivityStat(
                    'Distance',
                    '${_activityMetrics.distanceKm.toStringAsFixed(1)}km',
                  ),
                  _buildActivityStat(
                    'Calories',
                    _activityMetrics.calories.toStringAsFixed(0),
                  ),
                  _buildActivityStat(
                    'Pace',
                    '${_activityMetrics.pace.toStringAsFixed(0)} spm',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text(
                        'Track in background',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _allowBackground,
                      onChanged: _toggleBackground,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text(
                        'Enable notifications',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _activityNotifications,
                      onChanged: _toggleNotifications,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text(
                        'Step tracking',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Motion & step detection',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _trackingEnabled,
                      onChanged: _toggleTracking,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A73E8),
            const Color(0xFF1A73E8).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dravik',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Born to Explore',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.explore,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Lottie.asset(
                'assets/animations/fire.json',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Steps',
            _activityMetrics.steps.toString(),
            Icons.directions_walk,
            const Color(0xFF34A853),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Distance',
            '${_activityMetrics.distanceKm.toStringAsFixed(1)}km',
            Icons.map,
            const Color(0xFFEA4335),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Calories',
            _activityMetrics.calories.toStringAsFixed(0),
            Icons.local_fire_department,
            const Color(0xFFFBBC04),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCards() {
    final bool showAR = FeatureFlags.isEnabled(AppFeature.arScanner);
    final bool showEmergency =
        FeatureFlags.isEnabled(AppFeature.emergencyContacts);

    return Column(
      children: [
        if (showAR)
          _buildFeatureCard(
            'AR Scanner',
            'Real-time POI detection\n& navigation',
            Icons.camera_alt,
            const Color(0xFF1A73E8),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArTrailScannerPro(),
              ),
            ),
          )
        else
          _buildLockedFeatureCard(
            title: 'AR Scanner',
            subtitle: 'Available only in Android and iOS app builds.',
            icon: Icons.camera_alt,
          ),
        const SizedBox(height: 12),
        if (showEmergency)
          _buildFeatureCard(
            'Emergency',
            'SOS contacts & safety\nfeatures',
            Icons.safety_check,
            const Color(0xFFEA4335),
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmergencyContactScreen(),
              ),
            ),
          )
        else
          _buildLockedFeatureCard(
            title: 'Emergency',
            subtitle: 'Mobile-only for device safety and contact workflows.',
            icon: Icons.safety_check,
          ),
      ],
    );
  }

  Widget _buildLockedFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        color: Colors.grey.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade700, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(Icons.phone_iphone, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.9),
                color.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = <(String, IconData, Color, VoidCallback)>[
      (
        'Map',
        Icons.map,
        const Color(0xFF1A73E8),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            )
      ),
      (
        'Guides',
        Icons.book,
        const Color(0xFF34A853),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GuideScreen()),
            )
      ),
      (
        'Trip',
        Icons.route,
        const Color(0xFFEA4335),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const TripPlannerScreen()))
      ),
      (
        'Weather',
        Icons.cloud_queue,
        const Color(0xFFFBBC04),
        () => _showWeatherAction(context)
      ),
      (
        'Gear',
        Icons.backpack,
        const Color(0xFF5F35F5),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GearScreen()),
            )
      ),
      (
        'Explorer',
        Icons.public,
        const Color(0xFFFF6F00),
        () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CountryExplorerScreen()))
      ),
      (
        'Companion',
        Icons.smart_toy,
        const Color(0xFF8E24AA),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlaceGuideScreen()),
            )
      ),
      (
        'Safety',
        Icons.health_and_safety,
        const Color(0xFFD32F2F),
        () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OfflineGuidesScreen(),
              ),
            )
      ),
      (
        'Library',
        Icons.menu_book,
        const Color(0xFF3949AB),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UltimateGuideScreen()),
            )
      ),
      (
        'Analytics',
        Icons.query_stats,
        const Color(0xFF00897B),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
            )
      ),
      (
        'Community',
        Icons.groups,
        const Color(0xFF7B1FA2),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CommunityV2Screen()),
            )
      ),
      (
        'Quests',
        Icons.military_tech,
        const Color(0xFFF57C00),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuestsV2Screen()),
            )
      ),
      (
        'Premium',
        Icons.workspace_premium,
        const Color(0xFFFFB300),
        () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PremiumV2Screen()),
            )
      ),
    ];

    if (FeatureFlags.isEnabled(AppFeature.groupSync)) {
      features.add(
        (
          'Group',
          Icons.people,
          const Color(0xFF00BCD4),
          () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupSyncScreen()),
              )
        ),
      );
    }
    if (FeatureFlags.isEnabled(AppFeature.offlineRegions)) {
      features.add(
        (
          'Offline',
          Icons.download,
          const Color(0xFF6A1B9A),
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfflineRegionsScreen(),
                ),
              )
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: PlatformCapabilities.isWeb ? 3 : 4,
      childAspectRatio: 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: features.map((f) {
        return _buildMiniFeatureCard(f.$1, f.$2, f.$3, f.$4);
      }).toList(),
    );
  }

  Widget _buildMiniFeatureCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  Future<void> _showWeatherAction(BuildContext context) async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.best,
        ),
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherForecastScreen(
            latitude: position.latitude,
            longitude: position.longitude,
            locationName: 'Current Location',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get location. Enable GPS.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dravik'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: theme.scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _onItemTapped,
        items: PlatformCapabilities.isWeb
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Maps',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Guides',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.route),
                  label: 'Trip',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ]
            : const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Maps',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: 'Guides',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.backpack),
                  label: 'Gear',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
      ),
      // SOS button moved to Emergency Contacts screen for safety
    );
  }
}
