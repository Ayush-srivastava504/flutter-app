import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/history/history_stack.dart';

void main() {
  test('record / undo / redo walk the history', () {
    final h = HistoryStack<int>()..reset(0);
    expect(h.record(1), isTrue);
    expect(h.record(2), isTrue);
    expect(h.undo(), 1);
    expect(h.undo(), 0);
    expect(h.undo(), isNull);
    expect(h.redo(), 1);
    expect(h.redo(), 2);
    expect(h.redo(), isNull);
  });

  test('recording an equal state is ignored (restore echoes do not create steps)', () {
    final h = HistoryStack<int>()..reset(5);
    expect(h.record(5), isFalse);
    expect(h.canUndo, isFalse);
  });

  test('a new edit after undo clears redo', () {
    final h = HistoryStack<int>()..reset(0);
    h.record(1);
    h.record(2);
    h.undo();
    expect(h.canRedo, isTrue);
    h.record(9);
    expect(h.canRedo, isFalse);
    expect(h.undo(), 1);
  });

  test('history is capped at the limit, dropping the oldest', () {
    final h = HistoryStack<int>(limit: 3)..reset(0);
    for (var i = 1; i <= 6; i++) {
      h.record(i);
    }
    expect(h.undoDepth, 3);
    h.undo();
    h.undo();
    expect(h.undo(), 3); // 0,1,2 were dropped
    expect(h.canUndo, isFalse);
  });

  test('first record becomes the baseline, not an undo step', () {
    final h = HistoryStack<int>();
    expect(h.record(1), isFalse);
    expect(h.canUndo, isFalse);
  });

  test('lists compare by value when wrapped in a value type', () {
    final h = HistoryStack<List<int>>()..reset([1]);
    // plain lists use identity equality: documents why ProjectSnapshot overrides ==
    expect(h.record([1]), isTrue);
  });
}
