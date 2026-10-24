import '../../data/models/prompt_jobs.dart';
import 'prompt_job.dart';

const _system =
    'You write a ready-to-use draft for one small step of a task. '
    'Reply with ONLY a JSON object, no markdown and no other text, in exactly '
    'this shape: {"draft":"..."}. '
    'The draft is the text the user will copy: an email, a short message or an '
    'outline, whichever fits the step. Write it in the first person, plain and '
    'friendly, in at most 150 words. Put anything you do not know in [square '
    'brackets]. Put nothing but the draft itself in the "draft" value.';

PromptJob<StepDraft> helpJob() => const PromptJob(
  name: 'helpWithStep',
  systemInstruction: _system,
  maxOutputTokens: 450,
  parse: parseStepDraft,
);

String helpUserPrompt(HelpInput input) {
  final lines = [
    'Task: ${input.taskTitle.trim()}',
    'Step to help with: ${input.stepTitle.trim()}',
  ];
  final note = input.taskNote?.trim();
  if (note != null && note.isNotEmpty) lines.add('Note: $note');
  return lines.join('\n');
}

StepDraft parseStepDraft(String raw) {
  final json = extractJsonObject(raw);
  return StepDraft(requireString(json, 'draft'));
}
