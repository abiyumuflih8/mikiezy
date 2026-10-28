import '../../models/mikiezy_models.dart';

class MikiezySnapshot {
  const MikiezySnapshot({
    required this.products,
    required this.productCategories,
    required this.wallets,
    required this.categories,
    required this.transactions,
    required this.voiceProductAliases,
    required this.voiceUnitAliases,
    required this.voiceCorrections,
    this.onboardingCompleted = false,
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.cloudSyncEnabled,
    required this.supabaseUrl,
    required this.queuedSyncCount,
    required this.language,
    required this.voiceSensitivity,
    required this.handsfreeWakeWordEnabled,
    required this.silentTimeoutSeconds,
    required this.enableVoiceLearning,
    required this.voiceFinancialPrivacyEnabled,
    required this.maskVoiceFinancialValues,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.businessCategory,
    required this.businessLocation,
    required this.memberSince,
  });

  final List<Product> products;
  final List<String> productCategories;
  final List<Wallet> wallets;
  final List<LedgerCategory> categories;
  final List<TransactionRecord> transactions;
  final List<VoiceProductAlias> voiceProductAliases;
  final List<VoiceUnitAlias> voiceUnitAliases;
  final List<VoiceCorrection> voiceCorrections;
  final bool onboardingCompleted;
  final bool pinEnabled;
  final bool biometricEnabled;
  final bool cloudSyncEnabled;
  final String supabaseUrl;
  final int queuedSyncCount;
  final AppLanguage language;
  final int voiceSensitivity;
  final bool handsfreeWakeWordEnabled;
  final int silentTimeoutSeconds;
  final bool enableVoiceLearning;
  final bool voiceFinancialPrivacyEnabled;
  final bool maskVoiceFinancialValues;
  final String ownerName;
  final String email;
  final String phone;
  final String businessName;
  final String businessCategory;
  final String businessLocation;
  final String memberSince;

  MikiezySnapshot copy() {
    return MikiezySnapshot(
      products: List.of(products),
      productCategories: List.of(productCategories),
      wallets: List.of(wallets),
      categories: List.of(categories),
      transactions: List.of(transactions),
      voiceProductAliases: List.of(voiceProductAliases),
      voiceUnitAliases: List.of(voiceUnitAliases),
      voiceCorrections: List.of(voiceCorrections),
      onboardingCompleted: onboardingCompleted,
      pinEnabled: pinEnabled,
      biometricEnabled: biometricEnabled,
      cloudSyncEnabled: cloudSyncEnabled,
      supabaseUrl: supabaseUrl,
      queuedSyncCount: queuedSyncCount,
      language: language,
      voiceSensitivity: voiceSensitivity,
      handsfreeWakeWordEnabled: handsfreeWakeWordEnabled,
      silentTimeoutSeconds: silentTimeoutSeconds,
      enableVoiceLearning: enableVoiceLearning,
      voiceFinancialPrivacyEnabled: voiceFinancialPrivacyEnabled,
      maskVoiceFinancialValues: maskVoiceFinancialValues,
      ownerName: ownerName,
      email: email,
      phone: phone,
      businessName: businessName,
      businessCategory: businessCategory,
      businessLocation: businessLocation,
      memberSince: memberSince,
    );
  }
}
