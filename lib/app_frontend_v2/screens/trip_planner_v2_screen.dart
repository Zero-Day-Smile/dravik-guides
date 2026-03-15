import 'package:flutter/material.dart';

class TripPlannerV2Screen extends StatefulWidget {
  const TripPlannerV2Screen({super.key});

  @override
  State<TripPlannerV2Screen> createState() => _TripPlannerV2ScreenState();
}

class _TripPlannerV2ScreenState extends State<TripPlannerV2Screen> {
  final List<Map<String, dynamic>> _trips = [
    {
      'name': 'Nepal Adventure 2026',
      'destination': 'Nepal',
      'status': 'upcoming',
      'date': '2026-04-15 to 2026-05-01',
      'budget': 3500,
    },
    {
      'name': 'Inca Trail Spring',
      'destination': 'Peru',
      'status': 'planning',
      'date': '2026-06-10 to 2026-06-14',
      'budget': 2200,
    },
  ];

  bool _showCreate = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _destCtrl = TextEditingController();
  final TextEditingController _budgetCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _createTrip() {
    if (_nameCtrl.text.trim().isEmpty || _destCtrl.text.trim().isEmpty) return;
    setState(() {
      _trips.insert(0, {
        'name': _nameCtrl.text.trim(),
        'destination': _destCtrl.text.trim(),
        'status': 'planning',
        'date': 'TBD',
        'budget': int.tryParse(_budgetCtrl.text.trim()) ?? 0,
      });
      _nameCtrl.clear();
      _destCtrl.clear();
      _budgetCtrl.clear();
      _showCreate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Trip Planner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showCreate = !_showCreate),
              icon: Icon(_showCreate ? Icons.close : Icons.add),
              label: Text(_showCreate ? 'Cancel' : 'New Trip'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showCreate)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Trip Name')),
                  const SizedBox(height: 8),
                  TextField(controller: _destCtrl, decoration: const InputDecoration(labelText: 'Destination')),
                  const SizedBox(height: 8),
                  TextField(controller: _budgetCtrl, decoration: const InputDecoration(labelText: 'Budget'), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _createTrip, child: const Text('Create Trip')),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ..._trips.map((t) => Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(t['name']),
                subtitle: Text('${t['destination']} • ${t['date']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t['status'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('\$${t['budget']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 10),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Text('Discover and itinerary tabs from the new frontend can be ported next in this V2 screen.'),
          ),
        ),
      ],
    );
  }
}
