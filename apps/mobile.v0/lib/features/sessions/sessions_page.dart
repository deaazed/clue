import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/session.dart';
import '../../services/session_repository.dart';
import '../../services/api_client.dart';

enum _UploadStatus { idle, uploading, done, failed }

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<Session>? _sessions;
  final Map<String, _UploadStatus> _uploads = {};
  final _listKey = GlobalKey<AnimatedListState>();

  static const _removeDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await SessionRepository.loadAll();
    if (mounted) setState(() => _sessions = sessions);
  }

  bool get _isUploading =>
      _uploads.values.any((s) => s == _UploadStatus.uploading);

  List<Session> get _uploadable => (_sessions ?? [])
      .where((s) =>
          (_uploads[s.id] ?? _UploadStatus.idle) == _UploadStatus.idle)
      .toList();

  Future<void> _upload(Session session) async {
    setState(() => _uploads[session.id] = _UploadStatus.uploading);
    try {
      await ApiClient.uploadSession(session);
      await _removeAfterUpload(session);
    } catch (e) {
      if (mounted) {
        setState(() => _uploads[session.id] = _UploadStatus.failed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _uploadAll() async {
    // Snapshot before any removals shift the list
    final toUpload = List<Session>.from(_uploadable);
    await Future.wait(toUpload.map(_upload));
  }

  Future<void> _removeAfterUpload(Session session) async {
    await SessionRepository.delete(session.id);
    if (!mounted) return;

    final idx = _sessions!.indexOf(session);
    if (idx == -1) return;

    // Update data before notifying AnimatedList so itemBuilder indices align
    _sessions!.removeAt(idx);
    _uploads.remove(session.id);

    _listKey.currentState?.removeItem(
      idx,
      (ctx, anim) => SizeTransition(
        sizeFactor: anim,
        child: FadeTransition(
          opacity: anim,
          child: _SessionTile(session,
              status: _UploadStatus.done, onUpload: () {}),
        ),
      ),
      duration: _removeDuration,
    );

    // Wait for animation before rebuilding (avoids tearing on last item)
    await Future.delayed(_removeDuration);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: Column(
        children: [
          Expanded(child: _buildList()),
          _UploadAllBar(
            count: _uploadable.length,
            uploading: _isUploading,
            onPressed: _uploadAll,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final sessions = _sessions;
    if (sessions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (sessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No sessions yet.\nRecord one on the Logger tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: AnimatedList(
        key: _listKey,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        initialItemCount: sessions.length,
        itemBuilder: (ctx, i, anim) => SizeTransition(
          sizeFactor: anim,
          child: _SessionTile(
            sessions[i],
            status: _uploads[sessions[i].id] ?? _UploadStatus.idle,
            onUpload: () => _upload(sessions[i]),
          ),
        ),
      ),
    );
  }
}

class _UploadAllBar extends StatelessWidget {
  const _UploadAllBar({
    required this.count,
    required this.uploading,
    required this.onPressed,
  });
  final int count;
  final bool uploading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: FilledButton.icon(
        onPressed: (count == 0 || uploading) ? null : onPressed,
        icon: uploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(
          uploading
              ? 'Uploading...'
              : count > 0
                  ? 'Upload All ($count)'
                  : 'All uploaded',
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile(this.session,
      {required this.status, required this.onUpload});
  final Session session;
  final _UploadStatus status;
  final VoidCallback onUpload;

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.sensors, color: Colors.indigo),
          title: Text(dateStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          subtitle: Text('$durStr · ${session.sampleCount} samples'),
          trailing: _trailing(),
          onTap: () => context.push('/sessions/${session.id}', extra: session),
        ),
      ),
    );
  }

  Widget _trailing() => switch (status) {
        _UploadStatus.idle => IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Upload to server',
            onPressed: onUpload,
          ),
        _UploadStatus.uploading => const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        _UploadStatus.done =>
          const Icon(Icons.cloud_done, color: Colors.green),
        _UploadStatus.failed =>
          const Icon(Icons.cloud_off, color: Colors.red),
      };
}
