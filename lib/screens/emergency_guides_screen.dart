import 'package:flutter/material.dart';
import 'package:dravik/services/offline_guides_service.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class OfflineGuidesScreen extends StatefulWidget {
  const OfflineGuidesScreen({super.key});

  @override
  State<OfflineGuidesScreen> createState() => _OfflineGuidesScreenState();
}

class _OfflineGuidesScreenState extends State<OfflineGuidesScreen> {
  final _guidesService = OfflineGuidesService();
  List<Map> _guides = [];
  List<Map> _filteredGuides = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuides();
    _searchCtrl.addListener(_filterGuides);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGuides() async {
    setState(() => _loading = true);
    // Cache all guides on first load
    await _guidesService.cacheAllGuides();
    _guides = await _guidesService.getAllGuides();
    _filteredGuides = _guides;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _filterGuides() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _filteredGuides = _guides);
    } else {
      _filteredGuides = await _guidesService.searchGuides(query);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Guides'),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const EditionBannerForScreen(
                  screen: EditionScreen.emergencyGuides,
                ),
                // Search bar
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search guides (e.g., "bleeding", "snake")...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Guides list
                Expanded(
                  child: _filteredGuides.isEmpty
                      ? Center(
                          child: Text(
                            _searchCtrl.text.isEmpty
                                ? 'No guides cached. Tap refresh.'
                                : 'No guides match your search.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredGuides.length,
                          itemBuilder: (ctx, i) =>
                              _buildGuideCard(_filteredGuides[i]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadGuides,
        backgroundColor: Colors.red.shade700,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Guides'),
      ),
    );
  }

  Widget _buildGuideCard(Map guide) {
    final title = guide['title'] ?? 'Guide';
    final category = guide['category'] ?? 'General';
    final content = guide['content'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              _getCategoryEmoji(category),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border(top: BorderSide(color: Colors.red.shade200)),
            ),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    const emojis = {
      'Environmental': '⛈️',
      'Trauma': '🩸',
      'Water': '💧',
      'Wildlife': '🐍',
      'General': '📚',
    };
    return emojis[category] ?? '📚';
  }
}
