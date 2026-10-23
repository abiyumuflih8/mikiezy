import '../../domain/models/product_unit.dart';
import '../../domain/services/quantity_formatter.dart';
import '../../domain/services/unit_normalizer.dart';
import '../../models/mikiezy_models.dart';
import 'voice_command.dart';
import 'voice_product_name_normalizer.dart';
import 'voice_product_resolver.dart';
import 'voice_stock_increment_entity_extractor.dart';

enum VoiceStockIncrementClarification {
  productName,
  productSelection,
  quantity,
  unit,
  trackingActivation,
}

class VoiceStockIncrementConversationTurn {
  const VoiceStockIncrementConversationTurn({
    this.response,
    this.readyCommand,
    this.routeAsNewCommand = false,
  });

  final VoiceCommandResponse? response;
  final VoiceCommand? readyCommand;
  final bool routeAsNewCommand;
}

class VoiceStockIncrementConversation {
  VoiceStockIncrementConversation({
    this.extractor = const VoiceStockIncrementEntityExtractor(),
    this.productResolver = const VoiceProductResolver(),
    this.unitNormalizer = const UnitNormalizer(),
    this.nameNormalizer = const VoiceProductNameNormalizer(),
    this.expiration = const Duration(minutes: 2),
    this.maximumInvalidAttempts = 3,
  });

  final VoiceStockIncrementEntityExtractor extractor;
  final VoiceProductResolver productResolver;
  final UnitNormalizer unitNormalizer;
  final VoiceProductNameNormalizer nameNormalizer;
  final Duration expiration;
  final int maximumInvalidAttempts;

  VoiceCommand? _command;
  VoiceCommandEntities? _entities;
  VoiceStockIncrementClarification? _clarification;
  DateTime? _expiresAt;
  int _invalidAttempts = 0;
  bool _wasClarified = false;
  List<Product> _candidates = const [];

  bool get hasPending => _command != null && _clarification != null;

  VoiceStockIncrementConversationTurn start({
    required VoiceCommand command,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    required DateTime now,
  }) {
    clear();
    _command = command;
    _entities = command.entities.merge(
      extractor.extract(command.normalizedText, unitAliases: unitAliases),
    );
    _expiresAt = now.add(expiration);
    return _advance(
      products: products,
      aliases: aliases,
      unitAliases: unitAliases,
    );
  }

  VoiceStockIncrementConversationTurn answer({
    required String transcript,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    required DateTime now,
    bool looksLikeNewCommand = false,
  }) {
    if (_command == null || _clarification == null) {
      clear();
      return const VoiceStockIncrementConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Tidak ada penambahan stok yang sedang menunggu jawaban.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    if (_expiresAt == null || !now.isBefore(_expiresAt!)) {
      clear();
      return const VoiceStockIncrementConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Penambahan stok sudah kedaluwarsa. Ulangi perintah dari awal.',
          kind: VoiceResponseKind.error,
        ),
      );
    }

