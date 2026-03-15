import 'package:flutter/material.dart';

class WeatherForecastV2Screen extends StatefulWidget {
  const WeatherForecastV2Screen({super.key});

  @override
  State<WeatherForecastV2Screen> createState() => _WeatherForecastV2ScreenState();
}

class _WeatherForecastV2ScreenState extends State<WeatherForecastV2Screen> {
  int _selectedLocation = 0;

  final List<Map<String, dynamic>> _weatherData = const [
    {
      'location': 'Annapurna, Nepal',
      'current': {'temp': 4, 'feels': 1, 'condition': 'Partly Cloudy', 'humidity': 62, 'wind': 19, 'uv': 4, 'visibility': 8},
      'alerts': [
        {'severity': 'moderate', 'title': 'Wind Advisory', 'description': 'Afternoon gusts may exceed 45 km/h above 3800m.'}
      ],
      'hourly': [
        {'time': '08:00', 'temp': 2, 'icon': '☁️', 'precip': 20},
        {'time': '11:00', 'temp': 4, 'icon': '⛅', 'precip': 12},
        {'time': '14:00', 'temp': 5, 'icon': '🌤️', 'precip': 8},
        {'time': '17:00', 'temp': 3, 'icon': '🌥️', 'precip': 18},
      ],
      'daily': [
        {'day': 'Mon', 'condition': 'Cloudy', 'icon': '☁️', 'high': 5, 'low': -2, 'precip': 24, 'wind': 21},
        {'day': 'Tue', 'condition': 'Light Snow', 'icon': '🌨️', 'high': 2, 'low': -5, 'precip': 61, 'wind': 28},
        {'day': 'Wed', 'condition': 'Clear', 'icon': '☀️', 'high': 6, 'low': -1, 'precip': 4, 'wind': 14},
      ],
    },
    {
      'location': 'Everest, Nepal',
      'current': {'temp': -8, 'feels': -14, 'condition': 'Snow Showers', 'humidity': 55, 'wind': 31, 'uv': 3, 'visibility': 4},
      'alerts': [
        {'severity': 'high', 'title': 'Extreme Cold', 'description': 'Wind chill risk is high above base camp elevation.'},
      ],
      'hourly': [
        {'time': '08:00', 'temp': -10, 'icon': '🌨️', 'precip': 45},
        {'time': '11:00', 'temp': -8, 'icon': '🌨️', 'precip': 52},
        {'time': '14:00', 'temp': -7, 'icon': '☁️', 'precip': 28},
        {'time': '17:00', 'temp': -11, 'icon': '❄️', 'precip': 34},
      ],
      'daily': [
        {'day': 'Mon', 'condition': 'Snow', 'icon': '🌨️', 'high': -7, 'low': -15, 'precip': 64, 'wind': 34},
        {'day': 'Tue', 'condition': 'Blizzard Risk', 'icon': '🌬️', 'high': -9, 'low': -18, 'precip': 72, 'wind': 46},
        {'day': 'Wed', 'condition': 'Partly Clear', 'icon': '🌤️', 'high': -5, 'low': -13, 'precip': 10, 'wind': 22},
      ],
    },
    {
      'location': 'Cusco, Peru',
      'current': {'temp': 12, 'feels': 11, 'condition': 'Sunny', 'humidity': 39, 'wind': 10, 'uv': 8, 'visibility': 12},
      'alerts': [],
      'hourly': [
        {'time': '08:00', 'temp': 9, 'icon': '🌤️', 'precip': 6},
        {'time': '11:00', 'temp': 12, 'icon': '☀️', 'precip': 2},
        {'time': '14:00', 'temp': 15, 'icon': '☀️', 'precip': 0},
        {'time': '17:00', 'temp': 12, 'icon': '⛅', 'precip': 8},
      ],
      'daily': [
        {'day': 'Mon', 'condition': 'Clear', 'icon': '☀️', 'high': 16, 'low': 6, 'precip': 2, 'wind': 11},
        {'day': 'Tue', 'condition': 'Partly Cloudy', 'icon': '⛅', 'high': 15, 'low': 7, 'precip': 8, 'wind': 14},
        {'day': 'Wed', 'condition': 'Clear', 'icon': '☀️', 'high': 17, 'low': 6, 'precip': 1, 'wind': 10},
      ],
    },
  ];

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
      case 'extreme':
        return const Color(0xFFC62828);
      case 'moderate':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _weatherData[_selectedLocation];
    final current = data['current'] as Map<String, dynamic>;
    final alerts = data['alerts'] as List<dynamic>;
    final hourly = data['hourly'] as List<dynamic>;
    final daily = data['daily'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Weather Forecast', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Trail conditions and forecasts', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_weatherData.length, (i) {
            final location = _weatherData[i]['location'].toString();
            final selected = i == _selectedLocation;
            return ChoiceChip(
              selected: selected,
              label: Text(location.split(',').first),
              onSelected: (_) => setState(() => _selectedLocation = i),
            );
          }),
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...alerts.map((item) {
            final alert = item as Map<String, dynamic>;
            final severity = alert['severity'].toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _severityColor(severity).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _severityColor(severity).withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: _severityColor(severity)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(alert['description'].toString(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['location'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${current['temp']}°C', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Feels like ${current['feels']}°C • ${current['condition']}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _metric('Humidity', '${current['humidity']}%'),
                    _metric('Wind', '${current['wind']} km/h'),
                    _metric('UV Index', '${current['uv']}'),
                    _metric('Visibility', '${current['visibility']} km'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today\'s Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, i) {
                      final h = hourly[i] as Map<String, dynamic>;
                      return Container(
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(h['time'].toString(), style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(h['icon'].toString(), style: const TextStyle(fontSize: 22)),
                            const SizedBox(height: 4),
                            Text('${h['temp']}°', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('💧 ${h['precip']}%', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: hourly.length,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('7-Day Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...daily.map((item) {
                  final d = item as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 46, child: Text(d['day'].toString(), style: const TextStyle(fontWeight: FontWeight.w600))),
                        SizedBox(width: 34, child: Text(d['icon'].toString())),
                        Expanded(child: Text(d['condition'].toString())),
                        Text('💧 ${d['precip']}%'),
                        const SizedBox(width: 10),
                        Text('🌬️ ${d['wind']}'),
                        const SizedBox(width: 10),
                        Text('${d['high']}°/${d['low']}°', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(String title, String value) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}
