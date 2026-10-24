import 'package:get/get.dart';

import '../data/models/enums.dart';
import '../data/repositories/outcome_repository.dart';
import '../data/repositories/task_repository.dart';
import 'predictor_service.dart';

/// Closes a task and logs its outcome. Both the Do It and Dodge It paths end
/// here, so a task is only ever closed once.
class OutcomeService extends GetxService {
  OutcomeService({
    required this._tasks,
    required this._outcomes,
    this._predictor,
  });

  final TaskRepository _tasks;
  final OutcomeRepository _outcomes;

  /// Saves the features with each outcome and learns from it.
  final PredictorService? _predictor;

  /// Called after a task is closed, for example to cancel its nudges.
  Future<void> Function(int taskId)? onClosed;

  /// The last step was ticked. Returns false if the task was already closed.
  Future<bool> markDone(int taskId) =>
      _close(taskId, TaskStatus.done, OutcomeResult.done);

  /// An excuse was copied or shared. Returns false if the task was already
  /// closed.
  Future<bool> markDodged(int taskId) =>
      _close(taskId, TaskStatus.dodged, OutcomeResult.dodged);

  /// The due date passed with no progress. Returns false if already closed.
  Future<bool> markAbandoned(int taskId) =>
      _close(taskId, TaskStatus.abandoned, OutcomeResult.abandoned);

  Future<bool> _close(
    int taskId,
    TaskStatus status,
    OutcomeResult result,
  ) async {
    final task = await _tasks.getById(taskId);
    if (task == null || isClosed(task.status)) return false;
    // The features from when the user chose, not from now.
    final snapshot = await _predictor?.takeDecisionSnapshot(task) ?? const {};
    await _tasks.updateStatus(taskId, status);
    await _outcomes.record(
      taskId: taskId,
      result: result,
      featureSnapshot: Map<String, dynamic>.from(snapshot),
    );
    try {
      await _predictor?.retrain();
    } catch (_) {
      // Learning is a bonus; it must never stop a task from closing.
    }
    await onClosed?.call(taskId);
    return true;
  }
}

/// Done, dodged and abandoned tasks are closed.
bool isClosed(TaskStatus status) =>
    status == TaskStatus.done ||
    status == TaskStatus.dodged ||
    status == TaskStatus.abandoned;
