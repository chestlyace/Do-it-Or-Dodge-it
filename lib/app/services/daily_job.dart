import 'nudge_service.dart';
import 'predictor_service.dart';

/// What the daily job did.
class DailyJobResult {
  const DailyJobResult({
    required this.fired,
    required this.abandoned,
    required this.planned,
    this.retrained = 0,
  });

  /// Nudges whose time had passed and were marked as fired.
  final int fired;

  /// Do It tasks past their due date with no progress.
  final int abandoned;

  /// Nudges scheduled again for tasks still being worked on.
  final int planned;

  /// Outcomes the dodge predictor was trained on (0 while the simple rule is
  /// used).
  final int retrained;

  @override
  String toString() =>
      'fired $fired, abandoned $abandoned, planned $planned nudges, '
      'predictor trained on $retrained';
}

/// The work done once a day in the background, and by the debug screen.
///
/// It never uses the model, so it is cheap and works with the app closed.
class DailyJob {
  const DailyJob(this._nudges, {this._predictor});

  final NudgeService _nudges;
  final PredictorService? _predictor;

  Future<DailyJobResult> run() async {
    final fired = await _nudges.syncFired();
    final abandoned = await _nudges.abandonOverdue();
    // Learn first, so the new plan uses the latest scores.
    final retrained = await _predictor?.retrain() ?? 0;
    final planned = await _nudges.replanAll();
    return DailyJobResult(
      fired: fired,
      abandoned: abandoned,
      planned: planned,
      retrained: retrained,
    );
  }
}
