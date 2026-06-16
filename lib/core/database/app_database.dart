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
  IntColumn get stockPcs => integer().withDefault(const Constant(0))();
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
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text()();
  IntColumn get unitPrice => integer().withDefault(const Constant(0))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  TextColumn get segment => text()();
  IntColumn get unitMultiplier => integer().withDefault(const Constant(1))();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDatabaseConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(productCategories);
        await migrator.createTable(products);
        await migrator.createTable(wallets);
        await migrator.createTable(transactionCategories);
        await migrator.createTable(transactions);
        await migrator.createTable(transactionLines);
        await migrator.createTable(businessProfiles);
        await migrator.createTable(appSettings);
      }
    },
  );
}
