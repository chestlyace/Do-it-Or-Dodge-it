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
import 'package:do_it_or_dodge_it/app/services/daily_job.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';
import 'package:do_it_or_dodge_it/app/services/nudge_service.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';

import '../data/test_database.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Monday 10:00.
  final start = DateTime(2030, 1, 7, 10);

  late AppDatabase db;
  late TaskRepository tasks;
  late StepRepository steps;
  late NudgeRepository nudges;
  late OutcomeRepository outcomes;
  late SettingsRepository settings;
  late OutcomeService outcomeService;
  late FakeNotificationGateway gateway;
  late NudgeService service;
  late DateTime now;

  NudgeService build({GemmaService? gemma}) {
    final s = NudgeService(
      tasks: tasks,
      steps: steps,
      nudges: nudges,
      settings: settings,
      outcomes: outcomeService,
      gateway: gateway,
      gemma: gemma,
      now: () => now,
    );
    outcomeService.onClosed = s.cancelFor;
    return s;
  }

  Future<Task> doingTask({
    String title = 'Pay rent',
    DateTime? dueAt,
    double? risk,
    List<String> stepTitles = const ['Open the app', 'Pick the invoice', 'Pay'],
  }) async {
    final task = await tasks.create(
      title: title,
      category: TaskCategory.money,
      dueAt: dueAt,
      createdAt: now,
    );
    await steps.createAll(task.id, [
      for (final t in stepTitles) NewStep(title: t, estMinutes: 1),
    ]);
    await tasks.updateStatus(task.id, TaskStatus.doing);
    if (risk != null) await tasks.setDodgeRisk(task.id, risk);
    return (await tasks.getById(task.id))!;
  }

  setUp(() {
    now = start;
    db = createTestDatabase();
    tasks = TaskRepository(db);
    steps = StepRepository(db);
    nudges = NudgeRepository(db);
    outcomes = OutcomeRepository(db);
    settings = SettingsRepository(db);
    outcomeService = OutcomeService(tasks: tasks, outcomes: outcomes);
    gateway = FakeNotificationGateway();
    service = build();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  group('plan', () {
    test('schedules a notification for every nudge, matched by id', () async {
      final task = await doingTask(risk: 0.5);

      final count = await service.plan(task);

      expect(count, 4);
      final rows = await nudges.listForTask(task.id);
      expect(rows, hasLength(4));
      expect(
        gateway.scheduled.keys.toSet(),
        rows.map((n) => n.notificationId).toSet(),
      );
      for (final row in rows) {
        final scheduled = gateway.scheduled[row.notificationId]!;
        expect(scheduled.at, row.fireAt);
        expect(scheduled.body, row.message);
        expect(scheduled.payload, '${row.id}:${task.id}');
        expect(row.fired, isFalse);
        expect(row.opened, isFalse);
      }
    });

    test('every nudge names only the next undone step', () async {
      final task = await doingTask(risk: 0.5);

      await service.plan(task);

      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Open the app'));
        expect(n.body, isNot(contains('Pick the invoice')));
        expect(n.body, isNot(contains('Pay rent')));
        expect(n.title, 'Next tiny step');
      }
    });

    test('uses the placeholder risk until the predictor exists', () async {
      final task = await doingTask();
      expect(task.dodgeRisk, isNull);

      expect(await service.plan(task), 4); // medium
    });

    test(
      'a high risk task gets more, closer nudges than a low risk one',
      () async {
        final low = await doingTask(title: 'Low', risk: 0.1);
        final high = await doingTask(title: 'High', risk: 0.9);

        await service.plan(low);
        await service.plan(high);

        final lowRows = await nudges.listForTask(low.id);
        final highRows = await nudges.listForTask(high.id);
        expect(highRows.length, greaterThan(lowRows.length));
        expect(
          highRows[1].fireAt.difference(highRows[0].fireAt),
          lessThan(lowRows[1].fireAt.difference(lowRows[0].fireAt)),
        );
      },
    );

    test('nothing is scheduled during quiet hours', () async {
      now = DateTime(2030, 1, 7, 20, 30);
      final task = await doingTask(risk: 0.9);

      await service.plan(task);

      expect(gateway.scheduled, isNotEmpty);
      for (final n in gateway.scheduled.values) {
        expect(QuietHours.standard.contains(n.at), isFalse, reason: '${n.at}');
      }
    });

    test('quiet hours come from settings', () async {
      await settings.set(SettingsKeys.quietHoursStart, '10:00');
      await settings.set(SettingsKeys.quietHoursEnd, '17:00');
      final task = await doingTask(risk: 0.9);

      await service.plan(task);

      for (final n in gateway.scheduled.values) {
        final hour = n.at.hour;
        expect(hour < 10 || hour >= 17, isTrue, reason: '${n.at}');
      }
    });

    test('nothing is scheduled after the due date', () async {
      final task = await doingTask(risk: 0.9, dueAt: DateTime(2030, 1, 7));

      await service.plan(task);

      for (final n in gateway.scheduled.values) {
        expect(n.at.isBefore(DateTime(2030, 1, 7, 23, 59, 59)), isTrue);
      }
    });

    test('plans again from scratch instead of piling up', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final firstIds = gateway.scheduled.keys.toSet();

      await service.plan(task);

      expect(await nudges.listForTask(task.id), hasLength(4));
      expect(gateway.scheduled, hasLength(4));
      expect(gateway.cancelled.toSet(), firstIds);
    });

    test('plans nothing for a task with no undone step', () async {
      final task = await doingTask(stepTitles: ['Only']);
      final only = (await steps.listForTask(task.id)).single;
      await steps.markDone(only.id);

      expect(await service.plan(task), 0);
      expect(gateway.scheduled, isEmpty);
    });

    test('plans nothing for a closed task', () async {
      final task = await doingTask();
      await tasks.updateStatus(task.id, TaskStatus.dodged);

      expect(await service.plan((await tasks.getById(task.id))!), 0);
    });

    test('plans nothing when notifications are off', () async {
      gateway.enabled = false;
      final task = await doingTask();

      expect(await service.plan(task), 0);
      expect(await nudges.listAll(), isEmpty);
      expect(service.notificationsEnabled.value, isFalse);
    });

    test('fast clock plans three nudges a minute apart', () async {
      await settings.set(SettingsKeys.nudgeFastClock, 'true');
      now = DateTime(2030, 1, 7, 23, 0); // in quiet hours
      final task = await doingTask();

      await service.plan(task);

      final times = gateway.inOrder.map((n) => n.at).toList();
      expect(times, [
        now.add(const Duration(minutes: 1)),
        now.add(const Duration(minutes: 2)),
        now.add(const Duration(minutes: 3)),
      ]);
    });

    test('a scheduling error does not stop the rest', () async {
      final task = await doingTask(risk: 0.5);
      final failing = _FailingGateway(failAfter: 1);
      service = NudgeService(
        tasks: tasks,
        steps: steps,
        nudges: nudges,
        settings: settings,
        outcomes: outcomeService,
        gateway: failing,
        now: () => now,
      );

      final count = await service.plan(task);

      expect(count, 3);
    });
  });

  group('ticking steps', () {
    test('replaces pending nudges and names the next step', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final oldIds = gateway.scheduled.keys.toSet();
      final first = (await steps.listForTask(task.id)).first;

      await steps.markDone(first.id);
      await service.replan(task.id);

      expect(gateway.scheduled.keys.toSet().intersection(oldIds), isEmpty);
      expect(gateway.cancelled.toSet().containsAll(oldIds), isTrue);
      expect(gateway.scheduled, isNotEmpty);
      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Pick the invoice'));
        expect(n.body, isNot(contains('Open the app')));
      }
    });

    test('unticking brings the earlier step back', () async {
      final task = await doingTask(risk: 0.5);
      final first = (await steps.listForTask(task.id)).first;
      await steps.markDone(first.id);
      await service.replan(task.id);

      await steps.markUndone(first.id);
      await service.replan(task.id);

      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Open the app'));
      }
    });

    test('replan for a deleted task cancels what is left', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);

      await service.cancelFor(task.id);
      await tasks.delete(task.id);

      expect(await service.replan(task.id), 0);
      expect(gateway.scheduled, isEmpty);
    });
  });

  group('closing a task', () {
    test('finishing cancels every pending nudge', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      expect(gateway.scheduled, isNotEmpty);

      await outcomeService.markDone(task.id);

      expect(gateway.scheduled, isEmpty);
      expect(await nudges.listPendingForTask(task.id), isEmpty);
    });

    test('dodging cancels every pending nudge', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);

      await outcomeService.markDodged(task.id);

      expect(gateway.scheduled, isEmpty);
    });

    test('cancelling keeps nudges that already fired', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final firedRow = (await nudges.listForTask(task.id)).first;
      await nudges.markFired(firedRow.id);

      await service.cancelFor(task.id);

      final left = await nudges.listForTask(task.id);
      expect(left.map((n) => n.id), [firedRow.id]);
    });

    test(
      "one task's nudges are left alone when another is cancelled",
      () async {
        final a = await doingTask(title: 'A', risk: 0.5);
        final b = await doingTask(title: 'B', risk: 0.5);
        await service.plan(a);
        await service.plan(b);

        await service.cancelFor(a.id);

        expect(await nudges.listPendingForTask(a.id), isEmpty);
        expect(await nudges.listPendingForTask(b.id), hasLength(4));
        expect(gateway.scheduled, hasLength(4));
      },
    );
  });

  group('wording from the model', () {
    late FakeModelRuntime runtime;
    late GemmaService gemma;

    setUp(() async {
      runtime = FakeModelRuntime()..responder = scripted([validNudge]);
      await installModelFixture(db, runtime);
      gemma = GemmaService(runtime: runtime, settings: settings);
      Get.put(gemma);
      await gemma.started;
      service = build(gemma: gemma);
    });

    test(
      'is written once in the background and replaces the template',
      () async {
        await gemma.load();
        final task = await doingTask(risk: 0.5);

        await service.plan(task);
        expect(gateway.inOrder.first.body, contains('Open the app'));

        await service.settled();

        final bodies = gateway.scheduled.values.map((n) => n.body).toSet();
        expect(
          bodies,
          {
            'Ready to open the website?',
            'Open the website now.',
            'Last chance today: open the website.',
          }.intersection(bodies),
        );
        expect(
          bodies.every((b) => !b.contains('Ready for a tiny step')),
          isTrue,
        );
        expect(runtime.calls, hasLength(1));
        final rows = await nudges.listForTask(task.id);
        expect(rows.map((r) => r.message).toSet(), bodies);
      },
    );

    test('is stored, so planning again does not ask the model', () async {
      await gemma.load();
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      await service.settled();
      final calls = runtime.calls.length;

      await service.plan(task);
      await service.settled();

      expect(runtime.calls.length, calls);
      expect(
        gateway.scheduled.values.every(
          (n) => !n.body.contains('Ready for a tiny'),
        ),
        isTrue,
      );
    });

    test('the daily re-plan reuses stored wording without the model', () async {
      await gemma.load();
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      await service.settled();
      final calls = runtime.calls.length;

      await service.replanAll();

      expect(runtime.calls.length, calls);
      expect(
        gateway.scheduled.values.every(
          (n) => !n.body.contains('Ready for a tiny'),
        ),
        isTrue,
      );
    });

    test('is not written when the model is not loaded', () async {
      final task = await doingTask(risk: 0.5);

      await service.plan(task);
      await service.settled();

      expect(runtime.calls, isEmpty);
      expect(
        gateway.scheduled.values.every((n) => n.body.contains('Open the app')),
        isTrue,
      );
    });

    test('bad model output leaves the template in place', () async {
      runtime.responder = scripted(['not json']);
      await gemma.load();
      final task = await doingTask(risk: 0.5);

      await service.plan(task);
      await service.settled();

      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Open the app'));
      }
    });

    test('a step ticked meanwhile does not get the old wording', () async {
      await gemma.load();
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final first = (await steps.listForTask(task.id)).first;
      await steps.markDone(first.id);
      await service.replan(task.id, allowModel: false);

      await service.settled();

      for (final n in gateway.scheduled.values) {
        expect(n.body, contains('Pick the invoice'));
      }
    });
  });

  group('permission', () {
    test('is asked for once, the first time', () async {
      gateway
        ..enabled = false
        ..grantOnRequest = false;

      expect(await service.ensurePermission(), isFalse);
      expect(await service.ensurePermission(), isFalse);

      expect(gateway.permissionRequests, 1);
      expect(service.notificationsEnabled.value, isFalse);
    });

    test('granting it turns nudges on', () async {
      gateway.enabled = false;

      expect(await service.ensurePermission(), isTrue);

      expect(gateway.permissionRequests, 1);
      expect(service.notificationsEnabled.value, isTrue);
    });

    test('is not asked when already allowed', () async {
      expect(await service.ensurePermission(), isTrue);
      expect(gateway.permissionRequests, 0);
    });
  });

  group('daily maintenance', () {
    test('replanAll plans tasks being worked on, not open ones', () async {
      final doing = await doingTask(title: 'Doing', risk: 0.5);
      await tasks.create(title: 'Open', category: TaskCategory.work);

      final count = await service.replanAll();

      expect(count, 4);
      expect(await nudges.listForTask(doing.id), hasLength(4));
      expect((await nudges.listAll()).length, 4);
    });

    test('a task past its due date with no progress is abandoned', () async {
      final task = await doingTask(dueAt: DateTime(2030, 1, 6));

      expect(await service.abandonOverdue(), 1);

      expect((await tasks.getById(task.id))!.status, TaskStatus.abandoned);
      final logged = await outcomes.listForTask(task.id);
      expect(logged.single.result, OutcomeResult.abandoned);
    });

    test('abandoning cancels its nudges', () async {
      final task = await doingTask(risk: 0.5, dueAt: DateTime(2030, 1, 7));
      await service.plan(task);
      expect(gateway.scheduled, isNotEmpty);

      now = DateTime(2030, 1, 8, 9);
      await service.abandonOverdue();

      expect(gateway.scheduled, isEmpty);
    });

    test(
      'progress, no due date, or a due day not over keep the task',
      () async {
        final withProgress = await doingTask(
          title: 'A',
          dueAt: DateTime(2030, 1, 6),
        );
        await steps.markDone(
          (await steps.listForTask(withProgress.id)).first.id,
        );
        final noDue = await doingTask(title: 'B');
        final dueToday = await doingTask(
          title: 'C',
          dueAt: DateTime(2030, 1, 7),
        );
        now = DateTime(2030, 1, 7, 23, 0);

        expect(await service.abandonOverdue(), 0);

        for (final t in [withProgress, noDue, dueToday]) {
          expect((await tasks.getById(t.id))!.status, TaskStatus.doing);
        }
      },
    );

    test('an open task that was never started is left alone', () async {
      await tasks.create(
        title: 'Never started',
        category: TaskCategory.work,
        dueAt: DateTime(2030, 1, 1),
      );
      expect(await service.abandonOverdue(), 0);
    });

    test('syncFired marks nudges whose time has passed', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);

      now = start.add(const Duration(hours: 7));
      final count = await service.syncFired();

      expect(count, 2); // 13:00 and 16:00
      final rows = await nudges.listForTask(task.id);
      expect(rows.where((n) => n.fired), hasLength(2));
    });

    test('the daily job does all three and reports it', () async {
      final overdue = await doingTask(
        title: 'Overdue',
        dueAt: DateTime(2030, 1, 6),
      );
      final active = await doingTask(title: 'Active', risk: 0.5);
      await service.plan(active);
      now = start.add(const Duration(hours: 4));

      final result = await DailyJob(service).run();

      expect(result.fired, 1);
      expect(result.abandoned, 1);
      expect(result.planned, 4);
      expect((await tasks.getById(overdue.id))!.status, TaskStatus.abandoned);
      expect(result.toString(), contains('abandoned 1'));
    });
  });

  group('tapping a nudge', () {
    test('records that it was opened', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final row = (await nudges.listForTask(task.id)).first;

      await service.handleTap('${row.id}:${task.id}');

      final saved = (await nudges.getById(row.id))!;
      expect(saved.opened, isTrue);
      expect(saved.fired, isTrue);
    });

    test(
      'while the app is starting, the task opens once Home is ready',
      () async {
        final task = await doingTask(risk: 0.5);
        await service.plan(task);
        final row = (await nudges.listForTask(task.id)).first;

        await service.handleTap('${row.id}:${task.id}');

        expect(service.takePendingOpen(), task.id);
        expect(service.takePendingOpen(), isNull);
      },
    );

    test('ignores payloads it cannot read', () async {
      for (final bad in [null, '', 'x', '1', '1:2:3', 'a:b']) {
        await service.handleTap(bad);
      }
      expect(service.takePendingOpen(), isNull);
    });

    test(
      'the notification that launched the app is handled at startup',
      () async {
        final task = await doingTask(risk: 0.5);
        await service.plan(task);
        final row = (await nudges.listForTask(task.id)).first;
        gateway.launch = '${row.id}:${task.id}';

        await service.init(maintain: false);

        expect(service.takePendingOpen(), task.id);
        expect((await nudges.getById(row.id))!.opened, isTrue);
      },
    );

    test('the tap callback is wired to the plugin', () async {
      final task = await doingTask(risk: 0.5);
      await service.plan(task);
      final row = (await nudges.listForTask(task.id)).first;
      await service.init(maintain: false);

      gateway.onTap!('${row.id}:${task.id}');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((await nudges.getById(row.id))!.opened, isTrue);
    });
  });

  group('startup', () {
    test(
      'sets the plugin up and tidies up what happened while closed',
      () async {
        final overdue = await doingTask(
          title: 'Overdue',
          dueAt: DateTime(2030, 1, 6),
        );
        final active = await doingTask(title: 'Active', risk: 0.5);

        await service.init();

        expect(gateway.initializeCalls, 1);
        expect((await tasks.getById(overdue.id))!.status, TaskStatus.abandoned);
        expect(await nudges.listForTask(active.id), hasLength(4));
      },
    );

    test('a plugin failure never crashes the app', () async {
      gateway.initializeError = StateError('no plugin');
      await doingTask(risk: 0.5);

      await service.init();
    });
  });
}

class _FailingGateway extends FakeNotificationGateway {
  _FailingGateway({required this.failAfter});

  final int failAfter;
  int _calls = 0;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (++_calls == failAfter) throw StateError('alarm limit');
    return super.schedule(
      id: id,
      title: title,
      body: body,
      at: at,
      payload: payload,
    );
  }
}
