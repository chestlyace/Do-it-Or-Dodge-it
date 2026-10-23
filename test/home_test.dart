import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/main.dart';

import 'data/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  testWidgets('seed button fills Home and tapping a task advances it', (
    tester,
  ) async {
    // Drift streams use timers; run in real async to let them settle.
    await tester.runAsync(() async {
      await tester.pumpWidget(DoItOrDodgeItApp(database: db));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('No tasks yet'), findsOneWidget);

      await tester.tap(find.text('Seed sample tasks'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('File my tax return'), findsOneWidget);
      expect(find.text('open'), findsWidgets);

      await tester.tap(find.text('Go for a 20 minute run'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('doing'), findsOneWidget);
    });
  });
}
