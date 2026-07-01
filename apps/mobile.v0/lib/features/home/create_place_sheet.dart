import 'dart:async';
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
  // Live accuracy feedback during GPS acquisition
  double? _liveAccuracy;

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
    setState(() { _saving = true; _error = null; _liveAccuracy = null; });

    Position? best;

    // Use last known as an instant fallback while the stream warms up
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) best = last;
    } catch (_) {}

    // Stream positions for up to 15 s; pick the one with smallest accuracy radius
    try {
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));

      await for (final pos in stream) {
        if (best == null || pos.accuracy < best.accuracy) {
          best = pos;
          if (mounted) setState(() => _liveAccuracy = pos.accuracy);
        }
        // Good enough — stop waiting
        if (pos.accuracy <= 15.0) break;
      }
    } catch (_) {}

    if (best == null) {
      if (mounted) {
        setState(() {
          _saving = false;
          _liveAccuracy = null;
          _error = 'Could not get your location. Check permissions.';
        });
      }
      return;
    }

    final place = Place(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lat: best.latitude,
      lng: best.longitude,
      timestamp: DateTime.now(),
    );

    await PlaceRepository.save(place);
    if (mounted) Navigator.of(context).pop(place);
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

          // GPS info row — live accuracy chip while saving
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: ClueColors.amber),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _saving
                      ? 'Finding best position…'
                      : 'Your GPS position marks the place. Walk inside before saving.',
                  style:
                      TextStyle(fontSize: 12, color: mutedColor, height: 1.4),
                ),
              ),
              if (_saving && _liveAccuracy != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accuracyColor(_liveAccuracy!)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '±${_liveAccuracy!.round()} m',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accuracyColor(_liveAccuracy!),
                    ),
                  ),
                ),
              ],
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

Color _accuracyColor(double accuracy) {
  if (accuracy < 20) return const Color(0xFF34A853);
  if (accuracy < 60) return ClueColors.amber;
  return const Color(0xFFE53935);
}
