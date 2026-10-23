import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/excuse_repository.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/task_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late ExcuseRepository excuses;
  late int taskId;

  setUp(() async {
    db = createTestDatabase();
    excuses = ExcuseRepository(db);
    taskId = (await TaskRepository(
      db,
    ).create(title: 'T', category: TaskCategory.work)).id;
  });

  tearDown(() => db.close());

  Future<void> add(String recipient, String text, DateTime at) {
    return excuses.create(
      taskId: taskId,
      recipientLabel: recipient,
      tone: 'Polite',
      text: text,
      createdAt: at,
    );
  }

  test('creates an excuse that is not shared yet', () async {
    final created = await excuses.create(
      taskId: taskId,
      recipientLabel: 'boss',
      tone: 'Polite',
      text: 'My bus was late.',
    );

    expect(created.body, 'My bus was late.');
    expect(created.shared, isFalse);
    expect((await excuses.listForTask(taskId)).single.id, created.id);
  });

  test('markShared flips the shared flag', () async {
    final created = await excuses.create(
      taskId: taskId,
      recipientLabel: 'boss',
      tone: 'Casual',
      text: 'Running late.',
    );

    await excuses.markShared(created.id);
    expect((await excuses.listForTask(taskId)).single.shared, isTrue);
  });

  test('recentForRecipient returns the newest excuses, capped', () async {
    for (var i = 0; i < 7; i++) {
      await add('boss', 'boss $i', DateTime(2030, 1, 1 + i));
    }
    await add('mum', 'mum 0', DateTime(2030, 2, 1));

    final recent = await excuses.recentForRecipient('boss');
    expect(recent.map((e) => e.body), [
      'boss 6',
      'boss 5',
      'boss 4',
      'boss 3',
      'boss 2',
    ]);
    expect(await excuses.recentForRecipient('boss', limit: 2), hasLength(2));
  });
}
