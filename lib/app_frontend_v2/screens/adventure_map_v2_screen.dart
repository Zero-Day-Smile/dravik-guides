import 'package:flutter/material.dart';

class AdventureMapV2Screen extends StatefulWidget {
  const AdventureMapV2Screen({super.key});

  @override
  State<AdventureMapV2Screen> createState() => _AdventureMapV2ScreenState();
}

class _AdventureMapV2ScreenState extends State<AdventureMapV2Screen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showPins = true;
  bool _showLayers = false;
  bool _showOffline = false;
  bool _addingPin = false;
  String _activeLayer = 'Street';

  final List<String> _layers = const ['Street', 'Topographic', 'Satellite', 'Terrain'];

  final List<Map<String, dynamic>> _offlineMaps = [
    {'region': 'Nepal Himalayas', 'size': '245 MB', 'downloaded': false},
    {'region': 'European Alps', 'size': '380 MB', 'downloaded': true},
    {'region': 'Andes Range', 'size': '290 MB', 'downloaded': false},
    {'region': 'Rocky Mountains', 'size': '310 MB', 'downloaded': false},
  ];

  final List<Map<String, dynamic>> _pins = [
    {
      'title': 'Annapurna Base Camp',
      'note': 'Reached ABC. Crystal clear sunrise and stable trail conditions.',
      'type': 'visited',
      'icon': Icons.pin_drop,
      'date': '2026-01-15',
      'coords': '28.53, 83.87',
    },
    {
      'title': 'EBC Viewpoint',
      'note': 'Kala Patthar viewpoint. Windy but outstanding visibility.',
      'type': 'viewpoint',
      'icon': Icons.visibility,
      'date': '2026-02-20',
      'coords': '27.98, 86.85',
    },
    {
      'title': 'Sun Gate Camp',
      'note': 'Best campsite before sunrise push. Water source nearby.',
      'type': 'campsite',
      'icon': Icons.terrain,
      'date': '2025-09-10',
      'coords': '-13.16, -72.54',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPins = _pins.where((pin) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return pin['title'].toString().toLowerCase().contains(q) ||
          pin['note'].toString().toLowerCase().contains(q);
    }).toList();

    return Row(
      children: [
        if (_showPins)
          SizedBox(
            width: 320,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Travel Pins',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showPins = false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search pins...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: filteredPins.length,
                      itemBuilder: (context, i) {
                        final pin = filteredPins[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(pin['icon'] as IconData),
                            title: Text(pin['title'].toString()),
                            subtitle: Text('${pin['date']} • ${pin['coords']}\n${pin['note']}'),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F2FF), Color(0xFFE7FAF0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.public, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Adventure Map • $_activeLayer Layer',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Chip(label: Text('${filteredPins.length} pins')),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 64, color: Colors.black45),
                            SizedBox(height: 8),
                            Text(
                              'Interactive map canvas (V2)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap Add Pin to capture coordinates and notes.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Row(
                        children: [
                          _statTile('Pins', '${filteredPins.length}'),
                          const SizedBox(width: 8),
                          _statTile('Regions', '3'),
                          const SizedBox(width: 8),
                          _statTile('Trails', '24'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showPins = !_showPins),
                      icon: const Icon(Icons.pin_drop_outlined),
                      label: Text('Pins (${_pins.length})'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showLayers = !_showLayers),
                      icon: const Icon(Icons.layers_outlined),
                      label: const Text('Layers'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showOffline = !_showOffline),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Offline'),
                    ),
                    FilledButton.icon(
                      onPressed: () => setState(() => _addingPin = !_addingPin),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text(_addingPin ? 'Tap map to pin' : 'Add Pin'),
                    ),
                  ],
                ),
              ),
              if (_showLayers)
                Positioned(
                  top: 74,
                  left: 150,
                  child: Card(
                    child: SizedBox(
                      width: 200,
                      child: Column(
                        children: _layers
                            .map(
                              (layer) => ListTile(
                                leading: Icon(
                                  _activeLayer == layer
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                title: Text(layer),
                                onTap: () {
                                  setState(() {
                                    _activeLayer = layer;
                                    _showLayers = false;
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              if (_showOffline)
                Positioned(
                  top: 74,
                  right: 20,
                  child: Card(
                    child: SizedBox(
                      width: 280,
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _offlineMaps.length,
                        itemBuilder: (context, i) {
                          final item = _offlineMaps[i];
                          final downloaded = item['downloaded'] as bool;
                          return ListTile(
                            dense: true,
                            title: Text(item['region'].toString()),
                            subtitle: Text(item['size'].toString()),
                            trailing: TextButton(
                              onPressed: () {
                                setState(() => item['downloaded'] = !downloaded);
                              },
                              child: Text(downloaded ? 'Remove' : 'Get'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
