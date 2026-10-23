import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;

  setUp(() {
    db = createTestDatabase();
    tasks = TaskRepository(db);
  });

  tearDown(() => db.close());

  test('creates a task with open status and reads it back', () async {
    final due = DateTime(2030, 1, 2);
    final created = await tasks.create(
      title: 'Write report',
      category: TaskCategory.work,
      note: 'Q3 numbers',
      dueAt: due,
    );

    final found = await tasks.getById(created.id);
    expect(found, isNotNull);
    expect(found!.title, 'Write report');
    expect(found.note, 'Q3 numbers');
    expect(found.category, TaskCategory.work);
    expect(found.dueAt, due);
    expect(found.status, TaskStatus.open);
    expect(found.dodgeRisk, isNull);
  });

  test('stores free text for the Other category', () async {
    final created = await tasks.create(
      title: 'Tidy shed',
      category: TaskCategory.other,
      customCategory: 'Garden',
    );
    expect((await tasks.getById(created.id))!.customCategory, 'Garden');
  });

  test('status moves open to doing to done', () async {
    final task = await tasks.create(title: 'A', category: TaskCategory.chores);

    await tasks.updateStatus(task.id, TaskStatus.doing);
    expect((await tasks.getById(task.id))!.status, TaskStatus.doing);

    await tasks.updateStatus(task.id, TaskStatus.done);
    expect((await tasks.getById(task.id))!.status, TaskStatus.done);
  });

  test('lists all tasks newest first and filters by status', () async {
    final older = await tasks.create(
      title: 'Older',
      category: TaskCategory.work,
      createdAt: DateTime(2030, 1, 1),
    );
    final newer = await tasks.create(
      title: 'Newer',
      category: TaskCategory.work,
      createdAt: DateTime(2030, 1, 2),
    );
    await tasks.updateStatus(older.id, TaskStatus.done);

    expect((await tasks.listAll()).map((t) => t.id), [newer.id, older.id]);
    expect((await tasks.listByStatus(TaskStatus.done)).map((t) => t.id), [
      older.id,
    ]);
  });

  test('updates fields and the dodge risk', () async {
    final task = await tasks.create(title: 'A', category: TaskCategory.money);

    await tasks.update(task.copyWith(title: 'B'));
    await tasks.setDodgeRisk(task.id, 0.7);

    final found = (await tasks.getById(task.id))!;
    expect(found.title, 'B');
    expect(found.dodgeRisk, 0.7);
  });

  test('delete removes the task', () async {
    final task = await tasks.create(title: 'A', category: TaskCategory.study);
    expect(await tasks.delete(task.id), 1);
    expect(await tasks.getById(task.id), isNull);
  });

  test('watchAll emits when a task is added', () async {
    final first = tasks.watchAll().first;
    expect(await first, isEmpty);

    final next = tasks.watchAll().skip(1).first;
    await tasks.create(title: 'A', category: TaskCategory.family);
    expect((await next).single.title, 'A');
  });
}
