// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductCategoriesTable extends ProductCategories
    with TableInfo<$ProductCategoriesTable, ProductCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ProductCategoriesTable createAlias(String alias) {
    return $ProductCategoriesTable(attachedDatabase, alias);
  }
}

class ProductCategoryRow extends DataClass
    implements Insertable<ProductCategoryRow> {
  final String id;
  final String name;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const ProductCategoryRow({
    required this.id,
    required this.name,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ProductCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ProductCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ProductCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  ProductCategoryRow copyWith({
    String? id,
    String? name,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => ProductCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ProductCategoryRow copyWithCompanion(ProductCategoriesCompanion data) {
    return ProductCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    position,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ProductCategoriesCompanion extends UpdateCompanion<ProductCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ProductCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCategoriesCompanion.insert({
    required String id,
    required String name,
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ProductCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return ProductCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES product_categories (id)',
    ),
  );
  static const VerificationMeta _categoryNameSnapshotMeta =
      const VerificationMeta('categoryNameSnapshot');
  @override
  late final GeneratedColumn<String> categoryNameSnapshot =
      GeneratedColumn<String>(
        'category_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('Lain-lain'),
      );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<int> costPrice = GeneratedColumn<int>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retailPriceMeta = const VerificationMeta(
    'retailPrice',
  );
  @override
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
    'retail_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wholesalePriceMeta = const VerificationMeta(
    'wholesalePrice',
  );
  @override
  late final GeneratedColumn<int> wholesalePrice = GeneratedColumn<int>(
    'wholesale_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _packSizeMeta = const VerificationMeta(
    'packSize',
  );
  @override
  late final GeneratedColumn<int> packSize = GeneratedColumn<int>(
    'pack_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _cartonSizeMeta = const VerificationMeta(
    'cartonSize',
  );
  @override
  late final GeneratedColumn<int> cartonSize = GeneratedColumn<int>(
    'carton_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _stockPcsMeta = const VerificationMeta(
    'stockPcs',
  );
  @override
  late final GeneratedColumn<double> stockPcs = GeneratedColumn<double>(
    'stock_pcs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _trackStockMeta = const VerificationMeta(
    'trackStock',
  );
  @override
  late final GeneratedColumn<bool> trackStock = GeneratedColumn<bool>(
    'track_stock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("track_stock" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _baseUnitMeta = const VerificationMeta(
    'baseUnit',
  );
  @override
  late final GeneratedColumn<String> baseUnit = GeneratedColumn<String>(
    'base_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _minStockMeta = const VerificationMeta(
    'minStock',
  );
  @override
  late final GeneratedColumn<double> minStock = GeneratedColumn<double>(
    'min_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    categoryNameSnapshot,
    costPrice,
    retailPrice,
    wholesalePrice,
    packSize,
    cartonSize,
    stockPcs,
    trackStock,
    baseUnit,
    minStock,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name_snapshot')) {
      context.handle(
        _categoryNameSnapshotMeta,
        categoryNameSnapshot.isAcceptableOrUnknown(
          data['category_name_snapshot']!,
          _categoryNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('retail_price')) {
      context.handle(
        _retailPriceMeta,
        retailPrice.isAcceptableOrUnknown(
          data['retail_price']!,
          _retailPriceMeta,
        ),
      );
    }
    if (data.containsKey('wholesale_price')) {
      context.handle(
        _wholesalePriceMeta,
        wholesalePrice.isAcceptableOrUnknown(
          data['wholesale_price']!,
          _wholesalePriceMeta,
        ),
      );
    }
    if (data.containsKey('pack_size')) {
      context.handle(
        _packSizeMeta,
        packSize.isAcceptableOrUnknown(data['pack_size']!, _packSizeMeta),
      );
    }
    if (data.containsKey('carton_size')) {
      context.handle(
        _cartonSizeMeta,
        cartonSize.isAcceptableOrUnknown(data['carton_size']!, _cartonSizeMeta),
      );
    }
    if (data.containsKey('stock_pcs')) {
      context.handle(
        _stockPcsMeta,
        stockPcs.isAcceptableOrUnknown(data['stock_pcs']!, _stockPcsMeta),
      );
    }
    if (data.containsKey('track_stock')) {
      context.handle(
        _trackStockMeta,
        trackStock.isAcceptableOrUnknown(data['track_stock']!, _trackStockMeta),
      );
    }
    if (data.containsKey('base_unit')) {
      context.handle(
        _baseUnitMeta,
        baseUnit.isAcceptableOrUnknown(data['base_unit']!, _baseUnitMeta),
      );
    }
    if (data.containsKey('min_stock')) {
      context.handle(
        _minStockMeta,
        minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_snapshot'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price'],
      )!,
      retailPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_price'],
      )!,
      wholesalePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wholesale_price'],
      )!,
      packSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pack_size'],
      )!,
      cartonSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carton_size'],
      )!,
      stockPcs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock_pcs'],
      )!,
      trackStock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}track_stock'],
      )!,
      baseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_unit'],
      )!,
      minStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_stock'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String name;
  final String? categoryId;
  final String categoryNameSnapshot;
  final int costPrice;
  final int retailPrice;
  final int wholesalePrice;
  final int packSize;
  final int cartonSize;
  final double stockPcs;
  final bool trackStock;
  final String baseUnit;
  final double minStock;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const ProductRow({
    required this.id,
    required this.name,
    this.categoryId,
    required this.categoryNameSnapshot,
    required this.costPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.packSize,
    required this.cartonSize,
    required this.stockPcs,
    required this.trackStock,
    required this.baseUnit,
    required this.minStock,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['category_name_snapshot'] = Variable<String>(categoryNameSnapshot);
    map['cost_price'] = Variable<int>(costPrice);
    map['retail_price'] = Variable<int>(retailPrice);
    map['wholesale_price'] = Variable<int>(wholesalePrice);
    map['pack_size'] = Variable<int>(packSize);
    map['carton_size'] = Variable<int>(cartonSize);
    map['stock_pcs'] = Variable<double>(stockPcs);
    map['track_stock'] = Variable<bool>(trackStock);
    map['base_unit'] = Variable<String>(baseUnit);
    map['min_stock'] = Variable<double>(minStock);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryNameSnapshot: Value(categoryNameSnapshot),
      costPrice: Value(costPrice),
      retailPrice: Value(retailPrice),
      wholesalePrice: Value(wholesalePrice),
      packSize: Value(packSize),
      cartonSize: Value(cartonSize),
      stockPcs: Value(stockPcs),
      trackStock: Value(trackStock),
      baseUnit: Value(baseUnit),
      minStock: Value(minStock),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryNameSnapshot: serializer.fromJson<String>(
        json['categoryNameSnapshot'],
      ),
      costPrice: serializer.fromJson<int>(json['costPrice']),
      retailPrice: serializer.fromJson<int>(json['retailPrice']),
      wholesalePrice: serializer.fromJson<int>(json['wholesalePrice']),
      packSize: serializer.fromJson<int>(json['packSize']),
      cartonSize: serializer.fromJson<int>(json['cartonSize']),
      stockPcs: serializer.fromJson<double>(json['stockPcs']),
      trackStock: serializer.fromJson<bool>(json['trackStock']),
      baseUnit: serializer.fromJson<String>(json['baseUnit']),
      minStock: serializer.fromJson<double>(json['minStock']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryNameSnapshot': serializer.toJson<String>(categoryNameSnapshot),
      'costPrice': serializer.toJson<int>(costPrice),
      'retailPrice': serializer.toJson<int>(retailPrice),
      'wholesalePrice': serializer.toJson<int>(wholesalePrice),
      'packSize': serializer.toJson<int>(packSize),
      'cartonSize': serializer.toJson<int>(cartonSize),
      'stockPcs': serializer.toJson<double>(stockPcs),
      'trackStock': serializer.toJson<bool>(trackStock),
      'baseUnit': serializer.toJson<String>(baseUnit),
      'minStock': serializer.toJson<double>(minStock),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  ProductRow copyWith({
    String? id,
    String? name,
    Value<String?> categoryId = const Value.absent(),
    String? categoryNameSnapshot,
    int? costPrice,
    int? retailPrice,
    int? wholesalePrice,
    int? packSize,
    int? cartonSize,
    double? stockPcs,
    bool? trackStock,
    String? baseUnit,
    double? minStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => ProductRow(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
    costPrice: costPrice ?? this.costPrice,
    retailPrice: retailPrice ?? this.retailPrice,
    wholesalePrice: wholesalePrice ?? this.wholesalePrice,
    packSize: packSize ?? this.packSize,
    cartonSize: cartonSize ?? this.cartonSize,
    stockPcs: stockPcs ?? this.stockPcs,
    trackStock: trackStock ?? this.trackStock,
    baseUnit: baseUnit ?? this.baseUnit,
    minStock: minStock ?? this.minStock,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryNameSnapshot: data.categoryNameSnapshot.present
          ? data.categoryNameSnapshot.value
          : this.categoryNameSnapshot,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      retailPrice: data.retailPrice.present
          ? data.retailPrice.value
          : this.retailPrice,
      wholesalePrice: data.wholesalePrice.present
          ? data.wholesalePrice.value
          : this.wholesalePrice,
      packSize: data.packSize.present ? data.packSize.value : this.packSize,
      cartonSize: data.cartonSize.present
          ? data.cartonSize.value
          : this.cartonSize,
      stockPcs: data.stockPcs.present ? data.stockPcs.value : this.stockPcs,
      trackStock: data.trackStock.present
          ? data.trackStock.value
          : this.trackStock,
      baseUnit: data.baseUnit.present ? data.baseUnit.value : this.baseUnit,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('packSize: $packSize, ')
          ..write('cartonSize: $cartonSize, ')
          ..write('stockPcs: $stockPcs, ')
          ..write('trackStock: $trackStock, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('minStock: $minStock, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    categoryNameSnapshot,
    costPrice,
    retailPrice,
    wholesalePrice,
    packSize,
    cartonSize,
    stockPcs,
    trackStock,
    baseUnit,
    minStock,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.categoryNameSnapshot == this.categoryNameSnapshot &&
          other.costPrice == this.costPrice &&
          other.retailPrice == this.retailPrice &&
          other.wholesalePrice == this.wholesalePrice &&
          other.packSize == this.packSize &&
          other.cartonSize == this.cartonSize &&
          other.stockPcs == this.stockPcs &&
          other.trackStock == this.trackStock &&
          other.baseUnit == this.baseUnit &&
          other.minStock == this.minStock &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> categoryId;
  final Value<String> categoryNameSnapshot;
  final Value<int> costPrice;
  final Value<int> retailPrice;
  final Value<int> wholesalePrice;
  final Value<int> packSize;
  final Value<int> cartonSize;
  final Value<double> stockPcs;
  final Value<bool> trackStock;
  final Value<String> baseUnit;
  final Value<double> minStock;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.packSize = const Value.absent(),
    this.cartonSize = const Value.absent(),
    this.stockPcs = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.minStock = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.categoryId = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.packSize = const Value.absent(),
    this.cartonSize = const Value.absent(),
    this.stockPcs = const Value.absent(),
    this.trackStock = const Value.absent(),
    this.baseUnit = const Value.absent(),
    this.minStock = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? categoryNameSnapshot,
    Expression<int>? costPrice,
    Expression<int>? retailPrice,
    Expression<int>? wholesalePrice,
    Expression<int>? packSize,
    Expression<int>? cartonSize,
    Expression<double>? stockPcs,
    Expression<bool>? trackStock,
    Expression<String>? baseUnit,
    Expression<double>? minStock,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryNameSnapshot != null)
        'category_name_snapshot': categoryNameSnapshot,
      if (costPrice != null) 'cost_price': costPrice,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (packSize != null) 'pack_size': packSize,
      if (cartonSize != null) 'carton_size': cartonSize,
      if (stockPcs != null) 'stock_pcs': stockPcs,
      if (trackStock != null) 'track_stock': trackStock,
      if (baseUnit != null) 'base_unit': baseUnit,
      if (minStock != null) 'min_stock': minStock,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? categoryId,
    Value<String>? categoryNameSnapshot,
    Value<int>? costPrice,
    Value<int>? retailPrice,
    Value<int>? wholesalePrice,
    Value<int>? packSize,
    Value<int>? cartonSize,
    Value<double>? stockPcs,
    Value<bool>? trackStock,
    Value<String>? baseUnit,
    Value<double>? minStock,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      packSize: packSize ?? this.packSize,
      cartonSize: cartonSize ?? this.cartonSize,
      stockPcs: stockPcs ?? this.stockPcs,
      trackStock: trackStock ?? this.trackStock,
      baseUnit: baseUnit ?? this.baseUnit,
      minStock: minStock ?? this.minStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryNameSnapshot.present) {
      map['category_name_snapshot'] = Variable<String>(
        categoryNameSnapshot.value,
      );
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<int>(costPrice.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    if (wholesalePrice.present) {
      map['wholesale_price'] = Variable<int>(wholesalePrice.value);
    }
    if (packSize.present) {
      map['pack_size'] = Variable<int>(packSize.value);
    }
    if (cartonSize.present) {
      map['carton_size'] = Variable<int>(cartonSize.value);
    }
    if (stockPcs.present) {
      map['stock_pcs'] = Variable<double>(stockPcs.value);
    }
    if (trackStock.present) {
      map['track_stock'] = Variable<bool>(trackStock.value);
    }
    if (baseUnit.present) {
      map['base_unit'] = Variable<String>(baseUnit.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<double>(minStock.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('packSize: $packSize, ')
          ..write('cartonSize: $cartonSize, ')
          ..write('stockPcs: $stockPcs, ')
          ..write('trackStock: $trackStock, ')
          ..write('baseUnit: $baseUnit, ')
          ..write('minStock: $minStock, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletsTable extends Wallets with TableInfo<$WalletsTable, WalletRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    balance,
    isPrimary,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }
}

class WalletRow extends DataClass implements Insertable<WalletRow> {
  final String id;
  final String name;
  final int balance;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const WalletRow({
    required this.id,
    required this.name,
    required this.balance,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<int>(balance);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      balance: Value(balance),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory WalletRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<int>(json['balance']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'balance': serializer.toJson<int>(balance),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  WalletRow copyWith({
    String? id,
    String? name,
    int? balance,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => WalletRow(
    id: id ?? this.id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
    isPrimary: isPrimary ?? this.isPrimary,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  WalletRow copyWithCompanion(WalletsCompanion data) {
    return WalletRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    balance,
    isPrimary,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.balance == this.balance &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class WalletsCompanion extends UpdateCompanion<WalletRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> balance;
  final Value<bool> isPrimary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletsCompanion.insert({
    required String id,
    required String name,
    this.balance = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WalletRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? balance,
    Expression<bool>? isPrimary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? balance,
    Value<bool>? isPrimary,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionCategoriesTable extends TransactionCategories
    with TableInfo<$TransactionCategoriesTable, TransactionCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    direction,
    isSystem,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TransactionCategoriesTable createAlias(String alias) {
    return $TransactionCategoriesTable(attachedDatabase, alias);
  }
}

class TransactionCategoryRow extends DataClass
    implements Insertable<TransactionCategoryRow> {
  final String id;
  final String name;
  final String direction;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const TransactionCategoryRow({
    required this.id,
    required this.name,
    required this.direction,
    required this.isSystem,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['direction'] = Variable<String>(direction);
    map['is_system'] = Variable<bool>(isSystem);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TransactionCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      direction: Value(direction),
      isSystem: Value(isSystem),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TransactionCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      direction: serializer.fromJson<String>(json['direction']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'direction': serializer.toJson<String>(direction),
      'isSystem': serializer.toJson<bool>(isSystem),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TransactionCategoryRow copyWith({
    String? id,
    String? name,
    String? direction,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => TransactionCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    direction: direction ?? this.direction,
    isSystem: isSystem ?? this.isSystem,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TransactionCategoryRow copyWithCompanion(
    TransactionCategoriesCompanion data,
  ) {
    return TransactionCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      direction: data.direction.present ? data.direction.value : this.direction,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    direction,
    isSystem,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.direction == this.direction &&
          other.isSystem == this.isSystem &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TransactionCategoriesCompanion
    extends UpdateCompanion<TransactionCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> direction;
  final Value<bool> isSystem;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TransactionCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionCategoriesCompanion.insert({
    required String id,
    required String name,
    required String direction,
    this.isSystem = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       direction = Value(direction);
  static Insertable<TransactionCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? direction,
    Expression<bool>? isSystem,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (direction != null) 'direction': direction,
      if (isSystem != null) 'is_system': isSystem,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? direction,
    Value<bool>? isSystem,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TransactionCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
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
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wallets (id)',
    ),
  );
  static const VerificationMeta _walletNameSnapshotMeta =
      const VerificationMeta('walletNameSnapshot');
  @override
  late final GeneratedColumn<String> walletNameSnapshot =
      GeneratedColumn<String>(
        'wallet_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_categories (id)',
    ),
  );
  static const VerificationMeta _categoryNameSnapshotMeta =
      const VerificationMeta('categoryNameSnapshot');
  @override
  late final GeneratedColumn<String> categoryNameSnapshot =
      GeneratedColumn<String>(
        'category_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<int> discount = GeneratedColumn<int>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _evidencePathMeta = const VerificationMeta(
    'evidencePath',
  );
  @override
  late final GeneratedColumn<String> evidencePath = GeneratedColumn<String>(
    'evidence_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrSourceMeta = const VerificationMeta(
    'ocrSource',
  );
  @override
  late final GeneratedColumn<String> ocrSource = GeneratedColumn<String>(
    'ocr_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawVoiceTextMeta = const VerificationMeta(
    'rawVoiceText',
  );
  @override
  late final GeneratedColumn<String> rawVoiceText = GeneratedColumn<String>(
    'raw_voice_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('localOnly'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    walletId,
    walletNameSnapshot,
    categoryId,
    categoryNameSnapshot,
    amount,
    discount,
    note,
    evidencePath,
    ocrSource,
    rawVoiceText,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('wallet_name_snapshot')) {
      context.handle(
        _walletNameSnapshotMeta,
        walletNameSnapshot.isAcceptableOrUnknown(
          data['wallet_name_snapshot']!,
          _walletNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_walletNameSnapshotMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name_snapshot')) {
      context.handle(
        _categoryNameSnapshotMeta,
        categoryNameSnapshot.isAcceptableOrUnknown(
          data['category_name_snapshot']!,
          _categoryNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameSnapshotMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('evidence_path')) {
      context.handle(
        _evidencePathMeta,
        evidencePath.isAcceptableOrUnknown(
          data['evidence_path']!,
          _evidencePathMeta,
        ),
      );
    }
    if (data.containsKey('ocr_source')) {
      context.handle(
        _ocrSourceMeta,
        ocrSource.isAcceptableOrUnknown(data['ocr_source']!, _ocrSourceMeta),
      );
    }
    if (data.containsKey('raw_voice_text')) {
      context.handle(
        _rawVoiceTextMeta,
        rawVoiceText.isAcceptableOrUnknown(
          data['raw_voice_text']!,
          _rawVoiceTextMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      walletNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_name_snapshot'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_snapshot'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      evidencePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_path'],
      ),
      ocrSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_source'],
      ),
      rawVoiceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_voice_text'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String kind;
  final String walletId;
  final String walletNameSnapshot;
  final String? categoryId;
  final String categoryNameSnapshot;
  final int amount;
  final int discount;
  final String note;
  final String? evidencePath;
  final String? ocrSource;
  final String? rawVoiceText;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;
  const TransactionRow({
    required this.id,
    required this.kind,
    required this.walletId,
    required this.walletNameSnapshot,
    this.categoryId,
    required this.categoryNameSnapshot,
    required this.amount,
    required this.discount,
    required this.note,
    this.evidencePath,
    this.ocrSource,
    this.rawVoiceText,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['wallet_id'] = Variable<String>(walletId);
    map['wallet_name_snapshot'] = Variable<String>(walletNameSnapshot);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['category_name_snapshot'] = Variable<String>(categoryNameSnapshot);
    map['amount'] = Variable<int>(amount);
    map['discount'] = Variable<int>(discount);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || evidencePath != null) {
      map['evidence_path'] = Variable<String>(evidencePath);
    }
    if (!nullToAbsent || ocrSource != null) {
      map['ocr_source'] = Variable<String>(ocrSource);
    }
    if (!nullToAbsent || rawVoiceText != null) {
      map['raw_voice_text'] = Variable<String>(rawVoiceText);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      walletId: Value(walletId),
      walletNameSnapshot: Value(walletNameSnapshot),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryNameSnapshot: Value(categoryNameSnapshot),
      amount: Value(amount),
      discount: Value(discount),
      note: Value(note),
      evidencePath: evidencePath == null && nullToAbsent
          ? const Value.absent()
          : Value(evidencePath),
      ocrSource: ocrSource == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrSource),
      rawVoiceText: rawVoiceText == null && nullToAbsent
          ? const Value.absent()
          : Value(rawVoiceText),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory TransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      walletId: serializer.fromJson<String>(json['walletId']),
      walletNameSnapshot: serializer.fromJson<String>(
        json['walletNameSnapshot'],
      ),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryNameSnapshot: serializer.fromJson<String>(
        json['categoryNameSnapshot'],
      ),
      amount: serializer.fromJson<int>(json['amount']),
      discount: serializer.fromJson<int>(json['discount']),
      note: serializer.fromJson<String>(json['note']),
      evidencePath: serializer.fromJson<String?>(json['evidencePath']),
      ocrSource: serializer.fromJson<String?>(json['ocrSource']),
      rawVoiceText: serializer.fromJson<String?>(json['rawVoiceText']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'walletId': serializer.toJson<String>(walletId),
      'walletNameSnapshot': serializer.toJson<String>(walletNameSnapshot),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryNameSnapshot': serializer.toJson<String>(categoryNameSnapshot),
      'amount': serializer.toJson<int>(amount),
      'discount': serializer.toJson<int>(discount),
      'note': serializer.toJson<String>(note),
      'evidencePath': serializer.toJson<String?>(evidencePath),
      'ocrSource': serializer.toJson<String?>(ocrSource),
      'rawVoiceText': serializer.toJson<String?>(rawVoiceText),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TransactionRow copyWith({
    String? id,
    String? kind,
    String? walletId,
    String? walletNameSnapshot,
    Value<String?> categoryId = const Value.absent(),
    String? categoryNameSnapshot,
    int? amount,
    int? discount,
    String? note,
    Value<String?> evidencePath = const Value.absent(),
    Value<String?> ocrSource = const Value.absent(),
    Value<String?> rawVoiceText = const Value.absent(),
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? syncStatus,
  }) => TransactionRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    walletId: walletId ?? this.walletId,
    walletNameSnapshot: walletNameSnapshot ?? this.walletNameSnapshot,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
    amount: amount ?? this.amount,
    discount: discount ?? this.discount,
    note: note ?? this.note,
    evidencePath: evidencePath.present ? evidencePath.value : this.evidencePath,
    ocrSource: ocrSource.present ? ocrSource.value : this.ocrSource,
    rawVoiceText: rawVoiceText.present ? rawVoiceText.value : this.rawVoiceText,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      walletNameSnapshot: data.walletNameSnapshot.present
          ? data.walletNameSnapshot.value
          : this.walletNameSnapshot,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryNameSnapshot: data.categoryNameSnapshot.present
          ? data.categoryNameSnapshot.value
          : this.categoryNameSnapshot,
      amount: data.amount.present ? data.amount.value : this.amount,
      discount: data.discount.present ? data.discount.value : this.discount,
      note: data.note.present ? data.note.value : this.note,
      evidencePath: data.evidencePath.present
          ? data.evidencePath.value
          : this.evidencePath,
      ocrSource: data.ocrSource.present ? data.ocrSource.value : this.ocrSource,
      rawVoiceText: data.rawVoiceText.present
          ? data.rawVoiceText.value
          : this.rawVoiceText,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('walletId: $walletId, ')
          ..write('walletNameSnapshot: $walletNameSnapshot, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('amount: $amount, ')
          ..write('discount: $discount, ')
          ..write('note: $note, ')
          ..write('evidencePath: $evidencePath, ')
          ..write('ocrSource: $ocrSource, ')
          ..write('rawVoiceText: $rawVoiceText, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    walletId,
    walletNameSnapshot,
    categoryId,
    categoryNameSnapshot,
    amount,
    discount,
    note,
    evidencePath,
    ocrSource,
    rawVoiceText,
    occurredAt,
    createdAt,
    updatedAt,
    deletedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.walletId == this.walletId &&
          other.walletNameSnapshot == this.walletNameSnapshot &&
          other.categoryId == this.categoryId &&
          other.categoryNameSnapshot == this.categoryNameSnapshot &&
          other.amount == this.amount &&
          other.discount == this.discount &&
          other.note == this.note &&
          other.evidencePath == this.evidencePath &&
          other.ocrSource == this.ocrSource &&
          other.rawVoiceText == this.rawVoiceText &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> walletId;
  final Value<String> walletNameSnapshot;
  final Value<String?> categoryId;
  final Value<String> categoryNameSnapshot;
  final Value<int> amount;
  final Value<int> discount;
  final Value<String> note;
  final Value<String?> evidencePath;
  final Value<String?> ocrSource;
  final Value<String?> rawVoiceText;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.walletId = const Value.absent(),
    this.walletNameSnapshot = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.amount = const Value.absent(),
    this.discount = const Value.absent(),
    this.note = const Value.absent(),
    this.evidencePath = const Value.absent(),
    this.ocrSource = const Value.absent(),
    this.rawVoiceText = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String kind,
    required String walletId,
    required String walletNameSnapshot,
    this.categoryId = const Value.absent(),
    required String categoryNameSnapshot,
    this.amount = const Value.absent(),
    this.discount = const Value.absent(),
    this.note = const Value.absent(),
    this.evidencePath = const Value.absent(),
    this.ocrSource = const Value.absent(),
    this.rawVoiceText = const Value.absent(),
    required DateTime occurredAt,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       walletId = Value(walletId),
       walletNameSnapshot = Value(walletNameSnapshot),
       categoryNameSnapshot = Value(categoryNameSnapshot),
       occurredAt = Value(occurredAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? walletId,
    Expression<String>? walletNameSnapshot,
    Expression<String>? categoryId,
    Expression<String>? categoryNameSnapshot,
    Expression<int>? amount,
    Expression<int>? discount,
    Expression<String>? note,
    Expression<String>? evidencePath,
    Expression<String>? ocrSource,
    Expression<String>? rawVoiceText,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (walletId != null) 'wallet_id': walletId,
      if (walletNameSnapshot != null)
        'wallet_name_snapshot': walletNameSnapshot,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryNameSnapshot != null)
        'category_name_snapshot': categoryNameSnapshot,
      if (amount != null) 'amount': amount,
      if (discount != null) 'discount': discount,
      if (note != null) 'note': note,
      if (evidencePath != null) 'evidence_path': evidencePath,
      if (ocrSource != null) 'ocr_source': ocrSource,
      if (rawVoiceText != null) 'raw_voice_text': rawVoiceText,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? walletId,
    Value<String>? walletNameSnapshot,
    Value<String?>? categoryId,
    Value<String>? categoryNameSnapshot,
    Value<int>? amount,
    Value<int>? discount,
    Value<String>? note,
    Value<String?>? evidencePath,
    Value<String?>? ocrSource,
    Value<String?>? rawVoiceText,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      walletId: walletId ?? this.walletId,
      walletNameSnapshot: walletNameSnapshot ?? this.walletNameSnapshot,
      categoryId: categoryId ?? this.categoryId,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      note: note ?? this.note,
      evidencePath: evidencePath ?? this.evidencePath,
      ocrSource: ocrSource ?? this.ocrSource,
      rawVoiceText: rawVoiceText ?? this.rawVoiceText,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (walletNameSnapshot.present) {
      map['wallet_name_snapshot'] = Variable<String>(walletNameSnapshot.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryNameSnapshot.present) {
      map['category_name_snapshot'] = Variable<String>(
        categoryNameSnapshot.value,
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (discount.present) {
      map['discount'] = Variable<int>(discount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (evidencePath.present) {
      map['evidence_path'] = Variable<String>(evidencePath.value);
    }
    if (ocrSource.present) {
      map['ocr_source'] = Variable<String>(ocrSource.value);
    }
    if (rawVoiceText.present) {
      map['raw_voice_text'] = Variable<String>(rawVoiceText.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('walletId: $walletId, ')
          ..write('walletNameSnapshot: $walletNameSnapshot, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('amount: $amount, ')
          ..write('discount: $discount, ')
          ..write('note: $note, ')
          ..write('evidencePath: $evidencePath, ')
          ..write('ocrSource: $ocrSource, ')
          ..write('rawVoiceText: $rawVoiceText, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionLinesTable extends TransactionLines
    with TableInfo<$TransactionLinesTable, TransactionLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transactions (id)',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<int> costPrice = GeneratedColumn<int>(
    'cost_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<String> segment = GeneratedColumn<String>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMultiplierMeta = const VerificationMeta(
    'unitMultiplier',
  );
  @override
  late final GeneratedColumn<double> unitMultiplier = GeneratedColumn<double>(
    'unit_multiplier',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    productId,
    productNameSnapshot,
    position,
    quantity,
    unit,
    unitPrice,
    costPrice,
    segment,
    unitMultiplier,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentMeta);
    }
    if (data.containsKey('unit_multiplier')) {
      context.handle(
        _unitMultiplierMeta,
        unitMultiplier.isAcceptableOrUnknown(
          data['unit_multiplier']!,
          _unitMultiplierMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_price'],
      )!,
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment'],
      )!,
      unitMultiplier: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_multiplier'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionLinesTable createAlias(String alias) {
    return $TransactionLinesTable(attachedDatabase, alias);
  }
}

class TransactionLineRow extends DataClass
    implements Insertable<TransactionLineRow> {
  final String id;
  final String transactionId;
  final String? productId;
  final String productNameSnapshot;
  final int position;
  final double quantity;
  final String unit;
  final int unitPrice;
  final int costPrice;
  final String segment;
  final double unitMultiplier;
  final DateTime createdAt;
  const TransactionLineRow({
    required this.id,
    required this.transactionId,
    this.productId,
    required this.productNameSnapshot,
    required this.position,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.costPrice,
    required this.segment,
    required this.unitMultiplier,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    map['position'] = Variable<int>(position);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['unit_price'] = Variable<int>(unitPrice);
    map['cost_price'] = Variable<int>(costPrice);
    map['segment'] = Variable<String>(segment);
    map['unit_multiplier'] = Variable<double>(unitMultiplier);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TransactionLinesCompanion toCompanion(bool nullToAbsent) {
    return TransactionLinesCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      productNameSnapshot: Value(productNameSnapshot),
      position: Value(position),
      quantity: Value(quantity),
      unit: Value(unit),
      unitPrice: Value(unitPrice),
      costPrice: Value(costPrice),
      segment: Value(segment),
      unitMultiplier: Value(unitMultiplier),
      createdAt: Value(createdAt),
    );
  }

  factory TransactionLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionLineRow(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      productId: serializer.fromJson<String?>(json['productId']),
      productNameSnapshot: serializer.fromJson<String>(
        json['productNameSnapshot'],
      ),
      position: serializer.fromJson<int>(json['position']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      costPrice: serializer.fromJson<int>(json['costPrice']),
      segment: serializer.fromJson<String>(json['segment']),
      unitMultiplier: serializer.fromJson<double>(json['unitMultiplier']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'productId': serializer.toJson<String?>(productId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'position': serializer.toJson<int>(position),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'costPrice': serializer.toJson<int>(costPrice),
      'segment': serializer.toJson<String>(segment),
      'unitMultiplier': serializer.toJson<double>(unitMultiplier),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TransactionLineRow copyWith({
    String? id,
    String? transactionId,
    Value<String?> productId = const Value.absent(),
    String? productNameSnapshot,
    int? position,
    double? quantity,
    String? unit,
    int? unitPrice,
    int? costPrice,
    String? segment,
    double? unitMultiplier,
    DateTime? createdAt,
  }) => TransactionLineRow(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    productId: productId.present ? productId.value : this.productId,
    productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
    position: position ?? this.position,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    costPrice: costPrice ?? this.costPrice,
    segment: segment ?? this.segment,
    unitMultiplier: unitMultiplier ?? this.unitMultiplier,
    createdAt: createdAt ?? this.createdAt,
  );
  TransactionLineRow copyWithCompanion(TransactionLinesCompanion data) {
    return TransactionLineRow(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      position: data.position.present ? data.position.value : this.position,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      segment: data.segment.present ? data.segment.value : this.segment,
      unitMultiplier: data.unitMultiplier.present
          ? data.unitMultiplier.value
          : this.unitMultiplier,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLineRow(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('position: $position, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('segment: $segment, ')
          ..write('unitMultiplier: $unitMultiplier, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    productId,
    productNameSnapshot,
    position,
    quantity,
    unit,
    unitPrice,
    costPrice,
    segment,
    unitMultiplier,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionLineRow &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.position == this.position &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.costPrice == this.costPrice &&
          other.segment == this.segment &&
          other.unitMultiplier == this.unitMultiplier &&
          other.createdAt == this.createdAt);
}

class TransactionLinesCompanion extends UpdateCompanion<TransactionLineRow> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String?> productId;
  final Value<String> productNameSnapshot;
  final Value<int> position;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<int> unitPrice;
  final Value<int> costPrice;
  final Value<String> segment;
  final Value<double> unitMultiplier;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TransactionLinesCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.position = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.segment = const Value.absent(),
    this.unitMultiplier = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionLinesCompanion.insert({
    required String id,
    required String transactionId,
    this.productId = const Value.absent(),
    required String productNameSnapshot,
    this.position = const Value.absent(),
    this.quantity = const Value.absent(),
    required String unit,
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    required String segment,
    this.unitMultiplier = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       productNameSnapshot = Value(productNameSnapshot),
       unit = Value(unit),
       segment = Value(segment);
  static Insertable<TransactionLineRow> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<int>? position,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<int>? unitPrice,
    Expression<int>? costPrice,
    Expression<String>? segment,
    Expression<double>? unitMultiplier,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (position != null) 'position': position,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (segment != null) 'segment': segment,
      if (unitMultiplier != null) 'unit_multiplier': unitMultiplier,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<String?>? productId,
    Value<String>? productNameSnapshot,
    Value<int>? position,
    Value<double>? quantity,
    Value<String>? unit,
    Value<int>? unitPrice,
    Value<int>? costPrice,
    Value<String>? segment,
    Value<double>? unitMultiplier,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TransactionLinesCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      position: position ?? this.position,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      segment: segment ?? this.segment,
      unitMultiplier: unitMultiplier ?? this.unitMultiplier,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<int>(costPrice.value);
    }
    if (segment.present) {
      map['segment'] = Variable<String>(segment.value);
    }
    if (unitMultiplier.present) {
      map['unit_multiplier'] = Variable<double>(unitMultiplier.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLinesCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('position: $position, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('segment: $segment, ')
          ..write('unitMultiplier: $unitMultiplier, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessProfilesTable extends BusinessProfiles
    with TableInfo<$BusinessProfilesTable, BusinessProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessCategoryMeta = const VerificationMeta(
    'businessCategory',
  );
  @override
  late final GeneratedColumn<String> businessCategory = GeneratedColumn<String>(
    'business_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessLocationMeta = const VerificationMeta(
    'businessLocation',
  );
  @override
  late final GeneratedColumn<String> businessLocation = GeneratedColumn<String>(
    'business_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberSinceMeta = const VerificationMeta(
    'memberSince',
  );
  @override
  late final GeneratedColumn<String> memberSince = GeneratedColumn<String>(
    'member_since',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerName,
    email,
    phone,
    businessName,
    businessCategory,
    businessLocation,
    memberSince,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('business_category')) {
      context.handle(
        _businessCategoryMeta,
        businessCategory.isAcceptableOrUnknown(
          data['business_category']!,
          _businessCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessCategoryMeta);
    }
    if (data.containsKey('business_location')) {
      context.handle(
        _businessLocationMeta,
        businessLocation.isAcceptableOrUnknown(
          data['business_location']!,
          _businessLocationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessLocationMeta);
    }
    if (data.containsKey('member_since')) {
      context.handle(
        _memberSinceMeta,
        memberSince.isAcceptableOrUnknown(
          data['member_since']!,
          _memberSinceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memberSinceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      businessCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_category'],
      )!,
      businessLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_location'],
      )!,
      memberSince: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_since'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BusinessProfilesTable createAlias(String alias) {
    return $BusinessProfilesTable(attachedDatabase, alias);
  }
}

class BusinessProfileRow extends DataClass
    implements Insertable<BusinessProfileRow> {
  final String id;
  final String ownerName;
  final String email;
  final String phone;
  final String businessName;
  final String businessCategory;
  final String businessLocation;
  final String memberSince;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BusinessProfileRow({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.businessCategory,
    required this.businessLocation,
    required this.memberSince,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['owner_name'] = Variable<String>(ownerName);
    map['email'] = Variable<String>(email);
    map['phone'] = Variable<String>(phone);
    map['business_name'] = Variable<String>(businessName);
    map['business_category'] = Variable<String>(businessCategory);
    map['business_location'] = Variable<String>(businessLocation);
    map['member_since'] = Variable<String>(memberSince);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BusinessProfilesCompanion toCompanion(bool nullToAbsent) {
    return BusinessProfilesCompanion(
      id: Value(id),
      ownerName: Value(ownerName),
      email: Value(email),
      phone: Value(phone),
      businessName: Value(businessName),
      businessCategory: Value(businessCategory),
      businessLocation: Value(businessLocation),
      memberSince: Value(memberSince),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BusinessProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessProfileRow(
      id: serializer.fromJson<String>(json['id']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      email: serializer.fromJson<String>(json['email']),
      phone: serializer.fromJson<String>(json['phone']),
      businessName: serializer.fromJson<String>(json['businessName']),
      businessCategory: serializer.fromJson<String>(json['businessCategory']),
      businessLocation: serializer.fromJson<String>(json['businessLocation']),
      memberSince: serializer.fromJson<String>(json['memberSince']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerName': serializer.toJson<String>(ownerName),
      'email': serializer.toJson<String>(email),
      'phone': serializer.toJson<String>(phone),
      'businessName': serializer.toJson<String>(businessName),
      'businessCategory': serializer.toJson<String>(businessCategory),
      'businessLocation': serializer.toJson<String>(businessLocation),
      'memberSince': serializer.toJson<String>(memberSince),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BusinessProfileRow copyWith({
    String? id,
    String? ownerName,
    String? email,
    String? phone,
    String? businessName,
    String? businessCategory,
    String? businessLocation,
    String? memberSince,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BusinessProfileRow(
    id: id ?? this.id,
    ownerName: ownerName ?? this.ownerName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    businessName: businessName ?? this.businessName,
    businessCategory: businessCategory ?? this.businessCategory,
    businessLocation: businessLocation ?? this.businessLocation,
    memberSince: memberSince ?? this.memberSince,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BusinessProfileRow copyWithCompanion(BusinessProfilesCompanion data) {
    return BusinessProfileRow(
      id: data.id.present ? data.id.value : this.id,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      email: data.email.present ? data.email.value : this.email,
      phone: data.phone.present ? data.phone.value : this.phone,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      businessCategory: data.businessCategory.present
          ? data.businessCategory.value
          : this.businessCategory,
      businessLocation: data.businessLocation.present
          ? data.businessLocation.value
          : this.businessLocation,
      memberSince: data.memberSince.present
          ? data.memberSince.value
          : this.memberSince,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessProfileRow(')
          ..write('id: $id, ')
          ..write('ownerName: $ownerName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('businessName: $businessName, ')
          ..write('businessCategory: $businessCategory, ')
          ..write('businessLocation: $businessLocation, ')
          ..write('memberSince: $memberSince, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerName,
    email,
    phone,
    businessName,
    businessCategory,
    businessLocation,
    memberSince,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessProfileRow &&
          other.id == this.id &&
          other.ownerName == this.ownerName &&
          other.email == this.email &&
          other.phone == this.phone &&
          other.businessName == this.businessName &&
          other.businessCategory == this.businessCategory &&
          other.businessLocation == this.businessLocation &&
          other.memberSince == this.memberSince &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BusinessProfilesCompanion extends UpdateCompanion<BusinessProfileRow> {
  final Value<String> id;
  final Value<String> ownerName;
  final Value<String> email;
  final Value<String> phone;
  final Value<String> businessName;
  final Value<String> businessCategory;
  final Value<String> businessLocation;
  final Value<String> memberSince;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BusinessProfilesCompanion({
    this.id = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.email = const Value.absent(),
    this.phone = const Value.absent(),
    this.businessName = const Value.absent(),
    this.businessCategory = const Value.absent(),
    this.businessLocation = const Value.absent(),
    this.memberSince = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessProfilesCompanion.insert({
    required String id,
    required String ownerName,
    required String email,
    required String phone,
    required String businessName,
    required String businessCategory,
    required String businessLocation,
    required String memberSince,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ownerName = Value(ownerName),
       email = Value(email),
       phone = Value(phone),
       businessName = Value(businessName),
       businessCategory = Value(businessCategory),
       businessLocation = Value(businessLocation),
       memberSince = Value(memberSince);
  static Insertable<BusinessProfileRow> custom({
    Expression<String>? id,
    Expression<String>? ownerName,
    Expression<String>? email,
    Expression<String>? phone,
    Expression<String>? businessName,
    Expression<String>? businessCategory,
    Expression<String>? businessLocation,
    Expression<String>? memberSince,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerName != null) 'owner_name': ownerName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (businessName != null) 'business_name': businessName,
      if (businessCategory != null) 'business_category': businessCategory,
      if (businessLocation != null) 'business_location': businessLocation,
      if (memberSince != null) 'member_since': memberSince,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? ownerName,
    Value<String>? email,
    Value<String>? phone,
    Value<String>? businessName,
    Value<String>? businessCategory,
    Value<String>? businessLocation,
    Value<String>? memberSince,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BusinessProfilesCompanion(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      businessCategory: businessCategory ?? this.businessCategory,
      businessLocation: businessLocation ?? this.businessLocation,
      memberSince: memberSince ?? this.memberSince,
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
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (businessCategory.present) {
      map['business_category'] = Variable<String>(businessCategory.value);
    }
    if (businessLocation.present) {
      map['business_location'] = Variable<String>(businessLocation.value);
    }
    if (memberSince.present) {
      map['member_since'] = Variable<String>(memberSince.value);
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
    return (StringBuffer('BusinessProfilesCompanion(')
          ..write('id: $id, ')
          ..write('ownerName: $ownerName, ')
          ..write('email: $email, ')
          ..write('phone: $phone, ')
          ..write('businessName: $businessName, ')
          ..write('businessCategory: $businessCategory, ')
          ..write('businessLocation: $businessLocation, ')
          ..write('memberSince: $memberSince, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceProductAliasesTable extends VoiceProductAliases
    with TableInfo<$VoiceProductAliasesTable, VoiceProductAliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceProductAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasTextMeta = const VerificationMeta(
    'aliasText',
  );
  @override
  late final GeneratedColumn<String> aliasText = GeneratedColumn<String>(
    'alias_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedAliasMeta = const VerificationMeta(
    'normalizedAlias',
  );
  @override
  late final GeneratedColumn<String> normalizedAlias = GeneratedColumn<String>(
    'normalized_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _canonicalProductNameMeta =
      const VerificationMeta('canonicalProductName');
  @override
  late final GeneratedColumn<String> canonicalProductName =
      GeneratedColumn<String>(
        'canonical_product_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _hitCountMeta = const VerificationMeta(
    'hitCount',
  );
  @override
  late final GeneratedColumn<int> hitCount = GeneratedColumn<int>(
    'hit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aliasText,
    normalizedAlias,
    productId,
    canonicalProductName,
    hitCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_product_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceProductAliasRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alias_text')) {
      context.handle(
        _aliasTextMeta,
        aliasText.isAcceptableOrUnknown(data['alias_text']!, _aliasTextMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasTextMeta);
    }
    if (data.containsKey('normalized_alias')) {
      context.handle(
        _normalizedAliasMeta,
        normalizedAlias.isAcceptableOrUnknown(
          data['normalized_alias']!,
          _normalizedAliasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedAliasMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('canonical_product_name')) {
      context.handle(
        _canonicalProductNameMeta,
        canonicalProductName.isAcceptableOrUnknown(
          data['canonical_product_name']!,
          _canonicalProductNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalProductNameMeta);
    }
    if (data.containsKey('hit_count')) {
      context.handle(
        _hitCountMeta,
        hitCount.isAcceptableOrUnknown(data['hit_count']!, _hitCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedAlias},
  ];
  @override
  VoiceProductAliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceProductAliasRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aliasText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias_text'],
      )!,
      normalizedAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_alias'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      canonicalProductName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_product_name'],
      )!,
      hitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hit_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VoiceProductAliasesTable createAlias(String alias) {
    return $VoiceProductAliasesTable(attachedDatabase, alias);
  }
}

class VoiceProductAliasRow extends DataClass
    implements Insertable<VoiceProductAliasRow> {
  final String id;
  final String aliasText;
  final String normalizedAlias;
  final String? productId;
  final String canonicalProductName;
  final int hitCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VoiceProductAliasRow({
    required this.id,
    required this.aliasText,
    required this.normalizedAlias,
    this.productId,
    required this.canonicalProductName,
    required this.hitCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alias_text'] = Variable<String>(aliasText);
    map['normalized_alias'] = Variable<String>(normalizedAlias);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['canonical_product_name'] = Variable<String>(canonicalProductName);
    map['hit_count'] = Variable<int>(hitCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VoiceProductAliasesCompanion toCompanion(bool nullToAbsent) {
    return VoiceProductAliasesCompanion(
      id: Value(id),
      aliasText: Value(aliasText),
      normalizedAlias: Value(normalizedAlias),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      canonicalProductName: Value(canonicalProductName),
      hitCount: Value(hitCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VoiceProductAliasRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceProductAliasRow(
      id: serializer.fromJson<String>(json['id']),
      aliasText: serializer.fromJson<String>(json['aliasText']),
      normalizedAlias: serializer.fromJson<String>(json['normalizedAlias']),
      productId: serializer.fromJson<String?>(json['productId']),
      canonicalProductName: serializer.fromJson<String>(
        json['canonicalProductName'],
      ),
      hitCount: serializer.fromJson<int>(json['hitCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aliasText': serializer.toJson<String>(aliasText),
      'normalizedAlias': serializer.toJson<String>(normalizedAlias),
      'productId': serializer.toJson<String?>(productId),
      'canonicalProductName': serializer.toJson<String>(canonicalProductName),
      'hitCount': serializer.toJson<int>(hitCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VoiceProductAliasRow copyWith({
    String? id,
    String? aliasText,
    String? normalizedAlias,
    Value<String?> productId = const Value.absent(),
    String? canonicalProductName,
    int? hitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VoiceProductAliasRow(
    id: id ?? this.id,
    aliasText: aliasText ?? this.aliasText,
    normalizedAlias: normalizedAlias ?? this.normalizedAlias,
    productId: productId.present ? productId.value : this.productId,
    canonicalProductName: canonicalProductName ?? this.canonicalProductName,
    hitCount: hitCount ?? this.hitCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VoiceProductAliasRow copyWithCompanion(VoiceProductAliasesCompanion data) {
    return VoiceProductAliasRow(
      id: data.id.present ? data.id.value : this.id,
      aliasText: data.aliasText.present ? data.aliasText.value : this.aliasText,
      normalizedAlias: data.normalizedAlias.present
          ? data.normalizedAlias.value
          : this.normalizedAlias,
      productId: data.productId.present ? data.productId.value : this.productId,
      canonicalProductName: data.canonicalProductName.present
          ? data.canonicalProductName.value
          : this.canonicalProductName,
      hitCount: data.hitCount.present ? data.hitCount.value : this.hitCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceProductAliasRow(')
          ..write('id: $id, ')
          ..write('aliasText: $aliasText, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('productId: $productId, ')
          ..write('canonicalProductName: $canonicalProductName, ')
          ..write('hitCount: $hitCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aliasText,
    normalizedAlias,
    productId,
    canonicalProductName,
    hitCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceProductAliasRow &&
          other.id == this.id &&
          other.aliasText == this.aliasText &&
          other.normalizedAlias == this.normalizedAlias &&
          other.productId == this.productId &&
          other.canonicalProductName == this.canonicalProductName &&
          other.hitCount == this.hitCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VoiceProductAliasesCompanion
    extends UpdateCompanion<VoiceProductAliasRow> {
  final Value<String> id;
  final Value<String> aliasText;
  final Value<String> normalizedAlias;
  final Value<String?> productId;
  final Value<String> canonicalProductName;
  final Value<int> hitCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VoiceProductAliasesCompanion({
    this.id = const Value.absent(),
    this.aliasText = const Value.absent(),
    this.normalizedAlias = const Value.absent(),
    this.productId = const Value.absent(),
    this.canonicalProductName = const Value.absent(),
    this.hitCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceProductAliasesCompanion.insert({
    required String id,
    required String aliasText,
    required String normalizedAlias,
    this.productId = const Value.absent(),
    required String canonicalProductName,
    this.hitCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aliasText = Value(aliasText),
       normalizedAlias = Value(normalizedAlias),
       canonicalProductName = Value(canonicalProductName);
  static Insertable<VoiceProductAliasRow> custom({
    Expression<String>? id,
    Expression<String>? aliasText,
    Expression<String>? normalizedAlias,
    Expression<String>? productId,
    Expression<String>? canonicalProductName,
    Expression<int>? hitCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aliasText != null) 'alias_text': aliasText,
      if (normalizedAlias != null) 'normalized_alias': normalizedAlias,
      if (productId != null) 'product_id': productId,
      if (canonicalProductName != null)
        'canonical_product_name': canonicalProductName,
      if (hitCount != null) 'hit_count': hitCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceProductAliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? aliasText,
    Value<String>? normalizedAlias,
    Value<String?>? productId,
    Value<String>? canonicalProductName,
    Value<int>? hitCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VoiceProductAliasesCompanion(
      id: id ?? this.id,
      aliasText: aliasText ?? this.aliasText,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      productId: productId ?? this.productId,
      canonicalProductName: canonicalProductName ?? this.canonicalProductName,
      hitCount: hitCount ?? this.hitCount,
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
    if (aliasText.present) {
      map['alias_text'] = Variable<String>(aliasText.value);
    }
    if (normalizedAlias.present) {
      map['normalized_alias'] = Variable<String>(normalizedAlias.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (canonicalProductName.present) {
      map['canonical_product_name'] = Variable<String>(
        canonicalProductName.value,
      );
    }
    if (hitCount.present) {
      map['hit_count'] = Variable<int>(hitCount.value);
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
    return (StringBuffer('VoiceProductAliasesCompanion(')
          ..write('id: $id, ')
          ..write('aliasText: $aliasText, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('productId: $productId, ')
          ..write('canonicalProductName: $canonicalProductName, ')
          ..write('hitCount: $hitCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceUnitAliasesTable extends VoiceUnitAliases
    with TableInfo<$VoiceUnitAliasesTable, VoiceUnitAliasRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceUnitAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasTextMeta = const VerificationMeta(
    'aliasText',
  );
  @override
  late final GeneratedColumn<String> aliasText = GeneratedColumn<String>(
    'alias_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedAliasMeta = const VerificationMeta(
    'normalizedAlias',
  );
  @override
  late final GeneratedColumn<String> normalizedAlias = GeneratedColumn<String>(
    'normalized_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalUnitMeta = const VerificationMeta(
    'canonicalUnit',
  );
  @override
  late final GeneratedColumn<String> canonicalUnit = GeneratedColumn<String>(
    'canonical_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hitCountMeta = const VerificationMeta(
    'hitCount',
  );
  @override
  late final GeneratedColumn<int> hitCount = GeneratedColumn<int>(
    'hit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    aliasText,
    normalizedAlias,
    canonicalUnit,
    hitCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_unit_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceUnitAliasRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('alias_text')) {
      context.handle(
        _aliasTextMeta,
        aliasText.isAcceptableOrUnknown(data['alias_text']!, _aliasTextMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasTextMeta);
    }
    if (data.containsKey('normalized_alias')) {
      context.handle(
        _normalizedAliasMeta,
        normalizedAlias.isAcceptableOrUnknown(
          data['normalized_alias']!,
          _normalizedAliasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedAliasMeta);
    }
    if (data.containsKey('canonical_unit')) {
      context.handle(
        _canonicalUnitMeta,
        canonicalUnit.isAcceptableOrUnknown(
          data['canonical_unit']!,
          _canonicalUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalUnitMeta);
    }
    if (data.containsKey('hit_count')) {
      context.handle(
        _hitCountMeta,
        hitCount.isAcceptableOrUnknown(data['hit_count']!, _hitCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedAlias},
  ];
  @override
  VoiceUnitAliasRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceUnitAliasRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      aliasText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias_text'],
      )!,
      normalizedAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_alias'],
      )!,
      canonicalUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_unit'],
      )!,
      hitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hit_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VoiceUnitAliasesTable createAlias(String alias) {
    return $VoiceUnitAliasesTable(attachedDatabase, alias);
  }
}

class VoiceUnitAliasRow extends DataClass
    implements Insertable<VoiceUnitAliasRow> {
  final String id;
  final String aliasText;
  final String normalizedAlias;
  final String canonicalUnit;
  final int hitCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VoiceUnitAliasRow({
    required this.id,
    required this.aliasText,
    required this.normalizedAlias,
    required this.canonicalUnit,
    required this.hitCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['alias_text'] = Variable<String>(aliasText);
    map['normalized_alias'] = Variable<String>(normalizedAlias);
    map['canonical_unit'] = Variable<String>(canonicalUnit);
    map['hit_count'] = Variable<int>(hitCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VoiceUnitAliasesCompanion toCompanion(bool nullToAbsent) {
    return VoiceUnitAliasesCompanion(
      id: Value(id),
      aliasText: Value(aliasText),
      normalizedAlias: Value(normalizedAlias),
      canonicalUnit: Value(canonicalUnit),
      hitCount: Value(hitCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VoiceUnitAliasRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceUnitAliasRow(
      id: serializer.fromJson<String>(json['id']),
      aliasText: serializer.fromJson<String>(json['aliasText']),
      normalizedAlias: serializer.fromJson<String>(json['normalizedAlias']),
      canonicalUnit: serializer.fromJson<String>(json['canonicalUnit']),
      hitCount: serializer.fromJson<int>(json['hitCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'aliasText': serializer.toJson<String>(aliasText),
      'normalizedAlias': serializer.toJson<String>(normalizedAlias),
      'canonicalUnit': serializer.toJson<String>(canonicalUnit),
      'hitCount': serializer.toJson<int>(hitCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VoiceUnitAliasRow copyWith({
    String? id,
    String? aliasText,
    String? normalizedAlias,
    String? canonicalUnit,
    int? hitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VoiceUnitAliasRow(
    id: id ?? this.id,
    aliasText: aliasText ?? this.aliasText,
    normalizedAlias: normalizedAlias ?? this.normalizedAlias,
    canonicalUnit: canonicalUnit ?? this.canonicalUnit,
    hitCount: hitCount ?? this.hitCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VoiceUnitAliasRow copyWithCompanion(VoiceUnitAliasesCompanion data) {
    return VoiceUnitAliasRow(
      id: data.id.present ? data.id.value : this.id,
      aliasText: data.aliasText.present ? data.aliasText.value : this.aliasText,
      normalizedAlias: data.normalizedAlias.present
          ? data.normalizedAlias.value
          : this.normalizedAlias,
      canonicalUnit: data.canonicalUnit.present
          ? data.canonicalUnit.value
          : this.canonicalUnit,
      hitCount: data.hitCount.present ? data.hitCount.value : this.hitCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceUnitAliasRow(')
          ..write('id: $id, ')
          ..write('aliasText: $aliasText, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('canonicalUnit: $canonicalUnit, ')
          ..write('hitCount: $hitCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    aliasText,
    normalizedAlias,
    canonicalUnit,
    hitCount,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceUnitAliasRow &&
          other.id == this.id &&
          other.aliasText == this.aliasText &&
          other.normalizedAlias == this.normalizedAlias &&
          other.canonicalUnit == this.canonicalUnit &&
          other.hitCount == this.hitCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VoiceUnitAliasesCompanion extends UpdateCompanion<VoiceUnitAliasRow> {
  final Value<String> id;
  final Value<String> aliasText;
  final Value<String> normalizedAlias;
  final Value<String> canonicalUnit;
  final Value<int> hitCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VoiceUnitAliasesCompanion({
    this.id = const Value.absent(),
    this.aliasText = const Value.absent(),
    this.normalizedAlias = const Value.absent(),
    this.canonicalUnit = const Value.absent(),
    this.hitCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceUnitAliasesCompanion.insert({
    required String id,
    required String aliasText,
    required String normalizedAlias,
    required String canonicalUnit,
    this.hitCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       aliasText = Value(aliasText),
       normalizedAlias = Value(normalizedAlias),
       canonicalUnit = Value(canonicalUnit);
  static Insertable<VoiceUnitAliasRow> custom({
    Expression<String>? id,
    Expression<String>? aliasText,
    Expression<String>? normalizedAlias,
    Expression<String>? canonicalUnit,
    Expression<int>? hitCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (aliasText != null) 'alias_text': aliasText,
      if (normalizedAlias != null) 'normalized_alias': normalizedAlias,
      if (canonicalUnit != null) 'canonical_unit': canonicalUnit,
      if (hitCount != null) 'hit_count': hitCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceUnitAliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? aliasText,
    Value<String>? normalizedAlias,
    Value<String>? canonicalUnit,
    Value<int>? hitCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VoiceUnitAliasesCompanion(
      id: id ?? this.id,
      aliasText: aliasText ?? this.aliasText,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      canonicalUnit: canonicalUnit ?? this.canonicalUnit,
      hitCount: hitCount ?? this.hitCount,
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
    if (aliasText.present) {
      map['alias_text'] = Variable<String>(aliasText.value);
    }
    if (normalizedAlias.present) {
      map['normalized_alias'] = Variable<String>(normalizedAlias.value);
    }
    if (canonicalUnit.present) {
      map['canonical_unit'] = Variable<String>(canonicalUnit.value);
    }
    if (hitCount.present) {
      map['hit_count'] = Variable<int>(hitCount.value);
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
    return (StringBuffer('VoiceUnitAliasesCompanion(')
          ..write('id: $id, ')
          ..write('aliasText: $aliasText, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('canonicalUnit: $canonicalUnit, ')
          ..write('hitCount: $hitCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceCorrectionsTable extends VoiceCorrections
    with TableInfo<$VoiceCorrectionsTable, VoiceCorrectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceCorrectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedProductNameMeta = const VerificationMeta(
    'parsedProductName',
  );
  @override
  late final GeneratedColumn<String> parsedProductName =
      GeneratedColumn<String>(
        'parsed_product_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _correctedProductNameMeta =
      const VerificationMeta('correctedProductName');
  @override
  late final GeneratedColumn<String> correctedProductName =
      GeneratedColumn<String>(
        'corrected_product_name',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _parsedUnitMeta = const VerificationMeta(
    'parsedUnit',
  );
  @override
  late final GeneratedColumn<String> parsedUnit = GeneratedColumn<String>(
    'parsed_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedUnitMeta = const VerificationMeta(
    'correctedUnit',
  );
  @override
  late final GeneratedColumn<String> correctedUnit = GeneratedColumn<String>(
    'corrected_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedQuantityMeta = const VerificationMeta(
    'parsedQuantity',
  );
  @override
  late final GeneratedColumn<double> parsedQuantity = GeneratedColumn<double>(
    'parsed_quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedQuantityMeta = const VerificationMeta(
    'correctedQuantity',
  );
  @override
  late final GeneratedColumn<double> correctedQuantity =
      GeneratedColumn<double>(
        'corrected_quantity',
        aliasedName,
        false,
        type: DriftSqlType.double,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    parsedProductName,
    correctedProductName,
    parsedUnit,
    correctedUnit,
    parsedQuantity,
    correctedQuantity,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_corrections';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceCorrectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('parsed_product_name')) {
      context.handle(
        _parsedProductNameMeta,
        parsedProductName.isAcceptableOrUnknown(
          data['parsed_product_name']!,
          _parsedProductNameMeta,
        ),
      );
    }
    if (data.containsKey('corrected_product_name')) {
      context.handle(
        _correctedProductNameMeta,
        correctedProductName.isAcceptableOrUnknown(
          data['corrected_product_name']!,
          _correctedProductNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedProductNameMeta);
    }
    if (data.containsKey('parsed_unit')) {
      context.handle(
        _parsedUnitMeta,
        parsedUnit.isAcceptableOrUnknown(data['parsed_unit']!, _parsedUnitMeta),
      );
    }
    if (data.containsKey('corrected_unit')) {
      context.handle(
        _correctedUnitMeta,
        correctedUnit.isAcceptableOrUnknown(
          data['corrected_unit']!,
          _correctedUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedUnitMeta);
    }
    if (data.containsKey('parsed_quantity')) {
      context.handle(
        _parsedQuantityMeta,
        parsedQuantity.isAcceptableOrUnknown(
          data['parsed_quantity']!,
          _parsedQuantityMeta,
        ),
      );
    }
    if (data.containsKey('corrected_quantity')) {
      context.handle(
        _correctedQuantityMeta,
        correctedQuantity.isAcceptableOrUnknown(
          data['corrected_quantity']!,
          _correctedQuantityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedQuantityMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceCorrectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceCorrectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      parsedProductName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_product_name'],
      ),
      correctedProductName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_product_name'],
      )!,
      parsedUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_unit'],
      ),
      correctedUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_unit'],
      )!,
      parsedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}parsed_quantity'],
      ),
      correctedQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}corrected_quantity'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VoiceCorrectionsTable createAlias(String alias) {
    return $VoiceCorrectionsTable(attachedDatabase, alias);
  }
}

class VoiceCorrectionRow extends DataClass
    implements Insertable<VoiceCorrectionRow> {
  final String id;
  final String rawText;
  final String? parsedProductName;
  final String correctedProductName;
  final String? parsedUnit;
  final String correctedUnit;
  final double? parsedQuantity;
  final double correctedQuantity;
  final DateTime createdAt;
  const VoiceCorrectionRow({
    required this.id,
    required this.rawText,
    this.parsedProductName,
    required this.correctedProductName,
    this.parsedUnit,
    required this.correctedUnit,
    this.parsedQuantity,
    required this.correctedQuantity,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || parsedProductName != null) {
      map['parsed_product_name'] = Variable<String>(parsedProductName);
    }
    map['corrected_product_name'] = Variable<String>(correctedProductName);
    if (!nullToAbsent || parsedUnit != null) {
      map['parsed_unit'] = Variable<String>(parsedUnit);
    }
    map['corrected_unit'] = Variable<String>(correctedUnit);
    if (!nullToAbsent || parsedQuantity != null) {
      map['parsed_quantity'] = Variable<double>(parsedQuantity);
    }
    map['corrected_quantity'] = Variable<double>(correctedQuantity);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VoiceCorrectionsCompanion toCompanion(bool nullToAbsent) {
    return VoiceCorrectionsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      parsedProductName: parsedProductName == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedProductName),
      correctedProductName: Value(correctedProductName),
      parsedUnit: parsedUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedUnit),
      correctedUnit: Value(correctedUnit),
      parsedQuantity: parsedQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedQuantity),
      correctedQuantity: Value(correctedQuantity),
      createdAt: Value(createdAt),
    );
  }

  factory VoiceCorrectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceCorrectionRow(
      id: serializer.fromJson<String>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      parsedProductName: serializer.fromJson<String?>(
        json['parsedProductName'],
      ),
      correctedProductName: serializer.fromJson<String>(
        json['correctedProductName'],
      ),
      parsedUnit: serializer.fromJson<String?>(json['parsedUnit']),
      correctedUnit: serializer.fromJson<String>(json['correctedUnit']),
      parsedQuantity: serializer.fromJson<double?>(json['parsedQuantity']),
      correctedQuantity: serializer.fromJson<double>(json['correctedQuantity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawText': serializer.toJson<String>(rawText),
      'parsedProductName': serializer.toJson<String?>(parsedProductName),
      'correctedProductName': serializer.toJson<String>(correctedProductName),
      'parsedUnit': serializer.toJson<String?>(parsedUnit),
      'correctedUnit': serializer.toJson<String>(correctedUnit),
      'parsedQuantity': serializer.toJson<double?>(parsedQuantity),
      'correctedQuantity': serializer.toJson<double>(correctedQuantity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VoiceCorrectionRow copyWith({
    String? id,
    String? rawText,
    Value<String?> parsedProductName = const Value.absent(),
    String? correctedProductName,
    Value<String?> parsedUnit = const Value.absent(),
    String? correctedUnit,
    Value<double?> parsedQuantity = const Value.absent(),
    double? correctedQuantity,
    DateTime? createdAt,
  }) => VoiceCorrectionRow(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    parsedProductName: parsedProductName.present
        ? parsedProductName.value
        : this.parsedProductName,
    correctedProductName: correctedProductName ?? this.correctedProductName,
    parsedUnit: parsedUnit.present ? parsedUnit.value : this.parsedUnit,
    correctedUnit: correctedUnit ?? this.correctedUnit,
    parsedQuantity: parsedQuantity.present
        ? parsedQuantity.value
        : this.parsedQuantity,
    correctedQuantity: correctedQuantity ?? this.correctedQuantity,
    createdAt: createdAt ?? this.createdAt,
  );
  VoiceCorrectionRow copyWithCompanion(VoiceCorrectionsCompanion data) {
    return VoiceCorrectionRow(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      parsedProductName: data.parsedProductName.present
          ? data.parsedProductName.value
          : this.parsedProductName,
      correctedProductName: data.correctedProductName.present
          ? data.correctedProductName.value
          : this.correctedProductName,
      parsedUnit: data.parsedUnit.present
          ? data.parsedUnit.value
          : this.parsedUnit,
      correctedUnit: data.correctedUnit.present
          ? data.correctedUnit.value
          : this.correctedUnit,
      parsedQuantity: data.parsedQuantity.present
          ? data.parsedQuantity.value
          : this.parsedQuantity,
      correctedQuantity: data.correctedQuantity.present
          ? data.correctedQuantity.value
          : this.correctedQuantity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceCorrectionRow(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('parsedProductName: $parsedProductName, ')
          ..write('correctedProductName: $correctedProductName, ')
          ..write('parsedUnit: $parsedUnit, ')
          ..write('correctedUnit: $correctedUnit, ')
          ..write('parsedQuantity: $parsedQuantity, ')
          ..write('correctedQuantity: $correctedQuantity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    parsedProductName,
    correctedProductName,
    parsedUnit,
    correctedUnit,
    parsedQuantity,
    correctedQuantity,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceCorrectionRow &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.parsedProductName == this.parsedProductName &&
          other.correctedProductName == this.correctedProductName &&
          other.parsedUnit == this.parsedUnit &&
          other.correctedUnit == this.correctedUnit &&
          other.parsedQuantity == this.parsedQuantity &&
          other.correctedQuantity == this.correctedQuantity &&
          other.createdAt == this.createdAt);
}

class VoiceCorrectionsCompanion extends UpdateCompanion<VoiceCorrectionRow> {
  final Value<String> id;
  final Value<String> rawText;
  final Value<String?> parsedProductName;
  final Value<String> correctedProductName;
  final Value<String?> parsedUnit;
  final Value<String> correctedUnit;
  final Value<double?> parsedQuantity;
  final Value<double> correctedQuantity;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VoiceCorrectionsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.parsedProductName = const Value.absent(),
    this.correctedProductName = const Value.absent(),
    this.parsedUnit = const Value.absent(),
    this.correctedUnit = const Value.absent(),
    this.parsedQuantity = const Value.absent(),
    this.correctedQuantity = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceCorrectionsCompanion.insert({
    required String id,
    required String rawText,
    this.parsedProductName = const Value.absent(),
    required String correctedProductName,
    this.parsedUnit = const Value.absent(),
    required String correctedUnit,
    this.parsedQuantity = const Value.absent(),
    required double correctedQuantity,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawText = Value(rawText),
       correctedProductName = Value(correctedProductName),
       correctedUnit = Value(correctedUnit),
       correctedQuantity = Value(correctedQuantity);
  static Insertable<VoiceCorrectionRow> custom({
    Expression<String>? id,
    Expression<String>? rawText,
    Expression<String>? parsedProductName,
    Expression<String>? correctedProductName,
    Expression<String>? parsedUnit,
    Expression<String>? correctedUnit,
    Expression<double>? parsedQuantity,
    Expression<double>? correctedQuantity,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (parsedProductName != null) 'parsed_product_name': parsedProductName,
      if (correctedProductName != null)
        'corrected_product_name': correctedProductName,
      if (parsedUnit != null) 'parsed_unit': parsedUnit,
      if (correctedUnit != null) 'corrected_unit': correctedUnit,
      if (parsedQuantity != null) 'parsed_quantity': parsedQuantity,
      if (correctedQuantity != null) 'corrected_quantity': correctedQuantity,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceCorrectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawText,
    Value<String?>? parsedProductName,
    Value<String>? correctedProductName,
    Value<String?>? parsedUnit,
    Value<String>? correctedUnit,
    Value<double?>? parsedQuantity,
    Value<double>? correctedQuantity,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VoiceCorrectionsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      parsedProductName: parsedProductName ?? this.parsedProductName,
      correctedProductName: correctedProductName ?? this.correctedProductName,
      parsedUnit: parsedUnit ?? this.parsedUnit,
      correctedUnit: correctedUnit ?? this.correctedUnit,
      parsedQuantity: parsedQuantity ?? this.parsedQuantity,
      correctedQuantity: correctedQuantity ?? this.correctedQuantity,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (parsedProductName.present) {
      map['parsed_product_name'] = Variable<String>(parsedProductName.value);
    }
    if (correctedProductName.present) {
      map['corrected_product_name'] = Variable<String>(
        correctedProductName.value,
      );
    }
    if (parsedUnit.present) {
      map['parsed_unit'] = Variable<String>(parsedUnit.value);
    }
    if (correctedUnit.present) {
      map['corrected_unit'] = Variable<String>(correctedUnit.value);
    }
    if (parsedQuantity.present) {
      map['parsed_quantity'] = Variable<double>(parsedQuantity.value);
    }
    if (correctedQuantity.present) {
      map['corrected_quantity'] = Variable<double>(correctedQuantity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceCorrectionsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('parsedProductName: $parsedProductName, ')
          ..write('correctedProductName: $correctedProductName, ')
          ..write('parsedUnit: $parsedUnit, ')
          ..write('correctedUnit: $correctedUnit, ')
          ..write('parsedQuantity: $parsedQuantity, ')
          ..write('correctedQuantity: $correctedQuantity, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceActionAuditsTable extends VoiceActionAudits
    with TableInfo<$VoiceActionAuditsTable, VoiceActionAuditRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceActionAuditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetEntityTypeMeta = const VerificationMeta(
    'targetEntityType',
  );
  @override
  late final GeneratedColumn<String> targetEntityType = GeneratedColumn<String>(
    'target_entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetEntityIdMeta = const VerificationMeta(
    'targetEntityId',
  );
  @override
  late final GeneratedColumn<String> targetEntityId = GeneratedColumn<String>(
    'target_entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beforeSummaryMeta = const VerificationMeta(
    'beforeSummary',
  );
  @override
  late final GeneratedColumn<String> beforeSummary = GeneratedColumn<String>(
    'before_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _afterSummaryMeta = const VerificationMeta(
    'afterSummary',
  );
  @override
  late final GeneratedColumn<String> afterSummary = GeneratedColumn<String>(
    'after_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _confirmedMeta = const VerificationMeta(
    'confirmed',
  );
  @override
  late final GeneratedColumn<bool> confirmed = GeneratedColumn<bool>(
    'confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authRequiredMeta = const VerificationMeta(
    'authRequired',
  );
  @override
  late final GeneratedColumn<bool> authRequired = GeneratedColumn<bool>(
    'auth_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auth_required" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authSucceededMeta = const VerificationMeta(
    'authSucceeded',
  );
  @override
  late final GeneratedColumn<bool> authSucceeded = GeneratedColumn<bool>(
    'auth_succeeded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auth_succeeded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _undoStatusMeta = const VerificationMeta(
    'undoStatus',
  );
  @override
  late final GeneratedColumn<String> undoStatus = GeneratedColumn<String>(
    'undo_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('notAvailable'),
  );
  static const VerificationMeta _commandFingerprintMeta =
      const VerificationMeta('commandFingerprint');
  @override
  late final GeneratedColumn<String> commandFingerprint =
      GeneratedColumn<String>(
        'command_fingerprint',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionId,
    actionType,
    source,
    status,
    targetEntityType,
    targetEntityId,
    beforeSummary,
    afterSummary,
    confirmed,
    authRequired,
    authSucceeded,
    errorCode,
    undoStatus,
    commandFingerprint,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_action_audits';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceActionAuditRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('target_entity_type')) {
      context.handle(
        _targetEntityTypeMeta,
        targetEntityType.isAcceptableOrUnknown(
          data['target_entity_type']!,
          _targetEntityTypeMeta,
        ),
      );
    }
    if (data.containsKey('target_entity_id')) {
      context.handle(
        _targetEntityIdMeta,
        targetEntityId.isAcceptableOrUnknown(
          data['target_entity_id']!,
          _targetEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('before_summary')) {
      context.handle(
        _beforeSummaryMeta,
        beforeSummary.isAcceptableOrUnknown(
          data['before_summary']!,
          _beforeSummaryMeta,
        ),
      );
    }
    if (data.containsKey('after_summary')) {
      context.handle(
        _afterSummaryMeta,
        afterSummary.isAcceptableOrUnknown(
          data['after_summary']!,
          _afterSummaryMeta,
        ),
      );
    }
    if (data.containsKey('confirmed')) {
      context.handle(
        _confirmedMeta,
        confirmed.isAcceptableOrUnknown(data['confirmed']!, _confirmedMeta),
      );
    }
    if (data.containsKey('auth_required')) {
      context.handle(
        _authRequiredMeta,
        authRequired.isAcceptableOrUnknown(
          data['auth_required']!,
          _authRequiredMeta,
        ),
      );
    }
    if (data.containsKey('auth_succeeded')) {
      context.handle(
        _authSucceededMeta,
        authSucceeded.isAcceptableOrUnknown(
          data['auth_succeeded']!,
          _authSucceededMeta,
        ),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('undo_status')) {
      context.handle(
        _undoStatusMeta,
        undoStatus.isAcceptableOrUnknown(data['undo_status']!, _undoStatusMeta),
      );
    }
    if (data.containsKey('command_fingerprint')) {
      context.handle(
        _commandFingerprintMeta,
        commandFingerprint.isAcceptableOrUnknown(
          data['command_fingerprint']!,
          _commandFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commandFingerprintMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {actionId, status},
  ];
  @override
  VoiceActionAuditRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceActionAuditRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_id'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      targetEntityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_entity_type'],
      ),
      targetEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_entity_id'],
      ),
      beforeSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_summary'],
      )!,
      afterSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_summary'],
      )!,
      confirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirmed'],
      )!,
      authRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auth_required'],
      )!,
      authSucceeded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auth_succeeded'],
      )!,
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      undoStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}undo_status'],
      )!,
      commandFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}command_fingerprint'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VoiceActionAuditsTable createAlias(String alias) {
    return $VoiceActionAuditsTable(attachedDatabase, alias);
  }
}

class VoiceActionAuditRow extends DataClass
    implements Insertable<VoiceActionAuditRow> {
  final String id;
  final String actionId;
  final String actionType;
  final String source;
  final String status;
  final String? targetEntityType;
  final String? targetEntityId;
  final String beforeSummary;
  final String afterSummary;
  final bool confirmed;
  final bool authRequired;
  final bool authSucceeded;
  final String? errorCode;
  final String undoStatus;
  final String commandFingerprint;
  final DateTime createdAt;
  const VoiceActionAuditRow({
    required this.id,
    required this.actionId,
    required this.actionType,
    required this.source,
    required this.status,
    this.targetEntityType,
    this.targetEntityId,
    required this.beforeSummary,
    required this.afterSummary,
    required this.confirmed,
    required this.authRequired,
    required this.authSucceeded,
    this.errorCode,
    required this.undoStatus,
    required this.commandFingerprint,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['action_id'] = Variable<String>(actionId);
    map['action_type'] = Variable<String>(actionType);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || targetEntityType != null) {
      map['target_entity_type'] = Variable<String>(targetEntityType);
    }
    if (!nullToAbsent || targetEntityId != null) {
      map['target_entity_id'] = Variable<String>(targetEntityId);
    }
    map['before_summary'] = Variable<String>(beforeSummary);
    map['after_summary'] = Variable<String>(afterSummary);
    map['confirmed'] = Variable<bool>(confirmed);
    map['auth_required'] = Variable<bool>(authRequired);
    map['auth_succeeded'] = Variable<bool>(authSucceeded);
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['undo_status'] = Variable<String>(undoStatus);
    map['command_fingerprint'] = Variable<String>(commandFingerprint);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VoiceActionAuditsCompanion toCompanion(bool nullToAbsent) {
    return VoiceActionAuditsCompanion(
      id: Value(id),
      actionId: Value(actionId),
      actionType: Value(actionType),
      source: Value(source),
      status: Value(status),
      targetEntityType: targetEntityType == null && nullToAbsent
          ? const Value.absent()
          : Value(targetEntityType),
      targetEntityId: targetEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetEntityId),
      beforeSummary: Value(beforeSummary),
      afterSummary: Value(afterSummary),
      confirmed: Value(confirmed),
      authRequired: Value(authRequired),
      authSucceeded: Value(authSucceeded),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      undoStatus: Value(undoStatus),
      commandFingerprint: Value(commandFingerprint),
      createdAt: Value(createdAt),
    );
  }

  factory VoiceActionAuditRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceActionAuditRow(
      id: serializer.fromJson<String>(json['id']),
      actionId: serializer.fromJson<String>(json['actionId']),
      actionType: serializer.fromJson<String>(json['actionType']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      targetEntityType: serializer.fromJson<String?>(json['targetEntityType']),
      targetEntityId: serializer.fromJson<String?>(json['targetEntityId']),
      beforeSummary: serializer.fromJson<String>(json['beforeSummary']),
      afterSummary: serializer.fromJson<String>(json['afterSummary']),
      confirmed: serializer.fromJson<bool>(json['confirmed']),
      authRequired: serializer.fromJson<bool>(json['authRequired']),
      authSucceeded: serializer.fromJson<bool>(json['authSucceeded']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      undoStatus: serializer.fromJson<String>(json['undoStatus']),
      commandFingerprint: serializer.fromJson<String>(
        json['commandFingerprint'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionId': serializer.toJson<String>(actionId),
      'actionType': serializer.toJson<String>(actionType),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'targetEntityType': serializer.toJson<String?>(targetEntityType),
      'targetEntityId': serializer.toJson<String?>(targetEntityId),
      'beforeSummary': serializer.toJson<String>(beforeSummary),
      'afterSummary': serializer.toJson<String>(afterSummary),
      'confirmed': serializer.toJson<bool>(confirmed),
      'authRequired': serializer.toJson<bool>(authRequired),
      'authSucceeded': serializer.toJson<bool>(authSucceeded),
      'errorCode': serializer.toJson<String?>(errorCode),
      'undoStatus': serializer.toJson<String>(undoStatus),
      'commandFingerprint': serializer.toJson<String>(commandFingerprint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VoiceActionAuditRow copyWith({
    String? id,
    String? actionId,
    String? actionType,
    String? source,
    String? status,
    Value<String?> targetEntityType = const Value.absent(),
    Value<String?> targetEntityId = const Value.absent(),
    String? beforeSummary,
    String? afterSummary,
    bool? confirmed,
    bool? authRequired,
    bool? authSucceeded,
    Value<String?> errorCode = const Value.absent(),
    String? undoStatus,
    String? commandFingerprint,
    DateTime? createdAt,
  }) => VoiceActionAuditRow(
    id: id ?? this.id,
    actionId: actionId ?? this.actionId,
    actionType: actionType ?? this.actionType,
    source: source ?? this.source,
    status: status ?? this.status,
    targetEntityType: targetEntityType.present
        ? targetEntityType.value
        : this.targetEntityType,
    targetEntityId: targetEntityId.present
        ? targetEntityId.value
        : this.targetEntityId,
    beforeSummary: beforeSummary ?? this.beforeSummary,
    afterSummary: afterSummary ?? this.afterSummary,
    confirmed: confirmed ?? this.confirmed,
    authRequired: authRequired ?? this.authRequired,
    authSucceeded: authSucceeded ?? this.authSucceeded,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    undoStatus: undoStatus ?? this.undoStatus,
    commandFingerprint: commandFingerprint ?? this.commandFingerprint,
    createdAt: createdAt ?? this.createdAt,
  );
  VoiceActionAuditRow copyWithCompanion(VoiceActionAuditsCompanion data) {
    return VoiceActionAuditRow(
      id: data.id.present ? data.id.value : this.id,
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      targetEntityType: data.targetEntityType.present
          ? data.targetEntityType.value
          : this.targetEntityType,
      targetEntityId: data.targetEntityId.present
          ? data.targetEntityId.value
          : this.targetEntityId,
      beforeSummary: data.beforeSummary.present
          ? data.beforeSummary.value
          : this.beforeSummary,
      afterSummary: data.afterSummary.present
          ? data.afterSummary.value
          : this.afterSummary,
      confirmed: data.confirmed.present ? data.confirmed.value : this.confirmed,
      authRequired: data.authRequired.present
          ? data.authRequired.value
          : this.authRequired,
      authSucceeded: data.authSucceeded.present
          ? data.authSucceeded.value
          : this.authSucceeded,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      undoStatus: data.undoStatus.present
          ? data.undoStatus.value
          : this.undoStatus,
      commandFingerprint: data.commandFingerprint.present
          ? data.commandFingerprint.value
          : this.commandFingerprint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceActionAuditRow(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('actionType: $actionType, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('targetEntityType: $targetEntityType, ')
          ..write('targetEntityId: $targetEntityId, ')
          ..write('beforeSummary: $beforeSummary, ')
          ..write('afterSummary: $afterSummary, ')
          ..write('confirmed: $confirmed, ')
          ..write('authRequired: $authRequired, ')
          ..write('authSucceeded: $authSucceeded, ')
          ..write('errorCode: $errorCode, ')
          ..write('undoStatus: $undoStatus, ')
          ..write('commandFingerprint: $commandFingerprint, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionId,
    actionType,
    source,
    status,
    targetEntityType,
    targetEntityId,
    beforeSummary,
    afterSummary,
    confirmed,
    authRequired,
    authSucceeded,
    errorCode,
    undoStatus,
    commandFingerprint,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceActionAuditRow &&
          other.id == this.id &&
          other.actionId == this.actionId &&
          other.actionType == this.actionType &&
          other.source == this.source &&
          other.status == this.status &&
          other.targetEntityType == this.targetEntityType &&
          other.targetEntityId == this.targetEntityId &&
          other.beforeSummary == this.beforeSummary &&
          other.afterSummary == this.afterSummary &&
          other.confirmed == this.confirmed &&
          other.authRequired == this.authRequired &&
          other.authSucceeded == this.authSucceeded &&
          other.errorCode == this.errorCode &&
          other.undoStatus == this.undoStatus &&
          other.commandFingerprint == this.commandFingerprint &&
          other.createdAt == this.createdAt);
}

class VoiceActionAuditsCompanion extends UpdateCompanion<VoiceActionAuditRow> {
  final Value<String> id;
  final Value<String> actionId;
  final Value<String> actionType;
  final Value<String> source;
  final Value<String> status;
  final Value<String?> targetEntityType;
  final Value<String?> targetEntityId;
  final Value<String> beforeSummary;
  final Value<String> afterSummary;
  final Value<bool> confirmed;
  final Value<bool> authRequired;
  final Value<bool> authSucceeded;
  final Value<String?> errorCode;
  final Value<String> undoStatus;
  final Value<String> commandFingerprint;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VoiceActionAuditsCompanion({
    this.id = const Value.absent(),
    this.actionId = const Value.absent(),
    this.actionType = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.targetEntityType = const Value.absent(),
    this.targetEntityId = const Value.absent(),
    this.beforeSummary = const Value.absent(),
    this.afterSummary = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.authRequired = const Value.absent(),
    this.authSucceeded = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.undoStatus = const Value.absent(),
    this.commandFingerprint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceActionAuditsCompanion.insert({
    required String id,
    required String actionId,
    required String actionType,
    required String source,
    required String status,
    this.targetEntityType = const Value.absent(),
    this.targetEntityId = const Value.absent(),
    this.beforeSummary = const Value.absent(),
    this.afterSummary = const Value.absent(),
    this.confirmed = const Value.absent(),
    this.authRequired = const Value.absent(),
    this.authSucceeded = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.undoStatus = const Value.absent(),
    required String commandFingerprint,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionId = Value(actionId),
       actionType = Value(actionType),
       source = Value(source),
       status = Value(status),
       commandFingerprint = Value(commandFingerprint);
  static Insertable<VoiceActionAuditRow> custom({
    Expression<String>? id,
    Expression<String>? actionId,
    Expression<String>? actionType,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? targetEntityType,
    Expression<String>? targetEntityId,
    Expression<String>? beforeSummary,
    Expression<String>? afterSummary,
    Expression<bool>? confirmed,
    Expression<bool>? authRequired,
    Expression<bool>? authSucceeded,
    Expression<String>? errorCode,
    Expression<String>? undoStatus,
    Expression<String>? commandFingerprint,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionId != null) 'action_id': actionId,
      if (actionType != null) 'action_type': actionType,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (targetEntityType != null) 'target_entity_type': targetEntityType,
      if (targetEntityId != null) 'target_entity_id': targetEntityId,
      if (beforeSummary != null) 'before_summary': beforeSummary,
      if (afterSummary != null) 'after_summary': afterSummary,
      if (confirmed != null) 'confirmed': confirmed,
      if (authRequired != null) 'auth_required': authRequired,
      if (authSucceeded != null) 'auth_succeeded': authSucceeded,
      if (errorCode != null) 'error_code': errorCode,
      if (undoStatus != null) 'undo_status': undoStatus,
      if (commandFingerprint != null) 'command_fingerprint': commandFingerprint,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceActionAuditsCompanion copyWith({
    Value<String>? id,
    Value<String>? actionId,
    Value<String>? actionType,
    Value<String>? source,
    Value<String>? status,
    Value<String?>? targetEntityType,
    Value<String?>? targetEntityId,
    Value<String>? beforeSummary,
    Value<String>? afterSummary,
    Value<bool>? confirmed,
    Value<bool>? authRequired,
    Value<bool>? authSucceeded,
    Value<String?>? errorCode,
    Value<String>? undoStatus,
    Value<String>? commandFingerprint,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VoiceActionAuditsCompanion(
      id: id ?? this.id,
      actionId: actionId ?? this.actionId,
      actionType: actionType ?? this.actionType,
      source: source ?? this.source,
      status: status ?? this.status,
      targetEntityType: targetEntityType ?? this.targetEntityType,
      targetEntityId: targetEntityId ?? this.targetEntityId,
      beforeSummary: beforeSummary ?? this.beforeSummary,
      afterSummary: afterSummary ?? this.afterSummary,
      confirmed: confirmed ?? this.confirmed,
      authRequired: authRequired ?? this.authRequired,
      authSucceeded: authSucceeded ?? this.authSucceeded,
      errorCode: errorCode ?? this.errorCode,
      undoStatus: undoStatus ?? this.undoStatus,
      commandFingerprint: commandFingerprint ?? this.commandFingerprint,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (targetEntityType.present) {
      map['target_entity_type'] = Variable<String>(targetEntityType.value);
    }
    if (targetEntityId.present) {
      map['target_entity_id'] = Variable<String>(targetEntityId.value);
    }
    if (beforeSummary.present) {
      map['before_summary'] = Variable<String>(beforeSummary.value);
    }
    if (afterSummary.present) {
      map['after_summary'] = Variable<String>(afterSummary.value);
    }
    if (confirmed.present) {
      map['confirmed'] = Variable<bool>(confirmed.value);
    }
    if (authRequired.present) {
      map['auth_required'] = Variable<bool>(authRequired.value);
    }
    if (authSucceeded.present) {
      map['auth_succeeded'] = Variable<bool>(authSucceeded.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (undoStatus.present) {
      map['undo_status'] = Variable<String>(undoStatus.value);
    }
    if (commandFingerprint.present) {
      map['command_fingerprint'] = Variable<String>(commandFingerprint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceActionAuditsCompanion(')
          ..write('id: $id, ')
          ..write('actionId: $actionId, ')
          ..write('actionType: $actionType, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('targetEntityType: $targetEntityType, ')
          ..write('targetEntityId: $targetEntityId, ')
          ..write('beforeSummary: $beforeSummary, ')
          ..write('afterSummary: $afterSummary, ')
          ..write('confirmed: $confirmed, ')
          ..write('authRequired: $authRequired, ')
          ..write('authSucceeded: $authSucceeded, ')
          ..write('errorCode: $errorCode, ')
          ..write('undoStatus: $undoStatus, ')
          ..write('commandFingerprint: $commandFingerprint, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductCategoriesTable productCategories =
      $ProductCategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $TransactionCategoriesTable transactionCategories =
      $TransactionCategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $TransactionLinesTable transactionLines = $TransactionLinesTable(
    this,
  );
  late final $BusinessProfilesTable businessProfiles = $BusinessProfilesTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $VoiceProductAliasesTable voiceProductAliases =
      $VoiceProductAliasesTable(this);
  late final $VoiceUnitAliasesTable voiceUnitAliases = $VoiceUnitAliasesTable(
    this,
  );
  late final $VoiceCorrectionsTable voiceCorrections = $VoiceCorrectionsTable(
    this,
  );
  late final $VoiceActionAuditsTable voiceActionAudits =
      $VoiceActionAuditsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productCategories,
    products,
    wallets,
    transactionCategories,
    transactions,
    transactionLines,
    businessProfiles,
    appSettings,
    voiceProductAliases,
    voiceUnitAliases,
    voiceCorrections,
    voiceActionAudits,
  ];
}

typedef $$ProductCategoriesTableCreateCompanionBuilder =
    ProductCategoriesCompanion Function({
      required String id,
      required String name,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$ProductCategoriesTableUpdateCompanionBuilder =
    ProductCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$ProductCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ProductCategoriesTable,
          ProductCategoryRow
        > {
  $$ProductCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProductsTable, List<ProductRow>>
  _productsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: $_aliasNameGenerator(
      db.productCategories.id,
      db.products.categoryId,
    ),
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductCategoriesTable> {
  $$ProductCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductCategoriesTable> {
  $$ProductCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductCategoriesTable> {
  $$ProductCategoriesTableAnnotationComposer({
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

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductCategoriesTable,
          ProductCategoryRow,
          $$ProductCategoriesTableFilterComposer,
          $$ProductCategoriesTableOrderingComposer,
          $$ProductCategoriesTableAnnotationComposer,
          $$ProductCategoriesTableCreateCompanionBuilder,
          $$ProductCategoriesTableUpdateCompanionBuilder,
          (ProductCategoryRow, $$ProductCategoriesTableReferences),
          ProductCategoryRow,
          PrefetchHooks Function({bool productsRefs})
        > {
  $$ProductCategoriesTableTableManager(
    _$AppDatabase db,
    $ProductCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCategoriesCompanion(
                id: id,
                name: name,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCategoriesCompanion.insert(
                id: id,
                name: name,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<
                      ProductCategoryRow,
                      $ProductCategoriesTable,
                      ProductRow
                    >(
                      currentTable: table,
                      referencedTable: $$ProductCategoriesTableReferences
                          ._productsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProductCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).productsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProductCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductCategoriesTable,
      ProductCategoryRow,
      $$ProductCategoriesTableFilterComposer,
      $$ProductCategoriesTableOrderingComposer,
      $$ProductCategoriesTableAnnotationComposer,
      $$ProductCategoriesTableCreateCompanionBuilder,
      $$ProductCategoriesTableUpdateCompanionBuilder,
      (ProductCategoryRow, $$ProductCategoriesTableReferences),
      ProductCategoryRow,
      PrefetchHooks Function({bool productsRefs})
    >;
typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> categoryId,
      Value<String> categoryNameSnapshot,
      Value<int> costPrice,
      Value<int> retailPrice,
      Value<int> wholesalePrice,
      Value<int> packSize,
      Value<int> cartonSize,
      Value<double> stockPcs,
      Value<bool> trackStock,
      Value<String> baseUnit,
      Value<double> minStock,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> categoryId,
      Value<String> categoryNameSnapshot,
      Value<int> costPrice,
      Value<int> retailPrice,
      Value<int> wholesalePrice,
      Value<int> packSize,
      Value<int> cartonSize,
      Value<double> stockPcs,
      Value<bool> trackStock,
      Value<String> baseUnit,
      Value<double> minStock,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, ProductRow> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.productCategories.createAlias(
        $_aliasNameGenerator(db.products.categoryId, db.productCategories.id),
      );

  $$ProductCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$ProductCategoriesTableTableManager(
      $_db,
      $_db.productCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLineRow>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(
      db.products.id,
      db.transactionLines.productId,
    ),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $VoiceProductAliasesTable,
    List<VoiceProductAliasRow>
  >
  _voiceProductAliasesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.voiceProductAliases,
        aliasName: $_aliasNameGenerator(
          db.products.id,
          db.voiceProductAliases.productId,
        ),
      );

  $$VoiceProductAliasesTableProcessedTableManager get voiceProductAliasesRefs {
    final manager = $$VoiceProductAliasesTableTableManager(
      $_db,
      $_db.voiceProductAliases,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _voiceProductAliasesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cartonSize => $composableBuilder(
    column: $table.cartonSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stockPcs => $composableBuilder(
    column: $table.stockPcs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductCategoriesTableFilterComposer get categoryId {
    final $$ProductCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.productCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.productCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> voiceProductAliasesRefs(
    Expression<bool> Function($$VoiceProductAliasesTableFilterComposer f) f,
  ) {
    final $$VoiceProductAliasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.voiceProductAliases,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VoiceProductAliasesTableFilterComposer(
            $db: $db,
            $table: $db.voiceProductAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get packSize => $composableBuilder(
    column: $table.packSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cartonSize => $composableBuilder(
    column: $table.cartonSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stockPcs => $composableBuilder(
    column: $table.stockPcs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUnit => $composableBuilder(
    column: $table.baseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductCategoriesTableOrderingComposer get categoryId {
    final $$ProductCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.productCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.productCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wholesalePrice => $composableBuilder(
    column: $table.wholesalePrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get packSize =>
      $composableBuilder(column: $table.packSize, builder: (column) => column);

  GeneratedColumn<int> get cartonSize => $composableBuilder(
    column: $table.cartonSize,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stockPcs =>
      $composableBuilder(column: $table.stockPcs, builder: (column) => column);

  GeneratedColumn<bool> get trackStock => $composableBuilder(
    column: $table.trackStock,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseUnit =>
      $composableBuilder(column: $table.baseUnit, builder: (column) => column);

  GeneratedColumn<double> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$ProductCategoriesTableAnnotationComposer get categoryId {
    final $$ProductCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.productCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ProductCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.productCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> voiceProductAliasesRefs<T extends Object>(
    Expression<T> Function($$VoiceProductAliasesTableAnnotationComposer a) f,
  ) {
    final $$VoiceProductAliasesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.voiceProductAliases,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VoiceProductAliasesTableAnnotationComposer(
                $db: $db,
                $table: $db.voiceProductAliases,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          ProductRow,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (ProductRow, $$ProductsTableReferences),
          ProductRow,
          PrefetchHooks Function({
            bool categoryId,
            bool transactionLinesRefs,
            bool voiceProductAliasesRefs,
          })
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryNameSnapshot = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<int> retailPrice = const Value.absent(),
                Value<int> wholesalePrice = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<int> cartonSize = const Value.absent(),
                Value<double> stockPcs = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<String> baseUnit = const Value.absent(),
                Value<double> minStock = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                categoryNameSnapshot: categoryNameSnapshot,
                costPrice: costPrice,
                retailPrice: retailPrice,
                wholesalePrice: wholesalePrice,
                packSize: packSize,
                cartonSize: cartonSize,
                stockPcs: stockPcs,
                trackStock: trackStock,
                baseUnit: baseUnit,
                minStock: minStock,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryNameSnapshot = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<int> retailPrice = const Value.absent(),
                Value<int> wholesalePrice = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<int> cartonSize = const Value.absent(),
                Value<double> stockPcs = const Value.absent(),
                Value<bool> trackStock = const Value.absent(),
                Value<String> baseUnit = const Value.absent(),
                Value<double> minStock = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                categoryNameSnapshot: categoryNameSnapshot,
                costPrice: costPrice,
                retailPrice: retailPrice,
                wholesalePrice: wholesalePrice,
                packSize: packSize,
                cartonSize: cartonSize,
                stockPcs: stockPcs,
                trackStock: trackStock,
                baseUnit: baseUnit,
                minStock: minStock,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                transactionLinesRefs = false,
                voiceProductAliasesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionLinesRefs) db.transactionLines,
                    if (voiceProductAliasesRefs) db.voiceProductAliases,
                  ],
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ProductsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ProductsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionLinesRefs)
                        await $_getPrefetchedData<
                          ProductRow,
                          $ProductsTable,
                          TransactionLineRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._transactionLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (voiceProductAliasesRefs)
                        await $_getPrefetchedData<
                          ProductRow,
                          $ProductsTable,
                          VoiceProductAliasRow
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._voiceProductAliasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).voiceProductAliasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      ProductRow,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (ProductRow, $$ProductsTableReferences),
      ProductRow,
      PrefetchHooks Function({
        bool categoryId,
        bool transactionLinesRefs,
        bool voiceProductAliasesRefs,
      })
    >;
typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      required String id,
      required String name,
      Value<int> balance,
      Value<bool> isPrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> balance,
      Value<bool> isPrimary,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$WalletsTableReferences
    extends BaseReferences<_$AppDatabase, $WalletsTable, WalletRow> {
  $$WalletsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.wallets.id, db.transactions.walletId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.walletId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
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

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.walletId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          WalletRow,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (WalletRow, $$WalletsTableReferences),
          WalletRow,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                balance: balance,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> balance = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                balance: balance,
                isPrimary: isPrimary,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WalletsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      WalletRow,
                      $WalletsTable,
                      TransactionRow
                    >(
                      currentTable: table,
                      referencedTable: $$WalletsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WalletsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.walletId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      WalletRow,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (WalletRow, $$WalletsTableReferences),
      WalletRow,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionCategoriesTableCreateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      required String id,
      required String name,
      required String direction,
      Value<bool> isSystem,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$TransactionCategoriesTableUpdateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> direction,
      Value<bool> isSystem,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$TransactionCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionCategoriesTable,
          TransactionCategoryRow
        > {
  $$TransactionCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.transactionCategories.id,
      db.transactions.categoryId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionCategoriesTable,
          TransactionCategoryRow,
          $$TransactionCategoriesTableFilterComposer,
          $$TransactionCategoriesTableOrderingComposer,
          $$TransactionCategoriesTableAnnotationComposer,
          $$TransactionCategoriesTableCreateCompanionBuilder,
          $$TransactionCategoriesTableUpdateCompanionBuilder,
          (TransactionCategoryRow, $$TransactionCategoriesTableReferences),
          TransactionCategoryRow,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$TransactionCategoriesTableTableManager(
    _$AppDatabase db,
    $TransactionCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionCategoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion(
                id: id,
                name: name,
                direction: direction,
                isSystem: isSystem,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String direction,
                Value<bool> isSystem = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion.insert(
                id: id,
                name: name,
                direction: direction,
                isSystem: isSystem,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      TransactionCategoryRow,
                      $TransactionCategoriesTable,
                      TransactionRow
                    >(
                      currentTable: table,
                      referencedTable: $$TransactionCategoriesTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransactionCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransactionCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionCategoriesTable,
      TransactionCategoryRow,
      $$TransactionCategoriesTableFilterComposer,
      $$TransactionCategoriesTableOrderingComposer,
      $$TransactionCategoriesTableAnnotationComposer,
      $$TransactionCategoriesTableCreateCompanionBuilder,
      $$TransactionCategoriesTableUpdateCompanionBuilder,
      (TransactionCategoryRow, $$TransactionCategoriesTableReferences),
      TransactionCategoryRow,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String kind,
      required String walletId,
      required String walletNameSnapshot,
      Value<String?> categoryId,
      required String categoryNameSnapshot,
      Value<int> amount,
      Value<int> discount,
      Value<String> note,
      Value<String?> evidencePath,
      Value<String?> ocrSource,
      Value<String?> rawVoiceText,
      required DateTime occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> walletId,
      Value<String> walletNameSnapshot,
      Value<String?> categoryId,
      Value<String> categoryNameSnapshot,
      Value<int> amount,
      Value<int> discount,
      Value<String> note,
      Value<String?> evidencePath,
      Value<String?> ocrSource,
      Value<String?> rawVoiceText,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WalletsTable _walletIdTable(_$AppDatabase db) =>
      db.wallets.createAlias(
        $_aliasNameGenerator(db.transactions.walletId, db.wallets.id),
      );

  $$WalletsTableProcessedTableManager get walletId {
    final $_column = $_itemColumn<String>('wallet_id')!;

    final manager = $$WalletsTableTableManager(
      $_db,
      $_db.wallets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_walletIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TransactionCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.transactionCategories.createAlias(
        $_aliasNameGenerator(
          db.transactions.categoryId,
          db.transactionCategories.id,
        ),
      );

  $$TransactionCategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$TransactionCategoriesTableTableManager(
      $_db,
      $_db.transactionCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLineRow>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(
      db.transactions.id,
      db.transactionLines.transactionId,
    ),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.transactionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletNameSnapshot => $composableBuilder(
    column: $table.walletNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidencePath => $composableBuilder(
    column: $table.evidencePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrSource => $composableBuilder(
    column: $table.ocrSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawVoiceText => $composableBuilder(
    column: $table.rawVoiceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$WalletsTableFilterComposer get walletId {
    final $$WalletsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableFilterComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableFilterComposer get categoryId {
    final $$TransactionCategoriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableFilterComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletNameSnapshot => $composableBuilder(
    column: $table.walletNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidencePath => $composableBuilder(
    column: $table.evidencePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrSource => $composableBuilder(
    column: $table.ocrSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawVoiceText => $composableBuilder(
    column: $table.rawVoiceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$WalletsTableOrderingComposer get walletId {
    final $$WalletsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableOrderingComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableOrderingComposer get categoryId {
    final $$TransactionCategoriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableOrderingComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get walletNameSnapshot => $composableBuilder(
    column: $table.walletNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get evidencePath => $composableBuilder(
    column: $table.evidencePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrSource =>
      $composableBuilder(column: $table.ocrSource, builder: (column) => column);

  GeneratedColumn<String> get rawVoiceText => $composableBuilder(
    column: $table.rawVoiceText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$WalletsTableAnnotationComposer get walletId {
    final $$WalletsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.walletId,
      referencedTable: $db.wallets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WalletsTableAnnotationComposer(
            $db: $db,
            $table: $db.wallets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransactionCategoriesTableAnnotationComposer get categoryId {
    final $$TransactionCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.transactionCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.transactionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRow,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionRow, $$TransactionsTableReferences),
          TransactionRow,
          PrefetchHooks Function({
            bool walletId,
            bool categoryId,
            bool transactionLinesRefs,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<String> walletNameSnapshot = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> categoryNameSnapshot = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> discount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> evidencePath = const Value.absent(),
                Value<String?> ocrSource = const Value.absent(),
                Value<String?> rawVoiceText = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                kind: kind,
                walletId: walletId,
                walletNameSnapshot: walletNameSnapshot,
                categoryId: categoryId,
                categoryNameSnapshot: categoryNameSnapshot,
                amount: amount,
                discount: discount,
                note: note,
                evidencePath: evidencePath,
                ocrSource: ocrSource,
                rawVoiceText: rawVoiceText,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String walletId,
                required String walletNameSnapshot,
                Value<String?> categoryId = const Value.absent(),
                required String categoryNameSnapshot,
                Value<int> amount = const Value.absent(),
                Value<int> discount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> evidencePath = const Value.absent(),
                Value<String?> ocrSource = const Value.absent(),
                Value<String?> rawVoiceText = const Value.absent(),
                required DateTime occurredAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                kind: kind,
                walletId: walletId,
                walletNameSnapshot: walletNameSnapshot,
                categoryId: categoryId,
                categoryNameSnapshot: categoryNameSnapshot,
                amount: amount,
                discount: discount,
                note: note,
                evidencePath: evidencePath,
                ocrSource: ocrSource,
                rawVoiceText: rawVoiceText,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                walletId = false,
                categoryId = false,
                transactionLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionLinesRefs) db.transactionLines,
                  ],
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
                        if (walletId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.walletId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._walletIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._walletIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionLinesRefs)
                        await $_getPrefetchedData<
                          TransactionRow,
                          $TransactionsTable,
                          TransactionLineRow
                        >(
                          currentTable: table,
                          referencedTable: $$TransactionsTableReferences
                              ._transactionLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransactionsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transactionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRow,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionRow, $$TransactionsTableReferences),
      TransactionRow,
      PrefetchHooks Function({
        bool walletId,
        bool categoryId,
        bool transactionLinesRefs,
      })
    >;
typedef $$TransactionLinesTableCreateCompanionBuilder =
    TransactionLinesCompanion Function({
      required String id,
      required String transactionId,
      Value<String?> productId,
      required String productNameSnapshot,
      Value<int> position,
      Value<double> quantity,
      required String unit,
      Value<int> unitPrice,
      Value<int> costPrice,
      required String segment,
      Value<double> unitMultiplier,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$TransactionLinesTableUpdateCompanionBuilder =
    TransactionLinesCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<String?> productId,
      Value<String> productNameSnapshot,
      Value<int> position,
      Value<double> quantity,
      Value<String> unit,
      Value<int> unitPrice,
      Value<int> costPrice,
      Value<String> segment,
      Value<double> unitMultiplier,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$TransactionLinesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionLinesTable,
          TransactionLineRow
        > {
  $$TransactionLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionsTable _transactionIdTable(_$AppDatabase db) =>
      db.transactions.createAlias(
        $_aliasNameGenerator(
          db.transactionLines.transactionId,
          db.transactions.id,
        ),
      );

  $$TransactionsTableProcessedTableManager get transactionId {
    final $_column = $_itemColumn<String>('transaction_id')!;

    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.transactionLines.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionLinesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitMultiplier => $composableBuilder(
    column: $table.unitMultiplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitMultiplier => $composableBuilder(
    column: $table.unitMultiplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableOrderingComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<double> get unitMultiplier => $composableBuilder(
    column: $table.unitMultiplier,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transactionId,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionLinesTable,
          TransactionLineRow,
          $$TransactionLinesTableFilterComposer,
          $$TransactionLinesTableOrderingComposer,
          $$TransactionLinesTableAnnotationComposer,
          $$TransactionLinesTableCreateCompanionBuilder,
          $$TransactionLinesTableUpdateCompanionBuilder,
          (TransactionLineRow, $$TransactionLinesTableReferences),
          TransactionLineRow,
          PrefetchHooks Function({bool transactionId, bool productId})
        > {
  $$TransactionLinesTableTableManager(
    _$AppDatabase db,
    $TransactionLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> productNameSnapshot = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<String> segment = const Value.absent(),
                Value<double> unitMultiplier = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionLinesCompanion(
                id: id,
                transactionId: transactionId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                position: position,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                costPrice: costPrice,
                segment: segment,
                unitMultiplier: unitMultiplier,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                Value<String?> productId = const Value.absent(),
                required String productNameSnapshot,
                Value<int> position = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                required String unit,
                Value<int> unitPrice = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                required String segment,
                Value<double> unitMultiplier = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionLinesCompanion.insert(
                id: id,
                transactionId: transactionId,
                productId: productId,
                productNameSnapshot: productNameSnapshot,
                position: position,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                costPrice: costPrice,
                segment: segment,
                unitMultiplier: unitMultiplier,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionId = false, productId = false}) {
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
                    if (transactionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.transactionId,
                                referencedTable:
                                    $$TransactionLinesTableReferences
                                        ._transactionIdTable(db),
                                referencedColumn:
                                    $$TransactionLinesTableReferences
                                        ._transactionIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$TransactionLinesTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$TransactionLinesTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TransactionLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionLinesTable,
      TransactionLineRow,
      $$TransactionLinesTableFilterComposer,
      $$TransactionLinesTableOrderingComposer,
      $$TransactionLinesTableAnnotationComposer,
      $$TransactionLinesTableCreateCompanionBuilder,
      $$TransactionLinesTableUpdateCompanionBuilder,
      (TransactionLineRow, $$TransactionLinesTableReferences),
      TransactionLineRow,
      PrefetchHooks Function({bool transactionId, bool productId})
    >;
typedef $$BusinessProfilesTableCreateCompanionBuilder =
    BusinessProfilesCompanion Function({
      required String id,
      required String ownerName,
      required String email,
      required String phone,
      required String businessName,
      required String businessCategory,
      required String businessLocation,
      required String memberSince,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BusinessProfilesTableUpdateCompanionBuilder =
    BusinessProfilesCompanion Function({
      Value<String> id,
      Value<String> ownerName,
      Value<String> email,
      Value<String> phone,
      Value<String> businessName,
      Value<String> businessCategory,
      Value<String> businessLocation,
      Value<String> memberSince,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BusinessProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessCategory => $composableBuilder(
    column: $table.businessCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessLocation => $composableBuilder(
    column: $table.businessLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessCategory => $composableBuilder(
    column: $table.businessCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessLocation => $composableBuilder(
    column: $table.businessLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessCategory => $composableBuilder(
    column: $table.businessCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get businessLocation => $composableBuilder(
    column: $table.businessLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BusinessProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessProfilesTable,
          BusinessProfileRow,
          $$BusinessProfilesTableFilterComposer,
          $$BusinessProfilesTableOrderingComposer,
          $$BusinessProfilesTableAnnotationComposer,
          $$BusinessProfilesTableCreateCompanionBuilder,
          $$BusinessProfilesTableUpdateCompanionBuilder,
          (
            BusinessProfileRow,
            BaseReferences<
              _$AppDatabase,
              $BusinessProfilesTable,
              BusinessProfileRow
            >,
          ),
          BusinessProfileRow,
          PrefetchHooks Function()
        > {
  $$BusinessProfilesTableTableManager(
    _$AppDatabase db,
    $BusinessProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String> businessCategory = const Value.absent(),
                Value<String> businessLocation = const Value.absent(),
                Value<String> memberSince = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessProfilesCompanion(
                id: id,
                ownerName: ownerName,
                email: email,
                phone: phone,
                businessName: businessName,
                businessCategory: businessCategory,
                businessLocation: businessLocation,
                memberSince: memberSince,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ownerName,
                required String email,
                required String phone,
                required String businessName,
                required String businessCategory,
                required String businessLocation,
                required String memberSince,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessProfilesCompanion.insert(
                id: id,
                ownerName: ownerName,
                email: email,
                phone: phone,
                businessName: businessName,
                businessCategory: businessCategory,
                businessLocation: businessLocation,
                memberSince: memberSince,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessProfilesTable,
      BusinessProfileRow,
      $$BusinessProfilesTableFilterComposer,
      $$BusinessProfilesTableOrderingComposer,
      $$BusinessProfilesTableAnnotationComposer,
      $$BusinessProfilesTableCreateCompanionBuilder,
      $$BusinessProfilesTableUpdateCompanionBuilder,
      (
        BusinessProfileRow,
        BaseReferences<
          _$AppDatabase,
          $BusinessProfilesTable,
          BusinessProfileRow
        >,
      ),
      BusinessProfileRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$VoiceProductAliasesTableCreateCompanionBuilder =
    VoiceProductAliasesCompanion Function({
      required String id,
      required String aliasText,
      required String normalizedAlias,
      Value<String?> productId,
      required String canonicalProductName,
      Value<int> hitCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$VoiceProductAliasesTableUpdateCompanionBuilder =
    VoiceProductAliasesCompanion Function({
      Value<String> id,
      Value<String> aliasText,
      Value<String> normalizedAlias,
      Value<String?> productId,
      Value<String> canonicalProductName,
      Value<int> hitCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VoiceProductAliasesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VoiceProductAliasesTable,
          VoiceProductAliasRow
        > {
  $$VoiceProductAliasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias(
        $_aliasNameGenerator(db.voiceProductAliases.productId, db.products.id),
      );

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VoiceProductAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $VoiceProductAliasesTable> {
  $$VoiceProductAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasText => $composableBuilder(
    column: $table.aliasText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalProductName => $composableBuilder(
    column: $table.canonicalProductName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceProductAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoiceProductAliasesTable> {
  $$VoiceProductAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasText => $composableBuilder(
    column: $table.aliasText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalProductName => $composableBuilder(
    column: $table.canonicalProductName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceProductAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoiceProductAliasesTable> {
  $$VoiceProductAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aliasText =>
      $composableBuilder(column: $table.aliasText, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalProductName => $composableBuilder(
    column: $table.canonicalProductName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hitCount =>
      $composableBuilder(column: $table.hitCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VoiceProductAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoiceProductAliasesTable,
          VoiceProductAliasRow,
          $$VoiceProductAliasesTableFilterComposer,
          $$VoiceProductAliasesTableOrderingComposer,
          $$VoiceProductAliasesTableAnnotationComposer,
          $$VoiceProductAliasesTableCreateCompanionBuilder,
          $$VoiceProductAliasesTableUpdateCompanionBuilder,
          (VoiceProductAliasRow, $$VoiceProductAliasesTableReferences),
          VoiceProductAliasRow,
          PrefetchHooks Function({bool productId})
        > {
  $$VoiceProductAliasesTableTableManager(
    _$AppDatabase db,
    $VoiceProductAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceProductAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceProductAliasesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$VoiceProductAliasesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aliasText = const Value.absent(),
                Value<String> normalizedAlias = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> canonicalProductName = const Value.absent(),
                Value<int> hitCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceProductAliasesCompanion(
                id: id,
                aliasText: aliasText,
                normalizedAlias: normalizedAlias,
                productId: productId,
                canonicalProductName: canonicalProductName,
                hitCount: hitCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aliasText,
                required String normalizedAlias,
                Value<String?> productId = const Value.absent(),
                required String canonicalProductName,
                Value<int> hitCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceProductAliasesCompanion.insert(
                id: id,
                aliasText: aliasText,
                normalizedAlias: normalizedAlias,
                productId: productId,
                canonicalProductName: canonicalProductName,
                hitCount: hitCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VoiceProductAliasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productId,
                                referencedTable:
                                    $$VoiceProductAliasesTableReferences
                                        ._productIdTable(db),
                                referencedColumn:
                                    $$VoiceProductAliasesTableReferences
                                        ._productIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$VoiceProductAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoiceProductAliasesTable,
      VoiceProductAliasRow,
      $$VoiceProductAliasesTableFilterComposer,
      $$VoiceProductAliasesTableOrderingComposer,
      $$VoiceProductAliasesTableAnnotationComposer,
      $$VoiceProductAliasesTableCreateCompanionBuilder,
      $$VoiceProductAliasesTableUpdateCompanionBuilder,
      (VoiceProductAliasRow, $$VoiceProductAliasesTableReferences),
      VoiceProductAliasRow,
      PrefetchHooks Function({bool productId})
    >;
typedef $$VoiceUnitAliasesTableCreateCompanionBuilder =
    VoiceUnitAliasesCompanion Function({
      required String id,
      required String aliasText,
      required String normalizedAlias,
      required String canonicalUnit,
      Value<int> hitCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$VoiceUnitAliasesTableUpdateCompanionBuilder =
    VoiceUnitAliasesCompanion Function({
      Value<String> id,
      Value<String> aliasText,
      Value<String> normalizedAlias,
      Value<String> canonicalUnit,
      Value<int> hitCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$VoiceUnitAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $VoiceUnitAliasesTable> {
  $$VoiceUnitAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasText => $composableBuilder(
    column: $table.aliasText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalUnit => $composableBuilder(
    column: $table.canonicalUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoiceUnitAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $VoiceUnitAliasesTable> {
  $$VoiceUnitAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasText => $composableBuilder(
    column: $table.aliasText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalUnit => $composableBuilder(
    column: $table.canonicalUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hitCount => $composableBuilder(
    column: $table.hitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoiceUnitAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoiceUnitAliasesTable> {
  $$VoiceUnitAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get aliasText =>
      $composableBuilder(column: $table.aliasText, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalUnit => $composableBuilder(
    column: $table.canonicalUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hitCount =>
      $composableBuilder(column: $table.hitCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VoiceUnitAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoiceUnitAliasesTable,
          VoiceUnitAliasRow,
          $$VoiceUnitAliasesTableFilterComposer,
          $$VoiceUnitAliasesTableOrderingComposer,
          $$VoiceUnitAliasesTableAnnotationComposer,
          $$VoiceUnitAliasesTableCreateCompanionBuilder,
          $$VoiceUnitAliasesTableUpdateCompanionBuilder,
          (
            VoiceUnitAliasRow,
            BaseReferences<
              _$AppDatabase,
              $VoiceUnitAliasesTable,
              VoiceUnitAliasRow
            >,
          ),
          VoiceUnitAliasRow,
          PrefetchHooks Function()
        > {
  $$VoiceUnitAliasesTableTableManager(
    _$AppDatabase db,
    $VoiceUnitAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceUnitAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceUnitAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceUnitAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> aliasText = const Value.absent(),
                Value<String> normalizedAlias = const Value.absent(),
                Value<String> canonicalUnit = const Value.absent(),
                Value<int> hitCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceUnitAliasesCompanion(
                id: id,
                aliasText: aliasText,
                normalizedAlias: normalizedAlias,
                canonicalUnit: canonicalUnit,
                hitCount: hitCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String aliasText,
                required String normalizedAlias,
                required String canonicalUnit,
                Value<int> hitCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceUnitAliasesCompanion.insert(
                id: id,
                aliasText: aliasText,
                normalizedAlias: normalizedAlias,
                canonicalUnit: canonicalUnit,
                hitCount: hitCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoiceUnitAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoiceUnitAliasesTable,
      VoiceUnitAliasRow,
      $$VoiceUnitAliasesTableFilterComposer,
      $$VoiceUnitAliasesTableOrderingComposer,
      $$VoiceUnitAliasesTableAnnotationComposer,
      $$VoiceUnitAliasesTableCreateCompanionBuilder,
      $$VoiceUnitAliasesTableUpdateCompanionBuilder,
      (
        VoiceUnitAliasRow,
        BaseReferences<
          _$AppDatabase,
          $VoiceUnitAliasesTable,
          VoiceUnitAliasRow
        >,
      ),
      VoiceUnitAliasRow,
      PrefetchHooks Function()
    >;
typedef $$VoiceCorrectionsTableCreateCompanionBuilder =
    VoiceCorrectionsCompanion Function({
      required String id,
      required String rawText,
      Value<String?> parsedProductName,
      required String correctedProductName,
      Value<String?> parsedUnit,
      required String correctedUnit,
      Value<double?> parsedQuantity,
      required double correctedQuantity,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$VoiceCorrectionsTableUpdateCompanionBuilder =
    VoiceCorrectionsCompanion Function({
      Value<String> id,
      Value<String> rawText,
      Value<String?> parsedProductName,
      Value<String> correctedProductName,
      Value<String?> parsedUnit,
      Value<String> correctedUnit,
      Value<double?> parsedQuantity,
      Value<double> correctedQuantity,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VoiceCorrectionsTableFilterComposer
    extends Composer<_$AppDatabase, $VoiceCorrectionsTable> {
  $$VoiceCorrectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedProductName => $composableBuilder(
    column: $table.parsedProductName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedProductName => $composableBuilder(
    column: $table.correctedProductName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedUnit => $composableBuilder(
    column: $table.parsedUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedUnit => $composableBuilder(
    column: $table.correctedUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get parsedQuantity => $composableBuilder(
    column: $table.parsedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get correctedQuantity => $composableBuilder(
    column: $table.correctedQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoiceCorrectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $VoiceCorrectionsTable> {
  $$VoiceCorrectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedProductName => $composableBuilder(
    column: $table.parsedProductName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedProductName => $composableBuilder(
    column: $table.correctedProductName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedUnit => $composableBuilder(
    column: $table.parsedUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedUnit => $composableBuilder(
    column: $table.correctedUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get parsedQuantity => $composableBuilder(
    column: $table.parsedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get correctedQuantity => $composableBuilder(
    column: $table.correctedQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoiceCorrectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoiceCorrectionsTable> {
  $$VoiceCorrectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get parsedProductName => $composableBuilder(
    column: $table.parsedProductName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctedProductName => $composableBuilder(
    column: $table.correctedProductName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedUnit => $composableBuilder(
    column: $table.parsedUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctedUnit => $composableBuilder(
    column: $table.correctedUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get parsedQuantity => $composableBuilder(
    column: $table.parsedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get correctedQuantity => $composableBuilder(
    column: $table.correctedQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VoiceCorrectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoiceCorrectionsTable,
          VoiceCorrectionRow,
          $$VoiceCorrectionsTableFilterComposer,
          $$VoiceCorrectionsTableOrderingComposer,
          $$VoiceCorrectionsTableAnnotationComposer,
          $$VoiceCorrectionsTableCreateCompanionBuilder,
          $$VoiceCorrectionsTableUpdateCompanionBuilder,
          (
            VoiceCorrectionRow,
            BaseReferences<
              _$AppDatabase,
              $VoiceCorrectionsTable,
              VoiceCorrectionRow
            >,
          ),
          VoiceCorrectionRow,
          PrefetchHooks Function()
        > {
  $$VoiceCorrectionsTableTableManager(
    _$AppDatabase db,
    $VoiceCorrectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceCorrectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceCorrectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceCorrectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> parsedProductName = const Value.absent(),
                Value<String> correctedProductName = const Value.absent(),
                Value<String?> parsedUnit = const Value.absent(),
                Value<String> correctedUnit = const Value.absent(),
                Value<double?> parsedQuantity = const Value.absent(),
                Value<double> correctedQuantity = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceCorrectionsCompanion(
                id: id,
                rawText: rawText,
                parsedProductName: parsedProductName,
                correctedProductName: correctedProductName,
                parsedUnit: parsedUnit,
                correctedUnit: correctedUnit,
                parsedQuantity: parsedQuantity,
                correctedQuantity: correctedQuantity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawText,
                Value<String?> parsedProductName = const Value.absent(),
                required String correctedProductName,
                Value<String?> parsedUnit = const Value.absent(),
                required String correctedUnit,
                Value<double?> parsedQuantity = const Value.absent(),
                required double correctedQuantity,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceCorrectionsCompanion.insert(
                id: id,
                rawText: rawText,
                parsedProductName: parsedProductName,
                correctedProductName: correctedProductName,
                parsedUnit: parsedUnit,
                correctedUnit: correctedUnit,
                parsedQuantity: parsedQuantity,
                correctedQuantity: correctedQuantity,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoiceCorrectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoiceCorrectionsTable,
      VoiceCorrectionRow,
      $$VoiceCorrectionsTableFilterComposer,
      $$VoiceCorrectionsTableOrderingComposer,
      $$VoiceCorrectionsTableAnnotationComposer,
      $$VoiceCorrectionsTableCreateCompanionBuilder,
      $$VoiceCorrectionsTableUpdateCompanionBuilder,
      (
        VoiceCorrectionRow,
        BaseReferences<
          _$AppDatabase,
          $VoiceCorrectionsTable,
          VoiceCorrectionRow
        >,
      ),
      VoiceCorrectionRow,
      PrefetchHooks Function()
    >;
typedef $$VoiceActionAuditsTableCreateCompanionBuilder =
    VoiceActionAuditsCompanion Function({
      required String id,
      required String actionId,
      required String actionType,
      required String source,
      required String status,
      Value<String?> targetEntityType,
      Value<String?> targetEntityId,
      Value<String> beforeSummary,
      Value<String> afterSummary,
      Value<bool> confirmed,
      Value<bool> authRequired,
      Value<bool> authSucceeded,
      Value<String?> errorCode,
      Value<String> undoStatus,
      required String commandFingerprint,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$VoiceActionAuditsTableUpdateCompanionBuilder =
    VoiceActionAuditsCompanion Function({
      Value<String> id,
      Value<String> actionId,
      Value<String> actionType,
      Value<String> source,
      Value<String> status,
      Value<String?> targetEntityType,
      Value<String?> targetEntityId,
      Value<String> beforeSummary,
      Value<String> afterSummary,
      Value<bool> confirmed,
      Value<bool> authRequired,
      Value<bool> authSucceeded,
      Value<String?> errorCode,
      Value<String> undoStatus,
      Value<String> commandFingerprint,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VoiceActionAuditsTableFilterComposer
    extends Composer<_$AppDatabase, $VoiceActionAuditsTable> {
  $$VoiceActionAuditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetEntityType => $composableBuilder(
    column: $table.targetEntityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetEntityId => $composableBuilder(
    column: $table.targetEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeSummary => $composableBuilder(
    column: $table.beforeSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterSummary => $composableBuilder(
    column: $table.afterSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get authRequired => $composableBuilder(
    column: $table.authRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get authSucceeded => $composableBuilder(
    column: $table.authSucceeded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get undoStatus => $composableBuilder(
    column: $table.undoStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandFingerprint => $composableBuilder(
    column: $table.commandFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoiceActionAuditsTableOrderingComposer
    extends Composer<_$AppDatabase, $VoiceActionAuditsTable> {
  $$VoiceActionAuditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetEntityType => $composableBuilder(
    column: $table.targetEntityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetEntityId => $composableBuilder(
    column: $table.targetEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeSummary => $composableBuilder(
    column: $table.beforeSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterSummary => $composableBuilder(
    column: $table.afterSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmed => $composableBuilder(
    column: $table.confirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get authRequired => $composableBuilder(
    column: $table.authRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get authSucceeded => $composableBuilder(
    column: $table.authSucceeded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get undoStatus => $composableBuilder(
    column: $table.undoStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandFingerprint => $composableBuilder(
    column: $table.commandFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoiceActionAuditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VoiceActionAuditsTable> {
  $$VoiceActionAuditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get targetEntityType => $composableBuilder(
    column: $table.targetEntityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetEntityId => $composableBuilder(
    column: $table.targetEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beforeSummary => $composableBuilder(
    column: $table.beforeSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterSummary => $composableBuilder(
    column: $table.afterSummary,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmed =>
      $composableBuilder(column: $table.confirmed, builder: (column) => column);

  GeneratedColumn<bool> get authRequired => $composableBuilder(
    column: $table.authRequired,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get authSucceeded => $composableBuilder(
    column: $table.authSucceeded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<String> get undoStatus => $composableBuilder(
    column: $table.undoStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commandFingerprint => $composableBuilder(
    column: $table.commandFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VoiceActionAuditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VoiceActionAuditsTable,
          VoiceActionAuditRow,
          $$VoiceActionAuditsTableFilterComposer,
          $$VoiceActionAuditsTableOrderingComposer,
          $$VoiceActionAuditsTableAnnotationComposer,
          $$VoiceActionAuditsTableCreateCompanionBuilder,
          $$VoiceActionAuditsTableUpdateCompanionBuilder,
          (
            VoiceActionAuditRow,
            BaseReferences<
              _$AppDatabase,
              $VoiceActionAuditsTable,
              VoiceActionAuditRow
            >,
          ),
          VoiceActionAuditRow,
          PrefetchHooks Function()
        > {
  $$VoiceActionAuditsTableTableManager(
    _$AppDatabase db,
    $VoiceActionAuditsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceActionAuditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceActionAuditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceActionAuditsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> actionId = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> targetEntityType = const Value.absent(),
                Value<String?> targetEntityId = const Value.absent(),
                Value<String> beforeSummary = const Value.absent(),
                Value<String> afterSummary = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<bool> authRequired = const Value.absent(),
                Value<bool> authSucceeded = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String> undoStatus = const Value.absent(),
                Value<String> commandFingerprint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceActionAuditsCompanion(
                id: id,
                actionId: actionId,
                actionType: actionType,
                source: source,
                status: status,
                targetEntityType: targetEntityType,
                targetEntityId: targetEntityId,
                beforeSummary: beforeSummary,
                afterSummary: afterSummary,
                confirmed: confirmed,
                authRequired: authRequired,
                authSucceeded: authSucceeded,
                errorCode: errorCode,
                undoStatus: undoStatus,
                commandFingerprint: commandFingerprint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String actionId,
                required String actionType,
                required String source,
                required String status,
                Value<String?> targetEntityType = const Value.absent(),
                Value<String?> targetEntityId = const Value.absent(),
                Value<String> beforeSummary = const Value.absent(),
                Value<String> afterSummary = const Value.absent(),
                Value<bool> confirmed = const Value.absent(),
                Value<bool> authRequired = const Value.absent(),
                Value<bool> authSucceeded = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<String> undoStatus = const Value.absent(),
                required String commandFingerprint,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceActionAuditsCompanion.insert(
                id: id,
                actionId: actionId,
                actionType: actionType,
                source: source,
                status: status,
                targetEntityType: targetEntityType,
                targetEntityId: targetEntityId,
                beforeSummary: beforeSummary,
                afterSummary: afterSummary,
                confirmed: confirmed,
                authRequired: authRequired,
                authSucceeded: authSucceeded,
                errorCode: errorCode,
                undoStatus: undoStatus,
                commandFingerprint: commandFingerprint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoiceActionAuditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VoiceActionAuditsTable,
      VoiceActionAuditRow,
      $$VoiceActionAuditsTableFilterComposer,
      $$VoiceActionAuditsTableOrderingComposer,
      $$VoiceActionAuditsTableAnnotationComposer,
      $$VoiceActionAuditsTableCreateCompanionBuilder,
      $$VoiceActionAuditsTableUpdateCompanionBuilder,
      (
        VoiceActionAuditRow,
        BaseReferences<
          _$AppDatabase,
          $VoiceActionAuditsTable,
          VoiceActionAuditRow
        >,
      ),
      VoiceActionAuditRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductCategoriesTableTableManager get productCategories =>
      $$ProductCategoriesTableTableManager(_db, _db.productCategories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$TransactionCategoriesTableTableManager get transactionCategories =>
      $$TransactionCategoriesTableTableManager(_db, _db.transactionCategories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$TransactionLinesTableTableManager get transactionLines =>
      $$TransactionLinesTableTableManager(_db, _db.transactionLines);
  $$BusinessProfilesTableTableManager get businessProfiles =>
      $$BusinessProfilesTableTableManager(_db, _db.businessProfiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$VoiceProductAliasesTableTableManager get voiceProductAliases =>
      $$VoiceProductAliasesTableTableManager(_db, _db.voiceProductAliases);
  $$VoiceUnitAliasesTableTableManager get voiceUnitAliases =>
      $$VoiceUnitAliasesTableTableManager(_db, _db.voiceUnitAliases);
  $$VoiceCorrectionsTableTableManager get voiceCorrections =>
      $$VoiceCorrectionsTableTableManager(_db, _db.voiceCorrections);
  $$VoiceActionAuditsTableTableManager get voiceActionAudits =>
      $$VoiceActionAuditsTableTableManager(_db, _db.voiceActionAudits);
}
