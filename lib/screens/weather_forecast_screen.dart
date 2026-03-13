import 'package:flutter/material.dart';
import 'package:dravik/models/weather_forecast.dart';
import 'package:dravik/services/offline_weather_service.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class WeatherForecastScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const WeatherForecastScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  final _weatherService = OfflineWeatherService();
  List<WeatherForecast> _forecasts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _loading = true);
    // Download fresh forecast
    await _weatherService.downloadForecast(
      widget.latitude,
      widget.longitude,
      widget.locationName,
    );
    // Then load from cache
    final forecasts =
        await _weatherService.getForecast(widget.latitude, widget.longitude);
    if (mounted) {
      setState(() {
        _forecasts = forecasts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = _loading
        ? const Center(child: CircularProgressIndicator())
        : _forecasts.isEmpty
            ? const Center(
                child: Text(
                    'No forecast data. Check internet connection and try again.'),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Severe weather banner (if any)
                    ..._buildSevereWeatherBanners(),
                    // 7-day cards
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _forecasts.length,
                        itemBuilder: (context, i) =>
                            _buildForecastCard(_forecasts[i]),
                      ),
                    ),
                  ],
                ),
              );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.locationName} — 7-Day Forecast'),
        backgroundColor: Colors.deepPurple.shade700,
        elevation: 0,
      ),
      body: Column(
        children: [
          const EditionBannerForScreen(screen: EditionScreen.weather),
          Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadWeather,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  List<Widget> _buildSevereWeatherBanners() {
    final severe = _forecasts.where((f) => f.hasSevereWeather()).toList();
    if (severe.isEmpty) return [];

    return [
      Container(
        width: double.infinity,
        color: Colors.red.shade700,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Severe Weather Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Storm/wind expected on ${severe.map((f) => f.forecastDate.toString().split(' ')[0]).join(', ')}. Plan accordingly.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildForecastCard(WeatherForecast forecast) {
    final isSevere = forecast.hasSevereWeather();
    final icon = forecast.getWeatherIcon();
    final dateStr = forecast.forecastDate.toString().split(' ')[0];
    final dayName = _getDayName(forecast.forecastDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: isSevere ? Colors.orange.shade50 : Colors.white,
      elevation: isSevere ? 4 : 1,
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 32)),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dayName ($dateStr)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    forecast.condition,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (isSevere)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⚠️ SEVERE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${forecast.tempC.toInt()}°C (high) / ${forecast.feelsLikeC.toInt()}°C (low)'),
                Text('💨 ${forecast.windKmh.toInt()} km/h'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('💧 ${forecast.precipitationMm} mm'),
                Text('☀️ UV ${forecast.uvIndex}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '🌅 ${forecast.sunrise.toString().split(' ')[1].substring(0, 5)}'),
                Text(
                    '🌇 ${forecast.sunset.toString().split(' ')[1].substring(0, 5)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday % 7];
  }
}
