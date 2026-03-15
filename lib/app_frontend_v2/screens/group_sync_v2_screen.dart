import 'package:flutter/material.dart';

class GroupSyncV2Screen extends StatefulWidget {
  const GroupSyncV2Screen({super.key});

  @override
  State<GroupSyncV2Screen> createState() => _GroupSyncV2ScreenState();
}

class _GroupSyncV2ScreenState extends State<GroupSyncV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _broadcasting = false;
  final TextEditingController _msgCtrl = TextEditingController();

  final List<Map<String, dynamic>> _members = [
    {'name': 'You (Leader)', 'role': 'Leader', 'status': 'online', 'battery': 78, 'signal': 4, 'distance': '—', 'altitude': 4130, 'heart': 92, 'pace': '3.2 km/h', 'avatar': '⚔️'},
    {'name': 'Shadowfax', 'role': 'Scout', 'status': 'online', 'battery': 62, 'signal': 3, 'distance': '45m ahead', 'altitude': 4145, 'heart': 105, 'pace': '3.8 km/h', 'avatar': '🐺'},
    {'name': 'Torch Bearer', 'role': 'Navigator', 'status': 'online', 'battery': 41, 'signal': 2, 'distance': '120m behind', 'altitude': 4115, 'heart': 88, 'pace': '2.9 km/h', 'avatar': '🔥'},
    {'name': 'Storm Eye', 'role': 'Gear Master', 'status': 'sos', 'battery': 12, 'signal': 1, 'distance': '500m behind', 'altitude': 4070, 'heart': null, 'pace': null, 'avatar': '⛈️'},
  ];

  final List<Map<String, String>> _quickMessages = [
    {'icon': '👍', 'text': 'I\'m OK — continuing'},
    {'icon': '✋', 'text': 'Wait for me'},
    {'icon': '😤', 'text': 'Need a break'},
    {'icon': '💧', 'text': 'Found water source'},
    {'icon': '⚠️', 'text': 'Trail blocked — rerouting'},
    {'icon': '⛺', 'text': 'Setting up camp here'},
    {'icon': '⛈️', 'text': 'Weather turning bad'},
    {'icon': '🆘', 'text': 'HELP — Need assistance'},
  ];

  final List<Map<String, String>> _chat = [
    {'from': 'Shadowfax', 'time': '2m ago', 'text': 'Trail is clear ahead, beautiful views!'},
    {'from': 'Torch Bearer', 'time': '5m ago', 'text': 'Slowing down — steep section'},
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'online':
        return const Color(0xFF2E7D32);
      case 'sos':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  void _sendMessage([String? text]) {
    final value = (text ?? _msgCtrl.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _chat.insert(0, {'from': 'You', 'time': 'Just now', 'text': value});
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _members.where((m) => m['status'] == 'online').length;
    final hasSos = _members.any((m) => m['status'] == 'sos');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pack Sync', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  Text('Real-time expedition coordination', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _broadcasting = !_broadcasting),
              icon: Icon(Icons.wifi_tethering, color: _broadcasting ? const Color(0xFF2E7D32) : null),
              label: Text(_broadcasting ? 'Stop' : 'Broadcast'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1), label: const Text('Invite')),
          ],
        ),
        if (hasSos) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFEBEE),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFC62828),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOS SIGNAL DETECTED', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC62828))),
                        Text('Storm Eye • 500m behind • 4070m altitude', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.call), label: const Text('Call')),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.navigation_outlined), label: const Text('Navigate')),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard(Icons.groups_outlined, '$onlineCount/${_members.length}', 'Online')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.place_outlined, '500m', 'Spread')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.signal_cellular_alt, 'Good', 'Avg Signal')),
            const SizedBox(width: 8),
            Expanded(child: _statCard(Icons.terrain, '4,130m', 'Altitude')),
          ],
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Members'),
            Tab(text: 'Pack Chat'),
            Tab(text: 'Tools'),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 560,
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, i) {
                  final m = _members[i];
                  final status = m['status'].toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: status == 'sos' ? const Color(0xFFFFF3F3) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.black.withValues(alpha: 0.06),
                            child: Text(m['avatar'].toString(), style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m['name'].toString(),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Chip(label: Text(m['role'].toString())),
                                    const SizedBox(width: 6),
                                    Chip(
                                      label: Text(status.toUpperCase()),
                                      backgroundColor: _statusColor(status).withValues(alpha: 0.14),
                                      side: BorderSide.none,
                                      labelStyle: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('${m['distance']} • Alt ${m['altitude']}m', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Text('🔋 ${m['battery']}%'),
                                    Text('📶 ${m['signal']}/5'),
                                    if (m['heart'] != null) Text('❤️ ${m['heart']} bpm'),
                                    if (m['pace'] != null) Text('🏃 ${m['pace']}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickMessages
                        .map(
                          (q) => ActionChip(
                            label: Text('${q['icon']} ${q['text']}'),
                            onPressed: () => _sendMessage(q['text']),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: const InputDecoration(hintText: 'Type a message...'),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(onPressed: _sendMessage, icon: const Icon(Icons.send), label: const Text('Send')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _chat.length,
                      itemBuilder: (context, i) {
                        final msg = _chat[i];
                        final fromYou = msg['from'] == 'You';
                        return Align(
                          alignment: fromYou ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            width: 420,
                            decoration: BoxDecoration(
                              color: fromYou ? const Color(0xFFE3F2FD) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${msg['from']} • ${msg['time']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 3),
                                Text(msg['text'].toString()),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: const [
                  _ToolTile(icon: Icons.location_on_outlined, title: 'Share Location', subtitle: 'Send your GPS to pack', action: 'Share'),
                  _ToolTile(icon: Icons.explore_outlined, title: 'Set Waypoint', subtitle: 'Mark point of interest', action: 'Mark'),
                  _ToolTile(icon: Icons.warning_amber_outlined, title: 'Emergency Ping', subtitle: 'Alert all members', action: 'Ping'),
                  _ToolTile(icon: Icons.flag_outlined, title: 'Set Rally Point', subtitle: 'Designate meeting point', action: 'Set'),
                  _ToolTile(icon: Icons.note_alt_outlined, title: 'Share Trail Notes', subtitle: 'Send route conditions', action: 'Share'),
                  _ToolTile(icon: Icons.inventory_2_outlined, title: 'Request Resupply', subtitle: 'Ask for water/gear', action: 'Request'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(onPressed: () {}, child: Text(action)),
            ),
          ],
        ),
      ),
    );
  }
}
