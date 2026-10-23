import 'package:drift/drift.dart';

import '../db/app_database.dart';

class ExcuseRepository {
  ExcuseRepository(this._db);

  final AppDatabase _db;

  Future<Excuse> create({
    required int taskId,
    required String recipientLabel,
    required String tone,
    required String text,
    DateTime? createdAt,
  }) {
    return _db
        .into(_db.excuses)
        .insertReturning(
          ExcusesCompanion.insert(
            taskId: taskId,
            recipientLabel: recipientLabel,
            tone: tone,
            body: text,
            createdAt: createdAt ?? DateTime.now(),
          ),
        );
  }

  Future<List<Excuse>> listForTask(int taskId) {
    return (_db.select(_db.excuses)
          ..where((e) => e.taskId.equals(taskId))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();
  }

  /// Most recent excuses used for [recipientLabel], newest first.
  Future<List<Excuse>> recentForRecipient(
    String recipientLabel, {
    int limit = 5,
  }) {
    return (_db.select(_db.excuses)
          ..where((e) => e.recipientLabel.equals(recipientLabel))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> markShared(int id) {
    return (_db.update(_db.excuses)..where((e) => e.id.equals(id))).write(
      const ExcusesCompanion(shared: Value(true)),
    );
  }
}
