import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/prompt_jobs.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';

import '../data/test_database.dart';
import '../support/fakes.dart';
import '../support/job_replies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeModelRuntime runtime;
  late GemmaService service;

  setUp(() async {
    db = createTestDatabase();
    runtime = FakeModelRuntime();
    await installModelFixture(db, runtime);
    service = GemmaService(runtime: runtime, settings: SettingsRepository(db));
    Get.put(service);
    await service.started;
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  const shrinkInput = ShrinkInput(title: 'File my tax return');

  group('success', () {
    test('shrinkTask returns a typed result on the first try', () async {
      runtime.responder = scripted([validShrink]);

      final result = await service.shrinkTask(shrinkInput);

      expect(result, isA<JobSuccess<ShrunkTask>>());
      final success = result as JobSuccess<ShrunkTask>;
      expect(success.value.steps, hasLength(3));
      expect(success.retried, isFalse);
      expect(success.rawText, validShrink);
      expect(runtime.calls, hasLength(1));
    });

    test('the other three jobs return typed results too', () async {
      runtime.responder = validResponder();

      final help = await service.helpWithStep(
        const HelpInput(taskTitle: 'Invoice', stepTitle: 'Open the email'),
      );
      final excuse = await service.writeExcuse(
        const ExcuseInput(
          taskTitle: 'Invoice',
          recipient: 'Sam',
          tone: ExcuseTone.polite,
        ),
      );
      final nudge = await service.nudgeWording(
        const NudgeInput(taskTitle: 'Invoice', stepTitle: 'Open the email'),
      );

      expect((help as JobSuccess<StepDraft>).value.draft, contains('Sam'));
      expect((excuse as JobSuccess<ExcuseDraft>).value.shortVariant, 'Busy.');
      expect((nudge as JobSuccess<NudgeWording>).value.firm, isNotEmpty);
    });

    test('streams tokens and reports attempts', () async {
      runtime.responder = scripted([validShrink]);
      final tokens = StringBuffer();
      final attempts = <int>[];

      await service.shrinkTask(
        shrinkInput,
        onToken: tokens.write,
        onAttempt: attempts.add,
      );

      expect(tokens.toString(), validShrink);
      expect(attempts, [0]);
    });

    test('sends the system instruction, prompt and output cap', () async {
      runtime.responder = scripted([validShrink]);

      await service.shrinkTask(shrinkInput);

      final call = runtime.calls.single;
      expect(call.systemInstruction, contains('tiny steps'));
      expect(call.prompt, 'Task: File my tax return');
      expect(call.maxOutputTokens, 400);
    });

    test('tolerates a markdown fence around the JSON', () async {
      runtime.responder = scripted(['```json\n$validShrink\n```']);
      final result = await service.shrinkTask(shrinkInput);
      expect(result, isA<JobSuccess<ShrunkTask>>());
    });
  });

  group('retry and fallback', () {
    test('invalid JSON is retried once with a stricter instruction', () async {
      runtime.responder = scripted(['Sure, here are some steps!', validShrink]);
      final attempts = <int>[];

      final result = await service.shrinkTask(
        shrinkInput,
        onAttempt: attempts.add,
      );

      expect(result, isA<JobSuccess<ShrunkTask>>());
      expect(result.retried, isTrue);
      expect(attempts, [0, 1]);
      final calls = runtime.calls;
      expect(calls, hasLength(2));
      expect(calls[0].systemInstruction, isNot(contains('IMPORTANT')));
      expect(calls[1].systemInstruction, contains('IMPORTANT'));
      expect(calls[1].systemInstruction, contains('no JSON'));
      expect(calls[1].prompt, calls[0].prompt);
    });

    test('a reply that parses but breaks a rule is retried', () async {
      const tooFew = '{"steps":[{"title":"A","estMinutes":1}]}';
      runtime.responder = scripted([tooFew, validShrink]);

      final result = await service.shrinkTask(shrinkInput);

      expect(result, isA<JobSuccess<ShrunkTask>>());
      expect(runtime.calls[1].systemInstruction, contains('3 to 7 steps'));
    });

    test('two bad replies return the raw text as a fallback', () async {
      runtime.responder = scripted(['not json', 'still not json']);

      final result = await service.shrinkTask(shrinkInput);

      expect(result, isA<JobFallback<ShrunkTask>>());
      final fallback = result as JobFallback<ShrunkTask>;
      expect(fallback.rawText, 'still not json');
      expect(fallback.reason, contains('not usable'));
      expect(fallback.retried, isTrue);
      expect(fallback.stopped, isFalse);
      expect(runtime.calls, hasLength(2));
    });

    test('an empty reply never crashes', () async {
      runtime.responder = scripted(['']);
      final result = await service.shrinkTask(shrinkInput);
      expect(result, isA<JobFallback<ShrunkTask>>());
      expect(result.rawText, isEmpty);
    });

    test('a model error becomes a fallback, not an exception', () async {
      runtime.generateError = StateError('out of memory');

      final result = await service.shrinkTask(shrinkInput);

      expect(result, isA<JobFallback<ShrunkTask>>());
      expect((result as JobFallback).reason, contains('out of memory'));
      expect(service.isGenerating.value, isFalse);
    });

    test('an off-limits excuse is retried, then replaced', () async {
      runtime.responder = scripted([
        excuseJson('I was sick all week.'),
        excuseJson('My week was packed with meetings.'),
      ]);

      final result = await service.writeExcuse(
        const ExcuseInput(
          taskTitle: 'Report',
          recipient: 'boss',
          tone: ExcuseTone.polite,
        ),
      );

      expect(result, isA<JobSuccess<ExcuseDraft>>());
      expect(result.retried, isTrue);
    });

    test('an off-limits excuse twice gives a fallback', () async {
      runtime.responder = scripted([excuseJson('I was sick.')]);

      final result = await service.writeExcuse(
        const ExcuseInput(
          taskTitle: 'Report',
          recipient: 'boss',
          tone: ExcuseTone.polite,
        ),
      );

      expect(result, isA<JobFallback<ExcuseDraft>>());
      expect((result as JobFallback).reason, contains('health'));
    });
  });

  group('stopping', () {
    test('stop ends the job with a stopped fallback and no retry', () async {
      runtime.responder = scripted([validShrink]);
      await service.load();
      final model = runtime.models.single..gate = Completer<void>();

      final future = service.shrinkTask(shrinkInput);
      await Future<void>.delayed(Duration.zero);
      await service.stop();
      model.gate!.complete();
      final result = await future;

      expect(result, isA<JobFallback<ShrunkTask>>());
      expect((result as JobFallback).stopped, isTrue);
      expect(model.calls, hasLength(1));
      expect(service.isGenerating.value, isFalse);
    });

    test('a new job after a stop runs normally', () async {
      runtime.responder = scripted([validShrink]);
      await service.stop();

      final result = await service.shrinkTask(shrinkInput);

      expect(result, isA<JobSuccess<ShrunkTask>>());
    });
  });

  group('excuses do not repeat across 5 runs', () {
    test('the history reaches the prompt and a repeat is retried', () async {
      // The model tries to reuse "Excuse A" on the third run.
      final replies = [
        excuseJson('Excuse A: the printer jammed.'),
        excuseJson('Excuse B: my train was delayed.'),
        excuseJson('excuse a - the printer jammed!'),
        excuseJson('Excuse C: I double-booked myself.'),
        excuseJson('Excuse D: the wifi went down.'),
        excuseJson('Excuse E: my laptop updated itself.'),
      ];
      runtime.responder = scripted(replies);

      final used = <String>[];
      for (var run = 0; run < 5; run++) {
        final result = await service.writeExcuse(
          ExcuseInput(
            taskTitle: 'Report',
            recipient: 'boss',
            tone: ExcuseTone.casual,
            previousExcuses: used.reversed.toList(),
          ),
        );
        expect(result, isA<JobSuccess<ExcuseDraft>>(), reason: 'run $run');
        used.add((result as JobSuccess<ExcuseDraft>).value.text);
      }

      expect(used.toSet(), hasLength(5));
      // The third run was retried because its first reply repeated Excuse A.
      expect(runtime.calls, hasLength(6));
      final lastPrompt = runtime.calls.last.prompt;
      expect(lastPrompt, contains('Excuse A'));
      expect(lastPrompt, contains('Excuse D'));
    });
  });
}
