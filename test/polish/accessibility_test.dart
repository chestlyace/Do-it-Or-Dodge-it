import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/core/theme/app_theme.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';

import '../data/test_database.dart';
import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

double _luminance(Color c) => c.computeLuminance();

/// WCAG contrast ratio between two colours.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late AppHarness app;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime()..responder = validResponder();
    app = AppHarness(db: db, runtime: runtime, share: FakeShareService());
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  group('colours', () {
    for (final entry in {
      'light': AppTheme.light,
      'dark': AppTheme.dark,
    }.entries) {
      final scheme = entry.value.colorScheme;
      final pairs = {
        'text on the background': (scheme.onSurface, scheme.surface),
        'text on a button': (scheme.onPrimary, scheme.primary),
        'text on a highlighted card': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
        ),
        'text on a secondary card': (
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
        ),
        'error text on the background': (scheme.error, scheme.surface),
        'text on an error card': (
          scheme.onErrorContainer,
          scheme.errorContainer,
        ),
        'quiet text on the background': (
          scheme.onSurfaceVariant,
          scheme.surface,
        ),
      };
      for (final pair in pairs.entries) {
        test('${entry.key} theme: ${pair.key} is easy to read (4.5:1)', () {
          expect(
            contrast(pair.value.$1, pair.value.$2),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });

  group('screen reader', () {
    testWidgets(
      'Do It and Dodge It are labelled buttons that say what they do',
      (tester) async {
        final handle = tester.ensureSemantics();
        await runWithApp(tester, () async {
          await TaskRepository(db)
              .create(title: 'Pay rent', category: TaskCategory.money);
          await app.start(tester);
          await app.tapText(tester, 'Pay rent');

          for (final entry in {
            'Do It': 'Break "Pay rent" into tiny steps',
            'Dodge It': 'Get an excuse for "Pay rent"',
          }.entries) {
            final node = tester.getSemantics(find.bySemanticsLabel(entry.key));
            final data = node.getSemanticsData();
            expect(data.label, entry.key);
            expect(data.hint, contains(entry.value));
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
          }
        });
        handle.dispose();
      },
    );

    testWidgets('the buttons can be activated through accessibility', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await TaskRepository(db)
            .create(title: 'Pay rent', category: TaskCategory.money);
        await app.start(tester);
        await app.tapText(tester, 'Pay rent');

        tester.semantics.tap(find.semantics.byLabel('Dodge It'));
        await settle(tester);

        expect(Get.currentRoute, Routes.dodgeIt);
      });
      handle.dispose();
    });

    testWidgets('icon buttons have names', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await app.start(tester);

        for (final name in ['History', 'Settings']) {
          final data = tester
              .getSemantics(find.byTooltip(name))
              .getSemanticsData();
          expect(data.tooltip, name);
          expect(data.flagsCollection.isButton, isTrue);
        }
        expect(find.bySemanticsLabel('Add task'), findsWidgets);
      });
      handle.dispose();
    });

    testWidgets('settings has headings and the slider says its value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.settings);
        await settle(tester);

        expect(find.semantics.byValue('6 nudges a day'), findsOneWidget);
        final heading = tester.getSemantics(find.text('Nudges'));
        expect(heading.getSemanticsData().flagsCollection.isHeader, isTrue);
      });
      handle.dispose();
    });
  });

  group('large text on a small phone', () {
    void bigText(WidgetTester tester) {
      tester.view.physicalSize = const Size(720, 1280); // 360 x 640 at 2x
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearAllTestValues();
      });
    }

    Future<void> seed() async {
      final repo = TaskRepository(db);
      final doing = await repo.create(
        title: 'A fairly long task title that has to wrap onto several lines',
        category: TaskCategory.other,
        customCategory: 'Something rather long to describe',
        note:
            'A note that is also quite long so it wraps around the screen too.',
        dueAt: DateTime.now().add(const Duration(days: 3)),
      );
      await repo.updateStatus(doing.id, TaskStatus.doing);
      final open = await repo.create(
        title: 'Open one',
        category: TaskCategory.work,
      );
      final done = await repo.create(
        title: 'Finished task',
        category: TaskCategory.chores,
      );
      await repo.updateStatus(done.id, TaskStatus.done);
      await OutcomeRepository(db)
          .record(taskId: done.id, result: OutcomeResult.done);
      final dodged = await repo.create(
        title: 'Dodged task',
        category: TaskCategory.admin,
      );
      await repo.updateStatus(dodged.id, TaskStatus.dodged);
      await OutcomeRepository(db)
          .record(taskId: dodged.id, result: OutcomeResult.dodged);
      expect(open.id, isNonZero);
    }

    testWidgets('Home', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await seed();
        await app.start(tester);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Home when empty', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await app.start(tester);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('the add task sheet', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await app.start(tester);
        await tester.tap(find.text('Add task'));
        await settle(tester);
        final save = find.widgetWithText(FilledButton, 'Add task');
        await tester.ensureVisible(save);
        await tester.pump();
        await tester.tap(save);
        await settle(tester);
        expect(find.text('Give the task a title'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Task detail', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await seed();
        await app.start(tester);
        await app.tapText(
          tester,
          'A fairly long task title that has to wrap onto several lines',
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Dodge It'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Do It with steps and the help sheet', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Do It');
        expect(tester.takeException(), isNull);

        await app.tapText(tester, 'Help me');
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Dodge It: form, excuse and logged', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Dodge It');
        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField), 'my landlord');
        await app.tapText(tester, 'Write my excuse');
        expect(tester.takeException(), isNull);

        await app.tapText(tester, 'Copy');
        expect(tester.takeException(), isNull);
        expect(find.text('Logged as dodged.'), findsOneWidget);
      });
    });

    testWidgets('History', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await seed();
        await app.start(tester);
        await tester.tap(find.byTooltip('History'));
        await settle(tester);
        expect(find.text('Abandoned'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Settings, top to bottom', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.settings);
        await settle(tester);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Clear tasks and history'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('Onboarding', (tester) async {
      bigText(tester);
      await runWithApp(tester, () async {
        runtime.files.clear();
        await app.start(tester);
        // start() installs the model fixture; remove it again to see onboarding.
        Get.offAllNamed(Routes.onboarding);
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('guidelines', () {
    Future<void> check(WidgetTester tester) async {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    }

    testWidgets('Home', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await TaskRepository(db)
            .create(title: 'Pay rent', category: TaskCategory.money);
        await app.start(tester);
        await check(tester);
      });
      handle.dispose();
    });

    testWidgets('Task detail', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await TaskRepository(db)
            .create(title: 'Pay rent', category: TaskCategory.money);
        await app.start(tester);
        await app.tapText(tester, 'Pay rent');
        await check(tester);
      });
      handle.dispose();
    });

    testWidgets('Do It', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Do It');
        await check(tester);
      });
      handle.dispose();
    });

    testWidgets('Dodge It', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Dodge It');
        await tester.enterText(find.byType(TextField), 'boss');
        await app.tapText(tester, 'Write my excuse');
        await check(tester);
      });
      handle.dispose();
    });

    testWidgets('Settings', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.settings);
        await settle(tester);
        await check(tester);
      });
      handle.dispose();
    });

    testWidgets('History', (tester) async {
      final handle = tester.ensureSemantics();
      await runWithApp(tester, () async {
        final repo = TaskRepository(db);
        final t = await repo.create(
          title: 'Done one',
          category: TaskCategory.work,
        );
        await repo.updateStatus(t.id, TaskStatus.done);
        await OutcomeRepository(db)
            .record(taskId: t.id, result: OutcomeResult.done);
        await app.start(tester);
        await tester.tap(find.byTooltip('History'));
        await settle(tester);
        await check(tester);
      });
      handle.dispose();
    });
  });
}
