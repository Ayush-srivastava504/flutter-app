import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../data/project_database.dart';
import 'history_stack.dart';

/// Undo/redo + autosave for one project.
///
/// Every timeline edit already goes straight to SQLite, so instead of
/// instrumenting each widget this watches the project's rows, snapshots them
/// (debounced, so a slider drag or a burst of edits becomes ONE undo step) and
/// restores a snapshot on undo/redo. The same debounced tick stamps
/// `updatedAt`, which is the autosave "last saved" time shown in the editor.
class ProjectHistory extends ChangeNotifier {
  static const Duration debounce = Duration(milliseconds: 450);

  final ProjectDatabase _db;
  final String projectId;
  final HistoryStack<ProjectSnapshot> _stack = HistoryStack(limit: 50);
  final List<StreamSubscription<dynamic>> _subs = [];
  Timer? _timer;
  bool _restoring = false;
  bool _disposed = false;
  DateTime? _lastSaved;

  ProjectHistory(this._db, this.projectId) {
    _init();
  }

  bool get canUndo => _stack.canUndo;
  bool get canRedo => _stack.canRedo;
  DateTime? get lastSaved => _lastSaved;

  Future<void> _init() async {
    _stack.reset(await _db.snapshotProject(projectId));
    _lastSaved = (await _db.getProject(projectId))?.updatedAt;
    if (_disposed) return;
    _subs
      ..add(_db.watchClips(projectId).listen((_) => _schedule()))
      ..add(_db.watchAudioTrack(projectId).listen((_) => _schedule()))
      ..add(_db.watchTextOverlays(projectId).listen((_) => _schedule()));
    notifyListeners();
  }

  void _schedule() {
    if (_restoring || _disposed) return;
    _timer?.cancel();
    _timer = Timer(debounce, _capture);
  }

  Future<void> _capture() async {
    if (_disposed || _restoring) return;
    final snap = await _db.snapshotProject(projectId);
    if (_disposed || _restoring) return;
    if (_stack.record(snap)) {
      await _db.touchProject(projectId); // autosave stamp
      _lastSaved = DateTime.now();
      notifyListeners();
    }
  }

  Future<void> undo() => _apply(_stack.undo());
  Future<void> redo() => _apply(_stack.redo());

  Future<void> _apply(ProjectSnapshot? target) async {
    if (target == null) return;
    _timer?.cancel();
    _restoring = true;
    try {
      await _db.restoreProject(projectId, target);
      await _db.touchProject(projectId);
      _lastSaved = DateTime.now();
    } finally {
      // Let the stream events from the restore drain before we start listening
      // for edits again; they equal the restored state, so they'd be ignored anyway.
      Future<void>.delayed(const Duration(milliseconds: 50), () => _restoring = false);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

final projectHistoryProvider = ChangeNotifierProvider.autoDispose.family<ProjectHistory, String>((ref, projectId) {
  return ProjectHistory(ref.watch(projectDatabaseProvider), projectId);
});
