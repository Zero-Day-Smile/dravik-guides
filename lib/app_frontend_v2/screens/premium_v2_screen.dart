import 'package:flutter/material.dart';

class PremiumV2Screen extends StatefulWidget {
  const PremiumV2Screen({super.key});

  @override
  State<PremiumV2Screen> createState() => _PremiumV2ScreenState();
}

class _PremiumV2ScreenState extends State<PremiumV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final String _currentPlan = 'free';

  final plans = const [
    (
      'free',
      'Explorer',
      'Free',
      '',
      [
        'Basic trail maps',
        '5 travel pins',
        'Emergency guides',
        'Community access',
        'Basic weather'
      ],
      false,
    ),
    (
      'pro',
      'Pathfinder Pro',
      '\$9.99',
      '/month',
      [
        'Everything in Explorer',
        'HD offline maps',
        'AR trail scanner',
        'Advanced SOS',
        'AI trail advisor',
        '50GB storage',
      ],
      true,
    ),
    (
      'legend',
      'Legend',
      '\$19.99',
      '/month',
      [
        'Everything in Pro',
        'Unlimited pack sync',
        'Live health analytics',
        'Unlimited storage',
        'Priority support',
      ],
      false,
    ),
  ];

  final features = const [
    ('HD Offline Maps', 'Download high-resolution maps', Icons.map),
    ('AR Trail Scanner', 'Scan terrain and trail markers', Icons.camera_alt_outlined),
    ('Advanced SOS', 'Priority emergency dispatch', Icons.health_and_safety_outlined),
    ('AI Trail Advisor', 'Personalized route recommendations', Icons.smart_toy_outlined),
    ('Unlimited Pack Sync', 'Real-time team coordination', Icons.sync),
    ('Live Health Analytics', 'Vitals and fatigue insights', Icons.query_stats),
  ];

  final compareRows = const [
    ('Trail Maps', 'Basic', 'HD + Offline', 'HD + Offline'),
    ('Travel Pins', '5 pins', 'Unlimited', 'Unlimited'),
    ('AR Scanner', '-', 'Yes', 'Yes'),
    ('SOS Broadcast', 'Pack only', 'Pack + Public', 'Satellite SOS'),
    ('AI Companion', '5/day', '50/day', 'Unlimited'),
    ('Storage', '1 GB', '50 GB', 'Unlimited'),
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
    return Column(
      children: [
        const SizedBox(height: 16),
        const CircleAvatar(radius: 36, child: Text('👑', style: TextStyle(fontSize: 34))),
        const SizedBox(height: 8),
        const Text('Upgrade to Premium', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Text(
            'Unlock advanced maps, AR scanning, satellite SOS, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Plans'),
            Tab(text: 'Features'),
            Tab(text: 'Compare'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: plans.length,
                itemBuilder: (context, i) {
                  final p = plans[i];
                  final isCurrent = p.$1 == _currentPlan;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: p.$6 ? const Color(0xFFFFF8E1) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(p.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                              Text('${p.$3}${p.$4}'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...p.$5.map((f) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, size: 16, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(f)),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isCurrent ? null : () {},
                              child: Text(isCurrent ? 'Current Plan' : 'Upgrade'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: features.length,
                itemBuilder: (context, i) {
                  final f = features[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(f.$3, color: const Color(0xFFF9AB00)),
                      title: Text(f.$1),
                      subtitle: Text(f.$2),
                      trailing: const Chip(label: Text('PRO')),
                    ),
                  );
                },
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Feature')),
                    DataColumn(label: Text('Explorer')),
                    DataColumn(label: Text('Pro')),
                    DataColumn(label: Text('Legend')),
                  ],
                  rows: compareRows
                      .map(
                        (r) => DataRow(
                          cells: [
                            DataCell(Text(r.$1)),
                            DataCell(Text(r.$2)),
                            DataCell(Text(r.$3)),
                            DataCell(Text(r.$4)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
