import 'package:drift/drift.dart';

import '../db/app_database.dart';

class NewStep {
  const NewStep({required this.title, required this.estMinutes});

  final String title;
  final int estMinutes;
}

class StepRepository {
  StepRepository(this._db);

  final AppDatabase _db;

  /// Inserts [steps] for [taskId], numbering positions from 0 in list order.
  Future<List<Step>> createAll(int taskId, List<NewStep> steps) {
    return _db.transaction(() async {
      final created = <Step>[];
      for (var i = 0; i < steps.length; i++) {
        created.add(
          await _db
              .into(_db.steps)
              .insertReturning(
                StepsCompanion.insert(
                  taskId: taskId,
                  position: i,
                  title: steps[i].title,
                  estMinutes: steps[i].estMinutes,
                ),
              ),
        );
      }
      return created;
    });
  }

  Future<List<Step>> listForTask(int taskId) {
    return (_db.select(_db.steps)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  Stream<List<Step>> watchForTask(int taskId) {
    return (_db.select(_db.steps)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .watch();
  }

  Future<void> markDone(int id, {DateTime? at}) {
    return (_db.update(_db.steps)..where((s) => s.id.equals(id))).write(
      StepsCompanion(doneAt: Value(at ?? DateTime.now())),
    );
  }

  Future<void> markUndone(int id) {
    return (_db.update(_db.steps)..where((s) => s.id.equals(id))).write(
      const StepsCompanion(doneAt: Value(null)),
    );
  }

  Future<void> setDraft(int id, String? draftText) {
    return (_db.update(_db.steps)..where((s) => s.id.equals(id))).write(
      StepsCompanion(draftText: Value(draftText)),
    );
  }

  /// First step by position that is not done yet, or null when all are done.
  Future<Step?> nextUndone(int taskId) async {
    final steps = await listForTask(taskId);
    for (final step in steps) {
      if (step.doneAt == null) return step;
    }
    return null;
  }

  Future<int> deleteForTask(int taskId) {
    return (_db.delete(_db.steps)..where((s) => s.taskId.equals(taskId))).go();
  }
}
