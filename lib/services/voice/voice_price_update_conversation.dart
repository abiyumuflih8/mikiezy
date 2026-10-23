import '../../domain/models/product_price.dart';
import '../../models/mikiezy_models.dart';
import 'voice_command.dart';
import 'voice_price_update_entity_extractor.dart';
import 'voice_product_name_normalizer.dart';
import 'voice_product_resolver.dart';

enum VoicePriceUpdateClarification {
  productName,
  productSelection,
  priceType,
  newPrice,
}

class VoicePriceUpdateConversationTurn {
  const VoicePriceUpdateConversationTurn({
    this.response,
    this.readyCommand,
    this.routeAsNewCommand = false,
  });

  final VoiceCommandResponse? response;
  final VoiceCommand? readyCommand;
  final bool routeAsNewCommand;
}

class VoicePriceUpdateConversation {
  VoicePriceUpdateConversation({
    this.extractor = const VoicePriceUpdateEntityExtractor(),
    this.productResolver = const VoiceProductResolver(),
    this.nameNormalizer = const VoiceProductNameNormalizer(),
    this.expiration = const Duration(minutes: 2),
    this.maximumInvalidAttempts = 3,
  });

  final VoicePriceUpdateEntityExtractor extractor;
  final VoiceProductResolver productResolver;
  final VoiceProductNameNormalizer nameNormalizer;
  final Duration expiration;
  final int maximumInvalidAttempts;

  VoiceCommand? _command;
  VoiceCommandEntities? _entities;
  VoicePriceUpdateClarification? _clarification;
  DateTime? _expiresAt;
  int _invalidAttempts = 0;
  bool _wasClarified = false;
  List<Product> _candidates = const [];

  bool get hasPending => _command != null && _clarification != null;

  VoicePriceUpdateConversationTurn start({
    required VoiceCommand command,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    required DateTime now,
  }) {
    clear();
    _command = command;
    _entities = command.entities.merge(
      extractor.extract(command.normalizedText),
    );
    _expiresAt = now.add(expiration);
    return _advance(products: products, aliases: aliases);
  }

  VoicePriceUpdateConversationTurn answer({
    required String transcript,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    required DateTime now,
    bool looksLikeNewCommand = false,
  }) {
    if (_command == null || _clarification == null) {
      clear();
      return const VoicePriceUpdateConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Tidak ada perubahan harga yang sedang menunggu jawaban.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    if (_expiresAt == null || !now.isBefore(_expiresAt!)) {
      clear();
      return const VoicePriceUpdateConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Perubahan harga sudah kedaluwarsa. Ulangi perintah dari awal.',
          kind: VoiceResponseKind.error,
        ),
      );
    }

