import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/core/utils/nudge_planner.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/modules/settings/controllers/settings_controller.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';

import '../data/test_database.dart';
import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late FakeNotificationGateway gateway;
  late AppHarness app;
  late SettingsRepository settings;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime()..responder = scripted([validShrink]);
    gateway = FakeNotificationGateway();
    settings = SettingsRepository(db);
    app = AppHarness(
      db: db,
      runtime: runtime,
      share: FakeShareService(),
      notifications: gateway,
    );
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<SettingsController> openSettings(WidgetTester tester) async {
    await app.start(tester);
    Get.toNamed(Routes.settings);
    await settle(tester);
    return Get.find<SettingsController>();
  }

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);
  }

  testWidgets('shows the defaults', (tester) async {
    await runWithApp(tester, () async {
      await openSettings(tester);

      expect(find.text('Quiet hours start'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('At most 6 nudges a day for a task'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });
  });

  testWidgets('shows what it has stored', (tester) async {
    await runWithApp(tester, () async {
      await settings.set(SettingsKeys.quietHoursStart, '22:30');
      await settings.set(SettingsKeys.quietHoursEnd, '07:15');
      await settings.set(SettingsKeys.maxNudgesPerDay, '3');
      await settings.set(SettingsKeys.wifiOnly, 'false');
      await openSettings(tester);

      expect(find.text('22:30'), findsOneWidget);
      expect(find.text('07:15'), findsOneWidget);
      expect(find.text('At most 3 nudges a day for a task'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });

  testWidgets('quiet hours open a time picker and are saved', (tester) async {
    await runWithApp(tester, () async {
      await openSettings(tester);

      await tester.tap(find.text('Quiet hours start'));
      await settle(tester);
      expect(find.text('Select time'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(await settings.get(SettingsKeys.quietHoursStart), '21:00');
    });
  });

  testWidgets('the Wi-Fi only switch is saved', (tester) async {
    await runWithApp(tester, () async {
      await openSettings(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);

      expect(await settings.get(SettingsKeys.wifiOnly), 'false');
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    });
  });

  testWidgets('the nudge limit slider is saved', (tester) async {
    await runWithApp(tester, () async {
      await openSettings(tester);

      await tester.drag(find.byType(Slider), const Offset(-800, 0));
      await settle(tester);

      expect(await settings.get(SettingsKeys.maxNudgesPerDay), '1');
      expect(find.text('At most 1 nudges a day for a task'), findsOneWidget);
    });
  });

  group('changes apply without restarting', () {
    Future<Task> startedTask(WidgetTester tester) async {
      await app.addTask(tester, 'Pay rent');
      await app.tapText(tester, 'Pay rent');
      await app.tapText(tester, 'Do It');
      Get.until((r) => r.settings.name == Routes.home);
      await settle(tester);
      return (await TaskRepository(db).listAll()).single;
    }

    testWidgets('new quiet hours re-plan the pending nudges now', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        await startedTask(tester);
        final before = gateway.scheduled.keys.toSet();
        expect(before, isNotEmpty);
        Get.toNamed(Routes.settings);
        await settle(tester);
        final controller = Get.find<SettingsController>();

        // Quiet from 00:00 to 23:00 leaves only the last hour of the day.
        await controller.setQuietStart(0);
        await controller.setQuietEnd(23 * 60);
        await settle(tester);

        expect(gateway.scheduled.keys.toSet().intersection(before), isEmpty);
        const quiet = QuietHours(startMinutes: 0, endMinutes: 23 * 60);
        for (final n in gateway.scheduled.values) {
          expect(quiet.contains(n.at), isFalse, reason: '${n.at}');
        }
        expect(await settings.get(SettingsKeys.quietHoursStart), '00:00');
        expect(await settings.get(SettingsKeys.quietHoursEnd), '23:00');
        expect(find.text('23:00'), findsOneWidget);
      });
    });

    testWidgets('a lower daily limit re-plans the pending nudges now', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        final task = await startedTask(tester);
        Get.toNamed(Routes.settings);
        await settle(tester);

        await Get.find<SettingsController>().setMaxNudgesPerDay(1);
        await settle(tester);

        final rows = await NudgeRepository(db).listPendingForTask(task.id);
        final perDay = <String, int>{};
        for (final n in rows) {
          final key = '${n.fireAt.month}-${n.fireAt.day}';
          perDay[key] = (perDay[key] ?? 0) + 1;
        }
        expect(perDay.values.every((c) => c <= 1), isTrue);
        expect(rows.length, lessThanOrEqualTo(2));
        expect(find.textContaining(RegExp(r'Saved\.')), findsOneWidget);
      });
    });
  });

  group('model', () {
    testWidgets('shows what is installed', (tester) async {
      await runWithApp(tester, () async {
        await openSettings(tester);
        await scrollTo(tester, 'Gemma 4 E2B');

        expect(find.text('Gemma 4 E2B'), findsOneWidget);
        expect(find.text('gemma-4-E2B-it@1caa527'), findsOneWidget);
        expect(find.text('2.6 GB'), findsOneWidget);
        expect(find.text('Not loaded right now'), findsOneWidget);
      });
    });

    testWidgets('shows what it runs on once loaded', (tester) async {
      await runWithApp(tester, () async {
        await openSettings(tester);
        await Get.find<SettingsController>().gemma.load();
        await settle(tester);
        await scrollTo(tester, 'Running on');

        expect(find.text('GPU'), findsOneWidget);
      });
    });

    testWidgets('deleting asks first, then returns to the download screen', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await openSettings(tester);
        await scrollTo(tester, 'Delete model');

        await tester.tap(find.text('Delete model'));
        await settle(tester);
        expect(find.text('Delete the model?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(runtime.uninstalled, isEmpty);

        await tester.tap(find.text('Delete model'));
        await settle(tester);
        await tester.tap(find.text('Delete'));
        await settle(tester);

        expect(runtime.uninstalled, ['gemma-4-E2B-it.litertlm']);
        expect(await settings.get(SettingsKeys.modelId), isNull);
        expect(Get.currentRoute, Routes.onboarding);
        expect(find.text('Download the on-device model'), findsOneWidget);
      });
    });

    testWidgets('your tasks are kept when the model is deleted', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await TaskRepository(db)
            .create(title: 'Keep me', category: TaskCategory.work);
        await openSettings(tester);
        await scrollTo(tester, 'Delete model');
        await tester.tap(find.text('Delete model'));
        await settle(tester);
        await tester.tap(find.text('Delete'));
        await settle(tester);

        expect(await TaskRepository(db).listAll(), hasLength(1));
      });
    });
  });

  group('clearing data', () {
    testWidgets('asks first, then removes tasks and history', (tester) async {
      await runWithApp(tester, () async {
        final repo = TaskRepository(db);
        final t = await repo.create(title: 'Old', category: TaskCategory.work);
        await StepRepository(db)
            .createAll(t.id, const [NewStep(title: 'a', estMinutes: 1)]);
        await OutcomeRepository(db)
            .record(taskId: t.id, result: OutcomeResult.dodged);
        await settings.set(SettingsKeys.predictorWeights, '{}');
        await settings.set(SettingsKeys.quietHoursStart, '22:00');
        await openSettings(tester);
        await scrollTo(tester, 'Clear tasks and history');

        await tester.tap(find.text('Clear tasks and history'));
        await settle(tester);
        expect(find.text('Clear all data?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await settle(tester);
        expect(await repo.listAll(), hasLength(1));

        await tester.tap(find.text('Clear tasks and history'));
        await settle(tester);
        await tester.tap(find.text('Clear'));
        await settle(tester);

        expect(await repo.listAll(), isEmpty);
        expect(await OutcomeRepository(db).listAll(), isEmpty);
        expect(await settings.get(SettingsKeys.predictorWeights), isNull);
        // The model and the preferences stay.
        expect(await settings.get(SettingsKeys.modelId), isNotNull);
        expect(await settings.get(SettingsKeys.quietHoursStart), '22:00');
        expect(
          find.text('Your tasks and history were cleared.'),
          findsOneWidget,
        );
      });
    });

    testWidgets('cancels the nudges that were scheduled', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Do It');
        expect(gateway.scheduled, isNotEmpty);
        Get.toNamed(Routes.settings);
        await settle(tester);
        await scrollTo(tester, 'Clear tasks and history');

        await tester.tap(find.text('Clear tasks and history'));
        await settle(tester);
        await tester.tap(find.text('Clear'));
        await settle(tester);

        expect(gateway.scheduled, isEmpty);
        expect(await NudgeRepository(db).listAll(), isEmpty);
      });
    });
  });

  group('about', () {
    testWidgets('says where the model comes from and its licence', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await openSettings(tester);
        await scrollTo(tester, 'Open source licences');

        expect(
          find.textContaining('Everything runs on your phone'),
          findsOneWidget,
        );
        expect(find.textContaining('Apache 2.0'), findsOneWidget);
      });
    });

    testWidgets('opens the open source licences page', (tester) async {
      await runWithApp(tester, () async {
        await openSettings(tester);
        await scrollTo(tester, 'Open source licences');

        await tester.tap(find.text('Open source licences'));
        await settle(tester);

        expect(find.byType(LicensePage), findsOneWidget);
        expect(find.text('Do It or Dodge It'), findsWidgets);
        expect(find.textContaining('MIT licence'), findsOneWidget);
      });
    });
  });
}
