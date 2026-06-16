import 'app_database.dart';

class DatabaseSeedService {
  const DatabaseSeedService(this._database);

  final AppDatabase _database;

  Future<bool> seedIfEmpty(Future<void> Function() seed) async {
    final empty = await isEmpty();
    if (!empty) return false;

    await seed();
    return true;
  }

  Future<bool> isEmpty() async {
    final hasProduct = await (_database.select(
      _database.products,
    )..limit(1)).getSingleOrNull();
    final hasWallet = await (_database.select(
      _database.wallets,
    )..limit(1)).getSingleOrNull();
    final hasTransactionCategory = await (_database.select(
      _database.transactionCategories,
    )..limit(1)).getSingleOrNull();
    final hasTransaction = await (_database.select(
      _database.transactions,
    )..limit(1)).getSingleOrNull();

    return hasProduct == null &&
        hasWallet == null &&
        hasTransactionCategory == null &&
        hasTransaction == null;
  }
}
