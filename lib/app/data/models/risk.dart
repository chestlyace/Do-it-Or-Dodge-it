/// Where a risk score came from.
enum RiskSource {
  /// The simple rule used until there is enough history: the user's dodge rate
  /// for the task's category, or 50% with none.
  rule,

  /// The logistic regression trained on the user's own outcomes.
  model,
}

/// A dodge risk from 0 to 1 with a plain-words reason.
class RiskAssessment {
  const RiskAssessment({
    required this.risk,
    required this.reason,
    required this.source,
    required this.outcomesUsed,
  });

  final double risk;
  final String reason;
  final RiskSource source;

  /// Outcomes with saved features that the model was trained on (0 for the
  /// rule).
  final int outcomesUsed;

  int get percent => (risk * 100).round();
}
