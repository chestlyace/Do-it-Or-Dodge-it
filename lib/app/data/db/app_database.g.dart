// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskCategory, String> category =
      GeneratedColumn<String>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TaskCategory>($TasksTable.$convertercategory);
  static const VerificationMeta _customCategoryMeta = const VerificationMeta(
    'customCategory',
  );
  @override
  late final GeneratedColumn<String> customCategory = GeneratedColumn<String>(
    'custom_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(TaskStatus.open.name),
      ).withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _dodgeRiskMeta = const VerificationMeta(
    'dodgeRisk',
  );
  @override
  late final GeneratedColumn<double> dodgeRisk = GeneratedColumn<double>(
    'dodge_risk',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    note,
    category,
    customCategory,
    dueAt,
    createdAt,
    status,
    dodgeRisk,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('custom_category')) {
      context.handle(
        _customCategoryMeta,
        customCategory.isAcceptableOrUnknown(
          data['custom_category']!,
          _customCategoryMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('dodge_risk')) {
      context.handle(
        _dodgeRiskMeta,
        dodgeRisk.isAcceptableOrUnknown(data['dodge_risk']!, _dodgeRiskMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      category: $TasksTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      customCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_category'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: $TasksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      dodgeRisk: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}dodge_risk'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskCategory, String, String> $convertercategory =
      const EnumNameConverter<TaskCategory>(TaskCategory.values);
  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final String? note;
  final TaskCategory category;

  /// Free text typed by the user when [category] is `other`.
  final String? customCategory;
  final DateTime? dueAt;
  final DateTime createdAt;
  final TaskStatus status;
  final double? dodgeRisk;
  const Task({
    required this.id,
    required this.title,
    this.note,
    required this.category,
    this.customCategory,
    this.dueAt,
    required this.createdAt,
    required this.status,
    this.dodgeRisk,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['category'] = Variable<String>(
        $TasksTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || customCategory != null) {
      map['custom_category'] = Variable<String>(customCategory);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || dodgeRisk != null) {
      map['dodge_risk'] = Variable<double>(dodgeRisk);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      category: Value(category),
      customCategory: customCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(customCategory),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      createdAt: Value(createdAt),
      status: Value(status),
      dodgeRisk: dodgeRisk == null && nullToAbsent
          ? const Value.absent()
          : Value(dodgeRisk),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      category: $TasksTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      customCategory: serializer.fromJson<String?>(json['customCategory']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: $TasksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      dodgeRisk: serializer.fromJson<double?>(json['dodgeRisk']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'category': serializer.toJson<String>(
        $TasksTable.$convertercategory.toJson(category),
      ),
      'customCategory': serializer.toJson<String?>(customCategory),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(
        $TasksTable.$converterstatus.toJson(status),
      ),
      'dodgeRisk': serializer.toJson<double?>(dodgeRisk),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    Value<String?> note = const Value.absent(),
    TaskCategory? category,
    Value<String?> customCategory = const Value.absent(),
    Value<DateTime?> dueAt = const Value.absent(),
    DateTime? createdAt,
    TaskStatus? status,
    Value<double?> dodgeRisk = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    category: category ?? this.category,
    customCategory: customCategory.present
        ? customCategory.value
        : this.customCategory,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    dodgeRisk: dodgeRisk.present ? dodgeRisk.value : this.dodgeRisk,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      category: data.category.present ? data.category.value : this.category,
      customCategory: data.customCategory.present
          ? data.customCategory.value
          : this.customCategory,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      dodgeRisk: data.dodgeRisk.present ? data.dodgeRisk.value : this.dodgeRisk,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('customCategory: $customCategory, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('dodgeRisk: $dodgeRisk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    note,
    category,
    customCategory,
    dueAt,
    createdAt,
    status,
    dodgeRisk,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.category == this.category &&
          other.customCategory == this.customCategory &&
          other.dueAt == this.dueAt &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.dodgeRisk == this.dodgeRisk);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<TaskCategory> category;
  final Value<String?> customCategory;
  final Value<DateTime?> dueAt;
  final Value<DateTime> createdAt;
  final Value<TaskStatus> status;
  final Value<double?> dodgeRisk;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.category = const Value.absent(),
    this.customCategory = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.dodgeRisk = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required TaskCategory category,
    this.customCategory = const Value.absent(),
    this.dueAt = const Value.absent(),
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.dodgeRisk = const Value.absent(),
  }) : title = Value(title),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? category,
    Expression<String>? customCategory,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<double>? dodgeRisk,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (category != null) 'category': category,
      if (customCategory != null) 'custom_category': customCategory,
      if (dueAt != null) 'due_at': dueAt,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (dodgeRisk != null) 'dodge_risk': dodgeRisk,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? note,
    Value<TaskCategory>? category,
    Value<String?>? customCategory,
    Value<DateTime?>? dueAt,
    Value<DateTime>? createdAt,
    Value<TaskStatus>? status,
    Value<double?>? dodgeRisk,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      dodgeRisk: dodgeRisk ?? this.dodgeRisk,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $TasksTable.$convertercategory.toSql(category.value),
      );
    }
    if (customCategory.present) {
      map['custom_category'] = Variable<String>(customCategory.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TasksTable.$converterstatus.toSql(status.value),
      );
    }
    if (dodgeRisk.present) {
      map['dodge_risk'] = Variable<double>(dodgeRisk.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('category: $category, ')
          ..write('customCategory: $customCategory, ')
          ..write('dueAt: $dueAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('dodgeRisk: $dodgeRisk')
          ..write(')'))
        .toString();
  }
}

class $StepsTable extends Steps with TableInfo<$StepsTable, Step> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estMinutesMeta = const VerificationMeta(
    'estMinutes',
  );
  @override
  late final GeneratedColumn<int> estMinutes = GeneratedColumn<int>(
    'est_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<DateTime> doneAt = GeneratedColumn<DateTime>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _draftTextMeta = const VerificationMeta(
    'draftText',
  );
  @override
  late final GeneratedColumn<String> draftText = GeneratedColumn<String>(
    'draft_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    position,
    title,
    estMinutes,
    doneAt,
    draftText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<Step> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('est_minutes')) {
      context.handle(
        _estMinutesMeta,
        estMinutes.isAcceptableOrUnknown(data['est_minutes']!, _estMinutesMeta),
      );
    } else if (isInserting) {
      context.missing(_estMinutesMeta);
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    if (data.containsKey('draft_text')) {
      context.handle(
        _draftTextMeta,
        draftText.isAcceptableOrUnknown(data['draft_text']!, _draftTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Step map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Step(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      estMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}est_minutes'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}done_at'],
      ),
      draftText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_text'],
      ),
    );
  }

  @override
  $StepsTable createAlias(String alias) {
    return $StepsTable(attachedDatabase, alias);
  }
}

class Step extends DataClass implements Insertable<Step> {
  final int id;
  final int taskId;
  final int position;
  final String title;
  final int estMinutes;
  final DateTime? doneAt;
  final String? draftText;
  const Step({
    required this.id,
    required this.taskId,
    required this.position,
    required this.title,
    required this.estMinutes,
    this.doneAt,
    this.draftText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['position'] = Variable<int>(position);
    map['title'] = Variable<String>(title);
    map['est_minutes'] = Variable<int>(estMinutes);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<DateTime>(doneAt);
    }
    if (!nullToAbsent || draftText != null) {
      map['draft_text'] = Variable<String>(draftText);
    }
    return map;
  }

  StepsCompanion toCompanion(bool nullToAbsent) {
    return StepsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      position: Value(position),
      title: Value(title),
      estMinutes: Value(estMinutes),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
      draftText: draftText == null && nullToAbsent
          ? const Value.absent()
          : Value(draftText),
    );
  }

  factory Step.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Step(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      position: serializer.fromJson<int>(json['position']),
      title: serializer.fromJson<String>(json['title']),
      estMinutes: serializer.fromJson<int>(json['estMinutes']),
      doneAt: serializer.fromJson<DateTime?>(json['doneAt']),
      draftText: serializer.fromJson<String?>(json['draftText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'position': serializer.toJson<int>(position),
      'title': serializer.toJson<String>(title),
      'estMinutes': serializer.toJson<int>(estMinutes),
      'doneAt': serializer.toJson<DateTime?>(doneAt),
      'draftText': serializer.toJson<String?>(draftText),
    };
  }

  Step copyWith({
    int? id,
    int? taskId,
    int? position,
    String? title,
    int? estMinutes,
    Value<DateTime?> doneAt = const Value.absent(),
    Value<String?> draftText = const Value.absent(),
  }) => Step(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    position: position ?? this.position,
    title: title ?? this.title,
    estMinutes: estMinutes ?? this.estMinutes,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
    draftText: draftText.present ? draftText.value : this.draftText,
  );
  Step copyWithCompanion(StepsCompanion data) {
    return Step(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      position: data.position.present ? data.position.value : this.position,
      title: data.title.present ? data.title.value : this.title,
      estMinutes: data.estMinutes.present
          ? data.estMinutes.value
          : this.estMinutes,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
      draftText: data.draftText.present ? data.draftText.value : this.draftText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Step(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('doneAt: $doneAt, ')
          ..write('draftText: $draftText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, position, title, estMinutes, doneAt, draftText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Step &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.position == this.position &&
          other.title == this.title &&
          other.estMinutes == this.estMinutes &&
          other.doneAt == this.doneAt &&
          other.draftText == this.draftText);
}

class StepsCompanion extends UpdateCompanion<Step> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> position;
  final Value<String> title;
  final Value<int> estMinutes;
  final Value<DateTime?> doneAt;
  final Value<String?> draftText;
  const StepsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.position = const Value.absent(),
    this.title = const Value.absent(),
    this.estMinutes = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.draftText = const Value.absent(),
  });
  StepsCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int position,
    required String title,
    required int estMinutes,
    this.doneAt = const Value.absent(),
    this.draftText = const Value.absent(),
  }) : taskId = Value(taskId),
       position = Value(position),
       title = Value(title),
       estMinutes = Value(estMinutes);
  static Insertable<Step> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? position,
    Expression<String>? title,
    Expression<int>? estMinutes,
    Expression<DateTime>? doneAt,
    Expression<String>? draftText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (position != null) 'position': position,
      if (title != null) 'title': title,
      if (estMinutes != null) 'est_minutes': estMinutes,
      if (doneAt != null) 'done_at': doneAt,
      if (draftText != null) 'draft_text': draftText,
    });
  }

  StepsCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? position,
    Value<String>? title,
    Value<int>? estMinutes,
    Value<DateTime?>? doneAt,
    Value<String?>? draftText,
  }) {
    return StepsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      position: position ?? this.position,
      title: title ?? this.title,
      estMinutes: estMinutes ?? this.estMinutes,
      doneAt: doneAt ?? this.doneAt,
      draftText: draftText ?? this.draftText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (estMinutes.present) {
      map['est_minutes'] = Variable<int>(estMinutes.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<DateTime>(doneAt.value);
    }
    if (draftText.present) {
      map['draft_text'] = Variable<String>(draftText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('estMinutes: $estMinutes, ')
          ..write('doneAt: $doneAt, ')
          ..write('draftText: $draftText')
          ..write(')'))
        .toString();
  }
}

class $OutcomesTable extends Outcomes with TableInfo<$OutcomesTable, Outcome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutcomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<OutcomeResult, String> result =
      GeneratedColumn<String>(
        'result',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<OutcomeResult>($OutcomesTable.$converterresult);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _featureSnapshotMeta = const VerificationMeta(
    'featureSnapshot',
  );
  @override
  late final GeneratedColumn<String> featureSnapshot = GeneratedColumn<String>(
    'feature_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    result,
    at,
    featureSnapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outcomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Outcome> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('feature_snapshot')) {
      context.handle(
        _featureSnapshotMeta,
        featureSnapshot.isAcceptableOrUnknown(
          data['feature_snapshot']!,
          _featureSnapshotMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Outcome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Outcome(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      result: $OutcomesTable.$converterresult.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}result'],
        )!,
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      featureSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature_snapshot'],
      )!,
    );
  }

  @override
  $OutcomesTable createAlias(String alias) {
    return $OutcomesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutcomeResult, String, String> $converterresult =
      const EnumNameConverter<OutcomeResult>(OutcomeResult.values);
}

class Outcome extends DataClass implements Insertable<Outcome> {
  final int id;
  final int taskId;
  final OutcomeResult result;
  final DateTime at;

  /// JSON of the features the predictor saw at decision time.
  final String featureSnapshot;
  const Outcome({
    required this.id,
    required this.taskId,
    required this.result,
    required this.at,
    required this.featureSnapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    {
      map['result'] = Variable<String>(
        $OutcomesTable.$converterresult.toSql(result),
      );
    }
    map['at'] = Variable<DateTime>(at);
    map['feature_snapshot'] = Variable<String>(featureSnapshot);
    return map;
  }

  OutcomesCompanion toCompanion(bool nullToAbsent) {
    return OutcomesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      result: Value(result),
      at: Value(at),
      featureSnapshot: Value(featureSnapshot),
    );
  }

  factory Outcome.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Outcome(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      result: $OutcomesTable.$converterresult.fromJson(
        serializer.fromJson<String>(json['result']),
      ),
      at: serializer.fromJson<DateTime>(json['at']),
      featureSnapshot: serializer.fromJson<String>(json['featureSnapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'result': serializer.toJson<String>(
        $OutcomesTable.$converterresult.toJson(result),
      ),
      'at': serializer.toJson<DateTime>(at),
      'featureSnapshot': serializer.toJson<String>(featureSnapshot),
    };
  }

  Outcome copyWith({
    int? id,
    int? taskId,
    OutcomeResult? result,
    DateTime? at,
    String? featureSnapshot,
  }) => Outcome(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    result: result ?? this.result,
    at: at ?? this.at,
    featureSnapshot: featureSnapshot ?? this.featureSnapshot,
  );
  Outcome copyWithCompanion(OutcomesCompanion data) {
    return Outcome(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      result: data.result.present ? data.result.value : this.result,
      at: data.at.present ? data.at.value : this.at,
      featureSnapshot: data.featureSnapshot.present
          ? data.featureSnapshot.value
          : this.featureSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Outcome(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('result: $result, ')
          ..write('at: $at, ')
          ..write('featureSnapshot: $featureSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, result, at, featureSnapshot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Outcome &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.result == this.result &&
          other.at == this.at &&
          other.featureSnapshot == this.featureSnapshot);
}

class OutcomesCompanion extends UpdateCompanion<Outcome> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<OutcomeResult> result;
  final Value<DateTime> at;
  final Value<String> featureSnapshot;
  const OutcomesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.result = const Value.absent(),
    this.at = const Value.absent(),
    this.featureSnapshot = const Value.absent(),
  });
  OutcomesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required OutcomeResult result,
    required DateTime at,
    this.featureSnapshot = const Value.absent(),
  }) : taskId = Value(taskId),
       result = Value(result),
       at = Value(at);
  static Insertable<Outcome> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? result,
    Expression<DateTime>? at,
    Expression<String>? featureSnapshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (result != null) 'result': result,
      if (at != null) 'at': at,
      if (featureSnapshot != null) 'feature_snapshot': featureSnapshot,
    });
  }

  OutcomesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<OutcomeResult>? result,
    Value<DateTime>? at,
    Value<String>? featureSnapshot,
  }) {
    return OutcomesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      result: result ?? this.result,
      at: at ?? this.at,
      featureSnapshot: featureSnapshot ?? this.featureSnapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(
        $OutcomesTable.$converterresult.toSql(result.value),
      );
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (featureSnapshot.present) {
      map['feature_snapshot'] = Variable<String>(featureSnapshot.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutcomesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('result: $result, ')
          ..write('at: $at, ')
          ..write('featureSnapshot: $featureSnapshot')
          ..write(')'))
        .toString();
  }
}

