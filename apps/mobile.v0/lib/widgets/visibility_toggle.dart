import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Public / "Just me" segmented toggle used when saving or editing
/// places and clues. Private items never leave the device.
class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({
    super.key,
    required this.isPublic,
    required this.onChanged,
  });

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isPublic ? const Color(0xFFF4E6D5) : cardBg,
                border: Border.all(
                  color: isPublic ? ClueColors.amber : borderColor,
                  width: isPublic ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.public,
                      size: 16,
                      color: isPublic ? ClueColors.amber : mutedColor),
                  const SizedBox(width: 7),
                  Text('Public',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isPublic
                            ? const Color(0xFFB0672C)
                            : mutedColor,
                      )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border.all(
                  color: !isPublic ? inkColor : borderColor,
                  width: !isPublic ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: !isPublic ? inkColor : mutedColor),
                  const SizedBox(width: 7),
                  Text('Just me',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: !isPublic ? inkColor : mutedColor,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
