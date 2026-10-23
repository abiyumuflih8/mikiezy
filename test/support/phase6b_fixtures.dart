import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/models/mikiezy_models.dart';
import 'package:mikiezy/services/voice/voice_action_draft_factory.dart';
import 'package:mikiezy/services/voice/voice_command.dart';

Product phase6bProduct({
  String id = 'stock-product',
  String name = 'Kopi Susu',
  double stock = 20,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.gelas,
  int packSize = 12,
  int cartonSize = 48,
  double minStock = 5,
}) {
  return Product(
    id: id,
    name: name,
    category: 'Minuman',
    costPrice: 5000,
    retailPrice: 10000,
    wholesalePrice: 9000,
    packSize: packSize,
    cartonSize: cartonSize,
    stockPcs: stock,
    trackStock: trackStock,
    baseUnit: baseUnit,
    minStock: minStock,
  );
}

Future<VoiceActionDraft> phase6bIncrementAction({
  Product? product,
  double quantity = 10,
  SaleUnit unit = SaleUnit.gelas,
  bool trackingEnableConfirmed = false,
  bool wasClarified = false,
  VoiceActionStatus status = VoiceActionStatus.confirmed,
  DateTime? now,
}) async {
  final value = product ?? phase6bProduct();
  final createdAt = now ?? DateTime(2030, 1, 1, 10);
  final draft = await VoiceActionDraftFactory().create(
    command: VoiceCommand(
      rawText: 'tambah stok ${value.name} $quantity ${unit.label}',
      normalizedText:
          'tambah stok ${value.name.toLowerCase()} $quantity ${unit.name}',
      intent: VoiceCommandIntent.incrementProductStock,
      entities: VoiceCommandEntities(
        productId: value.id,
        productName: value.name,
        quantity: quantity,
        unit: unit.name,
        trackingEnableConfirmed: trackingEnableConfirmed,
        clarificationOccurred: wasClarified,
      ),
      confidence: 1,
    ),
    products: [value],
    now: createdAt,
  );
  return draft.copyWith(status: status);
}
