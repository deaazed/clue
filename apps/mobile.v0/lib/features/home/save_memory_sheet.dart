import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/memory.dart';
import '../../services/memory_repository.dart';
import '../../widgets/memory_card.dart' show memoryIcon;

const _iconTypes = [
  'item',
  'place',
  'parking',
  'gate',
  'outlet',
  'restroom',
  'other',
];
const _iconLabels = [
  'Item',
  'Place',
  'Parking',
  'Gate',
  'Outlet',
  'Restroom',
  'Other',
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

  @override
  void dispose() {
    _labelCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.lowest,
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
        for (final r in results) { devices.add(r.device.remoteId.str); }
      });
      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 2));
      await Future.delayed(const Duration(seconds: 2));
    } catch (_) {
      // BLE unavailable or permissions not yet granted — save without it
    } finally {
      await sub?.cancel();
      try { await FlutterBluePlus.stopScan(); } catch (_) {}
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
    );

    await MemoryRepository.save(memory);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Save Memory',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          // Icon picker
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          memoryIcon(type),
                          size: 20,
                          color: selected ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _iconLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What is it? e.g. "Milk", "My car"',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
