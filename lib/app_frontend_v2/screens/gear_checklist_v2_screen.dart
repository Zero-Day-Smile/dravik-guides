import 'package:flutter/material.dart';

class GearChecklistV2Screen extends StatefulWidget {
  const GearChecklistV2Screen({super.key});

  @override
  State<GearChecklistV2Screen> createState() => _GearChecklistV2ScreenState();
}

class _GearChecklistV2ScreenState extends State<GearChecklistV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _newItemCtrl = TextEditingController();
  final TextEditingController _newWeightCtrl = TextEditingController();
  String? _category;
  String? _terrain;
  double _bmi = 22.9;

  final List<Map<String, dynamic>> _gear = [
    {'name': 'Backpack (65L)', 'category': 'Backpack', 'weight': 1700, 'packed': true, 'essential': true, 'condition': 'Good'},
    {'name': 'Down Jacket', 'category': 'Clothing', 'weight': 580, 'packed': false, 'essential': true, 'condition': 'Excellent'},
    {'name': 'Rain Jacket', 'category': 'Clothing', 'weight': 420, 'packed': true, 'essential': true, 'condition': 'Good'},
    {'name': 'Trekking Poles', 'category': 'Gear', 'weight': 520, 'packed': false, 'essential': true, 'condition': 'Good'},
    {'name': 'Headlamp', 'category': 'Electronics', 'weight': 95, 'packed': true, 'essential': true, 'condition': 'Good'},
    {'name': 'First Aid Kit', 'category': 'Safety', 'weight': 320, 'packed': true, 'essential': true, 'condition': 'Good'},
    {'name': 'Water Filter', 'category': 'Safety', 'weight': 160, 'packed': false, 'essential': false, 'condition': 'New'},
    {'name': 'Sleeping Bag (-10C)', 'category': 'Shelter', 'weight': 1100, 'packed': false, 'essential': true, 'condition': 'Good'},
  ];

  final List<Map<String, dynamic>> _terrainPresets = [
    {
      'id': 'mountain',
      'name': 'Mountain/Altitude',
      'icon': Icons.terrain,
      'essentials': [
        'Trekking Poles',
        'Down Jacket',
        'Sleeping Bag (-10C)',
        'Headlamp',
        'First Aid Kit',
        'Rain Jacket',
        'Backpack (65L)',
      ],
    },
    {
      'id': 'snow',
      'name': 'Snow/Winter',
      'icon': Icons.ac_unit,
      'essentials': [
        'Down Jacket',
        'Sleeping Bag (-10C)',
        'Headlamp',
        'Rain Jacket',
      ],
    },
    {
      'id': 'forest',
      'name': 'Forest/Jungle',
      'icon': Icons.forest,
      'essentials': [
        'Water Filter',
        'First Aid Kit',
        'Rain Jacket',
        'Headlamp',
      ],
    },
    {
      'id': 'desert',
      'name': 'Desert/Arid',
      'icon': Icons.wb_sunny,
      'essentials': [
        'Water Filter',
        'First Aid Kit',
        'Headlamp',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _newItemCtrl.dispose();
    _newWeightCtrl.dispose();
    super.dispose();
  }

  List<String> _bmiSuggestions(double bmi) {
    if (bmi < 18.5) {
      return [
        'Carry extra high-calorie trail food',
        'Use lighter pack target: max 15% body weight',
        'Include extra insulation layers',
      ];
    }
    if (bmi < 25) {
      return [
        'Standard pack weight OK: up to 20% body weight',
        'Balanced hydration and electrolyte strategy',
      ];
    }
    if (bmi < 30) {
      return [
        'Prefer lighter gear alternatives',
        'Use trekking poles on all steep sections',
        'Carry extra hydration reserve',
      ];
    }
    return [
      'Ultralight setup is strongly recommended',
      'Use trekking poles and knee support',
      'Plan shorter daily stage distances',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _gear.map((g) => g['category'].toString()).toSet().toList()..sort();

    final packedCount = _gear.where((g) => g['packed'] == true).length;
    final totalWeight = _gear.fold<int>(0, (sum, g) => sum + (g['weight'] as int));
    final packedWeight = _gear
        .where((g) => g['packed'] == true)
        .fold<int>(0, (sum, g) => sum + (g['weight'] as int));
    final essentialTotal = _gear.where((g) => g['essential'] == true).length;
    final essentialPacked = _gear.where((g) => g['essential'] == true && g['packed'] == true).length;

    final filtered = _gear.where((g) {
      final q = _searchCtrl.text.trim().toLowerCase();
      final matchSearch = q.isEmpty || g['name'].toString().toLowerCase().contains(q);
      final matchCat = _category == null || g['category'] == _category;
      return matchSearch && matchCat;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Gear Checklist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Pack smart, trek safe — customized to your terrain', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 14),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Checklist'),
            Tab(text: 'Terrain Presets'),
            Tab(text: 'Smart Suggestions'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 700,
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView(
                children: [
                  Row(
                    children: [
                      Expanded(child: _statTile(Icons.inventory_2_outlined, '$packedCount/${_gear.length}', 'Items Packed')),
                      const SizedBox(width: 8),
                      Expanded(child: _statTile(Icons.scale_outlined, '${(packedWeight / 1000).toStringAsFixed(1)}kg', 'Packed Weight')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _statTile(Icons.shield_outlined, '$essentialPacked/$essentialTotal', 'Essentials Ready')),
                      const SizedBox(width: 8),
                      Expanded(child: _statTile(Icons.category_outlined, '${categories.length}', 'Categories')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: totalWeight == 0 ? 0 : packedWeight / totalWeight),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newItemCtrl,
                              decoration: const InputDecoration(hintText: 'Item name'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _newWeightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: 'Weight (g)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              final name = _newItemCtrl.text.trim();
                              if (name.isEmpty) return;
                              setState(() {
                                _gear.add({
                                  'name': name,
                                  'category': 'Custom',
                                  'weight': int.tryParse(_newWeightCtrl.text.trim()) ?? 100,
                                  'packed': false,
                                  'essential': false,
                                  'condition': 'New',
                                });
                                _newItemCtrl.clear();
                                _newWeightCtrl.clear();
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search gear...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...filtered.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: item['packed'] as bool,
                          onChanged: (_) => setState(() => item['packed'] = !(item['packed'] as bool)),
                        ),
                        title: Text(
                          item['name'].toString(),
                          style: TextStyle(
                            decoration: item['packed'] == true ? TextDecoration.lineThrough : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text('${item['category']} • ${item['weight']}g • ${item['condition']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item['essential'] == true)
                              const Chip(label: Text('Essential')),
                            IconButton(
                              onPressed: () => setState(() => _gear.remove(item)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              ListView(
                children: [
                  const Text('Select your terrain type and we will mark key essentials.'),
                  const SizedBox(height: 10),
                  ..._terrainPresets.map((preset) {
                    final selected = _terrain == preset['id'];
                    final essentials = preset['essentials'] as List<dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(preset['icon'] as IconData),
                        title: Text(preset['name'].toString()),
                        subtitle: Text(
                          essentials.take(4).join(' • ') +
                              (essentials.length > 4 ? ' • +${essentials.length - 4} more' : ''),
                        ),
                        onTap: () {
                          setState(() {
                            _terrain = preset['id'].toString();
                            for (final g in _gear) {
                              if (essentials.contains(g['name'])) {
                                g['essential'] = true;
                              }
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
              ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Body-Based Suggestions', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('BMI:'),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  controller: TextEditingController(text: _bmi.toStringAsFixed(1)),
                                  onSubmitted: (v) {
                                    final next = double.tryParse(v);
                                    if (next == null) return;
                                    setState(() => _bmi = next);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  _bmi < 18.5
                                      ? 'Underweight'
                                      : _bmi < 25
                                          ? 'Normal'
                                          : _bmi < 30
                                              ? 'Overweight'
                                              : 'Obese',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._bmiSuggestions(_bmi).map(
                            (s) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Text('💡'),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(s)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Pack Weight Guidelines', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          _GuideRow(title: 'Ultralight', range: '< 4.5kg', note: 'Fast and light for experienced trekkers.'),
                          _GuideRow(title: 'Lightweight', range: '4.5 - 9kg', note: 'Balanced comfort and mobility.'),
                          _GuideRow(title: 'Traditional', range: '9 - 14kg', note: 'More comfort items, slower pace.'),
                          _GuideRow(title: 'Heavy', range: '> 14kg', note: 'High strain risk; reduce if possible.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final String title;
  final String range;
  final String note;

  const _GuideRow({required this.title, required this.range, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: $range', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(note, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
