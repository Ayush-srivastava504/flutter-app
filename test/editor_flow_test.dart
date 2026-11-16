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
import 'package:video_editor_app/models/video_template.dart';
import 'package:video_editor_app/screens/editor_screen.dart';
import 'package:video_editor_app/widgets/editor/tool_dock.dart';
import 'package:video_editor_app/widgets/templates_section.dart';

/// Launch checks for the video editor: adding more clips, getting back from
/// a clip panel to the tools, and every tool's sheet opening without an
/// overflow or crash — on a small phone, upright and rotated.
void main() {
  const sizes = [(360.0, 640.0), (640.0, 360.0)];

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpEditor(WidgetTester tester, (double, double) size, {int clips = 0}) async {
    tester.view.physicalSize = Size(size.$1, size.$2);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = ProjectDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final dir = Directory.systemTemp.createTempSync('flow_prefs');
    final prefs = AppPrefs(directory: () async => dir);
    await tester.runAsync(() async {
      for (final m in ['youtube', 'insta', 'normal']) {
        await prefs.markModeTipsSeen(m);
      }
      final now = DateTime.now();
      await db.insertProject(ProjectsCompanion.insert(
          id: 'p1', name: 'Flow test', mode: const Value('youtube'), aspectRatio: const Value(16 / 9),
          createdAt: now, updatedAt: now));
      for (var i = 0; i < clips; i++) {
        await db.appendClip(id: 'c$i', projectId: 'p1', sourceUri: '/missing/photo$i.jpg', durationMs: 3000);
      }
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        projectDatabaseProvider.overrideWithValue(db),
        appPrefsProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const EditorScreen(projectId: 'p1')),
    ));
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Taps a tool-bar button, scrolling the dock to it first.
  Future<void> tapTool(WidgetTester tester, String label) async {
    final item = find.descendant(of: find.byType(ToolDock), matching: find.text(label));
    // The dock is a lazily built horizontal list: go back to its start, then
    // swipe along until the button exists, like a thumb would.
    await tester.drag(find.byType(ToolDock), const Offset(3000, 0));
    await tester.pump();
    for (var i = 0; i < 20 && item.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ToolDock), const Offset(-120, 0));
      await tester.pump();
    }
    await tester.ensureVisible(item);
    await tester.pump();
    await tester.tap(item);
    await settle(tester);
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4)); // the modal barrier
    await settle(tester);
  }

  for (final size in sizes) {
    final name = '${size.$1.toInt()}x${size.$2.toInt()}';

    testWidgets('empty timeline offers "Add videos or photos" ($name)', (tester) async {
      await pumpEditor(tester, size);
      expect(find.text('Add videos or photos'), findsOneWidget);
      await tester.tap(find.text('Add videos or photos'));
      await settle(tester);
      expect(find.text('Videos & photos'), findsOneWidget, reason: 'import sheet with multi-pick');
      expect(tester.takeException(), isNull);
      await closeSheet(tester);
      await finish(tester);
    });

    testWidgets('with clips: "+" adds more, Done and tap-again return to the tools ($name)', (tester) async {
      await pumpEditor(tester, size, clips: 2);
      // The "+" tile at the end of the timeline.
      expect(find.byTooltip('Add videos or photos'), findsOneWidget);
      await tester.tap(find.byTooltip('Add videos or photos'));
      await settle(tester);
      expect(find.text('Videos & photos'), findsOneWidget);
      await closeSheet(tester);

      // Select a clip: its panel replaces the tools…
      final tile = find.byWidgetPredicate((w) => w is ReorderableDragStartListener && w.key == const ValueKey('c0'));
      await tester.tap(tile);
      await settle(tester);
      expect(find.byTooltip('Done'), findsOneWidget);
      expect(find.byType(ToolDock), findsNothing);
      // …and the "+" is still there to add more.
      expect(find.byTooltip('Add videos or photos'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Done brings the tools back.
      await tester.tap(find.byTooltip('Done'));
      await settle(tester);
      expect(find.byType(ToolDock), findsOneWidget);

      // Tapping the selected clip again also closes its panel.
      await tester.tap(tile);
      await settle(tester);
      expect(find.byType(ToolDock), findsNothing);
      await tester.tap(tile);
      await settle(tester);
      expect(find.byType(ToolDock), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('every tool sheet opens without overflow ($name)', (tester) async {
      await pumpEditor(tester, size, clips: 2);
      for (final tool in ['Media', 'Music', 'AutoCut', 'SFX', 'Tips', 'Assistant', 'Speech', 'Jump cuts', 'Chapters']) {
        await tapTool(tester, tool);
        expect(tester.takeException(), isNull, reason: '$tool sheet');
        await closeSheet(tester);
        expect(tester.takeException(), isNull, reason: 'closing $tool');
      }
      // The non-modal voice recorder, then the two toggles (Ducking shows a
      // message over the dock, so it goes last).
      await tapTool(tester, 'Voice');
      expect(find.text('Tap to record'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'voice recorder');
      await tester.tap(find.byIcon(Icons.close).last);
      await settle(tester);
      expect(find.text('Tap to record'), findsNothing, reason: 'recorder closes');
      for (final tool in ['Safe zones', 'Ducking']) {
        await tapTool(tester, tool);
        expect(tester.takeException(), isNull, reason: tool);
      }
      await finish(tester);
    });

    testWidgets('transition picker fits ($name)', (tester) async {
      await pumpEditor(tester, size, clips: 2);
      await tester.tap(find.byTooltip('Transition').first);
      await settle(tester);
      expect(find.text('Flash'), findsOneWidget);
      // Every option is reachable: scroll to the last one.
      await tester.scrollUntilVisible(find.text('Spin'), 120,
          scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first);
      expect(find.text('Spin'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await closeSheet(tester);
      await finish(tester);
    });

    testWidgets('every template details sheet fits ($name)', (tester) async {
      tester.view.physicalSize = Size(size.$1, size.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ListView(key: const ValueKey('outer'), children: [DiscoverSection(onUse: (_) {})])),
      ));
      expect(tester.takeException(), isNull);
      for (final t in videoTemplates) {
        final tab = t.discoverCategory!.tab;
        await tester.ensureVisible(find.text(tab.label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(tab.label));
        await tester.pumpAndSettle();
        final rowKey = find.byKey(ValueKey('discover-row-${t.category}'));
        await tester.scrollUntilVisible(rowKey, 120,
            scrollable: find.descendant(of: find.byKey(const ValueKey('outer')), matching: find.byType(Scrollable)).first);
        final card = find.widgetWithText(DiscoverCard, t.name);
        await tester.scrollUntilVisible(card, 120,
            scrollable: find.descendant(of: rowKey, matching: find.byType(Scrollable)));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${t.id} card');
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text('Pick ${t.suggestedClips} clips'), findsOneWidget, reason: t.id);
        expect(tester.takeException(), isNull, reason: t.id);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();
      }
    });
  }
}
