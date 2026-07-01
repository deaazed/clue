import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/place.dart';
import '../../services/place_repository.dart';
import '../../theme/colors.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  List<Place> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await PlaceRepository.loadAll();
    if (mounted) {
      setState(() {
        _places = places..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Places',
                      style: TextStyle(
                        fontFamily:
                            GoogleFonts.bricolageGrotesque().fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        letterSpacing: -0.5,
                        color: isDark ? ClueColors.paper : ClueColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _loading
                          ? ''
                          : _places.isEmpty
                              ? 'No places yet'
                              : '${_places.length} ${_places.length == 1 ? 'venue' : 'venues'} remembered',
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
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_places.isEmpty)
            SliverFillRemaining(
              child: _EmptyPlaces(isDark: isDark),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PlaceCard(
                  place: _places[i],
                  isDark: isDark,
                  onTap: () => context.push('/place', extra: _places[i]),
                ),
                childCount: _places.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.isDark,
    required this.onTap,
  });

  final Place place;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? ClueColors.inkCard : const Color(0xFFFBF7F0);
    final borderColor =
        isDark ? const Color(0xFF3A342C) : const Color(0xFFE9E0D1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4E6D5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 20,
                      color: ClueColors.amber,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontFamily:
                                GoogleFonts.bricolageGrotesque().fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: isDark ? ClueColors.paper : ClueColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(place.timestamp),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? const Color(0xFF8A7F74)
                                : const Color(0xFF8A8172),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF8A7F74)
                        : const Color(0xFF9C9384),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 52,
              color: (isDark
                      ? const Color(0xFF8A7F74)
                      : const Color(0xFF9C9384))
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No places yet',
              style: TextStyle(
                fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? ClueColors.paper : ClueColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Map tab and tap +\nto add a place.',
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
