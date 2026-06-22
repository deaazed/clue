import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../widgets/memory_card.dart';
import 'save_memory_sheet.dart';

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
      body: SafeArea(
        child: ListView(
          children: [
            _Header(cs: cs, onSearchTap: () => context.go('/search')),
            if (_recent.isEmpty)
              _EmptyState(cs: cs)
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Text(
                  'RECENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ..._recent.map(
                (m) => MemoryCard(
                  memory: m,
                  onTap: () => context.push('/memory', extra: m),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSave,
        icon: const Icon(Icons.add),
        label: const Text('Save Memory'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs, required this.onSearchTap});
  final ColorScheme cs;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/logo-clue.svg',
                width: 28,
                height: 28,
                colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                'Clue',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your indoor memory',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Search memories…',
                    style:
                        TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/logo-clue.svg',
            width: 72,
            height: 72,
            colorFilter:
                ColorFilter.mode(cs.outlineVariant, BlendMode.srcIn),
          ),
          const SizedBox(height: 20),
          Text(
            'No memories yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
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
}
