import 'package:flutter/material.dart';
import 'package:dravik/app_frontend_v2/screens/activity_tracker_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/survival_guide_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/auth_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/index_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/trail_maps_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/trek_guides_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/trip_planner_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/community_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/quests_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/premium_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/settings_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/adventure_map_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/weather_forecast_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/emergency_guides_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/group_sync_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/country_explorer_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/place_guide_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/analytics_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/gear_checklist_v2_screen.dart';
import 'package:dravik/app_frontend_v2/screens/ultimate_guide_v2_screen.dart';

class AppHomeV2Screen extends StatefulWidget {
  const AppHomeV2Screen({super.key});

  @override
  State<AppHomeV2Screen> createState() => _AppHomeV2ScreenState();
}

class _AppHomeV2ScreenState extends State<AppHomeV2Screen> {
  int _selectedIndex = 0;

  late final List<_NavItem> _items = [
    const _NavItem('Home', Icons.home_outlined, IndexV2Screen()),
    const _NavItem('Auth', Icons.login, AuthV2Screen()),
    const _NavItem('Maps', Icons.map_outlined, TrailMapsV2Screen()),
    const _NavItem('Adventure Map', Icons.pin_drop_outlined, AdventureMapV2Screen()),
    const _NavItem('Guides', Icons.menu_book_outlined, TrekGuidesV2Screen()),
    const _NavItem('Library', Icons.library_books_outlined, UltimateGuideV2Screen()),
    const _NavItem('Trips', Icons.route_outlined, TripPlannerV2Screen()),
    const _NavItem('Gear', Icons.backpack_outlined, GearChecklistV2Screen()),
    const _NavItem('Weather', Icons.cloud_outlined, WeatherForecastV2Screen()),
    const _NavItem('Countries', Icons.public_outlined, CountryExplorerV2Screen()),
    const _NavItem('Companion', Icons.smart_toy_outlined, PlaceGuideV2Screen()),
    const _NavItem('Analytics', Icons.query_stats_outlined, AnalyticsV2Screen()),
    const _NavItem('Activity', Icons.directions_run_outlined, ActivityTrackerV2Screen()),
    const _NavItem('Settings', Icons.settings_outlined, SettingsV2Screen()),
    const _NavItem('Emergency', Icons.health_and_safety_outlined, EmergencyGuidesV2Screen()),
    const _NavItem('Community', Icons.groups_outlined, CommunityV2Screen()),
    const _NavItem('Sync', Icons.sync_outlined, GroupSyncV2Screen()),
    const _NavItem('Quests', Icons.military_tech_outlined, QuestsV2Screen()),
    const _NavItem('Survival', Icons.local_fire_department_outlined, SurvivalGuideV2Screen()),
    const _NavItem('Premium', Icons.workspace_premium_outlined, PremiumV2Screen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final selected = _items[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dravik V2 • ${selected.label}'),
      ),
      drawer: isWide ? null : Drawer(child: _buildNavList()),
      body: isWide
          ? Row(
              children: [
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: _buildNavList(),
                ),
                Expanded(child: selected.screen),
              ],
            )
          : selected.screen,
    );
  }

  Widget _buildNavList() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.label),
          selected: i == _selectedIndex,
          onTap: () {
            setState(() => _selectedIndex = i);
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const _NavItem(this.label, this.icon, this.screen);
}
