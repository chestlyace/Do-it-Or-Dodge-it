import 'dart:math' as math;

import '../../data/models/prompt_jobs.dart';
import 'prompt_job.dart';

const _system =
    'You break a task someone is avoiding into tiny steps. '
    'Reply with ONLY a JSON object, no markdown and no other text, in exactly '
    'this shape: {"steps":[{"title":"...","estMinutes":1}]}. '
    'Rules: give 3 to 7 steps in the order they are done. '
    'Each title is a short, concrete action that starts with a verb, at most '
    '80 characters. estMinutes is a whole number of minutes. '
    'The first step must take 1 minute and be so easy it is hard to refuse, '
    'such as opening a file or finding one number.';

const minShrinkSteps = 3;
const maxShrinkSteps = 7;

PromptJob<ShrunkTask> shrinkJob() => const PromptJob(
  name: 'shrinkTask',
  systemInstruction: _system,
  maxOutputTokens: 400,
  parse: parseShrunkTask,
);

String shrinkUserPrompt(ShrinkInput input) {
  final lines = ['Task: ${input.title.trim()}'];
  final note = input.note?.trim();
  if (note != null && note.isNotEmpty) lines.add('Note: $note');
  final due = input.dueAt;
  if (due != null) {
    final month = due.month.toString().padLeft(2, '0');
    final day = due.day.toString().padLeft(2, '0');
    lines.add('Due: ${due.year}-$month-$day');
  }
  return lines.join('\n');
}

ShrunkTask parseShrunkTask(String raw) {
  final json = extractJsonObject(raw);
  final list = json['steps'];
  if (list is! List) throw const JobFormatException('"steps" is not a list');
  if (list.length < minShrinkSteps || list.length > maxShrinkSteps) {
    throw JobFormatException(
      'expected $minShrinkSteps to $maxShrinkSteps steps, got ${list.length}',
    );
  }

  final steps = <TinyStep>[];
  for (var i = 0; i < list.length; i++) {
    final item = list[i];
    if (item is! Map<String, dynamic>) {
      throw JobFormatException('step ${i + 1} is not an object');
    }
    final title = requireString(item, 'title', maxLength: 120);
    final minutes = item['estMinutes'];
    if (minutes is! num || !minutes.isFinite || minutes <= 0) {
      throw JobFormatException('step ${i + 1} has no valid "estMinutes"');
    }
    steps.add(
      TinyStep(
        title: title,
        estMinutes: math.min(math.max(minutes.ceil(), 1), 240),
      ),
    );
  }

  if (steps.first.estMinutes >= 2) {
    throw const JobFormatException('the first step must take under 2 minutes');
  }
  return ShrunkTask(steps);
}
