import 'dart:math';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/risk.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/services/daily_job.dart';
import 'package:do_it_or_dodge_it/app/services/nudge_service.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';
import 'package:do_it_or_dodge_it/app/services/predictor_service.dart';

import '../data/test_database.dart';
import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late StepRepository steps;
  late NudgeRepository nudges;
  late OutcomeRepository outcomes;
  late SettingsRepository settings;
  late PredictorService predictor;
  late OutcomeService closer;
  late FakeNotificationGateway gateway;

  setUp(() {
    db = createTestDatabase();
    tasks = TaskRepository(db);
    steps = StepRepository(db);
    nudges = NudgeRepository(db);
    outcomes = OutcomeRepository(db);
    settings = SettingsRepository(db);
    predictor = PredictorService(
      tasks: tasks,
      steps: steps,
      outcomes: outcomes,
      settings: settings,
    );
    closer = OutcomeService(
      tasks: tasks,
      outcomes: outcomes,
      predictor: predictor,
    );
    gateway = FakeNotificationGateway();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  /// 60 past tasks: admin mostly dodged, health mostly done.
  Future<void> history({int count = 60}) async {
    final rng = Random(7);
    for (var i = 0; i < count; i++) {
      final admin = i.isEven;
      final task = await tasks.create(
        title: 'Past',
        category: admin ? TaskCategory.admin : TaskCategory.health,
        createdAt: DateTime(2030, 1, 1 + i % 28, (i * 7) % 24),
      );
      await predictor.recordDecision(task.id);
      if (rng.nextDouble() < (admin ? 0.9 : 0.1)) {
        await closer.markDodged(task.id);
      } else {
        await closer.markDone(task.id);
      }
    }
  }

  group('pacing nudges', () {
    final monday = DateTime(2030, 6, 3, 10);

    Future<Task> doing(TaskCategory category) async {
      final task = await tasks.create(
        title: category.label,
        category: category,
        createdAt: monday,
        dueAt: DateTime(2030, 6, 20),
      );
      await steps.createAll(task.id, const [
        NewStep(title: 'First', estMinutes: 1),
      ]);
      await tasks.updateStatus(task.id, TaskStatus.doing);
      return (await tasks.getById(task.id))!;
    }

    NudgeService nudgeService() => NudgeService(
      tasks: tasks,
      steps: steps,
      nudges: nudges,
      settings: settings,
      outcomes: closer,
      gateway: gateway,
      predictor: predictor,
      now: () => monday,
    );

    test('a task the user usually dodges gets more, closer nudges', () async {
      await history();
      final service = nudgeService();
      final risky = await doing(TaskCategory.admin);
      final safe = await doing(TaskCategory.health);

      await service.plan(risky);
      await service.plan(safe);

      final riskyRows = await nudges.listForTask(risky.id);
      final safeRows = await nudges.listForTask(safe.id);
      expect(riskyRows.length, greaterThan(safeRows.length));
      expect(
        riskyRows[1].fireAt.difference(riskyRows[0].fireAt),
        lessThan(safeRows[1].fireAt.difference(safeRows[0].fireAt)),
      );
    });

    test('the real score replaces the placeholder', () async {
      await history();
      final service = nudgeService();
      final risky = await doing(TaskCategory.admin);

      await service.plan(risky);

      final saved = (await tasks.getById(risky.id))!.dodgeRisk;
      expect(saved, isNotNull);
      expect(saved, greaterThan(0.65));
    });

    test('with no history it paces like a medium risk task', () async {
      final service = nudgeService();
      final task = await doing(TaskCategory.admin);

      expect(await service.plan(task), 4);
    });

    test('a scoring failure falls back to the stored risk', () async {
      final service = NudgeService(
        tasks: tasks,
        steps: steps,
        nudges: nudges,
        settings: settings,
        outcomes: closer,
        gateway: gateway,
        predictor: _BrokenPredictor(
          tasks: tasks,
          steps: steps,
          outcomes: outcomes,
          settings: settings,
        ),
        now: () => monday,
      );
      final task = await doing(TaskCategory.admin);
      await tasks.setDodgeRisk(task.id, 0.9);

      // 0.9 is a high risk: 6 nudges, not the 4 of the placeholder.
      expect(await service.plan((await tasks.getById(task.id))!), 6);
    });
  });

  group('daily job', () {
    test('retrains the predictor and reports it', () async {
      await history(count: 30);
      await settings.remove(SettingsKeys.predictorWeights);
      final service = NudgeService(
        tasks: tasks,
        steps: steps,
        nudges: nudges,
        settings: settings,
        outcomes: closer,
        gateway: gateway,
        predictor: predictor,
      );

      final result = await DailyJob(service, predictor: predictor).run();

      expect(result.retrained, 30);
      expect(await settings.get(SettingsKeys.predictorWeights), isNotNull);
      expect(result.toString(), contains('predictor trained on 30'));
    });

    test('reports 0 while the simple rule is used', () async {
      await history(count: 5);
      final service = NudgeService(
        tasks: tasks,
        steps: steps,
        nudges: nudges,
        settings: settings,
        outcomes: closer,
        gateway: gateway,
        predictor: predictor,
      );

      final result = await DailyJob(service, predictor: predictor).run();

      expect(result.retrained, 0);
    });
  });

  group('on screen', () {
    late FakeModelRuntime runtime;
    late AppHarness app;

    setUp(() {
      runtime = FakeModelRuntime()..responder = validResponder();
      app = AppHarness(
        db: db,
        runtime: runtime,
        share: FakeShareService(),
        notifications: gateway,
      );
    });

    testWidgets('a new task shows a starting guess and why', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent', category: 'Money');

        await app.tapText(tester, 'Pay rent');

        expect(find.text('Dodge risk'), findsOneWidget);
        expect(find.textContaining('50%'), findsWidgets);
        expect(
          find.textContaining('Not enough history yet, so this starts at 50%.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('A starting guess until there is more history'),
          findsOneWidget,
        );
        final saved = (await TaskRepository(db).listAll()).single.dodgeRisk;
        expect(saved, 0.5);
      });
    });

    testWidgets('after enough history it shows a learned score and a reason', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await history();
        await app.start(tester);
        await app.addTask(tester, 'File taxes', category: 'Admin');

        await app.tapText(tester, 'File taxes');

        expect(
          find.textContaining('Learned from your last 60 tasks'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            RegExp(r'You dodge admin tasks \d+% of the time\.'),
          ),
          findsOneWidget,
        );
        final risk = (await TaskRepository(
          db,
        ).listAll()).firstWhere((t) => t.title == 'File taxes').dodgeRisk!;
        expect(risk, greaterThan(0.65));
        expect(find.textContaining('${(risk * 100).round()}%'), findsWidgets);
      });
    });

    testWidgets('a task the user usually does shows a low score', (
      tester,
    ) async {
      await runWithApp(tester, () async {
        await history();
        await app.start(tester);
        await app.addTask(tester, 'Gym', category: 'Health');

        await app.tapText(tester, 'Gym');

        expect(
          find.textContaining(
            RegExp(r'You finish health tasks \d+% of the time\.'),
          ),
          findsOneWidget,
        );
        final risk = (await TaskRepository(
          db,
        ).listAll()).firstWhere((t) => t.title == 'Gym').dodgeRisk!;
        expect(risk, lessThan(0.35));
      });
    });

    testWidgets(
      'choosing Do It saves the features, kept when the task is done',
      (tester) async {
        await runWithApp(tester, () async {
          runtime.responder = scripted([validShrink]);
          await app.start(tester);
          await app.addTask(tester, 'Pay rent', category: 'Money');
          final id = (await TaskRepository(db).listAll()).single.id;

          await app.tapText(tester, 'Pay rent');
          await app.tapText(tester, 'Do It');

          expect(
            await settings.get('${SettingsKeys.decisionSnapshotPrefix}$id'),
            isNotNull,
          );

          for (var i = 0; i < 3; i++) {
            await tester.tap(find.byType(Checkbox).at(i));
            await settle(tester);
          }

          final logged = (await outcomes.listForTask(id)).single;
          final snapshot = outcomes.snapshotOf(logged);
          expect(logged.result, OutcomeResult.done);
          expect(snapshot['cat_money'], 1);
          // The steps were written after the choice, so they are not in it.
          expect(snapshot['step_count'], 0);
          expect(
            await settings.get('${SettingsKeys.decisionSnapshotPrefix}$id'),
            isNull,
          );
        });
      },
    );

    testWidgets('choosing Dodge It saves the features too', (tester) async {
      await runWithApp(tester, () async {
        await app.start(tester);
        await app.addTask(tester, 'Pay rent', category: 'Money');
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Dodge It');
        await tester.enterText(find.byType(TextField), 'boss');
        await app.tapText(tester, 'Write my excuse');
        await app.tapText(tester, 'Copy');

        final id = (await TaskRepository(db).listAll()).single.id;
        final logged = (await outcomes.listForTask(id)).single;
        expect(logged.result, OutcomeResult.dodged);
        expect(outcomes.snapshotOf(logged)['cat_money'], 1);
      });
    });

    testWidgets('every closed task teaches the model', (tester) async {
      await runWithApp(tester, () async {
        await history(count: 19);
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent', category: 'Money');
        expect(await settings.get(SettingsKeys.predictorWeights), isNull);

        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Do It');
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byType(Checkbox).at(i));
          await settle(tester);
        }

        // That was the 20th outcome.
        expect(await settings.get(SettingsKeys.predictorWeights), isNotNull);
      });
    });

    testWidgets('deleting a task forgets its saved features', (tester) async {
      await runWithApp(tester, () async {
        runtime.responder = scripted([validShrink]);
        await app.start(tester);
        await app.addTask(tester, 'Pay rent');
        final id = (await TaskRepository(db).listAll()).single.id;
        await app.tapText(tester, 'Pay rent');
        await app.tapText(tester, 'Do It');
        Get.until((r) => r.settings.name == '/home');
        await settle(tester);
        expect(
          await settings.get('${SettingsKeys.decisionSnapshotPrefix}$id'),
          isNotNull,
        );

        await app.longPress(tester, find.text('Pay rent'));
        await tester.tap(find.text('Delete'));
        await settle(tester);

        expect(
          await settings.get('${SettingsKeys.decisionSnapshotPrefix}$id'),
          isNull,
        );
      });
    });
  });
}

class _BrokenPredictor extends PredictorService {
  _BrokenPredictor({
    required super.tasks,
    required super.steps,
    required super.outcomes,
    required super.settings,
  });

  @override
  Future<RiskAssessment> assess(Task task, {bool save = true}) {
    throw StateError('scoring is broken');
  }
}
