// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductCategoryEntriesTable extends ProductCategoryEntries
    with TableInfo<$ProductCategoryEntriesTable, ProductCategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductCategoryEntriesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_category_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductCategoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  ProductCategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductCategoryEntry(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ProductCategoryEntriesTable createAlias(String alias) {
    return $ProductCategoryEntriesTable(attachedDatabase, alias);
  }
}

class ProductCategoryEntry extends DataClass
    implements Insertable<ProductCategoryEntry> {
  final String name;
  final int position;
  const ProductCategoryEntry({required this.name, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  ProductCategoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProductCategoryEntriesCompanion(
      name: Value(name),
      position: Value(position),
    );
  }

  factory ProductCategoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductCategoryEntry(
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  ProductCategoryEntry copyWith({String? name, int? position}) =>
      ProductCategoryEntry(
        name: name ?? this.name,
        position: position ?? this.position,
      );
  ProductCategoryEntry copyWithCompanion(ProductCategoryEntriesCompanion data) {
    return ProductCategoryEntry(
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductCategoryEntry(')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductCategoryEntry &&
          other.name == this.name &&
          other.position == this.position);
}

class ProductCategoryEntriesCompanion
    extends UpdateCompanion<ProductCategoryEntry> {
  final Value<String> name;
  final Value<int> position;
  final Value<int> rowid;
  const ProductCategoryEntriesCompanion({
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductCategoryEntriesCompanion.insert({
    required String name,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<ProductCategoryEntry> custom({
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductCategoryEntriesCompanion copyWith({
    Value<String>? name,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return ProductCategoryEntriesCompanion(
      name: name ?? this.name,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCategoryEntriesCompanion(')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductEntriesTable extends ProductEntries
    with TableInfo<$ProductEntriesTable, ProductEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumn<int> stockPcs = GeneratedColumn<int>(
    'stock_pcs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    costPrice,
    retailPrice,
    wholesalePrice,
    packSize,
    cartonSize,
    stockPcs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductEntry> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
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
        DriftSqlType.int,
        data['${effectivePrefix}stock_pcs'],
      )!,
    );
  }

  @override
  $ProductEntriesTable createAlias(String alias) {
    return $ProductEntriesTable(attachedDatabase, alias);
  }
}

class ProductEntry extends DataClass implements Insertable<ProductEntry> {
  final String id;
  final String name;
  final String category;
  final int costPrice;
  final int retailPrice;
  final int wholesalePrice;
  final int packSize;
  final int cartonSize;
  final int stockPcs;
  const ProductEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.packSize,
    required this.cartonSize,
    required this.stockPcs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['cost_price'] = Variable<int>(costPrice);
    map['retail_price'] = Variable<int>(retailPrice);
    map['wholesale_price'] = Variable<int>(wholesalePrice);
    map['pack_size'] = Variable<int>(packSize);
    map['carton_size'] = Variable<int>(cartonSize);
    map['stock_pcs'] = Variable<int>(stockPcs);
    return map;
  }

  ProductEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProductEntriesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      costPrice: Value(costPrice),
      retailPrice: Value(retailPrice),
      wholesalePrice: Value(wholesalePrice),
      packSize: Value(packSize),
      cartonSize: Value(cartonSize),
      stockPcs: Value(stockPcs),
    );
  }

  factory ProductEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      costPrice: serializer.fromJson<int>(json['costPrice']),
      retailPrice: serializer.fromJson<int>(json['retailPrice']),
      wholesalePrice: serializer.fromJson<int>(json['wholesalePrice']),
      packSize: serializer.fromJson<int>(json['packSize']),
      cartonSize: serializer.fromJson<int>(json['cartonSize']),
      stockPcs: serializer.fromJson<int>(json['stockPcs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'costPrice': serializer.toJson<int>(costPrice),
      'retailPrice': serializer.toJson<int>(retailPrice),
      'wholesalePrice': serializer.toJson<int>(wholesalePrice),
      'packSize': serializer.toJson<int>(packSize),
      'cartonSize': serializer.toJson<int>(cartonSize),
      'stockPcs': serializer.toJson<int>(stockPcs),
    };
  }

  ProductEntry copyWith({
    String? id,
    String? name,
    String? category,
    int? costPrice,
    int? retailPrice,
    int? wholesalePrice,
    int? packSize,
    int? cartonSize,
    int? stockPcs,
  }) => ProductEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    costPrice: costPrice ?? this.costPrice,
    retailPrice: retailPrice ?? this.retailPrice,
    wholesalePrice: wholesalePrice ?? this.wholesalePrice,
    packSize: packSize ?? this.packSize,
    cartonSize: cartonSize ?? this.cartonSize,
    stockPcs: stockPcs ?? this.stockPcs,
  );
  ProductEntry copyWithCompanion(ProductEntriesCompanion data) {
    return ProductEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('packSize: $packSize, ')
          ..write('cartonSize: $cartonSize, ')
          ..write('stockPcs: $stockPcs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    costPrice,
    retailPrice,
    wholesalePrice,
    packSize,
    cartonSize,
    stockPcs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.costPrice == this.costPrice &&
          other.retailPrice == this.retailPrice &&
          other.wholesalePrice == this.wholesalePrice &&
          other.packSize == this.packSize &&
          other.cartonSize == this.cartonSize &&
          other.stockPcs == this.stockPcs);
}

class ProductEntriesCompanion extends UpdateCompanion<ProductEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> costPrice;
  final Value<int> retailPrice;
  final Value<int> wholesalePrice;
  final Value<int> packSize;
  final Value<int> cartonSize;
  final Value<int> stockPcs;
  final Value<int> rowid;
  const ProductEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.packSize = const Value.absent(),
    this.cartonSize = const Value.absent(),
    this.stockPcs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductEntriesCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.costPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.packSize = const Value.absent(),
    this.cartonSize = const Value.absent(),
    this.stockPcs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category);
  static Insertable<ProductEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? costPrice,
    Expression<int>? retailPrice,
    Expression<int>? wholesalePrice,
    Expression<int>? packSize,
    Expression<int>? cartonSize,
    Expression<int>? stockPcs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (costPrice != null) 'cost_price': costPrice,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (packSize != null) 'pack_size': packSize,
      if (cartonSize != null) 'carton_size': cartonSize,
      if (stockPcs != null) 'stock_pcs': stockPcs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? costPrice,
    Value<int>? retailPrice,
    Value<int>? wholesalePrice,
    Value<int>? packSize,
    Value<int>? cartonSize,
    Value<int>? stockPcs,
    Value<int>? rowid,
  }) {
    return ProductEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      packSize: packSize ?? this.packSize,
      cartonSize: cartonSize ?? this.cartonSize,
      stockPcs: stockPcs ?? this.stockPcs,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
      map['stock_pcs'] = Variable<int>(stockPcs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('costPrice: $costPrice, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('packSize: $packSize, ')
          ..write('cartonSize: $cartonSize, ')
          ..write('stockPcs: $stockPcs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WalletEntriesTable extends WalletEntries
    with TableInfo<$WalletEntriesTable, WalletEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletEntriesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, name, balance, isPrimary];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallet_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletEntry> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletEntry(
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
    );
  }

  @override
  $WalletEntriesTable createAlias(String alias) {
    return $WalletEntriesTable(attachedDatabase, alias);
  }
}

class WalletEntry extends DataClass implements Insertable<WalletEntry> {
  final String id;
  final String name;
  final int balance;
  final bool isPrimary;
  const WalletEntry({
    required this.id,
    required this.name,
    required this.balance,
    required this.isPrimary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<int>(balance);
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  WalletEntriesCompanion toCompanion(bool nullToAbsent) {
    return WalletEntriesCompanion(
      id: Value(id),
      name: Value(name),
      balance: Value(balance),
      isPrimary: Value(isPrimary),
    );
  }

  factory WalletEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<int>(json['balance']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
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
    };
  }

  WalletEntry copyWith({
    String? id,
    String? name,
    int? balance,
    bool? isPrimary,
  }) => WalletEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
    isPrimary: isPrimary ?? this.isPrimary,
  );
  WalletEntry copyWithCompanion(WalletEntriesCompanion data) {
    return WalletEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, balance, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.balance == this.balance &&
          other.isPrimary == this.isPrimary);
}

class WalletEntriesCompanion extends UpdateCompanion<WalletEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> balance;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const WalletEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletEntriesCompanion.insert({
    required String id,
    required String name,
    this.balance = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<WalletEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? balance,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? balance,
    Value<bool>? isPrimary,
    Value<int>? rowid,
  }) {
    return WalletEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPrimary: isPrimary ?? this.isPrimary,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerCategoryEntriesTable extends LedgerCategoryEntries
    with TableInfo<$LedgerCategoryEntriesTable, LedgerCategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerCategoryEntriesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, name, direction, isSystem];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_category_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerCategoryEntry> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerCategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerCategoryEntry(
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
    );
  }

  @override
  $LedgerCategoryEntriesTable createAlias(String alias) {
    return $LedgerCategoryEntriesTable(attachedDatabase, alias);
  }
}

class LedgerCategoryEntry extends DataClass
    implements Insertable<LedgerCategoryEntry> {
  final String id;
  final String name;
  final String direction;
  final bool isSystem;
  const LedgerCategoryEntry({
    required this.id,
    required this.name,
    required this.direction,
    required this.isSystem,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['direction'] = Variable<String>(direction);
    map['is_system'] = Variable<bool>(isSystem);
    return map;
  }

  LedgerCategoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerCategoryEntriesCompanion(
      id: Value(id),
      name: Value(name),
      direction: Value(direction),
      isSystem: Value(isSystem),
    );
  }

  factory LedgerCategoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerCategoryEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      direction: serializer.fromJson<String>(json['direction']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
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
    };
  }

  LedgerCategoryEntry copyWith({
    String? id,
    String? name,
    String? direction,
    bool? isSystem,
  }) => LedgerCategoryEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    direction: direction ?? this.direction,
    isSystem: isSystem ?? this.isSystem,
  );
  LedgerCategoryEntry copyWithCompanion(LedgerCategoryEntriesCompanion data) {
    return LedgerCategoryEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      direction: data.direction.present ? data.direction.value : this.direction,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategoryEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('isSystem: $isSystem')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, direction, isSystem);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerCategoryEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.direction == this.direction &&
          other.isSystem == this.isSystem);
}

class LedgerCategoryEntriesCompanion
    extends UpdateCompanion<LedgerCategoryEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> direction;
  final Value<bool> isSystem;
  final Value<int> rowid;
  const LedgerCategoryEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.direction = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerCategoryEntriesCompanion.insert({
    required String id,
    required String name,
    required String direction,
    this.isSystem = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       direction = Value(direction);
  static Insertable<LedgerCategoryEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? direction,
    Expression<bool>? isSystem,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (direction != null) 'direction': direction,
      if (isSystem != null) 'is_system': isSystem,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerCategoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? direction,
    Value<bool>? isSystem,
    Value<int>? rowid,
  }) {
    return LedgerCategoryEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      direction: direction ?? this.direction,
      isSystem: isSystem ?? this.isSystem,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerCategoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('direction: $direction, ')
          ..write('isSystem: $isSystem, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionEntriesTable extends TransactionEntries
    with TableInfo<$TransactionEntriesTable, TransactionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionEntriesTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _walletNameMeta = const VerificationMeta(
    'walletName',
  );
  @override
  late final GeneratedColumn<String> walletName = GeneratedColumn<String>(
    'wallet_name',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
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
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    createdAt,
    walletId,
    walletName,
    categoryId,
    categoryName,
    amount,
    discount,
    note,
    evidencePath,
    ocrSource,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionEntry> instance, {
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    } else if (isInserting) {
      context.missing(_walletIdMeta);
    }
    if (data.containsKey('wallet_name')) {
      context.handle(
        _walletNameMeta,
        walletName.isAcceptableOrUnknown(data['wallet_name']!, _walletNameMeta),
      );
    } else if (isInserting) {
      context.missing(_walletNameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryNameMeta);
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
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      )!,
      walletName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
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
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TransactionEntriesTable createAlias(String alias) {
    return $TransactionEntriesTable(attachedDatabase, alias);
  }
}

class TransactionEntry extends DataClass
    implements Insertable<TransactionEntry> {
  final String id;
  final String kind;
  final DateTime createdAt;
  final String walletId;
  final String walletName;
  final String categoryId;
  final String categoryName;
  final int amount;
  final int discount;
  final String note;
  final String? evidencePath;
  final String? ocrSource;
  final String syncStatus;
  const TransactionEntry({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.walletId,
    required this.walletName,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.discount,
    required this.note,
    this.evidencePath,
    this.ocrSource,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['wallet_id'] = Variable<String>(walletId);
    map['wallet_name'] = Variable<String>(walletName);
    map['category_id'] = Variable<String>(categoryId);
    map['category_name'] = Variable<String>(categoryName);
    map['amount'] = Variable<int>(amount);
    map['discount'] = Variable<int>(discount);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || evidencePath != null) {
      map['evidence_path'] = Variable<String>(evidencePath);
    }
    if (!nullToAbsent || ocrSource != null) {
      map['ocr_source'] = Variable<String>(ocrSource);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TransactionEntriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      createdAt: Value(createdAt),
      walletId: Value(walletId),
      walletName: Value(walletName),
      categoryId: Value(categoryId),
      categoryName: Value(categoryName),
      amount: Value(amount),
      discount: Value(discount),
      note: Value(note),
      evidencePath: evidencePath == null && nullToAbsent
          ? const Value.absent()
          : Value(evidencePath),
      ocrSource: ocrSource == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrSource),
      syncStatus: Value(syncStatus),
    );
  }

  factory TransactionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEntry(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      walletId: serializer.fromJson<String>(json['walletId']),
      walletName: serializer.fromJson<String>(json['walletName']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      categoryName: serializer.fromJson<String>(json['categoryName']),
      amount: serializer.fromJson<int>(json['amount']),
      discount: serializer.fromJson<int>(json['discount']),
      note: serializer.fromJson<String>(json['note']),
      evidencePath: serializer.fromJson<String?>(json['evidencePath']),
      ocrSource: serializer.fromJson<String?>(json['ocrSource']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'walletId': serializer.toJson<String>(walletId),
      'walletName': serializer.toJson<String>(walletName),
      'categoryId': serializer.toJson<String>(categoryId),
      'categoryName': serializer.toJson<String>(categoryName),
      'amount': serializer.toJson<int>(amount),
      'discount': serializer.toJson<int>(discount),
      'note': serializer.toJson<String>(note),
      'evidencePath': serializer.toJson<String?>(evidencePath),
      'ocrSource': serializer.toJson<String?>(ocrSource),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TransactionEntry copyWith({
    String? id,
    String? kind,
    DateTime? createdAt,
    String? walletId,
    String? walletName,
    String? categoryId,
    String? categoryName,
    int? amount,
    int? discount,
    String? note,
    Value<String?> evidencePath = const Value.absent(),
    Value<String?> ocrSource = const Value.absent(),
    String? syncStatus,
  }) => TransactionEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    walletId: walletId ?? this.walletId,
    walletName: walletName ?? this.walletName,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    amount: amount ?? this.amount,
    discount: discount ?? this.discount,
    note: note ?? this.note,
    evidencePath: evidencePath.present ? evidencePath.value : this.evidencePath,
    ocrSource: ocrSource.present ? ocrSource.value : this.ocrSource,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TransactionEntry copyWithCompanion(TransactionEntriesCompanion data) {
    return TransactionEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      walletName: data.walletName.present
          ? data.walletName.value
          : this.walletName,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      amount: data.amount.present ? data.amount.value : this.amount,
      discount: data.discount.present ? data.discount.value : this.discount,
      note: data.note.present ? data.note.value : this.note,
      evidencePath: data.evidencePath.present
          ? data.evidencePath.value
          : this.evidencePath,
      ocrSource: data.ocrSource.present ? data.ocrSource.value : this.ocrSource,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('walletId: $walletId, ')
          ..write('walletName: $walletName, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('amount: $amount, ')
          ..write('discount: $discount, ')
          ..write('note: $note, ')
          ..write('evidencePath: $evidencePath, ')
          ..write('ocrSource: $ocrSource, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    createdAt,
    walletId,
    walletName,
    categoryId,
    categoryName,
    amount,
    discount,
    note,
    evidencePath,
    ocrSource,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.walletId == this.walletId &&
          other.walletName == this.walletName &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.amount == this.amount &&
          other.discount == this.discount &&
          other.note == this.note &&
          other.evidencePath == this.evidencePath &&
          other.ocrSource == this.ocrSource &&
          other.syncStatus == this.syncStatus);
}

class TransactionEntriesCompanion extends UpdateCompanion<TransactionEntry> {
  final Value<String> id;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  final Value<String> walletId;
  final Value<String> walletName;
  final Value<String> categoryId;
  final Value<String> categoryName;
  final Value<int> amount;
  final Value<int> discount;
  final Value<String> note;
  final Value<String?> evidencePath;
  final Value<String?> ocrSource;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TransactionEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.walletId = const Value.absent(),
    this.walletName = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.amount = const Value.absent(),
    this.discount = const Value.absent(),
    this.note = const Value.absent(),
    this.evidencePath = const Value.absent(),
    this.ocrSource = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionEntriesCompanion.insert({
    required String id,
    required String kind,
    required DateTime createdAt,
    required String walletId,
    required String walletName,
    required String categoryId,
    required String categoryName,
    this.amount = const Value.absent(),
    this.discount = const Value.absent(),
    this.note = const Value.absent(),
    this.evidencePath = const Value.absent(),
    this.ocrSource = const Value.absent(),
    required String syncStatus,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       createdAt = Value(createdAt),
       walletId = Value(walletId),
       walletName = Value(walletName),
       categoryId = Value(categoryId),
       categoryName = Value(categoryName),
       syncStatus = Value(syncStatus);
  static Insertable<TransactionEntry> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<String>? walletId,
    Expression<String>? walletName,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? amount,
    Expression<int>? discount,
    Expression<String>? note,
    Expression<String>? evidencePath,
    Expression<String>? ocrSource,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (walletId != null) 'wallet_id': walletId,
      if (walletName != null) 'wallet_name': walletName,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (amount != null) 'amount': amount,
      if (discount != null) 'discount': discount,
      if (note != null) 'note': note,
      if (evidencePath != null) 'evidence_path': evidencePath,
      if (ocrSource != null) 'ocr_source': ocrSource,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<DateTime>? createdAt,
    Value<String>? walletId,
    Value<String>? walletName,
    Value<String>? categoryId,
    Value<String>? categoryName,
    Value<int>? amount,
    Value<int>? discount,
    Value<String>? note,
    Value<String?>? evidencePath,
    Value<String?>? ocrSource,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TransactionEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      walletId: walletId ?? this.walletId,
      walletName: walletName ?? this.walletName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      note: note ?? this.note,
      evidencePath: evidencePath ?? this.evidencePath,
      ocrSource: ocrSource ?? this.ocrSource,
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
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (walletName.present) {
      map['wallet_name'] = Variable<String>(walletName.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
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
    return (StringBuffer('TransactionEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('walletId: $walletId, ')
          ..write('walletName: $walletName, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('amount: $amount, ')
          ..write('discount: $discount, ')
          ..write('note: $note, ')
          ..write('evidencePath: $evidencePath, ')
          ..write('ocrSource: $ocrSource, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionLineEntriesTable extends TransactionLineEntries
    with TableInfo<$TransactionLineEntriesTable, TransactionLineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionLineEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  @override
  List<GeneratedColumn> get $columns => [
    rowId,
    transactionId,
    productId,
    productName,
    quantity,
    unit,
    unitPrice,
    costPrice,
    segment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_line_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionLineEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
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
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  TransactionLineEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionLineEntry(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
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
    );
  }

  @override
  $TransactionLineEntriesTable createAlias(String alias) {
    return $TransactionLineEntriesTable(attachedDatabase, alias);
  }
}

class TransactionLineEntry extends DataClass
    implements Insertable<TransactionLineEntry> {
  final int rowId;
  final String transactionId;
  final String productId;
  final String productName;
  final int quantity;
  final String unit;
  final int unitPrice;
  final int costPrice;
  final String segment;
  const TransactionLineEntry({
    required this.rowId,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.costPrice,
    required this.segment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['transaction_id'] = Variable<String>(transactionId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['quantity'] = Variable<int>(quantity);
    map['unit'] = Variable<String>(unit);
    map['unit_price'] = Variable<int>(unitPrice);
    map['cost_price'] = Variable<int>(costPrice);
    map['segment'] = Variable<String>(segment);
    return map;
  }

  TransactionLineEntriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionLineEntriesCompanion(
      rowId: Value(rowId),
      transactionId: Value(transactionId),
      productId: Value(productId),
      productName: Value(productName),
      quantity: Value(quantity),
      unit: Value(unit),
      unitPrice: Value(unitPrice),
      costPrice: Value(costPrice),
      segment: Value(segment),
    );
  }

  factory TransactionLineEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionLineEntry(
      rowId: serializer.fromJson<int>(json['rowId']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      costPrice: serializer.fromJson<int>(json['costPrice']),
      segment: serializer.fromJson<String>(json['segment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rowId': serializer.toJson<int>(rowId),
      'transactionId': serializer.toJson<String>(transactionId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(unit),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'costPrice': serializer.toJson<int>(costPrice),
      'segment': serializer.toJson<String>(segment),
    };
  }

  TransactionLineEntry copyWith({
    int? rowId,
    String? transactionId,
    String? productId,
    String? productName,
    int? quantity,
    String? unit,
    int? unitPrice,
    int? costPrice,
    String? segment,
  }) => TransactionLineEntry(
    rowId: rowId ?? this.rowId,
    transactionId: transactionId ?? this.transactionId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    costPrice: costPrice ?? this.costPrice,
    segment: segment ?? this.segment,
  );
  TransactionLineEntry copyWithCompanion(TransactionLineEntriesCompanion data) {
    return TransactionLineEntry(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      segment: data.segment.present ? data.segment.value : this.segment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLineEntry(')
          ..write('rowId: $rowId, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('segment: $segment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rowId,
    transactionId,
    productId,
    productName,
    quantity,
    unit,
    unitPrice,
    costPrice,
    segment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionLineEntry &&
          other.rowId == this.rowId &&
          other.transactionId == this.transactionId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.costPrice == this.costPrice &&
          other.segment == this.segment);
}

class TransactionLineEntriesCompanion
    extends UpdateCompanion<TransactionLineEntry> {
  final Value<int> rowId;
  final Value<String> transactionId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<int> quantity;
  final Value<String> unit;
  final Value<int> unitPrice;
  final Value<int> costPrice;
  final Value<String> segment;
  const TransactionLineEntriesCompanion({
    this.rowId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.segment = const Value.absent(),
  });
  TransactionLineEntriesCompanion.insert({
    this.rowId = const Value.absent(),
    required String transactionId,
    required String productId,
    required String productName,
    this.quantity = const Value.absent(),
    required String unit,
    this.unitPrice = const Value.absent(),
    this.costPrice = const Value.absent(),
    required String segment,
  }) : transactionId = Value(transactionId),
       productId = Value(productId),
       productName = Value(productName),
       unit = Value(unit),
       segment = Value(segment);
  static Insertable<TransactionLineEntry> custom({
    Expression<int>? rowId,
    Expression<String>? transactionId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<int>? unitPrice,
    Expression<int>? costPrice,
    Expression<String>? segment,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (costPrice != null) 'cost_price': costPrice,
      if (segment != null) 'segment': segment,
    });
  }

  TransactionLineEntriesCompanion copyWith({
    Value<int>? rowId,
    Value<String>? transactionId,
    Value<String>? productId,
    Value<String>? productName,
    Value<int>? quantity,
    Value<String>? unit,
    Value<int>? unitPrice,
    Value<int>? costPrice,
    Value<String>? segment,
  }) {
    return TransactionLineEntriesCompanion(
      rowId: rowId ?? this.rowId,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      segment: segment ?? this.segment,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLineEntriesCompanion(')
          ..write('rowId: $rowId, ')
          ..write('transactionId: $transactionId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('costPrice: $costPrice, ')
          ..write('segment: $segment')
          ..write(')'))
        .toString();
  }
}

class $AppSettingEntriesTable extends AppSettingEntries
    with TableInfo<$AppSettingEntriesTable, AppSettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_setting_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingEntry> instance, {
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
  AppSettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingEntry(
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
  $AppSettingEntriesTable createAlias(String alias) {
    return $AppSettingEntriesTable(attachedDatabase, alias);
  }
}

class AppSettingEntry extends DataClass implements Insertable<AppSettingEntry> {
  final String key;
  final String value;
  const AppSettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return AppSettingEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingEntry(
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

  AppSettingEntry copyWith({String? key, String? value}) =>
      AppSettingEntry(key: key ?? this.key, value: value ?? this.value);
  AppSettingEntry copyWithCompanion(AppSettingEntriesCompanion data) {
    return AppSettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingEntry(')
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
      (other is AppSettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingEntriesCompanion extends UpdateCompanion<AppSettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingEntry> custom({
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

  AppSettingEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingEntriesCompanion(
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
    return (StringBuffer('AppSettingEntriesCompanion(')
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
  late final $ProductCategoryEntriesTable productCategoryEntries =
      $ProductCategoryEntriesTable(this);
  late final $ProductEntriesTable productEntries = $ProductEntriesTable(this);
  late final $WalletEntriesTable walletEntries = $WalletEntriesTable(this);
  late final $LedgerCategoryEntriesTable ledgerCategoryEntries =
      $LedgerCategoryEntriesTable(this);
  late final $TransactionEntriesTable transactionEntries =
      $TransactionEntriesTable(this);
  late final $TransactionLineEntriesTable transactionLineEntries =
      $TransactionLineEntriesTable(this);
  late final $AppSettingEntriesTable appSettingEntries =
      $AppSettingEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productCategoryEntries,
    productEntries,
    walletEntries,
    ledgerCategoryEntries,
    transactionEntries,
    transactionLineEntries,
    appSettingEntries,
  ];
}

typedef $$ProductCategoryEntriesTableCreateCompanionBuilder =
    ProductCategoryEntriesCompanion Function({
      required String name,
      Value<int> position,
      Value<int> rowid,
    });
typedef $$ProductCategoryEntriesTableUpdateCompanionBuilder =
    ProductCategoryEntriesCompanion Function({
      Value<String> name,
      Value<int> position,
      Value<int> rowid,
    });

class $$ProductCategoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductCategoryEntriesTable> {
  $$ProductCategoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductCategoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductCategoryEntriesTable> {
  $$ProductCategoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductCategoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductCategoryEntriesTable> {
  $$ProductCategoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$ProductCategoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductCategoryEntriesTable,
          ProductCategoryEntry,
          $$ProductCategoryEntriesTableFilterComposer,
          $$ProductCategoryEntriesTableOrderingComposer,
          $$ProductCategoryEntriesTableAnnotationComposer,
          $$ProductCategoryEntriesTableCreateCompanionBuilder,
          $$ProductCategoryEntriesTableUpdateCompanionBuilder,
          (
            ProductCategoryEntry,
            BaseReferences<
              _$AppDatabase,
              $ProductCategoryEntriesTable,
              ProductCategoryEntry
            >,
          ),
          ProductCategoryEntry,
          PrefetchHooks Function()
        > {
  $$ProductCategoryEntriesTableTableManager(
    _$AppDatabase db,
    $ProductCategoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductCategoryEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ProductCategoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductCategoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCategoryEntriesCompanion(
                name: name,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductCategoryEntriesCompanion.insert(
                name: name,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductCategoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductCategoryEntriesTable,
      ProductCategoryEntry,
      $$ProductCategoryEntriesTableFilterComposer,
      $$ProductCategoryEntriesTableOrderingComposer,
      $$ProductCategoryEntriesTableAnnotationComposer,
      $$ProductCategoryEntriesTableCreateCompanionBuilder,
      $$ProductCategoryEntriesTableUpdateCompanionBuilder,
      (
        ProductCategoryEntry,
        BaseReferences<
          _$AppDatabase,
          $ProductCategoryEntriesTable,
          ProductCategoryEntry
        >,
      ),
      ProductCategoryEntry,
      PrefetchHooks Function()
    >;
typedef $$ProductEntriesTableCreateCompanionBuilder =
    ProductEntriesCompanion Function({
      required String id,
      required String name,
      required String category,
      Value<int> costPrice,
      Value<int> retailPrice,
      Value<int> wholesalePrice,
      Value<int> packSize,
      Value<int> cartonSize,
      Value<int> stockPcs,
      Value<int> rowid,
    });
typedef $$ProductEntriesTableUpdateCompanionBuilder =
    ProductEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<int> costPrice,
      Value<int> retailPrice,
      Value<int> wholesalePrice,
      Value<int> packSize,
      Value<int> cartonSize,
      Value<int> stockPcs,
      Value<int> rowid,
    });

class $$ProductEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductEntriesTable> {
  $$ProductEntriesTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnFilters<int> get stockPcs => $composableBuilder(
    column: $table.stockPcs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductEntriesTable> {
  $$ProductEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
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

  ColumnOrderings<int> get stockPcs => $composableBuilder(
    column: $table.stockPcs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductEntriesTable> {
  $$ProductEntriesTableAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

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

  GeneratedColumn<int> get stockPcs =>
      $composableBuilder(column: $table.stockPcs, builder: (column) => column);
}

class $$ProductEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductEntriesTable,
          ProductEntry,
          $$ProductEntriesTableFilterComposer,
          $$ProductEntriesTableOrderingComposer,
          $$ProductEntriesTableAnnotationComposer,
          $$ProductEntriesTableCreateCompanionBuilder,
          $$ProductEntriesTableUpdateCompanionBuilder,
          (
            ProductEntry,
            BaseReferences<_$AppDatabase, $ProductEntriesTable, ProductEntry>,
          ),
          ProductEntry,
          PrefetchHooks Function()
        > {
  $$ProductEntriesTableTableManager(
    _$AppDatabase db,
    $ProductEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<int> retailPrice = const Value.absent(),
                Value<int> wholesalePrice = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<int> cartonSize = const Value.absent(),
                Value<int> stockPcs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductEntriesCompanion(
                id: id,
                name: name,
                category: category,
                costPrice: costPrice,
                retailPrice: retailPrice,
                wholesalePrice: wholesalePrice,
                packSize: packSize,
                cartonSize: cartonSize,
                stockPcs: stockPcs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                Value<int> costPrice = const Value.absent(),
                Value<int> retailPrice = const Value.absent(),
                Value<int> wholesalePrice = const Value.absent(),
                Value<int> packSize = const Value.absent(),
                Value<int> cartonSize = const Value.absent(),
                Value<int> stockPcs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductEntriesCompanion.insert(
                id: id,
                name: name,
                category: category,
                costPrice: costPrice,
                retailPrice: retailPrice,
                wholesalePrice: wholesalePrice,
                packSize: packSize,
                cartonSize: cartonSize,
                stockPcs: stockPcs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductEntriesTable,
      ProductEntry,
      $$ProductEntriesTableFilterComposer,
      $$ProductEntriesTableOrderingComposer,
      $$ProductEntriesTableAnnotationComposer,
      $$ProductEntriesTableCreateCompanionBuilder,
      $$ProductEntriesTableUpdateCompanionBuilder,
      (
        ProductEntry,
        BaseReferences<_$AppDatabase, $ProductEntriesTable, ProductEntry>,
      ),
      ProductEntry,
      PrefetchHooks Function()
    >;
typedef $$WalletEntriesTableCreateCompanionBuilder =
    WalletEntriesCompanion Function({
      required String id,
      required String name,
      Value<int> balance,
      Value<bool> isPrimary,
      Value<int> rowid,
    });
typedef $$WalletEntriesTableUpdateCompanionBuilder =
    WalletEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> balance,
      Value<bool> isPrimary,
      Value<int> rowid,
    });

class $$WalletEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WalletEntriesTable> {
  $$WalletEntriesTableFilterComposer({
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
}

class $$WalletEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletEntriesTable> {
  $$WalletEntriesTableOrderingComposer({
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
}

class $$WalletEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletEntriesTable> {
  $$WalletEntriesTableAnnotationComposer({
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
}

class $$WalletEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletEntriesTable,
          WalletEntry,
          $$WalletEntriesTableFilterComposer,
          $$WalletEntriesTableOrderingComposer,
          $$WalletEntriesTableAnnotationComposer,
          $$WalletEntriesTableCreateCompanionBuilder,
          $$WalletEntriesTableUpdateCompanionBuilder,
          (
            WalletEntry,
            BaseReferences<_$AppDatabase, $WalletEntriesTable, WalletEntry>,
          ),
          WalletEntry,
          PrefetchHooks Function()
        > {
  $$WalletEntriesTableTableManager(_$AppDatabase db, $WalletEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletEntriesCompanion(
                id: id,
                name: name,
                balance: balance,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> balance = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletEntriesCompanion.insert(
                id: id,
                name: name,
                balance: balance,
                isPrimary: isPrimary,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletEntriesTable,
      WalletEntry,
      $$WalletEntriesTableFilterComposer,
      $$WalletEntriesTableOrderingComposer,
      $$WalletEntriesTableAnnotationComposer,
      $$WalletEntriesTableCreateCompanionBuilder,
      $$WalletEntriesTableUpdateCompanionBuilder,
      (
        WalletEntry,
        BaseReferences<_$AppDatabase, $WalletEntriesTable, WalletEntry>,
      ),
      WalletEntry,
      PrefetchHooks Function()
    >;
typedef $$LedgerCategoryEntriesTableCreateCompanionBuilder =
    LedgerCategoryEntriesCompanion Function({
      required String id,
      required String name,
      required String direction,
      Value<bool> isSystem,
      Value<int> rowid,
    });
typedef $$LedgerCategoryEntriesTableUpdateCompanionBuilder =
    LedgerCategoryEntriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> direction,
      Value<bool> isSystem,
      Value<int> rowid,
    });

class $$LedgerCategoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerCategoryEntriesTable> {
  $$LedgerCategoryEntriesTableFilterComposer({
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
}

class $$LedgerCategoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerCategoryEntriesTable> {
  $$LedgerCategoryEntriesTableOrderingComposer({
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
}

class $$LedgerCategoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerCategoryEntriesTable> {
  $$LedgerCategoryEntriesTableAnnotationComposer({
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
}

class $$LedgerCategoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerCategoryEntriesTable,
          LedgerCategoryEntry,
          $$LedgerCategoryEntriesTableFilterComposer,
          $$LedgerCategoryEntriesTableOrderingComposer,
          $$LedgerCategoryEntriesTableAnnotationComposer,
          $$LedgerCategoryEntriesTableCreateCompanionBuilder,
          $$LedgerCategoryEntriesTableUpdateCompanionBuilder,
          (
            LedgerCategoryEntry,
            BaseReferences<
              _$AppDatabase,
              $LedgerCategoryEntriesTable,
              LedgerCategoryEntry
            >,
          ),
          LedgerCategoryEntry,
          PrefetchHooks Function()
        > {
  $$LedgerCategoryEntriesTableTableManager(
    _$AppDatabase db,
    $LedgerCategoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerCategoryEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LedgerCategoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LedgerCategoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoryEntriesCompanion(
                id: id,
                name: name,
                direction: direction,
                isSystem: isSystem,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String direction,
                Value<bool> isSystem = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerCategoryEntriesCompanion.insert(
                id: id,
                name: name,
                direction: direction,
                isSystem: isSystem,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LedgerCategoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerCategoryEntriesTable,
      LedgerCategoryEntry,
      $$LedgerCategoryEntriesTableFilterComposer,
      $$LedgerCategoryEntriesTableOrderingComposer,
      $$LedgerCategoryEntriesTableAnnotationComposer,
      $$LedgerCategoryEntriesTableCreateCompanionBuilder,
      $$LedgerCategoryEntriesTableUpdateCompanionBuilder,
      (
        LedgerCategoryEntry,
        BaseReferences<
          _$AppDatabase,
          $LedgerCategoryEntriesTable,
          LedgerCategoryEntry
        >,
      ),
      LedgerCategoryEntry,
      PrefetchHooks Function()
    >;
typedef $$TransactionEntriesTableCreateCompanionBuilder =
    TransactionEntriesCompanion Function({
      required String id,
      required String kind,
      required DateTime createdAt,
      required String walletId,
      required String walletName,
      required String categoryId,
      required String categoryName,
      Value<int> amount,
      Value<int> discount,
      Value<String> note,
      Value<String?> evidencePath,
      Value<String?> ocrSource,
      required String syncStatus,
      Value<int> rowid,
    });
typedef $$TransactionEntriesTableUpdateCompanionBuilder =
    TransactionEntriesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<DateTime> createdAt,
      Value<String> walletId,
      Value<String> walletName,
      Value<String> categoryId,
      Value<String> categoryName,
      Value<int> amount,
      Value<int> discount,
      Value<String> note,
      Value<String?> evidencePath,
      Value<String?> ocrSource,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$TransactionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
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

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
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

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionEntriesTable> {
  $$TransactionEntriesTableAnnotationComposer({
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get walletId =>
      $composableBuilder(column: $table.walletId, builder: (column) => column);

  GeneratedColumn<String> get walletName => $composableBuilder(
    column: $table.walletName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
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

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TransactionEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionEntriesTable,
          TransactionEntry,
          $$TransactionEntriesTableFilterComposer,
          $$TransactionEntriesTableOrderingComposer,
          $$TransactionEntriesTableAnnotationComposer,
          $$TransactionEntriesTableCreateCompanionBuilder,
          $$TransactionEntriesTableUpdateCompanionBuilder,
          (
            TransactionEntry,
            BaseReferences<
              _$AppDatabase,
              $TransactionEntriesTable,
              TransactionEntry
            >,
          ),
          TransactionEntry,
          PrefetchHooks Function()
        > {
  $$TransactionEntriesTableTableManager(
    _$AppDatabase db,
    $TransactionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> walletId = const Value.absent(),
                Value<String> walletName = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> categoryName = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> discount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> evidencePath = const Value.absent(),
                Value<String?> ocrSource = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionEntriesCompanion(
                id: id,
                kind: kind,
                createdAt: createdAt,
                walletId: walletId,
                walletName: walletName,
                categoryId: categoryId,
                categoryName: categoryName,
                amount: amount,
                discount: discount,
                note: note,
                evidencePath: evidencePath,
                ocrSource: ocrSource,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required DateTime createdAt,
                required String walletId,
                required String walletName,
                required String categoryId,
                required String categoryName,
                Value<int> amount = const Value.absent(),
                Value<int> discount = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String?> evidencePath = const Value.absent(),
                Value<String?> ocrSource = const Value.absent(),
                required String syncStatus,
                Value<int> rowid = const Value.absent(),
              }) => TransactionEntriesCompanion.insert(
                id: id,
                kind: kind,
                createdAt: createdAt,
                walletId: walletId,
                walletName: walletName,
                categoryId: categoryId,
                categoryName: categoryName,
                amount: amount,
                discount: discount,
                note: note,
                evidencePath: evidencePath,
                ocrSource: ocrSource,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionEntriesTable,
      TransactionEntry,
      $$TransactionEntriesTableFilterComposer,
      $$TransactionEntriesTableOrderingComposer,
      $$TransactionEntriesTableAnnotationComposer,
      $$TransactionEntriesTableCreateCompanionBuilder,
      $$TransactionEntriesTableUpdateCompanionBuilder,
      (
        TransactionEntry,
        BaseReferences<
          _$AppDatabase,
          $TransactionEntriesTable,
          TransactionEntry
        >,
      ),
      TransactionEntry,
      PrefetchHooks Function()
    >;
typedef $$TransactionLineEntriesTableCreateCompanionBuilder =
    TransactionLineEntriesCompanion Function({
      Value<int> rowId,
      required String transactionId,
      required String productId,
      required String productName,
      Value<int> quantity,
      required String unit,
      Value<int> unitPrice,
      Value<int> costPrice,
      required String segment,
    });
typedef $$TransactionLineEntriesTableUpdateCompanionBuilder =
    TransactionLineEntriesCompanion Function({
      Value<int> rowId,
      Value<String> transactionId,
      Value<String> productId,
      Value<String> productName,
      Value<int> quantity,
      Value<String> unit,
      Value<int> unitPrice,
      Value<int> costPrice,
      Value<String> segment,
    });

class $$TransactionLineEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionLineEntriesTable> {
  $$TransactionLineEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
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
}

class $$TransactionLineEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionLineEntriesTable> {
  $$TransactionLineEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
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
}

class $$TransactionLineEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionLineEntriesTable> {
  $$TransactionLineEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);
}

class $$TransactionLineEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionLineEntriesTable,
          TransactionLineEntry,
          $$TransactionLineEntriesTableFilterComposer,
          $$TransactionLineEntriesTableOrderingComposer,
          $$TransactionLineEntriesTableAnnotationComposer,
          $$TransactionLineEntriesTableCreateCompanionBuilder,
          $$TransactionLineEntriesTableUpdateCompanionBuilder,
          (
            TransactionLineEntry,
            BaseReferences<
              _$AppDatabase,
              $TransactionLineEntriesTable,
              TransactionLineEntry
            >,
          ),
          TransactionLineEntry,
          PrefetchHooks Function()
        > {
  $$TransactionLineEntriesTableTableManager(
    _$AppDatabase db,
    $TransactionLineEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionLineEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionLineEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionLineEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                Value<String> segment = const Value.absent(),
              }) => TransactionLineEntriesCompanion(
                rowId: rowId,
                transactionId: transactionId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                costPrice: costPrice,
                segment: segment,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String transactionId,
                required String productId,
                required String productName,
                Value<int> quantity = const Value.absent(),
                required String unit,
                Value<int> unitPrice = const Value.absent(),
                Value<int> costPrice = const Value.absent(),
                required String segment,
              }) => TransactionLineEntriesCompanion.insert(
                rowId: rowId,
                transactionId: transactionId,
                productId: productId,
                productName: productName,
                quantity: quantity,
                unit: unit,
                unitPrice: unitPrice,
                costPrice: costPrice,
                segment: segment,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionLineEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionLineEntriesTable,
      TransactionLineEntry,
      $$TransactionLineEntriesTableFilterComposer,
      $$TransactionLineEntriesTableOrderingComposer,
      $$TransactionLineEntriesTableAnnotationComposer,
      $$TransactionLineEntriesTableCreateCompanionBuilder,
      $$TransactionLineEntriesTableUpdateCompanionBuilder,
      (
        TransactionLineEntry,
        BaseReferences<
          _$AppDatabase,
          $TransactionLineEntriesTable,
          TransactionLineEntry
        >,
      ),
      TransactionLineEntry,
      PrefetchHooks Function()
    >;
typedef $$AppSettingEntriesTableCreateCompanionBuilder =
    AppSettingEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingEntriesTableUpdateCompanionBuilder =
    AppSettingEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingEntriesTable> {
  $$AppSettingEntriesTableFilterComposer({
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

class $$AppSettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingEntriesTable> {
  $$AppSettingEntriesTableOrderingComposer({
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

class $$AppSettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingEntriesTable> {
  $$AppSettingEntriesTableAnnotationComposer({
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

class $$AppSettingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingEntriesTable,
          AppSettingEntry,
          $$AppSettingEntriesTableFilterComposer,
          $$AppSettingEntriesTableOrderingComposer,
          $$AppSettingEntriesTableAnnotationComposer,
          $$AppSettingEntriesTableCreateCompanionBuilder,
          $$AppSettingEntriesTableUpdateCompanionBuilder,
          (
            AppSettingEntry,
            BaseReferences<
              _$AppDatabase,
              $AppSettingEntriesTable,
              AppSettingEntry
            >,
          ),
          AppSettingEntry,
          PrefetchHooks Function()
        > {
  $$AppSettingEntriesTableTableManager(
    _$AppDatabase db,
    $AppSettingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingEntriesTable,
      AppSettingEntry,
      $$AppSettingEntriesTableFilterComposer,
      $$AppSettingEntriesTableOrderingComposer,
      $$AppSettingEntriesTableAnnotationComposer,
      $$AppSettingEntriesTableCreateCompanionBuilder,
      $$AppSettingEntriesTableUpdateCompanionBuilder,
      (
        AppSettingEntry,
        BaseReferences<_$AppDatabase, $AppSettingEntriesTable, AppSettingEntry>,
      ),
      AppSettingEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductCategoryEntriesTableTableManager get productCategoryEntries =>
      $$ProductCategoryEntriesTableTableManager(
        _db,
        _db.productCategoryEntries,
      );
  $$ProductEntriesTableTableManager get productEntries =>
      $$ProductEntriesTableTableManager(_db, _db.productEntries);
  $$WalletEntriesTableTableManager get walletEntries =>
      $$WalletEntriesTableTableManager(_db, _db.walletEntries);
  $$LedgerCategoryEntriesTableTableManager get ledgerCategoryEntries =>
      $$LedgerCategoryEntriesTableTableManager(_db, _db.ledgerCategoryEntries);
  $$TransactionEntriesTableTableManager get transactionEntries =>
      $$TransactionEntriesTableTableManager(_db, _db.transactionEntries);
  $$TransactionLineEntriesTableTableManager get transactionLineEntries =>
      $$TransactionLineEntriesTableTableManager(
        _db,
        _db.transactionLineEntries,
      );
  $$AppSettingEntriesTableTableManager get appSettingEntries =>
      $$AppSettingEntriesTableTableManager(_db, _db.appSettingEntries);
}
