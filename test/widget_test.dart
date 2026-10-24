import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';
import 'package:do_it_or_dodge_it/app/services/background_service.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';
import 'package:do_it_or_dodge_it/app/services/nudge_service.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';
import 'package:do_it_or_dodge_it/app/services/predictor_service.dart';
import 'package:do_it_or_dodge_it/app/services/share_service.dart';
import 'package:do_it_or_dodge_it/main.dart';

import 'data/test_database.dart';
import 'support/fakes.dart';

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

  Widget app() => DoItOrDodgeItApp(
    database: db,
    modelRuntime: runtime,
    deviceInfo: FakeDeviceInfoSource(),
    notifications: FakeNotificationGateway(),
    backgroundScheduler: FakeBackgroundScheduler(),
    shareService: FakeShareService(),
  );

  testWidgets('registers every service at startup', (tester) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(app());
      await settle(tester);

      expect(Get.isRegistered<GemmaService>(), isTrue);
      expect(Get.isRegistered<PredictorService>(), isTrue);
      expect(Get.isRegistered<NudgeService>(), isTrue);
      expect(Get.isRegistered<ShareService>(), isTrue);
      expect(Get.isRegistered<BackgroundService>(), isTrue);
      expect(Get.isRegistered<OutcomeService>(), isTrue);
    });
  });

  testWidgets('task screens show a clear message when opened without a task', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(app());
      await settle(tester);

      for (final route in [Routes.taskDetail, Routes.doIt, Routes.dodgeIt]) {
        Get.toNamed(route);
        await settle(tester);
        expect(
          find.text('This task could not be found.'),
          findsOneWidget,
          reason: route,
        );
        Get.back();
        await settle(tester);
      }
    });
  });

  testWidgets('History and Settings open from Home', (tester) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(app());
      await settle(tester);

      await tester.tap(find.byTooltip('History'));
      await settle(tester);
      expect(find.textContaining('Nothing here yet'), findsOneWidget);
      Get.back();
      await settle(tester);

      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);
      expect(find.text('Settings placeholder'), findsOneWidget);
    });
  });
}
