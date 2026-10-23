import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/models/product_price.dart';
import '../../domain/services/product_price_update_validator.dart';
import '../../domain/services/quantity_formatter.dart';
import '../../domain/services/product_validator.dart';
import '../../domain/services/stable_fingerprint_service.dart';
import '../../domain/services/stock_increment_calculator.dart';
import '../../domain/services/unit_normalizer.dart';
import '../../models/mikiezy_models.dart';
import 'money_parser.dart';
import 'voice_command.dart';
import 'voice_product_resolver.dart';

class VoiceActionDraftFactory {
  VoiceActionDraftFactory({
    this.productResolver = const VoiceProductResolver(),
    this.moneyParser = const MoneyParser(),
    this.productValidator = const ProductValidator(),
    this.priceUpdateValidator = const ProductPriceUpdateValidator(),
    this.stockIncrementCalculator = const StockIncrementCalculator(),
    this.unitNormalizer = const UnitNormalizer(),
    this.fingerprintService = const StableFingerprintService(),
    this.expiration = const Duration(minutes: 2),
  });

  final VoiceProductResolver productResolver;
  final MoneyParser moneyParser;
  final ProductValidator productValidator;
  final ProductPriceUpdateValidator priceUpdateValidator;
  final StockIncrementCalculator stockIncrementCalculator;
  final UnitNormalizer unitNormalizer;
  final StableFingerprintService fingerprintService;
  final Duration expiration;
  int _sequence = 0;

  Future<VoiceActionDraft> create({
    required VoiceCommand command,
    required List<Product> products,
    List<VoiceProductAlias> aliases = const [],
    List<VoiceUnitAlias> unitAliases = const [],
    required DateTime now,
  }) async {
    final commandFingerprint = await fingerprintService.create(
      '${command.intent.name}:${command.normalizedText}',
    );
    return switch (command.intent) {
      VoiceCommandIntent.createProduct => _createProduct(
        command: command,
        products: products,
        aliases: aliases,
        now: now,
        commandFingerprint: commandFingerprint,
      ),
      VoiceCommandIntent.incrementProductStock => _incrementProductStock(
        command: command,
        products: products,
        aliases: aliases,
        unitAliases: unitAliases,
        now: now,
        initialCommandFingerprint: commandFingerprint,
      ),
      VoiceCommandIntent.updateProduct => _updateProduct(
        command: command,
        products: products,
        aliases: aliases,
        now: now,
        commandFingerprint: commandFingerprint,
      ),
      _ => _unsupported(
        command: command,
        now: now,
        commandFingerprint: commandFingerprint,
      ),
    };
  }

  Future<String> productFingerprint(Product product) {
    return fingerprintService.create(
      stockMutationProductFingerprintSource(product),
    );
  }

  Future<String> priceProductFingerprint(Product product) {
    return fingerprintService.create(
      priceMutationProductFingerprintSource(product),
    );
  }

  Future<String> catalogFingerprint(List<Product> products) {
    final sorted = [...products]..sort((a, b) => a.id.compareTo(b.id));
    return fingerprintService.create(
      sorted.map(stockMutationProductFingerprintSource).join('|'),
    );
  }

  Future<VoiceActionDraft?> refreshIncrementStockDraft({
    required VoiceActionDraft action,
    required Product latestProduct,
    required DateTime now,
  }) async {
    final payload = action.payload;
    if (payload is! IncrementStockVoiceActionPayload) return null;
    return create(
      command: VoiceCommand(
        rawText: action.sourceTranscript,
        normalizedText: action.sourceTranscript.toLowerCase().trim(),
        intent: VoiceCommandIntent.incrementProductStock,
        entities: VoiceCommandEntities(
          productId: latestProduct.id,
          productName: payload.spokenProductName,
          quantity: payload.requestedQuantity,
          unit: payload.requestedUnit.name,
          trackingEnableConfirmed: payload.enableTracking,
          clarificationOccurred: payload.wasClarified,
        ),
        confidence: 1,
      ),
      products: [latestProduct],
      now: now,
    );
  }

