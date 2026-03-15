import 'package:flutter/material.dart';

class TrailMapsV2Screen extends StatefulWidget {
  const TrailMapsV2Screen({super.key});

  @override
  State<TrailMapsV2Screen> createState() => _TrailMapsV2ScreenState();
}

class _TrailMapsV2ScreenState extends State<TrailMapsV2Screen> {
  final TextEditingController _search = TextEditingController();
  String? _difficulty;
  Map<String, dynamic>? _selected;

  final List<Map<String, dynamic>> _trails = const [
    {'name': 'Annapurna Base Camp', 'location': 'Pokhara, Nepal', 'difficulty': 'hard', 'distance': 110, 'elevation': 4130, 'rating': 4.8},
    {'name': 'Everest Base Camp', 'location': 'Solukhumbu, Nepal', 'difficulty': 'hard', 'distance': 130, 'elevation': 5364, 'rating': 4.9},
    {'name': 'Inca Trail', 'location': 'Cusco, Peru', 'difficulty': 'moderate', 'distance': 43, 'elevation': 4215, 'rating': 4.7},
    {'name': 'Tour du Mont Blanc', 'location': 'Chamonix, France', 'difficulty': 'moderate', 'distance': 170, 'elevation': 2537, 'rating': 4.6},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _trails.where((t) {
      final q = _search.text.toLowerCase();
      final matchQ = q.isEmpty || t['name'].toLowerCase().contains(q) || t['location'].toLowerCase().contains(q);
      final matchD = _difficulty == null || t['difficulty'] == _difficulty;
      return matchQ && matchD;
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search trails...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: ['easy', 'moderate', 'hard', 'expert'].map((d) {
                  final selected = _difficulty == d;
                  return ChoiceChip(
                    label: Text(d),
                    selected: selected,
                    onSelected: (_) => setState(() => _difficulty = selected ? null : d),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        onTap: () => setState(() => _selected = t),
                        title: Text(t['name']),
                        subtitle: Text('${t['location']} • ${t['distance']} km • ${t['elevation']} m'),
                        trailing: Text('${t['rating']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: _selected == null
                  ? const Text('Select a trail to explore')
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_selected!['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(_selected!['location']),
                          const SizedBox(height: 12),
                          Text('Distance: ${_selected!['distance']} km'),
                          Text('Elevation: ${_selected!['elevation']} m'),
                          Text('Difficulty: ${_selected!['difficulty']}'),
                          Text('Rating: ${_selected!['rating']}'),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
