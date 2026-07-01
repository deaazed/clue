import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your clues',
                            style: TextStyle(
                              fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                              fontWeight: FontWeight.w600,
                              fontSize: 26,
                              letterSpacing: -0.02 * 26,
                              color: isDark ? ClueColors.paper : ClueColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _memories.isEmpty
                                ? 'No clues yet — drop your first one'
                                : '${_memories.length} ${_memories.length == 1 ? 'place' : 'places'} you\'ve helped remember',
                            style: TextStyle(fontSize: 13.5, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_memories.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(isDark: isDark),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final items = _buildItems(context);
                        return items[i];
                      },
                      childCount: _buildItems(context).length,
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final result = <Widget>[];
    String? lastGroup;

    for (final m in _memories) {
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
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEEE),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
        ),
        confirmDismiss: (_) => showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete clue?'),
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
        onDismissed: (_) => _delete(m.id),
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
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[d.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (d.year == now.year) return '${months[d.month - 1]} ${d.day}';
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1 * 11,
          color: isDark ? const Color(0xFF8A7F74) : const Color(0xFF9C9384),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark ? const Color(0xFF8A7F74) : const Color(0xFF9C9384);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 52, color: mutedColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No clues yet',
              style: TextStyle(
                fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? ClueColors.paper : ClueColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + on the map to drop\nyour first clue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: mutedColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
