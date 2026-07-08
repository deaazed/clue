import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../config.dart';
import '../../models/memory.dart';
import '../../models/place.dart';
import '../../services/memory_repository.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/memory_card.dart';
import '../clue_recording/trace_shape_recording_page.dart';
import '../home/edit_place_sheet.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.place});
  final Place place;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  late Place _place;
  List<Memory> _clues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _load();
  }

  Future<void> _load() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _clues = all
            .where((m) => m.placeId == _place.id)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    }
  }

  Future<void> _addClue() async {
    final saved = await context.push<bool>('/record', extra: _place);
    if (saved == true) _load();
  }

  Future<void> _traceShape() async {
    final updated = await context.push<Object?>(
      '/trace',
      extra: TraceShapeArgs(
        center: LatLng(_place.lat, _place.lng),
        title: _place.name,
        onSave: (pts, centroid) async {
          // Move the place pin to the centroid of the traced boundary
          final p = _place.copyWith(
            boundary: pts,
            lat: centroid.latitude,
            lng: centroid.longitude,
          );
          await PlaceRepository.save(p);
          return p;
        },
      ),
    );
    if (updated is Place && mounted) {
      setState(() => _place = updated);
    }
  }

  Future<void> _rename() async {
    final updated = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditPlaceSheet(place: _place),
    );
    if (updated != null && mounted) {
      setState(() => _place = updated);
    }
  }

  Future<void> _toggleVisibility() async {
    final updated = _place.copyWith(isPublic: !_place.isPublic);
    await PlaceRepository.save(updated);
    if (!mounted) return;
    setState(() => _place = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updated.isPublic
            ? '"${updated.name}" is now public'
            : '"${updated.name}" is now private — removed from the hive'),
      ),
    );
  }

  Future<void> _deletePlace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text(
          'This will permanently delete "${_place.name}" and all its clues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE53935)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await MemoryRepository.deleteByPlaceId(_place.id);
    await PlaceRepository.delete(_place.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _showActions() {
    final hasBoundary =
        _place.boundary != null && _place.boundary!.length >= 3;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit name & privacy'),
              onTap: () {
                Navigator.pop(context);
                _rename();
              },
            ),
            ListTile(
              leading: Icon(_place.isPublic
                  ? Icons.lock_outline
                  : Icons.public),
              title: Text(_place.isPublic
                  ? 'Make private'
                  : 'Make public'),
              onTap: () {
                Navigator.pop(context);
                _toggleVisibility();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pentagon_outlined),
              title: Text(
                  hasBoundary ? 'Update shape' : 'Trace shape'),
              onTap: () {
                Navigator.pop(context);
                _traceShape();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Color(0xFFE53935)),
              title: const Text('Delete place',
                  style: TextStyle(color: Color(0xFFE53935))),
              onTap: () {
                Navigator.pop(context);
                _deletePlace();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pinned = _clues.where((m) => m.lat != null).toList();
    final hasBoundary =
        _place.boundary != null && _place.boundary!.length >= 3;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Map header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_place.lat, _place.lng),
                      initialZoom: 17.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                            : kOsmTilesUrl,
                        subdomains: isDark
                            ? const ['a', 'b', 'c', 'd']
                            : const [],
                        maxNativeZoom: 19,
                        userAgentPackageName: 'com.clue',
                      ),

                      // Boundary polygon
                      if (hasBoundary)
                        PolygonLayer(polygons: [
                          Polygon(
                            points: _place.boundary!,
                            color:
                                ClueColors.amber.withValues(alpha: 0.15),
                            borderColor:
                                ClueColors.amber.withValues(alpha: 0.7),
                            borderStrokeWidth: 2.0,
                          ),
                        ]),

                      MarkerLayer(
                        markers: [
                          // Place centre
                          Marker(
                            point: LatLng(_place.lat, _place.lng),
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ClueColors.ink,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                      blurRadius: 8,
                                      color: Colors.black26)
                                ],
                              ),
                              child: const Icon(Icons.storefront,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                          // Clue pins
                          ...pinned.map(
                            (m) => Marker(
                              point: LatLng(m.lat!, m.lng!),
                              width: 26,
                              height: 26,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: memoryColor(m.iconType),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: Icon(memoryIcon(m.iconType),
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Back + more buttons
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            _MapBtn(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.arrow_back,
                                  size: 20, color: ClueColors.ink),
                            ),
                            const Spacer(),
                            _MapBtn(
                              onTap: _showActions,
                              child: const Icon(Icons.more_vert,
                                  size: 20, color: ClueColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Gradient fade
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            isDark
                                ? ClueColors.inkSurface
                                : const Color(0xFFF7F2EA),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Place header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _place.name,
                          style: TextStyle(
                            fontFamily:
                                GoogleFonts.bricolageGrotesque().fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            letterSpacing: -0.5,
                            color:
                                isDark ? ClueColors.paper : ClueColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_place.isPublic) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? ClueColors.paper
                                    : ClueColors.ink)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 11,
                                  color: isDark
                                      ? const Color(0xFF8A7F74)
                                      : const Color(0xFF8A8172)),
                              const SizedBox(width: 4),
                              Text(
                                'Private',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF8A7F74)
                                      : const Color(0xFF8A8172),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _loading
                        ? 'Loading clues…'
                        : '${_clues.length} ${_clues.length == 1 ? 'clue' : 'clues'} saved here',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark
                          ? const Color(0xFF8A7F74)
                          : const Color(0xFF8A8172),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Trace shape CTA (only when no boundary yet) ───────────────
          if (!hasBoundary)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: GestureDetector(
                  onTap: _traceShape,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: ClueColors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ClueColors.amber.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: ClueColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pentagon_outlined,
                              size: 18, color: ClueColors.amber),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trace this place\'s shape',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.bricolageGrotesque()
                                      .fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? ClueColors.paper
                                      : ClueColors.ink,
                                ),
                              ),
                              Text(
                                'Walk the perimeter so Clue knows exactly where you are',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF8A7F74)
                                      : const Color(0xFF8A8172),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: ClueColors.amber),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Clue list ─────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_clues.isEmpty)
            SliverFillRemaining(
              child: _EmptyClues(isDark: isDark, onAdd: _addClue),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => MemoryCard(
                  memory: _clues[i],
                  onTap: () => context.push('/memory', extra: _clues[i]),
                ),
                childCount: _clues.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 58,
        height: 58,
        child: FloatingActionButton(
          onPressed: _addClue,
          backgroundColor: ClueColors.ink,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  const _MapBtn({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyClues extends StatelessWidget {
  const _EmptyClues({required this.isDark, required this.onAdd});
  final bool isDark;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 52,
              color: (isDark
                      ? const Color(0xFF8A7F74)
                      : const Color(0xFF9C9384))
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No clues yet',
              style: TextStyle(
                fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? ClueColors.paper : ClueColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to walk to an item\nand drop your first clue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF8A7F74)
                    : const Color(0xFF9C9384),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
