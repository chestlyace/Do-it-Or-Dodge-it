import 'nudge_service.dart';

/// What the daily job did.
class DailyJobResult {
  const DailyJobResult({
    required this.fired,
    required this.abandoned,
    required this.planned,
  });

  /// Nudges whose time had passed and were marked as fired.
  final int fired;

  /// Do It tasks past their due date with no progress.
  final int abandoned;

  /// Nudges scheduled again for tasks still being worked on.
  final int planned;

  @override
  String toString() =>
      'fired $fired, abandoned $abandoned, planned $planned nudges';
}

/// The work done once a day in the background, and by the debug screen.
///
/// It never uses the model, so it is cheap and works with the app closed.
class DailyJob {
  const DailyJob(this._nudges);

  final NudgeService _nudges;

  Future<DailyJobResult> run() async {
    final fired = await _nudges.syncFired();
    final abandoned = await _nudges.abandonOverdue();
    final planned = await _nudges.replanAll();
    return DailyJobResult(fired: fired, abandoned: abandoned, planned: planned);
  }
}
