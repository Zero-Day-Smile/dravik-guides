import 'package:flutter/material.dart';

class AnalyticsV2Screen extends StatefulWidget {
  const AnalyticsV2Screen({super.key});

  @override
  State<AnalyticsV2Screen> createState() => _AnalyticsV2ScreenState();
}

class _AnalyticsV2ScreenState extends State<AnalyticsV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final List<Map<String, dynamic>> _devices = [
    {
      'name': 'Apple Watch',
      'icon': '⌚',
      'connected': false,
      'metrics': ['Heart Rate', 'Steps', 'Calories', 'SpO2'],
    },
    {
      'name': 'Garmin',
      'icon': '🧭',
      'connected': true,
      'metrics': ['GPS Track', 'Elevation', 'Heart Rate', 'Cadence'],
    },
    {
      'name': 'Fitbit',
      'icon': '📟',
      'connected': false,
      'metrics': ['Steps', 'Heart Rate', 'Sleep', 'Calories'],
    },
  ];

  final List<Map<String, dynamic>> _activityLogs = const [
    {'type': 'trek', 'distance': 12.4, 'elevation': 930, 'calories': 980, 'durationMin': 240, 'date': '2026-03-10'},
    {'type': 'hike', 'distance': 8.1, 'elevation': 420, 'calories': 610, 'durationMin': 150, 'date': '2026-03-08'},
    {'type': 'climb', 'distance': 5.6, 'elevation': 1260, 'calories': 840, 'durationMin': 190, 'date': '2026-03-05'},
    {'type': 'run', 'distance': 6.3, 'elevation': 120, 'calories': 470, 'durationMin': 42, 'date': '2026-03-03'},
  ];

  final List<Map<String, dynamic>> _achievements = const [
    {'name': 'Trailhead', 'icon': '🏕️', 'desc': 'Begin your journey', 'rarity': 'common', 'unlocked': true},
    {'name': 'Summit Conqueror', 'icon': '⛰️', 'desc': 'Complete a hard trail', 'rarity': 'rare', 'unlocked': true},
    {'name': 'Storm Survivor', 'icon': '🌪️', 'desc': 'Trek severe weather', 'rarity': 'epic', 'unlocked': false},
    {'name': 'Dragon Eye', 'icon': '🐉', 'desc': 'Reach level 10', 'rarity': 'legendary', 'unlocked': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = _activityLogs.fold<double>(0, (s, e) => s + (e['distance'] as double));
    final totalElevation = _activityLogs.fold<int>(0, (s, e) => s + (e['elevation'] as int));
    final totalCalories = _activityLogs.fold<int>(0, (s, e) => s + (e['calories'] as int));
    final totalDuration = _activityLogs.fold<int>(0, (s, e) => s + (e['durationMin'] as int));

    final unlocked = _achievements.where((a) => a['unlocked'] == true).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Your trekking performance dashboard', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Wearables'),
            Tab(text: 'Achievements'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 620,
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statCard(Icons.route, '${totalDistance.toStringAsFixed(1)} km', 'Total Distance')),
                      const SizedBox(width: 8),
                      Expanded(child: _statCard(Icons.trending_up, '${(totalElevation / 1000).toStringAsFixed(1)}k m', 'Total Elevation')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _statCard(Icons.local_fire_department, '${(totalCalories / 1000).toStringAsFixed(1)}k', 'Calories Burned')),
                      const SizedBox(width: 8),
                      Expanded(child: _statCard(Icons.timer_outlined, '${(totalDuration / 60).round()}h', 'Time on Trail')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_devices.any((d) => d['connected'] == true))
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Live Health Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _metricTile('Heart Rate', '92 bpm', Icons.favorite, const Color(0xFFC62828)),
                                _metricTile('Steps Today', '8,432', Icons.directions_walk, const Color(0xFF1565C0)),
                                _metricTile('SpO2', '96%', Icons.bolt, const Color(0xFF00838F)),
                                _metricTile('Calories', '1,847', Icons.local_fire_department, const Color(0xFFEF6C00)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ..._activityLogs.reversed.map((log) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                                    child: Text(log['type'].toString().substring(0, 1).toUpperCase()),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(log['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(log['date'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Text('${log['distance']} km • ${log['elevation']}m', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, i) {
                  final device = _devices[i];
                  final connected = device['connected'] as bool;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Text(device['icon'].toString(), style: const TextStyle(fontSize: 26)),
                      title: Text(device['name'].toString()),
                      subtitle: Text((device['metrics'] as List<dynamic>).join(' • ')),
                      trailing: TextButton(
                        onPressed: () => setState(() => device['connected'] = !connected),
                        child: Text(connected ? 'Sync' : 'Connect'),
                      ),
                    ),
                  );
                },
              ),
              ListView(
                children: [
                  Text('$unlocked/${_achievements.length} unlocked', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _achievements.map((a) {
                      final isUnlocked = a['unlocked'] == true;
                      return Container(
                        width: 180,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUnlocked ? Colors.white : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['icon'].toString(), style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text(a['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(a['desc'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 5),
                            Text(
                              a['rarity'].toString().toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
