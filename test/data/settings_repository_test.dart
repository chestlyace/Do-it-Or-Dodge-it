import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';

import 'test_database.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = createTestDatabase();
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  test('returns null for a missing key', () async {
    expect(await settings.get(SettingsKeys.modelPath), isNull);
  });

  test('set then get', () async {
    await settings.set(SettingsKeys.modelPath, '/data/model.litertlm');
    expect(await settings.get(SettingsKeys.modelPath), '/data/model.litertlm');
  });

  test('set overwrites an existing value', () async {
    await settings.set(SettingsKeys.modelVersion, '1');
    await settings.set(SettingsKeys.modelVersion, '2');
    expect(await settings.get(SettingsKeys.modelVersion), '2');
  });

  test('getAll returns every key and remove deletes one', () async {
    await settings.set(SettingsKeys.quietHoursStart, '21:00');
    await settings.set(SettingsKeys.quietHoursEnd, '09:00');

    expect(await settings.getAll(), {
      SettingsKeys.quietHoursStart: '21:00',
      SettingsKeys.quietHoursEnd: '09:00',
    });

    await settings.remove(SettingsKeys.quietHoursStart);
    expect(await settings.get(SettingsKeys.quietHoursStart), isNull);
  });
}
