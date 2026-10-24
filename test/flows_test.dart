import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/excuse_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';

import 'data/test_database.dart';
import 'support/app_harness.dart';
import 'support/fakes.dart';
import 'support/job_replies.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late FakeShareService share;
  late AppHarness app;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime();
    share = FakeShareService();
    app = AppHarness(db: db, runtime: runtime, share: share);
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<Task> onlyTask() async => (await TaskRepository(db).listAll()).single;

  Future<void> backHome(WidgetTester tester) async {
    Get.until((r) => r.settings.name == Routes.home);
    await settle(tester);
  }

  Future<void> openDoIt(WidgetTester tester, String title) async {
    await app.tapText(tester, title);
    await app.tapText(tester, 'Do It');
  }

  Future<void> openDodgeIt(WidgetTester tester, String title) async {
    await app.tapText(tester, title);
    await app.tapText(tester, 'Dodge It');
  }

  group('Do It', () {
    testWidgets('add task, Do It, tick every step: task done, outcome saved', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDoIt(tester, 'Pay rent');

        expect(find.text('Open the website'), findsOneWidget);
        expect(find.text('Find the form'), findsOneWidget);
        expect(find.text('Fill in the first section'), findsOneWidget);
        expect(find.text('0 of 3 steps done'), findsOneWidget);
        expect((await onlyTask()).status, TaskStatus.doing);

        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(Checkbox).at(i));
          await settle(tester);
        }

        expect(find.text('All done. Logged as done.'), findsOneWidget);
        final task = await onlyTask();
        expect(task.status, TaskStatus.done);
        final outcomes = await OutcomeRepository(db).listForTask(task.id);
        expect(outcomes.single.result, OutcomeResult.done);
        final steps = await StepRepository(db).listForTask(task.id);
        expect(steps.every((s) => s.doneAt != null), isTrue);

        await backHome(tester);
        expect(find.text('Done (1)'), findsOneWidget);
      });
    });

    testWidgets('the last step closes the task only once', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDoIt(tester, 'Pay rent');

        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(Checkbox).at(i));
          await settle(tester);
        }

        expect(await OutcomeRepository(db).listAll(), hasLength(1));
        // A finished task cannot be unticked.
        final box = tester.widget<Checkbox>(find.byType(Checkbox).first);
        expect(box.onChanged, isNull);
      });
    });

    testWidgets('a step can be unticked before the task is finished', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDoIt(tester, 'Pay rent');

        await tester.tap(find.byType(Checkbox).first);
        await settle(tester);
        expect(find.text('1 of 3 steps done'), findsOneWidget);

        await tester.tap(find.byType(Checkbox).first);
        await settle(tester);
        expect(find.text('0 of 3 steps done'), findsOneWidget);
        expect(await OutcomeRepository(db).listAll(), isEmpty);
      });
    });

    testWidgets('reopening a task shows its saved steps without asking Gemma', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDoIt(tester, 'Pay rent');
        await tester.tap(find.byType(Checkbox).first);
        await settle(tester);
        final callsBefore = runtime.calls.length;

        await backHome(tester);
        await openDoIt(tester, 'Pay rent');

        expect(find.text('1 of 3 steps done'), findsOneWidget);
        expect(runtime.calls.length, callsBefore);
      });
    });

    testWidgets('"Help me" writes a draft the user can copy', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Reply to Sam');
        await openDoIt(tester, 'Reply to Sam');

        await tester.tap(find.text('Help me').first);
        await settle(tester);
        expect(
          find.text('Hi Sam, could you resend the invoice? Thanks!'),
          findsOneWidget,
        );

        await tester.tap(find.text('Copy draft'));
        await settle(tester);
        expect(share.copied, ['Hi Sam, could you resend the invoice? Thanks!']);

        final steps = await StepRepository(db)
            .listForTask((await onlyTask()).id);
        expect(steps.first.draftText, contains('Hi Sam'));
        expect(steps[1].draftText, isNull);
      });
    });

    testWidgets('a saved draft shows again without another model call', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Reply to Sam');
        await openDoIt(tester, 'Reply to Sam');
        await tester.tap(find.text('Help me').first);
        await settle(tester);
        final calls = runtime.calls.length;

        Navigator.of(tester.element(find.text('Copy draft'))).pop();
        await settle(tester);
        await tester.tap(find.text('Help me').first);
        await settle(tester);

        expect(find.textContaining('Hi Sam'), findsOneWidget);
        expect(runtime.calls.length, calls);
      });
    });

    testWidgets('broken output shows the raw text and can be retried', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        var reply = 'this is not json';
        runtime.responder = (_) => reply;
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDoIt(tester, 'Pay rent');

        expect(find.text('Gemma could not make the steps.'), findsOneWidget);
        expect(find.text('this is not json'), findsOneWidget);
        expect((await onlyTask()).status, TaskStatus.open);
        expect(
          await StepRepository(db).listForTask((await onlyTask()).id),
          isEmpty,
        );

        reply = validShrink;
        await app.tapText(tester, 'Try again');

        expect(find.text('Open the website'), findsOneWidget);
        expect((await onlyTask()).status, TaskStatus.doing);
      });
    });

    testWidgets('stopping generation shows a retry and saves nothing', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await app.tapText(tester, 'Pay rent');
        final gate = Completer<void>();
        runtime.models.single.gate = gate;

        await tester.tap(find.text('Do It').first);
        await settle(tester);
        expect(find.textContaining('Breaking "Pay rent"'), findsOneWidget);

        await tester.tap(find.text('Stop'));
        await settle(tester);
        gate.complete();
        await settle(tester);

        expect(find.text('Gemma could not make the steps.'), findsOneWidget);
        expect(find.text('Stopped.'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect((await onlyTask()).status, TaskStatus.open);
      });
    });

    testWidgets('Do It is not offered on a closed task', (tester) async {
      await runWithApp(tester, () async {
        final repo = TaskRepository(db);
        final task = await repo.create(
          title: 'Old',
          category: TaskCategory.work,
        );
        await repo.updateStatus(task.id, TaskStatus.done);
        await app.start(tester);

        await app.tapText(tester, 'Old');

        expect(find.text('Do It'), findsNothing);
        expect(runtime.calls, isEmpty);
      });
    });
  });

  group('Dodge It', () {
    Future<void> writeExcuse(WidgetTester tester, String recipient) async {
      await tester.enterText(find.byType(TextField), recipient);
      await app.tapText(tester, 'Write my excuse');
    }

    testWidgets('add task, Dodge It, copy: task dodged, outcome saved', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');

        await writeExcuse(tester, 'boss');
        expect(
          find.text('My week got away from me, number 1.'),
          findsOneWidget,
        );

        await app.tapText(tester, 'Short');
        expect(find.text('Busy.'), findsOneWidget);
        await app.tapText(tester, 'Copy');

        expect(share.copied, ['Busy.']);
        expect(find.text('Logged as dodged.'), findsOneWidget);

        final task = await onlyTask();
        expect(task.status, TaskStatus.dodged);
        final outcomes = await OutcomeRepository(db).listForTask(task.id);
        expect(outcomes.single.result, OutcomeResult.dodged);
        final excuses = await ExcuseRepository(db).listForTask(task.id);
        expect(excuses.single.recipientLabel, 'boss');
        expect(excuses.single.tone, 'Polite');
        expect(excuses.single.body, 'Busy.');
        expect(excuses.single.shared, isTrue);

        await app.tapText(tester, 'Back to my tasks');
        expect(find.text('Dodged (1)'), findsOneWidget);
      });
    });

    testWidgets('sharing through the share sheet logs the dodge', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');
        await writeExcuse(tester, 'boss');

        await app.tapText(tester, 'Share');

        expect(share.shared, ['My week got away from me, number 1.']);
        expect((await onlyTask()).status, TaskStatus.dodged);
        expect(await OutcomeRepository(db).listAll(), hasLength(1));
      });
    });

    testWidgets('a dismissed share sheet logs nothing', (tester) async {
      await runWithApp(tester, () async {
        share.shareResult = false;
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');
        await writeExcuse(tester, 'boss');

        await app.tapText(tester, 'Share');

        expect(find.text('Logged as dodged.'), findsNothing);
        expect((await onlyTask()).status, TaskStatus.open);
        expect(await OutcomeRepository(db).listAll(), isEmpty);
        expect(
          await ExcuseRepository(db).listForTask((await onlyTask()).id),
          isEmpty,
        );
      });
    });

    testWidgets('copying twice logs the dodge only once', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');
        await writeExcuse(tester, 'boss');

        await app.tapText(tester, 'Copy');
        await app.tapText(tester, 'Copy');

        expect(await OutcomeRepository(db).listAll(), hasLength(1));
      });
    });

    testWidgets('it needs to know who the excuse is for', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');
        final calls = runtime.calls.length;

        await app.tapText(tester, 'Write my excuse');

        expect(find.text('Say who the excuse is for'), findsOneWidget);
        expect(runtime.calls.length, calls);
      });
    });

    testWidgets('the chosen tone and recipient reach the prompt', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');

        await app.tapText(tester, 'Funny');
        await writeExcuse(tester, 'landlord');

        final prompt = runtime.calls.last.prompt;
        expect(prompt, contains('Task: Pay rent'));
        expect(prompt, contains('This is for: landlord'));
        expect(prompt, contains('Tone: Funny'));
      });
    });

    testWidgets('regenerate writes another excuse and logs nothing', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');
        await writeExcuse(tester, 'boss');

        await app.tapText(tester, 'Regenerate');

        expect(
          find.text('My week got away from me, number 2.'),
          findsOneWidget,
        );
        expect((await onlyTask()).status, TaskStatus.open);
        expect(await OutcomeRepository(db).listAll(), isEmpty);
      });
    });

    testWidgets('an excuse used for someone is remembered on the next task', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);
        await app.addTask(tester, 'Task one');
        await openDodgeIt(tester, 'Task one');
        await writeExcuse(tester, 'boss');
        await app.tapText(tester, 'Copy');
        await app.tapText(tester, 'Back to my tasks');

        await app.addTask(tester, 'Task two');
        await openDodgeIt(tester, 'Task two');
        await writeExcuse(tester, 'boss');

        final prompt = runtime.calls.last.prompt;
        expect(prompt, contains('Excuses already used for this person'));
        expect(prompt, contains('number 1'));
      });
    });

    testWidgets('an unusable excuse shows the reason and keeps the task open', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        runtime.responder = (_) => excuseJson('I was sick all week.');
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        await openDodgeIt(tester, 'Pay rent');

        await writeExcuse(tester, 'boss');

        expect(
          find.text('Gemma could not write a usable excuse.'),
          findsOneWidget,
        );
        expect(find.text('Copy'), findsNothing);
        expect((await onlyTask()).status, TaskStatus.open);
      });
    });

    testWidgets('a dodged task cannot be dodged again', (tester) async {
      await runWithApp(tester, () async {
        final repo = TaskRepository(db);
        final task = await repo.create(
          title: 'Old',
          category: TaskCategory.work,
        );
        await repo.updateStatus(task.id, TaskStatus.dodged);
        await app.start(tester);

        Get.toNamed(Routes.dodgeIt, arguments: task.id);
        await settle(tester);

        expect(find.text('This task is already dodged.'), findsOneWidget);
        expect(find.text('Write my excuse'), findsNothing);
      });
    });
  });

  group('History', () {
    testWidgets('counts match the outcome rows', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = validResponder();
        await app.start(tester);

        await app.addTask(tester, 'Finish me');
        await openDoIt(tester, 'Finish me');
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(Checkbox).at(i));
          await settle(tester);
        }
        await backHome(tester);

        await app.addTask(tester, 'Dodge me');
        await openDodgeIt(tester, 'Dodge me');
        await tester.enterText(find.byType(TextField), 'boss');
        await app.tapText(tester, 'Write my excuse');
        await app.tapText(tester, 'Copy');
        await backHome(tester);

        await tester.tap(find.byTooltip('History'));
        await settle(tester);

        final rows = await OutcomeRepository(db).listAll();
        expect(rows, hasLength(2));
        expect(find.text('Finish me'), findsOneWidget);
        expect(find.text('Dodge me'), findsOneWidget);
        expect(find.textContaining('Done ·'), findsOneWidget);
        expect(find.textContaining('Dodged ·'), findsOneWidget);

        // Header counts: Done 1, Dodged 1, Abandoned 0.
        final counts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .where((t) => t == '0' || t == '1')
            .toList();
        expect(counts, ['1', '1', '0']);
      });
    });
  });
}
