import 'package:drift/drift.dart';

import '../models/enums.dart';

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get category => textEnum<TaskCategory>()();

  /// Free text typed by the user when [category] is `other`.
  TextColumn get customCategory => text().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(Constant(TaskStatus.open.name))();
  RealColumn get dodgeRisk => real().nullable()();
}

class Steps extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get title => text()();
  IntColumn get estMinutes => integer()();
  DateTimeColumn get doneAt => dateTime().nullable()();
  TextColumn get draftText => text().nullable()();
}

class Outcomes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get result => textEnum<OutcomeResult>()();
  DateTimeColumn get at => dateTime()();

  /// JSON of the features the predictor saw at decision time.
  TextColumn get featureSnapshot => text().withDefault(const Constant('{}'))();
}

class Excuses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipientLabel => text()();
  TextColumn get tone => text()();

  /// Stored in the SQL column `text`; named `body` because `text` is drift's builder.
  TextColumn get body => text().named('text')();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get shared => boolean().withDefault(const Constant(false))();
}

class Nudges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get fireAt => dateTime()();
  TextColumn get level => textEnum<NudgeLevel>()();
  TextColumn get message => text()();
  IntColumn get notificationId => integer()();
  BoolColumn get fired => boolean().withDefault(const Constant(false))();
  BoolColumn get opened => boolean().withDefault(const Constant(false))();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
