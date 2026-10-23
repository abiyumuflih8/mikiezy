import '../../models/mikiezy_models.dart';
import 'money_parser.dart';
import 'voice_command.dart';
import 'voice_create_product_entity_extractor.dart';
import 'voice_product_resolver.dart';

enum VoiceCreateProductClarification {
  productName,
  retailPrice,
  trackStock,
  stockAndUnit,
  similarProduct,
}

class VoiceCreateProductConversationTurn {
  const VoiceCreateProductConversationTurn({
    this.response,
    this.readyCommand,
    this.rejectedCommand,
    this.routeAsNewCommand = false,
  });

  final VoiceCommandResponse? response;
  final VoiceCommand? readyCommand;
  final VoiceCommand? rejectedCommand;
  final bool routeAsNewCommand;
}

class VoiceCreateProductConversation {
  VoiceCreateProductConversation({
    this.moneyParser = const MoneyParser(),
    this.entityExtractor = const VoiceCreateProductEntityExtractor(),
    this.productResolver = const VoiceProductResolver(),
    this.expiration = const Duration(minutes: 2),
    this.maximumInvalidAttempts = 3,
  });

  final MoneyParser moneyParser;
  final VoiceCreateProductEntityExtractor entityExtractor;
  final VoiceProductResolver productResolver;
  final Duration expiration;
  final int maximumInvalidAttempts;

  VoiceCommand? _command;
  VoiceCommandEntities? _entities;
  VoiceCreateProductClarification? _clarification;
  DateTime? _expiresAt;
  int _invalidAttempts = 0;
  String? _similarProductName;

  bool get hasPending => _command != null && _clarification != null;

  VoiceCreateProductConversationTurn start({
    required VoiceCommand command,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    required DateTime now,
  }) {
    clear();
    _command = command;
    _entities = command.entities.merge(
      entityExtractor.extract(command.normalizedText, unitAliases: unitAliases),
    );
    _expiresAt = now.add(expiration);
    return _advance(products: products, aliases: aliases);
  }

