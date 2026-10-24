import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/excuse_prompt.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/help_prompt.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/nudge_prompt.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/prompt_job.dart';
import 'package:do_it_or_dodge_it/app/core/prompts/shrink_prompt.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/app/data/models/prompt_jobs.dart';

import '../support/job_replies.dart';

Matcher failsWith(String part) => throwsA(
  isA<JobFormatException>().having((e) => e.message, 'message', contains(part)),
);

String steps(List<(String, Object)> items) {
  final body = items
      .map((s) => '{"title":"${s.$1}","estMinutes":${s.$2}}')
      .join(',');
  return '{"steps":[$body]}';
}

void main() {
  group('extractJsonObject', () {
    test('reads plain JSON', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
    });

    test('reads JSON inside a markdown fence', () {
      expect(extractJsonObject('```json\n{"a":1}\n```'), {'a': 1});
      expect(extractJsonObject('```\n{"a":1}\n```'), {'a': 1});
    });

    test('ignores text before and after the object', () {
      expect(extractJsonObject('Sure! {"a":1} Hope that helps.'), {'a': 1});
    });

    test('rejects replies without a usable object', () {
      expect(() => extractJsonObject('no json here'), failsWith('no JSON'));
      expect(() => extractJsonObject('{"a": '), failsWith('no JSON'));
      expect(() => extractJsonObject('{a: 1}'), failsWith('not valid JSON'));
      expect(() => extractJsonObject('[1, 2]'), failsWith('no JSON'));
      expect(() => extractJsonObject(''), failsWith('no JSON'));
    });
  });

  group('shrinkTask', () {
    test('parses a valid reply', () {
      final task = parseShrunkTask(validShrink);
      expect(task.steps, hasLength(3));
      expect(task.steps.first.title, 'Open the website');
      expect(task.steps.first.estMinutes, 1);
    });

    test('accepts 3 and 7 steps but not 2 or 8', () {
      List<(String, Object)> n(int count) => [
        for (var i = 0; i < count; i++) ('Step $i', i == 0 ? 1 : 5),
      ];

      expect(parseShrunkTask(steps(n(3))).steps, hasLength(3));
      expect(parseShrunkTask(steps(n(7))).steps, hasLength(7));
      expect(() => parseShrunkTask(steps(n(2))), failsWith('3 to 7'));
      expect(() => parseShrunkTask(steps(n(8))), failsWith('3 to 7'));
    });

    test('the first step must take under 2 minutes', () {
      final bad = steps([('A', 2), ('B', 5), ('C', 5)]);
      expect(() => parseShrunkTask(bad), failsWith('under 2 minutes'));
    });

    test('fractional minutes round up to a whole minute', () {
      final task = parseShrunkTask(steps([('A', 0.5), ('B', 2.2), ('C', 5)]));
      expect(task.steps.map((s) => s.estMinutes), [1, 3, 5]);
    });

    test('rejects bad steps', () {
      expect(
        () => parseShrunkTask('{"steps":"nope"}'),
        failsWith('not a list'),
      );
      expect(
        () => parseShrunkTask(
          '{"steps":[{"title":"A"},{"title":"B","estMinutes":1},{"title":"C","estMinutes":1}]}',
        ),
        failsWith('estMinutes'),
      );
      expect(
        () => parseShrunkTask(steps([('', 1), ('B', 1), ('C', 1)])),
        failsWith('title'),
      );
      expect(
        () => parseShrunkTask(steps([('A', 0), ('B', 1), ('C', 1)])),
        failsWith('estMinutes'),
      );
      expect(
        () => parseShrunkTask('{"steps":[1,2,3]}'),
        failsWith('not an object'),
      );
    });

    test('caps absurd minutes', () {
      final task = parseShrunkTask(steps([('A', 1), ('B', 99999), ('C', 5)]));
      expect(task.steps[1].estMinutes, 240);
    });

    test('the user prompt carries the title, note and due date', () {
      final text = shrinkUserPrompt(
        ShrinkInput(
          title: ' Pay rent ',
          note: 'Use the app',
          dueAt: DateTime(2030, 3, 4),
        ),
      );
      expect(text, contains('Task: Pay rent'));
      expect(text, contains('Note: Use the app'));
      expect(text, contains('Due: 2030-03-04'));
      expect(shrinkUserPrompt(const ShrinkInput(title: 'A')), 'Task: A');
    });
  });

  group('helpWithStep', () {
    test('parses a draft', () {
      expect(parseStepDraft(validHelp).draft, startsWith('Hi Sam'));
    });

    test('rejects a missing or empty draft', () {
      expect(() => parseStepDraft('{}'), failsWith('draft'));
      expect(() => parseStepDraft('{"draft":"  "}'), failsWith('draft'));
      expect(() => parseStepDraft('{"draft":3}'), failsWith('draft'));
    });
  });

  group('writeExcuse', () {
    test('parses an excuse with a shorter variant', () {
      final draft = parseExcuse(
        excuseJson('My calendar was packed all week, sorry.', 'Packed week.'),
      );
      expect(draft.text, 'My calendar was packed all week, sorry.');
      expect(draft.shortVariant, 'Packed week.');
    });

    test('rejects a short variant longer than the excuse', () {
      expect(
        () => parseExcuse(excuseJson('Busy.', 'I was very busy this week.')),
        failsWith('longer'),
      );
    });

    test('rejects off-limits excuses', () {
      for (final bad in [
        'I was sick all week.',
        'There was a death in the family.',
        'I had to go to the hospital.',
        'I had a legal matter to deal with.',
        'It was an emergency at home.',
        'I got injured at the gym.',
        'We had a car accident.',
        'I was at the funeral.',
        'My lawyer told me to wait.',
      ]) {
        expect(
          () => parseExcuse(excuseJson(bad, 'No.')),
          failsWith('health'),
          reason: bad,
        );
      }
    });

    test('does not flag ordinary words', () {
      expect(
        parseExcuse(
          excuseJson("I'll get to it, my inbox is overflowing.", 'Busy.'),
        ),
        isA<ExcuseDraft>(),
      );
    });

    test('rejects a repeat of an earlier excuse', () {
      final job = excuseJob(
        previousExcuses: ['My calendar was packed all week.'],
      );
      expect(
        () =>
            job.parse(excuseJson('my calendar was PACKED all week!', 'Busy.')),
        failsWith('repeats'),
      );
      expect(
        job.parse(excuseJson('The printer ate my notes.', 'Printer.')),
        isA<ExcuseDraft>(),
      );
    });

    test('only the last 5 excuses reach the prompt and the check', () {
      final previous = [for (var i = 0; i < 8; i++) 'Excuse number $i'];
      final prompt = excuseUserPrompt(
        ExcuseInput(
          taskTitle: 'Report',
          recipient: 'boss',
          tone: ExcuseTone.funny,
          previousExcuses: previous,
        ),
      );
      for (var i = 0; i < 5; i++) {
        expect(prompt, contains('Excuse number $i'));
      }
      for (var i = 5; i < 8; i++) {
        expect(prompt, isNot(contains('Excuse number $i')));
      }
      expect(prompt, contains('This is for: boss'));
      expect(prompt, contains('Tone: Funny'));

      // An older excuse (6th) is no longer checked for repeats.
      final job = excuseJob(previousExcuses: previous);
      expect(
        job.parse(excuseJson('Excuse number 7', 'Seven.')),
        isA<ExcuseDraft>(),
      );
      expect(
        () => job.parse(excuseJson('Excuse number 2', 'Two.')),
        failsWith('repeats'),
      );
    });

    test('the prompt omits the history section when there is none', () {
      final prompt = excuseUserPrompt(
        const ExcuseInput(
          taskTitle: 'Report',
          recipient: 'boss',
          tone: ExcuseTone.polite,
        ),
      );
      expect(prompt, isNot(contains('already used')));
    });

    test('the system instruction forbids the off-limits topics', () {
      final text = excuseJob().systemInstruction;
      for (final topic in ['health', 'death', 'legal', 'emergencies']) {
        expect(text, contains(topic));
      }
    });
  });

  group('nudgeWording', () {
    test('parses three messages and picks one per level', () {
      final wording = parseNudgeWording(validNudge);
      expect(wording.forLevel(NudgeLevel.gentle), contains('Ready'));
      expect(wording.forLevel(NudgeLevel.firm), contains('now'));
      expect(wording.forLevel(NudgeLevel.lastCall), contains('Last chance'));
    });

    test('rejects a missing level or a message that is too long', () {
      expect(
        () => parseNudgeWording('{"gentle":"a","firm":"b"}'),
        failsWith('lastCall'),
      );
      final long = 'x' * (maxNudgeLength + 1);
      expect(
        () => parseNudgeWording('{"gentle":"a","firm":"$long","lastCall":"c"}'),
        failsWith('firm'),
      );
    });
  });

  test('the stricter instruction keeps the original and adds the reason', () {
    final job = shrinkJob();
    final text = job.stricterInstruction('the reply is not valid JSON');
    expect(text, startsWith(job.systemInstruction));
    expect(text, contains('the reply is not valid JSON'));
    expect(text, contains('ONLY the JSON object'));
  });

  test('every job caps its output length', () {
    expect(shrinkJob().maxOutputTokens, inInclusiveRange(1, 1000));
    expect(helpJob().maxOutputTokens, inInclusiveRange(1, 1000));
    expect(excuseJob().maxOutputTokens, inInclusiveRange(1, 1000));
    expect(nudgeJob().maxOutputTokens, inInclusiveRange(1, 1000));
  });
}
