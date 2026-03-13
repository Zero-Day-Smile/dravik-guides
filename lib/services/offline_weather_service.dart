import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:dravik/models/weather_forecast.dart';

class OfflineWeatherService {
  static final OfflineWeatherService _instance = OfflineWeatherService._();
  factory OfflineWeatherService() => _instance;
  OfflineWeatherService._();

  // Using open-meteo.com (free, no API key required)
  static const String _openMeteoUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Box> _weatherBox() async => Hive.openBox('offline_weather');

  Future<void> downloadForecast(
      double lat, double lon, String locationName) async {
    try {
      // Fetch 7-day forecast from open-meteo
      final uri = Uri.parse(_openMeteoUrl).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max,uv_index_max,sunrise,sunset',
        'timezone': 'UTC',
        'forecast_days': '7',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>? ?? {};
      final dates = daily['time'] as List? ?? [];
      final tempMax = daily['temperature_2m_max'] as List? ?? [];
      final tempMin = daily['temperature_2m_min'] as List? ?? [];
      final precip = daily['precipitation_sum'] as List? ?? [];
      final wind = daily['windspeed_10m_max'] as List? ?? [];
      final uvIndex = daily['uv_index_max'] as List? ?? [];
      final sunrises = daily['sunrise'] as List? ?? [];
      final sunsets = daily['sunset'] as List? ?? [];

      final box = await _weatherBox();
      final forecasts = <WeatherForecast>[];

      for (int i = 0; i < dates.length && i < 7; i++) {
        final condition = _weatherCodeToCondition(daily['weather_code'] != null
            ? (daily['weather_code'] as List?)?.elementAt(i)
            : null);
        final forecast = WeatherForecast(
          location: locationName,
          latitude: lat,
          longitude: lon,
          forecastDate: DateTime.parse(dates[i].toString()),
          tempC: ((tempMax.elementAt(i) as num?) ?? 0).toDouble(),
          feelsLikeC: ((tempMin.elementAt(i) as num?) ?? 0).toDouble(),
          humidityPercent: 65, // Not in free API
          windKmh: ((wind.elementAt(i) as num?) ?? 0).toDouble(),
          precipitationMm: ((precip.elementAt(i) as num?) ?? 0).toInt(),
          condition: condition,
          icon: _getWeatherIcon(condition),
          uvIndex: ((uvIndex.elementAt(i) as num?) ?? 0).toInt(),
          sunrise: DateTime.tryParse(sunrises.elementAt(i).toString()) ??
              DateTime.now(),
          sunset: DateTime.tryParse(sunsets.elementAt(i).toString()) ??
              DateTime.now(),
        );
        forecasts.add(forecast);
      }

      // Store with region key
      final key = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
      await box.put(key, {
        'location': locationName,
        'lat': lat,
        'lon': lon,
        'fetchedAt': DateTime.now().toIso8601String(),
        'forecasts': forecasts.map((f) => f.toJson()).toList(),
      });
    } catch (e) {
      // Silently fail; offline data will be used
    }
  }

  Future<List<WeatherForecast>> getForecast(double lat, double lon) async {
    final box = await _weatherBox();
    final key = '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
    final data = box.get(key) as Map?;
    if (data == null) return [];

    final forecasts = (data['forecasts'] as List?)
            ?.map((f) =>
                WeatherForecast.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList() ??
        [];
    return forecasts;
  }

  String _weatherCodeToCondition(dynamic code) {
    // WMO Weather codes
    final c = (code as num?)?.toInt() ?? 0;
    if (c == 0) return 'Clear';
    if (c == 1 || c == 2) return 'Partly cloudy';
    if (c == 3) return 'Overcast';
    if (c >= 45 && c <= 48) return 'Foggy';
    if (c >= 51 && c <= 67) return 'Drizzle';
    if (c >= 71 && c <= 77) return 'Snow';
    if (c >= 80 && c <= 82) return 'Rain showers';
    if (c >= 85 && c <= 86) return 'Snow showers';
    if (c >= 80 && c <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  String _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('clear')) return '☀️';
    if (cond.contains('cloud')) return '☁️';
    if (cond.contains('rain') || cond.contains('drizzle')) return '🌧️';
    if (cond.contains('snow')) return '❄️';
    if (cond.contains('storm') || cond.contains('thunder')) return '⛈️';
    if (cond.contains('fog')) return '🌫️';
    return '🌤️';
  }
}
