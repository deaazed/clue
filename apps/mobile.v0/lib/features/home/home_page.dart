import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import 'save_memory_sheet.dart';

IconData memoryIcon(String type) => switch (type) {
      'item' => Icons.inventory_2_outlined,
      'place' => Icons.location_on_outlined,
      'parking' => Icons.local_parking,
      'gate' => Icons.flight,
      'outlet' => Icons.power_outlined,
      'restroom' => Icons.wc,
      _ => Icons.more_horiz,
    };

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Memory> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) setState(() => _recent = all.take(5).toList());
  }

  Future<void> _showSave() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SaveMemorySheet(),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Clue')),
      body: _recent.isEmpty ? _emptyState(cs) : _recentList(cs),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSave,
        icon: const Icon(Icons.add),
        label: const Text('Save Memory'),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logo-clue.svg',
            width: 72,
            height: 72,
            colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
          ),
          const SizedBox(height: 20),
          Text(
            'No memories yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to save your first memory',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _recentList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _recent.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Recent',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          );
        }
        return MemoryTile(memory: _recent[i - 1]);
      },
    );
  }
}

class MemoryTile extends StatelessWidget {
  const MemoryTile({super.key, required this.memory});
  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Icon(memoryIcon(memory.iconType), color: cs.primary, size: 20),
      ),
      title: Text(memory.label,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: memory.note != null
          ? Text(memory.note!,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        _timeLabel(memory.timestamp),
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}
