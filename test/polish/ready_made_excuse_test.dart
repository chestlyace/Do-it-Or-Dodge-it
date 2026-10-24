import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/prompt_jobs.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/excuse_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';
import 'package:do_it_or_dodge_it/app/services/pregenerated_excuses.dart';

import '../data/test_database.dart';
import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late FakeShareService share;
  late FakeNotificationGateway gateway;
  late FakeBackgroundScheduler scheduler;
  late AppHarness app;
  late PregeneratedExcuses ready;

  const readyText = 'Something came up with my schedule, sorry.';

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime()..responder = validResponder();
    share = FakeShareService();
    gateway = FakeNotificationGateway();
    scheduler = FakeBackgroundScheduler();
    ready = PregeneratedExcuses(SettingsRepository(db));
    app = AppHarness(
      db: db,
      runtime: runtime,
      share: share,
      notifications: gateway,
      scheduler: scheduler,
    );
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<Task> taskWithReadyExcuse() async {
    final task = await TaskRepository(db)
        .create(title: 'Pay rent', category: TaskCategory.money);
    await ready.write(
      task.id,
      const ExcuseDraft(text: readyText, shortVariant: 'Schedule clash.'),
    );
    return task;
  }

  Future<void> openDodge(WidgetTester tester) async {
    await app.tapText(tester, 'Pay rent');
    await app.tapText(tester, 'Dodge It');
  }

  testWidgets(
    'shows the ready-made excuse instantly, without asking the model',
    (tester) async {
      await runWithApp(tester, () async {
        await taskWithReadyExcuse();
        await app.start(tester);

        await openDodge(tester);

        expect(find.text(readyText), findsOneWidget);
        expect(
          find.textContaining('A ready-made excuse in a Polite tone'),
          findsOneWidget,
        );
        expect(find.text('Regenerate'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);
        expect(runtime.calls, isEmpty, reason: 'nothing was generated');
      });
    },
  );

  testWidgets('without one, Dodge It starts at the form as before', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await TaskRepository(db)
          .create(title: 'Pay rent', category: TaskCategory.money);
      await app.start(tester);

      await openDodge(tester);

      expect(find.text('Write my excuse'), findsOneWidget);
      expect(find.textContaining('ready-made'), findsNothing);
    });
  });

  testWidgets('add who it is for, copy it, and the dodge is logged', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      final task = await taskWithReadyExcuse();
      await app.start(tester);
      await openDodge(tester);

      await tester.enterText(find.byType(TextField), 'landlord');
      await app.tapText(tester, 'Copy');

      expect(share.copied, [readyText]);
      expect(find.text('Logged as dodged.'), findsOneWidget);
      expect(
        (await TaskRepository(db).getById(task.id))!.status,
        TaskStatus.dodged,
      );
      final excuse = (await ExcuseRepository(db).listForTask(task.id)).single;
      expect(excuse.recipientLabel, 'landlord');
      expect(excuse.body, readyText);
      expect(await ready.has(task.id), isFalse, reason: 'it was used up');
      expect(runtime.calls, isEmpty);
    });
  });

  testWidgets('it needs a name before it can be copied or shared', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      final task = await taskWithReadyExcuse();
      await app.start(tester);
      await openDodge(tester);

      await app.tapText(tester, 'Copy');
      expect(find.text('Say who the excuse is for'), findsOneWidget);
      await app.tapText(tester, 'Share');

      expect(share.copied, isEmpty);
      expect(share.shared, isEmpty);
      expect(await OutcomeRepository(db).listAll(), isEmpty);
      expect(await ready.has(task.id), isTrue);
    });
  });

  testWidgets('it will not reuse an excuse already used for that person', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      final task = await taskWithReadyExcuse();
      final earlier = await TaskRepository(db)
          .create(title: 'Earlier', category: TaskCategory.money);
      await ExcuseRepository(db).create(
        taskId: earlier.id,
        recipientLabel: 'landlord',
        tone: 'Polite',
        text: 'something came up with my SCHEDULE sorry',
      );
      await app.start(tester);
      await openDodge(tester);

      await tester.enterText(find.byType(TextField), 'landlord');
      await app.tapText(tester, 'Copy');

      expect(
        find.textContaining('You already used this one for landlord'),
        findsOneWidget,
      );
      expect(share.copied, isEmpty);
      expect(
        (await TaskRepository(db).getById(task.id))!.status,
        TaskStatus.open,
      );
    });
  });

  testWidgets(
    'regenerating writes a tailored one and drops the ready-made one',
    (tester) async {
      await runWithApp(tester, () async {
        final task = await taskWithReadyExcuse();
        await app.start(tester);
        await openDodge(tester);

        await tester.enterText(find.byType(TextField), 'landlord');
        await app.tapText(tester, 'Regenerate');

        expect(find.text(readyText), findsNothing);
        expect(
          find.text('My week got away from me, number 1.'),
          findsOneWidget,
        );
        expect(find.textContaining('ready-made'), findsNothing);
        expect(runtime.calls.last.prompt, contains('This is for: landlord'));
        expect(await ready.has(task.id), isFalse);
      });
    },
  );

  testWidgets('a closed task never shows one', (tester) async {
    await runWithApp(tester, () async {
      final task = await taskWithReadyExcuse();
      await TaskRepository(db).updateStatus(task.id, TaskStatus.dodged);
      await app.start(tester);

      Get.toNamed(Routes.dodgeIt, arguments: task.id);
      await settle(tester);

      expect(find.text(readyText), findsNothing);
      expect(find.text('This task is already dodged.'), findsOneWidget);
    });
  });

  group('background jobs', () {
    testWidgets('both are scheduled when the app starts', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);

        expect(scheduler.registerCalls, 1);
        expect(scheduler.pregenerationCalls, 1);
      });
    });

    testWidgets('one failing does not stop the other or the app', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        scheduler.error = StateError('no daily job');
        await app.start(tester);
        expect(scheduler.pregenerationCalls, 1);
        expect(find.textContaining('No tasks yet'), findsOneWidget);
      });
    });

    testWidgets('the pre-generation failing leaves the daily job alone', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        scheduler.pregenerationError = StateError('no charging job');
        await app.start(tester);
        expect(scheduler.registerCalls, 1);
        expect(find.textContaining('No tasks yet'), findsOneWidget);
      });
    });

    testWidgets('the debug screen can pre-generate on demand', (tester) async {
      await runWithApp(tester, () async {
        final repo = TaskRepository(db);
        final t = await repo.create(
          title: 'Pay rent',
          category: TaskCategory.money,
        );
        await app.start(tester);
        Get.toNamed(Routes.nudgeDebug);
        await settle(tester);

        await app.tapText(tester, 'Pre-generate now');

        expect(
          find.textContaining(
            'Pre-generation: wrote 0 nudge texts and 1 excuses for 1 tasks',
          ),
          findsOneWidget,
        );
        expect(await ready.has(t.id), isTrue);
      });
    });
  });
}
