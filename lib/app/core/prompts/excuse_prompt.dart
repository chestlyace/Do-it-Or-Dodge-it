import '../../data/models/prompt_jobs.dart';
import 'prompt_job.dart';

const _system =
    'You write a short, believable excuse for putting off a task. '
    'Reply with ONLY a JSON object, no markdown and no other text, in exactly '
    'this shape: {"excuse":"...","short":"..."}. '
    '"excuse" is one to three sentences in the first person, in the requested '
    'tone. "short" is a one-sentence version that is shorter than "excuse". '
    'Keep it light and low-stakes: ordinary schedule or workload reasons only. '
    'Never mention health, illness, injury, death, funerals, legal trouble, '
    'accidents or emergencies. Do not blame other named people. '
    'Do not repeat or paraphrase any excuse that was already used for this '
    'person.';

/// Words that make an excuse off-limits, whatever the model was told.
final _offLimits = RegExp(
  r'\b(sick|sickness|illness|flu|covid|hospital|doctor|surgery|injur\w*|'
  r'died|death|dead|funeral|passed away|lawyer|court|legal|police|arrest\w*|'
  r'emergency|accident)\b',
  caseSensitive: false,
);

PromptJob<ExcuseDraft> excuseJob({List<String> previousExcuses = const []}) {
  final used = previousExcuses.take(maxExcuseHistory).map(_normalise).toList();
  return PromptJob(
    name: 'writeExcuse',
    systemInstruction: _system,
    maxOutputTokens: 220,
    parse: (raw) => parseExcuse(raw, usedNormalised: used),
  );
}

String excuseUserPrompt(ExcuseInput input) {
  final lines = [
    'Task: ${input.taskTitle.trim()}',
    'This is for: ${input.recipient.trim()}',
    'Tone: ${input.tone.label}',
  ];
  final used = input.previousExcuses.take(maxExcuseHistory).toList();
  if (used.isNotEmpty) {
    lines.add('Excuses already used for this person (do not repeat them):');
    for (var i = 0; i < used.length; i++) {
      lines.add('${i + 1}. ${used[i].trim()}');
    }
  }
  return lines.join('\n');
}

ExcuseDraft parseExcuse(String raw, {List<String> usedNormalised = const []}) {
  final json = extractJsonObject(raw);
  final text = requireString(json, 'excuse', maxLength: 400);
  final short = requireString(json, 'short', maxLength: 200);
  if (short.length > text.length) {
    throw const JobFormatException('"short" is longer than "excuse"');
  }

  if (_offLimits.hasMatch(text) || _offLimits.hasMatch(short)) {
    throw const JobFormatException(
      'the excuse mentions health, death, legal trouble or an emergency',
    );
  }

  final normalised = _normalise(text);
  if (usedNormalised.contains(normalised) ||
      usedNormalised.contains(_normalise(short))) {
    throw const JobFormatException('the excuse repeats an earlier one');
  }
  return ExcuseDraft(text: text, shortVariant: short);
}

String _normalise(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
