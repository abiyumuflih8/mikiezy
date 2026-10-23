import '../models/mikiezy_models.dart';
import 'voice/voice_unit_dictionary.dart';

class VoiceTransactionParser {
  static const _numbers = <String, int>{
    'nol': 0,
    'satu': 1,
    'se': 1,
    'sebuah': 1,
    'dua': 2,
    'tiga': 3,
    'empat': 4,
    'lima': 5,
    'enam': 6,
    'tujuh': 7,
    'delapan': 8,
    'sembilan': 9,
    'sepuluh': 10,
    'sebelas': 11,
    'dua belas': 12,
    'tiga belas': 13,
    'empat belas': 14,
    'lima belas': 15,
    'dua puluh': 20,
  };

  TransactionDraft parse(String input) {
    final normalized = input.toLowerCase().trim();
    final kind = _detectKind(normalized);
    final amount = _extractAmount(normalized);
    final discount = _extractDiscount(normalized);
    final unit = _detectUnit(normalized);
    final segment = normalized.contains('grosir')
        ? PriceSegment.wholesale
        : PriceSegment.retail;
    final category = _detectCategory(normalized, kind);
    final product = kind == TransactionKind.sale
        ? _extractProduct(normalized)
        : category;
    final double quantity = kind == TransactionKind.sale
        ? _extractQuantity(normalized)
        : 1.0;

    return TransactionDraft(
      kind: kind,
      productName: product,
      quantity: quantity,
      unit: unit,
      unitPrice: amount,
      discount: kind == TransactionKind.sale ? discount : 0,
      categoryName: category,
      walletName: 'Dompet Utama',
      segment: segment,
      note: normalized,
      rawText: input,
    );
  }

  TransactionKind _detectKind(String text) {
    if (_containsAny(text, [
      'pengeluaran',
      'bayar',
      'beli',
      'belanja',
      'tagihan',
      'transport',
    ])) {
      return TransactionKind.expense;
    }
    if (_containsAny(text, [
      'modal masuk',
      'pemasukan',
      'terima uang',
      'top up',
    ])) {
      return TransactionKind.income;
    }
    if (_containsAny(text, ['penyesuaian saldo', 'koreksi saldo'])) {
      return TransactionKind.adjustment;
    }
    return TransactionKind.sale;
  }

  String _detectCategory(String text, TransactionKind kind) {
    if (kind == TransactionKind.sale) return 'Penjualan';
    if (_containsAny(text, [
      'bahan baku',
      'beras',
      'minyak',
      'gula',
      'tepung',
    ])) {
      return 'Bahan baku';
    }
    if (_containsAny(text, ['belanja barang', 'stok', 'supplier', 'kulakan'])) {
      return 'Belanja barang';
    }
    if (_containsAny(text, ['jasa', 'servis', 'service'])) return 'Jasa';
    if (_containsAny(text, ['tagihan', 'listrik', 'air', 'internet'])) {
      return 'Tagihan';
    }
    if (_containsAny(text, ['transport', 'bensin', 'parkir', 'ojek'])) {
      return 'Transport';
    }
    if (_containsAny(text, ['sosial', 'donasi', 'iuran'])) return 'Sosial';
    if (_containsAny(text, ['modal'])) return 'Modal masuk';
    return kind == TransactionKind.expense ? 'Lain-lain' : 'Pemasukan lain';
  }

  SaleUnit _detectUnit(String text) {
    for (final token in text.split(RegExp(r'\s+'))) {
      final unit = VoiceUnitDictionary.canonicalUnit(token);
      if (unit != null) {
        return VoiceUnitDictionary.saleUnitFor(unit) ?? SaleUnit.pcs;
      }
    }
    return SaleUnit.pcs;
  }

