import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';
import '../theme/colors.dart';

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

String _categoryLabel(String type) => switch (type) {
      'item' => 'Item',
      'place' => 'Place',
      'parking' => 'Parking',
      'gate' => 'Gate',
      'outlet' => 'Outlet',
      'restroom' => 'Restroom',
      _ => 'Other',
    };

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.memory, this.onTap});

  final Memory memory;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor = isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final textColor = isDark ? ClueColors.paper : const Color(0xFF2A2419);
    final mutedColor = isDark ? const Color(0xFF8A7F74) : const Color(0xFFB0A794);

    // Primary display text: note in quotes if available, otherwise label in quotes
    final quoteText = memory.note != null
        ? '"${memory.note!}"'
        : '"${memory.label}"';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5.5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF1A1714).withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + category + time row
                Row(
                  children: [
                    Hero(
                      tag: 'memory_icon_${memory.id}',
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E6D5),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          memoryIcon(memory.iconType),
                          color: ClueColors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _categoryLabel(memory.iconType).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFFB0967A),
                      ),
                    ),
                    const Spacer(),
                    // Show label as location when note exists
                    if (memory.note != null)
                      Text(
                        memory.label,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                // Note/label in Bricolage Grotesque with quote style
                Text(
                  quoteText,
                  style: TextStyle(
                    fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                    fontSize: 15.5,
                    height: 1.35,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 11),
                // Bottom: clock + time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      _timeLabel(memory.timestamp),
                      style: TextStyle(fontSize: 12.5, color: mutedColor),
                    ),
                    if (memory.path != null && memory.path!.length > 1) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.route, size: 13, color: ClueColors.amber),
                      const SizedBox(width: 3),
                      Text(
                        'Path saved',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: ClueColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
