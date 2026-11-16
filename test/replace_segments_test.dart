import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/project_database.dart';

import 'support/fixtures.dart';

/// `ProjectDatabase.replaceClipWithSegments`, used by "remove silences" and
/// "split scenes".
void main() {
  late ProjectDatabase db;
  var n = 0;
  String newId() => 'n${n++}';

  setUp(() async {
    n = 0;
    db = ProjectDatabase.forTesting(NativeDatabase.memory());
    await seedProject(db, [
      clipRow(id: 'a', trimEndMs: 2000),
      clipRow(id: 'b', trimStartMs: 1000, trimEndMs: 9000, durationMs: 10000, transitionOut: 'dissolve', volume: 0.4, look: 'sepia', fitMode: 'blur', speed: 1.5),
      clipRow(id: 'c', trimEndMs: 2000),
    ]);
  });
  tearDown(() => db.close());

  test('splits into ordered clips that keep the original settings; later clips shift', () async {
    final ids = await db.replaceClipWithSegments('b', [(1000, 3000), (4000, 6000), (7000, 9000)], newId: newId);
    expect(ids, ['b', 'n0', 'n1']);
    final all = await db.watchClips('p1').first;
    expect([for (final c in all) c.id], ['a', 'b', 'n0', 'n1', 'c']);
    expect([for (final c in all) c.orderIndex], [0, 1, 2, 3, 4]);
    for (final c in all.sublist(1, 4)) {
      expect((c.volume, c.look, c.fitMode, c.speed), (0.4, 'sepia', 'blur', 1.5));
    }
    // Only the last piece keeps the outgoing dissolve.
    expect([for (final c in all.sublist(1, 4)) c.transitionOut], ['cut', 'cut', 'dissolve']);
  });

  test('segments are clamped to the trim window and empty ones dropped', () async {
    final ids = await db.replaceClipWithSegments('b', [(0, 2000), (5000, 5000), (8000, 12000)], newId: newId);
    expect(ids, hasLength(2));
    final all = await db.watchClips('p1').first;
    expect((all[1].trimStartMs, all[1].trimEndMs), (1000, 2000));
    expect((all[2].trimStartMs, all[2].trimEndMs), (8000, 9000));
  });

  test('nothing valid -> no change', () async {
    expect(await db.replaceClipWithSegments('b', [(50000, 60000)], newId: newId), isEmpty);
    expect(await db.replaceClipWithSegments('missing', [(0, 1000)], newId: newId), isEmpty);
    expect(await db.watchClips('p1').first, hasLength(3));
  });
}