class $ExcusesTable extends Excuses with TableInfo<$ExcusesTable, Excuse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExcusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recipientLabelMeta = const VerificationMeta(
    'recipientLabel',
  );
  @override
  late final GeneratedColumn<String> recipientLabel = GeneratedColumn<String>(
    'recipient_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<String> tone = GeneratedColumn<String>(
    'tone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sharedMeta = const VerificationMeta('shared');
  @override
  late final GeneratedColumn<bool> shared = GeneratedColumn<bool>(
    'shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    recipientLabel,
    tone,
    body,
    createdAt,
    shared,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'excuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Excuse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('recipient_label')) {
      context.handle(
        _recipientLabelMeta,
        recipientLabel.isAcceptableOrUnknown(
          data['recipient_label']!,
          _recipientLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recipientLabelMeta);
    }
    if (data.containsKey('tone')) {
      context.handle(
        _toneMeta,
        tone.isAcceptableOrUnknown(data['tone']!, _toneMeta),
      );
    } else if (isInserting) {
      context.missing(_toneMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('shared')) {
      context.handle(
        _sharedMeta,
        shared.isAcceptableOrUnknown(data['shared']!, _sharedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Excuse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Excuse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      recipientLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipient_label'],
      )!,
      tone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tone'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      shared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shared'],
      )!,
    );
  }

  @override
  $ExcusesTable createAlias(String alias) {
    return $ExcusesTable(attachedDatabase, alias);
  }
}

