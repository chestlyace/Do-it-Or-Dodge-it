import '../models/enums.dart';
import '../repositories/step_repository.dart';
import '../repositories/task_repository.dart';

/// Inserts sample tasks for development. Only call this from debug builds.
Future<void> seedSampleTasks(
  TaskRepository tasks,
  StepRepository steps, {
  DateTime? now,
}) async {
  final base = now ?? DateTime.now();

  final taxes = await tasks.create(
    title: 'File my tax return',
    category: TaskCategory.admin,
    note: 'Gather payslips and receipts first.',
    dueAt: base.add(const Duration(days: 5)),
  );
  await steps.createAll(taxes.id, const [
    NewStep(title: 'Open the tax website', estMinutes: 1),
    NewStep(title: 'Find last year\'s return', estMinutes: 5),
    NewStep(title: 'Collect this year\'s payslips', estMinutes: 15),
  ]);

  await tasks.create(
    title: 'Reply to Sam about the invoice',
    category: TaskCategory.work,
    dueAt: base.add(const Duration(days: 1)),
  );
  await tasks.create(
    title: 'Go for a 20 minute run',
    category: TaskCategory.fitness,
  );
  await tasks.create(
    title: 'Do the laundry',
    category: TaskCategory.chores,
    dueAt: base.add(const Duration(days: 2)),
  );
  await tasks.create(
    title: 'Book a dentist appointment',
    category: TaskCategory.health,
  );
  await tasks.create(
    title: 'Sort out the garden shed',
    category: TaskCategory.other,
    customCategory: 'Garden',
  );
}
