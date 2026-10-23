import 'package:mikiezy/domain/models/product_price.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_action_draft_factory.dart';
import 'package:mikiezy/services/voice/voice_command.dart';

Product phase6cProduct({
  String id = 'price-product',
  String name = 'Kopi Susu',
  String category = 'Minuman',
  int retailPrice = 10000,
  int wholesalePrice = 9000,
  int costPrice = 6000,
  double stock = 20,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.gelas,
  double minStock = 5,
  int packSize = 10,
  int cartonSize = 24,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    costPrice: costPrice,
    retailPrice: retailPrice,
    wholesalePrice: wholesalePrice,
    packSize: packSize,
    cartonSize: cartonSize,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
    minStock: minStock,
  );
}

Future<VoiceActionDraft> phase6cPriceAction({
  Product? product,
  ProductPriceType priceType = ProductPriceType.retail,
  int newPrice = 12000,
  VoiceActionStatus status = VoiceActionStatus.confirmed,
  bool wasClarified = false,
  DateTime? now,
}) async {
  final value = product ?? phase6cProduct();
  final createdAt = now ?? DateTime(2030, 1, 1, 10);
  final draft = await VoiceActionDraftFactory().create(
    command: VoiceCommand(
      rawText: 'ubah ${priceType.label} ${value.name} menjadi $newPrice',
      normalizedText:
          'ubah ${priceType.label} ${value.name.toLowerCase()} menjadi $newPrice',
      intent: VoiceCommandIntent.updateProduct,
      entities: VoiceCommandEntities(
        productId: value.id,
        productName: value.name,
        productPriceType: priceType,
        newProductPrice: newPrice,
        clarificationOccurred: wasClarified,
      ),
      confidence: 1,
    ),
    products: [value],
    now: createdAt,
  );
  return draft.copyWith(status: status);
}

VoiceActionDraft copyPhase6cAction(
  VoiceActionDraft action, {
  VoiceActionStatus? status,
  DateTime? expiresAt,
  VoiceActionPayload? payload,
  List<String>? validationErrors,
  bool? requiresAuthentication,
}) {
  return VoiceActionDraft(
    actionId: action.actionId,
    type: action.type,
    before: action.before,
    payload: payload ?? action.payload,
    proposed: action.proposed,
    changes: action.changes,
    summary: action.summary,
    risk: action.risk,
    requiresAuthentication:
        requiresAuthentication ?? action.requiresAuthentication,
    isReversible: action.isReversible,
    createdAt: action.createdAt,
    expiresAt: expiresAt ?? action.expiresAt,
    sourceTranscript: action.sourceTranscript,
    commandFingerprint: action.commandFingerprint,
    baseFingerprint: action.baseFingerprint,
    validationErrors: validationErrors ?? action.validationErrors,
    status: status ?? action.status,
  );
}
