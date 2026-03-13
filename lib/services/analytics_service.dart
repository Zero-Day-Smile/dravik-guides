import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:dravik/models/achievement.dart';

class AnalyticsService {
  static const String _boxName = 'user_stats';
  static const String _achievementsBoxName = 'achievements';

  // Predefined achievements
  static final List<Achievement> _allAchievements = [
    Achievement(
      id: 'first_trek',
      title: 'First Steps',
      description: 'Complete your first trek',
      icon: '👣',
      category: AchievementCategory.exploration,
      pointsRequired: 0,
    ),
    Achievement(
      id: 'distance_10km',
      title: '10K Wanderer',
      description: 'Trek a total of 10 kilometers',
      icon: '🚶',
      category: AchievementCategory.distance,
      pointsRequired: 10,
    ),
    Achievement(
      id: 'distance_50km',
      title: 'Marathon Trekker',
      description: 'Trek a total of 50 kilometers',
      icon: '🏃',
      category: AchievementCategory.distance,
      pointsRequired: 50,
    ),
    Achievement(
      id: 'distance_100km',
      title: 'Century Walker',
      description: 'Trek a total of 100 kilometers',
      icon: '🎖️',
      category: AchievementCategory.distance,
      pointsRequired: 100,
    ),
    Achievement(
      id: 'distance_500km',
      title: 'Legendary Explorer',
      description: 'Trek a total of 500 kilometers',
      icon: '🏆',
      category: AchievementCategory.distance,
      pointsRequired: 500,
    ),
    Achievement(
      id: 'elevation_1000m',
      title: 'Hill Climber',
      description: 'Gain 1000m of elevation',
      icon: '⛰️',
      category: AchievementCategory.elevation,
      pointsRequired: 1000,
    ),
    Achievement(
      id: 'elevation_5000m',
      title: 'Mountain Master',
      description: 'Gain 5000m of elevation',
      icon: '🏔️',
      category: AchievementCategory.elevation,
      pointsRequired: 5000,
    ),
    Achievement(
      id: 'countries_3',
      title: 'Globe Trotter',
      description: 'Visit 3 countries',
      icon: '🌍',
      category: AchievementCategory.exploration,
      pointsRequired: 3,
    ),
    Achievement(
      id: 'countries_10',
      title: 'World Wanderer',
      description: 'Visit 10 countries',
      icon: '🌎',
      category: AchievementCategory.exploration,
      pointsRequired: 10,
    ),
    Achievement(
      id: 'offline_7days',
      title: 'Off the Grid',
      description: 'Spend 7 days offline',
      icon: '📵',
      category: AchievementCategory.survival,
      pointsRequired: 7,
    ),
    Achievement(
      id: 'offline_30days',
      title: 'Digital Detox Master',
      description: 'Spend 30 days offline',
      icon: '🔋',
      category: AchievementCategory.survival,
      pointsRequired: 30,
    ),
    Achievement(
      id: 'sos_survivor',
      title: 'Survivor',
      description: 'Activate SOS and return safely',
      icon: '🆘',
      category: AchievementCategory.survival,
      pointsRequired: 1,
    ),
  ];

  Future<UserStats> getStats() async {
    try {
      final box = await Hive.openBox(_boxName);
      final data = box.get('stats');

      if (data != null) {
        return UserStats.fromJson(json.decode(data));
      }

      return UserStats.empty();
    } catch (e) {
      return UserStats.empty();
    }
  }

  Future<void> saveStats(UserStats stats) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put('stats', json.encode(stats.toJson()));

      // Check for new achievements
      await _checkAchievements(stats);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateDistance(double distanceKm) async {
    final stats = await getStats();
    final updated = UserStats(
      totalDistanceKm: stats.totalDistanceKm + distanceKm,
      totalElevationM: stats.totalElevationM,
      totalTrips: stats.totalTrips,
      countriesVisited: stats.countriesVisited,
      daysOffline: stats.daysOffline,
      sosActivations: stats.sosActivations,
      caloriesBurned:
          stats.caloriesBurned + (distanceKm * 50), // ~50 cal per km
      terrainStats: stats.terrainStats,
      achievements: stats.achievements,
      firstTripDate: stats.firstTripDate,
      lastTripDate: DateTime.now(),
    );
    await saveStats(updated);
  }

  Future<void> updateElevation(double elevationM) async {
    final stats = await getStats();
    final updated = UserStats(
      totalDistanceKm: stats.totalDistanceKm,
      totalElevationM: stats.totalElevationM + elevationM,
      totalTrips: stats.totalTrips,
      countriesVisited: stats.countriesVisited,
      daysOffline: stats.daysOffline,
      sosActivations: stats.sosActivations,
      caloriesBurned: stats.caloriesBurned +
          (elevationM * 2), // Extra calories for climbing
      terrainStats: stats.terrainStats,
      achievements: stats.achievements,
      firstTripDate: stats.firstTripDate,
      lastTripDate: DateTime.now(),
    );
    await saveStats(updated);
  }

