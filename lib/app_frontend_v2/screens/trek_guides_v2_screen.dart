import 'package:flutter/material.dart';

class TrekGuidesV2Screen extends StatefulWidget {
  const TrekGuidesV2Screen({super.key});

  @override
  State<TrekGuidesV2Screen> createState() => _TrekGuidesV2ScreenState();
}

class _TrekGuidesV2ScreenState extends State<TrekGuidesV2Screen> {
  final TextEditingController _search = TextEditingController();
  String? _category;
  Map<String, String>? _selected;

  final List<Map<String, String>> _guides = const [
    {'title': 'Comprehensive Trekking Guide', 'category': 'General', 'readTime': '15 min', 'difficulty': 'Beginner', 'excerpt': 'Everything before hitting the trail.'},
    {'title': 'First Aid in the Wilderness', 'category': 'Safety', 'readTime': '12 min', 'difficulty': 'All Levels', 'excerpt': 'Handle emergencies in remote areas.'},
    {'title': 'Navigation Without GPS', 'category': 'Navigation', 'readTime': '10 min', 'difficulty': 'Intermediate', 'excerpt': 'Map and compass skills that matter.'},
    {'title': 'Survival Essentials', 'category': 'Safety', 'readTime': '20 min', 'difficulty': 'Advanced', 'excerpt': 'Critical survival priorities and actions.'},
  ];

  @override
  Widget build(BuildContext context) {
    final categories = _guides.map((e) => e['category']!).toSet().toList();
    final filtered = _guides.where((g) {
      final q = _search.text.toLowerCase();
      final matchQ = q.isEmpty || g['title']!.toLowerCase().contains(q);
      final matchC = _category == null || g['category'] == _category;
      return matchQ && matchC;
    }).toList();

    if (_selected != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _selected = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to guides'),
          ),
          const SizedBox(height: 8),
          Text(_selected!['title']!, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${_selected!['category']} • ${_selected!['readTime']} • ${_selected!['difficulty']}'),
          const SizedBox(height: 16),
          Text(_selected!['excerpt']!),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Detailed guide content will be mapped here from your new frontend source.'),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Trek Guides', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search guides...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: categories.map((c) {
            final selected = _category == c;
            return ChoiceChip(
              label: Text(c),
              selected: selected,
              onSelected: (_) => setState(() => _category = selected ? null : c),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        ...filtered.map((g) => Card(
              child: ListTile(
                onTap: () => setState(() => _selected = g),
                title: Text(g['title']!),
                subtitle: Text('${g['category']} • ${g['readTime']} • ${g['difficulty']}'),
              ),
            )),
      ],
    );
  }
}
