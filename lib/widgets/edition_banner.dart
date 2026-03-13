import 'package:flutter/material.dart';

enum EditionType { web, ios, mobile }

class EditionBanner extends StatelessWidget {
  const EditionBanner({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final EditionType type;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      EditionType.web => const Color(0xFF2563EB),
      EditionType.ios => const Color(0xFF111827),
      EditionType.mobile => const Color(0xFF059669),
    };

    final icon = switch (type) {
      EditionType.web => Icons.language,
      EditionType.ios => Icons.phone_iphone,
      EditionType.mobile => Icons.smartphone,
    };

    final label = switch (type) {
      EditionType.web => 'WEB',
      EditionType.ios => 'IOS',
      EditionType.mobile => 'APP',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.16),
            color.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
