import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';
import 'package:do_it_or_dodge_it/app/services/model_runtime.dart';
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

  testWidgets('long-pressing the Home title opens the benchmark', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(
        DoItOrDodgeItApp(
          database: db,
          modelRuntime: runtime,
          deviceInfo: FakeDeviceInfoSource(),
          notifications: FakeNotificationGateway(),
          backgroundScheduler: FakeBackgroundScheduler(),
        ),
      );
      await settle(tester);

      // The long-press timer runs in real time inside runAsync.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Do It or Dodge It')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await gesture.up();
      await settle(tester);

      expect(Get.currentRoute, Routes.benchmark);
      expect(find.text('Benchmark'), findsOneWidget);
    });
  });

  testWidgets('runs the fixed prompt and shows the reply and numbers', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await tester.pumpWidget(
        DoItOrDodgeItApp(
          database: db,
          modelRuntime: runtime,
          deviceInfo: FakeDeviceInfoSource(),
          notifications: FakeNotificationGateway(),
          backgroundScheduler: FakeBackgroundScheduler(),
        ),
      );
      await settle(tester);
      Get.toNamed(Routes.benchmark);
      await settle(tester);

      await tester.tap(find.text('CPU only'));
      await tester.pump();
      await tester.tap(find.text('Run'));
      await settle(tester);

      expect(runtime.loadCalls.single.backend, ModelBackend.cpu);
      expect(find.text('abc'), findsOneWidget);
      expect(find.textContaining('backend active: cpu'), findsOneWidget);
      expect(find.textContaining('tokens: 3'), findsOneWidget);
    });
  });
}
