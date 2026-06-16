import 'package:drift/drift.dart';

import 'database_connection.dart'
    if (dart.library.io) 'database_connection_io.dart';

part 'app_database.g.dart';

class ProductCategoryEntries extends Table {
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class ProductEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  IntColumn get retailPrice => integer().withDefault(const Constant(0))();
  IntColumn get wholesalePrice => integer().withDefault(const Constant(0))();
  IntColumn get packSize => integer().withDefault(const Constant(1))();
  IntColumn get cartonSize => integer().withDefault(const Constant(1))();
  IntColumn get stockPcs => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WalletEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LedgerCategoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get direction => text()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionEntries extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get walletId => text()();
  TextColumn get walletName => text()();
  TextColumn get categoryId => text()();
  TextColumn get categoryName => text()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get evidencePath => text().nullable()();
  TextColumn get ocrSource => text().nullable()();
  TextColumn get syncStatus => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TransactionLineEntries extends Table {
  IntColumn get rowId => integer().autoIncrement()();
  TextColumn get transactionId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text()();
  IntColumn get unitPrice => integer().withDefault(const Constant(0))();
  IntColumn get costPrice => integer().withDefault(const Constant(0))();
  TextColumn get segment => text()();
}

class AppSettingEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ProductCategoryEntries,
    ProductEntries,
    WalletEntries,
    LedgerCategoryEntries,
    TransactionEntries,
    TransactionLineEntries,
    AppSettingEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openDatabaseConnection());

  @override
  int get schemaVersion => 1;
}
