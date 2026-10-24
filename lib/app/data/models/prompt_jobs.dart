import 'enums.dart';

/// Input for `shrinkTask`.
class ShrinkInput {
  const ShrinkInput({required this.title, this.note, this.dueAt});

  final String title;
  final String? note;
  final DateTime? dueAt;
}

/// Input for `helpWithStep`.
class HelpInput {
  const HelpInput({
    required this.taskTitle,
    required this.stepTitle,
    this.taskNote,
  });

  final String taskTitle;
  final String stepTitle;
  final String? taskNote;
}

/// Input for `writeExcuse`.
class ExcuseInput {
  const ExcuseInput({
    required this.taskTitle,
    required this.recipient,
    required this.tone,
    this.previousExcuses = const [],
  });

  final String taskTitle;

  /// Free text the user typed, such as "boss".
  final String recipient;
  final ExcuseTone tone;

  /// Excuses already used for [recipient], newest first. Only the latest
  /// [maxExcuseHistory] reach the prompt.
  final List<String> previousExcuses;
}

/// Input for `nudgeWording`.
class NudgeInput {
  const NudgeInput({required this.taskTitle, required this.stepTitle});

  final String taskTitle;
  final String stepTitle;
}

/// Excuses shown to the model so it does not repeat itself.
const maxExcuseHistory = 5;

/// A parsed prompt job result that can be shown and saved.
abstract interface class JobOutput {
  Map<String, dynamic> toJson();

  /// Plain text for the prompt lab.
  String describe();
}

/// One tiny step produced by `shrinkTask`.
class TinyStep {
  const TinyStep({required this.title, required this.estMinutes});

  final String title;
  final int estMinutes;

  Map<String, dynamic> toJson() => {'title': title, 'estMinutes': estMinutes};

  @override
  bool operator ==(Object other) =>
      other is TinyStep &&
      other.title == title &&
      other.estMinutes == estMinutes;

  @override
  int get hashCode => Object.hash(title, estMinutes);
}

class ShrunkTask implements JobOutput {
  const ShrunkTask(this.steps);

  final List<TinyStep> steps;

  @override
  Map<String, dynamic> toJson() => {
    'steps': [for (final step in steps) step.toJson()],
  };

  @override
  String describe() => [
    for (var i = 0; i < steps.length; i++)
      '${i + 1}. ${steps[i].title} (${steps[i].estMinutes} min)',
  ].join('\n');
}

class StepDraft implements JobOutput {
  const StepDraft(this.draft);

  final String draft;

  @override
  Map<String, dynamic> toJson() => {'draft': draft};

  @override
  String describe() => draft;
}

class ExcuseDraft implements JobOutput {
  const ExcuseDraft({required this.text, required this.shortVariant});

  final String text;
  final String shortVariant;

  @override
  Map<String, dynamic> toJson() => {'excuse': text, 'short': shortVariant};

  @override
  String describe() => '$text\n\nShort: $shortVariant';
}

class NudgeWording implements JobOutput {
  const NudgeWording({
    required this.gentle,
    required this.firm,
    required this.lastCall,
  });

  final String gentle;
  final String firm;
  final String lastCall;

  @override
  Map<String, dynamic> toJson() => {
    'gentle': gentle,
    'firm': firm,
    'lastCall': lastCall,
  };

  @override
  String describe() => 'Gentle: $gentle\nFirm: $firm\nLast call: $lastCall';

  String forLevel(NudgeLevel level) => switch (level) {
    NudgeLevel.gentle => gentle,
    NudgeLevel.firm => firm,
    NudgeLevel.lastCall => lastCall,
  };
}

/// What a prompt job gave back: a parsed object, or a clear fallback.
sealed class JobResult<T> {
  const JobResult({required this.rawText, required this.retried});

  /// The model's last reply, exactly as it came out.
  final String rawText;

  /// True when the first reply was unusable and the job asked again.
  final bool retried;
}

class JobSuccess<T> extends JobResult<T> {
  const JobSuccess(this.value, {required super.rawText, super.retried = false});

  final T value;
}

/// The reply could not be used. Show [rawText] and explain with [reason].
class JobFallback<T> extends JobResult<T> {
  const JobFallback({
    required this.reason,
    required super.rawText,
    super.retried = false,
    this.stopped = false,
  });

  final String reason;

  /// True when the user stopped the job.
  final bool stopped;
}
