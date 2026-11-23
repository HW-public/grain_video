// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WatchHistoriesTable extends WatchHistories
    with TableInfo<$WatchHistoriesTable, WatchHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bangumiUrlMeta = const VerificationMeta(
    'bangumiUrl',
  );
  @override
  late final GeneratedColumn<String> bangumiUrl = GeneratedColumn<String>(
    'bangumi_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _episodeUrlMeta = const VerificationMeta(
    'episodeUrl',
  );
  @override
  late final GeneratedColumn<String> episodeUrl = GeneratedColumn<String>(
    'episode_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePackage,
    bangumiUrl,
    title,
    cover,
    episodeUrl,
    episodeTitle,
    positionMs,
    durationMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePackageMeta);
    }
    if (data.containsKey('bangumi_url')) {
      context.handle(
        _bangumiUrlMeta,
        bangumiUrl.isAcceptableOrUnknown(data['bangumi_url']!, _bangumiUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bangumiUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('episode_url')) {
      context.handle(
        _episodeUrlMeta,
        episodeUrl.isAcceptableOrUnknown(data['episode_url']!, _episodeUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeUrlMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourcePackage, episodeUrl},
  ];
  @override
  WatchHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      )!,
      bangumiUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bangumi_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      )!,
      episodeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_url'],
      )!,
      episodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_title'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WatchHistoriesTable createAlias(String alias) {
    return $WatchHistoriesTable(attachedDatabase, alias);
  }
}

class WatchHistory extends DataClass implements Insertable<WatchHistory> {
  final int id;

  /// 插件包名（PluginInfo.package），跨插件区分条目。
  final String sourcePackage;
  final String bangumiUrl;
  final String title;
  final String cover;
  final String episodeUrl;
  final String episodeTitle;