    final normalized = _normalize(transcript);
    if (_isCancel(normalized)) {
      clear();
      return const VoicePriceUpdateConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Perubahan harga dibatalkan. Tidak ada data yang berubah.',
        ),
      );
    }
    if (RegExp(r'\b(?:ulangi|ulang|sebutkan lagi)\b').hasMatch(normalized)) {
      return _ask(_clarification!, _questionFor(_clarification!));
    }

    final editedProduct = RegExp(
      r'\bubah\s+(?:produk|barang)\b',
    ).hasMatch(normalized);
    if (editedProduct) {
      final value = normalized
          .replaceFirst(RegExp(r'^.*?\bubah\s+(?:produk|barang)\b'), '')
          .trim();
      if (value.isEmpty) {
        return _ask(
          VoicePriceUpdateClarification.productName,
          'Produk mana yang ingin diubah harganya?',
        );
      }
      _entities = _copyEntities(
        _entities!,
        productName: value,
        clearProductId: true,
      );
      return _advance(products: products, aliases: aliases);
    }

    if (RegExp(r'\bubah\s+(?:jenis\s+)?harga\b').hasMatch(normalized)) {
      final type = extractor.extractPriceType(normalized);
      if (type == null) {
        return _ask(
          VoicePriceUpdateClarification.priceType,
          'Harga mana yang ingin diubah: harga jual, harga grosir, atau harga modal?',
        );
      }
      _entities = _copyEntities(_entities!, productPriceType: type);
      return _advance(products: products, aliases: aliases);
    }

    if (RegExp(
      r'\bubah\s+(?:nominal|nilai|harga\s+baru)\b',
    ).hasMatch(normalized)) {
      final price = extractor.extractNewPrice(normalized);
      if (price == null) {
        return _ask(
          VoicePriceUpdateClarification.newPrice,
          'Berapa harga baru produk ini?',
        );
      }
      _entities = _copyEntities(_entities!, newProductPrice: price);
      return _advance(products: products, aliases: aliases);
    }

    if (looksLikeNewCommand) {
      clear();
      return const VoicePriceUpdateConversationTurn(routeAsNewCommand: true);
    }

    final current = _entities!;
    switch (_clarification!) {
      case VoicePriceUpdateClarification.productName:
        final name = normalized
            .replaceFirst(RegExp(r'^(?:produk|barang|namanya)\s+'), '')
            .trim();
        if (name.isEmpty || !RegExp(r'[a-z0-9]').hasMatch(name)) {
          return _invalid(
            'Nama produk belum terbaca. Sebutkan satu produk yang ingin diubah harganya.',
          );
        }
        _entities = _copyEntities(
          current,
          productName: name,
          clearProductId: true,
        );
      case VoicePriceUpdateClarification.productSelection:
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
      case VoicePriceUpdateClarification.priceType:
        final type = extractor.extractPriceType(normalized);
        if (type == null) {
          return _invalid(
            'Jenis harga belum jelas. Sebutkan harga jual, harga grosir, atau harga modal.',
          );
        }
        _entities = _copyEntities(current, productPriceType: type);
      case VoicePriceUpdateClarification.newPrice:
        final price = extractor.parsePrice(normalized);
        if (price == null) {
          return _invalid(
            'Nominal harga belum terbaca. Sebutkan harga baru dalam rupiah.',
          );
        }
        _entities = _copyEntities(current, newProductPrice: price);
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
    _wasClarified = false;
    _candidates = const [];
  }

  VoicePriceUpdateConversationTurn _advance({
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
  }) {
    var entities = _entities!;
    if (entities.bulkPriceUpdateRequested == true) {
      clear();
      return const VoicePriceUpdateConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Perubahan harga banyak produk belum didukung. Sebutkan satu produk dan satu jenis harga.',
          kind: VoiceResponseKind.error,
          title: 'Perubahan massal diblokir',
        ),
      );
    }

    final spokenName = entities.productName?.trim() ?? '';
    if (spokenName.isEmpty) {
      return _ask(
        VoicePriceUpdateClarification.productName,
        'Produk mana yang ingin diubah harganya?',
      );
    }

    Product? product = _productById(products, entities.productId);
    if (product == null) {
      final match = productResolver.resolve(
        spokenName: spokenName,
        products: products,
        aliases: aliases,
      );
      if (match.type == VoiceProductMatchType.ambiguous) {
        _candidates = match.candidates
            .map((candidate) => candidate.product)
            .take(5)
            .toList(growable: false);
        return _ask(
          VoicePriceUpdateClarification.productSelection,
          'Saya menemukan ${_candidateNames()}. Produk mana yang dimaksud?',
        );
      }
      if (!match.isMatched || match.product == null) {
        clear();
        return VoicePriceUpdateConversationTurn(
          response: VoiceCommandResponse(
            displayText:
                'Produk $spokenName belum ditemukan. Tidak ada harga yang diubah.',
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

    if (entities.productPriceType == null) {
      return _ask(
        VoicePriceUpdateClarification.priceType,
        'Harga mana yang ingin diubah: harga jual, harga grosir, atau harga modal?',
      );
    }
    if (entities.newProductPrice == null) {
      return _ask(
        VoicePriceUpdateClarification.newPrice,
        'Berapa ${entities.productPriceType!.label} baru ${product.name}?',
      );
    }

    final ready = _resolvedCommand();
    clear();
    return VoicePriceUpdateConversationTurn(readyCommand: ready);
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

  VoicePriceUpdateConversationTurn _ask(
    VoicePriceUpdateClarification clarification,
    String message,
  ) {
    _clarification = clarification;
    _wasClarified = true;
    return VoicePriceUpdateConversationTurn(
      response: VoiceCommandResponse(
        displayText: message,
        kind: VoiceResponseKind.question,
        title: 'Lengkapi perubahan harga',
      ),
    );
  }

  VoicePriceUpdateConversationTurn _invalid(String message) {
    _invalidAttempts += 1;
    if (_invalidAttempts >= maximumInvalidAttempts) {
      clear();
      return const VoicePriceUpdateConversationTurn(
        response: VoiceCommandResponse(
          displayText:
              'Data perubahan harga belum dapat dipastikan. Aksi dibatalkan agar katalog tetap aman.',
          kind: VoiceResponseKind.error,
        ),
      );
    }
    return VoicePriceUpdateConversationTurn(
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
    ProductPriceType? productPriceType,
    int? newProductPrice,
    bool? clarificationOccurred,
    bool clearProductId = false,
  }) {
    return VoiceCommandEntities(
      productId: clearProductId ? null : productId ?? current.productId,
      productName: productName ?? current.productName,
      quantity: current.quantity,
      unit: current.unit,
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
      trackingEnableConfirmed: current.trackingEnableConfirmed,
      productPriceType: productPriceType ?? current.productPriceType,
      newProductPrice: newProductPrice ?? current.newProductPrice,
      bulkPriceUpdateRequested: current.bulkPriceUpdateRequested,
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

  String _questionFor(VoicePriceUpdateClarification clarification) {
    final name = _entities?.productName ?? 'produk ini';
    return switch (clarification) {
      VoicePriceUpdateClarification.productName =>
        'Produk mana yang ingin diubah harganya?',
      VoicePriceUpdateClarification.productSelection =>
        'Saya menemukan ${_candidateNames()}. Produk mana yang dimaksud?',
      VoicePriceUpdateClarification.priceType =>
        'Harga mana yang ingin diubah: harga jual, harga grosir, atau harga modal?',
      VoicePriceUpdateClarification.newPrice => 'Berapa harga baru $name?',
    };
  }

  bool _isCancel(String value) {
    return RegExp(r'\b(?:batal|batalkan|stop)\b').hasMatch(value);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.,\s-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