class Excuse extends DataClass implements Insertable<Excuse> {
  final int id;
  final int taskId;
  final String recipientLabel;
  final String tone;

  /// Stored in the SQL column `text`; named `body` because `text` is drift's builder.
  final String body;
  final DateTime createdAt;
  final bool shared;
  const Excuse({
    required this.id,
    required this.taskId,
    required this.recipientLabel,
    required this.tone,
    required this.body,
    required this.createdAt,
    required this.shared,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['recipient_label'] = Variable<String>(recipientLabel);
    map['tone'] = Variable<String>(tone);
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['shared'] = Variable<bool>(shared);
    return map;
  }

  ExcusesCompanion toCompanion(bool nullToAbsent) {
    return ExcusesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      recipientLabel: Value(recipientLabel),
      tone: Value(tone),
      body: Value(body),
      createdAt: Value(createdAt),
      shared: Value(shared),
    );
  }

  factory Excuse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Excuse(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      recipientLabel: serializer.fromJson<String>(json['recipientLabel']),
      tone: serializer.fromJson<String>(json['tone']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      shared: serializer.fromJson<bool>(json['shared']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'recipientLabel': serializer.toJson<String>(recipientLabel),
      'tone': serializer.toJson<String>(tone),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'shared': serializer.toJson<bool>(shared),
    };
  }

  Excuse copyWith({
    int? id,
    int? taskId,
    String? recipientLabel,
    String? tone,
    String? body,
    DateTime? createdAt,
    bool? shared,
  }) => Excuse(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    recipientLabel: recipientLabel ?? this.recipientLabel,
    tone: tone ?? this.tone,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    shared: shared ?? this.shared,
  );
  Excuse copyWithCompanion(ExcusesCompanion data) {
    return Excuse(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      recipientLabel: data.recipientLabel.present
          ? data.recipientLabel.value
          : this.recipientLabel,
      tone: data.tone.present ? data.tone.value : this.tone,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      shared: data.shared.present ? data.shared.value : this.shared,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Excuse(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('recipientLabel: $recipientLabel, ')
          ..write('tone: $tone, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('shared: $shared')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, recipientLabel, tone, body, createdAt, shared);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Excuse &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.recipientLabel == this.recipientLabel &&
          other.tone == this.tone &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.shared == this.shared);
}

class ExcusesCompanion extends UpdateCompanion<Excuse> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<String> recipientLabel;
  final Value<String> tone;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<bool> shared;
  const ExcusesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.recipientLabel = const Value.absent(),
    this.tone = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.shared = const Value.absent(),
  });
  ExcusesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required String recipientLabel,
    required String tone,
    required String body,
    required DateTime createdAt,
    this.shared = const Value.absent(),
  }) : taskId = Value(taskId),
       recipientLabel = Value(recipientLabel),
       tone = Value(tone),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<Excuse> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<String>? recipientLabel,
    Expression<String>? tone,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<bool>? shared,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (recipientLabel != null) 'recipient_label': recipientLabel,
      if (tone != null) 'tone': tone,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
      if (shared != null) 'shared': shared,
    });
  }

  ExcusesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<String>? recipientLabel,
    Value<String>? tone,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<bool>? shared,
  }) {
    return ExcusesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      recipientLabel: recipientLabel ?? this.recipientLabel,
      tone: tone ?? this.tone,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      shared: shared ?? this.shared,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (recipientLabel.present) {
      map['recipient_label'] = Variable<String>(recipientLabel.value);
    }
    if (tone.present) {
      map['tone'] = Variable<String>(tone.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (shared.present) {
      map['shared'] = Variable<bool>(shared.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExcusesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('recipientLabel: $recipientLabel, ')
          ..write('tone: $tone, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('shared: $shared')
          ..write(')'))
        .toString();
  }
}

class $NudgesTable extends Nudges with TableInfo<$NudgesTable, Nudge> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NudgesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<DateTime> fireAt = GeneratedColumn<DateTime>(
    'fire_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<NudgeLevel, String> level =
      GeneratedColumn<String>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NudgeLevel>($NudgesTable.$converterlevel);
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firedMeta = const VerificationMeta('fired');
  @override
  late final GeneratedColumn<bool> fired = GeneratedColumn<bool>(
    'fired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("fired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openedMeta = const VerificationMeta('opened');
  @override
  late final GeneratedColumn<bool> opened = GeneratedColumn<bool>(
    'opened',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("opened" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    fireAt,
    level,
    message,
    notificationId,
    fired,
    opened,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nudges';
  @override
  VerificationContext validateIntegrity(
    Insertable<Nudge> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('fire_at')) {
      context.handle(
        _fireAtMeta,
        fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    if (data.containsKey('fired')) {
      context.handle(
        _firedMeta,
        fired.isAcceptableOrUnknown(data['fired']!, _firedMeta),
      );
    }
    if (data.containsKey('opened')) {
      context.handle(
        _openedMeta,
        opened.isAcceptableOrUnknown(data['opened']!, _openedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Nudge map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Nudge(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}task_id'],
      )!,
      fireAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fire_at'],
      )!,
      level: $NudgesTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}level'],
        )!,
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
      fired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}fired'],
      )!,
      opened: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}opened'],
      )!,
    );
  }

  @override
  $NudgesTable createAlias(String alias) {
    return $NudgesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NudgeLevel, String, String> $converterlevel =
      const EnumNameConverter<NudgeLevel>(NudgeLevel.values);
}

class Nudge extends DataClass implements Insertable<Nudge> {
  final int id;
  final int taskId;
  final DateTime fireAt;
  final NudgeLevel level;
  final String message;
  final int notificationId;
  final bool fired;
  final bool opened;
  const Nudge({
    required this.id,
    required this.taskId,
    required this.fireAt,
    required this.level,
    required this.message,
    required this.notificationId,
    required this.fired,
    required this.opened,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['fire_at'] = Variable<DateTime>(fireAt);
    {
      map['level'] = Variable<String>(
        $NudgesTable.$converterlevel.toSql(level),
      );
    }
    map['message'] = Variable<String>(message);
    map['notification_id'] = Variable<int>(notificationId);
    map['fired'] = Variable<bool>(fired);
    map['opened'] = Variable<bool>(opened);
    return map;
  }

  NudgesCompanion toCompanion(bool nullToAbsent) {
    return NudgesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      fireAt: Value(fireAt),
      level: Value(level),
      message: Value(message),
      notificationId: Value(notificationId),
      fired: Value(fired),
      opened: Value(opened),
    );
  }

  factory Nudge.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Nudge(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      fireAt: serializer.fromJson<DateTime>(json['fireAt']),
      level: $NudgesTable.$converterlevel.fromJson(
        serializer.fromJson<String>(json['level']),
      ),
      message: serializer.fromJson<String>(json['message']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
      fired: serializer.fromJson<bool>(json['fired']),
      opened: serializer.fromJson<bool>(json['opened']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'fireAt': serializer.toJson<DateTime>(fireAt),
      'level': serializer.toJson<String>(
        $NudgesTable.$converterlevel.toJson(level),
      ),
      'message': serializer.toJson<String>(message),
      'notificationId': serializer.toJson<int>(notificationId),
      'fired': serializer.toJson<bool>(fired),
      'opened': serializer.toJson<bool>(opened),
    };
  }

  Nudge copyWith({
    int? id,
    int? taskId,
    DateTime? fireAt,
    NudgeLevel? level,
    String? message,
    int? notificationId,
    bool? fired,
    bool? opened,
  }) => Nudge(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    fireAt: fireAt ?? this.fireAt,
    level: level ?? this.level,
    message: message ?? this.message,
    notificationId: notificationId ?? this.notificationId,
    fired: fired ?? this.fired,
    opened: opened ?? this.opened,
  );
  Nudge copyWithCompanion(NudgesCompanion data) {
    return Nudge(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
      level: data.level.present ? data.level.value : this.level,
      message: data.message.present ? data.message.value : this.message,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
      fired: data.fired.present ? data.fired.value : this.fired,
      opened: data.opened.present ? data.opened.value : this.opened,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Nudge(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('fireAt: $fireAt, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('notificationId: $notificationId, ')
          ..write('fired: $fired, ')
          ..write('opened: $opened')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    fireAt,
    level,
    message,
    notificationId,
    fired,
    opened,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Nudge &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.fireAt == this.fireAt &&
          other.level == this.level &&
          other.message == this.message &&
          other.notificationId == this.notificationId &&
          other.fired == this.fired &&
          other.opened == this.opened);
}

class NudgesCompanion extends UpdateCompanion<Nudge> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<DateTime> fireAt;
  final Value<NudgeLevel> level;
  final Value<String> message;
  final Value<int> notificationId;
  final Value<bool> fired;
  final Value<bool> opened;
  const NudgesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.fired = const Value.absent(),
    this.opened = const Value.absent(),
  });
  NudgesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required DateTime fireAt,
    required NudgeLevel level,
    required String message,
    required int notificationId,
    this.fired = const Value.absent(),
    this.opened = const Value.absent(),
  }) : taskId = Value(taskId),
       fireAt = Value(fireAt),
       level = Value(level),
       message = Value(message),
       notificationId = Value(notificationId);
  static Insertable<Nudge> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<DateTime>? fireAt,
    Expression<String>? level,
    Expression<String>? message,
    Expression<int>? notificationId,
    Expression<bool>? fired,
    Expression<bool>? opened,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (fireAt != null) 'fire_at': fireAt,
      if (level != null) 'level': level,
      if (message != null) 'message': message,
      if (notificationId != null) 'notification_id': notificationId,
      if (fired != null) 'fired': fired,
      if (opened != null) 'opened': opened,
    });
  }

  NudgesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<DateTime>? fireAt,
    Value<NudgeLevel>? level,
    Value<String>? message,
    Value<int>? notificationId,
    Value<bool>? fired,
    Value<bool>? opened,
  }) {
    return NudgesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      fireAt: fireAt ?? this.fireAt,
      level: level ?? this.level,
      message: message ?? this.message,
      notificationId: notificationId ?? this.notificationId,
      fired: fired ?? this.fired,
      opened: opened ?? this.opened,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<DateTime>(fireAt.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(
        $NudgesTable.$converterlevel.toSql(level.value),
      );
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (fired.present) {
      map['fired'] = Variable<bool>(fired.value);
    }
    if (opened.present) {
      map['opened'] = Variable<bool>(opened.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NudgesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('fireAt: $fireAt, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('notificationId: $notificationId, ')
          ..write('fired: $fired, ')
          ..write('opened: $opened')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $StepsTable steps = $StepsTable(this);
  late final $OutcomesTable outcomes = $OutcomesTable(this);
  late final $ExcusesTable excuses = $ExcusesTable(this);
  late final $NudgesTable nudges = $NudgesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    steps,
    outcomes,
    excuses,
    nudges,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('steps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('outcomes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('excuses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nudges', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> note,
  required TaskCategory category,
  Value<String?> customCategory,
  Value<DateTime?> dueAt,
  required DateTime createdAt,
  Value<TaskStatus> status,
  Value<double?> dodgeRisk,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> note,
  Value<TaskCategory> category,
  Value<String?> customCategory,
  Value<DateTime?> dueAt,
  Value<DateTime> createdAt,
  Value<TaskStatus> status,
  Value<double?> dodgeRisk,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StepsTable, List<Step>> _stepsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.steps,
    aliasName: 'tasks__id__steps__task_id',
  );

  $$StepsTableProcessedTableManager get stepsRefs {
    final manager = $$StepsTableTableManager(
      $_db,
      $_db.steps,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_stepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutcomesTable, List<Outcome>> _outcomesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.outcomes,
    aliasName: 'tasks__id__outcomes__task_id',
  );

  $$OutcomesTableProcessedTableManager get outcomesRefs {
    final manager = $$OutcomesTableTableManager(
      $_db,
      $_db.outcomes,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_outcomesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExcusesTable, List<Excuse>> _excusesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.excuses,
    aliasName: 'tasks__id__excuses__task_id',
  );

  $$ExcusesTableProcessedTableManager get excusesRefs {
    final manager = $$ExcusesTableTableManager(
      $_db,
      $_db.excuses,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_excusesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NudgesTable, List<Nudge>> _nudgesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nudges,
    aliasName: 'tasks__id__nudges__task_id',
  );

  $$NudgesTableProcessedTableManager get nudgesRefs {
    final manager = $$NudgesTableTableManager(
      $_db,
      $_db.nudges,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nudgesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskCategory, TaskCategory, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get dodgeRisk => $composableBuilder(
    column: $table.dodgeRisk,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stepsRefs(
    Expression<bool> Function($$StepsTableFilterComposer f) f,
  ) {
    final $$StepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableFilterComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outcomesRefs(
    Expression<bool> Function($$OutcomesTableFilterComposer f) f,
  ) {
    final $$OutcomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outcomes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutcomesTableFilterComposer(
            $db: $db,
            $table: $db.outcomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> excusesRefs(
    Expression<bool> Function($$ExcusesTableFilterComposer f) f,
  ) {
    final $$ExcusesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.excuses,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExcusesTableFilterComposer(
            $db: $db,
            $table: $db.excuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nudgesRefs(
    Expression<bool> Function($$NudgesTableFilterComposer f) f,
  ) {
    final $$NudgesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nudges,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NudgesTableFilterComposer(
            $db: $db,
            $table: $db.nudges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dodgeRisk => $composableBuilder(
    column: $table.dodgeRisk,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get customCategory => $composableBuilder(
    column: $table.customCategory,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get dodgeRisk =>
      $composableBuilder(column: $table.dodgeRisk, builder: (column) => column);

  Expression<T> stepsRefs<T extends Object>(
    Expression<T> Function($$StepsTableAnnotationComposer a) f,
  ) {
    final $$StepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.steps,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StepsTableAnnotationComposer(
            $db: $db,
            $table: $db.steps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outcomesRefs<T extends Object>(
    Expression<T> Function($$OutcomesTableAnnotationComposer a) f,
  ) {
    final $$OutcomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outcomes,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutcomesTableAnnotationComposer(
            $db: $db,
            $table: $db.outcomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> excusesRefs<T extends Object>(
    Expression<T> Function($$ExcusesTableAnnotationComposer a) f,
  ) {
    final $$ExcusesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.excuses,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExcusesTableAnnotationComposer(
            $db: $db,
            $table: $db.excuses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nudgesRefs<T extends Object>(
    Expression<T> Function($$NudgesTableAnnotationComposer a) f,
  ) {
    final $$NudgesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nudges,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NudgesTableAnnotationComposer(
            $db: $db,
            $table: $db.nudges,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool stepsRefs,
            bool outcomesRefs,
            bool excusesRefs,
            bool nudgesRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<TaskCategory> category = const Value.absent(),
                Value<String?> customCategory = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<TaskStatus> status = const Value.absent(),
                Value<double?> dodgeRisk = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                note: note,
                category: category,
                customCategory: customCategory,
                dueAt: dueAt,
                createdAt: createdAt,
                status: status,
                dodgeRisk: dodgeRisk,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required TaskCategory category,
                Value<String?> customCategory = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                required DateTime createdAt,
                Value<TaskStatus> status = const Value.absent(),
                Value<double?> dodgeRisk = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                note: note,
                category: category,
                customCategory: customCategory,
                dueAt: dueAt,
                createdAt: createdAt,
                status: status,
                dodgeRisk: dodgeRisk,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                stepsRefs = false,
                outcomesRefs = false,
                excusesRefs = false,
                nudgesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stepsRefs) db.steps,
                    if (outcomesRefs) db.outcomes,
                    if (excusesRefs) db.excuses,
                    if (nudgesRefs) db.nudges,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stepsRefs)
                        await $_getPrefetchedDataByColumns<
                          Task,
                          $TasksTable,
                          Step,
                          $StepsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._stepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(db, table, p0).stepsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'task_id',
                          typedResults: items,
                        ),
                      if (outcomesRefs)
                        await $_getPrefetchedDataByColumns<
                          Task,
                          $TasksTable,
                          Outcome,
                          $OutcomesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._outcomesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).outcomesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'task_id',
                          typedResults: items,
                        ),
                      if (excusesRefs)
                        await $_getPrefetchedDataByColumns<
                          Task,
                          $TasksTable,
                          Excuse,
                          $ExcusesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._excusesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(db, table, p0).excusesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'task_id',
                          typedResults: items,
                        ),
                      if (nudgesRefs)
                        await $_getPrefetchedDataByColumns<
                          Task,
                          $TasksTable,
                          Nudge,
                          $NudgesTable
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._nudgesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(db, table, p0).nudgesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'task_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool stepsRefs,
        bool outcomesRefs,
        bool excusesRefs,
        bool nudgesRefs,
      })
    >;
typedef $$StepsTableCreateCompanionBuilder = StepsCompanion Function({
  Value<int> id,
  required int taskId,
  required int position,
  required String title,
  required int estMinutes,
  Value<DateTime?> doneAt,
  Value<String?> draftText,
});
typedef $$StepsTableUpdateCompanionBuilder = StepsCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<int> position,
  Value<String> title,
  Value<int> estMinutes,
  Value<DateTime?> doneAt,
  Value<String?> draftText,
});

final class $$StepsTableReferences
    extends BaseReferences<_$AppDatabase, $StepsTable, Step> {
  $$StepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('steps__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StepsTableFilterComposer extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get draftText => $composableBuilder(
    column: $table.draftText,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get draftText => $composableBuilder(
    column: $table.draftText,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepsTable> {
  $$StepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get estMinutes => $composableBuilder(
    column: $table.estMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);

  GeneratedColumn<String> get draftText =>
      $composableBuilder(column: $table.draftText, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepsTable,
          Step,
          $$StepsTableFilterComposer,
          $$StepsTableOrderingComposer,
          $$StepsTableAnnotationComposer,
          $$StepsTableCreateCompanionBuilder,
          $$StepsTableUpdateCompanionBuilder,
          (Step, $$StepsTableReferences),
          Step,
          PrefetchHooks Function({bool taskId})
        > {
  $$StepsTableTableManager(_$AppDatabase db, $StepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> estMinutes = const Value.absent(),
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> draftText = const Value.absent(),
              }) => StepsCompanion(
                id: id,
                taskId: taskId,
                position: position,
                title: title,
                estMinutes: estMinutes,
                doneAt: doneAt,
                draftText: draftText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required int position,
                required String title,
                required int estMinutes,
                Value<DateTime?> doneAt = const Value.absent(),
                Value<String?> draftText = const Value.absent(),
              }) => StepsCompanion.insert(
                id: id,
                taskId: taskId,
                position: position,
                title: title,
                estMinutes: estMinutes,
                doneAt: doneAt,
                draftText: draftText,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StepsTable, Step>(table),
                  $$StepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$StepsTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$StepsTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepsTable,
      Step,
      $$StepsTableFilterComposer,
      $$StepsTableOrderingComposer,
      $$StepsTableAnnotationComposer,
      $$StepsTableCreateCompanionBuilder,
      $$StepsTableUpdateCompanionBuilder,
      (Step, $$StepsTableReferences),
      Step,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$OutcomesTableCreateCompanionBuilder = OutcomesCompanion Function({
  Value<int> id,
  required int taskId,
  required OutcomeResult result,
  required DateTime at,
  Value<String> featureSnapshot,
});
typedef $$OutcomesTableUpdateCompanionBuilder = OutcomesCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<OutcomeResult> result,
  Value<DateTime> at,
  Value<String> featureSnapshot,
});

final class $$OutcomesTableReferences
    extends BaseReferences<_$AppDatabase, $OutcomesTable, Outcome> {
  $$OutcomesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('outcomes__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutcomesTableFilterComposer
    extends Composer<_$AppDatabase, $OutcomesTable> {
  $$OutcomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutcomeResult, OutcomeResult, String>
  get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get featureSnapshot => $composableBuilder(
    column: $table.featureSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutcomesTableOrderingComposer
    extends Composer<_$AppDatabase, $OutcomesTable> {
  $$OutcomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get featureSnapshot => $composableBuilder(
    column: $table.featureSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutcomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutcomesTable> {
  $$OutcomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutcomeResult, String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get featureSnapshot => $composableBuilder(
    column: $table.featureSnapshot,
    builder: (column) => column,
  );

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutcomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutcomesTable,
          Outcome,
          $$OutcomesTableFilterComposer,
          $$OutcomesTableOrderingComposer,
          $$OutcomesTableAnnotationComposer,
          $$OutcomesTableCreateCompanionBuilder,
          $$OutcomesTableUpdateCompanionBuilder,
          (Outcome, $$OutcomesTableReferences),
          Outcome,
          PrefetchHooks Function({bool taskId})
        > {
  $$OutcomesTableTableManager(_$AppDatabase db, $OutcomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutcomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutcomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutcomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<OutcomeResult> result = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> featureSnapshot = const Value.absent(),
              }) => OutcomesCompanion(
                id: id,
                taskId: taskId,
                result: result,
                at: at,
                featureSnapshot: featureSnapshot,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required OutcomeResult result,
                required DateTime at,
                Value<String> featureSnapshot = const Value.absent(),
              }) => OutcomesCompanion.insert(
                id: id,
                taskId: taskId,
                result: result,
                at: at,
                featureSnapshot: featureSnapshot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutcomesTable, Outcome>(table),
                  $$OutcomesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$OutcomesTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$OutcomesTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OutcomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutcomesTable,
      Outcome,
      $$OutcomesTableFilterComposer,
      $$OutcomesTableOrderingComposer,
      $$OutcomesTableAnnotationComposer,
      $$OutcomesTableCreateCompanionBuilder,
      $$OutcomesTableUpdateCompanionBuilder,
      (Outcome, $$OutcomesTableReferences),
      Outcome,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$ExcusesTableCreateCompanionBuilder = ExcusesCompanion Function({
  Value<int> id,
  required int taskId,
  required String recipientLabel,
  required String tone,
  required String body,
  required DateTime createdAt,
  Value<bool> shared,
});
typedef $$ExcusesTableUpdateCompanionBuilder = ExcusesCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<String> recipientLabel,
  Value<String> tone,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<bool> shared,
});

final class $$ExcusesTableReferences
    extends BaseReferences<_$AppDatabase, $ExcusesTable, Excuse> {
  $$ExcusesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('excuses__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExcusesTableFilterComposer
    extends Composer<_$AppDatabase, $ExcusesTable> {
  $$ExcusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recipientLabel => $composableBuilder(
    column: $table.recipientLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shared => $composableBuilder(
    column: $table.shared,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcusesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExcusesTable> {
  $$ExcusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recipientLabel => $composableBuilder(
    column: $table.recipientLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tone => $composableBuilder(
    column: $table.tone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shared => $composableBuilder(
    column: $table.shared,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExcusesTable> {
  $$ExcusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recipientLabel => $composableBuilder(
    column: $table.recipientLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get shared =>
      $composableBuilder(column: $table.shared, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExcusesTable,
          Excuse,
          $$ExcusesTableFilterComposer,
          $$ExcusesTableOrderingComposer,
          $$ExcusesTableAnnotationComposer,
          $$ExcusesTableCreateCompanionBuilder,
          $$ExcusesTableUpdateCompanionBuilder,
          (Excuse, $$ExcusesTableReferences),
          Excuse,
          PrefetchHooks Function({bool taskId})
        > {
  $$ExcusesTableTableManager(_$AppDatabase db, $ExcusesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExcusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExcusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExcusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<String> recipientLabel = const Value.absent(),
                Value<String> tone = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> shared = const Value.absent(),
              }) => ExcusesCompanion(
                id: id,
                taskId: taskId,
                recipientLabel: recipientLabel,
                tone: tone,
                body: body,
                createdAt: createdAt,
                shared: shared,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required String recipientLabel,
                required String tone,
                required String body,
                required DateTime createdAt,
                Value<bool> shared = const Value.absent(),
              }) => ExcusesCompanion.insert(
                id: id,
                taskId: taskId,
                recipientLabel: recipientLabel,
                tone: tone,
                body: body,
                createdAt: createdAt,
                shared: shared,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExcusesTable, Excuse>(table),
                  $$ExcusesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$ExcusesTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$ExcusesTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExcusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExcusesTable,
      Excuse,
      $$ExcusesTableFilterComposer,
      $$ExcusesTableOrderingComposer,
      $$ExcusesTableAnnotationComposer,
      $$ExcusesTableCreateCompanionBuilder,
      $$ExcusesTableUpdateCompanionBuilder,
      (Excuse, $$ExcusesTableReferences),
      Excuse,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$NudgesTableCreateCompanionBuilder = NudgesCompanion Function({
  Value<int> id,
  required int taskId,
  required DateTime fireAt,
  required NudgeLevel level,
  required String message,
  required int notificationId,
  Value<bool> fired,
  Value<bool> opened,
});
typedef $$NudgesTableUpdateCompanionBuilder = NudgesCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<DateTime> fireAt,
  Value<NudgeLevel> level,
  Value<String> message,
  Value<int> notificationId,
  Value<bool> fired,
  Value<bool> opened,
});

final class $$NudgesTableReferences
    extends BaseReferences<_$AppDatabase, $NudgesTable, Nudge> {
  $$NudgesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('nudges__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NudgesTableFilterComposer
    extends Composer<_$AppDatabase, $NudgesTable> {
  $$NudgesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NudgeLevel, NudgeLevel, String> get level =>
      $composableBuilder(
        column: $table.level,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fired => $composableBuilder(
    column: $table.fired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NudgesTableOrderingComposer
    extends Composer<_$AppDatabase, $NudgesTable> {
  $$NudgesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fireAt => $composableBuilder(
    column: $table.fireAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fired => $composableBuilder(
    column: $table.fired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get opened => $composableBuilder(
    column: $table.opened,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NudgesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NudgesTable> {
  $$NudgesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NudgeLevel, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fired =>
      $composableBuilder(column: $table.fired, builder: (column) => column);

  GeneratedColumn<bool> get opened =>
      $composableBuilder(column: $table.opened, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NudgesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NudgesTable,
          Nudge,
          $$NudgesTableFilterComposer,
          $$NudgesTableOrderingComposer,
          $$NudgesTableAnnotationComposer,
          $$NudgesTableCreateCompanionBuilder,
          $$NudgesTableUpdateCompanionBuilder,
          (Nudge, $$NudgesTableReferences),
          Nudge,
          PrefetchHooks Function({bool taskId})
        > {
  $$NudgesTableTableManager(_$AppDatabase db, $NudgesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NudgesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NudgesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NudgesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<DateTime> fireAt = const Value.absent(),
                Value<NudgeLevel> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<bool> fired = const Value.absent(),
                Value<bool> opened = const Value.absent(),
              }) => NudgesCompanion(
                id: id,
                taskId: taskId,
                fireAt: fireAt,
                level: level,
                message: message,
                notificationId: notificationId,
                fired: fired,
                opened: opened,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required DateTime fireAt,
                required NudgeLevel level,
                required String message,
                required int notificationId,
                Value<bool> fired = const Value.absent(),
                Value<bool> opened = const Value.absent(),
              }) => NudgesCompanion.insert(
                id: id,
                taskId: taskId,
                fireAt: fireAt,
                level: level,
                message: message,
                notificationId: notificationId,
                fired: fired,
                opened: opened,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NudgesTable, Nudge>(table),
                  $$NudgesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$NudgesTableReferences._taskIdTable(
                          db,
                        ),
                        referencedColumn: $$NudgesTableReferences
                            ._taskIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NudgesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NudgesTable,
      Nudge,
      $$NudgesTableFilterComposer,
      $$NudgesTableOrderingComposer,
      $$NudgesTableAnnotationComposer,
      $$NudgesTableCreateCompanionBuilder,
      $$NudgesTableUpdateCompanionBuilder,
      (Nudge, $$NudgesTableReferences),
      Nudge,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$StepsTableTableManager get steps =>
      $$StepsTableTableManager(_db, _db.steps);
  $$OutcomesTableTableManager get outcomes =>
      $$OutcomesTableTableManager(_db, _db.outcomes);
  $$ExcusesTableTableManager get excuses =>
      $$ExcusesTableTableManager(_db, _db.excuses);
  $$NudgesTableTableManager get nudges =>
      $$NudgesTableTableManager(_db, _db.nudges);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
