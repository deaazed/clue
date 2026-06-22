import 'package:flutter/material.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../home/home_page.dart' show memoryIcon;

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
                          padding: const EdgeInsets.only(right: 20),
                          color: cs.errorContainer,
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
                        onDismissed: (_) => _delete(m.id),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(memoryIcon(m.iconType),
                                color: cs.primary, size: 20),
                          ),
                          title: Text(m.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.note != null)
                                Text(m.note!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant)),
                              Text(
                                _formatTime(m.timestamp),
                                style: TextStyle(
                                    fontSize: 12, color: cs.outline),
                              ),
                            ],
                          ),
                          isThreeLine: m.note != null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today at $h:$m';
    }
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
