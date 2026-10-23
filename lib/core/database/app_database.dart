import 'package:drift/drift.dart';

import 'database_connection.dart'
    if (dart.library.io) 'database_connection_io.dart';

part 'app_database.g.dart';

@DataClassName('ProductCategoryRow')
class ProductCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProductRow')
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId =>
      text().nullable().references(ProductCategories, #id)();
  TextColumn get categoryNameSnapshot =>
      text().withDefault(const Constant('Lain-lain'))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get retailPrice => integer().withDefault(const Constant(0))();
  IntColumn get wholesalePrice => integer().withDefault(const Constant(0))();
  IntColumn get packSize => integer().withDefault(const Constant(1))();
  IntColumn get cartonSize => integer().withDefault(const Constant(1))();
  RealColumn get stockPcs => real().withDefault(const Constant(0.0))();
  BoolColumn get trackStock => boolean().withDefault(const Constant(true))();
  TextColumn get baseUnit => text().withDefault(const Constant('pcs'))();
  RealColumn get minStock => real().withDefault(const Constant(5.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WalletRow')
class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionCategoryRow')
class TransactionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get direction => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  TextColumn get walletNameSnapshot => text()();
  TextColumn get categoryId =>
      text().nullable().references(TransactionCategories, #id)();
  TextColumn get categoryNameSnapshot => text()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get evidencePath => text().nullable()();
  TextColumn get ocrSource => text().nullable()();
  TextColumn get rawVoiceText => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('localOnly'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TransactionLineRow')
class TransactionLines extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get productNameSnapshot => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  TextColumn get unit => text()();
  IntColumn get unitPrice => integer().withDefault(const Constant(0))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  TextColumn get segment => text()();
  RealColumn get unitMultiplier => real().withDefault(const Constant(1.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BusinessProfileRow')
class BusinessProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get ownerName => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get businessName => text()();
  TextColumn get businessCategory => text()();
  TextColumn get businessLocation => text()();
  TextColumn get memberSince => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('VoiceProductAliasRow')
class VoiceProductAliases extends Table {
  TextColumn get id => text()();
  TextColumn get aliasText => text()();
  TextColumn get normalizedAlias => text()();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get canonicalProductName => text()();
  IntColumn get hitCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {normalizedAlias},
  ];
}

@DataClassName('VoiceUnitAliasRow')
class VoiceUnitAliases extends Table {
  TextColumn get id => text()();
  TextColumn get aliasText => text()();
  TextColumn get normalizedAlias => text()();
  TextColumn get canonicalUnit => text()();
  IntColumn get hitCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {normalizedAlias},
  ];
}

@DataClassName('VoiceCorrectionRow')
class VoiceCorrections extends Table {
  TextColumn get id => text()();
  TextColumn get rawText => text()();
  TextColumn get parsedProductName => text().nullable()();
  TextColumn get correctedProductName => text()();
  TextColumn get parsedUnit => text().nullable()();
  TextColumn get correctedUnit => text()();
  RealColumn get parsedQuantity => real().nullable()();
  RealColumn get correctedQuantity => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VoiceActionAuditRow')
class VoiceActionAudits extends Table {
  TextColumn get id => text()();
  TextColumn get actionId => text()();
  TextColumn get actionType => text()();
  TextColumn get source => text()();
  TextColumn get status => text()();
  TextColumn get targetEntityType => text().nullable()();
  TextColumn get targetEntityId => text().nullable()();
  TextColumn get beforeSummary => text().withDefault(const Constant(''))();
  TextColumn get afterSummary => text().withDefault(const Constant(''))();
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  BoolColumn get authRequired =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get authSucceeded =>
      boolean().withDefault(const Constant(false))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get undoStatus => text().withDefault(const Constant('notAvailable'))();
  TextColumn get commandFingerprint => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {actionId, status},
  ];
}

@DriftDatabase(
  tables: [
    ProductCategories,
    Products,
    Wallets,
    TransactionCategories,
    Transactions,
    TransactionLines,
    BusinessProfiles,
    AppSettings,
    VoiceProductAliases,
    VoiceUnitAliases,
    VoiceCorrections,
    VoiceActionAudits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDatabaseConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createAll();
        return;
      }
      if (from < 3) {
        await migrator.alterTable(
          TableMigration(
            products,
            newColumns: [
              products.trackStock,
              products.baseUnit,
              products.minStock,
            ],
          ),
        );
        await migrator.alterTable(TableMigration(transactionLines));
      }
      if (from < 4) {
        await migrator.createTable(voiceProductAliases);
        await migrator.createTable(voiceUnitAliases);
        await migrator.createTable(voiceCorrections);
      }
      if (from >= 3 && from < 5) {
        await migrator.addColumn(products, products.trackStock);
        await migrator.addColumn(products, products.baseUnit);
        await migrator.addColumn(products, products.minStock);
      }
      if (from < 5) {
        // Preserve the old behavior: positive stock was controlled, while zero
        // stock was treated as an unlimited/untracked catalog item.
        await customStatement(
          'UPDATE products '
          'SET track_stock = CASE WHEN stock_pcs > 0 THEN 1 ELSE 0 END, '
          "base_unit = 'pcs', min_stock = 5",
        );
      }
      if (from >= 3 && from < 6) {
        await migrator.alterTable(TableMigration(transactionLines));
      }
      if (from < 6) {
        await migrator.createTable(voiceActionAudits);
      }
    },
  );
}
