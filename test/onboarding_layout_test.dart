import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_app/app/app_theme.dart';
import 'package:video_editor_app/app/onboarding_screen.dart';

/// Regression test for the tutorial's page-5 "bottom overflowed" bug: every
/// page must lay out on a small phone and with large system text. Test
/// fonts (Ahem) are wider than real ones, so this errs on the safe side.
void main() {
  for (final (w, h) in [(320.0, 568.0), (360.0, 640.0), (412.0, 915.0)]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('all tutorial pages fit at ${w.toInt()}x${h.toInt()}, text x$scale', (tester) async {
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var finished = false;
        await tester.pumpWidget(MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: OnboardingScreen(onFinished: () => finished = true),
          ),
        ));
        await tester.pumpAndSettle();
        for (var page = 0; page < 5; page++) {
          expect(tester.takeException(), isNull, reason: 'page ${page + 1}');
          // Scroll each page to its end too: overflow can hide below the fold.
          final list = find.byType(Scrollable);
          if (list.evaluate().length > 1) {
            await tester.drag(list.last, const Offset(0, -2000));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: 'page ${page + 1} scrolled');
          }
          await tester.tap(find.byType(FilledButton));
          await tester.pumpAndSettle();
        }
        expect(finished, isTrue);
      });
    }
  }
}
