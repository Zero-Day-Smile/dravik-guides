import 'package:flutter/material.dart';

class ActivityTrackerV2Screen extends StatelessWidget {
  const ActivityTrackerV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _MetricCard(title: 'Steps', value: '8,432', subtitle: 'Today'),
        SizedBox(height: 10),
        _MetricCard(title: 'Distance', value: '6.2 km', subtitle: 'Today'),
        SizedBox(height: 10),
        _MetricCard(title: 'Calories', value: '1,847', subtitle: 'Burned'),
        SizedBox(height: 10),
        _MetricCard(title: 'Streak', value: '7 days', subtitle: 'Active'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
