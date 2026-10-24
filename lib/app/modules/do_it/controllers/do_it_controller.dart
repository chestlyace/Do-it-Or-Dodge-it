import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/partial_steps.dart';
import '../../../data/db/app_database.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/prompt_jobs.dart';
import '../../../data/repositories/step_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/gemma_service.dart';
import '../../../services/outcome_service.dart';
import '../../../services/share_service.dart';

enum DoItPhase { loading, notFound, generating, failed, ready }

class DoItController extends GetxController {
  final _tasks = Get.find<TaskRepository>();
  final _steps = Get.find<StepRepository>();
  final _gemma = Get.find<GemmaService>();
  final _outcomes = Get.find<OutcomeService>();
  final _share = Get.find<ShareService>();

  final phase = DoItPhase.loading.obs;
  final task = Rxn<Task>();
  final steps = <Step>[].obs;

  /// Steps that have streamed in so far while Gemma is still writing.
  final streamed = <TinyStep>[].obs;
  final failureReason = RxnString();
  final failureRaw = RxnString();

  /// The step the help sheet is open for.
  final helpStep = Rxn<Step>();
  final helpLoading = false.obs;
  final helpDraft = RxnString();
  final helpError = RxnString();

  int? taskId;
  StreamSubscription<Task?>? _taskSub;
  StreamSubscription<List<Step>>? _stepsSub;

  bool get isDone => task.value?.status == TaskStatus.done;

  int get doneCount => steps.where((s) => s.doneAt != null).length;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    taskId = args is int ? args : null;
    _start();
  }

  Future<void> _start() async {
    final id = taskId;
    final found = id == null ? null : await _tasks.getById(id);
    if (found == null) {
      phase.value = DoItPhase.notFound;
      return;
    }
    task.value = found;
    _taskSub = _tasks.watchById(found.id).listen((t) => task.value = t);
    _stepsSub = _steps.watchForTask(found.id).listen(steps.assignAll);

    final existing = await _steps.listForTask(found.id);
    steps.assignAll(existing);
    if (existing.isNotEmpty || isClosed(found.status)) {
      phase.value = DoItPhase.ready;
    } else {
      await generate();
    }
  }

  /// Asks Gemma for tiny steps, showing them as they stream in.
  Future<void> generate() async {
    final current = task.value;
    if (current == null || phase.value == DoItPhase.generating) return;
    phase.value = DoItPhase.generating;
    failureReason.value = null;
    failureRaw.value = null;
    streamed.clear();

    final buffer = StringBuffer();
    final result = await _gemma.shrinkTask(
      ShrinkInput(
        title: current.title,
        note: current.note,
        dueAt: current.dueAt,
      ),
      onToken: (token) {
        buffer.write(token);
        streamed.assignAll(parsePartialSteps(buffer.toString()));
      },
      onAttempt: (attempt) {
        buffer.clear();
        streamed.clear();
      },
    );

    switch (result) {
      case JobSuccess<ShrunkTask>():
        await _steps.createAll(current.id, [
          for (final s in result.value.steps)
            NewStep(title: s.title, estMinutes: s.estMinutes),
        ]);
        if (current.status == TaskStatus.open) {
          await _tasks.updateStatus(current.id, TaskStatus.doing);
        }
        streamed.clear();
        phase.value = DoItPhase.ready;
      case JobFallback<ShrunkTask>():
        failureReason.value = result.reason;
        failureRaw.value = result.rawText;
        phase.value = DoItPhase.failed;
    }
  }

  Future<void> stopGenerating() => _gemma.stop();

  /// Ticks or unticks [step]. Ticking the last one finishes the task.
  Future<void> toggle(Step step) async {
    if (isDone) return;
    if (step.doneAt == null) {
      await _steps.markDone(step.id);
      final remaining = await _steps.nextUndone(step.taskId);
      if (remaining == null) await _outcomes.markDone(step.taskId);
    } else {
      await _steps.markUndone(step.id);
    }
  }

  /// Opens the draft helper for [step]. A saved draft shows straight away.
  Future<void> openHelp(Step step) async {
    helpStep.value = step;
    helpError.value = null;
    helpDraft.value = step.draftText;
    if (step.draftText == null) await writeDraft();
  }

  Future<void> writeDraft() async {
    final step = helpStep.value;
    final current = task.value;
    if (step == null || current == null || helpLoading.value) return;
    helpLoading.value = true;
    helpError.value = null;
    try {
      final result = await _gemma.helpWithStep(
        HelpInput(
          taskTitle: current.title,
          stepTitle: step.title,
          taskNote: current.note,
        ),
      );
      switch (result) {
        case JobSuccess<StepDraft>():
          helpDraft.value = result.value.draft;
          await _steps.setDraft(step.id, result.value.draft);
        case JobFallback<StepDraft>():
          helpError.value = result.stopped
              ? 'Stopped.'
              : '${result.reason}\n\n${result.rawText}'.trim();
      }
    } finally {
      helpLoading.value = false;
    }
  }

  Future<void> stopHelp() => _gemma.stop();

  void closeHelp() {
    helpStep.value = null;
    helpDraft.value = null;
    helpError.value = null;
  }

  Future<void> copyDraft() async {
    final draft = helpDraft.value;
    if (draft != null) await _share.copy(draft);
  }

  @override
  void onClose() {
    _taskSub?.cancel();
    _stepsSub?.cancel();
    if (phase.value == DoItPhase.generating || helpLoading.value) {
      _gemma.stop();
    }
    super.onClose();
  }
}
