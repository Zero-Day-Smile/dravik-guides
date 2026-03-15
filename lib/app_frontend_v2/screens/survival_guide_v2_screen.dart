import 'package:flutter/material.dart';

class SurvivalGuideV2Screen extends StatelessWidget {
  const SurvivalGuideV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Edible Plants', Icons.eco),
      ('Poisonous Plants', Icons.warning_amber),
      ('Water Purification', Icons.water_drop),
      ('Emergency Shelter', Icons.cabin),
      ('Fire Starting', Icons.local_fire_department),
      ('Navigation Basics', Icons.explore),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              leading: Icon(item.$2),
              title: Text(item.$1),
              subtitle: const Text('Offline-ready survival reference'),
            ),
          ),
        );
      },
    );
  }
}
