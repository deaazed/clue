import 'package:flutter/material.dart';
import '../../models/session.dart';
import '../../services/session_repository.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<Session>? _sessions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SessionRepository.loadAll();
    if (mounted) setState(() => _sessions = sessions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: switch (_sessions) {
        null => const Center(child: CircularProgressIndicator()),
        [] => const Center(
            child: Text(
              'No sessions yet.\nRecord one on the Logger tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        final sessions => RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (_, i) => _SessionTile(sessions[i]),
            ),
          ),
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session);
  final Session session;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(session.startedAtMs);
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    final dur = session.durationMs / 1000;
    final durStr = dur < 60
        ? '${dur.toStringAsFixed(1)} s'
        : '${(dur / 60).floor()}m ${(dur % 60).floor()}s';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.sensors, color: Colors.indigo),
        title: Text(dateStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text('$durStr · ${session.sampleCount} samples'),
      ),
    );
  }
}
