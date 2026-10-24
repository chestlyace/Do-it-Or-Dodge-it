import '../../data/db/app_database.dart';
import '../../data/models/enums.dart';

/// Order of the groups on the home screen.
const statusOrder = [
  TaskStatus.doing,
  TaskStatus.open,
  TaskStatus.done,
  TaskStatus.dodged,
  TaskStatus.abandoned,
];

String statusLabel(TaskStatus status) => switch (status) {
  TaskStatus.open => 'Open',
  TaskStatus.doing => 'Doing',
  TaskStatus.done => 'Done',
  TaskStatus.dodged => 'Dodged',
  TaskStatus.abandoned => 'Abandoned',
};

class TaskGroup {
  const TaskGroup(this.status, this.tasks);

  final TaskStatus status;
  final List<Task> tasks;
}

/// Groups tasks by status in [statusOrder], leaving out empty groups.
List<TaskGroup> groupTasks(List<Task> tasks) {
  return [
    for (final status in statusOrder)
      if (tasks.any((t) => t.status == status))
        TaskGroup(status, [
          for (final t in tasks)
            if (t.status == status) t,
        ]),
  ];
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// "3 Nov 2030".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// The category name, or the text the user typed for "Other".
String categoryText(Task task) {
  final custom = task.customCategory?.trim();
  if (task.category == TaskCategory.other &&
      custom != null &&
      custom.isNotEmpty) {
    return custom;
  }
  return task.category.label;
}

/// "3 Nov 2030, 09:05".
String formatDateTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '${formatDate(time)}, $h:$m';
}
