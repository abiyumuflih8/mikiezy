import '../../models/mikiezy_models.dart';

class VoiceIntentDetector {
  const VoiceIntentDetector();

  TransactionKind detect(String text) {
    if (_containsAny(text, const ['jual', 'penjualan', 'terjual', 'laku'])) {
      return TransactionKind.sale;
    }
    if (_containsAny(text, const [
      'pengeluaran',
      'beli',
      'belanja',
      'bayar',
      'kulakan',
    ])) {
      return TransactionKind.expense;
    }
    if (_containsAny(text, const [
      'pemasukan',
      'terima uang',
      'pendapatan',
      'modal masuk',
      'setor',
    ])) {
      return TransactionKind.income;
    }
    if (_containsAny(text, const [
      'penyesuaian saldo',
      'koreksi saldo',
      'adjustment',
    ])) {
      return TransactionKind.adjustment;
    }
    return TransactionKind.sale;
  }

  bool _containsAny(String text, List<String> values) {
    return values.any(text.contains);
  }
}
