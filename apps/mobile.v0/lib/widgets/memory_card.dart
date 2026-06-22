import 'package:flutter/material.dart';
import '../models/memory.dart';

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
      'item' => const Color(0xFFF59E0B),      // amber
      'place' => const Color(0xFF10B981),     // emerald
      'parking' => const Color(0xFF3B82F6),   // blue
      'gate' => const Color(0xFFF97316),      // orange
      'outlet' => const Color(0xFFEAB308),    // yellow
      'restroom' => const Color(0xFF8B5CF6),  // violet
      _ => const Color(0xFF6B7280),           // gray
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(memoryIcon(memory.iconType),
                      color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
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
                      const SizedBox(height: 5),
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
                            const SizedBox(width: 8),
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
                Icon(Icons.chevron_right, color: cs.outlineVariant, size: 20),
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