  double _extractQuantity(String text) {
    final digitMatch = RegExp(
      r'\b(\d+(?:[,.]\d+)?)\s*([a-z]+)?\b',
    ).firstMatch(text);
    if (digitMatch != null) {
      return double.tryParse(
            (digitMatch.group(1) ?? '').replaceAll(',', '.'),
          ) ??
          1;
    }

    for (final entry in _numbers.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(text)) {
        return entry.value.toDouble();
      }
    }
    return 1;
  }

  int _extractAmount(String text) {
    final priceMatch = RegExp(
      r'(harga|sebesar|senilai|rp|bayar|modal)\s+([^,.;]+)',
    ).firstMatch(text);
    final source = (priceMatch?.group(2) ?? text)
        .split(RegExp(r'\bdiskon\b|\bgrosir\b|\bretail\b'))
        .first
        .trim();

    final digit = RegExp(
      r'(\d+)(?:[.,](\d{3}))?\s*(ribu|rb|jt|juta)?',
    ).firstMatch(source);
    if (digit != null) {
      final first = int.tryParse(digit.group(1) ?? '') ?? 0;
      final second = int.tryParse(digit.group(2) ?? '') ?? 0;
      final multiplier = _amountMultiplier(digit.group(3));
      if (second > 0) return first * 1000 + second;
      return first * multiplier;
    }

    final wordsAmount = _parseIndonesianAmount(source);
    return wordsAmount > 0 ? wordsAmount : 0;
  }

  int _extractDiscount(String text) {
    final match = RegExp(r'diskon\s+([^,.;]+)').firstMatch(text);
    if (match == null) return 0;
    final phrase = match.group(1) ?? '';
    if (phrase.contains('persen') || phrase.contains('%')) {
      return 0;
    }
    return _extractAmount(phrase);
  }

  String _extractProduct(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'\bmiki\b'), '')
        .replaceAll(RegExp(r'\bcatat\b'), '')
        .replaceAll(RegExp(r'\bjual\b'), '')
        .replaceAll(RegExp(r'\bpenjualan\b'), '')
        .replaceAll(RegExp(r'\bsold\b'), '')
        .trim();
    cleaned = cleaned
        .split(
          RegExp(
            r'\bharganya\b|\bharga\b|\bseharga\b|\bsenilai\b|\btotal\b|\bdiskon\b|\bgrosir\b|\bretail\b',
          ),
        )
        .first
        .trim();
    cleaned = cleaned
        .replaceAll(
          RegExp(r'\b(itu apa namanya|apa namanya|namanya|produk baru)\b'),
          '',
        )
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\b'), '').trim();
    for (final entry in _numbers.entries) {
      cleaned = cleaned.replaceAll(RegExp('\\b${entry.key}\\b'), '').trim();
    }
    cleaned = cleaned
        .replaceAll(
          RegExp(r'\b(pcs|porsi|buah|pack|pak|karton|dus|box|per)\b'),
          '',
        )
        .replaceAll(RegExp(r'^[\s,.;:-]+|[\s,.;:-]+$'), '')
        .trim();
    return cleaned.isEmpty ? '' : _titleCase(cleaned);
  }

  int _amountMultiplier(String? suffix) {
    if (suffix == null) return 1;
    if (suffix == 'jt' || suffix == 'juta') return 1000000;
    if (suffix == 'rb' || suffix == 'ribu') return 1000;
    return 1;
  }

  int _parseIndonesianAmount(String source) {
    final normalized = source
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\bseratus\b'), 'se ratus')
        .replaceAll(RegExp(r'\bseribu\b'), 'se ribu')
        .replaceAll(RegExp(r'\bsebelas\b'), 'se belas');
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where(_isNumberToken)
        .toList();
    if (tokens.isEmpty) return 0;

    var total = 0;
    var group = 0;
    var current = 0;
    for (final token in tokens) {
      final value = _singleNumberValue(token);
      if (value != null) {
        current = value;
        continue;
      }

      switch (token) {
        case 'belas':
          group += (current == 0 ? 1 : current) + 10;
          current = 0;
        case 'puluh':
          group += (current == 0 ? 1 : current) * 10;
          current = 0;
        case 'ratus':
          group += (current == 0 ? 1 : current) * 100;
          current = 0;
        case 'ribu':
        case 'rb':
          total += (group + current == 0 ? 1 : group + current) * 1000;
          group = 0;
          current = 0;
        case 'juta':
        case 'jt':
          total += (group + current == 0 ? 1 : group + current) * 1000000;
          group = 0;
          current = 0;
      }
    }
    return total + group + current;
  }

  bool _isNumberToken(String token) {
    return _singleNumberValue(token) != null ||
        const {
          'belas',
          'puluh',
          'ratus',
          'ribu',
          'rb',
          'juta',
          'jt',
        }.contains(token);
  }

  int? _singleNumberValue(String token) {
    return const {
      'nol': 0,
      'satu': 1,
      'se': 1,
      'dua': 2,
      'tiga': 3,
      'empat': 4,
      'lima': 5,
      'enam': 6,
      'tujuh': 7,
      'delapan': 8,
      'sembilan': 9,
      'sepuluh': 10,
    }[token];
  }

  bool _containsAny(String text, List<String> words) {
    return words.any(text.contains);
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
