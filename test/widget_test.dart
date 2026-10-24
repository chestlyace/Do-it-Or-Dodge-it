import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';
import 'package:do_it_or_dodge_it/app/services/background_service.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';
import 'package:do_it_or_dodge_it/app/services/nudge_service.dart';
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

  testWidgets('registers every service at startup', (tester) async {
    await tester.pumpWidget(
      DoItOrDodgeItApp(
        database: db,
        modelRuntime: runtime,
        deviceInfo: FakeDeviceInfoSource(),
      ),
    );
    await tester.pumpAndSettle();

    expect(Get.isRegistered<GemmaService>(), isTrue);
    expect(Get.isRegistered<PredictorService>(), isTrue);
    expect(Get.isRegistered<NudgeService>(), isTrue);
    expect(Get.isRegistered<ShareService>(), isTrue);
    expect(Get.isRegistered<BackgroundService>(), isTrue);
  });

  testWidgets('every module route opens its placeholder', (tester) async {
    await tester.pumpWidget(
      DoItOrDodgeItApp(
        database: db,
        modelRuntime: runtime,
        deviceInfo: FakeDeviceInfoSource(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);

    const routes = {
      Routes.taskDetail: 'Task detail placeholder',
      Routes.doIt: 'Do It placeholder',
      Routes.dodgeIt: 'Dodge It placeholder',
      Routes.history: 'History placeholder',
      Routes.settings: 'Settings placeholder',
    };

    for (final entry in routes.entries) {
      Get.toNamed(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      Get.back();
      await tester.pumpAndSettle();
    }
  });
}
