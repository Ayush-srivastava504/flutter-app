// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aspectRatioMeta =
      const VerificationMeta('aspectRatio');
  @override
  late final GeneratedColumn<double> aspectRatio = GeneratedColumn<double>(
      'aspect_ratio', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(9 / 16));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, aspectRatio, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('aspect_ratio')) {
      context.handle(
          _aspectRatioMeta,
          aspectRatio.isAcceptableOrUnknown(
              data['aspect_ratio']!, _aspectRatioMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      aspectRatio: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}aspect_ratio'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final double aspectRatio;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project(
      {required this.id,
      required this.name,
      required this.aspectRatio,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['aspect_ratio'] = Variable<double>(aspectRatio);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      aspectRatio: Value(aspectRatio),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      aspectRatio: serializer.fromJson<double>(json['aspectRatio']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'aspectRatio': serializer.toJson<double>(aspectRatio),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith(
          {String? id,
          String? name,
          double? aspectRatio,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      aspectRatio:
          data.aspectRatio.present ? data.aspectRatio.value : this.aspectRatio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, aspectRatio, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.aspectRatio == this.aspectRatio &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> aspectRatio;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.aspectRatio = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? aspectRatio,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? aspectRatio,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (aspectRatio.present) {
      map['aspect_ratio'] = Variable<double>(aspectRatio.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClipsTable extends Clips with TableInfo<$ClipsTable, Clip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _sourceUriMeta =
      const VerificationMeta('sourceUri');
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
      'source_uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trimStartMsMeta =
      const VerificationMeta('trimStartMs');
  @override
  late final GeneratedColumn<int> trimStartMs = GeneratedColumn<int>(
      'trim_start_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _trimEndMsMeta =
      const VerificationMeta('trimEndMs');
  @override
  late final GeneratedColumn<int> trimEndMs = GeneratedColumn<int>(
      'trim_end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _transitionOutMeta =
      const VerificationMeta('transitionOut');
  @override
  late final GeneratedColumn<String> transitionOut = GeneratedColumn<String>(
      'transition_out', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cut'));
  static const VerificationMeta _brightnessMeta =
      const VerificationMeta('brightness');
  @override
  late final GeneratedColumn<double> brightness = GeneratedColumn<double>(
      'brightness', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _contrastMeta =
      const VerificationMeta('contrast');
  @override
  late final GeneratedColumn<double> contrast = GeneratedColumn<double>(
      'contrast', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _saturationMeta =
      const VerificationMeta('saturation');
  @override
  late final GeneratedColumn<double> saturation = GeneratedColumn<double>(
      'saturation', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
      'muted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("muted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        sourceUri,
        orderIndex,
        trimStartMs,
        trimEndMs,
        durationMs,
        transitionOut,
        brightness,
        contrast,
        saturation,
        muted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clips';
  @override
  VerificationContext validateIntegrity(Insertable<Clip> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(_sourceUriMeta,
          sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta));
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('trim_start_ms')) {
      context.handle(
          _trimStartMsMeta,
          trimStartMs.isAcceptableOrUnknown(
              data['trim_start_ms']!, _trimStartMsMeta));
    }
    if (data.containsKey('trim_end_ms')) {
      context.handle(
          _trimEndMsMeta,
          trimEndMs.isAcceptableOrUnknown(
              data['trim_end_ms']!, _trimEndMsMeta));
    } else if (isInserting) {
      context.missing(_trimEndMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('transition_out')) {
      context.handle(
          _transitionOutMeta,
          transitionOut.isAcceptableOrUnknown(
              data['transition_out']!, _transitionOutMeta));
    }
    if (data.containsKey('brightness')) {
      context.handle(
          _brightnessMeta,
          brightness.isAcceptableOrUnknown(
              data['brightness']!, _brightnessMeta));
    }
    if (data.containsKey('contrast')) {
      context.handle(_contrastMeta,
          contrast.isAcceptableOrUnknown(data['contrast']!, _contrastMeta));
    }
    if (data.containsKey('saturation')) {
      context.handle(
          _saturationMeta,
          saturation.isAcceptableOrUnknown(
              data['saturation']!, _saturationMeta));
    }
    if (data.containsKey('muted')) {
      context.handle(
          _mutedMeta, muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Clip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Clip(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      sourceUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_uri'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      trimStartMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_start_ms'])!,
      trimEndMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_end_ms'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      transitionOut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transition_out'])!,
      brightness: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}brightness'])!,
      contrast: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}contrast'])!,
      saturation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saturation'])!,
      muted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}muted'])!,
    );
  }

  @override
  $ClipsTable createAlias(String alias) {
    return $ClipsTable(attachedDatabase, alias);
  }
}

class Clip extends DataClass implements Insertable<Clip> {
  final String id;
  final String projectId;
  final String sourceUri;
  final int orderIndex;
  final int trimStartMs;
  final int trimEndMs;
  final int durationMs;
  final String transitionOut;
  final double brightness;
  final double contrast;
  final double saturation;
  final bool muted;
  const Clip(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.orderIndex,
      required this.trimStartMs,
      required this.trimEndMs,
      required this.durationMs,
      required this.transitionOut,
      required this.brightness,
      required this.contrast,
      required this.saturation,
      required this.muted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_uri'] = Variable<String>(sourceUri);
    map['order_index'] = Variable<int>(orderIndex);
    map['trim_start_ms'] = Variable<int>(trimStartMs);
    map['trim_end_ms'] = Variable<int>(trimEndMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['transition_out'] = Variable<String>(transitionOut);
    map['brightness'] = Variable<double>(brightness);
    map['contrast'] = Variable<double>(contrast);
    map['saturation'] = Variable<double>(saturation);
    map['muted'] = Variable<bool>(muted);
    return map;
  }

  ClipsCompanion toCompanion(bool nullToAbsent) {
    return ClipsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceUri: Value(sourceUri),
      orderIndex: Value(orderIndex),
      trimStartMs: Value(trimStartMs),
      trimEndMs: Value(trimEndMs),
      durationMs: Value(durationMs),
      transitionOut: Value(transitionOut),
      brightness: Value(brightness),
      contrast: Value(contrast),
      saturation: Value(saturation),
      muted: Value(muted),
    );
  }

  factory Clip.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Clip(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      trimStartMs: serializer.fromJson<int>(json['trimStartMs']),
      trimEndMs: serializer.fromJson<int>(json['trimEndMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      transitionOut: serializer.fromJson<String>(json['transitionOut']),
      brightness: serializer.fromJson<double>(json['brightness']),
      contrast: serializer.fromJson<double>(json['contrast']),
      saturation: serializer.fromJson<double>(json['saturation']),
      muted: serializer.fromJson<bool>(json['muted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'trimStartMs': serializer.toJson<int>(trimStartMs),
      'trimEndMs': serializer.toJson<int>(trimEndMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'transitionOut': serializer.toJson<String>(transitionOut),
      'brightness': serializer.toJson<double>(brightness),
      'contrast': serializer.toJson<double>(contrast),
      'saturation': serializer.toJson<double>(saturation),
      'muted': serializer.toJson<bool>(muted),
    };
  }

  Clip copyWith(
          {String? id,
          String? projectId,
          String? sourceUri,
          int? orderIndex,
          int? trimStartMs,
          int? trimEndMs,
          int? durationMs,
          String? transitionOut,
          double? brightness,
          double? contrast,
          double? saturation,
          bool? muted}) =>
      Clip(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        orderIndex: orderIndex ?? this.orderIndex,
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: trimEndMs ?? this.trimEndMs,
        durationMs: durationMs ?? this.durationMs,
        transitionOut: transitionOut ?? this.transitionOut,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        muted: muted ?? this.muted,
      );
  Clip copyWithCompanion(ClipsCompanion data) {
    return Clip(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      trimStartMs:
          data.trimStartMs.present ? data.trimStartMs.value : this.trimStartMs,
      trimEndMs: data.trimEndMs.present ? data.trimEndMs.value : this.trimEndMs,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      transitionOut: data.transitionOut.present
          ? data.transitionOut.value
          : this.transitionOut,
      brightness:
          data.brightness.present ? data.brightness.value : this.brightness,
      contrast: data.contrast.present ? data.contrast.value : this.contrast,
      saturation:
          data.saturation.present ? data.saturation.value : this.saturation,
      muted: data.muted.present ? data.muted.value : this.muted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Clip(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('transitionOut: $transitionOut, ')
          ..write('brightness: $brightness, ')
          ..write('contrast: $contrast, ')
          ..write('saturation: $saturation, ')
          ..write('muted: $muted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      sourceUri,
      orderIndex,
      trimStartMs,
      trimEndMs,
      durationMs,
      transitionOut,
      brightness,
      contrast,
      saturation,
      muted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Clip &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceUri == this.sourceUri &&
          other.orderIndex == this.orderIndex &&
          other.trimStartMs == this.trimStartMs &&
          other.trimEndMs == this.trimEndMs &&
          other.durationMs == this.durationMs &&
          other.transitionOut == this.transitionOut &&
          other.brightness == this.brightness &&
          other.contrast == this.contrast &&
          other.saturation == this.saturation &&
          other.muted == this.muted);
}

class ClipsCompanion extends UpdateCompanion<Clip> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceUri;
  final Value<int> orderIndex;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int> durationMs;
  final Value<String> transitionOut;
  final Value<double> brightness;
  final Value<double> contrast;
  final Value<double> saturation;
  final Value<bool> muted;
  final Value<int> rowid;
  const ClipsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.transitionOut = const Value.absent(),
    this.brightness = const Value.absent(),
    this.contrast = const Value.absent(),
    this.saturation = const Value.absent(),
    this.muted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClipsCompanion.insert({
    required String id,
    required String projectId,
    required String sourceUri,
    required int orderIndex,
    this.trimStartMs = const Value.absent(),
    required int trimEndMs,
    required int durationMs,
    this.transitionOut = const Value.absent(),
    this.brightness = const Value.absent(),
    this.contrast = const Value.absent(),
    this.saturation = const Value.absent(),
    this.muted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        sourceUri = Value(sourceUri),
        orderIndex = Value(orderIndex),
        trimEndMs = Value(trimEndMs),
        durationMs = Value(durationMs);
  static Insertable<Clip> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceUri,
    Expression<int>? orderIndex,
    Expression<int>? trimStartMs,
    Expression<int>? trimEndMs,
    Expression<int>? durationMs,
    Expression<String>? transitionOut,
    Expression<double>? brightness,
    Expression<double>? contrast,
    Expression<double>? saturation,
    Expression<bool>? muted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (orderIndex != null) 'order_index': orderIndex,
      if (trimStartMs != null) 'trim_start_ms': trimStartMs,
      if (trimEndMs != null) 'trim_end_ms': trimEndMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (transitionOut != null) 'transition_out': transitionOut,
      if (brightness != null) 'brightness': brightness,
      if (contrast != null) 'contrast': contrast,
      if (saturation != null) 'saturation': saturation,
      if (muted != null) 'muted': muted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClipsCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? sourceUri,
      Value<int>? orderIndex,
      Value<int>? trimStartMs,
      Value<int>? trimEndMs,
      Value<int>? durationMs,
      Value<String>? transitionOut,
      Value<double>? brightness,
      Value<double>? contrast,
      Value<double>? saturation,
      Value<bool>? muted,
      Value<int>? rowid}) {
    return ClipsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceUri: sourceUri ?? this.sourceUri,
      orderIndex: orderIndex ?? this.orderIndex,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      durationMs: durationMs ?? this.durationMs,
      transitionOut: transitionOut ?? this.transitionOut,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      muted: muted ?? this.muted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (trimStartMs.present) {
      map['trim_start_ms'] = Variable<int>(trimStartMs.value);
    }
    if (trimEndMs.present) {
      map['trim_end_ms'] = Variable<int>(trimEndMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (transitionOut.present) {
      map['transition_out'] = Variable<String>(transitionOut.value);
    }
    if (brightness.present) {
      map['brightness'] = Variable<double>(brightness.value);
    }
    if (contrast.present) {
      map['contrast'] = Variable<double>(contrast.value);
    }
    if (saturation.present) {
      map['saturation'] = Variable<double>(saturation.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('transitionOut: $transitionOut, ')
          ..write('brightness: $brightness, ')
          ..write('contrast: $contrast, ')
          ..write('saturation: $saturation, ')
          ..write('muted: $muted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioTracksTable extends AudioTracks
    with TableInfo<$AudioTracksTable, AudioTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _sourceUriMeta =
      const VerificationMeta('sourceUri');
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
      'source_uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trimStartMsMeta =
      const VerificationMeta('trimStartMs');
  @override
  late final GeneratedColumn<int> trimStartMs = GeneratedColumn<int>(
      'trim_start_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _trimEndMsMeta =
      const VerificationMeta('trimEndMs');
  @override
  late final GeneratedColumn<int> trimEndMs = GeneratedColumn<int>(
      'trim_end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _offsetMsMeta =
      const VerificationMeta('offsetMs');
  @override
  late final GeneratedColumn<int> offsetMs = GeneratedColumn<int>(
      'offset_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
      'volume', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, sourceUri, trimStartMs, trimEndMs, offsetMs, volume];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_tracks';
  @override
  VerificationContext validateIntegrity(Insertable<AudioTrack> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('source_uri')) {
      context.handle(_sourceUriMeta,
          sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta));
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('trim_start_ms')) {
      context.handle(
          _trimStartMsMeta,
          trimStartMs.isAcceptableOrUnknown(
              data['trim_start_ms']!, _trimStartMsMeta));
    }
    if (data.containsKey('trim_end_ms')) {
      context.handle(
          _trimEndMsMeta,
          trimEndMs.isAcceptableOrUnknown(
              data['trim_end_ms']!, _trimEndMsMeta));
    } else if (isInserting) {
      context.missing(_trimEndMsMeta);
    }
    if (data.containsKey('offset_ms')) {
      context.handle(_offsetMsMeta,
          offsetMs.isAcceptableOrUnknown(data['offset_ms']!, _offsetMsMeta));
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta,
          volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AudioTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioTrack(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      sourceUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_uri'])!,
      trimStartMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_start_ms'])!,
      trimEndMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_end_ms'])!,
      offsetMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}offset_ms'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
    );
  }

  @override
  $AudioTracksTable createAlias(String alias) {
    return $AudioTracksTable(attachedDatabase, alias);
  }
}

class AudioTrack extends DataClass implements Insertable<AudioTrack> {
  final String id;
  final String projectId;
  final String sourceUri;
  final int trimStartMs;
  final int trimEndMs;
  final int offsetMs;
  final double volume;
  const AudioTrack(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.trimStartMs,
      required this.trimEndMs,
      required this.offsetMs,
      required this.volume});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_uri'] = Variable<String>(sourceUri);
    map['trim_start_ms'] = Variable<int>(trimStartMs);
    map['trim_end_ms'] = Variable<int>(trimEndMs);
    map['offset_ms'] = Variable<int>(offsetMs);
    map['volume'] = Variable<double>(volume);
    return map;
  }

  AudioTracksCompanion toCompanion(bool nullToAbsent) {
    return AudioTracksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceUri: Value(sourceUri),
      trimStartMs: Value(trimStartMs),
      trimEndMs: Value(trimEndMs),
      offsetMs: Value(offsetMs),
      volume: Value(volume),
    );
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioTrack(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      trimStartMs: serializer.fromJson<int>(json['trimStartMs']),
      trimEndMs: serializer.fromJson<int>(json['trimEndMs']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      volume: serializer.fromJson<double>(json['volume']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'trimStartMs': serializer.toJson<int>(trimStartMs),
      'trimEndMs': serializer.toJson<int>(trimEndMs),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'volume': serializer.toJson<double>(volume),
    };
  }

  AudioTrack copyWith(
          {String? id,
          String? projectId,
          String? sourceUri,
          int? trimStartMs,
          int? trimEndMs,
          int? offsetMs,
          double? volume}) =>
      AudioTrack(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: trimEndMs ?? this.trimEndMs,
        offsetMs: offsetMs ?? this.offsetMs,
        volume: volume ?? this.volume,
      );
  AudioTrack copyWithCompanion(AudioTracksCompanion data) {
    return AudioTrack(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      trimStartMs:
          data.trimStartMs.present ? data.trimStartMs.value : this.trimStartMs,
      trimEndMs: data.trimEndMs.present ? data.trimEndMs.value : this.trimEndMs,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      volume: data.volume.present ? data.volume.value : this.volume,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioTrack(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('volume: $volume')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, projectId, sourceUri, trimStartMs, trimEndMs, offsetMs, volume);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioTrack &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceUri == this.sourceUri &&
          other.trimStartMs == this.trimStartMs &&
          other.trimEndMs == this.trimEndMs &&
          other.offsetMs == this.offsetMs &&
          other.volume == this.volume);
}

class AudioTracksCompanion extends UpdateCompanion<AudioTrack> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceUri;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int> offsetMs;
  final Value<double> volume;
  final Value<int> rowid;
  const AudioTracksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.volume = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioTracksCompanion.insert({
    required String id,
    required String projectId,
    required String sourceUri,
    this.trimStartMs = const Value.absent(),
    required int trimEndMs,
    this.offsetMs = const Value.absent(),
    this.volume = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        sourceUri = Value(sourceUri),
        trimEndMs = Value(trimEndMs);
  static Insertable<AudioTrack> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceUri,
    Expression<int>? trimStartMs,
    Expression<int>? trimEndMs,
    Expression<int>? offsetMs,
    Expression<double>? volume,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (trimStartMs != null) 'trim_start_ms': trimStartMs,
      if (trimEndMs != null) 'trim_end_ms': trimEndMs,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (volume != null) 'volume': volume,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioTracksCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? sourceUri,
      Value<int>? trimStartMs,
      Value<int>? trimEndMs,
      Value<int>? offsetMs,
      Value<double>? volume,
      Value<int>? rowid}) {
    return AudioTracksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceUri: sourceUri ?? this.sourceUri,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      offsetMs: offsetMs ?? this.offsetMs,
      volume: volume ?? this.volume,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (trimStartMs.present) {
      map['trim_start_ms'] = Variable<int>(trimStartMs.value);
    }
    if (trimEndMs.present) {
      map['trim_end_ms'] = Variable<int>(trimEndMs.value);
    }
    if (offsetMs.present) {
      map['offset_ms'] = Variable<int>(offsetMs.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioTracksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('volume: $volume, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TextOverlaysTable extends TextOverlays
    with TableInfo<$TextOverlaysTable, TextOverlay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TextOverlaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
      'project_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fontFamilyMeta =
      const VerificationMeta('fontFamily');
  @override
  late final GeneratedColumn<String> fontFamily = GeneratedColumn<String>(
      'font_family', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Default'));
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFFFFFFFF));
  static const VerificationMeta _fontSizeMeta =
      const VerificationMeta('fontSize');
  @override
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
      'font_size', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(24));
  static const VerificationMeta _positionXMeta =
      const VerificationMeta('positionX');
  @override
  late final GeneratedColumn<double> positionX = GeneratedColumn<double>(
      'position_x', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.5));
  static const VerificationMeta _positionYMeta =
      const VerificationMeta('positionY');
  @override
  late final GeneratedColumn<double> positionY = GeneratedColumn<double>(
      'position_y', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.5));
  static const VerificationMeta _startMsMeta =
      const VerificationMeta('startMs');
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
      'start_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
      'end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        content,
        fontFamily,
        colorValue,
        fontSize,
        positionX,
        positionY,
        startMs,
        endMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'text_overlays';
  @override
  VerificationContext validateIntegrity(Insertable<TextOverlay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('font_family')) {
      context.handle(
          _fontFamilyMeta,
          fontFamily.isAcceptableOrUnknown(
              data['font_family']!, _fontFamilyMeta));
    }
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    }
    if (data.containsKey('font_size')) {
      context.handle(_fontSizeMeta,
          fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta));
    }
    if (data.containsKey('position_x')) {
      context.handle(_positionXMeta,
          positionX.isAcceptableOrUnknown(data['position_x']!, _positionXMeta));
    }
    if (data.containsKey('position_y')) {
      context.handle(_positionYMeta,
          positionY.isAcceptableOrUnknown(data['position_y']!, _positionYMeta));
    }
    if (data.containsKey('start_ms')) {
      context.handle(_startMsMeta,
          startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta));
    }
    if (data.containsKey('end_ms')) {
      context.handle(
          _endMsMeta, endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta));
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TextOverlay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TextOverlay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      fontFamily: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}font_family'])!,
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value'])!,
      fontSize: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}font_size'])!,
      positionX: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}position_x'])!,
      positionY: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}position_y'])!,
      startMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ms'])!,
      endMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_ms'])!,
    );
  }

  @override
  $TextOverlaysTable createAlias(String alias) {
    return $TextOverlaysTable(attachedDatabase, alias);
  }
}

class TextOverlay extends DataClass implements Insertable<TextOverlay> {
  final String id;
  final String projectId;
  final String content;
  final String fontFamily;
  final int colorValue;
  final double fontSize;
  final double positionX;
  final double positionY;
  final int startMs;
  final int endMs;
  const TextOverlay(
      {required this.id,
      required this.projectId,
      required this.content,
      required this.fontFamily,
      required this.colorValue,
      required this.fontSize,
      required this.positionX,
      required this.positionY,
      required this.startMs,
      required this.endMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['content'] = Variable<String>(content);
    map['font_family'] = Variable<String>(fontFamily);
    map['color_value'] = Variable<int>(colorValue);
    map['font_size'] = Variable<double>(fontSize);
    map['position_x'] = Variable<double>(positionX);
    map['position_y'] = Variable<double>(positionY);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    return map;
  }

  TextOverlaysCompanion toCompanion(bool nullToAbsent) {
    return TextOverlaysCompanion(
      id: Value(id),
      projectId: Value(projectId),
      content: Value(content),
      fontFamily: Value(fontFamily),
      colorValue: Value(colorValue),
      fontSize: Value(fontSize),
      positionX: Value(positionX),
      positionY: Value(positionY),
      startMs: Value(startMs),
      endMs: Value(endMs),
    );
  }

  factory TextOverlay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TextOverlay(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      content: serializer.fromJson<String>(json['content']),
      fontFamily: serializer.fromJson<String>(json['fontFamily']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      fontSize: serializer.fromJson<double>(json['fontSize']),
      positionX: serializer.fromJson<double>(json['positionX']),
      positionY: serializer.fromJson<double>(json['positionY']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'content': serializer.toJson<String>(content),
      'fontFamily': serializer.toJson<String>(fontFamily),
      'colorValue': serializer.toJson<int>(colorValue),
      'fontSize': serializer.toJson<double>(fontSize),
      'positionX': serializer.toJson<double>(positionX),
      'positionY': serializer.toJson<double>(positionY),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
    };
  }

  TextOverlay copyWith(
          {String? id,
          String? projectId,
          String? content,
          String? fontFamily,
          int? colorValue,
          double? fontSize,
          double? positionX,
          double? positionY,
          int? startMs,
          int? endMs}) =>
      TextOverlay(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        content: content ?? this.content,
        fontFamily: fontFamily ?? this.fontFamily,
        colorValue: colorValue ?? this.colorValue,
        fontSize: fontSize ?? this.fontSize,
        positionX: positionX ?? this.positionX,
        positionY: positionY ?? this.positionY,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
      );
  TextOverlay copyWithCompanion(TextOverlaysCompanion data) {
    return TextOverlay(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      content: data.content.present ? data.content.value : this.content,
      fontFamily:
          data.fontFamily.present ? data.fontFamily.value : this.fontFamily,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      positionX: data.positionX.present ? data.positionX.value : this.positionX,
      positionY: data.positionY.present ? data.positionY.value : this.positionY,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TextOverlay(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('content: $content, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('colorValue: $colorValue, ')
          ..write('fontSize: $fontSize, ')
          ..write('positionX: $positionX, ')
          ..write('positionY: $positionY, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, content, fontFamily,
      colorValue, fontSize, positionX, positionY, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TextOverlay &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.content == this.content &&
          other.fontFamily == this.fontFamily &&
          other.colorValue == this.colorValue &&
          other.fontSize == this.fontSize &&
          other.positionX == this.positionX &&
          other.positionY == this.positionY &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class TextOverlaysCompanion extends UpdateCompanion<TextOverlay> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> content;
  final Value<String> fontFamily;
  final Value<int> colorValue;
  final Value<double> fontSize;
  final Value<double> positionX;
  final Value<double> positionY;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<int> rowid;
  const TextOverlaysCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.content = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.positionX = const Value.absent(),
    this.positionY = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TextOverlaysCompanion.insert({
    required String id,
    required String projectId,
    required String content,
    this.fontFamily = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.positionX = const Value.absent(),
    this.positionY = const Value.absent(),
    this.startMs = const Value.absent(),
    required int endMs,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        content = Value(content),
        endMs = Value(endMs);
  static Insertable<TextOverlay> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? content,
    Expression<String>? fontFamily,
    Expression<int>? colorValue,
    Expression<double>? fontSize,
    Expression<double>? positionX,
    Expression<double>? positionY,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (content != null) 'content': content,
      if (fontFamily != null) 'font_family': fontFamily,
      if (colorValue != null) 'color_value': colorValue,
      if (fontSize != null) 'font_size': fontSize,
      if (positionX != null) 'position_x': positionX,
      if (positionY != null) 'position_y': positionY,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TextOverlaysCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? content,
      Value<String>? fontFamily,
      Value<int>? colorValue,
      Value<double>? fontSize,
      Value<double>? positionX,
      Value<double>? positionY,
      Value<int>? startMs,
      Value<int>? endMs,
      Value<int>? rowid}) {
    return TextOverlaysCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      fontFamily: fontFamily ?? this.fontFamily,
      colorValue: colorValue ?? this.colorValue,
      fontSize: fontSize ?? this.fontSize,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (fontFamily.present) {
      map['font_family'] = Variable<String>(fontFamily.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (positionX.present) {
      map['position_x'] = Variable<double>(positionX.value);
    }
    if (positionY.present) {
      map['position_y'] = Variable<double>(positionY.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TextOverlaysCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('content: $content, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('colorValue: $colorValue, ')
          ..write('fontSize: $fontSize, ')
          ..write('positionX: $positionX, ')
          ..write('positionY: $positionY, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProjectDatabase extends GeneratedDatabase {
  _$ProjectDatabase(QueryExecutor e) : super(e);
  $ProjectDatabaseManager get managers => $ProjectDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ClipsTable clips = $ClipsTable(this);
  late final $AudioTracksTable audioTracks = $AudioTracksTable(this);
  late final $TextOverlaysTable textOverlays = $TextOverlaysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [projects, clips, audioTracks, textOverlays];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<double> aspectRatio,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> aspectRatio,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$ProjectDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClipsTable, List<Clip>> _clipsRefsTable(
          _$ProjectDatabase db) =>
      MultiTypedResultKey.fromTable(db.clips,
          aliasName: 'projects__id__clips__project_id');

  $$ClipsTableProcessedTableManager get clipsRefs {
    final manager = $$ClipsTableTableManager($_db, $_db.clips)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_clipsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AudioTracksTable, List<AudioTrack>>
      _audioTracksRefsTable(_$ProjectDatabase db) =>
          MultiTypedResultKey.fromTable(db.audioTracks,
              aliasName: 'projects__id__audio_tracks__project_id');

  $$AudioTracksTableProcessedTableManager get audioTracksRefs {
    final manager = $$AudioTracksTableTableManager($_db, $_db.audioTracks)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_audioTracksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TextOverlaysTable, List<TextOverlay>>
      _textOverlaysRefsTable(_$ProjectDatabase db) =>
          MultiTypedResultKey.fromTable(db.textOverlays,
              aliasName: 'projects__id__text_overlays__project_id');

  $$TextOverlaysTableProcessedTableManager get textOverlaysRefs {
    final manager = $$TextOverlaysTableTableManager($_db, $_db.textOverlays)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_textOverlaysRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$ProjectDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get aspectRatio => $composableBuilder(
      column: $table.aspectRatio, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> clipsRefs(
      Expression<bool> Function($$ClipsTableFilterComposer f) f) {
    final $$ClipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clips,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClipsTableFilterComposer(
              $db: $db,
              $table: $db.clips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> audioTracksRefs(
      Expression<bool> Function($$AudioTracksTableFilterComposer f) f) {
    final $$AudioTracksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.audioTracks,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AudioTracksTableFilterComposer(
              $db: $db,
              $table: $db.audioTracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> textOverlaysRefs(
      Expression<bool> Function($$TextOverlaysTableFilterComposer f) f) {
    final $$TextOverlaysTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.textOverlays,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TextOverlaysTableFilterComposer(
              $db: $db,
              $table: $db.textOverlays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get aspectRatio => $composableBuilder(
      column: $table.aspectRatio, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get aspectRatio => $composableBuilder(
      column: $table.aspectRatio, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> clipsRefs<T extends Object>(
      Expression<T> Function($$ClipsTableAnnotationComposer a) f) {
    final $$ClipsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.clips,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClipsTableAnnotationComposer(
              $db: $db,
              $table: $db.clips,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> audioTracksRefs<T extends Object>(
      Expression<T> Function($$AudioTracksTableAnnotationComposer a) f) {
    final $$AudioTracksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.audioTracks,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AudioTracksTableAnnotationComposer(
              $db: $db,
              $table: $db.audioTracks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> textOverlaysRefs<T extends Object>(
      Expression<T> Function($$TextOverlaysTableAnnotationComposer a) f) {
    final $$TextOverlaysTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.textOverlays,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TextOverlaysTableAnnotationComposer(
              $db: $db,
              $table: $db.textOverlays,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function(
        {bool clipsRefs, bool audioTracksRefs, bool textOverlaysRefs})> {
  $$ProjectsTableTableManager(_$ProjectDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> aspectRatio = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
            aspectRatio: aspectRatio,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<double> aspectRatio = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
            aspectRatio: aspectRatio,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {clipsRefs = false,
              audioTracksRefs = false,
              textOverlaysRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (clipsRefs) db.clips,
                if (audioTracksRefs) db.audioTracks,
                if (textOverlaysRefs) db.textOverlays
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (clipsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable, Clip>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._clipsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0).clipsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (audioTracksRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            AudioTrack>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._audioTracksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .audioTracksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (textOverlaysRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            TextOverlay>(
                        currentTable: table,
                        referencedTable: $$ProjectsTableReferences
                            ._textOverlaysRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .textOverlaysRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function(
        {bool clipsRefs, bool audioTracksRefs, bool textOverlaysRefs})>;
typedef $$ClipsTableCreateCompanionBuilder = ClipsCompanion Function({
  required String id,
  required String projectId,
  required String sourceUri,
  required int orderIndex,
  Value<int> trimStartMs,
  required int trimEndMs,
  required int durationMs,
  Value<String> transitionOut,
  Value<double> brightness,
  Value<double> contrast,
  Value<double> saturation,
  Value<bool> muted,
  Value<int> rowid,
});
typedef $$ClipsTableUpdateCompanionBuilder = ClipsCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> sourceUri,
  Value<int> orderIndex,
  Value<int> trimStartMs,
  Value<int> trimEndMs,
  Value<int> durationMs,
  Value<String> transitionOut,
  Value<double> brightness,
  Value<double> contrast,
  Value<double> saturation,
  Value<bool> muted,
  Value<int> rowid,
});

final class $$ClipsTableReferences
    extends BaseReferences<_$ProjectDatabase, $ClipsTable, Clip> {
  $$ClipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$ProjectDatabase db) =>
      db.projects.createAlias('clips__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ClipsTableFilterComposer
    extends Composer<_$ProjectDatabase, $ClipsTable> {
  $$ClipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get contrast => $composableBuilder(
      column: $table.contrast, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $ClipsTable> {
  $$ClipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get contrast => $composableBuilder(
      column: $table.contrast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $ClipsTable> {
  $$ClipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => column);

  GeneratedColumn<int> get trimEndMs =>
      $composableBuilder(column: $table.trimEndMs, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut, builder: (column) => column);

  GeneratedColumn<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => column);

  GeneratedColumn<double> get contrast =>
      $composableBuilder(column: $table.contrast, builder: (column) => column);

  GeneratedColumn<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => column);

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ClipsTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $ClipsTable,
    Clip,
    $$ClipsTableFilterComposer,
    $$ClipsTableOrderingComposer,
    $$ClipsTableAnnotationComposer,
    $$ClipsTableCreateCompanionBuilder,
    $$ClipsTableUpdateCompanionBuilder,
    (Clip, $$ClipsTableReferences),
    Clip,
    PrefetchHooks Function({bool projectId})> {
  $$ClipsTableTableManager(_$ProjectDatabase db, $ClipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> sourceUri = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int> trimStartMs = const Value.absent(),
            Value<int> trimEndMs = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> transitionOut = const Value.absent(),
            Value<double> brightness = const Value.absent(),
            Value<double> contrast = const Value.absent(),
            Value<double> saturation = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClipsCompanion(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            orderIndex: orderIndex,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            durationMs: durationMs,
            transitionOut: transitionOut,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            muted: muted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String sourceUri,
            required int orderIndex,
            Value<int> trimStartMs = const Value.absent(),
            required int trimEndMs,
            required int durationMs,
            Value<String> transitionOut = const Value.absent(),
            Value<double> brightness = const Value.absent(),
            Value<double> contrast = const Value.absent(),
            Value<double> saturation = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ClipsCompanion.insert(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            orderIndex: orderIndex,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            durationMs: durationMs,
            transitionOut: transitionOut,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            muted: muted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ClipsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable: $$ClipsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$ClipsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ClipsTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $ClipsTable,
    Clip,
    $$ClipsTableFilterComposer,
    $$ClipsTableOrderingComposer,
    $$ClipsTableAnnotationComposer,
    $$ClipsTableCreateCompanionBuilder,
    $$ClipsTableUpdateCompanionBuilder,
    (Clip, $$ClipsTableReferences),
    Clip,
    PrefetchHooks Function({bool projectId})>;
typedef $$AudioTracksTableCreateCompanionBuilder = AudioTracksCompanion
    Function({
  required String id,
  required String projectId,
  required String sourceUri,
  Value<int> trimStartMs,
  required int trimEndMs,
  Value<int> offsetMs,
  Value<double> volume,
  Value<int> rowid,
});
typedef $$AudioTracksTableUpdateCompanionBuilder = AudioTracksCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> sourceUri,
  Value<int> trimStartMs,
  Value<int> trimEndMs,
  Value<int> offsetMs,
  Value<double> volume,
  Value<int> rowid,
});

final class $$AudioTracksTableReferences
    extends BaseReferences<_$ProjectDatabase, $AudioTracksTable, AudioTrack> {
  $$AudioTracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$ProjectDatabase db) =>
      db.projects.createAlias('audio_tracks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AudioTracksTableFilterComposer
    extends Composer<_$ProjectDatabase, $AudioTracksTable> {
  $$AudioTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get offsetMs => $composableBuilder(
      column: $table.offsetMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AudioTracksTableOrderingComposer
    extends Composer<_$ProjectDatabase, $AudioTracksTable> {
  $$AudioTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get offsetMs => $composableBuilder(
      column: $table.offsetMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AudioTracksTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $AudioTracksTable> {
  $$AudioTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => column);

  GeneratedColumn<int> get trimEndMs =>
      $composableBuilder(column: $table.trimEndMs, builder: (column) => column);

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AudioTracksTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $AudioTracksTable,
    AudioTrack,
    $$AudioTracksTableFilterComposer,
    $$AudioTracksTableOrderingComposer,
    $$AudioTracksTableAnnotationComposer,
    $$AudioTracksTableCreateCompanionBuilder,
    $$AudioTracksTableUpdateCompanionBuilder,
    (AudioTrack, $$AudioTracksTableReferences),
    AudioTrack,
    PrefetchHooks Function({bool projectId})> {
  $$AudioTracksTableTableManager(_$ProjectDatabase db, $AudioTracksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> sourceUri = const Value.absent(),
            Value<int> trimStartMs = const Value.absent(),
            Value<int> trimEndMs = const Value.absent(),
            Value<int> offsetMs = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioTracksCompanion(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            offsetMs: offsetMs,
            volume: volume,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String sourceUri,
            Value<int> trimStartMs = const Value.absent(),
            required int trimEndMs,
            Value<int> offsetMs = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioTracksCompanion.insert(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            offsetMs: offsetMs,
            volume: volume,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AudioTracksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$AudioTracksTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$AudioTracksTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AudioTracksTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $AudioTracksTable,
    AudioTrack,
    $$AudioTracksTableFilterComposer,
    $$AudioTracksTableOrderingComposer,
    $$AudioTracksTableAnnotationComposer,
    $$AudioTracksTableCreateCompanionBuilder,
    $$AudioTracksTableUpdateCompanionBuilder,
    (AudioTrack, $$AudioTracksTableReferences),
    AudioTrack,
    PrefetchHooks Function({bool projectId})>;
typedef $$TextOverlaysTableCreateCompanionBuilder = TextOverlaysCompanion
    Function({
  required String id,
  required String projectId,
  required String content,
  Value<String> fontFamily,
  Value<int> colorValue,
  Value<double> fontSize,
  Value<double> positionX,
  Value<double> positionY,
  Value<int> startMs,
  required int endMs,
  Value<int> rowid,
});
typedef $$TextOverlaysTableUpdateCompanionBuilder = TextOverlaysCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> content,
  Value<String> fontFamily,
  Value<int> colorValue,
  Value<double> fontSize,
  Value<double> positionX,
  Value<double> positionY,
  Value<int> startMs,
  Value<int> endMs,
  Value<int> rowid,
});

final class $$TextOverlaysTableReferences
    extends BaseReferences<_$ProjectDatabase, $TextOverlaysTable, TextOverlay> {
  $$TextOverlaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$ProjectDatabase db) =>
      db.projects.createAlias('text_overlays__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TextOverlaysTableFilterComposer
    extends Composer<_$ProjectDatabase, $TextOverlaysTable> {
  $$TextOverlaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fontSize => $composableBuilder(
      column: $table.fontSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get positionX => $composableBuilder(
      column: $table.positionX, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get positionY => $composableBuilder(
      column: $table.positionY, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TextOverlaysTableOrderingComposer
    extends Composer<_$ProjectDatabase, $TextOverlaysTable> {
  $$TextOverlaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fontSize => $composableBuilder(
      column: $table.fontSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get positionX => $composableBuilder(
      column: $table.positionX, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get positionY => $composableBuilder(
      column: $table.positionY, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TextOverlaysTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $TextOverlaysTable> {
  $$TextOverlaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get fontFamily => $composableBuilder(
      column: $table.fontFamily, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<double> get fontSize =>
      $composableBuilder(column: $table.fontSize, builder: (column) => column);

  GeneratedColumn<double> get positionX =>
      $composableBuilder(column: $table.positionX, builder: (column) => column);

  GeneratedColumn<double> get positionY =>
      $composableBuilder(column: $table.positionY, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TextOverlaysTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $TextOverlaysTable,
    TextOverlay,
    $$TextOverlaysTableFilterComposer,
    $$TextOverlaysTableOrderingComposer,
    $$TextOverlaysTableAnnotationComposer,
    $$TextOverlaysTableCreateCompanionBuilder,
    $$TextOverlaysTableUpdateCompanionBuilder,
    (TextOverlay, $$TextOverlaysTableReferences),
    TextOverlay,
    PrefetchHooks Function({bool projectId})> {
  $$TextOverlaysTableTableManager(
      _$ProjectDatabase db, $TextOverlaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TextOverlaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TextOverlaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TextOverlaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> fontFamily = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> positionX = const Value.absent(),
            Value<double> positionY = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            Value<int> endMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TextOverlaysCompanion(
            id: id,
            projectId: projectId,
            content: content,
            fontFamily: fontFamily,
            colorValue: colorValue,
            fontSize: fontSize,
            positionX: positionX,
            positionY: positionY,
            startMs: startMs,
            endMs: endMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String content,
            Value<String> fontFamily = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<double> fontSize = const Value.absent(),
            Value<double> positionX = const Value.absent(),
            Value<double> positionY = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            required int endMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              TextOverlaysCompanion.insert(
            id: id,
            projectId: projectId,
            content: content,
            fontFamily: fontFamily,
            colorValue: colorValue,
            fontSize: fontSize,
            positionX: positionX,
            positionY: positionY,
            startMs: startMs,
            endMs: endMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TextOverlaysTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$TextOverlaysTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$TextOverlaysTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TextOverlaysTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $TextOverlaysTable,
    TextOverlay,
    $$TextOverlaysTableFilterComposer,
    $$TextOverlaysTableOrderingComposer,
    $$TextOverlaysTableAnnotationComposer,
    $$TextOverlaysTableCreateCompanionBuilder,
    $$TextOverlaysTableUpdateCompanionBuilder,
    (TextOverlay, $$TextOverlaysTableReferences),
    TextOverlay,
    PrefetchHooks Function({bool projectId})>;

class $ProjectDatabaseManager {
  final _$ProjectDatabase _db;
  $ProjectDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ClipsTableTableManager get clips =>
      $$ClipsTableTableManager(_db, _db.clips);
  $$AudioTracksTableTableManager get audioTracks =>
      $$AudioTracksTableTableManager(_db, _db.audioTracks);
  $$TextOverlaysTableTableManager get textOverlays =>
      $$TextOverlaysTableTableManager(_db, _db.textOverlays);
}
