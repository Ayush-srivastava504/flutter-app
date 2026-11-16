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
  static const VerificationMeta _duckMusicMeta =
      const VerificationMeta('duckMusic');
  @override
  late final GeneratedColumn<bool> duckMusic = GeneratedColumn<bool>(
      'duck_music', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("duck_music" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('normal'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, aspectRatio, createdAt, updatedAt, duckMusic, mode];
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
    if (data.containsKey('duck_music')) {
      context.handle(_duckMusicMeta,
          duckMusic.isAcceptableOrUnknown(data['duck_music']!, _duckMusicMeta));
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
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
      duckMusic: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}duck_music'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
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

  /// F19: when true, export lowers the music while clip audio is audible
  /// (FFmpeg `sidechaincompress`). Export-only — the preview does not duck.
  final bool duckMusic;

  /// v10: which editor mode the project was started in (`EditMode.name`:
  /// youtube | insta | normal). Rows from before v10 read as 'normal'.
  final String mode;
  const Project(
      {required this.id,
      required this.name,
      required this.aspectRatio,
      required this.createdAt,
      required this.updatedAt,
      required this.duckMusic,
      required this.mode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['aspect_ratio'] = Variable<double>(aspectRatio);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['duck_music'] = Variable<bool>(duckMusic);
    map['mode'] = Variable<String>(mode);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      aspectRatio: Value(aspectRatio),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      duckMusic: Value(duckMusic),
      mode: Value(mode),
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
      duckMusic: serializer.fromJson<bool>(json['duckMusic']),
      mode: serializer.fromJson<String>(json['mode']),
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
      'duckMusic': serializer.toJson<bool>(duckMusic),
      'mode': serializer.toJson<String>(mode),
    };
  }

  Project copyWith(
          {String? id,
          String? name,
          double? aspectRatio,
          DateTime? createdAt,
          DateTime? updatedAt,
          bool? duckMusic,
          String? mode}) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        duckMusic: duckMusic ?? this.duckMusic,
        mode: mode ?? this.mode,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      aspectRatio:
          data.aspectRatio.present ? data.aspectRatio.value : this.aspectRatio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      duckMusic: data.duckMusic.present ? data.duckMusic.value : this.duckMusic,
      mode: data.mode.present ? data.mode.value : this.mode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('aspectRatio: $aspectRatio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('duckMusic: $duckMusic, ')
          ..write('mode: $mode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, aspectRatio, createdAt, updatedAt, duckMusic, mode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.aspectRatio == this.aspectRatio &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.duckMusic == this.duckMusic &&
          other.mode == this.mode);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> aspectRatio;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> duckMusic;
  final Value<String> mode;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.aspectRatio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.duckMusic = const Value.absent(),
    this.mode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.aspectRatio = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.duckMusic = const Value.absent(),
    this.mode = const Value.absent(),
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
    Expression<bool>? duckMusic,
    Expression<String>? mode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (aspectRatio != null) 'aspect_ratio': aspectRatio,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (duckMusic != null) 'duck_music': duckMusic,
      if (mode != null) 'mode': mode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<double>? aspectRatio,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<bool>? duckMusic,
      Value<String>? mode,
      Value<int>? rowid}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      duckMusic: duckMusic ?? this.duckMusic,
      mode: mode ?? this.mode,
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
    if (duckMusic.present) {
      map['duck_music'] = Variable<bool>(duckMusic.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
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
          ..write('duckMusic: $duckMusic, ')
          ..write('mode: $mode, ')
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
  static const VerificationMeta _rotationDegreesMeta =
      const VerificationMeta('rotationDegrees');
  @override
  late final GeneratedColumn<int> rotationDegrees = GeneratedColumn<int>(
      'rotation_degrees', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _thumbnailUriMeta =
      const VerificationMeta('thumbnailUri');
  @override
  late final GeneratedColumn<String> thumbnailUri = GeneratedColumn<String>(
      'thumbnail_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _filterPresetMeta =
      const VerificationMeta('filterPreset');
  @override
  late final GeneratedColumn<String> filterPreset = GeneratedColumn<String>(
      'filter_preset', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mutedMeta = const VerificationMeta('muted');
  @override
  late final GeneratedColumn<bool> muted = GeneratedColumn<bool>(
      'muted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("muted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
      'volume', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _lookMeta = const VerificationMeta('look');
  @override
  late final GeneratedColumn<String> look = GeneratedColumn<String>(
      'look', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _turnsMeta = const VerificationMeta('turns');
  @override
  late final GeneratedColumn<int> turns = GeneratedColumn<int>(
      'turns', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _flipHMeta = const VerificationMeta('flipH');
  @override
  late final GeneratedColumn<bool> flipH = GeneratedColumn<bool>(
      'flip_h', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("flip_h" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _flipVMeta = const VerificationMeta('flipV');
  @override
  late final GeneratedColumn<bool> flipV = GeneratedColumn<bool>(
      'flip_v', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("flip_v" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
      'speed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _fitModeMeta =
      const VerificationMeta('fitMode');
  @override
  late final GeneratedColumn<String> fitMode = GeneratedColumn<String>(
      'fit_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('fit'));
  static const VerificationMeta _lookStrengthMeta =
      const VerificationMeta('lookStrength');
  @override
  late final GeneratedColumn<double> lookStrength = GeneratedColumn<double>(
      'look_strength', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _effectMeta = const VerificationMeta('effect');
  @override
  late final GeneratedColumn<String> effect = GeneratedColumn<String>(
      'effect', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _effectStrengthMeta =
      const VerificationMeta('effectStrength');
  @override
  late final GeneratedColumn<double> effectStrength = GeneratedColumn<double>(
      'effect_strength', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _enhanceSpeechMeta =
      const VerificationMeta('enhanceSpeech');
  @override
  late final GeneratedColumn<bool> enhanceSpeech = GeneratedColumn<bool>(
      'enhance_speech', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("enhance_speech" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _keyJsonMeta =
      const VerificationMeta('keyJson');
  @override
  late final GeneratedColumn<String> keyJson = GeneratedColumn<String>(
      'key_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        sourceUri,
        orderIndex,
        trimStartMs,
        trimEndMs,
        durationMs,
        rotationDegrees,
        thumbnailUri,
        transitionOut,
        brightness,
        contrast,
        saturation,
        filterPreset,
        muted,
        volume,
        look,
        turns,
        flipH,
        flipV,
        speed,
        fitMode,
        lookStrength,
        effect,
        effectStrength,
        enhanceSpeech,
        keyJson
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
    if (data.containsKey('rotation_degrees')) {
      context.handle(
          _rotationDegreesMeta,
          rotationDegrees.isAcceptableOrUnknown(
              data['rotation_degrees']!, _rotationDegreesMeta));
    }
    if (data.containsKey('thumbnail_uri')) {
      context.handle(
          _thumbnailUriMeta,
          thumbnailUri.isAcceptableOrUnknown(
              data['thumbnail_uri']!, _thumbnailUriMeta));
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
    if (data.containsKey('filter_preset')) {
      context.handle(
          _filterPresetMeta,
          filterPreset.isAcceptableOrUnknown(
              data['filter_preset']!, _filterPresetMeta));
    }
    if (data.containsKey('muted')) {
      context.handle(
          _mutedMeta, muted.isAcceptableOrUnknown(data['muted']!, _mutedMeta));
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta,
          volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    if (data.containsKey('look')) {
      context.handle(
          _lookMeta, look.isAcceptableOrUnknown(data['look']!, _lookMeta));
    }
    if (data.containsKey('turns')) {
      context.handle(
          _turnsMeta, turns.isAcceptableOrUnknown(data['turns']!, _turnsMeta));
    }
    if (data.containsKey('flip_h')) {
      context.handle(
          _flipHMeta, flipH.isAcceptableOrUnknown(data['flip_h']!, _flipHMeta));
    }
    if (data.containsKey('flip_v')) {
      context.handle(
          _flipVMeta, flipV.isAcceptableOrUnknown(data['flip_v']!, _flipVMeta));
    }
    if (data.containsKey('speed')) {
      context.handle(
          _speedMeta, speed.isAcceptableOrUnknown(data['speed']!, _speedMeta));
    }
    if (data.containsKey('fit_mode')) {
      context.handle(_fitModeMeta,
          fitMode.isAcceptableOrUnknown(data['fit_mode']!, _fitModeMeta));
    }
    if (data.containsKey('look_strength')) {
      context.handle(
          _lookStrengthMeta,
          lookStrength.isAcceptableOrUnknown(
              data['look_strength']!, _lookStrengthMeta));
    }
    if (data.containsKey('effect')) {
      context.handle(_effectMeta,
          effect.isAcceptableOrUnknown(data['effect']!, _effectMeta));
    }
    if (data.containsKey('effect_strength')) {
      context.handle(
          _effectStrengthMeta,
          effectStrength.isAcceptableOrUnknown(
              data['effect_strength']!, _effectStrengthMeta));
    }
    if (data.containsKey('enhance_speech')) {
      context.handle(
          _enhanceSpeechMeta,
          enhanceSpeech.isAcceptableOrUnknown(
              data['enhance_speech']!, _enhanceSpeechMeta));
    }
    if (data.containsKey('key_json')) {
      context.handle(_keyJsonMeta,
          keyJson.isAcceptableOrUnknown(data['key_json']!, _keyJsonMeta));
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
      rotationDegrees: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rotation_degrees'])!,
      thumbnailUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_uri']),
      transitionOut: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transition_out'])!,
      brightness: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}brightness'])!,
      contrast: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}contrast'])!,
      saturation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}saturation'])!,
      filterPreset: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filter_preset']),
      muted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}muted'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
      look: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}look']),
      turns: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}turns'])!,
      flipH: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}flip_h'])!,
      flipV: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}flip_v'])!,
      speed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed'])!,
      fitMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fit_mode'])!,
      lookStrength: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}look_strength'])!,
      effect: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effect']),
      effectStrength: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}effect_strength'])!,
      enhanceSpeech: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enhance_speech'])!,
      keyJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_json']),
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

  /// Degrees of rotation baked into the source container (0/90/180/270).
  /// Carried over from MediaAsset at import time so the timeline/preview
  /// don't need to re-probe the file to display it right-side-up.
  final int rotationDegrees;

  /// Cached thumbnail for this clip's timeline tile. Copied from the
  /// MediaAsset that created the clip; a split clip reuses its parent's.
  final String? thumbnailUri;
  final String transitionOut;
  final double brightness;
  final double contrast;
  final double saturation;

  /// Which `FilterPreset` (see `models/color_filter_x.dart`) this clip's
  /// brightness/contrast/saturation currently match, or null once the
  /// user drags a slider away from any preset ("Custom"). Purely a UI
  /// convenience so `FilterPanel` can highlight the active chip — the
  /// three numeric columns above are always the source of truth for
  /// what actually renders, both in the live preview and (Phase 8) at
  /// export.
  final String? filterPreset;
  final bool muted;

  /// Independent volume for this clip's *original* audio (0.0–1.0),
  /// separate from [muted] — mute is a hard on/off, this is the level
  /// applied when it isn't muted. Added Phase 5 (second half); mirrors
  /// `AudioTracks.volume`'s range/semantics so `TrimPanel` and
  /// `AudioTrackPanel`'s sliders behave the same way.
  final double volume;

  /// F7: which stylized look (see `models/look_x.dart`'s `lookPresets`)
  /// is layered on top of the brightness/contrast/saturation sliders
  /// above, or null for none. Unlike [filterPreset] (a shortcut for the
  /// three numeric sliders), a look's math — colorchannelmixer, a
  /// vignette — isn't expressible as brightness/contrast/saturation, so
  /// it needs its own column rather than reusing [filterPreset].
  final String? look;

  /// F10: quarter-turns clockwise (0–3) applied on top of
  /// [rotationDegrees] (the container-level rotation already baked into
  /// the source file). A user-requested rotate, not a re-probe of the
  /// file.
  final int turns;
  final bool flipH;
  final bool flipV;

  /// F11: constant per-clip playback speed, 0.5–2.0 (1.0 = unchanged).
  /// Scoped to this range so export needs exactly one FFmpeg `atempo`
  /// filter for the audio path — `atempo`'s own valid range is 0.5–2.0,
  /// and chaining several to cover a wider range is deliberately out of
  /// scope for this pass (see `export_command_builder.dart`). Ramped
  /// (mid-clip) speed changes are out of scope too — this is constant
  /// speed for the whole clip, same "v1 scope" call the original F11
  /// plan already made. Ignored for photo clips (nothing to speed up).
  final double speed;

  /// F15: how a clip whose shape differs from the project's fills the
  /// frame — 'fit' (letterbox, the pre-F15 behaviour), 'fill' (crop to
  /// cover) or 'blur' (fit over a blurred, cropped copy of itself). See
  /// `models/fit_mode_x.dart`.
  final String fitMode;

  /// How strongly [look] is applied, 0..1 (1 = the look as designed).
  final double lookStrength;

  /// v11: one effect from `models/effect_x.dart` (motion or stylise), or
  /// null for none, and how strongly it applies (0..1).
  final String? effect;
  final double effectStrength;

  /// v11: export cleans this clip's voice (denoise, EQ, compression).
  /// Export-only — the preview plays the original sound.
  final bool enhanceSpeech;

  /// v12: background removal (`models/chroma_key.dart` JSON), or null.
  final String? keyJson;
  const Clip(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.orderIndex,
      required this.trimStartMs,
      required this.trimEndMs,
      required this.durationMs,
      required this.rotationDegrees,
      this.thumbnailUri,
      required this.transitionOut,
      required this.brightness,
      required this.contrast,
      required this.saturation,
      this.filterPreset,
      required this.muted,
      required this.volume,
      this.look,
      required this.turns,
      required this.flipH,
      required this.flipV,
      required this.speed,
      required this.fitMode,
      required this.lookStrength,
      this.effect,
      required this.effectStrength,
      required this.enhanceSpeech,
      this.keyJson});
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
    map['rotation_degrees'] = Variable<int>(rotationDegrees);
    if (!nullToAbsent || thumbnailUri != null) {
      map['thumbnail_uri'] = Variable<String>(thumbnailUri);
    }
    map['transition_out'] = Variable<String>(transitionOut);
    map['brightness'] = Variable<double>(brightness);
    map['contrast'] = Variable<double>(contrast);
    map['saturation'] = Variable<double>(saturation);
    if (!nullToAbsent || filterPreset != null) {
      map['filter_preset'] = Variable<String>(filterPreset);
    }
    map['muted'] = Variable<bool>(muted);
    map['volume'] = Variable<double>(volume);
    if (!nullToAbsent || look != null) {
      map['look'] = Variable<String>(look);
    }
    map['turns'] = Variable<int>(turns);
    map['flip_h'] = Variable<bool>(flipH);
    map['flip_v'] = Variable<bool>(flipV);
    map['speed'] = Variable<double>(speed);
    map['fit_mode'] = Variable<String>(fitMode);
    map['look_strength'] = Variable<double>(lookStrength);
    if (!nullToAbsent || effect != null) {
      map['effect'] = Variable<String>(effect);
    }
    map['effect_strength'] = Variable<double>(effectStrength);
    map['enhance_speech'] = Variable<bool>(enhanceSpeech);
    if (!nullToAbsent || keyJson != null) {
      map['key_json'] = Variable<String>(keyJson);
    }
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
      rotationDegrees: Value(rotationDegrees),
      thumbnailUri: thumbnailUri == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUri),
      transitionOut: Value(transitionOut),
      brightness: Value(brightness),
      contrast: Value(contrast),
      saturation: Value(saturation),
      filterPreset: filterPreset == null && nullToAbsent
          ? const Value.absent()
          : Value(filterPreset),
      muted: Value(muted),
      volume: Value(volume),
      look: look == null && nullToAbsent ? const Value.absent() : Value(look),
      turns: Value(turns),
      flipH: Value(flipH),
      flipV: Value(flipV),
      speed: Value(speed),
      fitMode: Value(fitMode),
      lookStrength: Value(lookStrength),
      effect:
          effect == null && nullToAbsent ? const Value.absent() : Value(effect),
      effectStrength: Value(effectStrength),
      enhanceSpeech: Value(enhanceSpeech),
      keyJson: keyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(keyJson),
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
      rotationDegrees: serializer.fromJson<int>(json['rotationDegrees']),
      thumbnailUri: serializer.fromJson<String?>(json['thumbnailUri']),
      transitionOut: serializer.fromJson<String>(json['transitionOut']),
      brightness: serializer.fromJson<double>(json['brightness']),
      contrast: serializer.fromJson<double>(json['contrast']),
      saturation: serializer.fromJson<double>(json['saturation']),
      filterPreset: serializer.fromJson<String?>(json['filterPreset']),
      muted: serializer.fromJson<bool>(json['muted']),
      volume: serializer.fromJson<double>(json['volume']),
      look: serializer.fromJson<String?>(json['look']),
      turns: serializer.fromJson<int>(json['turns']),
      flipH: serializer.fromJson<bool>(json['flipH']),
      flipV: serializer.fromJson<bool>(json['flipV']),
      speed: serializer.fromJson<double>(json['speed']),
      fitMode: serializer.fromJson<String>(json['fitMode']),
      lookStrength: serializer.fromJson<double>(json['lookStrength']),
      effect: serializer.fromJson<String?>(json['effect']),
      effectStrength: serializer.fromJson<double>(json['effectStrength']),
      enhanceSpeech: serializer.fromJson<bool>(json['enhanceSpeech']),
      keyJson: serializer.fromJson<String?>(json['keyJson']),
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
      'rotationDegrees': serializer.toJson<int>(rotationDegrees),
      'thumbnailUri': serializer.toJson<String?>(thumbnailUri),
      'transitionOut': serializer.toJson<String>(transitionOut),
      'brightness': serializer.toJson<double>(brightness),
      'contrast': serializer.toJson<double>(contrast),
      'saturation': serializer.toJson<double>(saturation),
      'filterPreset': serializer.toJson<String?>(filterPreset),
      'muted': serializer.toJson<bool>(muted),
      'volume': serializer.toJson<double>(volume),
      'look': serializer.toJson<String?>(look),
      'turns': serializer.toJson<int>(turns),
      'flipH': serializer.toJson<bool>(flipH),
      'flipV': serializer.toJson<bool>(flipV),
      'speed': serializer.toJson<double>(speed),
      'fitMode': serializer.toJson<String>(fitMode),
      'lookStrength': serializer.toJson<double>(lookStrength),
      'effect': serializer.toJson<String?>(effect),
      'effectStrength': serializer.toJson<double>(effectStrength),
      'enhanceSpeech': serializer.toJson<bool>(enhanceSpeech),
      'keyJson': serializer.toJson<String?>(keyJson),
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
          int? rotationDegrees,
          Value<String?> thumbnailUri = const Value.absent(),
          String? transitionOut,
          double? brightness,
          double? contrast,
          double? saturation,
          Value<String?> filterPreset = const Value.absent(),
          bool? muted,
          double? volume,
          Value<String?> look = const Value.absent(),
          int? turns,
          bool? flipH,
          bool? flipV,
          double? speed,
          String? fitMode,
          double? lookStrength,
          Value<String?> effect = const Value.absent(),
          double? effectStrength,
          bool? enhanceSpeech,
          Value<String?> keyJson = const Value.absent()}) =>
      Clip(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        orderIndex: orderIndex ?? this.orderIndex,
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: trimEndMs ?? this.trimEndMs,
        durationMs: durationMs ?? this.durationMs,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
        thumbnailUri:
            thumbnailUri.present ? thumbnailUri.value : this.thumbnailUri,
        transitionOut: transitionOut ?? this.transitionOut,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        filterPreset:
            filterPreset.present ? filterPreset.value : this.filterPreset,
        muted: muted ?? this.muted,
        volume: volume ?? this.volume,
        look: look.present ? look.value : this.look,
        turns: turns ?? this.turns,
        flipH: flipH ?? this.flipH,
        flipV: flipV ?? this.flipV,
        speed: speed ?? this.speed,
        fitMode: fitMode ?? this.fitMode,
        lookStrength: lookStrength ?? this.lookStrength,
        effect: effect.present ? effect.value : this.effect,
        effectStrength: effectStrength ?? this.effectStrength,
        enhanceSpeech: enhanceSpeech ?? this.enhanceSpeech,
        keyJson: keyJson.present ? keyJson.value : this.keyJson,
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
      rotationDegrees: data.rotationDegrees.present
          ? data.rotationDegrees.value
          : this.rotationDegrees,
      thumbnailUri: data.thumbnailUri.present
          ? data.thumbnailUri.value
          : this.thumbnailUri,
      transitionOut: data.transitionOut.present
          ? data.transitionOut.value
          : this.transitionOut,
      brightness:
          data.brightness.present ? data.brightness.value : this.brightness,
      contrast: data.contrast.present ? data.contrast.value : this.contrast,
      saturation:
          data.saturation.present ? data.saturation.value : this.saturation,
      filterPreset: data.filterPreset.present
          ? data.filterPreset.value
          : this.filterPreset,
      muted: data.muted.present ? data.muted.value : this.muted,
      volume: data.volume.present ? data.volume.value : this.volume,
      look: data.look.present ? data.look.value : this.look,
      turns: data.turns.present ? data.turns.value : this.turns,
      flipH: data.flipH.present ? data.flipH.value : this.flipH,
      flipV: data.flipV.present ? data.flipV.value : this.flipV,
      speed: data.speed.present ? data.speed.value : this.speed,
      fitMode: data.fitMode.present ? data.fitMode.value : this.fitMode,
      lookStrength: data.lookStrength.present
          ? data.lookStrength.value
          : this.lookStrength,
      effect: data.effect.present ? data.effect.value : this.effect,
      effectStrength: data.effectStrength.present
          ? data.effectStrength.value
          : this.effectStrength,
      enhanceSpeech: data.enhanceSpeech.present
          ? data.enhanceSpeech.value
          : this.enhanceSpeech,
      keyJson: data.keyJson.present ? data.keyJson.value : this.keyJson,
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
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('thumbnailUri: $thumbnailUri, ')
          ..write('transitionOut: $transitionOut, ')
          ..write('brightness: $brightness, ')
          ..write('contrast: $contrast, ')
          ..write('saturation: $saturation, ')
          ..write('filterPreset: $filterPreset, ')
          ..write('muted: $muted, ')
          ..write('volume: $volume, ')
          ..write('look: $look, ')
          ..write('turns: $turns, ')
          ..write('flipH: $flipH, ')
          ..write('flipV: $flipV, ')
          ..write('speed: $speed, ')
          ..write('fitMode: $fitMode, ')
          ..write('lookStrength: $lookStrength, ')
          ..write('effect: $effect, ')
          ..write('effectStrength: $effectStrength, ')
          ..write('enhanceSpeech: $enhanceSpeech, ')
          ..write('keyJson: $keyJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        projectId,
        sourceUri,
        orderIndex,
        trimStartMs,
        trimEndMs,
        durationMs,
        rotationDegrees,
        thumbnailUri,
        transitionOut,
        brightness,
        contrast,
        saturation,
        filterPreset,
        muted,
        volume,
        look,
        turns,
        flipH,
        flipV,
        speed,
        fitMode,
        lookStrength,
        effect,
        effectStrength,
        enhanceSpeech,
        keyJson
      ]);
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
          other.rotationDegrees == this.rotationDegrees &&
          other.thumbnailUri == this.thumbnailUri &&
          other.transitionOut == this.transitionOut &&
          other.brightness == this.brightness &&
          other.contrast == this.contrast &&
          other.saturation == this.saturation &&
          other.filterPreset == this.filterPreset &&
          other.muted == this.muted &&
          other.volume == this.volume &&
          other.look == this.look &&
          other.turns == this.turns &&
          other.flipH == this.flipH &&
          other.flipV == this.flipV &&
          other.speed == this.speed &&
          other.fitMode == this.fitMode &&
          other.lookStrength == this.lookStrength &&
          other.effect == this.effect &&
          other.effectStrength == this.effectStrength &&
          other.enhanceSpeech == this.enhanceSpeech &&
          other.keyJson == this.keyJson);
}

class ClipsCompanion extends UpdateCompanion<Clip> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceUri;
  final Value<int> orderIndex;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int> durationMs;
  final Value<int> rotationDegrees;
  final Value<String?> thumbnailUri;
  final Value<String> transitionOut;
  final Value<double> brightness;
  final Value<double> contrast;
  final Value<double> saturation;
  final Value<String?> filterPreset;
  final Value<bool> muted;
  final Value<double> volume;
  final Value<String?> look;
  final Value<int> turns;
  final Value<bool> flipH;
  final Value<bool> flipV;
  final Value<double> speed;
  final Value<String> fitMode;
  final Value<double> lookStrength;
  final Value<String?> effect;
  final Value<double> effectStrength;
  final Value<bool> enhanceSpeech;
  final Value<String?> keyJson;
  final Value<int> rowid;
  const ClipsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
    this.thumbnailUri = const Value.absent(),
    this.transitionOut = const Value.absent(),
    this.brightness = const Value.absent(),
    this.contrast = const Value.absent(),
    this.saturation = const Value.absent(),
    this.filterPreset = const Value.absent(),
    this.muted = const Value.absent(),
    this.volume = const Value.absent(),
    this.look = const Value.absent(),
    this.turns = const Value.absent(),
    this.flipH = const Value.absent(),
    this.flipV = const Value.absent(),
    this.speed = const Value.absent(),
    this.fitMode = const Value.absent(),
    this.lookStrength = const Value.absent(),
    this.effect = const Value.absent(),
    this.effectStrength = const Value.absent(),
    this.enhanceSpeech = const Value.absent(),
    this.keyJson = const Value.absent(),
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
    this.rotationDegrees = const Value.absent(),
    this.thumbnailUri = const Value.absent(),
    this.transitionOut = const Value.absent(),
    this.brightness = const Value.absent(),
    this.contrast = const Value.absent(),
    this.saturation = const Value.absent(),
    this.filterPreset = const Value.absent(),
    this.muted = const Value.absent(),
    this.volume = const Value.absent(),
    this.look = const Value.absent(),
    this.turns = const Value.absent(),
    this.flipH = const Value.absent(),
    this.flipV = const Value.absent(),
    this.speed = const Value.absent(),
    this.fitMode = const Value.absent(),
    this.lookStrength = const Value.absent(),
    this.effect = const Value.absent(),
    this.effectStrength = const Value.absent(),
    this.enhanceSpeech = const Value.absent(),
    this.keyJson = const Value.absent(),
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
    Expression<int>? rotationDegrees,
    Expression<String>? thumbnailUri,
    Expression<String>? transitionOut,
    Expression<double>? brightness,
    Expression<double>? contrast,
    Expression<double>? saturation,
    Expression<String>? filterPreset,
    Expression<bool>? muted,
    Expression<double>? volume,
    Expression<String>? look,
    Expression<int>? turns,
    Expression<bool>? flipH,
    Expression<bool>? flipV,
    Expression<double>? speed,
    Expression<String>? fitMode,
    Expression<double>? lookStrength,
    Expression<String>? effect,
    Expression<double>? effectStrength,
    Expression<bool>? enhanceSpeech,
    Expression<String>? keyJson,
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
      if (rotationDegrees != null) 'rotation_degrees': rotationDegrees,
      if (thumbnailUri != null) 'thumbnail_uri': thumbnailUri,
      if (transitionOut != null) 'transition_out': transitionOut,
      if (brightness != null) 'brightness': brightness,
      if (contrast != null) 'contrast': contrast,
      if (saturation != null) 'saturation': saturation,
      if (filterPreset != null) 'filter_preset': filterPreset,
      if (muted != null) 'muted': muted,
      if (volume != null) 'volume': volume,
      if (look != null) 'look': look,
      if (turns != null) 'turns': turns,
      if (flipH != null) 'flip_h': flipH,
      if (flipV != null) 'flip_v': flipV,
      if (speed != null) 'speed': speed,
      if (fitMode != null) 'fit_mode': fitMode,
      if (lookStrength != null) 'look_strength': lookStrength,
      if (effect != null) 'effect': effect,
      if (effectStrength != null) 'effect_strength': effectStrength,
      if (enhanceSpeech != null) 'enhance_speech': enhanceSpeech,
      if (keyJson != null) 'key_json': keyJson,
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
      Value<int>? rotationDegrees,
      Value<String?>? thumbnailUri,
      Value<String>? transitionOut,
      Value<double>? brightness,
      Value<double>? contrast,
      Value<double>? saturation,
      Value<String?>? filterPreset,
      Value<bool>? muted,
      Value<double>? volume,
      Value<String?>? look,
      Value<int>? turns,
      Value<bool>? flipH,
      Value<bool>? flipV,
      Value<double>? speed,
      Value<String>? fitMode,
      Value<double>? lookStrength,
      Value<String?>? effect,
      Value<double>? effectStrength,
      Value<bool>? enhanceSpeech,
      Value<String?>? keyJson,
      Value<int>? rowid}) {
    return ClipsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceUri: sourceUri ?? this.sourceUri,
      orderIndex: orderIndex ?? this.orderIndex,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      durationMs: durationMs ?? this.durationMs,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      transitionOut: transitionOut ?? this.transitionOut,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      filterPreset: filterPreset ?? this.filterPreset,
      muted: muted ?? this.muted,
      volume: volume ?? this.volume,
      look: look ?? this.look,
      turns: turns ?? this.turns,
      flipH: flipH ?? this.flipH,
      flipV: flipV ?? this.flipV,
      speed: speed ?? this.speed,
      fitMode: fitMode ?? this.fitMode,
      lookStrength: lookStrength ?? this.lookStrength,
      effect: effect ?? this.effect,
      effectStrength: effectStrength ?? this.effectStrength,
      enhanceSpeech: enhanceSpeech ?? this.enhanceSpeech,
      keyJson: keyJson ?? this.keyJson,
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
    if (rotationDegrees.present) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees.value);
    }
    if (thumbnailUri.present) {
      map['thumbnail_uri'] = Variable<String>(thumbnailUri.value);
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
    if (filterPreset.present) {
      map['filter_preset'] = Variable<String>(filterPreset.value);
    }
    if (muted.present) {
      map['muted'] = Variable<bool>(muted.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (look.present) {
      map['look'] = Variable<String>(look.value);
    }
    if (turns.present) {
      map['turns'] = Variable<int>(turns.value);
    }
    if (flipH.present) {
      map['flip_h'] = Variable<bool>(flipH.value);
    }
    if (flipV.present) {
      map['flip_v'] = Variable<bool>(flipV.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (fitMode.present) {
      map['fit_mode'] = Variable<String>(fitMode.value);
    }
    if (lookStrength.present) {
      map['look_strength'] = Variable<double>(lookStrength.value);
    }
    if (effect.present) {
      map['effect'] = Variable<String>(effect.value);
    }
    if (effectStrength.present) {
      map['effect_strength'] = Variable<double>(effectStrength.value);
    }
    if (enhanceSpeech.present) {
      map['enhance_speech'] = Variable<bool>(enhanceSpeech.value);
    }
    if (keyJson.present) {
      map['key_json'] = Variable<String>(keyJson.value);
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
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('thumbnailUri: $thumbnailUri, ')
          ..write('transitionOut: $transitionOut, ')
          ..write('brightness: $brightness, ')
          ..write('contrast: $contrast, ')
          ..write('saturation: $saturation, ')
          ..write('filterPreset: $filterPreset, ')
          ..write('muted: $muted, ')
          ..write('volume: $volume, ')
          ..write('look: $look, ')
          ..write('turns: $turns, ')
          ..write('flipH: $flipH, ')
          ..write('flipV: $flipV, ')
          ..write('speed: $speed, ')
          ..write('fitMode: $fitMode, ')
          ..write('lookStrength: $lookStrength, ')
          ..write('effect: $effect, ')
          ..write('effectStrength: $effectStrength, ')
          ..write('enhanceSpeech: $enhanceSpeech, ')
          ..write('keyJson: $keyJson, ')
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
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
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
  static const VerificationMeta _fadeInMsMeta =
      const VerificationMeta('fadeInMs');
  @override
  late final GeneratedColumn<int> fadeInMs = GeneratedColumn<int>(
      'fade_in_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _fadeOutMsMeta =
      const VerificationMeta('fadeOutMs');
  @override
  late final GeneratedColumn<int> fadeOutMs = GeneratedColumn<int>(
      'fade_out_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        sourceUri,
        durationMs,
        trimStartMs,
        trimEndMs,
        offsetMs,
        volume,
        fadeInMs,
        fadeOutMs
      ];
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
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
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
    if (data.containsKey('fade_in_ms')) {
      context.handle(_fadeInMsMeta,
          fadeInMs.isAcceptableOrUnknown(data['fade_in_ms']!, _fadeInMsMeta));
    }
    if (data.containsKey('fade_out_ms')) {
      context.handle(
          _fadeOutMsMeta,
          fadeOutMs.isAcceptableOrUnknown(
              data['fade_out_ms']!, _fadeOutMsMeta));
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
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      trimStartMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_start_ms'])!,
      trimEndMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}trim_end_ms'])!,
      offsetMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}offset_ms'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
      fadeInMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fade_in_ms'])!,
      fadeOutMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fade_out_ms'])!,
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

  /// The source file's full untrimmed duration, in ms — kept separate
  /// from trimStartMs/trimEndMs so a trim can be dragged back out after
  /// being narrowed, same rationale as Clips.durationMs above.
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int offsetMs;
  final double volume;

  /// F9: fade the music in/out at its own start/end (i.e. within the
  /// trimmed window above, not the timeline) — 0 means no fade, same
  /// "0 is the neutral default" convention every other optional column
  /// here uses. Applied at export via FFmpeg `afade`; the preview
  /// approximates it with a volume ramp (see `VideoPreviewPlayer`) since
  /// `just_audio` has no frame-accurate fade filter — export is the
  /// exact version, same relationship F15/F19 already have between
  /// preview and export elsewhere in this app.
  final int fadeInMs;
  final int fadeOutMs;
  const AudioTrack(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.durationMs,
      required this.trimStartMs,
      required this.trimEndMs,
      required this.offsetMs,
      required this.volume,
      required this.fadeInMs,
      required this.fadeOutMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_uri'] = Variable<String>(sourceUri);
    map['duration_ms'] = Variable<int>(durationMs);
    map['trim_start_ms'] = Variable<int>(trimStartMs);
    map['trim_end_ms'] = Variable<int>(trimEndMs);
    map['offset_ms'] = Variable<int>(offsetMs);
    map['volume'] = Variable<double>(volume);
    map['fade_in_ms'] = Variable<int>(fadeInMs);
    map['fade_out_ms'] = Variable<int>(fadeOutMs);
    return map;
  }

  AudioTracksCompanion toCompanion(bool nullToAbsent) {
    return AudioTracksCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceUri: Value(sourceUri),
      durationMs: Value(durationMs),
      trimStartMs: Value(trimStartMs),
      trimEndMs: Value(trimEndMs),
      offsetMs: Value(offsetMs),
      volume: Value(volume),
      fadeInMs: Value(fadeInMs),
      fadeOutMs: Value(fadeOutMs),
    );
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioTrack(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      trimStartMs: serializer.fromJson<int>(json['trimStartMs']),
      trimEndMs: serializer.fromJson<int>(json['trimEndMs']),
      offsetMs: serializer.fromJson<int>(json['offsetMs']),
      volume: serializer.fromJson<double>(json['volume']),
      fadeInMs: serializer.fromJson<int>(json['fadeInMs']),
      fadeOutMs: serializer.fromJson<int>(json['fadeOutMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'durationMs': serializer.toJson<int>(durationMs),
      'trimStartMs': serializer.toJson<int>(trimStartMs),
      'trimEndMs': serializer.toJson<int>(trimEndMs),
      'offsetMs': serializer.toJson<int>(offsetMs),
      'volume': serializer.toJson<double>(volume),
      'fadeInMs': serializer.toJson<int>(fadeInMs),
      'fadeOutMs': serializer.toJson<int>(fadeOutMs),
    };
  }

  AudioTrack copyWith(
          {String? id,
          String? projectId,
          String? sourceUri,
          int? durationMs,
          int? trimStartMs,
          int? trimEndMs,
          int? offsetMs,
          double? volume,
          int? fadeInMs,
          int? fadeOutMs}) =>
      AudioTrack(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        durationMs: durationMs ?? this.durationMs,
        trimStartMs: trimStartMs ?? this.trimStartMs,
        trimEndMs: trimEndMs ?? this.trimEndMs,
        offsetMs: offsetMs ?? this.offsetMs,
        volume: volume ?? this.volume,
        fadeInMs: fadeInMs ?? this.fadeInMs,
        fadeOutMs: fadeOutMs ?? this.fadeOutMs,
      );
  AudioTrack copyWithCompanion(AudioTracksCompanion data) {
    return AudioTrack(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      trimStartMs:
          data.trimStartMs.present ? data.trimStartMs.value : this.trimStartMs,
      trimEndMs: data.trimEndMs.present ? data.trimEndMs.value : this.trimEndMs,
      offsetMs: data.offsetMs.present ? data.offsetMs.value : this.offsetMs,
      volume: data.volume.present ? data.volume.value : this.volume,
      fadeInMs: data.fadeInMs.present ? data.fadeInMs.value : this.fadeInMs,
      fadeOutMs: data.fadeOutMs.present ? data.fadeOutMs.value : this.fadeOutMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioTrack(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('durationMs: $durationMs, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('volume: $volume, ')
          ..write('fadeInMs: $fadeInMs, ')
          ..write('fadeOutMs: $fadeOutMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, sourceUri, durationMs,
      trimStartMs, trimEndMs, offsetMs, volume, fadeInMs, fadeOutMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioTrack &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceUri == this.sourceUri &&
          other.durationMs == this.durationMs &&
          other.trimStartMs == this.trimStartMs &&
          other.trimEndMs == this.trimEndMs &&
          other.offsetMs == this.offsetMs &&
          other.volume == this.volume &&
          other.fadeInMs == this.fadeInMs &&
          other.fadeOutMs == this.fadeOutMs);
}

class AudioTracksCompanion extends UpdateCompanion<AudioTrack> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceUri;
  final Value<int> durationMs;
  final Value<int> trimStartMs;
  final Value<int> trimEndMs;
  final Value<int> offsetMs;
  final Value<double> volume;
  final Value<int> fadeInMs;
  final Value<int> fadeOutMs;
  final Value<int> rowid;
  const AudioTracksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    this.trimEndMs = const Value.absent(),
    this.offsetMs = const Value.absent(),
    this.volume = const Value.absent(),
    this.fadeInMs = const Value.absent(),
    this.fadeOutMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioTracksCompanion.insert({
    required String id,
    required String projectId,
    required String sourceUri,
    this.durationMs = const Value.absent(),
    this.trimStartMs = const Value.absent(),
    required int trimEndMs,
    this.offsetMs = const Value.absent(),
    this.volume = const Value.absent(),
    this.fadeInMs = const Value.absent(),
    this.fadeOutMs = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        sourceUri = Value(sourceUri),
        trimEndMs = Value(trimEndMs);
  static Insertable<AudioTrack> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceUri,
    Expression<int>? durationMs,
    Expression<int>? trimStartMs,
    Expression<int>? trimEndMs,
    Expression<int>? offsetMs,
    Expression<double>? volume,
    Expression<int>? fadeInMs,
    Expression<int>? fadeOutMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (durationMs != null) 'duration_ms': durationMs,
      if (trimStartMs != null) 'trim_start_ms': trimStartMs,
      if (trimEndMs != null) 'trim_end_ms': trimEndMs,
      if (offsetMs != null) 'offset_ms': offsetMs,
      if (volume != null) 'volume': volume,
      if (fadeInMs != null) 'fade_in_ms': fadeInMs,
      if (fadeOutMs != null) 'fade_out_ms': fadeOutMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioTracksCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? sourceUri,
      Value<int>? durationMs,
      Value<int>? trimStartMs,
      Value<int>? trimEndMs,
      Value<int>? offsetMs,
      Value<double>? volume,
      Value<int>? fadeInMs,
      Value<int>? fadeOutMs,
      Value<int>? rowid}) {
    return AudioTracksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceUri: sourceUri ?? this.sourceUri,
      durationMs: durationMs ?? this.durationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      offsetMs: offsetMs ?? this.offsetMs,
      volume: volume ?? this.volume,
      fadeInMs: fadeInMs ?? this.fadeInMs,
      fadeOutMs: fadeOutMs ?? this.fadeOutMs,
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
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
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
    if (fadeInMs.present) {
      map['fade_in_ms'] = Variable<int>(fadeInMs.value);
    }
    if (fadeOutMs.present) {
      map['fade_out_ms'] = Variable<int>(fadeOutMs.value);
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
          ..write('durationMs: $durationMs, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('volume: $volume, ')
          ..write('fadeInMs: $fadeInMs, ')
          ..write('fadeOutMs: $fadeOutMs, ')
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
  static const VerificationMeta _alignmentMeta =
      const VerificationMeta('alignment');
  @override
  late final GeneratedColumn<int> alignment = GeneratedColumn<int>(
      'alignment', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _boldMeta = const VerificationMeta('bold');
  @override
  late final GeneratedColumn<bool> bold = GeneratedColumn<bool>(
      'bold', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("bold" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _boxEnabledMeta =
      const VerificationMeta('boxEnabled');
  @override
  late final GeneratedColumn<bool> boxEnabled = GeneratedColumn<bool>(
      'box_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("box_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _boxColorValueMeta =
      const VerificationMeta('boxColorValue');
  @override
  late final GeneratedColumn<int> boxColorValue = GeneratedColumn<int>(
      'box_color_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0x99000000));
  static const VerificationMeta _outlineWidthMeta =
      const VerificationMeta('outlineWidth');
  @override
  late final GeneratedColumn<double> outlineWidth = GeneratedColumn<double>(
      'outline_width', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _outlineColorValueMeta =
      const VerificationMeta('outlineColorValue');
  @override
  late final GeneratedColumn<int> outlineColorValue = GeneratedColumn<int>(
      'outline_color_value', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0xFF000000));
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
        endMs,
        alignment,
        bold,
        boxEnabled,
        boxColorValue,
        outlineWidth,
        outlineColorValue
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
    if (data.containsKey('alignment')) {
      context.handle(_alignmentMeta,
          alignment.isAcceptableOrUnknown(data['alignment']!, _alignmentMeta));
    }
    if (data.containsKey('bold')) {
      context.handle(
          _boldMeta, bold.isAcceptableOrUnknown(data['bold']!, _boldMeta));
    }
    if (data.containsKey('box_enabled')) {
      context.handle(
          _boxEnabledMeta,
          boxEnabled.isAcceptableOrUnknown(
              data['box_enabled']!, _boxEnabledMeta));
    }
    if (data.containsKey('box_color_value')) {
      context.handle(
          _boxColorValueMeta,
          boxColorValue.isAcceptableOrUnknown(
              data['box_color_value']!, _boxColorValueMeta));
    }
    if (data.containsKey('outline_width')) {
      context.handle(
          _outlineWidthMeta,
          outlineWidth.isAcceptableOrUnknown(
              data['outline_width']!, _outlineWidthMeta));
    }
    if (data.containsKey('outline_color_value')) {
      context.handle(
          _outlineColorValueMeta,
          outlineColorValue.isAcceptableOrUnknown(
              data['outline_color_value']!, _outlineColorValueMeta));
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
      alignment: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}alignment'])!,
      bold: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}bold'])!,
      boxEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}box_enabled'])!,
      boxColorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}box_color_value'])!,
      outlineWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}outline_width'])!,
      outlineColorValue: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}outline_color_value'])!,
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

  /// 0 = left, 1 = center, 2 = right — see `TextAlignment` in
  /// `models/text_overlay_x.dart` for the enum this maps to. Stored as
  /// an int rather than a text enum for the same reason `transitionOut`
  /// above is a string, not the other way: drift doesn't need a custom
  /// converter for a 3-value int, so keep it plain.
  final int alignment;

  /// F8 (text styling v2): bold weight, a background box, and an
  /// outline/stroke — on top of the font/size/color/alignment above.
  /// [boxColorValue] and [outlineColorValue] are independent of
  /// [colorValue] (the text fill) so e.g. white text can sit on a black
  /// box without the two colors being forced to match.
  final bool bold;
  final bool boxEnabled;
  final int boxColorValue;

  /// Outline width in the same logical-px space [fontSize] uses; 0 means
  /// no outline (the pre-F8 behavior — every overlay before this column
  /// existed effectively had width 0).
  final double outlineWidth;
  final int outlineColorValue;
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
      required this.endMs,
      required this.alignment,
      required this.bold,
      required this.boxEnabled,
      required this.boxColorValue,
      required this.outlineWidth,
      required this.outlineColorValue});
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
    map['alignment'] = Variable<int>(alignment);
    map['bold'] = Variable<bool>(bold);
    map['box_enabled'] = Variable<bool>(boxEnabled);
    map['box_color_value'] = Variable<int>(boxColorValue);
    map['outline_width'] = Variable<double>(outlineWidth);
    map['outline_color_value'] = Variable<int>(outlineColorValue);
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
      alignment: Value(alignment),
      bold: Value(bold),
      boxEnabled: Value(boxEnabled),
      boxColorValue: Value(boxColorValue),
      outlineWidth: Value(outlineWidth),
      outlineColorValue: Value(outlineColorValue),
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
      alignment: serializer.fromJson<int>(json['alignment']),
      bold: serializer.fromJson<bool>(json['bold']),
      boxEnabled: serializer.fromJson<bool>(json['boxEnabled']),
      boxColorValue: serializer.fromJson<int>(json['boxColorValue']),
      outlineWidth: serializer.fromJson<double>(json['outlineWidth']),
      outlineColorValue: serializer.fromJson<int>(json['outlineColorValue']),
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
      'alignment': serializer.toJson<int>(alignment),
      'bold': serializer.toJson<bool>(bold),
      'boxEnabled': serializer.toJson<bool>(boxEnabled),
      'boxColorValue': serializer.toJson<int>(boxColorValue),
      'outlineWidth': serializer.toJson<double>(outlineWidth),
      'outlineColorValue': serializer.toJson<int>(outlineColorValue),
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
          int? endMs,
          int? alignment,
          bool? bold,
          bool? boxEnabled,
          int? boxColorValue,
          double? outlineWidth,
          int? outlineColorValue}) =>
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
        alignment: alignment ?? this.alignment,
        bold: bold ?? this.bold,
        boxEnabled: boxEnabled ?? this.boxEnabled,
        boxColorValue: boxColorValue ?? this.boxColorValue,
        outlineWidth: outlineWidth ?? this.outlineWidth,
        outlineColorValue: outlineColorValue ?? this.outlineColorValue,
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
      alignment: data.alignment.present ? data.alignment.value : this.alignment,
      bold: data.bold.present ? data.bold.value : this.bold,
      boxEnabled:
          data.boxEnabled.present ? data.boxEnabled.value : this.boxEnabled,
      boxColorValue: data.boxColorValue.present
          ? data.boxColorValue.value
          : this.boxColorValue,
      outlineWidth: data.outlineWidth.present
          ? data.outlineWidth.value
          : this.outlineWidth,
      outlineColorValue: data.outlineColorValue.present
          ? data.outlineColorValue.value
          : this.outlineColorValue,
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
          ..write('endMs: $endMs, ')
          ..write('alignment: $alignment, ')
          ..write('bold: $bold, ')
          ..write('boxEnabled: $boxEnabled, ')
          ..write('boxColorValue: $boxColorValue, ')
          ..write('outlineWidth: $outlineWidth, ')
          ..write('outlineColorValue: $outlineColorValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      content,
      fontFamily,
      colorValue,
      fontSize,
      positionX,
      positionY,
      startMs,
      endMs,
      alignment,
      bold,
      boxEnabled,
      boxColorValue,
      outlineWidth,
      outlineColorValue);
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
          other.endMs == this.endMs &&
          other.alignment == this.alignment &&
          other.bold == this.bold &&
          other.boxEnabled == this.boxEnabled &&
          other.boxColorValue == this.boxColorValue &&
          other.outlineWidth == this.outlineWidth &&
          other.outlineColorValue == this.outlineColorValue);
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
  final Value<int> alignment;
  final Value<bool> bold;
  final Value<bool> boxEnabled;
  final Value<int> boxColorValue;
  final Value<double> outlineWidth;
  final Value<int> outlineColorValue;
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
    this.alignment = const Value.absent(),
    this.bold = const Value.absent(),
    this.boxEnabled = const Value.absent(),
    this.boxColorValue = const Value.absent(),
    this.outlineWidth = const Value.absent(),
    this.outlineColorValue = const Value.absent(),
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
    this.alignment = const Value.absent(),
    this.bold = const Value.absent(),
    this.boxEnabled = const Value.absent(),
    this.boxColorValue = const Value.absent(),
    this.outlineWidth = const Value.absent(),
    this.outlineColorValue = const Value.absent(),
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
    Expression<int>? alignment,
    Expression<bool>? bold,
    Expression<bool>? boxEnabled,
    Expression<int>? boxColorValue,
    Expression<double>? outlineWidth,
    Expression<int>? outlineColorValue,
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
      if (alignment != null) 'alignment': alignment,
      if (bold != null) 'bold': bold,
      if (boxEnabled != null) 'box_enabled': boxEnabled,
      if (boxColorValue != null) 'box_color_value': boxColorValue,
      if (outlineWidth != null) 'outline_width': outlineWidth,
      if (outlineColorValue != null) 'outline_color_value': outlineColorValue,
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
      Value<int>? alignment,
      Value<bool>? bold,
      Value<bool>? boxEnabled,
      Value<int>? boxColorValue,
      Value<double>? outlineWidth,
      Value<int>? outlineColorValue,
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
      alignment: alignment ?? this.alignment,
      bold: bold ?? this.bold,
      boxEnabled: boxEnabled ?? this.boxEnabled,
      boxColorValue: boxColorValue ?? this.boxColorValue,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      outlineColorValue: outlineColorValue ?? this.outlineColorValue,
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
    if (alignment.present) {
      map['alignment'] = Variable<int>(alignment.value);
    }
    if (bold.present) {
      map['bold'] = Variable<bool>(bold.value);
    }
    if (boxEnabled.present) {
      map['box_enabled'] = Variable<bool>(boxEnabled.value);
    }
    if (boxColorValue.present) {
      map['box_color_value'] = Variable<int>(boxColorValue.value);
    }
    if (outlineWidth.present) {
      map['outline_width'] = Variable<double>(outlineWidth.value);
    }
    if (outlineColorValue.present) {
      map['outline_color_value'] = Variable<int>(outlineColorValue.value);
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
          ..write('alignment: $alignment, ')
          ..write('bold: $bold, ')
          ..write('boxEnabled: $boxEnabled, ')
          ..write('boxColorValue: $boxColorValue, ')
          ..write('outlineWidth: $outlineWidth, ')
          ..write('outlineColorValue: $outlineColorValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoProjectsTable extends PhotoProjects
    with TableInfo<$PhotoProjectsTable, PhotoProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoProjectsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceUriMeta =
      const VerificationMeta('sourceUri');
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
      'source_uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _editJsonMeta =
      const VerificationMeta('editJson');
  @override
  late final GeneratedColumn<String> editJson = GeneratedColumn<String>(
      'edit_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
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
      [id, name, sourceUri, width, height, editJson, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_projects';
  @override
  VerificationContext validateIntegrity(Insertable<PhotoProject> instance,
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
    if (data.containsKey('source_uri')) {
      context.handle(_sourceUriMeta,
          sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta));
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('edit_json')) {
      context.handle(_editJsonMeta,
          editJson.isAcceptableOrUnknown(data['edit_json']!, _editJsonMeta));
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
  PhotoProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoProject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sourceUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_uri'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      editJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}edit_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PhotoProjectsTable createAlias(String alias) {
    return $PhotoProjectsTable(attachedDatabase, alias);
  }
}

class PhotoProject extends DataClass implements Insertable<PhotoProject> {
  final String id;
  final String name;

  /// The imported copy in app storage (never modified).
  final String sourceUri;
  final int width;
  final int height;
  final String editJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PhotoProject(
      {required this.id,
      required this.name,
      required this.sourceUri,
      required this.width,
      required this.height,
      required this.editJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source_uri'] = Variable<String>(sourceUri);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['edit_json'] = Variable<String>(editJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PhotoProjectsCompanion toCompanion(bool nullToAbsent) {
    return PhotoProjectsCompanion(
      id: Value(id),
      name: Value(name),
      sourceUri: Value(sourceUri),
      width: Value(width),
      height: Value(height),
      editJson: Value(editJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PhotoProject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoProject(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      editJson: serializer.fromJson<String>(json['editJson']),
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
      'sourceUri': serializer.toJson<String>(sourceUri),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'editJson': serializer.toJson<String>(editJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PhotoProject copyWith(
          {String? id,
          String? name,
          String? sourceUri,
          int? width,
          int? height,
          String? editJson,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      PhotoProject(
        id: id ?? this.id,
        name: name ?? this.name,
        sourceUri: sourceUri ?? this.sourceUri,
        width: width ?? this.width,
        height: height ?? this.height,
        editJson: editJson ?? this.editJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PhotoProject copyWithCompanion(PhotoProjectsCompanion data) {
    return PhotoProject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      editJson: data.editJson.present ? data.editJson.value : this.editJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoProject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('editJson: $editJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, sourceUri, width, height, editJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoProject &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceUri == this.sourceUri &&
          other.width == this.width &&
          other.height == this.height &&
          other.editJson == this.editJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PhotoProjectsCompanion extends UpdateCompanion<PhotoProject> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> sourceUri;
  final Value<int> width;
  final Value<int> height;
  final Value<String> editJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PhotoProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.editJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoProjectsCompanion.insert({
    required String id,
    required String name,
    required String sourceUri,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.editJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        sourceUri = Value(sourceUri),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<PhotoProject> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceUri,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? editJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (editJson != null) 'edit_json': editJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? sourceUri,
      Value<int>? width,
      Value<int>? height,
      Value<String>? editJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PhotoProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUri: sourceUri ?? this.sourceUri,
      width: width ?? this.width,
      height: height ?? this.height,
      editJson: editJson ?? this.editJson,
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
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (editJson.present) {
      map['edit_json'] = Variable<String>(editJson.value);
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
    return (StringBuffer('PhotoProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('editJson: $editJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceOversTable extends VoiceOvers
    with TableInfo<$VoiceOversTable, VoiceOver> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceOversTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startMsMeta =
      const VerificationMeta('startMs');
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
      'start_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _volumeMeta = const VerificationMeta('volume');
  @override
  late final GeneratedColumn<double> volume = GeneratedColumn<double>(
      'volume', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _enhanceMeta =
      const VerificationMeta('enhance');
  @override
  late final GeneratedColumn<bool> enhance = GeneratedColumn<bool>(
      'enhance', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enhance" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, sourceUri, startMs, durationMs, volume, enhance];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_overs';
  @override
  VerificationContext validateIntegrity(Insertable<VoiceOver> instance,
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
    if (data.containsKey('start_ms')) {
      context.handle(_startMsMeta,
          startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta));
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('volume')) {
      context.handle(_volumeMeta,
          volume.isAcceptableOrUnknown(data['volume']!, _volumeMeta));
    }
    if (data.containsKey('enhance')) {
      context.handle(_enhanceMeta,
          enhance.isAcceptableOrUnknown(data['enhance']!, _enhanceMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceOver map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceOver(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_id'])!,
      sourceUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_uri'])!,
      startMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ms'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      volume: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}volume'])!,
      enhance: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enhance'])!,
    );
  }

  @override
  $VoiceOversTable createAlias(String alias) {
    return $VoiceOversTable(attachedDatabase, alias);
  }
}

class VoiceOver extends DataClass implements Insertable<VoiceOver> {
  final String id;
  final String projectId;
  final String sourceUri;

  /// Timeline position where it starts.
  final int startMs;
  final int durationMs;
  final double volume;

  /// Same voice clean-up as `Clips.enhanceSpeech`; on by default.
  final bool enhance;
  const VoiceOver(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.startMs,
      required this.durationMs,
      required this.volume,
      required this.enhance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['source_uri'] = Variable<String>(sourceUri);
    map['start_ms'] = Variable<int>(startMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['volume'] = Variable<double>(volume);
    map['enhance'] = Variable<bool>(enhance);
    return map;
  }

  VoiceOversCompanion toCompanion(bool nullToAbsent) {
    return VoiceOversCompanion(
      id: Value(id),
      projectId: Value(projectId),
      sourceUri: Value(sourceUri),
      startMs: Value(startMs),
      durationMs: Value(durationMs),
      volume: Value(volume),
      enhance: Value(enhance),
    );
  }

  factory VoiceOver.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceOver(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sourceUri: serializer.fromJson<String>(json['sourceUri']),
      startMs: serializer.fromJson<int>(json['startMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      volume: serializer.fromJson<double>(json['volume']),
      enhance: serializer.fromJson<bool>(json['enhance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sourceUri': serializer.toJson<String>(sourceUri),
      'startMs': serializer.toJson<int>(startMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'volume': serializer.toJson<double>(volume),
      'enhance': serializer.toJson<bool>(enhance),
    };
  }

  VoiceOver copyWith(
          {String? id,
          String? projectId,
          String? sourceUri,
          int? startMs,
          int? durationMs,
          double? volume,
          bool? enhance}) =>
      VoiceOver(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        startMs: startMs ?? this.startMs,
        durationMs: durationMs ?? this.durationMs,
        volume: volume ?? this.volume,
        enhance: enhance ?? this.enhance,
      );
  VoiceOver copyWithCompanion(VoiceOversCompanion data) {
    return VoiceOver(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      volume: data.volume.present ? data.volume.value : this.volume,
      enhance: data.enhance.present ? data.enhance.value : this.enhance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceOver(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('startMs: $startMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('volume: $volume, ')
          ..write('enhance: $enhance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, projectId, sourceUri, startMs, durationMs, volume, enhance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceOver &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sourceUri == this.sourceUri &&
          other.startMs == this.startMs &&
          other.durationMs == this.durationMs &&
          other.volume == this.volume &&
          other.enhance == this.enhance);
}

class VoiceOversCompanion extends UpdateCompanion<VoiceOver> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> sourceUri;
  final Value<int> startMs;
  final Value<int> durationMs;
  final Value<double> volume;
  final Value<bool> enhance;
  final Value<int> rowid;
  const VoiceOversCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.startMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.volume = const Value.absent(),
    this.enhance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceOversCompanion.insert({
    required String id,
    required String projectId,
    required String sourceUri,
    required int startMs,
    required int durationMs,
    this.volume = const Value.absent(),
    this.enhance = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        projectId = Value(projectId),
        sourceUri = Value(sourceUri),
        startMs = Value(startMs),
        durationMs = Value(durationMs);
  static Insertable<VoiceOver> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? sourceUri,
    Expression<int>? startMs,
    Expression<int>? durationMs,
    Expression<double>? volume,
    Expression<bool>? enhance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (startMs != null) 'start_ms': startMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (volume != null) 'volume': volume,
      if (enhance != null) 'enhance': enhance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceOversCompanion copyWith(
      {Value<String>? id,
      Value<String>? projectId,
      Value<String>? sourceUri,
      Value<int>? startMs,
      Value<int>? durationMs,
      Value<double>? volume,
      Value<bool>? enhance,
      Value<int>? rowid}) {
    return VoiceOversCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sourceUri: sourceUri ?? this.sourceUri,
      startMs: startMs ?? this.startMs,
      durationMs: durationMs ?? this.durationMs,
      volume: volume ?? this.volume,
      enhance: enhance ?? this.enhance,
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
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (volume.present) {
      map['volume'] = Variable<double>(volume.value);
    }
    if (enhance.present) {
      map['enhance'] = Variable<bool>(enhance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceOversCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('startMs: $startMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('volume: $volume, ')
          ..write('enhance: $enhance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AudioProjectsTable extends AudioProjects
    with TableInfo<$AudioProjectsTable, AudioProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AudioProjectsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourceUriMeta =
      const VerificationMeta('sourceUri');
  @override
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
      'source_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _editJsonMeta =
      const VerificationMeta('editJson');
  @override
  late final GeneratedColumn<String> editJson = GeneratedColumn<String>(
      'edit_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _composeJsonMeta =
      const VerificationMeta('composeJson');
  @override
  late final GeneratedColumn<String> composeJson = GeneratedColumn<String>(
      'compose_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  List<GeneratedColumn> get $columns => [
        id,
        name,
        sourceUri,
        durationMs,
        editJson,
        composeJson,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_projects';
  @override
  VerificationContext validateIntegrity(Insertable<AudioProject> instance,
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
    if (data.containsKey('source_uri')) {
      context.handle(_sourceUriMeta,
          sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('edit_json')) {
      context.handle(_editJsonMeta,
          editJson.isAcceptableOrUnknown(data['edit_json']!, _editJsonMeta));
    }
    if (data.containsKey('compose_json')) {
      context.handle(
          _composeJsonMeta,
          composeJson.isAcceptableOrUnknown(
              data['compose_json']!, _composeJsonMeta));
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
  AudioProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioProject(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sourceUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_uri']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      editJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}edit_json'])!,
      composeJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}compose_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AudioProjectsTable createAlias(String alias) {
    return $AudioProjectsTable(attachedDatabase, alias);
  }
}

class AudioProject extends DataClass implements Insertable<AudioProject> {
  final String id;
  final String name;

  /// The audio being edited (an imported copy, a recording, or a rendered
  /// composition). Null for a composition that hasn't been rendered yet.
  final String? sourceUri;
  final int durationMs;
  final String editJson;
  final String? composeJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AudioProject(
      {required this.id,
      required this.name,
      this.sourceUri,
      required this.durationMs,
      required this.editJson,
      this.composeJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sourceUri != null) {
      map['source_uri'] = Variable<String>(sourceUri);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['edit_json'] = Variable<String>(editJson);
    if (!nullToAbsent || composeJson != null) {
      map['compose_json'] = Variable<String>(composeJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AudioProjectsCompanion toCompanion(bool nullToAbsent) {
    return AudioProjectsCompanion(
      id: Value(id),
      name: Value(name),
      sourceUri: sourceUri == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUri),
      durationMs: Value(durationMs),
      editJson: Value(editJson),
      composeJson: composeJson == null && nullToAbsent
          ? const Value.absent()
          : Value(composeJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AudioProject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioProject(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceUri: serializer.fromJson<String?>(json['sourceUri']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      editJson: serializer.fromJson<String>(json['editJson']),
      composeJson: serializer.fromJson<String?>(json['composeJson']),
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
      'sourceUri': serializer.toJson<String?>(sourceUri),
      'durationMs': serializer.toJson<int>(durationMs),
      'editJson': serializer.toJson<String>(editJson),
      'composeJson': serializer.toJson<String?>(composeJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AudioProject copyWith(
          {String? id,
          String? name,
          Value<String?> sourceUri = const Value.absent(),
          int? durationMs,
          String? editJson,
          Value<String?> composeJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      AudioProject(
        id: id ?? this.id,
        name: name ?? this.name,
        sourceUri: sourceUri.present ? sourceUri.value : this.sourceUri,
        durationMs: durationMs ?? this.durationMs,
        editJson: editJson ?? this.editJson,
        composeJson: composeJson.present ? composeJson.value : this.composeJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AudioProject copyWithCompanion(AudioProjectsCompanion data) {
    return AudioProject(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      editJson: data.editJson.present ? data.editJson.value : this.editJson,
      composeJson:
          data.composeJson.present ? data.composeJson.value : this.composeJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioProject(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('durationMs: $durationMs, ')
          ..write('editJson: $editJson, ')
          ..write('composeJson: $composeJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sourceUri, durationMs, editJson,
      composeJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioProject &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceUri == this.sourceUri &&
          other.durationMs == this.durationMs &&
          other.editJson == this.editJson &&
          other.composeJson == this.composeJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AudioProjectsCompanion extends UpdateCompanion<AudioProject> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> sourceUri;
  final Value<int> durationMs;
  final Value<String> editJson;
  final Value<String?> composeJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AudioProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.editJson = const Value.absent(),
    this.composeJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioProjectsCompanion.insert({
    required String id,
    required String name,
    this.sourceUri = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.editJson = const Value.absent(),
    this.composeJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AudioProject> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceUri,
    Expression<int>? durationMs,
    Expression<String>? editJson,
    Expression<String>? composeJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (durationMs != null) 'duration_ms': durationMs,
      if (editJson != null) 'edit_json': editJson,
      if (composeJson != null) 'compose_json': composeJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioProjectsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? sourceUri,
      Value<int>? durationMs,
      Value<String>? editJson,
      Value<String?>? composeJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AudioProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUri: sourceUri ?? this.sourceUri,
      durationMs: durationMs ?? this.durationMs,
      editJson: editJson ?? this.editJson,
      composeJson: composeJson ?? this.composeJson,
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
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (editJson.present) {
      map['edit_json'] = Variable<String>(editJson.value);
    }
    if (composeJson.present) {
      map['compose_json'] = Variable<String>(composeJson.value);
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
    return (StringBuffer('AudioProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('durationMs: $durationMs, ')
          ..write('editJson: $editJson, ')
          ..write('composeJson: $composeJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $PhotoProjectsTable photoProjects = $PhotoProjectsTable(this);
  late final $VoiceOversTable voiceOvers = $VoiceOversTable(this);
  late final $AudioProjectsTable audioProjects = $AudioProjectsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        projects,
        clips,
        audioTracks,
        textOverlays,
        photoProjects,
        voiceOvers,
        audioProjects
      ];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<double> aspectRatio,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> duckMusic,
  Value<String> mode,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<double> aspectRatio,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> duckMusic,
  Value<String> mode,
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

  static MultiTypedResultKey<$VoiceOversTable, List<VoiceOver>>
      _voiceOversRefsTable(_$ProjectDatabase db) =>
          MultiTypedResultKey.fromTable(db.voiceOvers,
              aliasName: 'projects__id__voice_overs__project_id');

  $$VoiceOversTableProcessedTableManager get voiceOversRefs {
    final manager = $$VoiceOversTableTableManager($_db, $_db.voiceOvers)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_voiceOversRefsTable($_db));
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

  ColumnFilters<bool> get duckMusic => $composableBuilder(
      column: $table.duckMusic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

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

  Expression<bool> voiceOversRefs(
      Expression<bool> Function($$VoiceOversTableFilterComposer f) f) {
    final $$VoiceOversTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.voiceOvers,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VoiceOversTableFilterComposer(
              $db: $db,
              $table: $db.voiceOvers,
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

  ColumnOrderings<bool> get duckMusic => $composableBuilder(
      column: $table.duckMusic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<bool> get duckMusic =>
      $composableBuilder(column: $table.duckMusic, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

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

  Expression<T> voiceOversRefs<T extends Object>(
      Expression<T> Function($$VoiceOversTableAnnotationComposer a) f) {
    final $$VoiceOversTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.voiceOvers,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VoiceOversTableAnnotationComposer(
              $db: $db,
              $table: $db.voiceOvers,
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
        {bool clipsRefs,
        bool audioTracksRefs,
        bool textOverlaysRefs,
        bool voiceOversRefs})> {
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
            Value<bool> duckMusic = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            name: name,
            aspectRatio: aspectRatio,
            createdAt: createdAt,
            updatedAt: updatedAt,
            duckMusic: duckMusic,
            mode: mode,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<double> aspectRatio = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<bool> duckMusic = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProjectsCompanion.insert(
            id: id,
            name: name,
            aspectRatio: aspectRatio,
            createdAt: createdAt,
            updatedAt: updatedAt,
            duckMusic: duckMusic,
            mode: mode,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {clipsRefs = false,
              audioTracksRefs = false,
              textOverlaysRefs = false,
              voiceOversRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (clipsRefs) db.clips,
                if (audioTracksRefs) db.audioTracks,
                if (textOverlaysRefs) db.textOverlays,
                if (voiceOversRefs) db.voiceOvers
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
                        typedResults: items),
                  if (voiceOversRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            VoiceOver>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._voiceOversRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .voiceOversRefs,
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
        {bool clipsRefs,
        bool audioTracksRefs,
        bool textOverlaysRefs,
        bool voiceOversRefs})>;
typedef $$ClipsTableCreateCompanionBuilder = ClipsCompanion Function({
  required String id,
  required String projectId,
  required String sourceUri,
  required int orderIndex,
  Value<int> trimStartMs,
  required int trimEndMs,
  required int durationMs,
  Value<int> rotationDegrees,
  Value<String?> thumbnailUri,
  Value<String> transitionOut,
  Value<double> brightness,
  Value<double> contrast,
  Value<double> saturation,
  Value<String?> filterPreset,
  Value<bool> muted,
  Value<double> volume,
  Value<String?> look,
  Value<int> turns,
  Value<bool> flipH,
  Value<bool> flipV,
  Value<double> speed,
  Value<String> fitMode,
  Value<double> lookStrength,
  Value<String?> effect,
  Value<double> effectStrength,
  Value<bool> enhanceSpeech,
  Value<String?> keyJson,
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
  Value<int> rotationDegrees,
  Value<String?> thumbnailUri,
  Value<String> transitionOut,
  Value<double> brightness,
  Value<double> contrast,
  Value<double> saturation,
  Value<String?> filterPreset,
  Value<bool> muted,
  Value<double> volume,
  Value<String?> look,
  Value<int> turns,
  Value<bool> flipH,
  Value<bool> flipV,
  Value<double> speed,
  Value<String> fitMode,
  Value<double> lookStrength,
  Value<String?> effect,
  Value<double> effectStrength,
  Value<bool> enhanceSpeech,
  Value<String?> keyJson,
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

  ColumnFilters<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailUri => $composableBuilder(
      column: $table.thumbnailUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get contrast => $composableBuilder(
      column: $table.contrast, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filterPreset => $composableBuilder(
      column: $table.filterPreset, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get look => $composableBuilder(
      column: $table.look, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get turns => $composableBuilder(
      column: $table.turns, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get flipH => $composableBuilder(
      column: $table.flipH, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get flipV => $composableBuilder(
      column: $table.flipV, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fitMode => $composableBuilder(
      column: $table.fitMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lookStrength => $composableBuilder(
      column: $table.lookStrength, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effect => $composableBuilder(
      column: $table.effect, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get effectStrength => $composableBuilder(
      column: $table.effectStrength,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enhanceSpeech => $composableBuilder(
      column: $table.enhanceSpeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyJson => $composableBuilder(
      column: $table.keyJson, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailUri => $composableBuilder(
      column: $table.thumbnailUri,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get contrast => $composableBuilder(
      column: $table.contrast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filterPreset => $composableBuilder(
      column: $table.filterPreset,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get muted => $composableBuilder(
      column: $table.muted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get look => $composableBuilder(
      column: $table.look, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get turns => $composableBuilder(
      column: $table.turns, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get flipH => $composableBuilder(
      column: $table.flipH, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get flipV => $composableBuilder(
      column: $table.flipV, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speed => $composableBuilder(
      column: $table.speed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fitMode => $composableBuilder(
      column: $table.fitMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lookStrength => $composableBuilder(
      column: $table.lookStrength,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effect => $composableBuilder(
      column: $table.effect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get effectStrength => $composableBuilder(
      column: $table.effectStrength,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enhanceSpeech => $composableBuilder(
      column: $table.enhanceSpeech,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyJson => $composableBuilder(
      column: $table.keyJson, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUri => $composableBuilder(
      column: $table.thumbnailUri, builder: (column) => column);

  GeneratedColumn<String> get transitionOut => $composableBuilder(
      column: $table.transitionOut, builder: (column) => column);

  GeneratedColumn<double> get brightness => $composableBuilder(
      column: $table.brightness, builder: (column) => column);

  GeneratedColumn<double> get contrast =>
      $composableBuilder(column: $table.contrast, builder: (column) => column);

  GeneratedColumn<double> get saturation => $composableBuilder(
      column: $table.saturation, builder: (column) => column);

  GeneratedColumn<String> get filterPreset => $composableBuilder(
      column: $table.filterPreset, builder: (column) => column);

  GeneratedColumn<bool> get muted =>
      $composableBuilder(column: $table.muted, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<String> get look =>
      $composableBuilder(column: $table.look, builder: (column) => column);

  GeneratedColumn<int> get turns =>
      $composableBuilder(column: $table.turns, builder: (column) => column);

  GeneratedColumn<bool> get flipH =>
      $composableBuilder(column: $table.flipH, builder: (column) => column);

  GeneratedColumn<bool> get flipV =>
      $composableBuilder(column: $table.flipV, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get fitMode =>
      $composableBuilder(column: $table.fitMode, builder: (column) => column);

  GeneratedColumn<double> get lookStrength => $composableBuilder(
      column: $table.lookStrength, builder: (column) => column);

  GeneratedColumn<String> get effect =>
      $composableBuilder(column: $table.effect, builder: (column) => column);

  GeneratedColumn<double> get effectStrength => $composableBuilder(
      column: $table.effectStrength, builder: (column) => column);

  GeneratedColumn<bool> get enhanceSpeech => $composableBuilder(
      column: $table.enhanceSpeech, builder: (column) => column);

  GeneratedColumn<String> get keyJson =>
      $composableBuilder(column: $table.keyJson, builder: (column) => column);

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
            Value<int> rotationDegrees = const Value.absent(),
            Value<String?> thumbnailUri = const Value.absent(),
            Value<String> transitionOut = const Value.absent(),
            Value<double> brightness = const Value.absent(),
            Value<double> contrast = const Value.absent(),
            Value<double> saturation = const Value.absent(),
            Value<String?> filterPreset = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<String?> look = const Value.absent(),
            Value<int> turns = const Value.absent(),
            Value<bool> flipH = const Value.absent(),
            Value<bool> flipV = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<String> fitMode = const Value.absent(),
            Value<double> lookStrength = const Value.absent(),
            Value<String?> effect = const Value.absent(),
            Value<double> effectStrength = const Value.absent(),
            Value<bool> enhanceSpeech = const Value.absent(),
            Value<String?> keyJson = const Value.absent(),
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
            rotationDegrees: rotationDegrees,
            thumbnailUri: thumbnailUri,
            transitionOut: transitionOut,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            filterPreset: filterPreset,
            muted: muted,
            volume: volume,
            look: look,
            turns: turns,
            flipH: flipH,
            flipV: flipV,
            speed: speed,
            fitMode: fitMode,
            lookStrength: lookStrength,
            effect: effect,
            effectStrength: effectStrength,
            enhanceSpeech: enhanceSpeech,
            keyJson: keyJson,
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
            Value<int> rotationDegrees = const Value.absent(),
            Value<String?> thumbnailUri = const Value.absent(),
            Value<String> transitionOut = const Value.absent(),
            Value<double> brightness = const Value.absent(),
            Value<double> contrast = const Value.absent(),
            Value<double> saturation = const Value.absent(),
            Value<String?> filterPreset = const Value.absent(),
            Value<bool> muted = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<String?> look = const Value.absent(),
            Value<int> turns = const Value.absent(),
            Value<bool> flipH = const Value.absent(),
            Value<bool> flipV = const Value.absent(),
            Value<double> speed = const Value.absent(),
            Value<String> fitMode = const Value.absent(),
            Value<double> lookStrength = const Value.absent(),
            Value<String?> effect = const Value.absent(),
            Value<double> effectStrength = const Value.absent(),
            Value<bool> enhanceSpeech = const Value.absent(),
            Value<String?> keyJson = const Value.absent(),
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
            rotationDegrees: rotationDegrees,
            thumbnailUri: thumbnailUri,
            transitionOut: transitionOut,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            filterPreset: filterPreset,
            muted: muted,
            volume: volume,
            look: look,
            turns: turns,
            flipH: flipH,
            flipV: flipV,
            speed: speed,
            fitMode: fitMode,
            lookStrength: lookStrength,
            effect: effect,
            effectStrength: effectStrength,
            enhanceSpeech: enhanceSpeech,
            keyJson: keyJson,
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
  Value<int> durationMs,
  Value<int> trimStartMs,
  required int trimEndMs,
  Value<int> offsetMs,
  Value<double> volume,
  Value<int> fadeInMs,
  Value<int> fadeOutMs,
  Value<int> rowid,
});
typedef $$AudioTracksTableUpdateCompanionBuilder = AudioTracksCompanion
    Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> sourceUri,
  Value<int> durationMs,
  Value<int> trimStartMs,
  Value<int> trimEndMs,
  Value<int> offsetMs,
  Value<double> volume,
  Value<int> fadeInMs,
  Value<int> fadeOutMs,
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

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get offsetMs => $composableBuilder(
      column: $table.offsetMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fadeInMs => $composableBuilder(
      column: $table.fadeInMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fadeOutMs => $composableBuilder(
      column: $table.fadeOutMs, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trimEndMs => $composableBuilder(
      column: $table.trimEndMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get offsetMs => $composableBuilder(
      column: $table.offsetMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fadeInMs => $composableBuilder(
      column: $table.fadeInMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fadeOutMs => $composableBuilder(
      column: $table.fadeOutMs, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get trimStartMs => $composableBuilder(
      column: $table.trimStartMs, builder: (column) => column);

  GeneratedColumn<int> get trimEndMs =>
      $composableBuilder(column: $table.trimEndMs, builder: (column) => column);

  GeneratedColumn<int> get offsetMs =>
      $composableBuilder(column: $table.offsetMs, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<int> get fadeInMs =>
      $composableBuilder(column: $table.fadeInMs, builder: (column) => column);

  GeneratedColumn<int> get fadeOutMs =>
      $composableBuilder(column: $table.fadeOutMs, builder: (column) => column);

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
            Value<int> durationMs = const Value.absent(),
            Value<int> trimStartMs = const Value.absent(),
            Value<int> trimEndMs = const Value.absent(),
            Value<int> offsetMs = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> fadeInMs = const Value.absent(),
            Value<int> fadeOutMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioTracksCompanion(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            durationMs: durationMs,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            offsetMs: offsetMs,
            volume: volume,
            fadeInMs: fadeInMs,
            fadeOutMs: fadeOutMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String sourceUri,
            Value<int> durationMs = const Value.absent(),
            Value<int> trimStartMs = const Value.absent(),
            required int trimEndMs,
            Value<int> offsetMs = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<int> fadeInMs = const Value.absent(),
            Value<int> fadeOutMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioTracksCompanion.insert(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            durationMs: durationMs,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            offsetMs: offsetMs,
            volume: volume,
            fadeInMs: fadeInMs,
            fadeOutMs: fadeOutMs,
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
  Value<int> alignment,
  Value<bool> bold,
  Value<bool> boxEnabled,
  Value<int> boxColorValue,
  Value<double> outlineWidth,
  Value<int> outlineColorValue,
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
  Value<int> alignment,
  Value<bool> bold,
  Value<bool> boxEnabled,
  Value<int> boxColorValue,
  Value<double> outlineWidth,
  Value<int> outlineColorValue,
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

  ColumnFilters<int> get alignment => $composableBuilder(
      column: $table.alignment, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get bold => $composableBuilder(
      column: $table.bold, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get boxEnabled => $composableBuilder(
      column: $table.boxEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get boxColorValue => $composableBuilder(
      column: $table.boxColorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get outlineWidth => $composableBuilder(
      column: $table.outlineWidth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get outlineColorValue => $composableBuilder(
      column: $table.outlineColorValue,
      builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get alignment => $composableBuilder(
      column: $table.alignment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get bold => $composableBuilder(
      column: $table.bold, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get boxEnabled => $composableBuilder(
      column: $table.boxEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get boxColorValue => $composableBuilder(
      column: $table.boxColorValue,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get outlineWidth => $composableBuilder(
      column: $table.outlineWidth,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get outlineColorValue => $composableBuilder(
      column: $table.outlineColorValue,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get alignment =>
      $composableBuilder(column: $table.alignment, builder: (column) => column);

  GeneratedColumn<bool> get bold =>
      $composableBuilder(column: $table.bold, builder: (column) => column);

  GeneratedColumn<bool> get boxEnabled => $composableBuilder(
      column: $table.boxEnabled, builder: (column) => column);

  GeneratedColumn<int> get boxColorValue => $composableBuilder(
      column: $table.boxColorValue, builder: (column) => column);

  GeneratedColumn<double> get outlineWidth => $composableBuilder(
      column: $table.outlineWidth, builder: (column) => column);

  GeneratedColumn<int> get outlineColorValue => $composableBuilder(
      column: $table.outlineColorValue, builder: (column) => column);

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
            Value<int> alignment = const Value.absent(),
            Value<bool> bold = const Value.absent(),
            Value<bool> boxEnabled = const Value.absent(),
            Value<int> boxColorValue = const Value.absent(),
            Value<double> outlineWidth = const Value.absent(),
            Value<int> outlineColorValue = const Value.absent(),
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
            alignment: alignment,
            bold: bold,
            boxEnabled: boxEnabled,
            boxColorValue: boxColorValue,
            outlineWidth: outlineWidth,
            outlineColorValue: outlineColorValue,
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
            Value<int> alignment = const Value.absent(),
            Value<bool> bold = const Value.absent(),
            Value<bool> boxEnabled = const Value.absent(),
            Value<int> boxColorValue = const Value.absent(),
            Value<double> outlineWidth = const Value.absent(),
            Value<int> outlineColorValue = const Value.absent(),
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
            alignment: alignment,
            bold: bold,
            boxEnabled: boxEnabled,
            boxColorValue: boxColorValue,
            outlineWidth: outlineWidth,
            outlineColorValue: outlineColorValue,
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
typedef $$PhotoProjectsTableCreateCompanionBuilder = PhotoProjectsCompanion
    Function({
  required String id,
  required String name,
  required String sourceUri,
  Value<int> width,
  Value<int> height,
  Value<String> editJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PhotoProjectsTableUpdateCompanionBuilder = PhotoProjectsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> sourceUri,
  Value<int> width,
  Value<int> height,
  Value<String> editJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PhotoProjectsTableFilterComposer
    extends Composer<_$ProjectDatabase, $PhotoProjectsTable> {
  $$PhotoProjectsTableFilterComposer({
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

  ColumnFilters<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get editJson => $composableBuilder(
      column: $table.editJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PhotoProjectsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $PhotoProjectsTable> {
  $$PhotoProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get editJson => $composableBuilder(
      column: $table.editJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PhotoProjectsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $PhotoProjectsTable> {
  $$PhotoProjectsTableAnnotationComposer({
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

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get editJson =>
      $composableBuilder(column: $table.editJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PhotoProjectsTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $PhotoProjectsTable,
    PhotoProject,
    $$PhotoProjectsTableFilterComposer,
    $$PhotoProjectsTableOrderingComposer,
    $$PhotoProjectsTableAnnotationComposer,
    $$PhotoProjectsTableCreateCompanionBuilder,
    $$PhotoProjectsTableUpdateCompanionBuilder,
    (
      PhotoProject,
      BaseReferences<_$ProjectDatabase, $PhotoProjectsTable, PhotoProject>
    ),
    PhotoProject,
    PrefetchHooks Function()> {
  $$PhotoProjectsTableTableManager(
      _$ProjectDatabase db, $PhotoProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> sourceUri = const Value.absent(),
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<String> editJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoProjectsCompanion(
            id: id,
            name: name,
            sourceUri: sourceUri,
            width: width,
            height: height,
            editJson: editJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String sourceUri,
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<String> editJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoProjectsCompanion.insert(
            id: id,
            name: name,
            sourceUri: sourceUri,
            width: width,
            height: height,
            editJson: editJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PhotoProjectsTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $PhotoProjectsTable,
    PhotoProject,
    $$PhotoProjectsTableFilterComposer,
    $$PhotoProjectsTableOrderingComposer,
    $$PhotoProjectsTableAnnotationComposer,
    $$PhotoProjectsTableCreateCompanionBuilder,
    $$PhotoProjectsTableUpdateCompanionBuilder,
    (
      PhotoProject,
      BaseReferences<_$ProjectDatabase, $PhotoProjectsTable, PhotoProject>
    ),
    PhotoProject,
    PrefetchHooks Function()>;
typedef $$VoiceOversTableCreateCompanionBuilder = VoiceOversCompanion Function({
  required String id,
  required String projectId,
  required String sourceUri,
  required int startMs,
  required int durationMs,
  Value<double> volume,
  Value<bool> enhance,
  Value<int> rowid,
});
typedef $$VoiceOversTableUpdateCompanionBuilder = VoiceOversCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> sourceUri,
  Value<int> startMs,
  Value<int> durationMs,
  Value<double> volume,
  Value<bool> enhance,
  Value<int> rowid,
});

final class $$VoiceOversTableReferences
    extends BaseReferences<_$ProjectDatabase, $VoiceOversTable, VoiceOver> {
  $$VoiceOversTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$ProjectDatabase db) =>
      db.projects.createAlias('voice_overs__project_id__projects__id');

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

class $$VoiceOversTableFilterComposer
    extends Composer<_$ProjectDatabase, $VoiceOversTable> {
  $$VoiceOversTableFilterComposer({
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

  ColumnFilters<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enhance => $composableBuilder(
      column: $table.enhance, builder: (column) => ColumnFilters(column));

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

class $$VoiceOversTableOrderingComposer
    extends Composer<_$ProjectDatabase, $VoiceOversTable> {
  $$VoiceOversTableOrderingComposer({
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

  ColumnOrderings<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get volume => $composableBuilder(
      column: $table.volume, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enhance => $composableBuilder(
      column: $table.enhance, builder: (column) => ColumnOrderings(column));

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

class $$VoiceOversTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $VoiceOversTable> {
  $$VoiceOversTableAnnotationComposer({
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

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<double> get volume =>
      $composableBuilder(column: $table.volume, builder: (column) => column);

  GeneratedColumn<bool> get enhance =>
      $composableBuilder(column: $table.enhance, builder: (column) => column);

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

class $$VoiceOversTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $VoiceOversTable,
    VoiceOver,
    $$VoiceOversTableFilterComposer,
    $$VoiceOversTableOrderingComposer,
    $$VoiceOversTableAnnotationComposer,
    $$VoiceOversTableCreateCompanionBuilder,
    $$VoiceOversTableUpdateCompanionBuilder,
    (VoiceOver, $$VoiceOversTableReferences),
    VoiceOver,
    PrefetchHooks Function({bool projectId})> {
  $$VoiceOversTableTableManager(_$ProjectDatabase db, $VoiceOversTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceOversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceOversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceOversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> projectId = const Value.absent(),
            Value<String> sourceUri = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<double> volume = const Value.absent(),
            Value<bool> enhance = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceOversCompanion(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            startMs: startMs,
            durationMs: durationMs,
            volume: volume,
            enhance: enhance,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String projectId,
            required String sourceUri,
            required int startMs,
            required int durationMs,
            Value<double> volume = const Value.absent(),
            Value<bool> enhance = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceOversCompanion.insert(
            id: id,
            projectId: projectId,
            sourceUri: sourceUri,
            startMs: startMs,
            durationMs: durationMs,
            volume: volume,
            enhance: enhance,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$VoiceOversTableReferences(db, table, e)
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
                        $$VoiceOversTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$VoiceOversTableReferences._projectIdTable(db).id,
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

typedef $$VoiceOversTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $VoiceOversTable,
    VoiceOver,
    $$VoiceOversTableFilterComposer,
    $$VoiceOversTableOrderingComposer,
    $$VoiceOversTableAnnotationComposer,
    $$VoiceOversTableCreateCompanionBuilder,
    $$VoiceOversTableUpdateCompanionBuilder,
    (VoiceOver, $$VoiceOversTableReferences),
    VoiceOver,
    PrefetchHooks Function({bool projectId})>;
typedef $$AudioProjectsTableCreateCompanionBuilder = AudioProjectsCompanion
    Function({
  required String id,
  required String name,
  Value<String?> sourceUri,
  Value<int> durationMs,
  Value<String> editJson,
  Value<String?> composeJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AudioProjectsTableUpdateCompanionBuilder = AudioProjectsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> sourceUri,
  Value<int> durationMs,
  Value<String> editJson,
  Value<String?> composeJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AudioProjectsTableFilterComposer
    extends Composer<_$ProjectDatabase, $AudioProjectsTable> {
  $$AudioProjectsTableFilterComposer({
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

  ColumnFilters<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get editJson => $composableBuilder(
      column: $table.editJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get composeJson => $composableBuilder(
      column: $table.composeJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AudioProjectsTableOrderingComposer
    extends Composer<_$ProjectDatabase, $AudioProjectsTable> {
  $$AudioProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get sourceUri => $composableBuilder(
      column: $table.sourceUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get editJson => $composableBuilder(
      column: $table.editJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get composeJson => $composableBuilder(
      column: $table.composeJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AudioProjectsTableAnnotationComposer
    extends Composer<_$ProjectDatabase, $AudioProjectsTable> {
  $$AudioProjectsTableAnnotationComposer({
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

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get editJson =>
      $composableBuilder(column: $table.editJson, builder: (column) => column);

  GeneratedColumn<String> get composeJson => $composableBuilder(
      column: $table.composeJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AudioProjectsTableTableManager extends RootTableManager<
    _$ProjectDatabase,
    $AudioProjectsTable,
    AudioProject,
    $$AudioProjectsTableFilterComposer,
    $$AudioProjectsTableOrderingComposer,
    $$AudioProjectsTableAnnotationComposer,
    $$AudioProjectsTableCreateCompanionBuilder,
    $$AudioProjectsTableUpdateCompanionBuilder,
    (
      AudioProject,
      BaseReferences<_$ProjectDatabase, $AudioProjectsTable, AudioProject>
    ),
    AudioProject,
    PrefetchHooks Function()> {
  $$AudioProjectsTableTableManager(
      _$ProjectDatabase db, $AudioProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AudioProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AudioProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AudioProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> sourceUri = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> editJson = const Value.absent(),
            Value<String?> composeJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioProjectsCompanion(
            id: id,
            name: name,
            sourceUri: sourceUri,
            durationMs: durationMs,
            editJson: editJson,
            composeJson: composeJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> sourceUri = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> editJson = const Value.absent(),
            Value<String?> composeJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AudioProjectsCompanion.insert(
            id: id,
            name: name,
            sourceUri: sourceUri,
            durationMs: durationMs,
            editJson: editJson,
            composeJson: composeJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AudioProjectsTableProcessedTableManager = ProcessedTableManager<
    _$ProjectDatabase,
    $AudioProjectsTable,
    AudioProject,
    $$AudioProjectsTableFilterComposer,
    $$AudioProjectsTableOrderingComposer,
    $$AudioProjectsTableAnnotationComposer,
    $$AudioProjectsTableCreateCompanionBuilder,
    $$AudioProjectsTableUpdateCompanionBuilder,
    (
      AudioProject,
      BaseReferences<_$ProjectDatabase, $AudioProjectsTable, AudioProject>
    ),
    AudioProject,
    PrefetchHooks Function()>;

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
  $$PhotoProjectsTableTableManager get photoProjects =>
      $$PhotoProjectsTableTableManager(_db, _db.photoProjects);
  $$VoiceOversTableTableManager get voiceOvers =>
      $$VoiceOversTableTableManager(_db, _db.voiceOvers);
  $$AudioProjectsTableTableManager get audioProjects =>
      $$AudioProjectsTableTableManager(_db, _db.audioProjects);
}