    final normalized = _normalize(transcript);
    if (_isCancel(normalized)) {
      clear();
      return const VoiceStockIncrementConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Penambahan stok dibatalkan. Tidak ada data yang berubah.',
        ),
      );
    }
    if (RegExp(r'\b(ulangi|ulang|sebutkan lagi)\b').hasMatch(normalized)) {
      return _ask(_clarification!, _questionFor(_clarification!));
    }
    if (RegExp(r'\bubah\s+(?:jumlah|kuantitas)\b').hasMatch(normalized)) {
      return _ask(
        VoiceStockIncrementClarification.quantity,
        'Berapa jumlah stok yang ingin ditambahkan?',
      );
    }
    if (RegExp(r'\bubah\s+satuan\b').hasMatch(normalized)) {
      return _ask(
        VoiceStockIncrementClarification.unit,
        _unitQuestion(products),
      );
    }
    if (looksLikeNewCommand) {
      clear();
      return const VoiceStockIncrementConversationTurn(routeAsNewCommand: true);
    }

    final current = _entities!;
    switch (_clarification!) {
      case VoiceStockIncrementClarification.productName:
        final name = normalized
            .replaceFirst(RegExp(r'^(?:produk|barang|namanya)\s+'), '')
            .trim();
        if (name.isEmpty || !RegExp(r'[a-z0-9]').hasMatch(name)) {
          return _invalid(
            'Nama produk belum terbaca. Sebutkan produk yang ingin direstok.',
          );
        }
        _entities = _copyEntities(
          current,
          productName: name,
          clearProductId: true,
        );
      case VoiceStockIncrementClarification.productSelection:
        final selected = _selectCandidate(normalized);
        if (selected == null) {
          return _invalid(
            'Pilihan produk belum jelas. Sebutkan nama produk atau nomor pilihannya.',
          );
        }
        _entities = _copyEntities(
          current,
          productId: selected.id,
          productName: selected.name,
        );
      case VoiceStockIncrementClarification.quantity:
        final quantity = extractor.parseQuantity(normalized);
        if (quantity == null || !quantity.isFinite || quantity <= 0) {
          return _invalid(
            'Jumlah belum terbaca. Sebutkan angka lebih besar dari nol.',
          );
        }
        _entities = _copyEntities(current, quantity: quantity);
      case VoiceStockIncrementClarification.unit:
        final unit = extractor.parseUnit(normalized, unitAliases: unitAliases);
        if (unit == null) {
          return _invalid(
            'Satuan belum dikenal. Sebutkan satuan seperti gelas, gram, liter, pack, atau karton.',
          );
        }
        _entities = _copyEntities(current, unit: unit.name);
      case VoiceStockIncrementClarification.trackingActivation:
        final decision = _yesNo(normalized);
        if (decision == null) {
          return _invalid(
            'Jawab ya untuk mengaktifkan pelacakan stok, atau tidak untuk membatalkan.',
          );
        }
        if (!decision) {
          clear();
          return const VoiceStockIncrementConversationTurn(
            response: VoiceCommandResponse(
              displayText:
                  'Pelacakan stok tidak diaktifkan. Tidak ada data yang berubah.',
            ),
          );
        }
        _entities = _copyEntities(current, trackingEnableConfirmed: true);
    }
    _invalidAttempts = 0;
    return _advance(
      products: products,
      aliases: aliases,
      unitAliases: unitAliases,
    );
  }

  void clear() {
    _command = null;
    _entities = null;
    _clarification = null;
    _expiresAt = null;
    _invalidAttempts = 0;
    _wasClarified = false;
    _candidates = const [];
  }

  VoiceStockIncrementConversationTurn _advance({
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
    required List<VoiceUnitAlias> unitAliases,
  }) {
    var entities = _entities!;
    final spokenName = entities.productName?.trim() ?? '';
    if (spokenName.isEmpty) {
      return _ask(
        VoiceStockIncrementClarification.productName,
        'Produk mana yang ingin ditambah stoknya?',
      );
    }

    Product? product = _productById(products, entities.productId);
    if (product == null) {
      final match = productResolver.resolve(
        spokenName: spokenName,
        products: products,
        aliases: aliases,
        spokenUnit: entities.unit,
      );
      if (match.type == VoiceProductMatchType.ambiguous) {
        _candidates = match.candidates
            .map((candidate) => candidate.product)
            .take(5)
            .toList(growable: false);
        return _ask(
          VoiceStockIncrementClarification.productSelection,
          'Saya menemukan ${_candidateNames()}. Produk mana yang dimaksud?',
        );
      }
      if (!match.isMatched || match.product == null) {
        clear();
        return VoiceStockIncrementConversationTurn(
          response: VoiceCommandResponse(
            displayText:
                'Produk $spokenName belum ditemukan. Tambahkan produknya terlebih dahulu.',
            kind: VoiceResponseKind.error,
            title: 'Produk tidak ditemukan',
            suggestedAction: 'Buka daftar produk',
          ),
        );
      }
      product = match.product!;
      entities = _copyEntities(
        entities,
        productId: product.id,
        productName: product.name,
      );
      _entities = entities;
    }

    final quantity = entities.quantity;
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      return _ask(
        VoiceStockIncrementClarification.quantity,
        'Berapa jumlah stok yang ingin ditambahkan?',
      );
    }

    final normalizedUnit = unitNormalizer.normalize(
      entities.unit,
      learnedAliases: unitAliases,
    );
    if (!normalizedUnit.isRecognized) {
      return _ask(
        VoiceStockIncrementClarification.unit,
        'Dalam satuan apa stok ditambahkan? Satuan dasar ${product.name} adalah ${product.baseUnit.label}.',
      );
    }
    _entities = _copyEntities(entities, unit: normalizedUnit.unit!.name);

    if (!product.trackStock && entities.trackingEnableConfirmed != true) {
      final requestedLabel =
          '${QuantityFormatter.label(quantity)} ${normalizedUnit.unit!.label}';
      final adoptsUnit =
          product.stockPcs == 0 &&
          product.baseUnit == SaleUnit.pcs &&
          !normalizedUnit.unit!.isPackaging;
      final unitNote = adoptsUnit
          ? ' Satuan dasar akan digunakan ${normalizedUnit.unit!.label}.'
          : '';
      return _ask(
        VoiceStockIncrementClarification.trackingActivation,
        'Stok ${product.name} saat ini tidak dilacak. Aktifkan pelacakan stok dan tambahkan $requestedLabel?$unitNote',
      );
    }

    final ready = _resolvedCommand();
    clear();
    return VoiceStockIncrementConversationTurn(readyCommand: ready);
  }

  VoiceCommand _resolvedCommand() {
    final command = _command!;
    return VoiceCommand(
      rawText: command.rawText,
      normalizedText: command.normalizedText,
      intent: command.intent,
      entities: command.entities.merge(
        _copyEntities(_entities!, clarificationOccurred: _wasClarified),
      ),
      confidence: command.confidence,
      hasMultipleIntents: command.hasMultipleIntents,
    );
  }

  VoiceStockIncrementConversationTurn _ask(
    VoiceStockIncrementClarification clarification,
    String message,
  ) {
    _clarification = clarification;
    _wasClarified = true;
    return VoiceStockIncrementConversationTurn(
      response: VoiceCommandResponse(
        displayText: message,
        kind: VoiceResponseKind.question,
        title: 'Lengkapi penambahan stok',
      ),
    );
  }

  VoiceStockIncrementConversationTurn _invalid(String message) {
    _invalidAttempts += 1;
    if (_invalidAttempts >= maximumInvalidAttempts) {
      clear();
      return const VoiceStockIncrementConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Data penambahan stok belum dapat dipastikan. Aksi dibatalkan agar stok tetap aman.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    return VoiceStockIncrementConversationTurn(
      response: VoiceCommandResponse(
        displayText: message,
        kind: VoiceResponseKind.question,
      ),
    );
  }

  VoiceCommandEntities _copyEntities(
    VoiceCommandEntities current, {
    String? productId,
    String? productName,
    double? quantity,
    String? unit,
    bool? trackingEnableConfirmed,
    bool? clarificationOccurred,
    bool clearProductId = false,
  }) {
    return VoiceCommandEntities(
      productId: clearProductId ? null : productId ?? current.productId,
      productName: productName ?? current.productName,
      quantity: quantity ?? current.quantity,
      unit: unit ?? current.unit,
      salePrice: current.salePrice,
      costPrice: current.costPrice,
      wholesalePrice: current.wholesalePrice,
      stock: current.stock,
      trackStock: current.trackStock,
      minStock: current.minStock,
      packSize: current.packSize,
      cartonSize: current.cartonSize,
      similarProductConfirmed: current.similarProductConfirmed,
      similarProductName: current.similarProductName,
      trackingEnableConfirmed:
          trackingEnableConfirmed ?? current.trackingEnableConfirmed,
      clarificationOccurred:
          clarificationOccurred ?? current.clarificationOccurred,
      categoryName: current.categoryName,
      walletName: current.walletName,
      period: current.period,
      transactionFilter: current.transactionFilter,
      resultLimit: current.resultLimit,
      topProductRanking: current.topProductRanking,
      allWallets: current.allWallets,
      largestWallet: current.largestWallet,
      largestExpense: current.largestExpense,
      navigationTarget: current.navigationTarget,
    );
  }

  Product? _productById(List<Product> products, String? productId) {
    if (productId == null) return null;
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Product? _selectCandidate(String answer) {
    final ordinal = switch (answer) {
      'pertama' || 'satu' || 'nomor satu' => 0,
      'kedua' || 'dua' || 'nomor dua' => 1,
      'ketiga' || 'tiga' || 'nomor tiga' => 2,
      'keempat' || 'empat' || 'nomor empat' => 3,
      'kelima' || 'lima' || 'nomor lima' => 4,
      _ => null,
    };
    if (ordinal != null && ordinal < _candidates.length) {
      return _candidates[ordinal];
    }
    final normalizedAnswer = nameNormalizer
        .normalize(answer)
        .replaceFirst(RegExp(r'^(?:yang|produk|barang)\s+'), '');
    final matches = _candidates
        .where((candidate) {
          final normalizedName = nameNormalizer.normalize(candidate.name);
          return normalizedName == normalizedAnswer ||
              normalizedName.contains(normalizedAnswer) ||
              normalizedAnswer.contains(normalizedName);
        })
        .toList(growable: false);
    return matches.length == 1 ? matches.single : null;
  }

  String _candidateNames() {
    return _candidates.map((product) => product.name).join(' dan ');
  }

  String _questionFor(VoiceStockIncrementClarification clarification) {
    final product = _entities?.productName ?? 'produk ini';
    return switch (clarification) {
      VoiceStockIncrementClarification.productName =>
        'Produk mana yang ingin ditambah stoknya?',
      VoiceStockIncrementClarification.productSelection =>
        'Saya menemukan ${_candidateNames()}. Produk mana yang dimaksud?',
      VoiceStockIncrementClarification.quantity =>
        'Berapa jumlah stok yang ingin ditambahkan?',
      VoiceStockIncrementClarification.unit =>
        'Dalam satuan apa stok $product ditambahkan?',
      VoiceStockIncrementClarification.trackingActivation =>
        'Stok $product belum dilacak. Aktifkan pelacakan stok?',
    };
  }

  String _unitQuestion(List<Product> products) {
    final product = _productById(products, _entities?.productId);
    if (product == null) return 'Dalam satuan apa stok ditambahkan?';
    return 'Dalam satuan apa stok ditambahkan? Satuan dasar ${product.name} adalah ${product.baseUnit.label}.';
  }

  bool? _yesNo(String value) {
    if (RegExp(r'\b(tidak|enggak|nggak|ga|gak|jangan)\b').hasMatch(value)) {
      return false;
    }
    if (RegExp(r'\b(ya|iya|boleh|aktifkan|lanjut)\b').hasMatch(value)) {
      return true;
    }
    return null;
  }

  bool _isCancel(String value) {
    return RegExp(r'\b(batal|batalkan|stop)\b').hasMatch(value);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
