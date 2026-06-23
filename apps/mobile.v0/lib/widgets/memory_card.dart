import 'package:flutter/material.dart';
import '../models/memory.dart';
import '../theme/spacing.dart';

IconData memoryIcon(String type) => switch (type) {
      'item' => Icons.inventory_2_outlined,
      'place' => Icons.location_on_outlined,
      'parking' => Icons.local_parking,
      'gate' => Icons.flight,
      'outlet' => Icons.power_outlined,
      'restroom' => Icons.wc,
      _ => Icons.more_horiz,
    };

Color memoryColor(String type) => switch (type) {
      'item' => const Color(0xFFF59E0B),
      'place' => const Color(0xFF10B981),
      'parking' => const Color(0xFF3B82F6),
      'gate' => const Color(0xFFF97316),
      'outlet' => const Color(0xFFEAB308),
      'restroom' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF6B7280),
    };

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memory, this.onTap});

  final Memory memory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = memoryColor(memory.iconType);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            child: Row(
              children: [
                Hero(
                  tag: 'memory_icon_${memory.id}',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.iconRadius),
                    ),
                    child: Icon(memoryIcon(memory.iconType),
                        color: color, size: 22),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (memory.note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          memory.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs + 1),
                      Row(
                        children: [
                          if (memory.lat != null) ...[
                            Icon(Icons.location_on,
                                size: 12, color: cs.primary),
                            const SizedBox(width: 2),
                            Text(
                              'Pinned',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            _timeLabel(memory.timestamp),
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right,
                    color: cs.outlineVariant, size: 18),
              ],
            ),
          ),
        ),
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
