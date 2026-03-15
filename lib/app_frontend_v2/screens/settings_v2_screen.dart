import 'package:flutter/material.dart';

class SettingsV2Screen extends StatefulWidget {
  const SettingsV2Screen({super.key});

  @override
  State<SettingsV2Screen> createState() => _SettingsV2ScreenState();
}

class _SettingsV2ScreenState extends State<SettingsV2Screen> {
  bool _darkMode = true;
  bool _offline = false;
  bool _weatherNotif = true;
  bool _tripNotif = true;
  bool _questNotif = true;
  bool _communityNotif = false;
  bool _sosNotif = true;

  final _nameCtrl = TextEditingController(text: 'Explorer');
  final _emailCtrl = TextEditingController(text: 'explorer@dravik.com');
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '70');

  final List<Map<String, String>> _contacts = [
    {'name': 'John Doe', 'phone': '+1-555-0123', 'relation': 'Brother'},
    {'name': 'Jane Smith', 'phone': '+1-555-0456', 'relation': 'Partner'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = double.tryParse(_heightCtrl.text) ?? 175;
    final w = double.tryParse(_weightCtrl.text) ?? 70;
    final bmi = (w / ((h / 100) * (h / 100))).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Your app, your rules', style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.workspace_premium), label: const Text('Premium')),
          ],
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Profile & Body Stats',
          icon: Icons.person_outline,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _heightCtrl, decoration: const InputDecoration(labelText: 'Height (cm)'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _weightCtrl, decoration: const InputDecoration(labelText: 'Weight (kg)'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(labelText: 'BMI', hintText: bmi),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () {}, child: const Text('Save Profile'))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Appearance & Themes',
          icon: Icons.palette_outlined,
          child: Column(
            children: [
              SwitchListTile(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle light and dark'),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  Chip(label: Text('⚡ Default')),
                  Chip(label: Text('🌲 Forest')),
                  Chip(label: Text('❄️ Ice')),
                  Chip(label: Text('🔥 Fire')),
                  Chip(label: Text('🌌 Void')),
                  Chip(label: Text('⛈️ Storm')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Emergency Contacts',
          icon: Icons.phone_outlined,
          child: Column(
            children: [
              ..._contacts.map(
                (c) => ListTile(
                  leading: const Icon(Icons.contact_phone_outlined),
                  title: Text(c['name']!),
                  subtitle: Text('${c['phone']} • ${c['relation']}'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Add Emergency Contact'))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Connectivity & Notifications',
          icon: Icons.wifi_outlined,
          child: Column(
            children: [
              SwitchListTile(
                value: _offline,
                onChanged: (v) => setState(() => _offline = v),
                title: const Text('Offline Mode'),
                subtitle: Text(_offline ? 'Cached data only' : 'All features active'),
              ),
              const Divider(height: 1),
              SwitchListTile(value: _weatherNotif, onChanged: (v) => setState(() => _weatherNotif = v), title: const Text('Weather Alerts')),
              SwitchListTile(value: _tripNotif, onChanged: (v) => setState(() => _tripNotif = v), title: const Text('Trip Reminders')),
              SwitchListTile(value: _questNotif, onChanged: (v) => setState(() => _questNotif = v), title: const Text('Quest Updates')),
              SwitchListTile(value: _communityNotif, onChanged: (v) => setState(() => _communityNotif = v), title: const Text('Community Activity')),
              SwitchListTile(value: _sosNotif, onChanged: (v) => setState(() => _sosNotif = v), title: const Text('SOS Alerts')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _sectionCard(
          title: 'Danger Zone',
          icon: Icons.delete_outline,
          child: Column(
            children: [
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.delete_outline), label: const Text('Clear Cache'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.restart_alt), label: const Text('Reset Settings'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.logout), label: const Text('Sign Out'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