  /// 播放进度（毫秒）。
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;
  const WatchHistory({
    required this.id,
    required this.sourcePackage,
    required this.bangumiUrl,
    required this.title,
    required this.cover,
    required this.episodeUrl,
    required this.episodeTitle,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_package'] = Variable<String>(sourcePackage);
    map['bangumi_url'] = Variable<String>(bangumiUrl);
    map['title'] = Variable<String>(title);
    map['cover'] = Variable<String>(cover);
    map['episode_url'] = Variable<String>(episodeUrl);
    map['episode_title'] = Variable<String>(episodeTitle);
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WatchHistoriesCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoriesCompanion(
      id: Value(id),
      sourcePackage: Value(sourcePackage),
      bangumiUrl: Value(bangumiUrl),
      title: Value(title),
      cover: Value(cover),
      episodeUrl: Value(episodeUrl),
      episodeTitle: Value(episodeTitle),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistory(
      id: serializer.fromJson<int>(json['id']),
      sourcePackage: serializer.fromJson<String>(json['sourcePackage']),
      bangumiUrl: serializer.fromJson<String>(json['bangumiUrl']),
      title: serializer.fromJson<String>(json['title']),
      cover: serializer.fromJson<String>(json['cover']),
      episodeUrl: serializer.fromJson<String>(json['episodeUrl']),
      episodeTitle: serializer.fromJson<String>(json['episodeTitle']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePackage': serializer.toJson<String>(sourcePackage),
      'bangumiUrl': serializer.toJson<String>(bangumiUrl),
      'title': serializer.toJson<String>(title),
      'cover': serializer.toJson<String>(cover),
      'episodeUrl': serializer.toJson<String>(episodeUrl),
      'episodeTitle': serializer.toJson<String>(episodeTitle),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WatchHistory copyWith({
    int? id,
    String? sourcePackage,
    String? bangumiUrl,
    String? title,
    String? cover,
    String? episodeUrl,
    String? episodeTitle,
    int? positionMs,
    int? durationMs,
    DateTime? updatedAt,
  }) => WatchHistory(
    id: id ?? this.id,
    sourcePackage: sourcePackage ?? this.sourcePackage,
    bangumiUrl: bangumiUrl ?? this.bangumiUrl,
    title: title ?? this.title,
    cover: cover ?? this.cover,
    episodeUrl: episodeUrl ?? this.episodeUrl,
    episodeTitle: episodeTitle ?? this.episodeTitle,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WatchHistory copyWithCompanion(WatchHistoriesCompanion data) {
    return WatchHistory(
      id: data.id.present ? data.id.value : this.id,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      bangumiUrl: data.bangumiUrl.present
          ? data.bangumiUrl.value
          : this.bangumiUrl,
      title: data.title.present ? data.title.value : this.title,
      cover: data.cover.present ? data.cover.value : this.cover,
      episodeUrl: data.episodeUrl.present
          ? data.episodeUrl.value
          : this.episodeUrl,
      episodeTitle: data.episodeTitle.present
          ? data.episodeTitle.value
          : this.episodeTitle,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistory(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('episodeUrl: $episodeUrl, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourcePackage,
    bangumiUrl,
    title,
    cover,
    episodeUrl,
    episodeTitle,
    positionMs,
    durationMs,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistory &&
          other.id == this.id &&
          other.sourcePackage == this.sourcePackage &&
          other.bangumiUrl == this.bangumiUrl &&
          other.title == this.title &&
          other.cover == this.cover &&
          other.episodeUrl == this.episodeUrl &&
          other.episodeTitle == this.episodeTitle &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.updatedAt == this.updatedAt);
}

class WatchHistoriesCompanion extends UpdateCompanion<WatchHistory> {
  final Value<int> id;
  final Value<String> sourcePackage;
  final Value<String> bangumiUrl;
  final Value<String> title;
  final Value<String> cover;
  final Value<String> episodeUrl;
  final Value<String> episodeTitle;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<DateTime> updatedAt;
  const WatchHistoriesCompanion({
    this.id = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.bangumiUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.cover = const Value.absent(),
    this.episodeUrl = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WatchHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    this.cover = const Value.absent(),
    required String episodeUrl,
    this.episodeTitle = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    required DateTime updatedAt,
  }) : sourcePackage = Value(sourcePackage),
       bangumiUrl = Value(bangumiUrl),
       title = Value(title),
       episodeUrl = Value(episodeUrl),
       updatedAt = Value(updatedAt);
  static Insertable<WatchHistory> custom({
    Expression<int>? id,
    Expression<String>? sourcePackage,
    Expression<String>? bangumiUrl,
    Expression<String>? title,
    Expression<String>? cover,
    Expression<String>? episodeUrl,
    Expression<String>? episodeTitle,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (bangumiUrl != null) 'bangumi_url': bangumiUrl,
      if (title != null) 'title': title,
      if (cover != null) 'cover': cover,
      if (episodeUrl != null) 'episode_url': episodeUrl,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WatchHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourcePackage,
    Value<String>? bangumiUrl,
    Value<String>? title,
    Value<String>? cover,
    Value<String>? episodeUrl,
    Value<String>? episodeTitle,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<DateTime>? updatedAt,
  }) {
    return WatchHistoriesCompanion(
      id: id ?? this.id,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      bangumiUrl: bangumiUrl ?? this.bangumiUrl,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      episodeUrl: episodeUrl ?? this.episodeUrl,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (bangumiUrl.present) {
      map['bangumi_url'] = Variable<String>(bangumiUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (episodeUrl.present) {
      map['episode_url'] = Variable<String>(episodeUrl.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('episodeUrl: $episodeUrl, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bangumiUrlMeta = const VerificationMeta(
    'bangumiUrl',
  );
  @override
  late final GeneratedColumn<String> bangumiUrl = GeneratedColumn<String>(
    'bangumi_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  List<GeneratedColumn> get $columns => [
    id,
    sourcePackage,
    bangumiUrl,
    title,
    cover,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePackageMeta);
    }
    if (data.containsKey('bangumi_url')) {
      context.handle(
        _bangumiUrlMeta,
        bangumiUrl.isAcceptableOrUnknown(data['bangumi_url']!, _bangumiUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bangumiUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourcePackage, bangumiUrl},
  ];
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      )!,
      bangumiUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bangumi_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final int id;
  final String sourcePackage;
  final String bangumiUrl;
  final String title;
  final String cover;
  final DateTime createdAt;
  const Favorite({
    required this.id,
    required this.sourcePackage,
    required this.bangumiUrl,
    required this.title,
    required this.cover,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_package'] = Variable<String>(sourcePackage);
    map['bangumi_url'] = Variable<String>(bangumiUrl);
    map['title'] = Variable<String>(title);
    map['cover'] = Variable<String>(cover);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      sourcePackage: Value(sourcePackage),
      bangumiUrl: Value(bangumiUrl),
      title: Value(title),
      cover: Value(cover),
      createdAt: Value(createdAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<int>(json['id']),
      sourcePackage: serializer.fromJson<String>(json['sourcePackage']),
      bangumiUrl: serializer.fromJson<String>(json['bangumiUrl']),
      title: serializer.fromJson<String>(json['title']),
      cover: serializer.fromJson<String>(json['cover']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePackage': serializer.toJson<String>(sourcePackage),
      'bangumiUrl': serializer.toJson<String>(bangumiUrl),
      'title': serializer.toJson<String>(title),
      'cover': serializer.toJson<String>(cover),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favorite copyWith({
    int? id,
    String? sourcePackage,
    String? bangumiUrl,
    String? title,
    String? cover,
    DateTime? createdAt,
  }) => Favorite(
    id: id ?? this.id,
    sourcePackage: sourcePackage ?? this.sourcePackage,
    bangumiUrl: bangumiUrl ?? this.bangumiUrl,
    title: title ?? this.title,
    cover: cover ?? this.cover,
    createdAt: createdAt ?? this.createdAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      bangumiUrl: data.bangumiUrl.present
          ? data.bangumiUrl.value
          : this.bangumiUrl,
      title: data.title.present ? data.title.value : this.title,
      cover: data.cover.present ? data.cover.value : this.cover,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourcePackage, bangumiUrl, title, cover, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.sourcePackage == this.sourcePackage &&
          other.bangumiUrl == this.bangumiUrl &&
          other.title == this.title &&
          other.cover == this.cover &&
          other.createdAt == this.createdAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<int> id;
  final Value<String> sourcePackage;
  final Value<String> bangumiUrl;
  final Value<String> title;
  final Value<String> cover;
  final Value<DateTime> createdAt;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.bangumiUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.cover = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    this.cover = const Value.absent(),
    required DateTime createdAt,
  }) : sourcePackage = Value(sourcePackage),
       bangumiUrl = Value(bangumiUrl),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Favorite> custom({
    Expression<int>? id,
    Expression<String>? sourcePackage,
    Expression<String>? bangumiUrl,
    Expression<String>? title,
    Expression<String>? cover,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (bangumiUrl != null) 'bangumi_url': bangumiUrl,
      if (title != null) 'title': title,
      if (cover != null) 'cover': cover,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoritesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourcePackage,
    Value<String>? bangumiUrl,
    Value<String>? title,
    Value<String>? cover,
    Value<DateTime>? createdAt,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      bangumiUrl: bangumiUrl ?? this.bangumiUrl,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (bangumiUrl.present) {
      map['bangumi_url'] = Variable<String>(bangumiUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FollowsTable extends Follows with TableInfo<$FollowsTable, Follow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FollowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sourcePackageMeta = const VerificationMeta(
    'sourcePackage',
  );
  @override
  late final GeneratedColumn<String> sourcePackage = GeneratedColumn<String>(
    'source_package',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bangumiUrlMeta = const VerificationMeta(
    'bangumiUrl',
  );
  @override
  late final GeneratedColumn<String> bangumiUrl = GeneratedColumn<String>(
    'bangumi_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currentEpisodeMeta = const VerificationMeta(
    'currentEpisode',
  );
  @override
  late final GeneratedColumn<int> currentEpisode = GeneratedColumn<int>(
    'current_episode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalEpisodeMeta = const VerificationMeta(
    'totalEpisode',
  );
  @override
  late final GeneratedColumn<int> totalEpisode = GeneratedColumn<int>(
    'total_episode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourcePackage,
    bangumiUrl,
    title,
    cover,
    currentEpisode,
    totalEpisode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'follows';
  @override
  VerificationContext validateIntegrity(
    Insertable<Follow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_package')) {
      context.handle(
        _sourcePackageMeta,
        sourcePackage.isAcceptableOrUnknown(
          data['source_package']!,
          _sourcePackageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePackageMeta);
    }
    if (data.containsKey('bangumi_url')) {
      context.handle(
        _bangumiUrlMeta,
        bangumiUrl.isAcceptableOrUnknown(data['bangumi_url']!, _bangumiUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_bangumiUrlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('current_episode')) {
      context.handle(
        _currentEpisodeMeta,
        currentEpisode.isAcceptableOrUnknown(
          data['current_episode']!,
          _currentEpisodeMeta,
        ),
      );
    }
    if (data.containsKey('total_episode')) {
      context.handle(
        _totalEpisodeMeta,
        totalEpisode.isAcceptableOrUnknown(
          data['total_episode']!,
          _totalEpisodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourcePackage, bangumiUrl},
  ];
  @override
  Follow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Follow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourcePackage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_package'],
      )!,
      bangumiUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bangumi_url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      )!,
      currentEpisode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_episode'],
      )!,
      totalEpisode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episode'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FollowsTable createAlias(String alias) {
    return $FollowsTable(attachedDatabase, alias);
  }
}

class Follow extends DataClass implements Insertable<Follow> {
  final int id;
  final String sourcePackage;
  final String bangumiUrl;
  final String title;
  final String cover;

  /// 当前进度与已知总集数（未知为 0）。
  final int currentEpisode;
  final int totalEpisode;
  final DateTime updatedAt;
  const Follow({
    required this.id,
    required this.sourcePackage,
    required this.bangumiUrl,
    required this.title,
    required this.cover,
    required this.currentEpisode,
    required this.totalEpisode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_package'] = Variable<String>(sourcePackage);
    map['bangumi_url'] = Variable<String>(bangumiUrl);
    map['title'] = Variable<String>(title);
    map['cover'] = Variable<String>(cover);
    map['current_episode'] = Variable<int>(currentEpisode);
    map['total_episode'] = Variable<int>(totalEpisode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FollowsCompanion toCompanion(bool nullToAbsent) {
    return FollowsCompanion(
      id: Value(id),
      sourcePackage: Value(sourcePackage),
      bangumiUrl: Value(bangumiUrl),
      title: Value(title),
      cover: Value(cover),
      currentEpisode: Value(currentEpisode),
      totalEpisode: Value(totalEpisode),
      updatedAt: Value(updatedAt),
    );
  }

  factory Follow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Follow(
      id: serializer.fromJson<int>(json['id']),
      sourcePackage: serializer.fromJson<String>(json['sourcePackage']),
      bangumiUrl: serializer.fromJson<String>(json['bangumiUrl']),
      title: serializer.fromJson<String>(json['title']),
      cover: serializer.fromJson<String>(json['cover']),
      currentEpisode: serializer.fromJson<int>(json['currentEpisode']),
      totalEpisode: serializer.fromJson<int>(json['totalEpisode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourcePackage': serializer.toJson<String>(sourcePackage),
      'bangumiUrl': serializer.toJson<String>(bangumiUrl),
      'title': serializer.toJson<String>(title),
      'cover': serializer.toJson<String>(cover),
      'currentEpisode': serializer.toJson<int>(currentEpisode),
      'totalEpisode': serializer.toJson<int>(totalEpisode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Follow copyWith({
    int? id,
    String? sourcePackage,
    String? bangumiUrl,
    String? title,
    String? cover,
    int? currentEpisode,
    int? totalEpisode,
    DateTime? updatedAt,
  }) => Follow(
    id: id ?? this.id,
    sourcePackage: sourcePackage ?? this.sourcePackage,
    bangumiUrl: bangumiUrl ?? this.bangumiUrl,
    title: title ?? this.title,
    cover: cover ?? this.cover,
    currentEpisode: currentEpisode ?? this.currentEpisode,
    totalEpisode: totalEpisode ?? this.totalEpisode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Follow copyWithCompanion(FollowsCompanion data) {
    return Follow(
      id: data.id.present ? data.id.value : this.id,
      sourcePackage: data.sourcePackage.present
          ? data.sourcePackage.value
          : this.sourcePackage,
      bangumiUrl: data.bangumiUrl.present
          ? data.bangumiUrl.value
          : this.bangumiUrl,
      title: data.title.present ? data.title.value : this.title,
      cover: data.cover.present ? data.cover.value : this.cover,
      currentEpisode: data.currentEpisode.present
          ? data.currentEpisode.value
          : this.currentEpisode,
      totalEpisode: data.totalEpisode.present
          ? data.totalEpisode.value
          : this.totalEpisode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Follow(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('currentEpisode: $currentEpisode, ')
          ..write('totalEpisode: $totalEpisode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourcePackage,
    bangumiUrl,
    title,
    cover,
    currentEpisode,
    totalEpisode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Follow &&
          other.id == this.id &&
          other.sourcePackage == this.sourcePackage &&
          other.bangumiUrl == this.bangumiUrl &&
          other.title == this.title &&
          other.cover == this.cover &&
          other.currentEpisode == this.currentEpisode &&
          other.totalEpisode == this.totalEpisode &&
          other.updatedAt == this.updatedAt);
}

class FollowsCompanion extends UpdateCompanion<Follow> {
  final Value<int> id;
  final Value<String> sourcePackage;
  final Value<String> bangumiUrl;
  final Value<String> title;
  final Value<String> cover;
  final Value<int> currentEpisode;
  final Value<int> totalEpisode;
  final Value<DateTime> updatedAt;
  const FollowsCompanion({
    this.id = const Value.absent(),
    this.sourcePackage = const Value.absent(),
    this.bangumiUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.cover = const Value.absent(),
    this.currentEpisode = const Value.absent(),
    this.totalEpisode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  FollowsCompanion.insert({
    this.id = const Value.absent(),
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    this.cover = const Value.absent(),
    this.currentEpisode = const Value.absent(),
    this.totalEpisode = const Value.absent(),
    required DateTime updatedAt,
  }) : sourcePackage = Value(sourcePackage),
       bangumiUrl = Value(bangumiUrl),
       title = Value(title),
       updatedAt = Value(updatedAt);
  static Insertable<Follow> custom({
    Expression<int>? id,
    Expression<String>? sourcePackage,
    Expression<String>? bangumiUrl,
    Expression<String>? title,
    Expression<String>? cover,
    Expression<int>? currentEpisode,
    Expression<int>? totalEpisode,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourcePackage != null) 'source_package': sourcePackage,
      if (bangumiUrl != null) 'bangumi_url': bangumiUrl,
      if (title != null) 'title': title,
      if (cover != null) 'cover': cover,
      if (currentEpisode != null) 'current_episode': currentEpisode,
      if (totalEpisode != null) 'total_episode': totalEpisode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  FollowsCompanion copyWith({
    Value<int>? id,
    Value<String>? sourcePackage,
    Value<String>? bangumiUrl,
    Value<String>? title,
    Value<String>? cover,
    Value<int>? currentEpisode,
    Value<int>? totalEpisode,
    Value<DateTime>? updatedAt,
  }) {
    return FollowsCompanion(
      id: id ?? this.id,
      sourcePackage: sourcePackage ?? this.sourcePackage,
      bangumiUrl: bangumiUrl ?? this.bangumiUrl,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      totalEpisode: totalEpisode ?? this.totalEpisode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourcePackage.present) {
      map['source_package'] = Variable<String>(sourcePackage.value);
    }
    if (bangumiUrl.present) {
      map['bangumi_url'] = Variable<String>(bangumiUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (currentEpisode.present) {
      map['current_episode'] = Variable<int>(currentEpisode.value);
    }
    if (totalEpisode.present) {
      map['total_episode'] = Variable<int>(totalEpisode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FollowsCompanion(')
          ..write('id: $id, ')
          ..write('sourcePackage: $sourcePackage, ')
          ..write('bangumiUrl: $bangumiUrl, ')
          ..write('title: $title, ')
          ..write('cover: $cover, ')
          ..write('currentEpisode: $currentEpisode, ')
          ..write('totalEpisode: $totalEpisode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoriesTable extends SearchHistories
    with TableInfo<$SearchHistoriesTable, SearchHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keywordMeta = const VerificationMeta(
    'keyword',
  );
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
    'keyword',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta(
    'searchedAt',
  );
  @override
  late final GeneratedColumn<int> searchedAt = GeneratedColumn<int>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, keyword, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(
        _keywordMeta,
        keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta),
      );
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(
        _searchedAtMeta,
        searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {keyword},
  ];
  @override
  SearchHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      keyword: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keyword'],
      )!,
      searchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}searched_at'],
      )!,
    );
  }

  @override
  $SearchHistoriesTable createAlias(String alias) {
    return $SearchHistoriesTable(attachedDatabase, alias);
  }
}

class SearchHistory extends DataClass implements Insertable<SearchHistory> {
  final int id;
  final String keyword;

  /// 搜索时间（Unix 毫秒）。
  final int searchedAt;
  const SearchHistory({
    required this.id,
    required this.keyword,
    required this.searchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['searched_at'] = Variable<int>(searchedAt);
    return map;
  }

  SearchHistoriesCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoriesCompanion(
      id: Value(id),
      keyword: Value(keyword),
      searchedAt: Value(searchedAt),
    );
  }

  factory SearchHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistory(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      searchedAt: serializer.fromJson<int>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'searchedAt': serializer.toJson<int>(searchedAt),
    };
  }

  SearchHistory copyWith({int? id, String? keyword, int? searchedAt}) =>
      SearchHistory(
        id: id ?? this.id,
        keyword: keyword ?? this.keyword,
        searchedAt: searchedAt ?? this.searchedAt,
      );
  SearchHistory copyWithCompanion(SearchHistoriesCompanion data) {
    return SearchHistory(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      searchedAt: data.searchedAt.present
          ? data.searchedAt.value
          : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistory(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistory &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.searchedAt == this.searchedAt);
}

class SearchHistoriesCompanion extends UpdateCompanion<SearchHistory> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<int> searchedAt;
  const SearchHistoriesCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.searchedAt = const Value.absent(),
  });
  SearchHistoriesCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    required int searchedAt,
  }) : keyword = Value(keyword),
       searchedAt = Value(searchedAt);
  static Insertable<SearchHistory> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<int>? searchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (searchedAt != null) 'searched_at': searchedAt,
    });
  }

  SearchHistoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? keyword,
    Value<int>? searchedAt,
  }) {
    return SearchHistoriesCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<int>(searchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WatchHistoriesTable watchHistories = $WatchHistoriesTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $FollowsTable follows = $FollowsTable(this);
  late final $SearchHistoriesTable searchHistories = $SearchHistoriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    watchHistories,
    favorites,
    follows,
    searchHistories,
  ];
}

typedef $$WatchHistoriesTableCreateCompanionBuilder =
    WatchHistoriesCompanion Function({
      Value<int> id,
      required String sourcePackage,
      required String bangumiUrl,
      required String title,
      Value<String> cover,
      required String episodeUrl,
      Value<String> episodeTitle,
      Value<int> positionMs,
      Value<int> durationMs,
      required DateTime updatedAt,
    });
typedef $$WatchHistoriesTableUpdateCompanionBuilder =
    WatchHistoriesCompanion Function({
      Value<int> id,
      Value<String> sourcePackage,
      Value<String> bangumiUrl,
      Value<String> title,
      Value<String> cover,
      Value<String> episodeUrl,
      Value<String> episodeTitle,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<DateTime> updatedAt,
    });

class $$WatchHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoriesTable> {
  $$WatchHistoriesTableFilterComposer({
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

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeUrl => $composableBuilder(
    column: $table.episodeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoriesTable> {
  $$WatchHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeUrl => $composableBuilder(
    column: $table.episodeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoriesTable> {
  $$WatchHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get episodeUrl => $composableBuilder(
    column: $table.episodeUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoriesTable,
          WatchHistory,
          $$WatchHistoriesTableFilterComposer,
          $$WatchHistoriesTableOrderingComposer,
          $$WatchHistoriesTableAnnotationComposer,
          $$WatchHistoriesTableCreateCompanionBuilder,
          $$WatchHistoriesTableUpdateCompanionBuilder,
          (
            WatchHistory,
            BaseReferences<_$AppDatabase, $WatchHistoriesTable, WatchHistory>,
          ),
          WatchHistory,
          PrefetchHooks Function()
        > {
  $$WatchHistoriesTableTableManager(
    _$AppDatabase db,
    $WatchHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourcePackage = const Value.absent(),
                Value<String> bangumiUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> cover = const Value.absent(),
                Value<String> episodeUrl = const Value.absent(),
                Value<String> episodeTitle = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WatchHistoriesCompanion(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                episodeUrl: episodeUrl,
                episodeTitle: episodeTitle,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourcePackage,
                required String bangumiUrl,
                required String title,
                Value<String> cover = const Value.absent(),
                required String episodeUrl,
                Value<String> episodeTitle = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                required DateTime updatedAt,
              }) => WatchHistoriesCompanion.insert(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                episodeUrl: episodeUrl,
                episodeTitle: episodeTitle,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoriesTable,
      WatchHistory,
      $$WatchHistoriesTableFilterComposer,
      $$WatchHistoriesTableOrderingComposer,
      $$WatchHistoriesTableAnnotationComposer,
      $$WatchHistoriesTableCreateCompanionBuilder,
      $$WatchHistoriesTableUpdateCompanionBuilder,
      (
        WatchHistory,
        BaseReferences<_$AppDatabase, $WatchHistoriesTable, WatchHistory>,
      ),
      WatchHistory,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      required String sourcePackage,
      required String bangumiUrl,
      required String title,
      Value<String> cover,
      required DateTime createdAt,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<int> id,
      Value<String> sourcePackage,
      Value<String> bangumiUrl,
      Value<String> title,
      Value<String> cover,
      Value<DateTime> createdAt,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
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

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
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

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourcePackage = const Value.absent(),
                Value<String> bangumiUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> cover = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourcePackage,
                required String bangumiUrl,
                required String title,
                Value<String> cover = const Value.absent(),
                required DateTime createdAt,
              }) => FavoritesCompanion.insert(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$FollowsTableCreateCompanionBuilder =
    FollowsCompanion Function({
      Value<int> id,
      required String sourcePackage,
      required String bangumiUrl,
      required String title,
      Value<String> cover,
      Value<int> currentEpisode,
      Value<int> totalEpisode,
      required DateTime updatedAt,
    });
typedef $$FollowsTableUpdateCompanionBuilder =
    FollowsCompanion Function({
      Value<int> id,
      Value<String> sourcePackage,
      Value<String> bangumiUrl,
      Value<String> title,
      Value<String> cover,
      Value<int> currentEpisode,
      Value<int> totalEpisode,
      Value<DateTime> updatedAt,
    });

class $$FollowsTableFilterComposer
    extends Composer<_$AppDatabase, $FollowsTable> {
  $$FollowsTableFilterComposer({
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

  ColumnFilters<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentEpisode => $composableBuilder(
    column: $table.currentEpisode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisode => $composableBuilder(
    column: $table.totalEpisode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FollowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FollowsTable> {
  $$FollowsTableOrderingComposer({
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

  ColumnOrderings<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentEpisode => $composableBuilder(
    column: $table.currentEpisode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisode => $composableBuilder(
    column: $table.totalEpisode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FollowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FollowsTable> {
  $$FollowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourcePackage => $composableBuilder(
    column: $table.sourcePackage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bangumiUrl => $composableBuilder(
    column: $table.bangumiUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<int> get currentEpisode => $composableBuilder(
    column: $table.currentEpisode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalEpisode => $composableBuilder(
    column: $table.totalEpisode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FollowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FollowsTable,
          Follow,
          $$FollowsTableFilterComposer,
          $$FollowsTableOrderingComposer,
          $$FollowsTableAnnotationComposer,
          $$FollowsTableCreateCompanionBuilder,
          $$FollowsTableUpdateCompanionBuilder,
          (Follow, BaseReferences<_$AppDatabase, $FollowsTable, Follow>),
          Follow,
          PrefetchHooks Function()
        > {
  $$FollowsTableTableManager(_$AppDatabase db, $FollowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FollowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FollowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FollowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourcePackage = const Value.absent(),
                Value<String> bangumiUrl = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> cover = const Value.absent(),
                Value<int> currentEpisode = const Value.absent(),
                Value<int> totalEpisode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => FollowsCompanion(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                currentEpisode: currentEpisode,
                totalEpisode: totalEpisode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourcePackage,
                required String bangumiUrl,
                required String title,
                Value<String> cover = const Value.absent(),
                Value<int> currentEpisode = const Value.absent(),
                Value<int> totalEpisode = const Value.absent(),
                required DateTime updatedAt,
              }) => FollowsCompanion.insert(
                id: id,
                sourcePackage: sourcePackage,
                bangumiUrl: bangumiUrl,
                title: title,
                cover: cover,
                currentEpisode: currentEpisode,
                totalEpisode: totalEpisode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FollowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FollowsTable,
      Follow,
      $$FollowsTableFilterComposer,
      $$FollowsTableOrderingComposer,
      $$FollowsTableAnnotationComposer,
      $$FollowsTableCreateCompanionBuilder,
      $$FollowsTableUpdateCompanionBuilder,
      (Follow, BaseReferences<_$AppDatabase, $FollowsTable, Follow>),
      Follow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoriesTableCreateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      required String keyword,
      required int searchedAt,
    });
typedef $$SearchHistoriesTableUpdateCompanionBuilder =
    SearchHistoriesCompanion Function({
      Value<int> id,
      Value<String> keyword,
      Value<int> searchedAt,
    });

class $$SearchHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableFilterComposer({
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

  ColumnFilters<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableOrderingComposer({
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

  ColumnOrderings<String> get keyword => $composableBuilder(
    column: $table.keyword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoriesTable> {
  $$SearchHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<int> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => column,
  );
}

class $$SearchHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoriesTable,
          SearchHistory,
          $$SearchHistoriesTableFilterComposer,
          $$SearchHistoriesTableOrderingComposer,
          $$SearchHistoriesTableAnnotationComposer,
          $$SearchHistoriesTableCreateCompanionBuilder,
          $$SearchHistoriesTableUpdateCompanionBuilder,
          (
            SearchHistory,
            BaseReferences<_$AppDatabase, $SearchHistoriesTable, SearchHistory>,
          ),
          SearchHistory,
          PrefetchHooks Function()
        > {
  $$SearchHistoriesTableTableManager(
    _$AppDatabase db,
    $SearchHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> keyword = const Value.absent(),
                Value<int> searchedAt = const Value.absent(),
              }) => SearchHistoriesCompanion(
                id: id,
                keyword: keyword,
                searchedAt: searchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String keyword,
                required int searchedAt,
              }) => SearchHistoriesCompanion.insert(
                id: id,
                keyword: keyword,
                searchedAt: searchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoriesTable,
      SearchHistory,
      $$SearchHistoriesTableFilterComposer,
      $$SearchHistoriesTableOrderingComposer,
      $$SearchHistoriesTableAnnotationComposer,
      $$SearchHistoriesTableCreateCompanionBuilder,
      $$SearchHistoriesTableUpdateCompanionBuilder,
      (
        SearchHistory,
        BaseReferences<_$AppDatabase, $SearchHistoriesTable, SearchHistory>,
      ),
      SearchHistory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WatchHistoriesTableTableManager get watchHistories =>
      $$WatchHistoriesTableTableManager(_db, _db.watchHistories);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$FollowsTableTableManager get follows =>
      $$FollowsTableTableManager(_db, _db.follows);
  $$SearchHistoriesTableTableManager get searchHistories =>
      $$SearchHistoriesTableTableManager(_db, _db.searchHistories);
}
