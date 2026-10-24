import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/routes/app_routes.dart';

import 'data/test_database.dart';
import 'support/app_harness.dart';
import 'support/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late AppHarness app;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime();
    app = AppHarness(db: db, runtime: runtime, share: FakeShareService());
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  testWidgets('shows an empty state before any task exists', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      expect(find.textContaining('No tasks yet'), findsOneWidget);
    });
  });

  testWidgets('adds a task with a category, note and Other text', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await app.addTask(
        tester,
        'Sort the shed',
        category: 'Other',
        customCategory: 'Garden',
        note: 'Start with the tools',
      );

      final saved = (await TaskRepository(db).listAll()).single;
      expect(saved.title, 'Sort the shed');
      expect(saved.category, TaskCategory.other);
      expect(saved.customCategory, 'Garden');
      expect(saved.note, 'Start with the tools');
      expect(saved.status, TaskStatus.open);

      expect(find.text('Sort the shed'), findsOneWidget);
      expect(find.textContaining('Garden'), findsOneWidget);
      expect(find.text('Open (1)'), findsOneWidget);
    });
  });

  testWidgets('a task needs a title', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);

      await tester.tap(find.text('Add task'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
      await settle(tester);

      expect(find.text('Give the task a title'), findsOneWidget);
      expect(await TaskRepository(db).listAll(), isEmpty);
    });
  });

  testWidgets('picks a due date', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);
      await tester.tap(find.text('Add task'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'Pay rent');

      await tester.tap(find.text('Pick a due date'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
      await settle(tester);

      final saved = (await TaskRepository(db).listAll()).single;
      expect(saved.dueAt, isNotNull);
      expect(find.textContaining('due '), findsOneWidget);
    });
  });

  testWidgets('groups tasks by status', (tester) async {
    await runWithApp(tester, () async {
      final repo = TaskRepository(db);
      final a = await repo.create(title: 'A', category: TaskCategory.work);
      final b = await repo.create(title: 'B', category: TaskCategory.work);
      final c = await repo.create(title: 'C', category: TaskCategory.work);
      await repo.create(title: 'D', category: TaskCategory.work);
      await repo.updateStatus(a.id, TaskStatus.doing);
      await repo.updateStatus(b.id, TaskStatus.done);
      await repo.updateStatus(c.id, TaskStatus.dodged);

      await app.start(tester);

      expect(find.text('Doing (1)'), findsOneWidget);
      expect(find.text('Open (1)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);
      expect(find.text('Dodged (1)'), findsOneWidget);
      expect(find.textContaining('Abandoned'), findsNothing);
    });
  });

  testWidgets('seed button fills the list in debug builds', (tester) async {
    await runWithApp(tester, () async {
      await app.start(tester);

      await tester.tap(find.byTooltip('Seed sample tasks'));
      await settle(tester);

      expect(find.text('File my tax return'), findsOneWidget);
      expect(find.text('Open (6)'), findsOneWidget);
    });
  });

  testWidgets('long-press deletes a task after confirming', (tester) async {
    await runWithApp(tester, () async {
      await TaskRepository(db)
          .create(title: 'Delete me', category: TaskCategory.work);
      await app.start(tester);

      await app.longPress(tester, find.text('Delete me'));
      await tester.tap(find.text('Keep'));
      await settle(tester);
      expect(find.text('Delete me'), findsOneWidget);

      await app.longPress(tester, find.text('Delete me'));
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Delete me'), findsNothing);
      expect(await TaskRepository(db).listAll(), isEmpty);
    });
  });

  testWidgets('tapping a task opens its detail with both buttons', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await TaskRepository(db).create(
        title: 'Pay rent',
        category: TaskCategory.money,
        note: 'Use the banking app',
      );
      await app.start(tester);

      await tester.tap(find.text('Pay rent'));
      await settle(tester);

      expect(Get.currentRoute, Routes.taskDetail);
      expect(find.text('Use the banking app'), findsOneWidget);
      expect(
        find.textContaining('Not enough history yet, so this starts at 50%.'),
        findsOneWidget,
      );
      expect(find.text('Do It'), findsOneWidget);
      expect(find.text('Dodge It'), findsOneWidget);
    });
  });

  testWidgets('opening a task loads the model in the background', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await TaskRepository(db)
          .create(title: 'Pay rent', category: TaskCategory.money);
      await app.start(tester);
      expect(runtime.loadCalls, isEmpty);

      await tester.tap(find.text('Pay rent'));
      await settle(tester);

      expect(runtime.loadCalls, hasLength(1));
      expect(find.text('Model ready'), findsOneWidget);
    });
  });

  testWidgets('a closed task shows its state instead of the buttons', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      final repo = TaskRepository(db);
      final task = await repo.create(title: 'Old', category: TaskCategory.work);
      await repo.updateStatus(task.id, TaskStatus.dodged);
      await app.start(tester);

      await tester.tap(find.text('Old'));
      await settle(tester);

      expect(find.text('This task is dodged.'), findsOneWidget);
      expect(find.text('Do It'), findsNothing);
      expect(runtime.loadCalls, isEmpty);
    });
  });
}
