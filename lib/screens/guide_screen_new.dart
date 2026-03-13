import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:dravik/screens/guide_detail_screen.dart';
import 'package:dravik/theme_provider.dart';
import 'package:dravik/screens/place_guide_screen.dart';
import 'package:dravik/widgets/edition_banner_for_screen.dart';
import 'package:dravik/config/edition_copy.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});
  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with SingleTickerProviderStateMixin {
  final String guideListUrl =
      'https://raw.githubusercontent.com/Zero-Day-Smile/dravik-guides/main/guide_list.json';

  List<Map<String, dynamic>> _guides = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String? _selectedTag;
  String searchQuery = '';
  bool _loadingList = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGuideList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGuideList() async {
    setState(() => _loadingList = true);
    try {
      final resp = await http.get(Uri.parse(guideListUrl));
      if (resp.statusCode == 200) {
        _guides = List<Map<String, dynamic>>.from(
          json.decode(resp.body) as List,
        );
        _filtered = _guides;

        _categories = [
          'All',
          ..._guides.map((g) => g['category'] as String).toSet(),
        ];
      } else {
        _showSnack('Failed to load list: ${resp.statusCode}');
      }
    } catch (e) {
      _showSnack('Error loading list: $e');
    }
    setState(() => _loadingList = false);
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
  }

  void _filterGuides(String q) {
    setState(() {
      searchQuery = q;
      _applyFilters();
    });
  }

  Future<void> _downloadAllGuides() async {
    final box = Hive.box<String>('guides');
    _showSnack('📥 Downloading all guides…');
    int downloaded = 0;
    for (final g in _guides) {
      if (!box.containsKey(g['title'])) {
        try {
          final resp = await http.get(Uri.parse(g['url']));
          if (resp.statusCode == 200) {
            await box.put(g['title'], resp.body);
            downloaded++;
          }
        } catch (_) {}
      }
    }
    _showSnack('✅ $downloaded guides cached offline!');
  }

  Future<void> _openGuide(String title) async {
    final guide = _guides.firstWhere((g) => g['title'] == title);
    final box = Hive.box<String>('guides');
    String? html = box.get(title);

    if (html == null) {
      try {
        final resp = await http.get(
          Uri.parse(guide['url']),
          headers: {'User-Agent': 'Mozilla/5.0 (FlutterApp)'},
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
          title: title,
          htmlContent: html ?? '<p>Content unavailable</p>',
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, child) {
        final box = Hive.box<String>('guides');

        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
          body: _loadingList
              ? const Center(child: CircularProgressIndicator())
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 200,
                        floating: false,
                        pinned: true,
                        backgroundColor:
                            isDark ? Colors.grey[850] : Colors.blue[700],
                        flexibleSpace: FlexibleSpaceBar(
                          title: const Text(
                            'Guides',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [Colors.grey[850]!, Colors.grey[900]!]
                                    : [Colors.blue[600]!, Colors.blue[900]!],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -30,
                                  top: -30,
                                  child: Icon(
                                    Icons.menu_book,
                                    size: 200,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                Positioned(
                                  left: 16,
                                  bottom: 60,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_guides.length} Guides',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${box.length} Offline',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.travel_explore),
                            tooltip: 'AI Place Guide',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PlaceGuideScreen(),
                              ),
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
                        ],
                      ),
                    ];
                  },
                  body: RefreshIndicator(
                    onRefresh: _loadGuideList,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(
                          child: EditionBannerForScreen(
                            screen: EditionScreen.guidesNew,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Search bar
                                TextField(
                                  onChanged: _filterGuides,
                                  decoration: InputDecoration(
                                    hintText: 'Search guides...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Filter chips
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _categories.length,
                                    itemBuilder: (context, index) {
                                      final cat = _categories[index];
                                      final isSelected =
                                          cat == _selectedCategory;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: FilterChip(
                                          label: Text(cat),
                                          selected: isSelected,
                                          onSelected: (_) {
                                            setState(() {
                                              _selectedCategory = cat;
                                              _applyFilters();
                                            });
                                          },
                                          backgroundColor: isDark
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                          selectedColor: Colors.blue,
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // General Basics
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple[400]!,
                                          Colors.purple[700]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ExpansionTile(
                                      title: const Row(
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'General Basics',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: const Text(
                                        'Safety, prep, packing essentials',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      collapsedBackgroundColor:
                                          Colors.transparent,
                                      backgroundColor: Colors.transparent,
                                      textColor: Colors.white,
                                      iconColor: Colors.white,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            0,
                                            24,
                                            20,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const [
                                              _BasicTip(
                                                icon: Icons.cloud,
                                                title: 'Weather Check',
                                                text:
                                                    'Check local weather & alerts before travel',
                                              ),
                                              SizedBox(height: 12),
                                              _BasicTip(
                                                icon: Icons.backpack,
                                                title: 'Pack Smart',
                                                text:
                                                    'Carry ID, first aid, water, sun protection',
                                              ),
                                              SizedBox(height: 12),
                                              _BasicTip(
                                                icon: Icons.local_hospital,
                                                title: 'Know Locations',
                                                text:
                                                    'Know nearest medical facilities & transport',
                                              ),
                                              SizedBox(height: 12),
                                              _BasicTip(
                                                icon: Icons.eco,
                                                title: 'Respect Nature',
                                                text:
                                                    'Respect local rules, leave no trace',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Guides list
                        _filtered.isEmpty
                            ? SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: isDark
                                            ? Colors.grey[700]
                                            : Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No guides found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your filters',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final guide = _filtered[index];
                                    final title = guide['title'];
                                    final category = guide['category'];
                                    final isOffline = box.containsKey(title);

                                    return _GuideCard(
                                      title: title,
                                      category: category,
                                      isOffline: isOffline,
                                      onTap: () => _openGuide(title),
                                      isDark: isDark,
                                    );
                                  }, childCount: _filtered.length),
                                ),
                              ),
                        const SliverToBoxAdapter(child: SizedBox(height: 32)),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _BasicTip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _BasicTip({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideCard extends StatefulWidget {
  final String title;
  final String category;
  final bool isOffline;
  final VoidCallback onTap;
  final bool isDark;

  const _GuideCard({
    required this.title,
    required this.category,
    required this.isOffline,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(widget.category),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.book,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isOffline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_done,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Offline',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String category) {
    switch (category.toLowerCase()) {
      case 'navigation':
        return [Colors.blue[600]!, Colors.blue[900]!];
      case 'safety':
        return [Colors.red[600]!, Colors.red[900]!];
      case 'survival':
        return [Colors.orange[600]!, Colors.orange[900]!];
      case 'health':
        return [Colors.green[600]!, Colors.green[900]!];
      case 'camping':
        return [Colors.teal[600]!, Colors.teal[900]!];
      case 'trekking':
        return [Colors.purple[600]!, Colors.purple[900]!];
      default:
        return [Colors.indigo[600]!, Colors.indigo[900]!];
    }
  }
}
