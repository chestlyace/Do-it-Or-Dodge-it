import '../data/db/app_database.dart';
import '../data/models/enums.dart';
import '../data/models/prompt_jobs.dart';
import '../data/repositories/step_repository.dart';
import '../data/repositories/task_repository.dart';
import 'gemma_service.dart';
import 'nudge_service.dart';
import 'pregenerated_excuses.dart';

/// What the pre-generation job wrote.
class PregenerateResult {
  const PregenerateResult({
    this.nudgeTexts = 0,
    this.excuses = 0,
    this.tasks = 0,
  });

  /// Tasks that got notification text for their next step.
  final int nudgeTexts;

  /// Tasks that got a ready-made excuse.
  final int excuses;

  /// Tasks looked at.
  final int tasks;

  @override
  String toString() =>
      'wrote $nudgeTexts nudge texts and $excuses excuses for $tasks tasks';
}

/// Writes notification text and a general excuse ahead of time for the tasks
/// that are open, so Dodge It and the nudges feel instant.
///
/// It uses the model, so it only runs from the background while the phone is
/// charging (or from the debug screen). It frees the model when it is done.
class PregenerateJob {
  const PregenerateJob({
    required this._tasks,
    required this._steps,
    required this._nudges,
    required this._gemma,
    required this._excuses,
    this.maxTasks = 8,
  });

  final TaskRepository _tasks;
  final StepRepository _steps;
  final NudgeService _nudges;
  final GemmaService _gemma;
  final PregeneratedExcuses _excuses;

  /// Keeps one run short.
  final int maxTasks;

  Future<PregenerateResult> run() async {
    await _gemma.started;
    if (_gemma.installState.value != ModelInstallState.installed) {
      return const PregenerateResult();
    }

    final open = [
      ...await _tasks.listByStatus(TaskStatus.doing),
      ...await _tasks.listByStatus(TaskStatus.open),
    ].take(maxTasks).toList();

    var nudgeTexts = 0;
    var excuses = 0;
    try {
      for (final task in open) {
        if (task.status == TaskStatus.doing) {
          if (await _writeNudgeText(task)) nudgeTexts++;
        }
        if (await _writeExcuse(task)) excuses++;
      }
    } finally {
      await _gemma.release();
    }
    return PregenerateResult(
      nudgeTexts: nudgeTexts,
      excuses: excuses,
      tasks: open.length,
    );
  }

  Future<bool> _writeNudgeText(Task task) async {
    try {
      final step = await _steps.nextUndone(task.id);
      if (step == null) return false;
      if (!await _nudges.ensureWording(task, step)) return false;
      // Put the new text into the notifications already scheduled.
      await _nudges.replan(task.id, allowModel: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _writeExcuse(Task task) async {
    try {
      if (await _excuses.has(task.id)) return false;
      final result = await _gemma.writeExcuse(
        ExcuseInput(
          taskTitle: task.title,
          recipient: genericRecipient,
          tone: ExcuseTone.polite,
        ),
      );
      if (result is! JobSuccess<ExcuseDraft>) return false;
      await _excuses.write(task.id, result.value);
      return true;
    } catch (_) {
      return false;
    }
  }
}
