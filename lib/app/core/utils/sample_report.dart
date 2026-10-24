import 'dart:convert';

/// One prompt job run on one sample task.
class SampleRun {
  const SampleRun({
    required this.job,
    required this.task,
    required this.parsed,
    required this.retried,
    required this.rawText,
    this.reason,
    this.output,
  });

  final String job;
  final String task;
  final bool parsed;
  final bool retried;
  final String rawText;

  /// Why the reply was unusable, when [parsed] is false.
  final String? reason;

  /// The parsed object as JSON, when [parsed] is true.
  final Map<String, dynamic>? output;

  Map<String, dynamic> toJson() => {
    'task': task,
    'parsed': parsed,
    'retried': retried,
    if (reason != null) 'reason': reason,
    if (output != null) 'output': output,
    'raw': rawText,
  };
}

/// How many runs of [job] parsed.
String passRate(List<SampleRun> runs, String job) {
  final forJob = runs.where((r) => r.job == job).toList();
  final passed = forJob.where((r) => r.parsed).length;
  return '$passed/${forJob.length}';
}

/// The report saved in `docs/prompt-samples/`: per-job pass rate and every
/// result with its raw text.
String buildSampleReport({
  required List<SampleRun> runs,
  required String model,
  required DateTime generatedAt,
}) {
  final jobs = <String>{for (final run in runs) run.job};
  final report = {
    'model': model,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'jobs': {
      for (final job in jobs)
        job: {
          'passRate': passRate(runs, job),
          'results': [
            for (final run in runs)
              if (run.job == job) run.toJson(),
          ],
        },
    },
  };
  return const JsonEncoder.withIndent('  ').convert(report);
}
