import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/sample_tasks.dart';
import 'package:do_it_or_dodge_it/app/core/utils/sample_report.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';

void main() {
  test('there are at least 20 sample tasks, all different', () {
    expect(sampleTasks.length, greaterThanOrEqualTo(20));
    expect(
      sampleTasks.map((t) => t.title).toSet(),
      hasLength(sampleTasks.length),
    );
    for (final task in sampleTasks) {
      expect(task.title, isNotEmpty);
      expect(task.step, isNotEmpty);
      expect(task.recipient, isNotEmpty);
    }
    expect(sampleTasks.map((t) => t.tone).toSet(), ExcuseTone.values.toSet());
  });

  test('pass rate counts parsed runs for one job', () {
    const runs = [
      SampleRun(job: 'a', task: '1', parsed: true, retried: false, rawText: ''),
      SampleRun(job: 'a', task: '2', parsed: false, retried: true, rawText: ''),
      SampleRun(job: 'b', task: '1', parsed: true, retried: false, rawText: ''),
    ];
    expect(passRate(runs, 'a'), '1/2');
    expect(passRate(runs, 'b'), '1/1');
  });

  test('the report lists pass rate and every result with its raw text', () {
    final text = buildSampleReport(
      runs: const [
        SampleRun(
          job: 'shrinkTask',
          task: 'Pay rent',
          parsed: true,
          retried: false,
          rawText: '{"steps":[]}',
          output: {'steps': []},
        ),
        SampleRun(
          job: 'shrinkTask',
          task: 'Do taxes',
          parsed: false,
          retried: true,
          rawText: 'oops',
          reason: 'no JSON',
        ),
      ],
      model: 'gemma-4-E2B-it@1caa527',
      generatedAt: DateTime.utc(2030, 1, 2, 3, 4, 5),
    );

    final json = jsonDecode(text) as Map<String, dynamic>;
    expect(json['model'], 'gemma-4-E2B-it@1caa527');
    expect(json['generatedAt'], '2030-01-02T03:04:05.000Z');
    final job = (json['jobs'] as Map)['shrinkTask'] as Map;
    expect(job['passRate'], '1/2');
    final results = job['results'] as List;
    expect(results, hasLength(2));
    expect(results[0], containsPair('parsed', true));
    expect(results[1], containsPair('reason', 'no JSON'));
    expect(results[1], containsPair('raw', 'oops'));
  });
}
