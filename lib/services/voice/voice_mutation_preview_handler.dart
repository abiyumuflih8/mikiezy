import '../../domain/models/voice_action.dart';
import '../../models/mikiezy_models.dart';
import 'voice_action_coordinator.dart';
import 'voice_action_draft_factory.dart';
import 'voice_command.dart';
import 'voice_command_router.dart';
import 'voice_create_product_conversation.dart';
import 'voice_price_update_conversation.dart';
import 'voice_stock_increment_conversation.dart';

class VoiceMutationPreviewHandler {
  VoiceMutationPreviewHandler(
    this._coordinator,
    this._productsProvider, {
    List<VoiceProductAlias> Function()? aliasesProvider,
    List<VoiceUnitAlias> Function()? unitAliasesProvider,
    this.refreshProducts,
    bool Function()? isAppLocked,
    VoiceActionDraftFactory? draftFactory,
    VoiceCreateProductConversation? createProductConversation,
    VoiceStockIncrementConversation? stockIncrementConversation,
    VoicePriceUpdateConversation? priceUpdateConversation,
    VoiceCommandRouter? commandRouter,
    DateTime Function()? now,
  }) : _aliasesProvider = aliasesProvider ?? _emptyAliases,
       _unitAliasesProvider = unitAliasesProvider ?? _emptyUnitAliases,
       _isAppLocked = isAppLocked ?? _alwaysUnlocked,
       _draftFactory = draftFactory ?? VoiceActionDraftFactory(),
       _createProductConversation =
           createProductConversation ?? VoiceCreateProductConversation(),
       _stockIncrementConversation =
           stockIncrementConversation ?? VoiceStockIncrementConversation(),
       _priceUpdateConversation =
           priceUpdateConversation ?? VoicePriceUpdateConversation(),
       _commandRouter = commandRouter ?? const VoiceCommandRouter(),
       _now = now ?? DateTime.now;

  final VoiceActionCoordinator _coordinator;
  final List<Product> Function() _productsProvider;
  final List<VoiceProductAlias> Function() _aliasesProvider;
  final List<VoiceUnitAlias> Function() _unitAliasesProvider;
  final Future<void> Function()? refreshProducts;
  final bool Function() _isAppLocked;
  final VoiceActionDraftFactory _draftFactory;
  final VoiceCreateProductConversation _createProductConversation;
  final VoiceStockIncrementConversation _stockIncrementConversation;
  final VoicePriceUpdateConversation _priceUpdateConversation;
  final VoiceCommandRouter _commandRouter;
  final DateTime Function() _now;

  bool get hasPendingAction => _coordinator.hasPendingAction;
  bool get hasPendingClarification =>
      _createProductConversation.hasPending ||
      _stockIncrementConversation.hasPending ||
      _priceUpdateConversation.hasPending;

  VoiceActionDraft? get pendingAction => _coordinator.pendingAction;

  Future<VoiceCommandResponse> preview(VoiceCommand command) async {
    if (command.intent == VoiceCommandIntent.createProduct) {
      final turn = _createProductConversation.start(
        command: command,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        unitAliases: _unitAliasesProvider(),
        now: _now(),
      );
      return _resolveCreateProductTurn(turn);
    }
    if (command.intent == VoiceCommandIntent.incrementProductStock) {
      final turn = _stockIncrementConversation.start(
        command: command,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        unitAliases: _unitAliasesProvider(),
        now: _now(),
      );
      return _resolveStockIncrementTurn(turn);
    }
    if (command.intent == VoiceCommandIntent.updateProduct) {
      final turn = _priceUpdateConversation.start(
        command: command,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        now: _now(),
      );
      return _resolvePriceUpdateTurn(turn);
    }
    return _previewReadyCommand(command);
  }

  Future<VoiceCommandResponse?> handleClarificationAnswer(String answer) async {
    final routedAnswer = _commandRouter.route(answer);
    if (_stockIncrementConversation.hasPending) {
      final turn = _stockIncrementConversation.answer(
        transcript: answer,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        unitAliases: _unitAliasesProvider(),
        now: _now(),
        looksLikeNewCommand: routedAnswer.intent != VoiceCommandIntent.unknown,
      );
      if (turn.routeAsNewCommand) return null;
      return _resolveStockIncrementTurn(turn);
    }
    if (_priceUpdateConversation.hasPending) {
      final turn = _priceUpdateConversation.answer(
        transcript: answer,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        now: _now(),
        looksLikeNewCommand: routedAnswer.intent != VoiceCommandIntent.unknown,
      );
      if (turn.routeAsNewCommand) return null;
      return _resolvePriceUpdateTurn(turn);
    }
    final turn = _createProductConversation.answer(
      transcript: answer,
      products: _productsProvider(),
      aliases: _aliasesProvider(),
      unitAliases: _unitAliasesProvider(),
      now: _now(),
      looksLikeNewCommand: routedAnswer.intent != VoiceCommandIntent.unknown,
    );
    if (turn.routeAsNewCommand) return null;
    return _resolveCreateProductTurn(turn);
  }

