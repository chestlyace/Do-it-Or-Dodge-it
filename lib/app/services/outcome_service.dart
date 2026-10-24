import 'package:get/get.dart';

import '../data/models/enums.dart';
import '../data/repositories/outcome_repository.dart';
import '../data/repositories/task_repository.dart';

/// Closes a task and logs its outcome. Both the Do It and Dodge It paths end
/// here, so a task is only ever closed once.
class OutcomeService extends GetxService {
  OutcomeService({required this._tasks, required this._outcomes});

  final TaskRepository _tasks;
  final OutcomeRepository _outcomes;

  /// The last step was ticked. Returns false if the task was already closed.
  Future<bool> markDone(int taskId) =>
      _close(taskId, TaskStatus.done, OutcomeResult.done);

  /// An excuse was copied or shared. Returns false if the task was already
  /// closed.
  Future<bool> markDodged(int taskId) =>
      _close(taskId, TaskStatus.dodged, OutcomeResult.dodged);

  Future<bool> _close(
    int taskId,
    TaskStatus status,
    OutcomeResult result,
  ) async {
    final task = await _tasks.getById(taskId);
    if (task == null || isClosed(task.status)) return false;
    await _tasks.updateStatus(taskId, status);
    await _outcomes.record(taskId: taskId, result: result);
    return true;
  }
}

/// Done, dodged and abandoned tasks are closed.
bool isClosed(TaskStatus status) =>
    status == TaskStatus.done ||
    status == TaskStatus.dodged ||
    status == TaskStatus.abandoned;
