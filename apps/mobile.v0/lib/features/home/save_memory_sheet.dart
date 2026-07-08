import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/memory.dart';
import '../../models/place.dart';
import '../../services/memory_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/memory_card.dart' show memoryIcon;
import '../../widgets/visibility_toggle.dart';

const _iconTypes = [
  'item', 'place', 'parking', 'gate', 'outlet', 'restroom', 'other',
];
const _iconLabels = [
  'Item', 'Place', 'Parking', 'Gate', 'Outlet', 'Restroom', 'Other',
];

class SaveMemorySheet extends StatefulWidget {
  const SaveMemorySheet({
    super.key,
    required this.place,
    required this.endpoint,
    required this.path,
    required this.bleDevices,
  });

  final Place place;
  final LatLng endpoint;
  final List<LatLng> path;
  final List<String> bleDevices;

  @override
  State<SaveMemorySheet> createState() => _SaveMemorySheetState();
}

class _SaveMemorySheetState extends State<SaveMemorySheet> {
  String _selectedIcon = 'item';
  final _labelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  bool _isPublic = true;
  String? _error;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Add a name for this clue');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final memory = Memory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      iconType: _selectedIcon,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      lat: widget.endpoint.latitude,
      lng: widget.endpoint.longitude,
      bleDevices: widget.bleDevices,
      timestamp: DateTime.now(),
      path: widget.path.length >= 2 ? widget.path : null,
      placeId: widget.place.id,
      isPublic: _isPublic,
    );

    await MemoryRepository.save(memory);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor = isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;

    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Drop a clue',
            style: TextStyle(
              fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.4,
              color: inkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.place.name,
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 18),

          // Category picker — fixed-width chips
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _iconTypes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final type = _iconTypes[i];
                final selected = _selectedIcon == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 70,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF4E6D5) : cardBg,
                      border: Border.all(
                        color: selected ? ClueColors.amber : borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(memoryIcon(type), size: 18,
                            color: selected ? ClueColors.amber : mutedColor),
                        const SizedBox(height: 4),
                        Text(
                          _iconLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? ClueColors.amber : mutedColor,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 13),

          // Name field
          _Field(
            label: 'NAME',
            cardBg: cardBg,
            borderColor: _error != null ? const Color(0xFFE53935) : borderColor,
            child: TextField(
              controller: _labelCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 15, color: inkColor, fontWeight: FontWeight.w600),
              decoration: InputDecoration.collapsed(
                hintText: 'e.g. "Oat milk", "Quiet corner"',
                hintStyle: TextStyle(fontSize: 15, color: mutedColor),
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
            ),
          ],
          const SizedBox(height: 10),

          // Note field — Bricolage descriptive text
          _Field(
            label: 'YOUR NOTE',
            cardBg: cardBg,
            borderColor: borderColor,
            child: TextField(
              controller: _noteCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(
                fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                fontSize: 15.5,
                height: 1.35,
                color: isDark ? ClueColors.paper : const Color(0xFF2A2419),
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Where exactly? Any useful detail…',
                hintStyle: TextStyle(
                  fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                  fontSize: 15.5,
                  color: mutedColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),

          // Privacy toggle
          VisibilityToggle(
            isPublic: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Drop clue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.cardBg,
    required this.borderColor,
    required this.child,
  });

  final String label;
  final Color cardBg;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Color(0xFFB0A794),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
