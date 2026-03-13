import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dravik/models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _cacheBoxName = 'weather_cache';
  static const Duration _cacheDuration = Duration(hours: 1);

  String get _apiKey {
    try {
      return dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  // Fetch current weather and forecasts
  Future<WeatherData?> getWeather(double lat, double lon) async {
    try {
      // Check cache first
      final cached = await _getCachedWeather(lat, lon);
      if (cached != null) return cached;

      // Fetch from API
      final currentResponse = await http
          .get(
            Uri.parse(
                '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
          )
          .timeout(const Duration(seconds: 10));

      if (currentResponse.statusCode != 200) return null;

      final forecastResponse = await http
          .get(
            Uri.parse(
                '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric'),
          )
          .timeout(const Duration(seconds: 10));

      if (forecastResponse.statusCode != 200) return null;

      final currentData = json.decode(currentResponse.body);
      final forecastData = json.decode(forecastResponse.body);

      final weather = _parseWeatherData(currentData, forecastData);

      // Cache the result
      await _cacheWeather(lat, lon, weather);

      return weather;
    } catch (e) {
      // Return cached data if available, even if expired
      return await _getCachedWeather(lat, lon, ignoreExpiry: true);
    }
  }

  WeatherData _parseWeatherData(
      Map<String, dynamic> current, Map<String, dynamic> forecast) {
    final hourlyList = (forecast['list'] as List).take(24).map((item) {
      return HourlyForecast(
        time: DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
        temperature: (item['main']['temp'] as num).toDouble(),
        description: item['weather'][0]['description'],
        icon: item['weather'][0]['icon'],
        precipProbability: ((item['pop'] ?? 0) * 100).toInt(),
      );
    }).toList();

    final dailyMap = <String, DailyForecast>{};
    for (var item in forecast['list']) {
      final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final dateKey = '${date.year}-${date.month}-${date.day}';

      final temp = (item['main']['temp'] as num).toDouble();
      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailyForecast(
          date: date,
          tempMax: temp,
          tempMin: temp,
          description: item['weather'][0]['description'],
          icon: item['weather'][0]['icon'],
          precipProbability: ((item['pop'] ?? 0) * 100).toInt(),
        );
      } else {
        final existing = dailyMap[dateKey]!;
        dailyMap[dateKey] = DailyForecast(
          date: existing.date,
          tempMax: temp > existing.tempMax ? temp : existing.tempMax,
          tempMin: temp < existing.tempMin ? temp : existing.tempMin,
          description: existing.description,
          icon: existing.icon,
          precipProbability: existing.precipProbability,
        );
      }
    }

    final alerts = <WeatherAlert>[];
    if (current['alerts'] != null) {
      for (var alert in current['alerts']) {
        alerts.add(WeatherAlert(
          title: alert['event'] ?? '',
          description: alert['description'] ?? '',
          severity: _parseSeverity(alert['severity'] ?? 'low'),
          startTime: DateTime.fromMillisecondsSinceEpoch(alert['start'] * 1000),
          endTime: DateTime.fromMillisecondsSinceEpoch(alert['end'] * 1000),
          source: alert['sender_name'] ?? 'Weather Service',
        ));
      }
    }

    return WeatherData(
      location: current['name'] ?? '',
      temperature: (current['main']['temp'] as num).toDouble(),
      feelsLike: (current['main']['feels_like'] as num).toDouble(),
      humidity: current['main']['humidity'],
      windSpeed: (current['wind']['speed'] as num).toDouble(),
      description: current['weather'][0]['description'],
      icon: current['weather'][0]['icon'],
      timestamp: DateTime.now(),
      hourly: hourlyList,
      daily: dailyMap.values.take(7).toList(),
      alerts: alerts,
    );
  }

  AlertSeverity _parseSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return AlertSeverity.extreme;
      case 'severe':
      case 'high':
        return AlertSeverity.high;
      case 'moderate':
      case 'medium':
        return AlertSeverity.medium;
      default:
        return AlertSeverity.low;
    }
  }

  Future<WeatherData?> _getCachedWeather(double lat, double lon,
      {bool ignoreExpiry = false}) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final key = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
      final cached = box.get(key);

      if (cached == null) return null;

      final data = json.decode(cached);
      final timestamp = DateTime.parse(data['cachedAt']);

      if (!ignoreExpiry &&
          DateTime.now().difference(timestamp) > _cacheDuration) {
        return null;
      }

      return WeatherData.fromJson(data['weather']);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheWeather(
      double lat, double lon, WeatherData weather) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final key = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
      final data = {
        'cachedAt': DateTime.now().toIso8601String(),
        'weather': weather.toJson(),
      };
      await box.put(key, json.encode(data));
    } catch (e) {
      // Ignore cache errors
    }
  }

  // Manage safety alerts
  Future<List<SafetyAlert>> getNearbyAlerts(double lat, double lon,
      {double radiusKm = 50}) async {
    try {
      // This would connect to your Supabase backend
      // For now, return empty list
      final box = await Hive.openBox('safety_alerts');
      final alerts = box.get('cached_alerts', defaultValue: []);

      if (alerts is List) {
        return alerts
            .map<SafetyAlert>((a) => SafetyAlert.fromJson(json.decode(a)))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> reportAlert(SafetyAlert alert) async {
    try {
      // Save to Hive for offline
      final box = await Hive.openBox('safety_alerts');
      final alerts = box.get('pending_reports', defaultValue: []) as List;
      alerts.add(json.encode(alert.toJson()));
      await box.put('pending_reports', alerts);

      // TODO: Sync to Supabase when online
    } catch (e) {
      // Handle error
    }
  }

  String getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return '☀️';
      case '02d':
      case '02n':
        return '⛅';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧️';
      case '10d':
      case '10n':
        return '🌦️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
