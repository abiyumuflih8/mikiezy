import 'package:mikiezy/data/local/mikiezy_snapshot.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_payload.dart';
import 'package:mikiezy/models/mikiezy_models.dart';

Product phase6aProduct({
  String id = 'prd-voice-test',
  String name = 'Kopi Susu',
  String category = 'Minuman',
  int costPrice = 6000,
  int retailPrice = 10000,
  int wholesalePrice = 9000,
  int packSize = 10,
  int cartonSize = 24,
  double stock = 20,
  bool trackStock = true,
  SaleUnit baseUnit = SaleUnit.gelas,
  double minStock = 2,
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

VoiceActionDraft phase6aCreateAction({
  String actionId = 'voice-action-1',
  String commandFingerprint = 'command-fingerprint-1',
  String baseFingerprint = 'catalog-fingerprint-1',
  Product? product,
  VoiceActionStatus status = VoiceActionStatus.confirmed,
  DateTime? createdAt,
  DateTime? expiresAt,
  bool requiresAuthentication = false,
  String? similarProductName,
  bool similarProductConfirmed = false,
}) {
  final value = product ?? phase6aProduct();
  final created = createdAt ?? DateTime(2030, 1, 1, 10);
  final fields = <String, String>{
    'nama': value.name,
    'hargaJual': 'Rp${value.retailPrice}',
    'hargaModal': 'Rp${value.costPrice}',
    'hargaGrosir': 'Rp${value.wholesalePrice}',
    'kategori': value.category,
    'lacakStok': value.trackStock ? 'Ya' : 'Tidak',
    'stok': value.trackStock
        ? '${value.stockPcs} ${value.baseUnit.name}'
        : 'Tidak dilacak',
    'stokMinimum': value.minStock.toString(),
    'isiPack': value.packSize.toString(),
    'isiKarton': value.cartonSize.toString(),
    'produkMirip': ?similarProductName,
  };
  return VoiceActionDraft(
    actionId: actionId,
    type: VoiceActionType.createProduct,
    payload: CreateProductVoiceActionPayload(
      product: value,
      similarProductName: similarProductName,
      similarProductConfirmed: similarProductConfirmed,
    ),
    proposed: VoiceActionSnapshot(
      entityType: 'product',
      entityId: value.id,
      fingerprint: 'proposed-${value.id}',
      fields: fields,
    ),
    changes: [
      VoiceActionFieldChange(
        field: 'name',
        label: 'Nama produk',
        after: value.name,
      ),
    ],
    summary:
        'Produk ${value.name} akan dibuat dengan harga jual Rp${value.retailPrice}.',
    risk: VoiceActionRisk.medium,
    requiresAuthentication: requiresAuthentication,
    isReversible: false,
    createdAt: created,
    expiresAt: expiresAt ?? created.add(const Duration(minutes: 5)),
    sourceTranscript: 'transcript hanya untuk fixture',
    commandFingerprint: commandFingerprint,
    baseFingerprint: baseFingerprint,
    status: status,
  );
}

MikiezySnapshot phase6aSnapshot({
  List<Product> products = const [],
  List<String> productCategories = const ['Lain-lain', 'Minuman'],
}) {
  return MikiezySnapshot(
    products: products,
    productCategories: productCategories,
    wallets: const [],
    categories: const [],
    transactions: const [],
    voiceProductAliases: const [],
    voiceUnitAliases: const [],
    voiceCorrections: const [],
    pinEnabled: false,
    biometricEnabled: false,
    cloudSyncEnabled: false,
    supabaseUrl: 'Belum dikonfigurasi',
    queuedSyncCount: 0,
    language: AppLanguage.id,
    voiceSensitivity: 75,
    handsfreeWakeWordEnabled: false,
    silentTimeoutSeconds: 5,
    enableVoiceLearning: true,
    voiceFinancialPrivacyEnabled: true,
    maskVoiceFinancialValues: true,
    ownerName: 'Pemilik',
    email: '',
    phone: '',
    businessName: 'Toko Test',
    businessCategory: 'UMKM',
    businessLocation: '',
    memberSince: '2030',
  );
}
