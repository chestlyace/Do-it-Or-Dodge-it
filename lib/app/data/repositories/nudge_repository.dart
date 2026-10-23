import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/enums.dart';

class NudgeRepository {
  NudgeRepository(this._db);

  final AppDatabase _db;

  Future<Nudge> create({
    required int taskId,
    required DateTime fireAt,
    required NudgeLevel level,
    required String message,
    required int notificationId,
  }) {
    return _db
        .into(_db.nudges)
        .insertReturning(
          NudgesCompanion.insert(
            taskId: taskId,
            fireAt: fireAt,
            level: level,
            message: message,
            notificationId: notificationId,
          ),
        );
  }

  Future<Nudge?> getById(int id) {
    return (_db.select(
      _db.nudges,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  Future<List<Nudge>> listAll() {
    return (_db.select(
      _db.nudges,
    )..orderBy([(n) => OrderingTerm.asc(n.fireAt)])).get();
  }

  Future<List<Nudge>> listForTask(int taskId) {
    return (_db.select(_db.nudges)
          ..where((n) => n.taskId.equals(taskId))
          ..orderBy([(n) => OrderingTerm.asc(n.fireAt)]))
        .get();
  }

  /// Nudges that have not fired yet, soonest first.
  Future<List<Nudge>> listPending() {
    return (_db.select(_db.nudges)
          ..where((n) => n.fired.equals(false))
          ..orderBy([(n) => OrderingTerm.asc(n.fireAt)]))
        .get();
  }

  Future<void> markFired(int id) {
    return (_db.update(_db.nudges)..where((n) => n.id.equals(id))).write(
      const NudgesCompanion(fired: Value(true)),
    );
  }

  Future<void> markOpened(int id) {
    return (_db.update(_db.nudges)..where((n) => n.id.equals(id))).write(
      const NudgesCompanion(opened: Value(true)),
    );
  }

  /// Removes the task's nudges that have not fired yet.
  Future<int> deletePendingForTask(int taskId) {
    return (_db.delete(
      _db.nudges,
    )..where((n) => n.taskId.equals(taskId) & n.fired.equals(false))).go();
  }
}
