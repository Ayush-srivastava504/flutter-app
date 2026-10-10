/// Generic undo/redo stack. No Flutter or database imports, so it's trivially
/// unit-testable.
///
/// Usage: call [record] with the *new* state after every change. Recording a
/// state equal to the current one is ignored — that's what makes restoring a
/// snapshot (which re-emits the same state from the database) a no-op.
class HistoryStack<T> {
  final int limit;
  final List<T> _undo = [];
  final List<T> _redo = [];
  T? _current;
  bool _hasCurrent = false;

  HistoryStack({this.limit = 50});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoDepth => _undo.length;
  int get redoDepth => _redo.length;

  /// Sets the baseline without creating an undo step (e.g. when a project opens).
  void reset(T state) {
    _undo.clear();
    _redo.clear();
    _current = state;
    _hasCurrent = true;
  }

  /// Returns true if this created a new undo step.
  bool record(T state) {
    if (!_hasCurrent) {
      reset(state);
      return false;
    }
    if (state == _current) return false;
    _undo.add(_current as T);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
    _current = state;
    return true;
  }

  /// Moves back one step and returns the state to restore, or null.
  T? undo() {
    if (!canUndo) return null;
    _redo.add(_current as T);
    _current = _undo.removeLast();
    return _current;
  }

  T? redo() {
    if (!canRedo) return null;
    _undo.add(_current as T);
    _current = _redo.removeLast();
    return _current;
  }
}
