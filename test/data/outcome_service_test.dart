import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';
import 'package:do_it_or_dodge_it/app/services/outcome_service.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;
  late OutcomeRepository outcomes;
  late OutcomeService service;
  late int taskId;

  setUp(() async {
    db = createTestDatabase();
    tasks = TaskRepository(db);
    outcomes = OutcomeRepository(db);
    service = OutcomeService(tasks: tasks, outcomes: outcomes);
    taskId = (await tasks.create(title: 'T', category: TaskCategory.work)).id;
  });

  tearDown(() => db.close());

  test('markDone closes the task and logs a done outcome', () async {
    expect(await service.markDone(taskId), isTrue);

    expect((await tasks.getById(taskId))!.status, TaskStatus.done);
    final logged = await outcomes.listForTask(taskId);
    expect(logged.single.result, OutcomeResult.done);
  });

  test('markDodged closes the task and logs a dodged outcome', () async {
    expect(await service.markDodged(taskId), isTrue);

    expect((await tasks.getById(taskId))!.status, TaskStatus.dodged);
    expect(
      (await outcomes.listForTask(taskId)).single.result,
      OutcomeResult.dodged,
    );
  });

  test('a task is only closed once', () async {
    await service.markDodged(taskId);

    expect(await service.markDodged(taskId), isFalse);
    expect(await service.markDone(taskId), isFalse);

    expect((await tasks.getById(taskId))!.status, TaskStatus.dodged);
    expect(await outcomes.listForTask(taskId), hasLength(1));
  });

  test('a missing task logs nothing', () async {
    expect(await service.markDone(9999), isFalse);
    expect(await outcomes.listAll(), isEmpty);
  });

  test('a doing task can be closed', () async {
    await tasks.updateStatus(taskId, TaskStatus.doing);
    expect(await service.markDone(taskId), isTrue);
  });

  test('watchHistory joins outcomes with their tasks, newest first', () async {
    final other = await tasks.create(
      title: 'Other',
      category: TaskCategory.health,
    );
    await outcomes.record(
      taskId: taskId,
      result: OutcomeResult.done,
      at: DateTime(2030, 1, 1),
    );
    await outcomes.record(
      taskId: other.id,
      result: OutcomeResult.dodged,
      at: DateTime(2030, 1, 2),
    );

    final history = await outcomes.watchHistory().first;

    expect(history.map((e) => e.task.title), ['Other', 'T']);
    expect(history.map((e) => e.outcome.result), [
      OutcomeResult.dodged,
      OutcomeResult.done,
    ]);
  });

  test('watchById emits the task, then null after it is deleted', () async {
    final stream = tasks.watchById(taskId);
    expect((await stream.first)!.id, taskId);

    final next = stream.skip(1).first;
    await tasks.delete(taskId);
    expect(await next, isNull);
  });
}
