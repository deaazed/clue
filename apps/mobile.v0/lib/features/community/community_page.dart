import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';

class _Contributor {
  const _Contributor({
    required this.userId,
    required this.displayName,
    required this.contributions,
  });
  final String userId;
  final String displayName;
  final int contributions;
}

/// Community tab — top contributors leaderboard. Nudges collaboration by
/// crediting the people who map the most public places and clues.
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<_Contributor>? _contributors; // null = loading, [] = empty/offline
  int _anonymous = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiClient.fetchCommunityTop();
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _contributors = [];
        _failed = true;
      });
      return;
    }
    setState(() {
      _failed = false;
      _anonymous = (data['anonymous_contributions'] as num?)?.toInt() ?? 0;
      _contributors = ((data['contributors'] as List<dynamic>?) ?? [])
          .map((e) => _Contributor(
                userId: e['user_id'] as String,
                displayName: e['display_name'] as String,
                contributions: (e['contributions'] as num).toInt(),
              ))
          .toList();
    });
  }

  Future<void> _openAccount() async {
    await context.push('/account');
    if (mounted) {
      setState(() {}); // sign-in state may have changed
      _load();
    }
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
    final me = AuthService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(AuthService.isSignedIn
                ? Icons.account_circle
                : Icons.account_circle_outlined),
            tooltip: 'Account',
            onPressed: _openAccount,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Sign-in CTA when logged out
            if (!AuthService.isSignedIn) ...[
              GestureDetector(
                onTap: _openAccount,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: ClueColors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: ClueColors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          size: 22, color: ClueColors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign in to join the leaderboard',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: inkColor,
                              ),
                            ),
                            Text(
                              'Your public clues get credited to you',
                              style: TextStyle(
                                  fontSize: 12, color: mutedColor),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: ClueColors.amber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            Text(
              'Top contributors',
              style: TextStyle(
                fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: inkColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Everyone who maps public places and clues helps the whole hive find things faster.',
              style:
                  TextStyle(fontSize: 12.5, height: 1.45, color: mutedColor),
            ),
            const SizedBox(height: 16),

            if (_contributors == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_contributors!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _failed ? Icons.cloud_off : Icons.groups_outlined,
                        size: 44,
                        color: mutedColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _failed
                            ? 'Couldn\'t reach the community — pull to retry'
                            : 'No contributors yet.\nSign in and drop public clues to be the first!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, height: 1.5, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._contributors!.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final c = entry.value;
                final isMe = me != null && c.userId == me.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? ClueColors.amber.withValues(alpha: 0.10)
                          : cardBg,
                      border: Border.all(
                        color: isMe ? ClueColors.amber : borderColor,
                        width: isMe ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _RankBadge(rank: rank),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMe ? '${c.displayName} (you)' : c.displayName,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                                  isMe ? FontWeight.w800 : FontWeight.w600,
                              color: inkColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: ClueColors.amber.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${c.contributions} clue${c.contributions == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB0672C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            if (_contributors != null &&
                !_failed &&
                _anonymous > 0) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '+ $_anonymous contribution${_anonymous == 1 ? '' : 's'} from anonymous explorers',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (rank) {
      1 => (const Color(0xFFF5C518), Colors.white), // gold
      2 => (const Color(0xFFB8BCC4), Colors.white), // silver
      3 => (const Color(0xFFCD7F32), Colors.white), // bronze
      _ => (
          ClueColors.muted.withValues(alpha: 0.15),
          ClueColors.muted,
        ),
    };
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}