  Future<VoiceActionDraft?> refreshPriceUpdateDraft({
    required VoiceActionDraft action,
    required Product latestProduct,
    required DateTime now,
  }) async {
    final payload = action.payload;
    if (payload is! UpdateProductPriceVoiceActionPayload) return null;
    return create(
      command: VoiceCommand(
        rawText: action.sourceTranscript,
        normalizedText: action.sourceTranscript.toLowerCase().trim(),
        intent: VoiceCommandIntent.updateProduct,
        entities: VoiceCommandEntities(
          productId: latestProduct.id,
          productName: payload.spokenProductName,
          productPriceType: payload.priceType,
          newProductPrice: payload.newPrice,
          clarificationOccurred: payload.wasClarified,
        ),
        confidence: 1,
      ),
      products: [latestProduct],
      now: now,
    );
  }

  Future<VoiceActionDraft> _createProduct({
    required VoiceCommand command,
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
    required DateTime now,
    required String commandFingerprint,
  }) async {
    final name = _titleCase(command.entities.productName?.trim() ?? '');
    final price = _moneyAmount(command);
    final trackStock = command.entities.trackStock;
    final stock = command.entities.stock;
    final normalizedUnit = unitNormalizer.normalize(command.entities.unit);
    final errors = <String>[];
    if (name.isEmpty) errors.add('Nama produk belum disebutkan.');
    if (price == null || price <= 0) {
      errors.add('Harga jual produk belum disebutkan dengan jelas.');
    }
    if (trackStock == null) {
      errors.add('Pilihan pelacakan stok belum ditentukan.');
    } else if (trackStock && stock == null) {
      errors.add('Stok awal belum disebutkan.');
    }
    if (trackStock == true && !normalizedUnit.isRecognized) {
      errors.add('Satuan dasar stok belum disebutkan atau belum dikenal.');
    }

    final product = Product(
      id: 'prd-voice-${commandFingerprint.substring(0, 16)}',
      name: name,
      category: _titleCase(command.entities.categoryName ?? 'Lain-lain'),
      costPrice: command.entities.costPrice ?? 0,
      retailPrice: price ?? 0,
      wholesalePrice: command.entities.wholesalePrice ?? price ?? 0,
      packSize: command.entities.packSize ?? 1,
      cartonSize: command.entities.cartonSize ?? 1,
      stockPcs: trackStock == true ? stock ?? 0 : 0,
      trackStock: trackStock ?? false,
      baseUnit: trackStock == true
          ? normalizedUnit.unit ?? SaleUnit.pcs
          : SaleUnit.pcs,
      minStock: trackStock == true ? command.entities.minStock ?? 0 : 0,
    );
    final similarProductName =
        command.entities.similarProductName ??
        _similarProductName(name: name, products: products, aliases: aliases);
    if (similarProductName != null &&
        command.entities.similarProductConfirmed != true) {
      errors.add(
        'Nama produk mirip dengan $similarProductName dan perlu dikonfirmasi.',
      );
    }
    errors.addAll(
      productValidator
          .validate(product, existingProducts: products)
          .issues
          .map((issue) => issue.message)
          .where((message) => !errors.contains(message)),
    );

    final fields = <String, String>{
      'nama': name.isEmpty ? 'Belum diisi' : name,
      'hargaJual': price == null ? 'Belum diisi' : _rupiah(price),
      if (command.entities.costPrice != null)
        'hargaModal': _rupiah(product.costPrice),
      if (command.entities.wholesalePrice != null)
        'hargaGrosir': _rupiah(product.wholesalePrice),
      'kategori': product.category,
      'lacakStok': product.trackStock ? 'Ya' : 'Tidak',
      'stok': product.trackStock
          ? '${QuantityFormatter.label(product.stockPcs)} ${product.baseUnit.label}'
          : 'Tidak dilacak',
      if (product.trackStock) 'satuanDasar': product.baseUnit.label,
      'stokMinimum': product.trackStock
          ? '${QuantityFormatter.label(product.minStock)} ${product.baseUnit.label}'
          : '-',
      'isiPack': product.packSize.toString(),
      'isiKarton': product.cartonSize.toString(),
      'produkMirip': ?similarProductName,
    };
    final proposedFingerprint = await fingerprintService.create(
      fields.entries.map((entry) => '${entry.key}=${entry.value}').join('|'),
    );
    final baseFingerprint = await catalogFingerprint(products);
    return VoiceActionDraft(
      actionId: _actionId(now, commandFingerprint),
      type: VoiceActionType.createProduct,
      payload: CreateProductVoiceActionPayload(
        product: product,
        similarProductName: similarProductName,
        similarProductConfirmed:
            command.entities.similarProductConfirmed ?? false,
      ),
      proposed: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: proposedFingerprint,
        fields: fields,
      ),
      changes: [
        VoiceActionFieldChange(
          field: 'name',
          label: 'Nama produk',
          after: name.isEmpty ? 'Belum diisi' : name,
        ),
        VoiceActionFieldChange(
          field: 'retailPrice',
          label: 'Harga jual',
          after: price == null ? 'Belum diisi' : _rupiah(price),
        ),
        VoiceActionFieldChange(
          field: 'trackStock',
          label: 'Pelacakan stok',
          after: product.trackStock ? 'Aktif' : 'Tidak aktif',
        ),
        if (product.trackStock)
          VoiceActionFieldChange(
            field: 'stock',
            label: 'Stok awal',
            after:
                '${QuantityFormatter.label(product.stockPcs)} ${product.baseUnit.label}',
          ),
      ],
      summary: _createProductSummary(
        product: product,
        hasValidPrice: price != null && price > 0,
      ),
      risk: VoiceActionRisk.medium,
      requiresAuthentication: false,
      isReversible: false,
      createdAt: now,
      expiresAt: now.add(expiration),
      sourceTranscript: command.rawText,
      commandFingerprint: commandFingerprint,
      baseFingerprint: baseFingerprint,
      validationErrors: errors,
    );
  }

  Future<VoiceActionDraft> _updateProduct({
    required VoiceCommand command,
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
    required DateTime now,
    required String commandFingerprint,
  }) async {
    final spokenName = command.entities.productName?.trim() ?? '';
    final match = productResolver.resolve(
      spokenName: spokenName,
      products: products,
      aliases: aliases,
      matchedProductId: command.entities.productId,
    );
    final product = match.product;
    final errors = <String>[];
    if (spokenName.isEmpty) {
      errors.add('Nama produk belum disebutkan.');
    } else if (command.entities.bulkPriceUpdateRequested == true) {
      errors.add(
        'Perubahan harga banyak produk belum didukung. Sebutkan satu produk dan satu jenis harga.',
      );
    } else if (match.type == VoiceProductMatchType.ambiguous) {
      errors.add('Nama produk masih ambigu.');
    } else if (!match.isMatched || product == null) {
      errors.add('Produk $spokenName belum ditemukan.');
    }

    if (product == null) {
      final fingerprint = await fingerprintService.create(
        'missing:$spokenName',
      );
      return VoiceActionDraft(
        actionId: _actionId(now, commandFingerprint),
        type: VoiceActionType.updateProductPrice,
        proposed: VoiceActionSnapshot(
          entityType: 'product',
          fingerprint: fingerprint,
          fields: {'nama': spokenName},
        ),
        summary: 'Perubahan produk belum dapat disiapkan.',
        risk: VoiceActionRisk.medium,
        requiresAuthentication: false,
        isReversible: true,
        createdAt: now,
        expiresAt: now.add(expiration),
        sourceTranscript: command.rawText,
        commandFingerprint: commandFingerprint,
        baseFingerprint: fingerprint,
        validationErrors: errors,
      );
    }

    final beforeFingerprint = await priceProductFingerprint(product);
    if (RegExp(r'\bstok\b').hasMatch(command.normalizedText)) {
      return _unsupportedStockMutation(
        command: command,
        product: product,
        now: now,
        commandFingerprint: commandFingerprint,
        beforeFingerprint: beforeFingerprint,
      );
    }
    return _priceDraft(
      command: command,
      product: product,
      now: now,
      commandFingerprint: commandFingerprint,
      beforeFingerprint: beforeFingerprint,
      initialErrors: errors,
    );
  }

  Future<VoiceActionDraft> _incrementProductStock({
    required VoiceCommand command,
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
    required List<VoiceUnitAlias> unitAliases,
    required DateTime now,
    required String initialCommandFingerprint,
  }) async {
    final spokenName = command.entities.productName?.trim() ?? '';
    final match = productResolver.resolve(
      spokenName: spokenName,
      products: products,
      aliases: aliases,
      matchedProductId: command.entities.productId,
      spokenUnit: command.entities.unit,
    );
    final product = match.product;
    final errors = <String>[];
    if (spokenName.isEmpty) {
      errors.add('Nama produk belum disebutkan.');
    } else if (match.type == VoiceProductMatchType.ambiguous) {
      errors.add('Nama produk masih ambigu.');
    } else if (!match.isMatched || product == null) {
      errors.add('Produk $spokenName belum ditemukan.');
    }

    if (product == null) {
      final missingFingerprint = await fingerprintService.create(
        'missing-stock-product:$spokenName',
      );
      return VoiceActionDraft(
        actionId: _actionId(now, initialCommandFingerprint),
        type: VoiceActionType.incrementProductStock,
        proposed: VoiceActionSnapshot(
          entityType: 'product',
          fingerprint: missingFingerprint,
          fields: {'nama': spokenName},
        ),
        summary: 'Penambahan stok belum dapat disiapkan.',
        risk: VoiceActionRisk.medium,
        requiresAuthentication: false,
        isReversible: false,
        createdAt: now,
        expiresAt: now.add(expiration),
        sourceTranscript: command.rawText,
        commandFingerprint: initialCommandFingerprint,
        baseFingerprint: missingFingerprint,
        validationErrors: errors,
      );
    }

    final requestedQuantity = command.entities.quantity;
    if (requestedQuantity == null ||
        !requestedQuantity.isFinite ||
        requestedQuantity <= 0) {
      errors.add('Jumlah stok harus lebih besar dari nol.');
    }
    final normalizedUnit = unitNormalizer.normalize(
      command.entities.unit,
      learnedAliases: unitAliases,
    );
    if (!normalizedUnit.isRecognized) {
      errors.add('Satuan stok belum dikenal.');
    }

    final baseFingerprint = await productFingerprint(product);
    StockIncrementCalculation? calculation;
    if (requestedQuantity != null && normalizedUnit.isRecognized) {
      calculation = stockIncrementCalculator.calculate(
        product: product,
        requestedQuantity: requestedQuantity,
        requestedUnit: normalizedUnit.unit!,
        trackingEnableConfirmed:
            command.entities.trackingEnableConfirmed == true,
      );
      if (!calculation.isSuccess) {
        errors.add(calculation.message ?? 'Penambahan stok belum valid.');
      }
    }

    final requestedUnit = normalizedUnit.unit ?? product.baseUnit;
    final normalizedIncrement = calculation?.normalizedQuantity ?? 0;
    final targetBaseUnit = calculation?.baseUnit ?? product.baseUnit;
    final stockBefore = calculation?.stockBefore ?? product.stockPcs;
    final stockAfter = calculation?.stockAfter ?? product.stockPcs;
    final multiplier = calculation?.multiplier ?? 0;
    final enableTracking = calculation?.enableTracking ?? false;
    final stockCommandFingerprint = await fingerprintService.create(
      [
        initialCommandFingerprint,
        product.id,
        baseFingerprint,
        QuantityFormatter.label(requestedQuantity ?? 0),
        requestedUnit.name,
      ].join(':'),
    );
    final actionId = _actionId(now, stockCommandFingerprint);
    final payload = IncrementStockVoiceActionPayload(
      actionId: actionId,
      commandFingerprint: stockCommandFingerprint,
      productId: product.id,
      spokenProductName: spokenName,
      productName: product.name,
      requestedQuantity: QuantityFormatter.normalize(requestedQuantity ?? 0),
      requestedUnit: requestedUnit,
      normalizedQuantity: normalizedIncrement,
      baseUnitBefore: product.baseUnit,
      baseUnit: targetBaseUnit,
      stockBefore: stockBefore,
      stockAfter: stockAfter,
      trackStockBefore: product.trackStock,
      enableTracking: enableTracking,
      productFingerprint: baseFingerprint,
      packSize: product.packSize,
      cartonSize: product.cartonSize,
      multiplier: multiplier,
      minStock: product.minStock,
      wasClarified: command.entities.clarificationOccurred == true,
      validationErrors: errors,
    );
    final requestedLabel =
        '${QuantityFormatter.label(payload.requestedQuantity)} ${payload.requestedUnit.label}';
    final normalizedLabel =
        '${QuantityFormatter.label(payload.normalizedQuantity)} ${payload.baseUnit.label}';
    final beforeLabel =
        '${QuantityFormatter.label(payload.stockBefore)} ${payload.baseUnit.label}';
    final afterLabel =
        '${QuantityFormatter.label(payload.stockAfter)} ${payload.baseUnit.label}';
    final fields = <String, String>{
      'nama': product.name,
      'stokSebelum': beforeLabel,
      'jumlahDiminta': requestedLabel,
      'hasilKonversi': normalizedLabel,
      'satuanDasar': payload.baseUnit.label,
      'stokSesudah': afterLabel,
      'lacakStokSebelum': product.trackStock ? 'Ya' : 'Tidak',
      'lacakStokSesudah': product.trackStock || enableTracking ? 'Ya' : 'Tidak',
      if (payload.requestedUnit == SaleUnit.pack)
        'multiplierKemasan':
            '1 pack = ${product.packSize} ${payload.baseUnit.label}',
      if (payload.requestedUnit == SaleUnit.carton)
        'multiplierKemasan':
            '1 karton = ${product.cartonSize} ${payload.baseUnit.label}',
      'stokMinimum':
          '${QuantityFormatter.label(product.minStock)} ${payload.baseUnit.label}',
      'statusStok': _stockStatusLabel(
        product.copyWith(
          stockPcs: payload.stockAfter,
          trackStock: product.trackStock || enableTracking,
          baseUnit: payload.baseUnit,
        ),
      ),
      if (enableTracking) 'peringatan': 'Pelacakan stok akan diaktifkan',
      'autentikasi': 'Sesi aplikasi terbuka',
      'kedaluwarsa': now.add(expiration).toIso8601String(),
    };
    final proposedFingerprint = await fingerprintService.create(
      fields.entries.map((entry) => '${entry.key}=${entry.value}').join('|'),
    );
    final summary = _stockIncrementSummary(payload);
    return VoiceActionDraft(
      actionId: actionId,
      type: VoiceActionType.incrementProductStock,
      before: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: baseFingerprint,
        fields: {
          'nama': product.name,
          'stok': beforeLabel,
          'lacakStok': product.trackStock ? 'Ya' : 'Tidak',
          'satuanDasar': product.baseUnit.label,
        },
      ),
      payload: payload,
      proposed: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: proposedFingerprint,
        fields: fields,
      ),
      changes: [
        VoiceActionFieldChange(
          field: 'stock',
          label: 'Stok',
          before: beforeLabel,
          after: afterLabel,
        ),
        if (enableTracking)
          const VoiceActionFieldChange(
            field: 'trackStock',
            label: 'Pelacakan stok',
            before: 'Tidak',
            after: 'Ya',
          ),
        if (payload.baseUnitBefore != payload.baseUnit)
          VoiceActionFieldChange(
            field: 'baseUnit',
            label: 'Satuan dasar',
            before: payload.baseUnitBefore.label,
            after: payload.baseUnit.label,
          ),
      ],
      summary: summary,
      risk: calculation?.risk == VoiceStockIncrementRisk.high
          ? VoiceActionRisk.high
          : VoiceActionRisk.medium,
      requiresAuthentication: false,
      isReversible: false,
      createdAt: now,
      expiresAt: now.add(expiration),
      sourceTranscript: command.rawText,
      commandFingerprint: stockCommandFingerprint,
      baseFingerprint: baseFingerprint,
      validationErrors: errors,
    );
  }

  Future<VoiceActionDraft> _priceDraft({
    required VoiceCommand command,
    required Product product,
    required DateTime now,
    required String commandFingerprint,
    required String beforeFingerprint,
    required List<String> initialErrors,
  }) async {
    final errors = [...initialErrors];
    final priceType = command.entities.productPriceType;
    final newPrice = command.entities.newProductPrice;
    if (priceType == null) {
      errors.add(
        'Jenis harga belum disebutkan. Pilih harga jual, harga grosir, atau harga modal.',
      );
    }
    if (newPrice == null) {
      errors.add('Harga baru belum disebutkan dengan jelas.');
    }

    ProductPriceValidationResult? validation;
    if (priceType != null && newPrice != null) {
      validation = priceUpdateValidator.validate(
        product: product,
        type: priceType,
        newPrice: newPrice,
      );
      if (!validation.isSuccess) {
        errors.add(validation.message ?? 'Harga baru belum valid.');
      }
    }
    final effectiveType = priceType ?? ProductPriceType.retail;
    final oldPrice = validation?.oldPrice ?? effectiveType.valueOf(product);
    final effectiveNewPrice = validation?.newPrice ?? newPrice ?? 0;
    final difference = validation?.difference ?? effectiveNewPrice - oldPrice;
    final warnings = validation?.warnings ?? const <ProductPriceWarning>[];
    final updatedProduct = effectiveType.applyTo(product, effectiveNewPrice);
    final afterFingerprint = await priceProductFingerprint(updatedProduct);
    final priceCommandFingerprint = await fingerprintService.create(
      [
        commandFingerprint,
        product.id,
        beforeFingerprint,
        effectiveType.name,
        effectiveNewPrice,
      ].join(':'),
    );
    final actionId = _actionId(now, priceCommandFingerprint);
    final expiresAt = now.add(expiration);
    final payload = UpdateProductPriceVoiceActionPayload(
      actionId: actionId,
      commandFingerprint: priceCommandFingerprint,
      productId: product.id,
      spokenProductName: command.entities.productName?.trim() ?? product.name,
      productName: product.name,
      priceType: effectiveType,
      oldPrice: oldPrice,
      newPrice: effectiveNewPrice,
      difference: difference,
      percentageChange: validation?.percentageChange,
      retailPriceBefore: product.retailPrice,
      wholesalePriceBefore: product.wholesalePrice,
      costPriceBefore: product.costPrice,
      productFingerprint: beforeFingerprint,
      expectedProductFingerprintAfter: afterFingerprint,
      risk: validation?.risk ?? ProductPriceUpdateRisk.medium,
      requiresAdditionalConfirmation:
          validation?.requiresAdditionalConfirmation ?? false,
      warnings: warnings,
      expiresAt: expiresAt,
      wasClarified: command.entities.clarificationOccurred == true,
      validationErrors: errors,
    );
    final warningText = warnings
        .map((warning) => warning.message(product.name))
        .join(' ');
    final oldPriceLabel = _displayRupiah(oldPrice);
    final newPriceLabel = newPrice == null
        ? 'Belum diisi'
        : _displayRupiah(effectiveNewPrice);
    final percentageLabel = payload.percentageChange == null
        ? 'Tidak tersedia karena harga sebelumnya nol'
        : _percentageLabel(payload.percentageChange!);
    final before = VoiceActionSnapshot(
      entityType: 'product',
      entityId: product.id,
      fingerprint: beforeFingerprint,
      fields: {
        'nama': product.name,
        'jenisHarga': effectiveType.label,
        'hargaLama': oldPrice.toString(),
        'hargaJual': product.retailPrice.toString(),
        'hargaGrosir': product.wholesalePrice.toString(),
        'hargaModal': product.costPrice.toString(),
      },
    );
    final proposedFields = <String, String>{
      'nama': product.name,
      'jenisHarga': effectiveType.label,
      'hargaLama': oldPrice.toString(),
      'hargaBaru': effectiveNewPrice.toString(),
      if (effectiveType == ProductPriceType.retail)
        'hargaJual': effectiveNewPrice.toString(),
      if (effectiveType == ProductPriceType.wholesale)
        'hargaGrosir': effectiveNewPrice.toString(),
      if (effectiveType == ProductPriceType.cost)
        'hargaModal': effectiveNewPrice.toString(),
      'selisihHarga': difference.toString(),
      'persentaseHarga': percentageLabel,
      if (warningText.isNotEmpty) 'peringatanHarga': warningText,
      'dampakHarga': 'Berlaku untuk transaksi baru setelah perubahan.',
      'riwayatHarga':
          'Transaksi dan laba historis tetap memakai snapshot lama.',
      'autentikasi': 'Sesi aplikasi terbuka',
      'kedaluwarsa': expiresAt.toIso8601String(),
    };
    final proposedFingerprint = await fingerprintService.create(
      '$beforeFingerprint|${effectiveType.fieldName}=$effectiveNewPrice',
    );
    return VoiceActionDraft(
      actionId: actionId,
      type: VoiceActionType.updateProductPrice,
      before: before,
      payload: payload,
      proposed: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: proposedFingerprint,
        fields: proposedFields,
      ),
      changes: [
        VoiceActionFieldChange(
          field: effectiveType.fieldName,
          label: effectiveType.label,
          before: oldPriceLabel,
          after: newPriceLabel,
        ),
      ],
      summary: _priceUpdateSummary(payload),
      risk: payload.risk == ProductPriceUpdateRisk.high
          ? VoiceActionRisk.high
          : VoiceActionRisk.medium,
      requiresAuthentication: false,
      isReversible: true,
      createdAt: now,
      expiresAt: expiresAt,
      sourceTranscript: command.rawText,
      commandFingerprint: priceCommandFingerprint,
      baseFingerprint: beforeFingerprint,
      validationErrors: errors,
    );
  }

  Future<VoiceActionDraft> _unsupportedStockMutation({
    required VoiceCommand command,
    required Product product,
    required DateTime now,
    required String commandFingerprint,
    required String beforeFingerprint,
  }) async {
    final proposedFingerprint = await fingerprintService.create(
      '$beforeFingerprint|unsupported-stock-mutation',
    );
    return VoiceActionDraft(
      actionId: _actionId(now, commandFingerprint),
      type: VoiceActionType.adjustStock,
      before: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: beforeFingerprint,
        fields: {
          'nama': product.name,
          'stok':
              '${QuantityFormatter.label(product.stockPcs)} ${product.baseUnit.label}',
        },
      ),
      proposed: VoiceActionSnapshot(
        entityType: 'product',
        entityId: product.id,
        fingerprint: proposedFingerprint,
        fields: {'nama': product.name},
      ),
      summary: 'Perubahan stok ini belum didukung.',
      risk: VoiceActionRisk.high,
      requiresAuthentication: true,
      isReversible: false,
      createdAt: now,
      expiresAt: now.add(expiration),
      sourceTranscript: command.rawText,
      commandFingerprint: commandFingerprint,
      baseFingerprint: beforeFingerprint,
      validationErrors: const [
        'Set stok absolut dan pengurangan stok melalui suara belum didukung.',
      ],
    );
  }

  Future<VoiceActionDraft> _unsupported({
    required VoiceCommand command,
    required DateTime now,
    required String commandFingerprint,
  }) async {
    final fingerprint = await fingerprintService.create('unsupported');
    return VoiceActionDraft(
      actionId: _actionId(now, commandFingerprint),
      type: VoiceActionType.updateSettings,
      proposed: VoiceActionSnapshot(
        entityType: 'unknown',
        fingerprint: fingerprint,
      ),
      summary: 'Command mutasi ini belum didukung.',
      risk: VoiceActionRisk.high,
      requiresAuthentication: true,
      isReversible: false,
      createdAt: now,
      expiresAt: now.add(expiration),
      sourceTranscript: command.rawText,
      commandFingerprint: commandFingerprint,
      baseFingerprint: fingerprint,
      validationErrors: const ['Jenis perubahan belum didukung.'],
    );
  }

  int? _moneyAmount(VoiceCommand command) {
    final explicit = command.entities.salePrice;
    if (explicit != null) return explicit;
    final afterKeyword = moneyParser.firstAfterKeyword(
      command.normalizedText,
      const ['menjadi', 'jadi', 'sebesar', 'harga jual', 'harga'],
    );
    if (afterKeyword != null) return afterKeyword.amount;
    final candidates = moneyParser.parseAll(command.normalizedText);
    return candidates.isEmpty ? null : candidates.last.amount;
  }

  String _actionId(DateTime now, String fingerprint) {
    _sequence += 1;
    return 'voice-${now.microsecondsSinceEpoch}-$_sequence-${fingerprint.substring(0, 10)}';
  }

  String _rupiah(int value) => 'Rp${value.toString()}';

  String _createProductSummary({
    required Product product,
    required bool hasValidPrice,
  }) {
    if (!hasValidPrice) {
      return 'Produk ${product.name.isEmpty ? 'baru' : product.name} akan disiapkan sebagai draft.';
    }
    final stockSummary = product.trackStock
        ? ' dan stok awal ${QuantityFormatter.label(product.stockPcs)} ${product.baseUnit.label}'
        : ' tanpa pelacakan stok';
    return 'Produk ${product.name} akan ditambahkan dengan harga jual ${_rupiah(product.retailPrice)}$stockSummary.';
  }

  String _stockIncrementSummary(IncrementStockVoiceActionPayload payload) {
    final requested =
        '${QuantityFormatter.label(payload.requestedQuantity)} ${payload.requestedUnit.label}';
    final normalized =
        '${QuantityFormatter.label(payload.normalizedQuantity)} ${payload.baseUnit.label}';
    final before =
        '${QuantityFormatter.label(payload.stockBefore)} ${payload.baseUnit.label}';
    final after =
        '${QuantityFormatter.label(payload.stockAfter)} ${payload.baseUnit.label}';
    final conversion = payload.requestedUnit == payload.baseUnit
        ? ''
        : ' atau $normalized';
    final tracking = payload.enableTracking
        ? 'Pelacakan stok ${payload.productName} akan diaktifkan. '
        : '';
    return '$tracking Stok ${payload.productName} akan ditambah $requested$conversion, dari $before menjadi $after.'
        .trim();
  }

  String _stockStatusLabel(Product product) {
    return switch (product.stockStatus) {
      ProductStockStatus.notTracked => 'Tidak dilacak',
      ProductStockStatus.outOfStock => 'Habis',
      ProductStockStatus.low => 'Stok rendah',
      ProductStockStatus.safe => 'Aman',
    };
  }

  String _priceUpdateSummary(UpdateProductPriceVoiceActionPayload payload) {
    final oldLabel = _displayRupiah(payload.oldPrice);
    final newLabel = _displayRupiah(payload.newPrice);
    final action =
        payload.oldPrice == 0 && payload.priceType != ProductPriceType.retail
        ? 'akan ditetapkan menjadi $newLabel'
        : 'akan diubah dari $oldLabel menjadi $newLabel';
    final warning = payload.warnings.isEmpty
        ? ''
        : ' ${payload.warnings.map((item) => item.message(payload.productName)).join(' ')}';
    final history = payload.priceType == ProductPriceType.cost
        ? ' Laba transaksi lama tetap menggunakan modal historis.'
        : ' Perubahan hanya berlaku untuk transaksi berikutnya.';
    return '${payload.priceType.label.substring(0, 1).toUpperCase()}${payload.priceType.label.substring(1)} ${payload.productName} $action.$warning$history';
  }

  String _displayRupiah(int value) {
    final sign = value < 0 ? '-' : '';
    final raw = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '${sign}Rp ${buffer.toString()}';
  }

  String _percentageLabel(double value) {
    final normalized = value.abs() < 0.000001 ? 0.0 : value;
    final fixed = normalized.toStringAsFixed(
      normalized == normalized.roundToDouble() ? 0 : 1,
    );
    return '${normalized > 0 ? '+' : ''}$fixed%';
  }

  String? _similarProductName({
    required String name,
    required List<Product> products,
    required List<VoiceProductAlias> aliases,
  }) {
    if (name.isEmpty) return null;
    final match = productResolver.resolve(
      spokenName: name,
      products: products,
      aliases: aliases,
    );
    if (match.type == VoiceProductMatchType.alias ||
        match.type == VoiceProductMatchType.fuzzy) {
      return match.product?.name;
    }
    if (match.type == VoiceProductMatchType.ambiguous &&
        match.candidates.isNotEmpty) {
      return match.candidates.first.product.name;
    }
    if (match.type == VoiceProductMatchType.notFound &&
        match.candidates.isNotEmpty &&
        match.candidates.first.confidence >= 0.72) {
      return match.candidates.first.product.name;
    }
    return null;
  }

  String _titleCase(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
