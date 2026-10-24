import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/risk_features.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/risk.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';
import 'package:do_it_or_dodge_it/app/services/predictor_service.dart';

import '../data/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late StepRepository steps;
  late OutcomeRepository outcomes;
  late SettingsRepository settings;
  late PredictorService predictor;
  late OutcomeService closer;

  PredictorService newPredictor() => PredictorService(
    tasks: tasks,
    steps: steps,
    outcomes: outcomes,
    settings: settings,
  );

  setUp(() {
    db = createTestDatabase();
    tasks = TaskRepository(db);
    steps = StepRepository(db);
    outcomes = OutcomeRepository(db);
    settings = SettingsRepository(db);
    predictor = newPredictor();
    closer = OutcomeService(
      tasks: tasks,
      outcomes: outcomes,
      predictor: predictor,
    );
  });

  tearDown(() => db.close());

  /// A task the user chose to Do or Dodge, and how it ended.
  Future<Task> finished(
    TaskCategory category, {
    required bool dodged,
    DateTime? createdAt,
    DateTime? dueAt,
  }) async {
    final task = await tasks.create(
      title: 'T',
      category: category,
      createdAt: createdAt,
      dueAt: dueAt,
    );
    await predictor.recordDecision(task.id);
    if (dodged) {
      await closer.markDodged(task.id);
    } else {
      await closer.markDone(task.id);
    }
    return task;
  }

  Future<Task> openTask(TaskCategory category) {
    return tasks.create(title: 'New', category: category);
  }

  /// A user who dodges admin 90% of the time and does health 90% of the time.
  Future<void> syntheticUser({int count = 60}) async {
    final rng = Random(7);
    for (var i = 0; i < count; i++) {
      final admin = i.isEven;
      final dodged = rng.nextDouble() < (admin ? 0.9 : 0.1);
      await finished(
        admin ? TaskCategory.admin : TaskCategory.health,
        dodged: dodged,
        createdAt: DateTime(2030, 1, 1 + i % 28, (i * 7) % 24),
      );
    }
  }

  Future<Map<String, dynamic>> storedModel() async {
    final raw = await settings.get(SettingsKeys.predictorWeights);
    return jsonDecode(raw!) as Map<String, dynamic>;
  }

  group('learning from a synthetic history', () {
    test('learns that admin is dodged more and scores it higher', () async {
      await syntheticUser();

      final admin = await predictor.assess(await openTask(TaskCategory.admin));
      final health = await predictor.assess(
        await openTask(TaskCategory.health),
      );

      expect(admin.source, RiskSource.model);
      expect(health.source, RiskSource.model);
      expect(admin.risk, greaterThan(0.65));
      expect(health.risk, lessThan(0.35));
      expect(admin.risk, greaterThan(health.risk + 0.3));
    });

    test('a category it has never seen sits in between', () async {
      await syntheticUser();

      final unknown = await predictor.assess(
        await openTask(TaskCategory.money),
      );

      expect(unknown.risk, inExclusiveRange(0.2, 0.8));
    });

    test('explains the score in plain words', () async {
      await syntheticUser();

      final admin = await predictor.assess(await openTask(TaskCategory.admin));
      final health = await predictor.assess(
        await openTask(TaskCategory.health),
      );

      expect(
        admin.reason,
        matches(RegExp(r'You dodge admin tasks \d+% of the time\.')),
      );
      expect(
        health.reason,
        matches(RegExp(r'You finish health tasks \d+% of the time\.')),
      );
      expect(admin.outcomesUsed, 60);
    });

    test('the score is saved on the task', () async {
      await syntheticUser();
      final task = await openTask(TaskCategory.admin);

      final result = await predictor.assess(task);

      expect((await tasks.getById(task.id))!.dodgeRisk, result.risk);
    });

    test('assess without saving leaves the task alone', () async {
      await syntheticUser();
      final task = await openTask(TaskCategory.admin);

      await predictor.assess(task, save: false);

      expect((await tasks.getById(task.id))!.dodgeRisk, isNull);
      expect(await predictor.riskFor(task), greaterThan(0.65));
    });
  });

  group('cold start', () {
    test('uses the category dodge rate below 20 outcomes', () async {
      for (var i = 0; i < 5; i++) {
        await finished(TaskCategory.admin, dodged: i != 0); // 4 of 5 dodged
      }

      final admin = await predictor.assess(await openTask(TaskCategory.admin));

      expect(admin.source, RiskSource.rule);
      expect(admin.risk, closeTo(0.8, 1e-9));
      expect(admin.reason, 'You dodge admin tasks 80% of the time.');
      expect(admin.outcomesUsed, 0);
    });

    test('a category with no history starts at 50%', () async {
      await finished(TaskCategory.admin, dodged: true);

      final health = await predictor.assess(
        await openTask(TaskCategory.health),
      );

      expect(health.source, RiskSource.rule);
      expect(health.risk, 0.5);
      expect(health.reason, 'Not enough history yet, so this starts at 50%.');
    });

    test('with no history at all it is 50%', () async {
      final result = await predictor.assess(await openTask(TaskCategory.work));
      expect(result.risk, 0.5);
      expect(result.source, RiskSource.rule);
    });

    test('abandoned counts as a dodge', () async {
      final a = await tasks.create(title: 'A', category: TaskCategory.chores);
      await predictor.recordDecision(a.id);
      await tasks.updateStatus(a.id, TaskStatus.doing);
      await closer.markAbandoned(a.id);
      await finished(TaskCategory.chores, dodged: false);

      final result = await predictor.assess(
        await openTask(TaskCategory.chores),
      );

      expect(result.risk, 0.5); // one abandoned, one done
    });

    test('the model takes over exactly at 20 outcomes', () async {
      for (var i = 0; i < 19; i++) {
        await finished(TaskCategory.admin, dodged: i % 2 == 0);
      }
      expect(
        (await predictor.assess(await openTask(TaskCategory.admin))).source,
        RiskSource.rule,
      );
      expect(await settings.get(SettingsKeys.predictorWeights), isNull);

      await finished(TaskCategory.admin, dodged: true);

      expect(
        (await predictor.assess(await openTask(TaskCategory.admin))).source,
        RiskSource.model,
      );
      expect((await storedModel())['trainedOn'], 20);
    });

    test(
      'outcomes without saved features do not count towards the 20',
      () async {
        for (var i = 0; i < 25; i++) {
          final t = await tasks.create(
            title: 'Old',
            category: TaskCategory.work,
          );
          await outcomes.record(taskId: t.id, result: OutcomeResult.dodged);
        }

        expect(await predictor.retrain(), 0);
        // They still inform the simple rule.
        final result = await predictor.assess(
          await openTask(TaskCategory.work),
        );
        expect(result.source, RiskSource.rule);
        expect(result.risk, 1.0);
      },
    );
  });

  group('training', () {
    test('retrains after every new outcome', () async {
      for (var i = 0; i < 20; i++) {
        await finished(TaskCategory.admin, dodged: i % 3 != 0);
      }
      expect((await storedModel())['trainedOn'], 20);

      await finished(TaskCategory.health, dodged: false);
      expect((await storedModel())['trainedOn'], 21);

      await finished(TaskCategory.health, dodged: false);
      expect((await storedModel())['trainedOn'], 22);
    });

    test('retrain on its own returns how many outcomes it used', () async {
      await syntheticUser(count: 30);
      expect(await predictor.retrain(), 30);
    });

    test('stores the weights with the feature names', () async {
      await syntheticUser(count: 25);

      final model = await storedModel();

      expect(model['names'], featureNames);
      expect((model['weights'] as List), hasLength(featureNames.length));
      expect(model['bias'], isA<num>());
      expect(model['trainedAt'], isA<String>());
    });

    test('forgets stale weights when the history shrinks below 20', () async {
      await syntheticUser(count: 22);
      expect(await settings.get(SettingsKeys.predictorWeights), isNotNull);

      final first = (await outcomes.listAll()).first;
      await tasks.delete(first.taskId);
      await tasks.delete((await outcomes.listAll()).first.taskId);
      await tasks.delete((await outcomes.listAll()).first.taskId);

      expect(await predictor.retrain(), 0);
      expect(await settings.get(SettingsKeys.predictorWeights), isNull);
    });

    test('a failure while learning never stops a task from closing', () async {
      await syntheticUser(count: 25);
      await settings.set(SettingsKeys.predictorWeights, 'not json');
      final task = await openTask(TaskCategory.admin);

      expect(await closer.markDodged(task.id), isTrue);
      expect((await tasks.getById(task.id))!.status, TaskStatus.dodged);
    });
  });

  group('persistence', () {
    test('weights survive an app restart', () async {
      await syntheticUser();
      final task = await openTask(TaskCategory.admin);
      final before = await predictor.assess(task, save: false);

      final restarted = newPredictor();
      final after = await restarted.assess(task, save: false);

      expect(after.source, RiskSource.model);
      expect(after.risk, before.risk);
      expect(after.reason, before.reason);
    });

    test('a model trained on other features is not used', () async {
      await syntheticUser(count: 25);
      final model = await storedModel();
      model['names'] = ['something', 'else'];
      await settings.set(SettingsKeys.predictorWeights, jsonEncode(model));

      final result = await predictor.assess(await openTask(TaskCategory.admin));

      expect(result.source, RiskSource.rule);
    });

    test('corrupt weights fall back to the rule', () async {
      await syntheticUser(count: 25);
      await settings.set(SettingsKeys.predictorWeights, '{broken');

      final result = await predictor.assess(await openTask(TaskCategory.admin));

      expect(result.source, RiskSource.rule);
    });
  });

  group('features saved at decision time', () {
    test(
      'are saved when the user chooses and kept when the task closes',
      () async {
        final task = await tasks.create(
          title: 'Pay rent',
          category: TaskCategory.money,
          createdAt: DateTime(2030, 1, 7, 9),
        );

        await predictor.recordDecision(task.id);
        // Things change after the choice: Gemma writes steps.
        await steps.createAll(task.id, const [
          NewStep(title: 'a', estMinutes: 30),
          NewStep(title: 'b', estMinutes: 30),
        ]);
        await closer.markDone(task.id);

        final saved = outcomes.snapshotOf(
          (await outcomes.listForTask(task.id)).single,
        );
        expect(saved['cat_money'], 1);
        expect(
          saved['step_count'],
          0,
          reason: 'steps did not exist at decision time',
        );
        expect(saved['total_minutes'], 0);
        expect(saved.keys.toSet(), featureNames.toSet());
      },
    );

    test('only the first choice is kept', () async {
      final task = await tasks.create(title: 'T', category: TaskCategory.work);
      await predictor.recordDecision(task.id);
      await steps.createAll(task.id, const [
        NewStep(title: 'a', estMinutes: 60),
      ]);

      await predictor.recordDecision(task.id);
      await closer.markDone(task.id);

      final saved = outcomes.snapshotOf(
        (await outcomes.listForTask(task.id)).single,
      );
      expect(saved['step_count'], 0);
    });

    test(
      'a task closed without a recorded choice still gets features',
      () async {
        final task = await tasks.create(
          title: 'T',
          category: TaskCategory.work,
        );
        await steps.createAll(task.id, const [
          NewStep(title: 'a', estMinutes: 60),
        ]);

        await closer.markAbandoned(task.id);

        final saved = outcomes.snapshotOf(
          (await outcomes.listForTask(task.id)).single,
        );
        expect(saved['cat_work'], 1);
        expect(saved['step_count'], closeTo(1 / 7, 1e-9));
      },
    );

    test('the saved copy is removed once used, and when forgotten', () async {
      final a = await tasks.create(title: 'A', category: TaskCategory.work);
      final b = await tasks.create(title: 'B', category: TaskCategory.work);
      await predictor.recordDecision(a.id);
      await predictor.recordDecision(b.id);
      await closer.markDone(a.id);
      await predictor.forget(b.id);

      expect(
        await settings.get('${SettingsKeys.decisionSnapshotPrefix}${a.id}'),
        isNull,
      );
      expect(
        await settings.get('${SettingsKeys.decisionSnapshotPrefix}${b.id}'),
        isNull,
      );
    });

    test('a missing task records nothing', () async {
      await predictor.recordDecision(9999);
      expect(await settings.getAll(), isEmpty);
    });

    test('rates in the features only use what happened before', () async {
      await finished(TaskCategory.admin, dodged: true);
      await finished(TaskCategory.admin, dodged: true);
      final third = await finished(TaskCategory.admin, dodged: false);

      final snapshots = [
        for (final o in (await outcomes.listForTask(third.id)))
          outcomes.snapshotOf(o),
      ];
      // At the third decision, 2 of 2 earlier admin tasks were dodged.
      expect(snapshots.single['category_dodge_rate'], closeTo(0.5, 1e-9));
    });
  });

  group('features from the live data', () {
    test('count the steps and minutes Gemma produced', () async {
      final task = await tasks.create(title: 'T', category: TaskCategory.work);
      await steps.createAll(task.id, const [
        NewStep(title: 'a', estMinutes: 10),
        NewStep(title: 'b', estMinutes: 20),
      ]);

      final f = await predictor.featuresFor(task);

      expect(f['step_count'], closeTo(2 / 7, 1e-9));
      expect(f['total_minutes'], closeTo(30 / 120, 1e-9));
    });

    test('the recent dodge rate only looks at the last 14 days', () async {
      final now = DateTime(2030, 3, 1);
      final clocked = PredictorService(
        tasks: tasks,
        steps: steps,
        outcomes: outcomes,
        settings: settings,
        now: () => now,
      );
      Future<void> outcome(TaskCategory c, OutcomeResult r, DateTime at) async {
        final t = await tasks.create(title: 'T', category: c);
        await outcomes.record(taskId: t.id, result: r, at: at);
      }

      await outcome(
        TaskCategory.work,
        OutcomeResult.dodged,
        DateTime(2030, 1, 1),
      );
      await outcome(
        TaskCategory.work,
        OutcomeResult.dodged,
        DateTime(2030, 2, 25),
      );
      await outcome(
        TaskCategory.work,
        OutcomeResult.done,
        DateTime(2030, 2, 26),
      );
      await outcome(
        TaskCategory.work,
        OutcomeResult.done,
        DateTime(2030, 2, 27),
      );
      final task = await tasks.create(
        title: 'N',
        category: TaskCategory.health,
      );

      final f = await clocked.featuresFor(task);

      // 1 of 3 recent outcomes dodged: 0.33 - 0.5.
      expect(f['recent_dodge_rate'], closeTo(1 / 3 - 0.5, 1e-9));
      // Health has no history.
      expect(f['category_dodge_rate'], 0);
    });
  });
}
