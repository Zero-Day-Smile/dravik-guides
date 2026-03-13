class WeatherForecast {
  final String location;
  final double latitude;
  final double longitude;
  final DateTime forecastDate;
  final double tempC;
  final double feelsLikeC;
  final int humidityPercent;
  final double windKmh;
  final int precipitationMm;
  final String condition;
  final String icon;
  final int uvIndex;
  final DateTime sunrise;
  final DateTime sunset;

  WeatherForecast({
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.forecastDate,
    required this.tempC,
    required this.feelsLikeC,
    required this.humidityPercent,
    required this.windKmh,
    required this.precipitationMm,
    required this.condition,
    required this.icon,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      location: json['location'] ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      forecastDate:
          DateTime.tryParse(json['forecastDate'] ?? '') ?? DateTime.now(),
      tempC: (json['tempC'] as num?)?.toDouble() ?? 0.0,
      feelsLikeC: (json['feelsLikeC'] as num?)?.toDouble() ?? 0.0,
      humidityPercent: (json['humidityPercent'] as num?)?.toInt() ?? 0,
      windKmh: (json['windKmh'] as num?)?.toDouble() ?? 0.0,
      precipitationMm: (json['precipitationMm'] as num?)?.toInt() ?? 0,
      condition: json['condition'] ?? 'Unknown',
      icon: json['icon'] ?? '❓',
      uvIndex: (json['uvIndex'] as num?)?.toInt() ?? 0,
      sunrise: DateTime.tryParse(json['sunrise'] ?? '') ?? DateTime.now(),
      sunset: DateTime.tryParse(json['sunset'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'forecastDate': forecastDate.toIso8601String(),
        'tempC': tempC,
        'feelsLikeC': feelsLikeC,
        'humidityPercent': humidityPercent,
        'windKmh': windKmh,
        'precipitationMm': precipitationMm,
        'condition': condition,
        'icon': icon,
        'uvIndex': uvIndex,
        'sunrise': sunrise.toIso8601String(),
        'sunset': sunset.toIso8601String(),
      };

  bool hasSevereWeather() =>
      condition.toLowerCase().contains('storm') ||
      condition.toLowerCase().contains('tornado') ||
      windKmh > 50 ||
      precipitationMm > 50;

  String getWeatherIcon() {
    final cond = condition.toLowerCase();
    if (cond.contains('cloud')) return '☁️';
    if (cond.contains('rain')) return '🌧️';
    if (cond.contains('snow')) return '❄️';
    if (cond.contains('storm') || cond.contains('thunder')) return '⛈️';
    if (cond.contains('clear') || cond.contains('sunny')) return '☀️';
    if (cond.contains('fog') || cond.contains('mist')) return '🌫️';
    if (cond.contains('wind')) return '💨';
    return icon;
  }
}
