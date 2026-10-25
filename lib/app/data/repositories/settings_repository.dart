import 'package:drift/drift.dart';

import '../db/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<Map<String, String>> getAll() async {
    final rows = await _db.select(_db.settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> remove(String key) {
    return (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
  }

  /// Removes every setting whose key starts with [prefix].
  Future<int> removeWithPrefix(String prefix) {
    return (_db.delete(
      _db.settings,
    )..where((s) => s.key.like('$prefix%'))).go();
  }
}
