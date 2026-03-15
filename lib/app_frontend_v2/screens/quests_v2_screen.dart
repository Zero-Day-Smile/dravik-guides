import 'package:flutter/material.dart';

class QuestsV2Screen extends StatefulWidget {
  const QuestsV2Screen({super.key});

  @override
  State<QuestsV2Screen> createState() => _QuestsV2ScreenState();
}

class _QuestsV2ScreenState extends State<QuestsV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  final quests = const [
    ('First Steps', 'Visit the dashboard', 1, 1, 50, 'common', '👣', true),
    ('Cartographer', 'Explore 5 trails', 3, 5, 150, 'rare', '🗺️', false),
    ('Weather Watcher', 'Check weather in 3 locations', 1, 3, 100, 'common', '⛈️', false),
    ('Gear Master', 'Pack all essentials', 6, 8, 200, 'epic', '🎒', false),
    ('Globe Trotter', 'Explore 10 countries', 2, 10, 500, 'legendary', '🌍', false),
  ];

  final badges = const [
    ('Trailhead', '🏕️', 'Begin your journey', 'common', true),
    ('Summit Conqueror', '⛰️', 'Complete a hard trail', 'rare', true),
    ('Storm Survivor', '🌪️', 'Trek through severe weather', 'epic', false),
    ('Dragon Eye', '🐉', 'Reach level 10', 'legendary', false),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const xp = 725;
    const xpToNext = 75;
    const streak = 7;
    final progress = ((xp % 200) / 200).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(radius: 24, child: Text('⚔️', style: TextStyle(fontSize: 22))),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Trailblazer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      ),
                      Chip(label: Text('Level 4')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Explorer of realms, seeker of summits', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  const Text('$xp XP • $xpToNext to next • 🔥 $streak day streak', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Quests'),
            Tab(text: 'Badges'),
            Tab(text: 'Leaderboard'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: quests.length,
                itemBuilder: (context, i) {
                  final q = quests[i];
                  final p = (q.$3 / q.$4).clamp(0.0, 1.0);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(q.$7, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(q.$2, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Text('+${q.$5} XP'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: p),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('${q.$3}/${q.$4}'),
                              const Spacer(),
                              if (q.$8) const Text('✅', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: badges.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, i) {
                  final b = badges[i];
                  final unlocked = b.$5;
                  return Card(
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.45,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(b.$2, style: const TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(b.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(b.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListView(
                padding: const EdgeInsets.all(12),
                children: const [
                  _LeaderRow(rank: 1, name: 'Dragon Peak', title: 'Legend', xp: '4,200 XP', avatar: '🐉', you: false),
                  _LeaderRow(rank: 2, name: 'Arya the Wanderer', title: 'Storm Chaser', xp: '3,100 XP', avatar: '🐺', you: false),
                  _LeaderRow(rank: 3, name: 'Ice Nomad', title: 'Realm Walker', xp: '2,800 XP', avatar: '❄️', you: false),
                  _LeaderRow(rank: 4, name: 'You', title: 'Trailblazer', xp: '725 XP', avatar: '⚔️', you: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final String name;
  final String title;
  final String xp;
  final String avatar;
  final bool you;

  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.title,
    required this.xp,
    required this.avatar,
    required this.you,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: you ? const Color(0xFFE8F0FE) : null,
      child: ListTile(
        leading: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.w700)),
        title: Text('$avatar  $name'),
        subtitle: Text(title),
        trailing: Text(xp, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
