// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_v3_database.dart';

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
        volume
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
      required this.volume});
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
          double? volume}) =>
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
          ..write('volume: $volume')
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
      rotationDegrees,
      thumbnailUri,
      transitionOut,
      brightness,
      contrast,
      saturation,
      filterPreset,
      muted,
      volume);
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
          other.volume == this.volume);
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
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        sourceUri,
        durationMs,
        trimStartMs,
        trimEndMs,
        offsetMs,
        volume
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
  const AudioTrack(
      {required this.id,
      required this.projectId,
      required this.sourceUri,
      required this.durationMs,
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
    map['duration_ms'] = Variable<int>(durationMs);
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
      durationMs: Value(durationMs),
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
      durationMs: serializer.fromJson<int>(json['durationMs']),
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
      'durationMs': serializer.toJson<int>(durationMs),
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
          int? durationMs,
          int? trimStartMs,
          int? trimEndMs,
          int? offsetMs,
          double? volume}) =>
      AudioTrack(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        sourceUri: sourceUri ?? this.sourceUri,
        durationMs: durationMs ?? this.durationMs,
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
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
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
          ..write('durationMs: $durationMs, ')
          ..write('trimStartMs: $trimStartMs, ')
          ..write('trimEndMs: $trimEndMs, ')
          ..write('offsetMs: $offsetMs, ')
          ..write('volume: $volume')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, projectId, sourceUri, durationMs,
      trimStartMs, trimEndMs, offsetMs, volume);
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
          other.volume == this.volume);
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LegacyV3Database extends GeneratedDatabase {
  _$LegacyV3Database(QueryExecutor e) : super(e);
  $LegacyV3DatabaseManager get managers => $LegacyV3DatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $ClipsTable clips = $ClipsTable(this);
  late final $AudioTracksTable audioTracks = $AudioTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [projects, clips, audioTracks];
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
    extends BaseReferences<_$LegacyV3Database, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ClipsTable, List<Clip>> _clipsRefsTable(
          _$LegacyV3Database db) =>
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
      _audioTracksRefsTable(_$LegacyV3Database db) =>
          MultiTypedResultKey.fromTable(db.audioTracks,
              aliasName: 'projects__id__audio_tracks__project_id');

  $$AudioTracksTableProcessedTableManager get audioTracksRefs {
    final manager = $$AudioTracksTableTableManager($_db, $_db.audioTracks)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_audioTracksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$LegacyV3Database, $ProjectsTable> {
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
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$LegacyV3Database, $ProjectsTable> {
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
    extends Composer<_$LegacyV3Database, $ProjectsTable> {
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
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$LegacyV3Database,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool clipsRefs, bool audioTracksRefs})> {
  $$ProjectsTableTableManager(_$LegacyV3Database db, $ProjectsTable table)
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
              {clipsRefs = false, audioTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (clipsRefs) db.clips,
                if (audioTracksRefs) db.audioTracks
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
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$LegacyV3Database,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool clipsRefs, bool audioTracksRefs})>;
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
  Value<int> rowid,
});

final class $$ClipsTableReferences
    extends BaseReferences<_$LegacyV3Database, $ClipsTable, Clip> {
  $$ClipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$LegacyV3Database db) =>
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
    extends Composer<_$LegacyV3Database, $ClipsTable> {
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
    extends Composer<_$LegacyV3Database, $ClipsTable> {
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
    extends Composer<_$LegacyV3Database, $ClipsTable> {
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
    _$LegacyV3Database,
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
  $$ClipsTableTableManager(_$LegacyV3Database db, $ClipsTable table)
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
    _$LegacyV3Database,
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
  Value<int> rowid,
});

final class $$AudioTracksTableReferences
    extends BaseReferences<_$LegacyV3Database, $AudioTracksTable, AudioTrack> {
  $$AudioTracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$LegacyV3Database db) =>
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
    extends Composer<_$LegacyV3Database, $AudioTracksTable> {
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
    extends Composer<_$LegacyV3Database, $AudioTracksTable> {
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
    extends Composer<_$LegacyV3Database, $AudioTracksTable> {
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
    _$LegacyV3Database,
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
  $$AudioTracksTableTableManager(_$LegacyV3Database db, $AudioTracksTable table)
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
    _$LegacyV3Database,
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

class $LegacyV3DatabaseManager {
  final _$LegacyV3Database _db;
  $LegacyV3DatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$ClipsTableTableManager get clips =>
      $$ClipsTableTableManager(_db, _db.clips);
  $$AudioTracksTableTableManager get audioTracks =>
      $$AudioTracksTableTableManager(_db, _db.audioTracks);
}
