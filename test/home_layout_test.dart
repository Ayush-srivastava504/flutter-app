import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/app/app_prefs.dart';
import 'package:video_editor_app/app/app_theme.dart';
import 'package:video_editor_app/app/launch_gate.dart';
import 'package:video_editor_app/data/database_provider.dart';
import 'package:video_editor_app/data/project_database.dart';
import 'package:video_editor_app/screens/home_screen.dart';

/// Home (mode cards, template cards, project grid) must lay out without
/// overflow on a small phone and with large system text.
void main() {
  for (final (w, h) in [(320.0, 568.0), (412.0, 915.0)]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('home fits at ${w.toInt()}x${h.toInt()}, text x$scale', (tester) async {
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final db = ProjectDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final dir = Directory.systemTemp.createTempSync('home_prefs');
        await tester.pumpWidget(ProviderScope(
          overrides: [
            projectDatabaseProvider.overrideWithValue(db),
            appPrefsProvider.overrideWithValue(AppPrefs(directory: () async => dir)),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: scale,
              maxScaleFactor: scale,
              child: const HomeScreen(),
            ),
          ),
        ));
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
        expect(find.text('Discover', skipOffstage: false), findsOneWidget);
        // Scroll through the whole page, checking each step.
        for (var i = 0; i < 6; i++) {
          await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: 'scroll step $i');
        }
        // And sideways through the template cards.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 2400));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1)); // drift's stream-close timer
      });
    }
  }
}
