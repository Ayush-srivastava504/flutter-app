import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/app/app_prefs.dart';
import 'package:video_editor_app/app/app_theme.dart';
import 'package:video_editor_app/app/launch_gate.dart';
import 'package:video_editor_app/data/database_provider.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/providers/timeline_providers.dart';
import 'package:video_editor_app/screens/editor_screen.dart';

/// Regression test for "bottom overflowed" in the editor when the phone is
/// rotated: the editor must lay out in portrait and landscape, with the tool
/// dock and with every clip panel open.
void main() {
  const sizes = [(360.0, 640.0), (412.0, 915.0), (640.0, 360.0), (915.0, 412.0)];

  Future<ProviderContainer> pumpEditor(WidgetTester tester, (double, double) size, {bool withClip = false}) async {
    tester.view.physicalSize = Size(size.$1, size.$2);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = ProjectDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dir = Directory.systemTemp.createTempSync('editor_prefs');
    final prefs = AppPrefs(directory: () async => dir);
    await tester.runAsync(() async {
      // The first-open guide would cover the editor; mark it seen.
      for (final m in ['youtube', 'insta', 'normal']) {
        await prefs.markModeTipsSeen(m);
      }
      final now = DateTime.now();
      await db.insertProject(ProjectsCompanion.insert(
          id: 'p1', name: 'Layout test', mode: const Value('youtube'), aspectRatio: const Value(16 / 9),
          createdAt: now, updatedAt: now));
      if (withClip) {
        await db.appendClip(id: 'c1', projectId: 'p1', sourceUri: '/missing/photo.jpg', durationMs: 3000);
      }
    });

    final container = ProviderContainer(overrides: [
      projectDatabaseProvider.overrideWithValue(db),
      appPrefsProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildAppTheme(), home: const EditorScreen(projectId: 'p1')),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    return container;
  }

  Future<void> unmount(WidgetTester tester) async {
    // Let the editor's autosave debounce (450 ms) fire before tearing down.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 600)); // drift + history timers
  }

  // Phone bug 2026-11-13: the keyboard shrank the body until it was wider
  // than tall, the editor flipped to its landscape layout, the text field
  // lost focus and the keyboard closed — text could not be typed at all.
  testWidgets('on-screen keyboard keeps a portrait phone in the portrait layout', (tester) async {
    await pumpEditor(tester, (412.0, 915.0));
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pump();
    await tester.pump();
    // Portrait layout: tools under the preview, starting at the left edge.
    // Landscape layout would put them in a column on the right half.
    expect(tester.getCenter(find.text('Media')).dx, lessThan(412 / 2));
    tester.view.resetViewInsets();
    await unmount(tester);
  });

  for (final size in sizes) {
    final name = '${size.$1.toInt()}x${size.$2.toInt()}';

    testWidgets('editor with the tool dock fits at $name', (tester) async {
      await pumpEditor(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Media'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('editor with each clip panel fits at $name', (tester) async {
      final c = await pumpEditor(tester, size, withClip: true);
      c.read(selectedClipIdProvider.notifier).state = 'c1';
      await tester.pump();
      for (final tab in ['Edit', 'Filters', 'Effects', 'Background']) {
        final finder = find.text(tab);
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$tab tab');
      }
      c.read(selectedClipIdProvider.notifier).state = null;
      await tester.pump();
      await unmount(tester);
    });
  }
}
