import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dravik/theme_provider.dart';
import 'package:dravik/services/place_guide_service.dart';
import 'package:dravik/models/place_guide.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class PlaceGuideScreen extends StatefulWidget {
  const PlaceGuideScreen({super.key});

  @override
  State<PlaceGuideScreen> createState() => _PlaceGuideScreenState();
}

class _PlaceGuideScreenState extends State<PlaceGuideScreen> {
  final _service = PlaceGuideService();
  final _queryCtrl = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  PlaceGuide? _guide;
  bool _loading = false;
  bool _generalExpanded = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate({bool forceRefresh = false}) async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) {
      _snack('Enter a destination');
      return;
    }
    setState(() {
      _loading = true;
      _guide = null;
    });
    try {
      final g = await _service.generate(
        placeQuery: q,
        month: _selectedMonth,
        useCache: !forceRefresh,
      );
      setState(() => _guide = g);
      final age = DateTime.now().difference(g.generatedAt);
      if (age.inMinutes < 1) {
        _snack('Guide generated ✓');
      } else if (age.inHours < 24) {
        _snack('Loaded from cache (${age.inHours}h old)');
      } else {
        _snack('Loaded from cache (${age.inDays}d old)');
      }
    } catch (e) {
      _snack('Failed to generate: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat.MMMM().format(DateTime(2000, _selectedMonth));
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Place Guide (AI)'),
            backgroundColor: isDark ? Colors.green[900] : Colors.green[700],
            actions: [
              if (_guide != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh from network',
                  onPressed: () => _generate(forceRefresh: true),
                ),
              if (_guide != null)
                IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'Show on map',
                  onPressed: () {
                    Navigator.pop(context, _guide);
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EditionBannerForScreen(screen: EditionScreen.placeGuide),
                // General Basics at top (expandable)
                Card(
                  elevation: 0,
                  color: isDark ? Colors.black26 : Colors.grey[100],
                  child: ExpansionTile(
                    initiallyExpanded: _generalExpanded,
                    onExpansionChanged: (v) =>
                        setState(() => _generalExpanded = v),
                    title: const Text('General Basics',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        const Text('Safety, prep, packing — quick essentials'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                                '• Check local weather and alerts before travel.'),
                            SizedBox(height: 6),
                            Text(
                                '• Carry ID, basic first aid, water, and sun protection.'),
                            SizedBox(height: 6),
                            Text(
                                '• Know nearest medical facilities and transport options.'),
                            SizedBox(height: 6),
                            Text('• Respect local rules; leave no trace.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Destination (city, region, park, etc.)',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Month:'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(DateFormat.MMMM()
                                    .format(DateTime(2000, m))),
                              ))
                          .toList(),
                      onChanged: (m) =>
                          setState(() => _selectedMonth = m ?? _selectedMonth),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate'),
                      onPressed: _loading ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.green[800] : Colors.green[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (!_loading && _guide != null) ...[
                  _sectionHeader('Overview'),
                  _overviewCard(_guide!, monthName, isDark),
                  const SizedBox(height: 12),
                  if (_guide!.safetyInfo != null) ...[
                    _sectionHeader('🛡️ Solo Traveler Safety'),
                    _safetyCard(_guide!.safetyInfo!, isDark),
                    const SizedBox(height: 12),
                  ],
                  _sectionHeader('Nearest Airports'),
                  _airportsList(_guide!, isDark),
                  const SizedBox(height: 12),
                  _sectionHeader('Nearby Transport'),
                  _transportList(_guide!, isDark),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _overviewCard(PlaceGuide g, String monthName, bool isDark) {
    final climateText = PlaceGuideService().climateDescription(g.climate);
    return Card(
      color: isDark ? Colors.black26 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.placeName,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(climateText),
          const SizedBox(height: 8),
          Text('Tips for $monthName:'),
          const SizedBox(height: 4),
          const Text('• Book transport in advance during peak months.'),
          const Text('• Adjust packing for temperature and rainfall.'),
          const Text('• Check trail or attraction permits if applicable.'),
        ]),
      ),
    );
  }

  Widget _airportsList(PlaceGuide g, bool isDark) {
    if (g.nearestAirports.isEmpty) {
      return Text('No airports found within ~100 km',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));
    }
    return Column(
      children: g.nearestAirports
          .map((a) => Card(
                color: isDark ? Colors.black26 : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.flight_takeoff),
                  title: Text(a.name),
                  subtitle: Text([
                    if (a.iata != null && a.iata!.isNotEmpty) 'IATA: ${a.iata}',
                    if (a.icao != null && a.icao!.isNotEmpty) 'ICAO: ${a.icao}',
                  ].join('  ')),
                  trailing: Text('${a.distanceKm.toStringAsFixed(1)} km'),
                ),
              ))
          .toList(),
    );
  }

  Widget _safetyCard(SoloTravelSafety safety, bool isDark) {
    return Card(
      color: isDark ? Colors.black26 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Numbers
            Row(
              children: [
                const Icon(Icons.emergency, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text('Emergency Numbers',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 8),
            if (safety.emergencyNumber != null)
              Text('🚨 Emergency: ${safety.emergencyNumber}'),
            if (safety.policeNumber != null)
              Text('👮 Police: ${safety.policeNumber}'),
            if (safety.ambulanceNumber != null)
              Text('🚑 Ambulance: ${safety.ambulanceNumber}'),
            const SizedBox(height: 12),

            // Basic Info
            if (safety.currency != null || safety.language != null) ...[
              Row(
                children: [
                  if (safety.currency != null)
                    Expanded(child: Text('💰 Currency: ${safety.currency}')),
                  if (safety.language != null)
                    Expanded(child: Text('🗣️ Language: ${safety.language}')),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Safety Tips
            if (safety.safetyTips.isNotEmpty) ...[
              const Text('Safety Tips:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...safety.safetyTips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
            ],

            // Common Phrases
            if (safety.commonPhrases.isNotEmpty) ...[
              const Text('Essential Phrases:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...safety.commonPhrases.map((phrase) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                        '${phrase['english']}: ${phrase['local'] ?? ''}',
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  )),
              const SizedBox(height: 12),
            ],

            // Local Customs
            if (safety.localCustoms.isNotEmpty) ...[
              const Text('Local Customs:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...safety.localCustoms.map((custom) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(custom)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _transportList(PlaceGuide g, bool isDark) {
    if (g.nearbyTransport.isEmpty) {
      return Text('No public transport stops nearby',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));
    }
    return Column(
      children: g.nearbyTransport
          .map((t) => Card(
                color: isDark ? Colors.black26 : Colors.white,
                child: ListTile(
                  leading: Icon(
                    t.type == 'train'
                        ? Icons.train
                        : t.type == 'subway'
                            ? Icons.directions_subway
                            : Icons.directions_bus,
                  ),
                  title: Text(t.name),
                  subtitle: Text(t.type.toUpperCase()),
                  trailing: Text('${t.distanceKm.toStringAsFixed(1)} km'),
                ),
              ))
          .toList(),
    );
  }
}
