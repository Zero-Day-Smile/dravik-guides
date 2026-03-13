import 'package:hive/hive.dart';
import 'package:dravik/models/weather_forecast.dart';
import 'package:dravik/models/emergency_contact.dart';
import 'package:dravik/services/offline_weather_service.dart';
import 'package:dravik/services/emergency_contact_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherAlertService {
  static final WeatherAlertService _instance = WeatherAlertService._();
  factory WeatherAlertService() => _instance;
  WeatherAlertService._();

  final _weatherService = OfflineWeatherService();
  final _emergencyService = EmergencyContactService();
  Timer? _monitoringTimer;

  Future<Box> _settingsBox() async => Hive.openBox('emergency_settings');

  void startWeatherMonitoring() {
    _monitoringTimer?.cancel();
    // Check every 30 minutes for severe weather
    _monitoringTimer =
        Timer.periodic(const Duration(minutes: 30), (_) => _checkAndAlert());
  }

  void stopWeatherMonitoring() {
    _monitoringTimer?.cancel();
  }

  Future<void> _checkAndAlert() async {
    try {
      final settingsBox = await _settingsBox();
      final isEnabled =
          settingsBox.get('weather_alerts_enabled', defaultValue: true);
      if (!isEnabled) return;

      final coords = await _getLastKnownCoords();
      if (coords == null) return;

      final lat = coords['lat']!;
      final lon = coords['lon']!;
      final forecasts = await _weatherService.getForecast(lat, lon);
      final severeWeather =
          forecasts.where((f) => f.hasSevereWeather()).toList();

      if (severeWeather.isEmpty) return;

      final contacts = await _emergencyService.getContacts();
      if (contacts.isEmpty) return;

      final message = _buildWeatherAlert(severeWeather);
      await _sendWeatherAlerts(message, contacts);
      await _storeWeatherAlert(message, severeWeather);
    } catch (e) {
      // Silently fail
    }
  }

  Future<Map<String, double>?> _getLastKnownCoords() async {
    try {
      final box = await Hive.openBox('offline_weather');
      final keys = box.keys.whereType<String>();
      if (keys.isEmpty) return null;
      final lastKey = keys.last;
      final data = box.get(lastKey) as Map?;
      return {
        'lat': (data?['lat'] as num?)?.toDouble() ?? 0.0,
        'lon': (data?['lon'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      return null;
    }
  }

  String _buildWeatherAlert(List<WeatherForecast> severe) {
    final dates = severe
        .map((f) => f.forecastDate.toString().split(' ')[0])
        .toSet()
        .join(', ');
    final maxWind =
        severe.map((f) => f.windKmh).fold<double>(0, (a, b) => a > b ? a : b);
    final maxPrecip = severe
        .map((f) => f.precipitationMm)
        .fold<int>(0, (a, b) => a > b ? a : b);

    return '⚠️ SEVERE WEATHER ALERT:\n'
        'Dates: $dates\n'
        'Wind: ${maxWind.toInt()} km/h\n'
        'Rain: $maxPrecip mm\n'
        'Plan accordingly. Check 7-Day Weather in Dravik.';
  }

  Future<void> _sendWeatherAlerts(
      String message, List<EmergencyContact> contacts) async {
    final settingsBox = await _settingsBox();
    final twilioSid = settingsBox.get('twilio_sid') as String?;
    final twilioToken = settingsBox.get('twilio_token') as String?;
    final twilioFrom = settingsBox.get('twilio_from') as String?;
    final sendgridKey = settingsBox.get('sendgrid_key') as String?;
    final sendgridFrom = settingsBox.get('sendgrid_from') as String?;

    for (final contact in contacts) {
      // Send SMS
      if (contact.receivesSms &&
          twilioSid != null &&
          twilioToken != null &&
          twilioFrom != null) {
        try {
          final auth = base64Encode(utf8.encode('$twilioSid:$twilioToken'));
          await http.post(
            Uri.parse(
                'https://api.twilio.com/2010-04-01/Accounts/$twilioSid/Messages.json'),
            headers: {
              'Authorization': 'Basic $auth',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'From': twilioFrom,
              'To': contact.phone,
              'Body': message,
            },
          ).timeout(const Duration(seconds: 5));
        } catch (e) {
          // Continue
        }
      }

      // Send Email
      if (contact.receivesEmail &&
          sendgridKey != null &&
          sendgridFrom != null) {
        try {
          await http
              .post(
                Uri.parse('https://api.sendgrid.com/v3/mail/send'),
                headers: {
                  'Authorization': 'Bearer $sendgridKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'personalizations': [
                    {
                      'to': [
                        {'email': contact.email}
                      ],
                    }
                  ],
                  'from': {'email': sendgridFrom},
                  'subject': '⚠️ Severe Weather Alert from Dravik',
                  'content': [
                    {
                      'type': 'text/plain',
                      'value': message,
                    }
                  ],
                }),
              )
              .timeout(const Duration(seconds: 5));
        } catch (e) {
          // Continue
        }
      }
    }
  }

  Future<void> _storeWeatherAlert(
      String message, List<WeatherForecast> severe) async {
    final box = await Hive.openBox('weather_alerts');
    await box.put(
      'latest_alert',
      {
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'severeForecastCount': severe.length,
      },
    );
  }

  Future<Map?> getLatestWeatherAlert() async {
    final box = await Hive.openBox('weather_alerts');
    return box.get('latest_alert') as Map?;
  }

  Future<void> disableWeatherAlerts() async {
    final box = await _settingsBox();
    await box.put('weather_alerts_enabled', false);
  }

  Future<void> enableWeatherAlerts() async {
    final box = await _settingsBox();
    await box.put('weather_alerts_enabled', true);
  }
}
