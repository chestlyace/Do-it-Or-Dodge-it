import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/partial_steps.dart';
import 'package:do_it_or_dodge_it/app/data/models/prompt_jobs.dart';

import '../support/job_replies.dart';

void main() {
  test('finds nothing before a step is complete', () {
    expect(parsePartialSteps(''), isEmpty);
    expect(parsePartialSteps('{"steps":[{"title":"Open the web'), isEmpty);
    expect(
      parsePartialSteps('{"steps":[{"title":"Open the website","estMin'),
      isEmpty,
    );
  });

  test('steps appear one by one as the reply streams in', () {
    const part1 = '{"steps":[{"title":"Open the website","estMinutes":1},';
    const part2 = '{"title":"Find the form","estMinutes":5},{"title":"Fi';

    expect(parsePartialSteps(part1), [
      const TinyStep(title: 'Open the website', estMinutes: 1),
    ]);
    expect(parsePartialSteps(part1 + part2), hasLength(2));
    expect(parsePartialSteps(validShrink), hasLength(3));
  });

  test('handles escaped characters and fractional minutes', () {
    final steps = parsePartialSteps(
      '{"steps":[{"title":"Say \\"hi\\" to Sam","estMinutes":0.5}]}',
    );
    expect(steps.single.title, 'Say "hi" to Sam');
    expect(steps.single.estMinutes, 1);
  });

  test('works inside a markdown fence', () {
    expect(parsePartialSteps('```json\n$validShrink'), hasLength(3));
  });
}
