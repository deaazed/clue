import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/spacing.dart';
import '../../widgets/memory_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Memory> _all = [];
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
    _ctrl.addListener(() {
      setState(() => _query = _ctrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _all = all..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  List<Memory> get _filtered => _query.isEmpty
      ? _all
      : _all
          .where((m) =>
              m.label.toLowerCase().contains(_query) ||
              (m.note?.toLowerCase().contains(_query) ?? false))
          .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Search memories…',
            border: InputBorder.none,
            hintStyle: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _ctrl.clear(),
            ),
        ],
      ),
      body: filtered.isEmpty
          ? _EmptySearch(query: _query, cs: cs)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: filtered.length,
              itemBuilder: (_, i) => MemoryCard(
                memory: filtered[i],
                onTap: () => context.push('/memory', extra: filtered[i]),
              ),
            ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query, required this.cs});
  final String query;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Start typing to search',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: cs.outlineVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nothing found for "$query"',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
