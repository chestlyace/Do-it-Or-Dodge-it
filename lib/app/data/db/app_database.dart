import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, Steps, Outcomes, Excuses, Nudges, Settings])
class AppDatabase extends _$AppDatabase {
  /// Pass [executor] in tests (for example an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'do_it_or_dodge_it'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Migration hook: add a step per schema version bump here.
    },
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless this is on; cascades need it.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