  Future<VoiceCommandResponse> _resolvePriceUpdateTurn(
    VoicePriceUpdateConversationTurn turn,
  ) async {
    final response = turn.response;
    if (response != null) return response;
    final readyCommand = turn.readyCommand;
    if (readyCommand != null) return _previewReadyCommand(readyCommand);
    return const VoiceCommandResponse(
      displayText:
          'Data perubahan harga belum dapat disiapkan. Ulangi perintah.',
      kind: VoiceResponseKind.error,
    );
  }

  Future<VoiceCommandResponse> _resolveStockIncrementTurn(
    VoiceStockIncrementConversationTurn turn,
  ) async {
    final response = turn.response;
    if (response != null) return response;
    final readyCommand = turn.readyCommand;
    if (readyCommand != null) return _previewReadyCommand(readyCommand);
    return const VoiceCommandResponse(
      displayText:
          'Data penambahan stok belum dapat disiapkan. Ulangi perintah.',
      kind: VoiceResponseKind.error,
    );
  }

  Future<VoiceCommandResponse> _resolveCreateProductTurn(
    VoiceCreateProductConversationTurn turn,
  ) async {
    final rejectedCommand = turn.rejectedCommand;
    if (rejectedCommand != null) {
      final draft = await _draftFactory.create(
        command: rejectedCommand,
        products: _productsProvider(),
        aliases: _aliasesProvider(),
        now: _now(),
      );
      return _coordinator.rejectDuplicate(
        draft,
        response:
            turn.response ??
            const VoiceCommandResponse(
              displayText: 'Produk tersebut sudah tersedia.',
              kind: VoiceResponseKind.error,
            ),
        isAppLocked: _isAppLocked(),
      );
    }
    final response = turn.response;
    if (response != null) return response;
    final readyCommand = turn.readyCommand;
    if (readyCommand != null) return _previewReadyCommand(readyCommand);
    return const VoiceCommandResponse(
      displayText: 'Data produk belum dapat disiapkan. Ulangi perintah.',
      kind: VoiceResponseKind.error,
    );
  }

  Future<VoiceCommandResponse> _previewReadyCommand(
    VoiceCommand command,
  ) async {
    final draft = await _draftFactory.create(
      command: command,
      products: _productsProvider(),
      aliases: _aliasesProvider(),
      unitAliases: _unitAliasesProvider(),
      now: _now(),
    );
    return _coordinator.preview(draft, isAppLocked: _isAppLocked());
  }

  Future<VoiceCommandResponse> handlePendingAnswer(String answer) {
    return _coordinator.handleAnswer(
      answer,
      isAppLocked: _isAppLocked(),
      currentBaseFingerprint: _currentBaseFingerprint,
      refreshDraftOnStale: _refreshDraftFromProvider,
      refreshDraftFromProduct: _refreshDraftFromProduct,
    );
  }

  Future<void> cancelPending({String errorCode = 'session_closed'}) {
    _createProductConversation.clear();
    _stockIncrementConversation.clear();
    _priceUpdateConversation.clear();
    return _coordinator.cancelPending(errorCode: errorCode);
  }

  Future<String?> _currentBaseFingerprint(VoiceActionDraft action) async {
    if (action.type == VoiceActionType.createProduct) {
      return _draftFactory.catalogFingerprint(_productsProvider());
    }
    final targetId = action.proposed.entityId;
    if (targetId == null) return null;
    for (final product in _productsProvider()) {
      if (product.id == targetId) {
        if (action.type == VoiceActionType.updateProductPrice) {
          return _draftFactory.priceProductFingerprint(product);
        }
        return _draftFactory.productFingerprint(product);
      }
    }
    return null;
  }

  Future<VoiceActionDraft?> _refreshDraftFromProvider(
    VoiceActionDraft action,
  ) async {
    if (action.type != VoiceActionType.incrementProductStock &&
        action.type != VoiceActionType.updateProductPrice) {
      return null;
    }
    final targetId = action.proposed.entityId;
    if (targetId == null) return null;
    for (final product in _productsProvider()) {
      if (product.id == targetId) {
        return _refreshDraftFromProduct(action, product);
      }
    }
    return null;
  }

  Future<VoiceActionDraft?> _refreshDraftFromProduct(
    VoiceActionDraft action,
    Product latestProduct,
  ) async {
    final refresh = refreshProducts;
    if (refresh != null) await refresh();
    var refreshedProduct = latestProduct;
    for (final product in _productsProvider()) {
      if (product.id == latestProduct.id) {
        refreshedProduct = product;
        break;
      }
    }
    if (action.type == VoiceActionType.updateProductPrice) {
      return _draftFactory.refreshPriceUpdateDraft(
        action: action,
        latestProduct: refreshedProduct,
        now: _now(),
      );
    }
    return _draftFactory.refreshIncrementStockDraft(
      action: action,
      latestProduct: refreshedProduct,
      now: _now(),
    );
  }
}

List<VoiceProductAlias> _emptyAliases() => const [];

List<VoiceUnitAlias> _emptyUnitAliases() => const [];

bool _alwaysUnlocked() => false;
