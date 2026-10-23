import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/outcome_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late OutcomeRepository outcomes;
  late int taskId;

  setUp(() async {
    db = createTestDatabase();
    outcomes = OutcomeRepository(db);
    taskId = (await TaskRepository(
      db,
    ).create(title: 'T', category: TaskCategory.work)).id;
  });

  tearDown(() => db.close());

  test('records an outcome with its feature snapshot', () async {
    final recorded = await outcomes.record(
      taskId: taskId,
      result: OutcomeResult.dodged,
      featureSnapshot: {'stepCount': 4, 'category': 'work'},
    );

    final list = await outcomes.listForTask(taskId);
    expect(list.single.id, recorded.id);
    expect(list.single.result, OutcomeResult.dodged);
    expect(outcomes.snapshotOf(list.single), {
      'stepCount': 4,
      'category': 'work',
    });
  });

  test('snapshot defaults to an empty map', () async {
    final recorded = await outcomes.record(
      taskId: taskId,
      result: OutcomeResult.done,
    );
    expect(outcomes.snapshotOf(recorded), isEmpty);
  });

  test('counts outcomes by result', () async {
    await outcomes.record(taskId: taskId, result: OutcomeResult.done);
    await outcomes.record(taskId: taskId, result: OutcomeResult.done);
    await outcomes.record(taskId: taskId, result: OutcomeResult.dodged);

    expect(await outcomes.countByResult(OutcomeResult.done), 2);
    expect(await outcomes.countByResult(OutcomeResult.dodged), 1);
    expect(await outcomes.countByResult(OutcomeResult.abandoned), 0);
  });

  test('lists all outcomes newest first', () async {
    final old = await outcomes.record(
      taskId: taskId,
      result: OutcomeResult.done,
      at: DateTime(2030, 1, 1),
    );
    final recent = await outcomes.record(
      taskId: taskId,
      result: OutcomeResult.dodged,
      at: DateTime(2030, 1, 2),
    );

    expect((await outcomes.listAll()).map((o) => o.id), [recent.id, old.id]);
  });
}
