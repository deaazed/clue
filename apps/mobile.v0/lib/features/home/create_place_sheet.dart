import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/place.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';

class CreatePlaceSheet extends StatefulWidget {
  const CreatePlaceSheet({super.key});

  @override
  State<CreatePlaceSheet> createState() => _CreatePlaceSheetState();
}

class _CreatePlaceSheetState extends State<CreatePlaceSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

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
    setState(() { _saving = true; _error = null; });

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (pos == null) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not get your location. Check permissions.';
        });
      }
      return;
    }

    final place = Place(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lat: pos.latitude,
      lng: pos.longitude,
      timestamp: DateTime.now(),
    );

    await PlaceRepository.save(place);
    if (mounted) Navigator.of(context).pop(place);
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
          Text(
            'Add a place',
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
            'Name the venue you\'re in right now',
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 20),

          // Name field
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(
                  color: _error != null
                      ? const Color(0xFFE53935)
                      : borderColor),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.fromLTRB(15, 11, 15, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLACE NAME',
                  style: const TextStyle(
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
                    hintText: 'e.g. "Whole Foods", "Gate A14"',
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
              child: Text(_error!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFE53935))),
            ),
          ],
          const SizedBox(height: 20),

          // Info row — GPS will be used
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: ClueColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your current GPS position marks the place. Walk inside before saving.',
                  style: TextStyle(fontSize: 12, color: mutedColor, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                  : const Text('Save place'),
            ),
          ),
        ],
      ),
    );
  }
}
