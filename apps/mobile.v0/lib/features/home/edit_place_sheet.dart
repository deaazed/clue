import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/place.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/visibility_toggle.dart';

class EditPlaceSheet extends StatefulWidget {
  const EditPlaceSheet({super.key, required this.place});
  final Place place;

  @override
  State<EditPlaceSheet> createState() => _EditPlaceSheetState();
}

class _EditPlaceSheetState extends State<EditPlaceSheet> {
  late final TextEditingController _nameCtrl;
  bool _saving = false;
  String? _error;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.place.name);
    _isPublic = widget.place.isPublic;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give this place a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final updated =
        widget.place.copyWith(name: name, isPublic: _isPublic);
    await PlaceRepository.save(updated);
    if (mounted) Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
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
          Text(
            'Edit place',
            style: TextStyle(
              fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.4,
              color: inkColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(
                color:
                    _error != null ? const Color(0xFFE53935) : borderColor,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLACE NAME',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: Color(0xFFB0A794),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                    fontSize: 16,
                    color: inkColor,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Place name',
                    hintStyle: TextStyle(
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      fontSize: 16,
                      color: mutedColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _error!,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFE53935)),
              ),
            ),
          ],
          const SizedBox(height: 14),
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
