import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dravik/screens/guide_detail_screen.dart'; // Updated
import 'package:dravik/theme_provider.dart'; // Updated
import 'package:dravik/screens/place_guide_screen.dart';
import 'package:dravik/config/platform_capabilities.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});
  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final String guideListUrl =
      'https://raw.githubusercontent.com/Zero-Day-Smile/dravik-guides/main/guide_list.json';

  List<Map<String, dynamic>> _guides = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  List<String> _tags = [];
  String? _selectedTag;
  String searchQuery = '';
  String? _selectedTitle;
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _loadGuideList();
  }

  Future<void> _loadGuideList() async {
    setState(() => _loadingList = true);
    try {
      final resp = await http.get(Uri.parse(guideListUrl));
      if (resp.statusCode == 200) {
        _guides =
            List<Map<String, dynamic>>.from(json.decode(resp.body) as List);
        _filtered = _guides;
        _selectedTitle = _guides.isNotEmpty ? _guides.first['title'] : null;

        _categories = [
          'All',
          ..._guides.map((g) => g['category'] as String).toSet()
        ];
        _tags = _guides
            .expand((g) => List<String>.from(g['tags']))
            .toSet()
            .toList()
          ..sort();
      } else {
        _showSnack('Failed to load list: ${resp.statusCode}');
      }
    } catch (e) {
      _showSnack('Error loading list: $e');
    }
    if (mounted) {
      setState(() => _loadingList = false);
    }
  }

  void _applyFilters() {
    _filtered = _guides.where((g) {
      final haystack = '${g['title']} ${g['tags'].join(' ')}'.toLowerCase();
      final matchesQuery = haystack.contains(searchQuery.toLowerCase());
      final matchesCat =
          _selectedCategory == 'All' || g['category'] == _selectedCategory;
      final matchesTag =
          _selectedTag == null || g['tags'].contains(_selectedTag);
      return matchesQuery && matchesCat && matchesTag;
    }).toList();
    if (_filtered.isNotEmpty) _selectedTitle = _filtered.first['title'];
  }

  void _filterGuides(String q) {
    setState(() {
      searchQuery = q;
      _applyFilters();
    });
  }

  Future<void> _downloadAllGuides() async {
    final box = Hive.box<String>('guides');
    _showSnack('Downloading all guides…');
    for (final g in _guides) {
      if (!box.containsKey(g['title'])) {
        try {
          final resp = await http.get(Uri.parse(g['url']));
          if (resp.statusCode == 200) {
            await box.put(g['title'], resp.body);
          }
        } catch (_) {}
      }
    }
    _showSnack('All guides cached offline ✅');
  }

  Future<void> _openGuide(String title) async {
    final guide = _guides.firstWhere((g) => g['title'] == title);
    final box = Hive.box<String>('guides');
    String? html = box.get(title);

    if (html == null) {
      try {
        final resp = await http.get(
          Uri.parse(guide['url']),
          headers: {
            'User-Agent': 'Mozilla/5.0 (FlutterApp)',
          },
        );

        if (resp.statusCode == 200) {
          html = resp.body;
          await box.put(title, html);
        } else {
          html = '<p>⚠️ Failed to load: ${resp.statusCode}</p>';
        }
      } catch (e) {
        html = '<p>❌ Error: $e</p>';
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuideDetailScreen(
            title: title, htmlContent: html ?? '<p>Content unavailable</p>'),
      ),
    );
  }

  Future<void> _exportSelectedGuide() async {
    final box = Hive.box<String>('guides');
    final html = box.get(_selectedTitle!);
    if (html == null) return _showSnack('Guide not cached yet');

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_selectedTitle!, style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 12),
            pw.Text(html.replaceAll(RegExp(r'<[^>]+>'), '')),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${_selectedTitle!}.pdf',
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = PlatformCapabilities.isWeb;

    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
          appBar: AppBar(
            title: const Text('Dravik Guides'),
            backgroundColor: isDark ? Colors.green[900] : Colors.green[700],
            actions: [
              IconButton(
                icon: const Icon(Icons.travel_explore),
                tooltip: 'Place Guide (AI)',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlaceGuideScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.cloud_download),
                tooltip: 'Download All',
                onPressed: _downloadAllGuides,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadGuideList,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Export PDF',
                onPressed: _selectedTitle == null ? null : _exportSelectedGuide,
              ),
            ],
          ),
          body: _loadingList
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadGuideList,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const EditionBannerForScreen(screen: EditionScreen.guides),

                          if (isWeb)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  Chip(label: Text('Top Rated Treks')),
                                  Chip(label: Text('Quick Weekend Plans')),
                                  Chip(label: Text('Culture + Nature Picks')),
                                  Chip(label: Text('Safety Essentials')),
                                ],
                              ),
                            ),

                          // General Basics quick section
                          Card(
                            elevation: 0,
                            color: isDark ? Colors.black26 : Colors.grey[100],
                            child: const ExpansionTile(
                              title: Text('General Basics',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Safety, prep, packing — quick essentials'),
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '• Check local weather and alerts before travel.'),
                                      SizedBox(height: 6),
                                      Text(
                                          '• Carry ID, basic first aid, water, and sun protection.'),
                                      SizedBox(height: 6),
                                      Text(
                                          '• Know nearest medical facilities and transport options.'),
                                      SizedBox(height: 6),
                                      Text(
                                          '• Respect local rules; leave no trace.'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: isDark ? Colors.black : Colors.white,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _selectedCategory = val;
                                _applyFilters();
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Search guides...',
                              hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.white60),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.black26 : Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            onChanged: _filterGuides,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: _selectedTag == null,
                                onSelected: (_) {
                                  setState(() => _selectedTag = null);
                                  _applyFilters();
                                },
                              ),
                              ..._tags.map((tag) => ChoiceChip(
                                    label: Text(tag),
                                    selected: _selectedTag == tag,
                                    onSelected: (_) {
                                      setState(() => _selectedTag = tag);
                                      _applyFilters();
                                    },
                                  )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: _selectedTitle,
                            dropdownColor: isDark ? Colors.black : Colors.white,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            items: _filtered
                                .map((g) => DropdownMenuItem<String>(
                                      value: g['title'],
                                      child: Text(g['title']),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTitle = val),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _selectedTitle == null
                                ? null
                                : () => _openGuide(_selectedTitle!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.green[800]
                                  : Colors.green[600],
                            ),
                            child: const Text('Open Guide'),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final g = _filtered[i];
                              return ListTile(
                                title: Text(g['title'],
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black)),
                                subtitle: Text('Updated: ${g['updated']}',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54)),
                                onTap: () => _openGuide(g['title']),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
