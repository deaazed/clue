import 'package:flutter/material.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../home/home_page.dart' show memoryIcon;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Memory> _all = [];
  List<Memory> _results = [];
  final _queryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _queryCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) setState(() => _all = all);
  }

  void _filter() {
    final q = _queryCtrl.text.toLowerCase().trim();
    setState(() {
      _results = q.isEmpty
          ? []
          : _all
              .where((m) =>
                  m.label.toLowerCase().contains(q) ||
                  (m.note?.toLowerCase().contains(q) ?? false))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _queryCtrl.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryCtrl,
          decoration: InputDecoration(
            hintText: 'Search memories…',
            border: InputBorder.none,
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        actions: [
          if (q.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _queryCtrl.clear(),
            ),
        ],
      ),
      body: q.isEmpty
          ? Center(
              child: Text('Start typing to search',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off,
                          size: 48, color: cs.outlineVariant),
                      const SizedBox(height: 8),
                      Text('Nothing found for "$q"',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final m = _results[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(memoryIcon(m.iconType),
                            color: cs.primary, size: 20),
                      ),
                      title: Text(m.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      subtitle: m.note != null
                          ? Text(m.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                    );
                  },
                ),
    );
  }
}