  Future<void> recordTripCompletion(String terrain, String countryCode) async {
    final stats = await getStats();
    final terrainStats = Map<String, int>.from(stats.terrainStats);
    terrainStats[terrain] = (terrainStats[terrain] ?? 0) + 1;

    final updated = UserStats(
      totalDistanceKm: stats.totalDistanceKm,
      totalElevationM: stats.totalElevationM,
      totalTrips: stats.totalTrips + 1,
      countriesVisited: stats.countriesVisited +
          (stats.terrainStats.containsKey(countryCode) ? 0 : 1),
      daysOffline: stats.daysOffline,
      sosActivations: stats.sosActivations,
      caloriesBurned: stats.caloriesBurned,
      terrainStats: terrainStats,
      achievements: stats.achievements,
      firstTripDate:
          stats.totalTrips == 0 ? DateTime.now() : stats.firstTripDate,
      lastTripDate: DateTime.now(),
    );
    await saveStats(updated);
  }

  Future<void> incrementSOSActivations() async {
    final stats = await getStats();
    final updated = UserStats(
      totalDistanceKm: stats.totalDistanceKm,
      totalElevationM: stats.totalElevationM,
      totalTrips: stats.totalTrips,
      countriesVisited: stats.countriesVisited,
      daysOffline: stats.daysOffline,
      sosActivations: stats.sosActivations + 1,
      caloriesBurned: stats.caloriesBurned,
      terrainStats: stats.terrainStats,
      achievements: stats.achievements,
      firstTripDate: stats.firstTripDate,
      lastTripDate: DateTime.now(),
    );
    await saveStats(updated);
  }

  Future<void> incrementOfflineDays(int days) async {
    final stats = await getStats();
    final updated = UserStats(
      totalDistanceKm: stats.totalDistanceKm,
      totalElevationM: stats.totalElevationM,
      totalTrips: stats.totalTrips,
      countriesVisited: stats.countriesVisited,
      daysOffline: stats.daysOffline + days,
      sosActivations: stats.sosActivations,
      caloriesBurned: stats.caloriesBurned,
      terrainStats: stats.terrainStats,
      achievements: stats.achievements,
      firstTripDate: stats.firstTripDate,
      lastTripDate: DateTime.now(),
    );
    await saveStats(updated);
  }

  Future<void> _checkAchievements(UserStats stats) async {
    final box = await Hive.openBox(_achievementsBoxName);
    final unlockedIds =
        List<String>.from(box.get('unlocked', defaultValue: []));

    for (final achievement in _allAchievements) {
      if (unlockedIds.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_trek':
          shouldUnlock = stats.totalTrips >= 1;
          break;
        case 'distance_10km':
          shouldUnlock = stats.totalDistanceKm >= 10;
          break;
        case 'distance_50km':
          shouldUnlock = stats.totalDistanceKm >= 50;
          break;
        case 'distance_100km':
          shouldUnlock = stats.totalDistanceKm >= 100;
          break;
        case 'distance_500km':
          shouldUnlock = stats.totalDistanceKm >= 500;
          break;
        case 'elevation_1000m':
          shouldUnlock = stats.totalElevationM >= 1000;
          break;
        case 'elevation_5000m':
          shouldUnlock = stats.totalElevationM >= 5000;
          break;
        case 'countries_3':
          shouldUnlock = stats.countriesVisited >= 3;
          break;
        case 'countries_10':
          shouldUnlock = stats.countriesVisited >= 10;
          break;
        case 'offline_7days':
          shouldUnlock = stats.daysOffline >= 7;
          break;
        case 'offline_30days':
          shouldUnlock = stats.daysOffline >= 30;
          break;
        case 'sos_survivor':
          shouldUnlock = stats.sosActivations >= 1;
          break;
      }

      if (shouldUnlock) {
        unlockedIds.add(achievement.id);
        await box.put('unlocked', unlockedIds);
      }
    }
  }

  Future<List<Achievement>> getAchievements() async {
    final box = await Hive.openBox(_achievementsBoxName);
    final unlockedIds =
        List<String>.from(box.get('unlocked', defaultValue: []));

    return _allAchievements.map((a) {
      final isUnlocked = unlockedIds.contains(a.id);
      return Achievement(
        id: a.id,
        title: a.title,
        description: a.description,
        icon: a.icon,
        category: a.category,
        pointsRequired: a.pointsRequired,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now() : null,
      );
    }).toList();
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final achievements = await getAchievements();
    return achievements.where((a) => a.isUnlocked).toList();
  }

  Future<List<Achievement>> getLockedAchievements() async {
    final achievements = await getAchievements();
    return achievements.where((a) => !a.isUnlocked).toList();
  }

  // Trip hazard analytics
  Future<void> logHazard(String type, String description, double? latitude,
      double? longitude) async {
    final box = await Hive.openBox('trip_hazards');
    await box.put(
      DateTime.now().toIso8601String(),
      {
        'type': type,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<Map<String, int>> getHazardPatterns() async {
    final box = await Hive.openBox('trip_hazards');
    final hazards = <String, int>{};
    for (final key in box.keys) {
      final hazardLog = box.get(key) as Map?;
      final hazardType = hazardLog?['type'] as String?;
      if (hazardType != null) {
        hazards[hazardType] = (hazards[hazardType] ?? 0) + 1;
      }
    }
    return hazards;
  }
}
