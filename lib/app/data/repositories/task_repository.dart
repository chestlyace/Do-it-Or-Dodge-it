import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/enums.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Future<Task> create({
    required String title,
    required TaskCategory category,
    String? note,
    String? customCategory,
    DateTime? dueAt,
    DateTime? createdAt,
  }) {
    return _db
        .into(_db.tasks)
        .insertReturning(
          TasksCompanion.insert(
            title: title,
            category: category,
            note: Value(note),
            customCategory: Value(customCategory),
            dueAt: Value(dueAt),
            createdAt: createdAt ?? DateTime.now(),
          ),
        );
  }

  Future<Task?> getById(int id) {
    return (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<Task?> watchById(int id) {
    return (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<List<Task>> listAll() {
    return (_db.select(
      _db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Stream<List<Task>> watchAll() {
    return (_db.select(
      _db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<Task>> listByStatus(TaskStatus status) {
    return (_db.select(_db.tasks)
          ..where((t) => t.status.equals(status.name))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<bool> update(Task task) => _db.update(_db.tasks).replace(task);

  Future<void> updateStatus(int id, TaskStatus status) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(status: Value(status)),
    );
  }

  Future<void> setDodgeRisk(int id, double? risk) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(dodgeRisk: Value(risk)),
    );
  }

  /// Deleting a task also deletes its steps, outcomes, excuses and nudges.
  Future<int> delete(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes every task, and with them all steps, outcomes, excuses and
  /// nudges.
  Future<int> deleteAll() => _db.delete(_db.tasks).go();
}
