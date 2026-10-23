import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/nudge_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late NudgeRepository nudges;
  late int taskId;

  setUp(() async {
    db = createTestDatabase();
    nudges = NudgeRepository(db);
    taskId = (await TaskRepository(
      db,
    ).create(title: 'T', category: TaskCategory.work)).id;
  });

  tearDown(() => db.close());

  Future<Nudge> add(DateTime at, {NudgeLevel level = NudgeLevel.gentle}) {
    return nudges.create(
      taskId: taskId,
      fireAt: at,
      level: level,
      message: 'Open the file',
      notificationId: at.millisecondsSinceEpoch % 100000,
    );
  }

  test('creates a nudge that is neither fired nor opened', () async {
    final nudge = await add(DateTime(2030, 1, 1, 10), level: NudgeLevel.firm);

    final found = await nudges.getById(nudge.id);
    expect(found!.level, NudgeLevel.firm);
    expect(found.message, 'Open the file');
    expect(found.fired, isFalse);
    expect(found.opened, isFalse);
  });

  test('lists a task\'s nudges soonest first', () async {
    final later = await add(DateTime(2030, 1, 2));
    final sooner = await add(DateTime(2030, 1, 1));

    expect((await nudges.listForTask(taskId)).map((n) => n.id), [
      sooner.id,
      later.id,
    ]);
  });

  test('markFired and markOpened update the flags', () async {
    final nudge = await add(DateTime(2030, 1, 1));

    await nudges.markFired(nudge.id);
    await nudges.markOpened(nudge.id);

    final found = (await nudges.getById(nudge.id))!;
    expect(found.fired, isTrue);
    expect(found.opened, isTrue);
  });

  test('listPending leaves out fired nudges', () async {
    final fired = await add(DateTime(2030, 1, 1));
    final pending = await add(DateTime(2030, 1, 2));
    await nudges.markFired(fired.id);

    expect((await nudges.listPending()).map((n) => n.id), [pending.id]);
  });

  test('deletePendingForTask keeps fired nudges', () async {
    final fired = await add(DateTime(2030, 1, 1));
    await add(DateTime(2030, 1, 2));
    await nudges.markFired(fired.id);

    expect(await nudges.deletePendingForTask(taskId), 1);
    expect((await nudges.listAll()).map((n) => n.id), [fired.id]);
  });
}
