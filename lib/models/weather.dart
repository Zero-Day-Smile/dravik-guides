// Weather and Safety Alert Models
class WeatherData {
  final String location;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final DateTime timestamp;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final List<WeatherAlert> alerts;

  WeatherData({
    required this.location,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.timestamp,
    required this.hourly,
    required this.daily,
    required this.alerts,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      feelsLike: (json['feelsLike'] ?? 0).toDouble(),
      humidity: json['humidity'] ?? 0,
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      hourly: (json['hourly'] as List?)
              ?.map((e) => HourlyForecast.fromJson(e))
              .toList() ??
          [],
      daily: (json['daily'] as List?)
              ?.map((e) => DailyForecast.fromJson(e))
              .toList() ??
          [],
      alerts: (json['alerts'] as List?)
              ?.map((e) => WeatherAlert.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
      'hourly': hourly.map((e) => e.toJson()).toList(),
      'daily': daily.map((e) => e.toJson()).toList(),
      'alerts': alerts.map((e) => e.toJson()).toList(),
    };
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final String description;
  final String icon;
  final int precipProbability;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.precipProbability,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
      temperature: (json['temperature'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      precipProbability: json['precipProbability'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'temperature': temperature,
      'description': description,
      'icon': icon,
      'precipProbability': precipProbability,
    };
  }
}

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final String description;
  final String icon;
  final int precipProbability;

  DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.description,
    required this.icon,
    required this.precipProbability,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      tempMax: (json['tempMax'] ?? 0).toDouble(),
      tempMin: (json['tempMin'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      precipProbability: json['precipProbability'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'tempMax': tempMax,
      'tempMin': tempMin,
      'description': description,
      'icon': icon,
      'precipProbability': precipProbability,
    };
  }
}

class WeatherAlert {
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime startTime;
  final DateTime endTime;
  final String source;

  WeatherAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.startTime,
    required this.endTime,
    required this.source,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${json['severity']}',
        orElse: () => AlertSeverity.low,
      ),
      startTime:
          DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime:
          DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      source: json['source'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'severity': severity.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'source': source,
    };
  }
}

enum AlertSeverity { low, medium, high, extreme }

class SafetyAlert {
  final String id;
  final String title;
  final String description;
  final AlertType type;
  final AlertSeverity severity;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final DateTime reportedAt;
  final String reportedBy;
  final bool verified;

  SafetyAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.reportedAt,
    required this.reportedBy,
    this.verified = false,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.toString() == 'AlertType.${json['type']}',
        orElse: () => AlertType.other,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == 'AlertSeverity.${json['severity']}',
        orElse: () => AlertSeverity.low,
      ),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      radiusKm: (json['radiusKm'] ?? 1.0).toDouble(),
      reportedAt: DateTime.parse(
          json['reportedAt'] ?? DateTime.now().toIso8601String()),
      reportedBy: json['reportedBy'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm,
      'reportedAt': reportedAt.toIso8601String(),
      'reportedBy': reportedBy,
      'verified': verified,
    };
  }
}

enum AlertType {
  flood,
  wildfire,
  landslide,
  wildlife,
  theft,
  roadClosure,
  weather,
  other
}
