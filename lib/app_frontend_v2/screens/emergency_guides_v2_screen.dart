import 'package:flutter/material.dart';

class EmergencyGuidesV2Screen extends StatefulWidget {
  const EmergencyGuidesV2Screen({super.key});

  @override
  State<EmergencyGuidesV2Screen> createState() => _EmergencyGuidesV2ScreenState();
}

class _EmergencyGuidesV2ScreenState extends State<EmergencyGuidesV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _sosActive = false;
  String _sosScope = 'none';

  final TextEditingController _countrySearch = TextEditingController();
  final TextEditingController _helpMessage = TextEditingController();
  String? _category;

  final List<Map<String, dynamic>> _guides = [
    {
      'title': 'Severe Altitude Sickness (HACE/HAPE)',
      'category': 'Medical',
      'severity': 'critical',
      'summary': 'Life-threatening symptoms above 2500m. Immediate descent is mandatory.',
      'steps': [
        'Stop ascending immediately',
        'Descend at least 500-1000m quickly',
        'Administer oxygen and dexamethasone if available',
        'Keep patient warm and evacuate urgently',
      ],
      'icon': '🫁',
    },
    {
      'title': 'Lost Without GPS',
      'category': 'Navigation',
      'severity': 'important',
      'summary': 'Use STOP protocol and avoid random movement.',
      'steps': [
        'Stop, Sit, Think, Observe, Plan',
        'Use whistle in 3-blast pattern',
        'Follow drainage only if safe',
        'Create visible rescue markers',
      ],
      'icon': '🧭',
    },
    {
      'title': 'Lightning Safety',
      'category': 'Weather',
      'severity': 'important',
      'summary': 'Move away from ridges and isolated trees immediately.',
      'steps': [
        'Descend from peaks/ridges',
        'Avoid water and metal gear',
        'Spread group 15m apart',
        'Wait 30 minutes after last thunder',
      ],
      'icon': '⚡',
    },
    {
      'title': 'Hypothermia Treatment',
      'category': 'Medical',
      'severity': 'critical',
      'summary': 'Core temperature under 35°C needs rapid warming and shelter.',
      'steps': [
        'Move to shelter and remove wet clothes',
        'Insulate from ground',
        'Apply warm packs to core',
        'Monitor breathing and consciousness',
      ],
      'icon': '🥶',
    },
  ];

  final List<Map<String, String>> _countries = [
    {'country': 'Nepal', 'flag': '🇳🇵', 'police': '100', 'ambulance': '102', 'fire': '101', 'mountain': '1166'},
    {'country': 'India', 'flag': '🇮🇳', 'police': '100', 'ambulance': '108', 'fire': '101', 'mountain': '112'},
    {'country': 'USA', 'flag': '🇺🇸', 'police': '911', 'ambulance': '911', 'fire': '911', 'mountain': '911'},
    {'country': 'France', 'flag': '🇫🇷', 'police': '17', 'ambulance': '15', 'fire': '18', 'mountain': '112'},
    {'country': 'Switzerland', 'flag': '🇨🇭', 'police': '117', 'ambulance': '144', 'fire': '118', 'mountain': '1414'},
    {'country': 'Chile', 'flag': '🇨🇱', 'police': '133', 'ambulance': '131', 'fire': '132', 'mountain': '136'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _countrySearch.dispose();
    _helpMessage.dispose();
    super.dispose();
  }

  Color _severityColor(String value) {
    switch (value) {
      case 'critical':
        return const Color(0xFFC62828);
      case 'important':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _guides.map((g) => g['category'].toString()).toSet().toList();
    final filteredGuides = _guides.where((g) {
      if (_category == null) return true;
      return g['category'] == _category;
    }).toList();

    final countries = _countries.where((c) {
      final q = _countrySearch.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c['country']!.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Emergency Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('SOS, emergency guides, and worldwide emergency numbers', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: _sosActive ? const Color(0xFFC62828) : const Color(0xFFEF9A9A)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _sosActive ? const Color(0xFFC62828) : const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sos,
                        color: _sosActive ? Colors.white : const Color(0xFFC62828),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Emergency SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(
                            _sosActive
                                ? 'Broadcasting to ${_sosScope == 'group' ? 'your pack' : 'all nearby users'}'
                                : 'Activate to share your location and call for help',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    if (_sosActive)
                      TextButton(
                        onPressed: () => setState(() {
                          _sosActive = false;
                          _sosScope = 'none';
                        }),
                        child: const Text('Cancel SOS'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_sosActive)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => setState(() {
                            _sosActive = true;
                            _sosScope = 'group';
                          }),
                          icon: const Icon(Icons.groups),
                          label: const Text('SOS to Pack'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => setState(() {
                            _sosActive = true;
                            _sosScope = 'all';
                          }),
                          icon: const Icon(Icons.wifi_tethering),
                          label: const Text('Broadcast SOS'),
                        ),
                      ),
                    ],
                  ),
                if (_sosActive)
                  Column(
                    children: [
                      TextField(
                        controller: _helpMessage,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Describe your situation, injuries, and what help you need...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Upload Photo')),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.location_on_outlined), label: const Text('Share Location')),
                          const Spacer(),
                          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('Send')), 
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Guides'),
            Tab(text: 'Emergency Numbers'),
            Tab(text: 'Request Help'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 560,
          child: TabBarView(
            controller: _tabs,
            children: [
              Column(
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      ...categories.map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredGuides.length,
                      itemBuilder: (context, i) {
                        final guide = filteredGuides[i];
                        final steps = guide['steps'] as List<dynamic>;
                        final severity = guide['severity'].toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            leading: Text(guide['icon'].toString(), style: const TextStyle(fontSize: 24)),
                            title: Text(guide['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(guide['summary'].toString()),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _severityColor(severity).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                severity,
                                style: TextStyle(
                                  color: _severityColor(severity),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              ...List.generate(
                                steps.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 18, child: Text('${index + 1}.', style: const TextStyle(fontWeight: FontWeight.w700))),
                                      Expanded(child: Text(steps[index].toString())),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  TextField(
                    controller: _countrySearch,
                    decoration: const InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: countries.length,
                      itemBuilder: (context, i) {
                        final c = countries[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c['flag']} ${c['country']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _numTile('Police', c['police']!),
                                    _numTile('Ambulance', c['ambulance']!),
                                    _numTile('Fire', c['fire']!),
                                    _numTile('Mountain', c['mountain']!),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Request Help', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text('If you are stuck, injured, or lost, send a detailed help request.'),
                      const SizedBox(height: 12),
                      const TextField(
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Describe your location, condition, and required support...',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file), label: const Text('Upload Photos')),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.gps_fixed), label: const Text('Share GPS')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Send to:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(onPressed: () {}, child: const Text('Pack Members')),
                          OutlinedButton(onPressed: () {}, child: const Text('Nearby Users')),
                          FilledButton(onPressed: () {}, child: const Text('Emergency Services')),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send), label: const Text('Send Help Request')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _numTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
