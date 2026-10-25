import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';

import '../data/test_database.dart';
import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late FakeNotificationGateway gateway;
  late FakeBackgroundScheduler scheduler;
  late AppHarness app;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime()..responder = scripted([validShrink]);
    gateway = FakeNotificationGateway();
    scheduler = FakeBackgroundScheduler();
    app = AppHarness(
      db: db,
      runtime: runtime,
      share: FakeShareService(),
      notifications: gateway,
      scheduler: scheduler,
    );
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> startDoIt(WidgetTester tester, String title) async {
    await app.addTask(tester, title);
    await app.tapText(tester, title);
    await app.tapText(tester, 'Do It');
  }

  Future<void> backHome(WidgetTester tester) async {
    Get.until((r) => r.settings.name == Routes.home);
    await settle(tester);
  }

  Future<Task> onlyTask() async => (await TaskRepository(db).listAll()).single;

  testWidgets('starting Do It schedules nudges about the first step', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');

      expect(gateway.scheduled, isNotEmpty);
      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Open the website'));
        expect(n.body, isNot(contains('Find the form')));
      }
      final rows = await NudgeRepository(db).listForTask((await onlyTask()).id);
      expect(
        rows.map((r) => r.notificationId).toSet(),
        gateway.scheduled.keys.toSet(),
      );
    });
  });

  testWidgets('the schedule is visible in the debug list', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');

      Get.toNamed(Routes.nudgeDebug);
      await settle(tester);

      expect(find.text('Nudges'), findsOneWidget);
      expect(
        find.textContaining(
          '${gateway.scheduled.length} scheduled with Android',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Open the website'), findsWidgets);
      expect(find.textContaining('Pay rent'), findsWidgets);
      expect(find.textContaining('pending'), findsWidgets);
    });
  });

  testWidgets('the permission is asked for on the first Do It only', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      gateway
        ..enabled = false
        ..grantOnRequest = true;
      await app.start(tester);

      await startDoIt(tester, 'Pay rent');
      expect(gateway.permissionRequests, 1);
      expect(gateway.scheduled, isNotEmpty);

      await backHome(tester);
      await startDoIt(tester, 'Second task');
      expect(gateway.permissionRequests, 1);
    });
  });

  testWidgets('without the permission Do It still works and says why', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      gateway
        ..enabled = false
        ..grantOnRequest = false;
      await app.start(tester);

      await startDoIt(tester, 'Pay rent');

      expect(find.text('Open the website'), findsOneWidget);
      expect(find.text('Nudges are off'), findsOneWidget);
      expect(gateway.scheduled, isEmpty);
      expect(await NudgeRepository(db).listAll(), isEmpty);
    });
  });

  testWidgets('ticking a step replaces the nudges with the next step', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      final oldIds = gateway.scheduled.keys.toSet();

      await tester.tap(find.byType(Checkbox).first);
      await settle(tester);

      expect(gateway.scheduled.keys.toSet().intersection(oldIds), isEmpty);
      expect(gateway.cancelled.toSet().containsAll(oldIds), isTrue);
      expect(gateway.scheduled, isNotEmpty);
      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Find the form'));
      }

      // Unticking brings the first step back.
      await tester.tap(find.byType(Checkbox).first);
      await settle(tester);
      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Open the website'));
      }
    });
  });

  testWidgets('finishing the last step cancels every nudge', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      expect(gateway.scheduled, isNotEmpty);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(Checkbox).at(i));
        await settle(tester);
      }

      expect((await onlyTask()).status, TaskStatus.done);
      expect(gateway.scheduled, isEmpty);
      expect(await NudgeRepository(db).listPending(), isEmpty);
    });
  });

  testWidgets('deleting a task cancels its nudges', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      await backHome(tester);
      expect(gateway.scheduled, isNotEmpty);

      await app.longPress(tester, find.text('Pay rent'));
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(gateway.scheduled, isEmpty);
      expect(await TaskRepository(db).listAll(), isEmpty);
    });
  });

  testWidgets('dodging a task being worked on cancels its nudges', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.responder = validResponder();
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      await backHome(tester);
      expect(gateway.scheduled, isNotEmpty);

      await app.tapText(tester, 'Pay rent');
      await app.tapText(tester, 'Dodge It');
      await tester.enterText(find.byType(TextField), 'boss');
      await app.tapText(tester, 'Write my excuse');
      await app.tapText(tester, 'Copy');

      expect((await onlyTask()).status, TaskStatus.dodged);
      expect(gateway.scheduled, isEmpty);
    });
  });

  testWidgets('tapping a nudge opens that task and records it', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      await backHome(tester);
      final row = (await NudgeRepository(db).listPending()).first;
      expect(Get.currentRoute, Routes.home);

      gateway.onTap!('${row.id}:${row.taskId}');
      await settle(tester);

      expect(Get.currentRoute, Routes.doIt);
      expect(find.text('Open the website'), findsOneWidget);
      expect((await NudgeRepository(db).getById(row.id))!.opened, isTrue);
    });
  });

  testWidgets('a nudge that launched the app opens its task from Home', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      // First run: create a task with steps and nudges.
      await app.start(tester);
      await startDoIt(tester, 'Pay rent');
      final row = (await NudgeRepository(db).listPending()).first;
      await tester.pumpWidget(const SizedBox.shrink());
      Get.reset();

      // The app starts again because the user tapped that nudge.
      gateway.launch = '${row.id}:${row.taskId}';
      await tester.pumpWidget(app.build());
      await settle(tester, rounds: 8);

      expect(Get.currentRoute, Routes.doIt);
    });
  });

  group('debug screen', () {
    testWidgets('the fast clock switch is remembered', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.nudgeDebug);
        await settle(tester);

        await tester.tap(find.byType(Switch));
        await settle(tester);

        expect(
          await SettingsRepository(db).get(SettingsKeys.nudgeFastClock),
          'true',
        );
      });
    });

    testWidgets('with the fast clock, nudges come minutes apart', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await SettingsRepository(db).set(SettingsKeys.nudgeFastClock, 'true');
        await app.start(tester);
        await startDoIt(tester, 'Pay rent');

        final times = gateway.inOrder.map((n) => n.at).toList();
        expect(times, hasLength(3));
        expect(times[1].difference(times[0]), const Duration(minutes: 1));
        expect(times[2].difference(times[1]), const Duration(minutes: 1));
      });
    });

    testWidgets('runs the daily job on demand', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.nudgeDebug);
        await settle(tester);

        await app.tapText(tester, 'Run daily job now');

        expect(
          find.textContaining('Daily job: fired 0, abandoned 0, planned 0'),
          findsOneWidget,
        );
      });
    });

    testWidgets('sends a test notification', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.nudgeDebug);
        await settle(tester);

        await app.tapText(tester, 'Test notification');

        expect(gateway.scheduled.containsKey(2147483000), isTrue);
        expect(find.textContaining('arrives in 10 seconds'), findsOneWidget);
      });
    });

    testWidgets('the benchmark screen links to it', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        Get.toNamed(Routes.benchmark);
        await settle(tester);

        await tester.tap(find.byTooltip('Nudges'));
        await settle(tester);

        expect(Get.currentRoute, Routes.nudgeDebug);
      });
    });
  });

  group('daily job registration', () {
    testWidgets('is scheduled once when the app starts', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        expect(scheduler.registerCalls, 1);
      });
    });

    testWidgets('a failure to schedule never stops the app', (tester) async {
      await runWithApp(tester, () async {
        scheduler.error = StateError('no work manager');
        await app.start(tester);

        expect(scheduler.registerCalls, 1);
        expect(find.textContaining('No tasks yet'), findsOneWidget);
      });
    });
  });
}
