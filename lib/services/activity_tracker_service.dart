import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ActivityMetrics {
  final int steps;
  final double distanceKm;
  final double calories;
  final double pace; // steps per minute
  final String flag; // green / yellow / red message
  final List<String> achievements;

  const ActivityMetrics({
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.pace,
    required this.flag,
    required this.achievements,
  });

  factory ActivityMetrics.zero() => const ActivityMetrics(
        steps: 0,
        distanceKm: 0,
        calories: 0,
        pace: 0,
        flag: 'Idle',
        achievements: [],
      );

  ActivityMetrics copyWith({
    int? steps,
    double? distanceKm,
    double? calories,
    double? pace,
    String? flag,
    List<String>? achievements,
  }) {
    return ActivityMetrics(
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      calories: calories ?? this.calories,
      pace: pace ?? this.pace,
      flag: flag ?? this.flag,
      achievements: achievements ?? this.achievements,
    );
  }
}

class ActivityTrackerService {
  ActivityTrackerService._internal();
  static final ActivityTrackerService instance =
      ActivityTrackerService._internal();

  final StreamController<ActivityMetrics> _metricsController =
      StreamController<ActivityMetrics>.broadcast();
  Stream<ActivityMetrics> get metricsStream => _metricsController.stream;

  ActivityMetrics _metrics = ActivityMetrics.zero();
  ActivityMetrics get currentMetrics => _metrics;

  bool _tracking = false;
  bool notificationsEnabled = true;
  bool backgroundAllowed = false;

  double stepLengthMeters = 0.75; // average stride length
  double caloriesPerStep = 0.04; // rough kcal per step

  final List<int> _achievementSteps = [1000, 5000, 10000, 20000];
  final Map<int, String> _achievementNames = {
    1000: 'Trail Scout',
    5000: 'Peak Chaser',
    10000: 'Summit Seeker',
    20000: 'Ultra Trekker',
  };

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _startTime;
  DateTime _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);
  void Function(String title, String body)? _notify;

  void setNotificationHandler(
      void Function(String title, String body)? handler) {
    _notify = handler;
  }

  void startTracking(
      {bool allowBackground = false, bool enableNotifications = true}) {
    backgroundAllowed = allowBackground;
    notificationsEnabled = enableNotifications;
    if (_tracking) return;

    _tracking = true;
    _startTime ??= DateTime.now();

    _accelerometerSubscription ??=
        accelerometerEventStream().listen(_handleAccelerometer, onError: (e) {
      debugPrint('ActivityTracker accelerometer error: $e');
    });
  }

  void stopTracking() {
    _tracking = false;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }

  void dispose() {
    stopTracking();
    _metricsController.close();
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    if (!_tracking) return;

    // Total acceleration magnitude (m/s^2)
    final magnitude =
        math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final now = DateTime.now();

    // Basic peak detection to approximate steps
    // Gravity baseline ~9.81 m/s^2. Consider a step when magnitude exceeds
    // gravity by a modest threshold, with a minimum interval to avoid double-counts.
    const double gravity = 9.81;
    const double deltaThreshold = 1.6; // sensitivity: lower -> more sensitive
    const Duration minStepInterval = Duration(milliseconds: 280);

    final bool isPeak = magnitude > (gravity + deltaThreshold);
    final bool spacingOk = now.difference(_lastStepTime) > minStepInterval;

    if (isPeak && spacingOk) {
      _lastStepTime = now;
      _metrics = _metrics.copyWith(
        steps: _metrics.steps + 1,
      );
      _updateDerivedMetrics();
      _checkAchievements();
      _emit();
    }
  }

  void _updateDerivedMetrics() {
    final distance = (_metrics.steps * stepLengthMeters) / 1000; // km
    final calories = _metrics.steps * caloriesPerStep;
    final pace = _computePace();

    _metrics = _metrics.copyWith(
      distanceKm: distance,
      calories: calories,
      pace: pace,
      flag: _resolveFlag(pace),
    );
  }

  double _computePace() {
    if (_startTime == null || _metrics.steps == 0) return 0;
    final minutes = DateTime.now().difference(_startTime!).inSeconds / 60.0;
    if (minutes <= 0) return 0;
    return _metrics.steps / minutes;
  }

  String _resolveFlag(double pace) {
    if (_metrics.steps >= 8000) return 'Green flag: strong day';
    if (pace > 130) return 'Yellow flag: intense pace';
    if (_metrics.steps < 1500) return 'Amber flag: warm up more';
    return 'Green flag: on track';
  }

  void _checkAchievements() {
    for (final threshold in _achievementSteps) {
      final alreadyEarned =
          _metrics.achievements.contains(_achievementNames[threshold]);
      if (_metrics.steps >= threshold && !alreadyEarned) {
        final name = _achievementNames[threshold]!;
        final updated = List<String>.from(_metrics.achievements)..add(name);
        _metrics = _metrics.copyWith(achievements: updated);
        if (notificationsEnabled && _notify != null) {
          _notify!.call('Achievement unlocked', name);
        }
      }
    }
  }

  void _emit() {
    if (!_metricsController.isClosed) {
      _metricsController.add(_metrics);
    }
  }
}
