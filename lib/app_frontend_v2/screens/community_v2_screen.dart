import 'package:flutter/material.dart';

class CommunityV2Screen extends StatefulWidget {
  const CommunityV2Screen({super.key});

  @override
  State<CommunityV2Screen> createState() => _CommunityV2ScreenState();
}

class _CommunityV2ScreenState extends State<CommunityV2Screen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _composer = TextEditingController();
  bool _showComposer = false;

  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Arya the Wanderer',
      'title': 'Storm Chaser',
      'level': 8,
      'location': 'Annapurna, Nepal',
      'content': 'Crossed a high pass in monsoon weather. The fog opened for seconds and the whole valley appeared.',
      'likes': 247,
      'comments': 18,
      'liked': false,
      'time': '2h ago',
      'emoji': '🐺',
    },
    {
      'author': 'Forest Walker',
      'title': 'Pathfinder',
      'level': 5,
      'location': 'Black Forest, Germany',
      'content': 'Found a hidden waterfall today. No trail markers, just sound and instinct.',
      'likes': 183,
      'comments': 12,
      'liked': true,
      'time': '5h ago',
      'emoji': '🌿',
    },
    {
      'author': 'Dragon Peak',
      'title': 'Legend',
      'level': 10,
      'location': 'PCT, California',
      'content': 'Long trail day, no comfort, but the night sky made every step worth it.',
      'likes': 512,
      'comments': 34,
      'liked': false,
      'time': '1d ago',
      'emoji': '🐉',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _composer.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      final liked = _posts[index]['liked'] as bool;
      _posts[index]['liked'] = !liked;
      _posts[index]['likes'] = (_posts[index]['likes'] as int) + (liked ? -1 : 1);
    });
  }

  void _submitPost() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _posts.insert(0, {
        'author': 'You',
        'title': 'Wanderer',
        'level': 4,
        'location': 'Unknown Realm',
        'content': text,
        'likes': 0,
        'comments': 0,
        'liked': false,
        'time': 'Just now',
        'emoji': '⚔️',
      });
      _composer.clear();
      _showComposer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trending = [..._posts]..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expedition Board', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Stories from the wild — share yours', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showComposer = !_showComposer),
                icon: const Icon(Icons.send),
                label: const Text('Share Story'),
              ),
            ],
          ),
        ),
        if (_showComposer)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _composer,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'What is your story, explorer?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => setState(() => _showComposer = false), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _submitPost, child: const Text('Post (+25 XP)')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Trending'),
            Tab(text: 'Legendary'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _posts.length,
                itemBuilder: (context, i) {
                  final p = _posts[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(child: Text(p['emoji'])),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['author'], style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text('${p['title']} • ${p['time']}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              Chip(label: Text('Lv.${p['level']}', style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(p['content']),
                          const SizedBox(height: 8),
                          Text('📍 ${p['location']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _toggleLike(i),
                                icon: Icon(
                                  (p['liked'] as bool) ? Icons.favorite : Icons.favorite_border,
                                  color: (p['liked'] as bool) ? Colors.red : null,
                                ),
                              ),
                              Text('${p['likes']}'),
                              const SizedBox(width: 10),
                              const Icon(Icons.mode_comment_outlined, size: 18),
                              const SizedBox(width: 4),
                              Text('${p['comments']}'),
                              const Spacer(),
                              const Icon(Icons.share_outlined, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: trending.length,
                itemBuilder: (context, i) {
                  final p = trending[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      title: Text(p['author']),
                      subtitle: Text(p['content'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text('❤ ${p['likes']}'),
                    ),
                  );
                },
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('👑', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 12),
                      Text('Hall of Legends', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text(
                        'Only top explorers unlock this board.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
