import 'package:flutter/material.dart';

class CountryExplorerV2Screen extends StatefulWidget {
  const CountryExplorerV2Screen({super.key});

  @override
  State<CountryExplorerV2Screen> createState() => _CountryExplorerV2ScreenState();
}

class _CountryExplorerV2ScreenState extends State<CountryExplorerV2Screen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _region;
  String? _selectedId;

  final List<Map<String, dynamic>> _countries = const [
    {
      'id': 'np',
      'name': 'Nepal',
      'capital': 'Kathmandu',
      'region': 'Asia',
      'flag': '🇳🇵',
      'safety': 4.3,
      'visa': true,
      'desc': 'Home to the Himalayas and world-class high-altitude trekking.',
      'languages': ['Nepali', 'English'],
      'season': 'Mar-May, Oct-Nov',
      'emergency': '100',
      'populationM': 30.5,
      'highlights': ['Everest Base Camp', 'Annapurna Circuit', 'Langtang Valley'],
      'currency': 'NPR',
      'timezone': 'UTC+5:45',
    },
    {
      'id': 'pe',
      'name': 'Peru',
      'capital': 'Lima',
      'region': 'South America',
      'flag': '🇵🇪',
      'safety': 3.9,
      'visa': false,
      'desc': 'Andean terrain, Inca trails, and rich mountain culture.',
      'languages': ['Spanish', 'Quechua'],
      'season': 'May-Sep',
      'emergency': '105',
      'populationM': 34.0,
      'highlights': ['Inca Trail', 'Salkantay Trek', 'Ausangate Circuit'],
      'currency': 'PEN',
      'timezone': 'UTC-5',
    },
    {
      'id': 'ch',
      'name': 'Switzerland',
      'capital': 'Bern',
      'region': 'Europe',
      'flag': '🇨🇭',
      'safety': 4.8,
      'visa': false,
      'desc': 'Premium alpine infrastructure and highly marked routes.',
      'languages': ['German', 'French', 'Italian'],
      'season': 'Jun-Sep',
      'emergency': '112',
      'populationM': 8.9,
      'highlights': ['Tour du Mont Blanc', 'Eiger Trail', 'Via Alpina'],
      'currency': 'CHF',
      'timezone': 'UTC+1',
    },
    {
      'id': 'is',
      'name': 'Iceland',
      'capital': 'Reykjavik',
      'region': 'Europe',
      'flag': '🇮🇸',
      'safety': 4.6,
      'visa': false,
      'desc': 'Volcanic landscapes and famous multi-day trekking routes.',
      'languages': ['Icelandic', 'English'],
      'season': 'Jun-Aug',
      'emergency': '112',
      'populationM': 0.4,
      'highlights': ['Laugavegur', 'Fimmvorduhals', 'Hornstrandir'],
      'currency': 'ISK',
      'timezone': 'UTC+0',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regions = _countries.map((c) => c['region'].toString()).toSet().toList()..sort();

    final filtered = _countries.where((c) {
      final q = _searchCtrl.text.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          c['name'].toString().toLowerCase().contains(q) ||
          c['capital'].toString().toLowerCase().contains(q);
      final matchRegion = _region == null || c['region'] == _region;
      return matchSearch && matchRegion;
    }).toList();

    final selected = _countries.where((c) => c['id'] == _selectedId).cast<Map<String, dynamic>?>().firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Country Explorer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Research trekking destinations worldwide', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search countries...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _region == null,
                    onSelected: (_) => setState(() => _region = null),
                  ),
                  ...regions.map(
                    (r) => ChoiceChip(
                      label: Text(r),
                      selected: _region == r,
                      onSelected: (_) => setState(() => _region = r),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.6,
                    ),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      final isSelected = c['id'] == _selectedId;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _selectedId = c['id'].toString()),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['flag'].toString(), style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(c['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${c['capital']} • ${c['region']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                const Spacer(),
                                Text('Safety ${c['safety']}/5 • ${c['visa'] == true ? 'Visa Required' : 'Visa Free'}', style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: selected == null
                          ? const Center(child: Text('Select a country to explore'))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${selected['flag']} ${selected['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                Text(selected['capital'].toString(), style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 10),
                                Text(selected['desc'].toString()),
                                const SizedBox(height: 10),
                                _detailLine(Icons.language, 'Languages', (selected['languages'] as List<dynamic>).join(', ')),
                                _detailLine(Icons.calendar_month, 'Best Season', selected['season'].toString()),
                                _detailLine(Icons.shield_outlined, 'Safety', '${selected['safety']} / 5.0'),
                                _detailLine(Icons.phone_outlined, 'Emergency', selected['emergency'].toString()),
                                _detailLine(Icons.groups_outlined, 'Population', '${selected['populationM']}M'),
                                const SizedBox(height: 10),
                                const Text('Top Treks', style: TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                ...(selected['highlights'] as List<dynamic>).map(
                                  (h) => Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.place_outlined, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(h.toString())),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(child: _miniBox('Currency', selected['currency'].toString())),
                                    const SizedBox(width: 8),
                                    Expanded(child: _miniBox('Timezone', selected['timezone'].toString())),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          SizedBox(width: 90, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  Widget _miniBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}
