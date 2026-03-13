// Gamification and Analytics Models
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int pointsRequired;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.pointsRequired,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: AchievementCategory.values.firstWhere(
        (e) => e.toString() == 'AchievementCategory.${json['category']}',
        orElse: () => AchievementCategory.exploration,
      ),
      pointsRequired: json['pointsRequired'] ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.toString().split('.').last,
      'pointsRequired': pointsRequired,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }
}

enum AchievementCategory { exploration, distance, elevation, survival, social }

class UserStats {
  final double totalDistanceKm;
  final double totalElevationM;
  final int totalTrips;
  final int countriesVisited;
  final int daysOffline;
  final int sosActivations;
  final double caloriesBurned;
  final Map<String, int> terrainStats; // terrain type -> count
  final List<Achievement> achievements;
  final DateTime firstTripDate;
  final DateTime lastTripDate;

  UserStats({
    required this.totalDistanceKm,
    required this.totalElevationM,
    required this.totalTrips,
    required this.countriesVisited,
    required this.daysOffline,
    required this.sosActivations,
    required this.caloriesBurned,
    required this.terrainStats,
    required this.achievements,
    required this.firstTripDate,
    required this.lastTripDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalDistanceKm: (json['totalDistanceKm'] ?? 0).toDouble(),
      totalElevationM: (json['totalElevationM'] ?? 0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      countriesVisited: json['countriesVisited'] ?? 0,
      daysOffline: json['daysOffline'] ?? 0,
      sosActivations: json['sosActivations'] ?? 0,
      caloriesBurned: (json['caloriesBurned'] ?? 0).toDouble(),
      terrainStats: Map<String, int>.from(json['terrainStats'] ?? {}),
      achievements: (json['achievements'] as List?)
              ?.map((e) => Achievement.fromJson(e))
              .toList() ??
          [],
      firstTripDate: DateTime.parse(
          json['firstTripDate'] ?? DateTime.now().toIso8601String()),
      lastTripDate: DateTime.parse(
          json['lastTripDate'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDistanceKm': totalDistanceKm,
      'totalElevationM': totalElevationM,
      'totalTrips': totalTrips,
      'countriesVisited': countriesVisited,
      'daysOffline': daysOffline,
      'sosActivations': sosActivations,
      'caloriesBurned': caloriesBurned,
      'terrainStats': terrainStats,
      'achievements': achievements.map((e) => e.toJson()).toList(),
      'firstTripDate': firstTripDate.toIso8601String(),
      'lastTripDate': lastTripDate.toIso8601String(),
    };
  }

  factory UserStats.empty() {
    return UserStats(
      totalDistanceKm: 0,
      totalElevationM: 0,
      totalTrips: 0,
      countriesVisited: 0,
      daysOffline: 0,
      sosActivations: 0,
      caloriesBurned: 0,
      terrainStats: {},
      achievements: [],
      firstTripDate: DateTime.now(),
      lastTripDate: DateTime.now(),
    );
  }
}
