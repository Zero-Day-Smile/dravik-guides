import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:dravik/theme_provider.dart'; // Updated
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class GuideDetailScreen extends StatelessWidget {
  final String title;
  final String htmlContent;

  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
          appBar: AppBar(
            title: Text(title),
            backgroundColor: isDark ? Colors.green[900] : Colors.green[700],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EditionBannerForScreen(screen: EditionScreen.guideDetail),
                Html(
                  data: htmlContent,
                  style: {
                    "body": Style(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: FontSize(16),
                    ),
                    "h1": Style(
                      color: isDark ? Colors.greenAccent : Colors.green,
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.bold,
                    ),
                    "h2": Style(
                      color: isDark ? Colors.green : Colors.green[700],
                      fontSize: FontSize(20),
                    ),
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔒 Export to PDF is a premium feature.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export as PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('🔒 Export as HTML is a premium feature.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Export as HTML'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
