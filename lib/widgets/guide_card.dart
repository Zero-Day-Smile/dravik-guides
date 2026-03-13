import 'package:flutter/material.dart';
import '../data/guides_data.dart';

class GuideCard extends StatelessWidget {
  final Guide guide;

  const GuideCard({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(guide.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(guide.title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(guide.subtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: guide.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
