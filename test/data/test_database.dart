import 'package:drift/native.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';

/// A fresh in-memory database for one test.
AppDatabase createTestDatabase() => AppDatabase(NativeDatabase.memory());
