import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/prompts/sample_tasks.dart';
import '../../../core/utils/sample_report.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/prompt_jobs.dart';
import '../../../services/gemma_service.dart';
import '../../../services/share_service.dart';

enum LabJob {
  shrinkTask('shrinkTask'),
  helpWithStep('helpWithStep'),
  writeExcuse('writeExcuse'),
  nudgeWording('nudgeWording');

  const LabJob(this.jobName);

  final String jobName;
}

class PromptLabController extends GetxController {
  final _gemma = Get.find<GemmaService>();
  final _share = Get.find<ShareService>();

  final job = LabJob.shrinkTask.obs;
  final tone = ExcuseTone.polite.obs;

  final titleField = TextEditingController(text: 'File my tax return');
  final noteField = TextEditingController();
  final stepField = TextEditingController(text: 'Find last year\'s return');
  final recipientField = TextEditingController(text: 'boss');

  final running = false.obs;
  final attempt = 0.obs;
  final raw = ''.obs;

  /// "Parsed" or the reason for the fallback; null before the first run.
  final status = RxnString();
  final parsedText = RxnString();

  /// Excuses written in this session, newest first, per recipient.
  final excuseHistory = <String, List<String>>{}.obs;

  final batchProgress = RxnString();
  final batchSummary = RxnString();
  String? _report;

  @override
  void onClose() {
    titleField.dispose();
    noteField.dispose();
    stepField.dispose();
    recipientField.dispose();
    super.onClose();
  }

  List<String> get currentHistory =>
      excuseHistory[recipientField.text.trim()] ?? const [];

  void clearHistory() {
    excuseHistory.remove(recipientField.text.trim());
    excuseHistory.refresh();
  }

  /// Runs the selected job once with the values in the form.
  Future<void> run() async {
    if (running.value) return;
    running.value = true;
    raw.value = '';
    attempt.value = 0;
    status.value = null;
    parsedText.value = null;
    try {
      final outcome = await _runJob(
        job.value,
        title: titleField.text,
        note: noteField.text,
        step: stepField.text,
        recipient: recipientField.text.trim(),
        tone: tone.value,
        previous: currentHistory,
        onToken: (t) => raw.value += t,
        onAttempt: (a) {
          attempt.value = a;
          if (a > 0) raw.value = '';
        },
      );
      raw.value = outcome.rawText;
      if (outcome is JobSuccess) {
        final value = outcome.value;
        status.value = outcome.retried ? 'Parsed (after one retry)' : 'Parsed';
        parsedText.value = value is JobOutput ? value.describe() : '$value';
        if (value is ExcuseDraft) _remember(value.text);
      } else if (outcome is JobFallback) {
        status.value = outcome.reason;
      }
    } catch (e) {
      status.value = 'Error: $e';
    } finally {
      running.value = false;
    }
  }

  void _remember(String excuse) {
    final recipient = recipientField.text.trim();
    final list = [excuse, ...?excuseHistory[recipient]];
    excuseHistory[recipient] = list.take(maxExcuseHistory).toList();
    excuseHistory.refresh();
  }

  Future<void> stop() => _gemma.stop();

  Future<JobResult<Object?>> _runJob(
    LabJob which, {
    required String title,
    required String note,
    required String step,
    required String recipient,
    required ExcuseTone tone,
    required List<String> previous,
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
  }) async {
    switch (which) {
      case LabJob.shrinkTask:
        return _widen(
          await _gemma.shrinkTask(
            ShrinkInput(title: title, note: note),
            onToken: onToken,
            onAttempt: onAttempt,
          ),
        );
      case LabJob.helpWithStep:
        return _widen(
          await _gemma.helpWithStep(
            HelpInput(taskTitle: title, stepTitle: step, taskNote: note),
            onToken: onToken,
            onAttempt: onAttempt,
          ),
        );
      case LabJob.writeExcuse:
        return _widen(
          await _gemma.writeExcuse(
            ExcuseInput(
              taskTitle: title,
              recipient: recipient,
              tone: tone,
              previousExcuses: previous,
            ),
            onToken: onToken,
            onAttempt: onAttempt,
          ),
        );
      case LabJob.nudgeWording:
        return _widen(
          await _gemma.nudgeWording(
            NudgeInput(taskTitle: title, stepTitle: step),
            onToken: onToken,
            onAttempt: onAttempt,
          ),
        );
    }
  }

  JobResult<Object?> _widen<T>(JobResult<T> result) {
    return switch (result) {
      JobSuccess<T>() => JobSuccess<Object?>(
        result.value,
        rawText: result.rawText,
        retried: result.retried,
      ),
      JobFallback<T>() => JobFallback<Object?>(
        reason: result.reason,
        rawText: result.rawText,
        retried: result.retried,
        stopped: result.stopped,
      ),
    };
  }

  /// Runs [jobs] on all 20 sample tasks and builds the report.
  Future<void> runSamples(List<LabJob> jobs) async {
    if (running.value) return;
    running.value = true;
    batchSummary.value = null;
    _report = null;
    final runs = <SampleRun>[];
    final total = jobs.length * sampleTasks.length;

    try {
      var done = 0;
      for (final which in jobs) {
        for (final sample in sampleTasks) {
          batchProgress.value =
              '${which.jobName}: ${done + 1} of $total (${sample.title})';
          final outcome = await _runJob(
            which,
            title: sample.title,
            note: sample.note ?? '',
            step: sample.step,
            recipient: sample.recipient,
            tone: sample.tone,
            previous: const [],
          );
          done++;
          if (outcome is JobFallback && outcome.stopped) {
            batchSummary.value = 'Stopped after $done of $total.';
            return;
          }
          final value = outcome is JobSuccess ? outcome.value : null;
          runs.add(
            SampleRun(
              job: which.jobName,
              task: sample.title,
              parsed: outcome is JobSuccess,
              retried: outcome.retried,
              rawText: outcome.rawText,
              reason: outcome is JobFallback ? outcome.reason : null,
              output: value is JobOutput ? value.toJson() : null,
            ),
          );
        }
      }

      _report = buildSampleReport(
        runs: runs,
        model: _gemma.installed.value?.version ?? 'unknown',
        generatedAt: DateTime.now(),
      );
      batchSummary.value = [
        for (final which in jobs)
          '${which.jobName}: ${passRate(runs, which.jobName)} parsed',
      ].join('\n');
    } catch (e) {
      batchSummary.value = 'Error: $e';
    } finally {
      batchProgress.value = null;
      running.value = false;
    }
  }

  /// Copies the last batch report (JSON) so it can be saved in the repo.
  Future<void> copyReport() async {
    final report = _report;
    if (report != null) await _share.copy(report);
  }

  bool get hasReport => _report != null;
}
