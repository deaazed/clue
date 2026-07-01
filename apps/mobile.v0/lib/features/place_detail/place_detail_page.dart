import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../config.dart';
import '../../models/memory.dart';
import '../../models/place.dart';
import '../../services/memory_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/memory_card.dart';

class PlaceDetailPage extends StatefulWidget {
  const PlaceDetailPage({super.key, required this.place});
  final Place place;

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  List<Memory> _clues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await MemoryRepository.loadAll();
    if (mounted) {
      setState(() {
        _clues = all
            .where((m) => m.placeId == widget.place.id)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    }
  }

  Future<void> _addClue() async {
    final saved = await context.push<bool>('/record', extra: widget.place);
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.place;
    final pinned = _clues.where((m) => m.lat != null).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Map header
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(p.lat, p.lng),
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
                      MarkerLayer(
                        markers: [
                          // Place centre
                          Marker(
                            point: LatLng(p.lat, p.lng),
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
                                      blurRadius: 8, color: Colors.black26)
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

                  // Back button
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.arrow_back,
                                      size: 20, color: ClueColors.ink),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Gradient fade at bottom
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

          // Place header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      fontFamily:
                          GoogleFonts.bricolageGrotesque().fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      color: isDark
                          ? ClueColors.paper
                          : ClueColors.ink,
                    ),
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
                  onTap: () =>
                      context.push('/memory', extra: _clues[i]),
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
