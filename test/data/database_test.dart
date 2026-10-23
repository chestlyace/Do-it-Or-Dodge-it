import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/db/seed_data.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/excuse_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  test(
    'deleting a task removes its steps, outcomes, excuses and nudges',
    () async {
      final db = createTestDatabase();
      addTearDown(db.close);
      final tasks = TaskRepository(db);
      final steps = StepRepository(db);
      final outcomes = OutcomeRepository(db);
      final excuses = ExcuseRepository(db);
      final nudges = NudgeRepository(db);

      final doomed = await tasks.create(
        title: 'A',
        category: TaskCategory.work,
      );
      final kept = await tasks.create(title: 'B', category: TaskCategory.work);
      for (final id in [doomed.id, kept.id]) {
        await steps.createAll(id, const [NewStep(title: 's', estMinutes: 1)]);
        await outcomes.record(taskId: id, result: OutcomeResult.dodged);
        await excuses.create(
          taskId: id,
          recipientLabel: 'boss',
          tone: 'Polite',
          text: 'x',
        );
        await nudges.create(
          taskId: id,
          fireAt: DateTime(2030),
          level: NudgeLevel.gentle,
          message: 'm',
          notificationId: id,
        );
      }

      await tasks.delete(doomed.id);

      expect(await steps.listForTask(doomed.id), isEmpty);
      expect(await outcomes.listForTask(doomed.id), isEmpty);
      expect(await excuses.listForTask(doomed.id), isEmpty);
      expect(await nudges.listForTask(doomed.id), isEmpty);

      expect(await steps.listForTask(kept.id), hasLength(1));
      expect(await outcomes.listForTask(kept.id), hasLength(1));
      expect(await excuses.listForTask(kept.id), hasLength(1));
      expect(await nudges.listForTask(kept.id), hasLength(1));
    },
  );

  test('data survives closing and reopening the database file', () async {
    final dir = Directory.systemTemp.createTempSync('dido_db_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    var db = AppDatabase(NativeDatabase(file));
    final created = await TaskRepository(db)
        .create(title: 'Persist me', category: TaskCategory.health);
    await TaskRepository(db).updateStatus(created.id, TaskStatus.doing);
    await TaskRepository(db).updateStatus(created.id, TaskStatus.done);
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final reopened = await TaskRepository(db).getById(created.id);
    expect(reopened!.title, 'Persist me');
    expect(reopened.status, TaskStatus.done);
  });

  test('seed inserts sample tasks, some with steps', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final tasks = TaskRepository(db);
    final steps = StepRepository(db);

    await seedSampleTasks(tasks, steps, now: DateTime(2030, 1, 1));

    final all = await tasks.listAll();
    expect(all, hasLength(6));
    expect(all.every((t) => t.status == TaskStatus.open), isTrue);
    expect(
      all.where((t) => t.category == TaskCategory.other).single.customCategory,
      'Garden',
    );
    final withSteps = [
      for (final t in all)
        if ((await steps.listForTask(t.id)).isNotEmpty) t,
    ];
    expect(withSteps, hasLength(1));
  });
}
