import 'package:flutter/material.dart';

class IndexV2Screen extends StatelessWidget {
  const IndexV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final statCards = const [
      ('Distance', '458 km', Icons.route),
      ('Elevation', '23.1k m', Icons.trending_up),
      ('Treks', '12', Icons.terrain),
      ('Countries', '8', Icons.public),
      ('Days', '67', Icons.calendar_today),
      ('Awards', '24', Icons.emoji_events),
    ];

    final quickActions = const [
      ('Trail Maps', Icons.map),
      ('Guides', Icons.book),
      ('Plan Trip', Icons.route),
      ('Gear', Icons.backpack),
      ('AI Companion', Icons.smart_toy),
      ('Survival', Icons.local_fire_department),
      ('Pack Sync', Icons.sync),
      ('Emergency', Icons.health_and_safety),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF34A853)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The Journey Awaits', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 6),
              Text('Welcome back, Explorer', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('Lv.4 Trailblazer • 725 XP • 7 day streak', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statCards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final s = statCards[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(s.$3, size: 18, color: const Color(0xFF1A73E8)),
                    const SizedBox(height: 5),
                    Text(s.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(s.$1, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quickActions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.95,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemBuilder: (context, i) {
            final q = quickActions[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(q.$2, color: const Color(0xFF1A73E8)),
                    const SizedBox(height: 6),
                    Text(q.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
