import 'package:flutter/material.dart';
import 'package:dravik/models/achievement.dart';
import 'package:dravik/services/analytics_service.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  UserStats? _stats;
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _stats = await _analyticsService.getStats();
    _achievements = await _analyticsService.getAchievements();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget analyticsContent = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                _buildStatsGrid(isDark),
                const SizedBox(height: 24),
                // Achievements
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_achievements.where((a) => a.isUnlocked).length} of ${_achievements.length} unlocked',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildAchievementsList(isDark),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Analytics & Achievements'),
        backgroundColor: Colors.green[900],
      ),
      body: Column(
        children: [
          const EditionBannerForScreen(screen: EditionScreen.analytics),
          Expanded(child: analyticsContent),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Distance',
                '${_stats!.totalDistanceKm.toStringAsFixed(1)} km',
                Icons.straighten,
                Colors.blue,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Elevation Gain',
                '${_stats!.totalElevationM.toStringAsFixed(0)} m',
                Icons.terrain,
                Colors.green,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Trips',
                '${_stats!.totalTrips}',
                Icons.check_circle,
                Colors.orange,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Countries',
                '${_stats!.countriesVisited}',
                Icons.public,
                Colors.purple,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Days',
                '${_stats!.daysOffline}',
                Icons.calendar_today,
                Colors.teal,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Max Altitude',
                '${_stats!.totalElevationM.toStringAsFixed(0)} m',
                Icons.landscape,
                Colors.red,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(bool isDark) {
    final categories = AchievementCategory.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final categoryAchievements =
            _achievements.where((a) => a.category == category).toList();

        if (categoryAchievements.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categoryAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(
                  categoryAchievements[index],
                  isDark,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isDark) {
    final isLocked = !achievement.isUnlocked;
    final progress = 0.0; // Progress will be calculated from UserStats

    return Card(
      elevation: isLocked ? 0 : 2,
      color: isLocked
          ? (isDark ? Colors.grey[850] : Colors.grey.shade200)
          : (isDark ? Colors.grey[800] : Colors.white),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isLocked ? Colors.grey.shade400 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 24,
                      color: isLocked ? Colors.grey.shade600 : null,
                    ),
                  ),
                ),
                const Spacer(),
                if (achievement.isUnlocked)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: 11,
                color: isLocked
                    ? Colors.grey.shade500
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (!achievement.isUnlocked) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                color: Colors.green,
                minHeight: 4,
              ),
              const SizedBox(height: 4),
              Text(
                '${achievement.pointsRequired} points required',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.exploration:
        return Icons.explore;
      case AchievementCategory.distance:
        return Icons.straighten;
      case AchievementCategory.elevation:
        return Icons.terrain;
      case AchievementCategory.survival:
        return Icons.local_fire_department;
      case AchievementCategory.social:
        return Icons.people;
    }
  }
}
