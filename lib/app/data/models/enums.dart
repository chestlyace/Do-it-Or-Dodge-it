/// Lifecycle of a task. `dodged` and `abandoned` count as dodges for the predictor.
enum TaskStatus { open, doing, done, dodged, abandoned }

/// Final result stored in an outcome row.
enum OutcomeResult { done, dodged, abandoned }

/// How firm a nudge is.
enum NudgeLevel { gentle, firm, lastCall }

/// Fixed list of task categories. [other] takes free text in `Tasks.customCategory`.
enum TaskCategory {
  work('Work'),
  study('Study'),
  admin('Admin'),
  money('Money'),
  health('Health'),
  fitness('Fitness'),
  chores('Chores'),
  errands('Errands'),
  social('Social'),
  family('Family'),
  creative('Creative'),
  other('Other');

  const TaskCategory(this.label);

  final String label;
}

/// Tone offered for an excuse.
enum ExcuseTone {
  polite('Polite'),
  casual('Casual'),
  funny('Funny'),
  formal('Formal');

  const ExcuseTone(this.label);

  final String label;
}
