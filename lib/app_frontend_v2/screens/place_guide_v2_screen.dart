import 'package:flutter/material.dart';

class PlaceGuideV2Screen extends StatefulWidget {
  const PlaceGuideV2Screen({super.key});

  @override
  State<PlaceGuideV2Screen> createState() => _PlaceGuideV2ScreenState();
}

class _PlaceGuideV2ScreenState extends State<PlaceGuideV2Screen> {
  final TextEditingController _inputCtrl = TextEditingController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hey Explorer. I am your AI Trail Companion for trip planning, survival, food, navigation, and field medical guidance.',
    },
  ];

  final List<Map<String, String>> _quickActions = const [
    {'label': 'Plan a trip', 'prompt': 'I want to plan a 5-day trek to Nepal. What should I do?'} ,
    {'label': 'Medical help', 'prompt': 'I have altitude sickness symptoms at 3500m. What should I do?'} ,
    {'label': 'What to eat', 'prompt': 'What are the best foods to try while trekking in Peru?'} ,
    {'label': 'I am lost', 'prompt': 'I am lost on a trail with no GPS signal. How do I find my way back?'} ,
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  String _reply(String input) {
    final q = input.toLowerCase();

    if (q.contains('plan') || q.contains('trip') || q.contains('nepal')) {
      return 'Nepal 5-day plan: Day 1 Pokhara to Nayapul, Day 2 Ghorepani, Day 3 Poon Hill sunrise, Day 4 Ghandruk, Day 5 return. Carry layered clothing, rain shell, poles, and emergency meds.';
    }
    if (q.contains('altitude') || q.contains('headache') || q.contains('nausea') || q.contains('medical')) {
      return 'Stop ascent immediately. Hydrate, rest, and monitor symptoms. If symptoms persist or worsen, descend 500-1000m and seek urgent medical support.';
    }
    if (q.contains('eat') || q.contains('food')) {
      return 'For Peru trekking: quinoa soup, lomo saltado, papa a la huancaina, and coca tea are common trail-friendly choices.';
    }
    if (q.contains('lost') || q.contains('gps')) {
      return 'Use STOP protocol: Sit, Think, Observe, Plan. Stay calm, signal with 3 whistle blasts, avoid random movement, and follow water downhill only if safe.';
    }
    return 'I can help with trip plans, emergency guidance, navigation, weather prep, local food recommendations, and route packing lists. Ask with destination + timeframe for best results.';
  }

  void _send([String? text]) {
    final content = (text ?? _inputCtrl.text).trim();
    if (content.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': content});
      _messages.add({'role': 'assistant', 'content': _reply(content)});
      _inputCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.smart_toy_outlined, color: Color(0xFF1565C0)),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('AI Trail Companion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Chip(label: Text('Online')),
                      ],
                    ),
                    Text('Trip planning • Medical help • Survival • Navigation', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final msg = _messages[i];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF1565C0) : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['content']!,
                    style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                  ),
                ),
              );
            },
          ),
        ),
        if (_messages.length <= 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickActions
                  .map(
                    (a) => ActionChip(
                      label: Text(a['label']!),
                      onPressed: () => _send(a['prompt']),
                    ),
                  )
                  .toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  decoration: const InputDecoration(hintText: 'Ask anything: trips, medical, survival, food...'),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send), label: const Text('Send')),
            ],
          ),
        ),
      ],
    );
  }
}
