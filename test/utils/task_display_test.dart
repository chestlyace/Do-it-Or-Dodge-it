import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/task_display.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';

Task task(
  int id,
  TaskStatus status, {
  TaskCategory category = TaskCategory.work,
  String? custom,
}) {
  return Task(
    id: id,
    title: 'T$id',
    category: category,
    customCategory: custom,
    createdAt: DateTime(2030),
    status: status,
  );
}

void main() {
  test('groups by status in display order and leaves out empty groups', () {
    final groups = groupTasks([
      task(1, TaskStatus.done),
      task(2, TaskStatus.open),
      task(3, TaskStatus.doing),
      task(4, TaskStatus.open),
      task(5, TaskStatus.abandoned),
    ]);

    expect(groups.map((g) => g.status), [
      TaskStatus.doing,
      TaskStatus.open,
      TaskStatus.done,
      TaskStatus.abandoned,
    ]);
    expect(groups[1].tasks.map((t) => t.id), [2, 4]);
  });

  test('no tasks gives no groups', () {
    expect(groupTasks([]), isEmpty);
  });

  test('formats dates', () {
    expect(formatDate(DateTime(2030, 11, 3)), '3 Nov 2030');
    expect(formatDate(DateTime(2031, 1, 21)), '21 Jan 2031');
  });

  test('shows the typed text for Other, else the category name', () {
    expect(categoryText(task(1, TaskStatus.open)), 'Work');
    expect(
      categoryText(
        task(
          1,
          TaskStatus.open,
          category: TaskCategory.other,
          custom: 'Garden',
        ),
      ),
      'Garden',
    );
    expect(
      categoryText(task(1, TaskStatus.open, category: TaskCategory.other)),
      'Other',
    );
    expect(
      categoryText(
        task(1, TaskStatus.open, category: TaskCategory.other, custom: '  '),
      ),
      'Other',
    );
  });
}
