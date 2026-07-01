import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/spacing.dart';
import '../../widgets/memory_card.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  List<Memory> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _memories = all..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    await MemoryRepository.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search',
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
              ? _EmptyState(cs: cs)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _GroupedList(
                    memories: _memories,
                    cs: cs,
                    onDelete: _delete,
                  ),
                ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.memories,
    required this.cs,
    required this.onDelete,
  });

  final List<Memory> memories;
  final ColorScheme cs;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppSpacing.sm, bottom: AppSpacing.xl),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final result = <Widget>[];
    String? lastGroup;

    for (final m in memories) {
      final group = _groupLabel(m.timestamp);
      if (group != lastGroup) {
        result.add(_DateHeader(label: group));
        lastGroup = group;
      }
      result.add(Dismissible(
        key: Key(m.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Icon(Icons.delete_outline, color: cs.error),
        ),
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete memory?'),
            content: Text('"${m.label}" will be removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ),
        onDismissed: (_) => onDelete(m.id),
        child: MemoryCard(
          memory: m,
          onTap: () => context.push('/memory', extra: m),
        ),
      ));
    }
    return result;
  }

  static String _groupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) {
      const days = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday',
        'Friday', 'Saturday', 'Sunday'
      ];
      return days[d.weekday - 1];
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (d.year == now.year) return '${months[d.month - 1]} ${d.day}';
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 4,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined,
                size: 64, color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No memories yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap Save Memory on the map\nto save your first location.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.outline),
            ),
          ],
        ),
      ),
    );
  }
}
