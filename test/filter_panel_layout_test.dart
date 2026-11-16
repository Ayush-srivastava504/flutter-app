import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/data/database_provider.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/widgets/timeline/background_panel.dart';
import 'package:video_editor_app/widgets/timeline/effects_panel.dart';
import 'package:video_editor_app/widgets/timeline/filter_panel.dart';
import 'package:video_editor_app/widgets/timeline/trim_panel.dart';

import 'support/fixtures.dart';

/// The filter panel must lay out without overflow on a small phone, inside
/// the editor's height-capped, scrollable bottom area.
void main() {
  final panels = <String, Widget Function()>{
    'filter': () => FilterPanel(clip: clipRow(look: 'anime')),
    'effects': () => EffectsPanel(clip: clipRow(effect: 'fx_glitch')),
    'effects (none)': () => EffectsPanel(clip: clipRow()),
    'background (off)': () => BackgroundPanel(clip: clipRow()),
    'background (on)': () => BackgroundPanel(clip: clipRow(keyJson: '{"c":45376,"s":0.08,"b":0.06}')),
    'trim (video)': () => TrimPanel(clip: clipRow(trimEndMs: 8000), allClips: [clipRow(trimEndMs: 8000)]),
    'trim (photo)': () => TrimPanel(
          clip: clipRow(sourceUri: '/p.jpg', trimEndMs: 3000),
          allClips: [clipRow(sourceUri: '/p.jpg', trimEndMs: 3000)],
        ),
  };
  for (final MapEntry(key: name, value: panel) in panels.entries)
  for (final (w, h) in [(320.0, 568.0), (360.0, 640.0), (412.0, 915.0)]) {
    testWidgets('$name panel fits at ${w.toInt()}x${h.toInt()}', (tester) async {
      tester.view.physicalSize = Size(w, h);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final db = ProjectDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(ProviderScope(
        overrides: [projectDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: SizedBox()),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: h * 0.4),
                  child: SingleChildScrollView(child: panel()),
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
