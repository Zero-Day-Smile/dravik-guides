import 'package:flutter/material.dart';

class UltimateGuideV2Screen extends StatefulWidget {
  const UltimateGuideV2Screen({super.key});

  @override
  State<UltimateGuideV2Screen> createState() => _UltimateGuideV2ScreenState();
}

class _UltimateGuideV2ScreenState extends State<UltimateGuideV2Screen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedGuideId;
  int? _expandedSection;

  final List<Map<String, dynamic>> _guides = const [
    {
      'id': 'g1',
      'icon': '🗺️',
      'title': 'Comprehensive Trekking Guide',
      'category': 'General',
      'readTime': '15 min',
      'difficulty': 'Beginner',
      'excerpt': 'Everything you need before hitting the trail.',
      'sections': [
        {
          'title': 'Planning and Route Selection',
          'body': 'Choose routes based on terrain, weather season, and team fitness. Keep fallback options for sudden closures and poor visibility.'
        },
        {
          'title': 'Packing and Weight Management',
          'body': 'Prioritize essentials first. Keep total pack weight within practical limits relative to body weight and trip profile.'
        },
        {
          'title': 'On-Trail Decision Making',
          'body': 'Follow turn-around times, hydrate consistently, and never ignore altitude or weather warning signals.'
        },
      ],
    },
    {
      'id': 'g2',
      'icon': '🏥',
      'title': 'Wilderness First Aid Essentials',
      'category': 'Safety',
      'readTime': '12 min',
      'difficulty': 'Intermediate',
      'excerpt': 'Core emergency medical actions in remote terrain.',
      'sections': [
        {
          'title': 'Primary Assessment',
          'body': 'Secure scene safety, check airway, breathing, circulation, and level of consciousness before any secondary care steps.'
        },
        {
          'title': 'Stabilization Priorities',
          'body': 'Control bleeding, prevent heat loss, and immobilize major fractures before attempting evacuation movement.'
        },
        {
          'title': 'Evacuation Triggers',
          'body': 'Persistent chest symptoms, confusion, severe trauma, or rapid deterioration require immediate evacuation.'
        },
      ],
    },
    {
      'id': 'g3',
      'icon': '🧭',
      'title': 'Navigation Without GPS',
      'category': 'Navigation',
      'readTime': '10 min',
      'difficulty': 'Intermediate',
      'excerpt': 'Map and compass methods for low-connectivity conditions.',
      'sections': [
        {
          'title': 'Map Orientation',
          'body': 'Orient map to terrain using contour lines, ridges, and valleys. Confirm cardinal direction before movement.'
        },
        {
          'title': 'Bearing and Handrails',
          'body': 'Use bearings for directional control and handrails like rivers or ridgelines to reduce navigation drift.'
        },
        {
          'title': 'Relocation Strategy',
          'body': 'If uncertain, stop, retrace to last known point, and re-identify terrain features before proceeding.'
        },
      ],
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _guides.where((g) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return g['title'].toString().toLowerCase().contains(q) ||
          g['category'].toString().toLowerCase().contains(q) ||
          g['excerpt'].toString().toLowerCase().contains(q);
    }).toList();

    final guide = _guides.where((g) => g['id'] == _selectedGuideId).cast<Map<String, dynamic>?>().firstOrNull;

    if (guide != null) {
      final sections = guide['sections'] as List<dynamic>;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _selectedGuideId = null;
              _expandedSection = null;
            }),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to library'),
          ),
          const SizedBox(height: 8),
          Text(guide['icon'].toString(), style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 6),
          Text(guide['title'].toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              Chip(label: Text(guide['category'].toString())),
              const SizedBox(width: 8),
              Text('${guide['readTime']} • ${guide['difficulty']}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          Text(guide['excerpt'].toString(), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          ...List.generate(sections.length, (i) {
            final section = sections[i] as Map<String, dynamic>;
            final expanded = _expandedSection == i;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  ListTile(
                    title: Text(section['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    onTap: () => setState(() => _expandedSection = expanded ? null : i),
                  ),
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Text(section['body'].toString(), style: const TextStyle(color: Colors.black87)),
                    ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 28),
            SizedBox(width: 8),
            Text('Ultimate Guide Library', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Your complete trekking knowledge base', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            hintText: 'Search all guides...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        ...filtered.map((g) {
          final sections = g['sections'] as List<dynamic>;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Text(g['icon'].toString(), style: const TextStyle(fontSize: 30)),
              title: Text(g['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g['excerpt'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('${g['category']} • ${g['readTime']} • ${g['difficulty']} • ${sections.length} sections', style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedGuideId = g['id'].toString()),
            ),
          );
        }),
      ],
    );
  }
}