  VoiceCreateProductConversationTurn answer({
    required String transcript,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    required DateTime now,
    bool looksLikeNewCommand = false,
  }) {
    if (_command == null || _clarification == null) {
      clear();
      return const VoiceCreateProductConversationTurn(
        response: VoiceCommandResponse(
          displayText: 'Tidak ada data produk yang sedang menunggu jawaban.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    if (_expiresAt == null || !now.isBefore(_expiresAt!)) {
      clear();
      return const VoiceCreateProductConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Pembuatan produk sudah kedaluwarsa. Ulangi perintah dari awal.',
          kind: VoiceResponseKind.error,
        ),
      );
    }

    final normalized = _normalize(transcript);
    if (_isCancel(normalized)) {
      clear();
      return const VoiceCreateProductConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Pembuatan produk dibatalkan. Tidak ada data yang diubah.',
        ),
      );
    }
    if (RegExp(r'\b(ulangi|ulang|sebutkan lagi)\b').hasMatch(normalized)) {
      return _ask(_clarification!, _questionFor(_clarification!, _entities!));
    }
    if (RegExp(r'\bubah\s+nama\b').hasMatch(normalized)) {
      return _ask(
        VoiceCreateProductClarification.productName,
        'Sebutkan nama produk yang baru.',
      );
    }
    if (RegExp(r'\bubah\s+harga\b').hasMatch(normalized)) {
      return _ask(
        VoiceCreateProductClarification.retailPrice,
        'Sebutkan harga jual yang baru.',
      );
    }
    if (looksLikeNewCommand) {
      clear();
      return const VoiceCreateProductConversationTurn(routeAsNewCommand: true);
    }

    final current = _entities!;
    switch (_clarification!) {
      case VoiceCreateProductClarification.productName:
        final name = normalized
            .replaceFirst(RegExp(r'^(?:namanya|nama produk|produk)\s+'), '')
            .trim();
        if (name.isEmpty || !RegExp(r'[a-z0-9]').hasMatch(name)) {
          return _invalid(
            'Nama produk belum terbaca. Sebutkan nama produknya.',
          );
        }
        _entities = _copyCreateEntities(
          current,
          productName: name,
          resetSimilarity: true,
        );
      case VoiceCreateProductClarification.retailPrice:
        final prices = moneyParser.parseAll(normalized);
        if (prices.isEmpty || prices.first.amount <= 0) {
          return _invalid(
            'Harga jual belum terbaca. Sebutkan nominal, misalnya dua belas ribu.',
          );
        }
        _entities = _copyCreateEntities(
          current,
          salePrice: prices.first.amount,
        );
      case VoiceCreateProductClarification.trackStock:
        final decision = _yesNo(normalized);
        if (decision == null) {
          return _invalid(
            'Apakah stok produk perlu dilacak? Jawab ya atau tidak.',
          );
        }
        _entities = current.merge(VoiceCommandEntities(trackStock: decision));
      case VoiceCreateProductClarification.stockAndUnit:
        final parsed = entityExtractor.extract(
          'stok $normalized',
          unitAliases: unitAliases,
        );
        if (parsed.stock == null || parsed.stock! < 0 || parsed.unit == null) {
          return _invalid(
            'Sebutkan stok awal beserta satuannya, misalnya sepuluh botol.',
          );
        }
        _entities = current.merge(
          VoiceCommandEntities(
            stock: parsed.stock,
            unit: parsed.unit,
            trackStock: true,
          ),
        );
      case VoiceCreateProductClarification.similarProduct:
        final decision = _yesNo(normalized);
        if (decision == null) {
          return _invalid(
            'Jawab ya untuk tetap membuat produk baru, atau tidak untuk membatalkan.',
          );
        }
        if (!decision) {
          clear();
          return const VoiceCreateProductConversationTurn(
            response: VoiceCommandResponse(
              displayText:
                  'Pembuatan produk dibatalkan agar tidak membuat produk ganda.',
            ),
          );
        }
        _entities = current.merge(
          VoiceCommandEntities(
            similarProductConfirmed: true,
            similarProductName: _similarProductName,
          ),
        );
    }
    _invalidAttempts = 0;
    return _advance(products: products, aliases: aliases);
  }

  void clear() {
    _command = null;
    _entities = null;
    _clarification = null;
    _expiresAt = null;
    _invalidAttempts = 0;
    _similarProductName = null;
  }

  VoiceCreateProductConversationTurn _advance({
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
  }) {
    final entities = _entities!;
    if ((entities.productName ?? '').trim().isEmpty) {
      return _ask(
        VoiceCreateProductClarification.productName,
        'Apa nama produk yang ingin ditambahkan?',
      );
    }
    if (entities.salePrice == null || entities.salePrice! <= 0) {
      return _ask(
        VoiceCreateProductClarification.retailPrice,
        'Berapa harga jual ${entities.productName}?',
      );
    }
    if (entities.trackStock == null) {
      return _ask(
        VoiceCreateProductClarification.trackStock,
        'Apakah stok ${entities.productName} perlu dilacak? Jawab ya atau tidak.',
      );
    }
    if (entities.trackStock == true &&
        (entities.stock == null || entities.unit == null)) {
      return _ask(
        VoiceCreateProductClarification.stockAndUnit,
        'Berapa stok awal ${entities.productName} beserta satuannya?',
      );
    }

    final match = productResolver.resolve(
      spokenName: entities.productName!,
      products: products,
      aliases: aliases,
    );
    if (match.type == VoiceProductMatchType.exact) {
      final existingName = match.product?.name ?? entities.productName!;
      final rejectedCommand = _resolvedCommand();
      clear();
      return VoiceCreateProductConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Produk $existingName sudah tersedia. Buka produk tersebut atau batalkan. Perintah tambah stok disiapkan untuk fase berikutnya dan belum aktif.',
          kind: VoiceResponseKind.error,
          title: 'Produk sudah ada',
        ),
        rejectedCommand: rejectedCommand,
      );
    }

    if (entities.similarProductConfirmed != true) {
      final similar = _similarCandidate(match);
      if (similar != null) {
        _similarProductName = similar.name;
        return _ask(
          VoiceCreateProductClarification.similarProduct,
          'Nama ${entities.productName} mirip dengan produk ${similar.name}. Tetap buat sebagai produk baru?',
        );
      }
    }

    final ready = _resolvedCommand();
    clear();
    return VoiceCreateProductConversationTurn(readyCommand: ready);
  }

  VoiceCommand _resolvedCommand() {
    final command = _command!;
    return VoiceCommand(
      rawText: command.rawText,
      normalizedText: command.normalizedText,
      intent: command.intent,
      entities: command.entities.merge(_entities!),
      confidence: command.confidence,
      hasMultipleIntents: command.hasMultipleIntents,
    );
  }

  Product? _similarCandidate(VoiceProductMatchResult match) {
    if (match.type == VoiceProductMatchType.alias ||
        match.type == VoiceProductMatchType.fuzzy) {
      return match.product;
    }
    if (match.type == VoiceProductMatchType.ambiguous &&
        match.candidates.isNotEmpty) {
      return match.candidates.first.product;
    }
    if (match.type == VoiceProductMatchType.notFound &&
        match.candidates.isNotEmpty &&
        match.candidates.first.confidence >= 0.72) {
      return match.candidates.first.product;
    }
    return null;
  }

  VoiceCreateProductConversationTurn _ask(
    VoiceCreateProductClarification clarification,
    String message,
  ) {
    _clarification = clarification;
    return VoiceCreateProductConversationTurn(
      response: VoiceCommandResponse(
        displayText: message,
        kind: VoiceResponseKind.question,
        title: 'Lengkapi produk',
      ),
    );
  }

  String _questionFor(
    VoiceCreateProductClarification clarification,
    VoiceCommandEntities entities,
  ) {
    final name = entities.productName ?? 'produk ini';
    return switch (clarification) {
      VoiceCreateProductClarification.productName =>
        'Apa nama produk yang ingin ditambahkan?',
      VoiceCreateProductClarification.retailPrice => 'Berapa harga jual $name?',
      VoiceCreateProductClarification.trackStock =>
        'Apakah stok $name perlu dilacak? Jawab ya atau tidak.',
      VoiceCreateProductClarification.stockAndUnit =>
        'Berapa stok awal $name beserta satuannya?',
      VoiceCreateProductClarification.similarProduct =>
        'Nama $name mirip dengan produk $_similarProductName. Tetap buat sebagai produk baru?',
    };
  }

  VoiceCommandEntities _copyCreateEntities(
    VoiceCommandEntities current, {
    String? productName,
    int? salePrice,
    bool resetSimilarity = false,
  }) {
    return VoiceCommandEntities(
      productName: productName ?? current.productName,
      quantity: current.quantity,
      unit: current.unit,
      salePrice: salePrice ?? current.salePrice,
      costPrice: current.costPrice,
      wholesalePrice: current.wholesalePrice,
      stock: current.stock,
      trackStock: current.trackStock,
      minStock: current.minStock,
      packSize: current.packSize,
      cartonSize: current.cartonSize,
      categoryName: current.categoryName,
      similarProductConfirmed: resetSimilarity
          ? null
          : current.similarProductConfirmed,
      similarProductName: resetSimilarity ? null : current.similarProductName,
    );
  }

  VoiceCreateProductConversationTurn _invalid(String message) {
    _invalidAttempts += 1;
    if (_invalidAttempts >= maximumInvalidAttempts) {
      clear();
      return const VoiceCreateProductConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Data produk belum dapat dipastikan. Pembuatan dibatalkan agar data katalog tetap aman.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    return VoiceCreateProductConversationTurn(
      response: VoiceCommandResponse(
        displayText: message,
        kind: VoiceResponseKind.question,
      ),
    );
  }

  bool? _yesNo(String value) {
    if (RegExp(r'\b(tidak|enggak|nggak|ga|gak|jangan)\b').hasMatch(value)) {
      return false;
    }
    if (RegExp(r'\b(ya|iya|boleh|perlu|aktifkan|lanjut)\b').hasMatch(value)) {
      return true;
    }
    return null;
  }

  bool _isCancel(String value) {
    return RegExp(r'\b(batal|batalkan|sudah|stop)\b').hasMatch(value);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
