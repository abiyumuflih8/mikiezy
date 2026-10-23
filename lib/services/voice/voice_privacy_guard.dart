import '../../domain/models/business_query_result.dart';
import '../../domain/models/voice_privacy_policy.dart';
import 'voice_command.dart';

class VoicePrivacyGuard {
  const VoicePrivacyGuard();

  VoiceCommandResponse protect(
    VoiceCommandResponse response,
    VoicePrivacyPolicy policy,
  ) {
    final result = response.businessResult;
    if (result?.metric != BusinessMetricType.walletBalance ||
        !policy.protectsWalletBalance) {
      return response;
    }

    final walletName = result!.walletName;
    final isAggregate = result.isAggregate;
    final subject = isAggregate
        ? 'Total saldo seluruh dompet'
        : 'Saldo dompet ${walletName ?? 'terpilih'}';
    final displayText = policy.maskFinancialValuesOnScreen
        ? '$subject: ********.'
        : response.displayText;
    final spokenText =
        policy.hideFinancialValuesFromTts || policy.maskFinancialValuesOnScreen
        ? policy.maskFinancialValuesOnScreen
              ? 'Nominal saldo disembunyikan karena mode privasi aktif.'
              : '$subject sudah ditampilkan di layar. Demi privasi, nominal tidak dibacakan.'
        : response.spokenText;

    return VoiceCommandResponse(
      displayText: displayText,
      spokenText: spokenText,
      kind: response.kind,
      title: response.title,
      businessResult: result,
      suggestedAction: response.suggestedAction,
    );
  }
}
