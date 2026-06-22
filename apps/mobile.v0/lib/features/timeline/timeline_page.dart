import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
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
    if (mounted) setState(() { _memories = all; _loading = false; });
  }

  Future<void> _delete(String id) async {
    await MemoryRepository.delete(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text('No memories yet',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _memories.length,
                    itemBuilder: (context, i) {
                      final m = _memories[i];
                      return Dismissible(
                        key: Key(m.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.delete_outline, color: cs.error),
                        ),
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete memory?'),
                            content:
                                Text('"${m.label}" will be removed.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => _delete(m.id),
                        child: MemoryCard(
                          memory: m,
                          onTap: () =>
                              context.push('/memory', extra: m),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
