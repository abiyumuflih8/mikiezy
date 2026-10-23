class VoicePrivacyPolicy {
  const VoicePrivacyPolicy({
    this.hideFinancialValuesFromTts = false,
    this.maskFinancialValuesOnScreen = false,
    this.isAppLocked = false,
  });

  final bool hideFinancialValuesFromTts;
  final bool maskFinancialValuesOnScreen;
  final bool isAppLocked;

  bool get protectsWalletBalance =>
      hideFinancialValuesFromTts || maskFinancialValuesOnScreen;
}
