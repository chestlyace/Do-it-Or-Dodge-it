import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/step_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late StepRepository steps;
  late int taskId;

  setUp(() async {
    db = createTestDatabase();
    steps = StepRepository(db);
    taskId = (await TaskRepository(
      db,
    ).create(title: 'T', category: TaskCategory.work)).id;
  });

  tearDown(() => db.close());

  Future<void> addThree() => steps.createAll(taskId, const [
    NewStep(title: 'One', estMinutes: 1),
    NewStep(title: 'Two', estMinutes: 5),
    NewStep(title: 'Three', estMinutes: 10),
  ]);

  test('creates steps in order with positions from 0', () async {
    await addThree();

    final list = await steps.listForTask(taskId);
    expect(list.map((s) => s.title), ['One', 'Two', 'Three']);
    expect(list.map((s) => s.position), [0, 1, 2]);
    expect(list.map((s) => s.estMinutes), [1, 5, 10]);
    expect(list.every((s) => s.doneAt == null), isTrue);
  });

  test('marks a step done and undone', () async {
    await addThree();
    final first = (await steps.listForTask(taskId)).first;
    final at = DateTime(2030, 5, 5, 9);

    await steps.markDone(first.id, at: at);
    expect((await steps.listForTask(taskId)).first.doneAt, at);

    await steps.markUndone(first.id);
    expect((await steps.listForTask(taskId)).first.doneAt, isNull);
  });

  test('nextUndone returns the first step not done, then null', () async {
    await addThree();
    final list = await steps.listForTask(taskId);

    expect((await steps.nextUndone(taskId))!.title, 'One');
    await steps.markDone(list[0].id);
    expect((await steps.nextUndone(taskId))!.title, 'Two');
    await steps.markDone(list[1].id);
    await steps.markDone(list[2].id);
    expect(await steps.nextUndone(taskId), isNull);
  });

  test('saves a draft on a step', () async {
    await addThree();
    final first = (await steps.listForTask(taskId)).first;

    await steps.setDraft(first.id, 'Hi Sam, ...');
    expect((await steps.listForTask(taskId)).first.draftText, 'Hi Sam, ...');
  });

  test('deleteForTask removes only that task\'s steps', () async {
    await addThree();
    final other = await TaskRepository(db)
        .create(title: 'Other', category: TaskCategory.work);
    await steps.createAll(other.id, const [NewStep(title: 'X', estMinutes: 1)]);

    expect(await steps.deleteForTask(taskId), 3);
    expect(await steps.listForTask(taskId), isEmpty);
    expect(await steps.listForTask(other.id), hasLength(1));
  });
}
