import '../../models/mikiezy_models.dart';
import 'voice_privacy_policy.dart';

class BusinessQueryData {
  BusinessQueryData({
    List<TransactionRecord> transactions = const [],
    List<Product> products = const [],
    List<Wallet> wallets = const [],
    List<VoiceProductAlias> productAliases = const [],
    this.isReady = true,
    this.sourceError,
    this.privacyPolicy = const VoicePrivacyPolicy(),
  }) : transactions = List.unmodifiable(transactions),
       products = List.unmodifiable(products),
       wallets = List.unmodifiable(wallets),
       productAliases = List.unmodifiable(productAliases);

  final List<TransactionRecord> transactions;
  final List<Product> products;
  final List<Wallet> wallets;
  final List<VoiceProductAlias> productAliases;
  final bool isReady;
  final String? sourceError;
  final VoicePrivacyPolicy privacyPolicy;
}
