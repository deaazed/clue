import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/place.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';
import 'map_picker_page.dart';

class CreatePlaceSheet extends StatefulWidget {
  const CreatePlaceSheet({super.key, this.initialPosition});
  final LatLng? initialPosition;

  @override
  State<CreatePlaceSheet> createState() => _CreatePlaceSheetState();
}

class _CreatePlaceSheetState extends State<CreatePlaceSheet> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  LatLng? _gpsPosition;
  LatLng? _picked;
  bool _loadingGps = false;

  LatLng? get _effectivePosition => _picked ?? _gpsPosition;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _gpsPosition = widget.initialPosition;
    } else {
      _loadingGps = true;
      _fetchGps();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted && _picked == null) {
        setState(() {
          _gpsPosition = LatLng(last.latitude, last.longitude);
          _loadingGps = false;
        });
        return;
      }
    } catch (_) {}

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 5));
      if (mounted && _picked == null) {
        setState(() => _gpsPosition = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}

    if (mounted) setState(() => _loadingGps = false);
  }

  Future<void> _pickOnMap() async {
    final ll = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(initialPosition: _effectivePosition),
      ),
    );
    if (ll != null && mounted) {
      setState(() {
        _picked = ll;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give this place a name');
      return;
    }

    // No GPS yet — open map picker immediately instead of blocking
    if (_effectivePosition == null) {
      await _pickOnMap();
      if (_effectivePosition == null) return;
    }

    setState(() { _saving = true; _error = null; });

    final location = _effectivePosition!;
    final place = Place(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      lat: location.latitude,
      lng: location.longitude,
      timestamp: DateTime.now(),
    );

    await PlaceRepository.save(place);
    if (mounted) Navigator.of(context).pop(place);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final cardBg = isDark ? const Color(0xFF2E2820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);
    final mutedColor =
        isDark ? const Color(0xFF8A7F74) : const Color(0xFF8A8172);
    final inkColor = isDark ? ClueColors.paper : ClueColors.ink;
    final hasLocation = _effectivePosition != null;

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
            'Name the venue you\'re saving',
            style: TextStyle(fontSize: 12.5, color: mutedColor),
          ),
          const SizedBox(height: 20),

          // Name field
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(
                color: _error != null && _error!.contains('name')
                    ? const Color(0xFFE53935)
                    : borderColor,
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

          const SizedBox(height: 14),

          // Location status + pick button side by side
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: hasLocation ? ClueColors.amber : mutedColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _picked != null
                      ? 'Location set on map'
                      : hasLocation
                          ? 'Using your approximate location'
                          : _loadingGps
                              ? 'Finding your location…'
                              : 'No location found',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ),
              if (_loadingGps && !hasLocation) ...[
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: mutedColor),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Always-visible map picker button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _pickOnMap,
              icon: Icon(
                _picked != null ? Icons.edit_location_alt_outlined : Icons.map_outlined,
                size: 16,
              ),
              label: Text(
                _picked != null
                    ? 'Change location on map'
                    : 'Pick location on map',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE53935)),
            ),
          ],

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
