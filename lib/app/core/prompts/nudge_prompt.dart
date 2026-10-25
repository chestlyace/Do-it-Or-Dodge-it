import '../../data/models/prompt_jobs.dart';
import 'prompt_job.dart';

const _system =
    'You write three short notification messages that nudge someone to do ONE '
    'small step. Reply with ONLY a JSON object, no markdown and no other text, '
    'in exactly this shape: {"gentle":"...","firm":"...","lastCall":"..."}. '
    'Each message is one sentence of at most 100 characters, names the step, '
    'and has no emoji. "gentle" is friendly and relaxed, "firm" is direct, '
    '"lastCall" is urgent but kind. Never shame the user.';

const maxNudgeLength = 100;

PromptJob<NudgeWording> nudgeJob() => const PromptJob(
  name: 'nudgeWording',
  systemInstruction: _system,
  maxOutputTokens: 160,
  parse: parseNudgeWording,
);

String nudgeUserPrompt(NudgeInput input) {
  return 'Task: ${input.taskTitle.trim()}\n'
      'Next step: ${input.stepTitle.trim()}';
}

NudgeWording parseNudgeWording(String raw) {
  final json = extractJsonObject(raw);
  return NudgeWording(
    gentle: requireString(json, 'gentle', maxLength: maxNudgeLength),
    firm: requireString(json, 'firm', maxLength: maxNudgeLength),
    lastCall: requireString(json, 'lastCall', maxLength: maxNudgeLength),
  );
}
