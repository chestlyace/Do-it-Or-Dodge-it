import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/core/utils/nudge_planner.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/data/models/prompt_jobs.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/excuse_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/services/data_reset_service.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';
import 'package:do_it_or_dodge_it/app/services/model_runtime.dart';
import 'package:do_it_or_dodge_it/app/services/nudge_service.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';
import 'package:do_it_or_dodge_it/app/services/pregenerate_job.dart';
import 'package:do_it_or_dodge_it/app/services/pregenerated_excuses.dart';

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
  late FakeModelRuntime runtime;
  late FakeNotificationGateway gateway;
  late GemmaService gemma;
  late NudgeService nudgeService;
  late PregeneratedExcuses pregenerated;

  setUp(() async {
    db = createTestDatabase();
    tasks = TaskRepository(db);
    steps = StepRepository(db);
    nudges = NudgeRepository(db);
    outcomes = OutcomeRepository(db);
    settings = SettingsRepository(db);
    runtime = FakeModelRuntime()..responder = validResponder();
    await installModelFixture(db, runtime);
    gateway = FakeNotificationGateway();
    gemma = GemmaService(runtime: runtime, settings: settings);
    Get.put(gemma);
    await gemma.started;
    final closer = OutcomeService(tasks: tasks, outcomes: outcomes);
    nudgeService = NudgeService(
      tasks: tasks,
      steps: steps,
      nudges: nudges,
      settings: settings,
      outcomes: closer,
      gateway: gateway,
      gemma: gemma,
      now: () => start,
    );
    closer.onClosed = nudgeService.cancelFor;
    pregenerated = PregeneratedExcuses(settings);
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<Task> task(
    String title, {
    TaskStatus status = TaskStatus.open,
    bool withSteps = false,
  }) async {
    final t = await tasks.create(
      title: title,
      category: TaskCategory.work,
      createdAt: start,
    );
    if (withSteps) {
      await steps.createAll(t.id, const [
        NewStep(title: 'Open the app', estMinutes: 1),
        NewStep(title: 'Pay', estMinutes: 5),
      ]);
    }
    await tasks.updateStatus(t.id, status);
    return (await tasks.getById(t.id))!;
  }

  PregenerateJob job({int maxTasks = 8}) => PregenerateJob(
    tasks: tasks,
    steps: steps,
    nudges: nudgeService,
    gemma: gemma,
    excuses: pregenerated,
    maxTasks: maxTasks,
  );

  group('max nudges per day', () {
    final now = DateTime(2030, 1, 7, 10);
    final due = DateTime(2030, 1, 20);

    Map<String, int> perDay(List<PlannedNudge> planned) {
      final counts = <String, int>{};
      for (final n in planned) {
        final key = '${n.fireAt.month}-${n.fireAt.day}';
        counts[key] = (counts[key] ?? 0) + 1;
      }
      return counts;
    }

    List<PlannedNudge> plan(double risk, int cap) =>
        planNudges(now: now, due: due, risk: risk, maxPerDay: cap);

    test('can only lower what the risk band allows, per calendar day', () {
      // The 24-hour window covers Monday afternoon and Tuesday morning.
      expect(perDay(plan(0.9, 6)).values.reduce((a, b) => a > b ? a : b), 5);
      expect(perDay(plan(0.9, 3)), {'1-7': 3, '1-8': 1});
      expect(perDay(plan(0.9, 1)), {'1-7': 1, '1-8': 1});
      // A high cap does not give a low risk task more than its band.
      expect(plan(0.1, 6), hasLength(2));
      expect(perDay(plan(0.1, 1)), {'1-7': 1, '1-8': 1});
    });

    test('is clamped between 1 and 6', () {
      expect(perDay(plan(0.9, 0)).values.every((c) => c == 1), isTrue);
      expect(plan(0.9, 99), plan(0.9, 6));
    });

    test('the nudge service reads the setting', () async {
      await settings.set(SettingsKeys.maxNudgesPerDay, '2');
      final t = await task('A', status: TaskStatus.doing, withSteps: true);
      await tasks.setDodgeRisk(t.id, 0.9);

      await nudgeService.plan((await tasks.getById(t.id))!);

      final perDay = <String, int>{};
      for (final n in await nudges.listForTask(t.id)) {
        final k = '${n.fireAt.month}-${n.fireAt.day}';
        perDay[k] = (perDay[k] ?? 0) + 1;
      }
      expect(perDay.values.every((c) => c <= 2), isTrue);
      expect(perDay, isNotEmpty);
    });

    test('a bad value is ignored', () async {
      await settings.set(SettingsKeys.maxNudgesPerDay, 'lots');
      final t = await task('A', status: TaskStatus.doing, withSteps: true);
      await tasks.setDodgeRisk(t.id, 0.9);

      expect(await nudgeService.plan((await tasks.getById(t.id))!), 6);
    });
  });

  group('pre-generation', () {
    test(
      'writes notification text and a general excuse ahead of time',
      () async {
        final doing = await task(
          'Pay rent',
          status: TaskStatus.doing,
          withSteps: true,
        );
        final open = await task('Call the bank');
        await tasks.setDodgeRisk(doing.id, 0.5);
        await nudgeService.plan(
          (await tasks.getById(doing.id))!,
          allowModel: false,
        );

        final result = await job().run();

        expect(result.tasks, 2);
        expect(result.nudgeTexts, 1);
        expect(result.excuses, 2);
        expect(
          await nudgeService.hasWording(
            doing.id,
            (await steps.nextUndone(doing.id))!.id,
          ),
          isTrue,
        );
        final ready = await pregenerated.read(open.id);
        expect(ready, isNotNull);
        expect(ready!.text, startsWith('My week got away from me'));
        expect(await pregenerated.has(doing.id), isTrue);
      },
    );

    test('the excuse is general and polite', () async {
      await task('Call the bank');

      await job().run();

      final prompt = runtime.calls.single.prompt;
      expect(prompt, contains('This is for: $genericRecipient'));
      expect(prompt, contains('Tone: Polite'));
    });

    test('puts the new text into notifications already scheduled', () async {
      final doing = await task(
        'Pay rent',
        status: TaskStatus.doing,
        withSteps: true,
      );
      await tasks.setDodgeRisk(doing.id, 0.5);
      await nudgeService.plan(
        (await tasks.getById(doing.id))!,
        allowModel: false,
      );
      expect(
        gateway.scheduled.values.every((n) => n.body.contains('Open the app')),
        isTrue,
      );

      await job().run();

      expect(gateway.scheduled, isNotEmpty);
      for (final n in gateway.scheduled.values) {
        expect(n.body, isNot(contains('Ready for a tiny step')));
      }
    });

    test('does not write the same thing twice', () async {
      final doing = await task(
        'Pay rent',
        status: TaskStatus.doing,
        withSteps: true,
      );
      await tasks.setDodgeRisk(doing.id, 0.5);
      await job().run();
      final calls = runtime.calls.length;

      final second = await job().run();

      expect(second.nudgeTexts, 0);
      expect(second.excuses, 0);
      expect(runtime.calls.length, calls);
    });

    test('leaves closed tasks alone', () async {
      await task('Done', status: TaskStatus.done);
      await task('Dodged', status: TaskStatus.dodged);

      final result = await job().run();

      expect(result.tasks, 0);
      expect(runtime.calls, isEmpty);
    });

    test('keeps a run short', () async {
      for (var i = 0; i < 5; i++) {
        await task('T$i');
      }

      final result = await job(maxTasks: 3).run();

      expect(result.tasks, 3);
      expect(result.excuses, 3);
    });

    test('frees the model when it is done', () async {
      await task('Call the bank');

      await job().run();

      expect(gemma.isLoaded.value, isFalse);
      expect(runtime.models.single.closed, isTrue);
    });

    test('does nothing without a downloaded model', () async {
      runtime.files.clear();
      await gemma.refreshInstallState();
      await task('Call the bank');

      final result = await job().run();

      expect(result.excuses, 0);
      expect(runtime.calls, isEmpty);
      expect(runtime.loadCalls, isEmpty);
    });

    test('bad model output or a model that cannot load never throws', () async {
      await task('A');
      runtime.responder = scripted(['not json']);
      expect((await job().run()).excuses, 0);

      runtime.failingBackends.addAll(ModelBackend.values);
      expect((await job().run()).excuses, 0);
    });

    test('a ready-made excuse can be used up', () async {
      final t = await task('A');
      await job().run();
      expect(await pregenerated.has(t.id), isTrue);

      await pregenerated.consume(t.id);

      expect(await pregenerated.read(t.id), isNull);
    });
  });

  group('clearing data', () {
    test(
      'removes tasks, history and what was learned, keeps the rest',
      () async {
        final doing = await task(
          'Pay rent',
          status: TaskStatus.doing,
          withSteps: true,
        );
        await tasks.setDodgeRisk(doing.id, 0.5);
        await nudgeService.plan((await tasks.getById(doing.id))!);
        final closed = await task('Old');
        await outcomes.record(taskId: closed.id, result: OutcomeResult.dodged);
        await ExcuseRepository(db).create(
          taskId: closed.id,
          recipientLabel: 'boss',
          tone: 'Polite',
          text: 'x',
        );
        await settings.set(SettingsKeys.predictorWeights, '{}');
        await settings.set('${SettingsKeys.decisionSnapshotPrefix}1', '{}');
        await settings.set('${SettingsKeys.nudgeWordingPrefix}1:1', '{}');
        await pregenerated.write(
          closed.id,
          const ExcuseDraft(text: 'a', shortVariant: 'b'),
        );
        await settings.set(SettingsKeys.quietHoursStart, '22:00');
        await settings.set(SettingsKeys.wifiOnly, 'false');
        await settings.set(SettingsKeys.maxNudgesPerDay, '3');
        expect(gateway.scheduled, isNotEmpty);

        await DataResetService(
          tasks: tasks,
          settings: settings,
          nudges: nudgeService,
        ).clearUserData();

        expect(await tasks.listAll(), isEmpty);
        expect(await steps.listForTask(doing.id), isEmpty);
        expect(await outcomes.listAll(), isEmpty);
        expect(await nudges.listAll(), isEmpty);
        expect(await ExcuseRepository(db).listForTask(closed.id), isEmpty);
        expect(gateway.scheduled, isEmpty);

        final left = await settings.getAll();
        expect(
          left.keys.any(
            (k) => k.startsWith(SettingsKeys.decisionSnapshotPrefix),
          ),
          isFalse,
        );
        expect(
          left.keys.any((k) => k.startsWith(SettingsKeys.nudgeWordingPrefix)),
          isFalse,
        );
        expect(
          left.keys.any((k) => k.startsWith(SettingsKeys.pregenExcusePrefix)),
          isFalse,
        );
        expect(left.containsKey(SettingsKeys.predictorWeights), isFalse);
        // Kept: the model and the preferences.
        expect(left[SettingsKeys.modelId], GemmaModelOption.gemma4E2B.id);
        expect(left[SettingsKeys.quietHoursStart], '22:00');
        expect(left[SettingsKeys.wifiOnly], 'false');
        expect(left[SettingsKeys.maxNudgesPerDay], '3');
      },
    );

    test('is fine when there is nothing to clear', () async {
      await DataResetService(
        tasks: tasks,
        settings: settings,
        nudges: nudgeService,
      ).clearUserData();
      expect(await tasks.listAll(), isEmpty);
    });
  });

  group('deleting the model', () {
    test('removes the file, forgets it and asks for it again', () async {
      await gemma.load();
      expect(gemma.installState.value, ModelInstallState.installed);

      await gemma.deleteModel();

      expect(runtime.uninstalled, [GemmaModelOption.gemma4E2B.fileName]);
      expect(gemma.installState.value, ModelInstallState.notInstalled);
      expect(gemma.installed.value, isNull);
      expect(gemma.isLoaded.value, isFalse);
      expect(runtime.models.single.closed, isTrue);
      for (final key in [
        SettingsKeys.modelId,
        SettingsKeys.modelPath,
        SettingsKeys.modelChecksum,
        SettingsKeys.modelVersion,
      ]) {
        expect(await settings.get(key), isNull, reason: key);
      }
      await expectLater(gemma.load(), throwsStateError);
    });

    test('a later check sees no model', () async {
      await gemma.deleteModel();
      await gemma.refreshInstallState();
      expect(gemma.installState.value, ModelInstallState.notInstalled);
    });

    test('works even if the file is already gone', () async {
      runtime.files.clear();
      await gemma.deleteModel();
      expect(gemma.installState.value, ModelInstallState.notInstalled);
    });
  });

  group('a phone that cannot load the model', () {
    test('gets a clear message, not a raw error', () async {
      runtime.failingBackends.addAll(ModelBackend.values);

      await expectLater(
        gemma.load(),
        throwsA(
          isA<ModelLoadException>().having(
            (e) => e.toString(),
            'message',
            contains('could not load the model'),
          ),
        ),
      );
    });

    test('the technical detail is kept for bug reports', () async {
      runtime.failingBackends.addAll(ModelBackend.values);
      try {
        await gemma.load();
        fail('expected a ModelLoadException');
      } on ModelLoadException catch (e) {
        expect(e.detail, contains('GPU'));
        expect(e.detail, contains('CPU'));
      }
    });

    test('a prompt job explains it instead of crashing', () async {
      runtime.failingBackends.addAll(ModelBackend.values);

      final result = await gemma.shrinkTask(const ShrinkInput(title: 'T'));

      expect(result, isA<JobFallback<ShrunkTask>>());
      expect((result as JobFallback).reason, ModelLoadException.message);
    });

    test('a GPU failure alone still works on the CPU', () async {
      runtime.failingBackends.add(ModelBackend.auto);
      await gemma.load();
      expect(gemma.activeBackend.value, 'cpu');
      expect(gemma.fellBackToCpu.value, isTrue);
    });
  });
}
