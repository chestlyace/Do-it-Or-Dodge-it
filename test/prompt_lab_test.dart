import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/modules/prompt_lab/controllers/prompt_lab_controller.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';
import 'package:do_it_or_dodge_it/main.dart';

import 'data/test_database.dart';
import 'support/fakes.dart';
import 'support/job_replies.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;

  setUp(() async {
    db = createTestDatabase();
    runtime = FakeModelRuntime();
    await installModelFixture(db, runtime);
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<PromptLabController> openLab(WidgetTester tester) async {
    await tester.pumpWidget(
      DoItOrDodgeItApp(
        database: db,
        modelRuntime: runtime,
        deviceInfo: FakeDeviceInfoSource(),
      ),
    );
    await settle(tester);
    Get.toNamed(Routes.promptLab);
    await settle(tester);
    return Get.find<PromptLabController>();
  }

  testWidgets('the benchmark screen links to the prompt lab', (tester) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(
        DoItOrDodgeItApp(
          database: db,
          modelRuntime: runtime,
          deviceInfo: FakeDeviceInfoSource(),
        ),
      );
      await settle(tester);
      Get.toNamed(Routes.benchmark);
      await settle(tester);

      await tester.tap(find.byTooltip('Prompt lab'));
      await settle(tester);

      expect(find.text('Prompt lab'), findsWidgets);
      expect(Get.currentRoute, Routes.promptLab);
    });
  });

  testWidgets('runs a job and shows the parsed result and the raw text', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.responder = scripted([validShrink]);
      await openLab(tester);

      await tester.tap(find.text('Run'));
      await settle(tester);

      expect(find.text('Parsed'), findsWidgets);
      expect(
        find.textContaining('1. Open the website (1 min)'),
        findsOneWidget,
      );
      expect(find.textContaining('"estMinutes":1'), findsOneWidget);
    });
  });

  testWidgets('broken output shows the reason and the raw text', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.responder = scripted(['this is not json']);
      await openLab(tester);

      await tester.tap(find.text('Run'));
      await settle(tester);

      expect(find.textContaining('not usable'), findsOneWidget);
      expect(find.text('this is not json'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('five excuse runs for one recipient are all different', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.responder = validResponder();
      final lab = await openLab(tester);
      lab.job.value = LabJob.writeExcuse;
      await tester.pump();

      for (var i = 0; i < 5; i++) {
        await lab.run();
      }

      final history = lab.currentHistory;
      expect(history, hasLength(5));
      expect(history.toSet(), hasLength(5));
      // Each later prompt carried the earlier excuses.
      expect(runtime.calls.last.prompt, contains('number 4'));
      expect(runtime.calls.last.prompt, contains('number 1'));
    });
  });

  testWidgets('runs all four jobs on the 20 samples and reports pass rates', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.responder = validResponder();
      final lab = await openLab(tester);

      await lab.runSamples(LabJob.values);

      final summary = lab.batchSummary.value!;
      for (final job in LabJob.values) {
        expect(summary, contains('${job.jobName}: 20/20 parsed'));
      }
      expect(lab.hasReport, isTrue);
      expect(runtime.calls.length, 80);
      expect(lab.running.value, isFalse);
    });
  });

  testWidgets('the batch counts failures in the pass rate', (tester) async {
    await runWithApp(tester, () async {
      runtime.responder = (call) => 'broken';
      final lab = await openLab(tester);

      await lab.runSamples([LabJob.shrinkTask]);

      expect(lab.batchSummary.value, 'shrinkTask: 0/20 parsed');
    });
  });
}
