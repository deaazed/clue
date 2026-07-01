import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/memory_card.dart' show memoryIcon;

const _iconTypes = [
  'item', 'place', 'parking', 'gate', 'outlet', 'restroom', 'other',
];
const _iconLabels = [
  'Item', 'Place', 'Parking', 'Gate', 'Outlet', 'Restroom', 'Other',
];

class SaveMemorySheet extends StatefulWidget {
  const SaveMemorySheet({super.key});

  @override
  State<SaveMemorySheet> createState() => _SaveMemorySheetState();
}

class _SaveMemorySheetState extends State<SaveMemorySheet> {
  String _selectedIcon = 'item';
  final _labelCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  // Path recording — accumulate GPS breadcrumbs while the sheet is open
  final List<LatLng> _pathPoints = [];
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen(
      (pos) {
        if (mounted) _pathPoints.add(LatLng(pos.latitude, pos.longitude));
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _getPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && last.accuracy <= 150) {
        final age = DateTime.now().difference(last.timestamp);
        if (age.inMinutes <= 15) return last;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _bleScan() async {
    final devices = <String>{};
    StreamSubscription? sub;
    try {
      sub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          devices.add(r.device.remoteId.str);
        }
      });
      await FlutterBluePlus.startScan(
          timeout: const Duration(milliseconds: 1500));
      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (_) {
    } finally {
      await sub?.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    return devices.toList();
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Please enter a label');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final posFuture = _getPosition();
    final bleFuture = _bleScan();
    final pos = await posFuture;
    final ble = await bleFuture;

    final memory = Memory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      iconType: _selectedIcon,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      lat: pos?.latitude,
      lng: pos?.longitude,
      bleDevices: ble,
      timestamp: DateTime.now(),
      path: _pathPoints.length >= 2 ? List.unmodifiable(_pathPoints) : null,
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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drop a clue',
                    style: TextStyle(
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.4,
                      color: isDark ? ClueColors.paper : ClueColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Save where something is',
                    style: TextStyle(fontSize: 12.5, color: mutedColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Note field — primary input in Bricolage style
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: _error != null ? const Color(0xFFE53935) : borderColor),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR NOTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: const Color(0xFFB0A794),
                  ),
                ),
                const SizedBox(height: 7),
                TextField(
                  controller: _labelCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                    fontSize: 16,
                    height: 1.35,
                    color: isDark ? ClueColors.paper : const Color(0xFF2A2419),
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: 'e.g. "Best oat milk, bottom shelf"',
                    hintStyle: TextStyle(
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      fontSize: 16,
                      color: const Color(0xFFB0A794),
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
              child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
            ),
          ],
          const SizedBox(height: 13),

          // Category picker
          SizedBox(
            height: 60,
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFF4E6D5) : cardBg,
                      border: Border.all(
                        color: selected ? ClueColors.amber : borderColor,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          memoryIcon(type),
                          size: 18,
                          color: selected ? ClueColors.amber : mutedColor,
                        ),
                        const SizedBox(height: 3),
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
          const SizedBox(height: 20),

          // CTA button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
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
