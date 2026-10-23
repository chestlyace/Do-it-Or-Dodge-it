import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/enums.dart';

class OutcomeRepository {
  OutcomeRepository(this._db);

  final AppDatabase _db;

  /// [featureSnapshot] is what the predictor knew at decision time.
  Future<Outcome> record({
    required int taskId,
    required OutcomeResult result,
    Map<String, dynamic> featureSnapshot = const {},
    DateTime? at,
  }) {
    return _db
        .into(_db.outcomes)
        .insertReturning(
          OutcomesCompanion.insert(
            taskId: taskId,
            result: result,
            at: at ?? DateTime.now(),
            featureSnapshot: Value(jsonEncode(featureSnapshot)),
          ),
        );
  }

  Future<List<Outcome>> listAll() {
    return (_db.select(
      _db.outcomes,
    )..orderBy([(o) => OrderingTerm.desc(o.at)])).get();
  }

  Stream<List<Outcome>> watchAll() {
    return (_db.select(
      _db.outcomes,
    )..orderBy([(o) => OrderingTerm.desc(o.at)])).watch();
  }

  Future<List<Outcome>> listForTask(int taskId) {
    return (_db.select(_db.outcomes)
          ..where((o) => o.taskId.equals(taskId))
          ..orderBy([(o) => OrderingTerm.desc(o.at)]))
        .get();
  }

  Future<int> countByResult(OutcomeResult result) async {
    final count = _db.outcomes.id.count();
    final query = _db.selectOnly(_db.outcomes)
      ..addColumns([count])
      ..where(_db.outcomes.result.equals(result.name));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Decodes the JSON feature snapshot saved with an outcome.
  Map<String, dynamic> snapshotOf(Outcome outcome) {
    return Map<String, dynamic>.from(
      jsonDecode(outcome.featureSnapshot) as Map,
    );
  }
}
