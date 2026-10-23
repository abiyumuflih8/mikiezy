import '../../models/mikiezy_models.dart';
import 'voice_action.dart';

enum VoiceActionExecutionStatus {
  succeeded,
  executionDisabled,
  locked,
  expired,
  notConfirmed,
  additionalConfirmationRequired,
  authenticationRequired,
  authenticationFailed,
  validationFailed,
  duplicateProduct,
  similarProductWarning,
  productNotFound,
  productAmbiguous,
  invalidPrice,
  samePrice,
  unsupportedPriceType,
  businessRuleWarning,
  invalidQuantity,
  unknownUnit,
  incompatibleUnit,
  missingPackSize,
  missingCartonSize,
  trackingConfirmationRequired,
  stale,
  alreadyExecuted,
  databaseFailure,
  auditFailure,
  stateRefreshFailed,
  cancelled,
  unexpectedFailure,
}

class VoiceActionExecutionResult {
  const VoiceActionExecutionResult({
    required this.status,
    required this.message,
    this.product,
    this.errorCode,
  });

  final VoiceActionExecutionStatus status;
  final String message;
  final Product? product;
  final String? errorCode;

  bool get isSuccess =>
      status == VoiceActionExecutionStatus.succeeded ||
      status == VoiceActionExecutionStatus.alreadyExecuted;
}

abstract interface class VoiceActionExecutor {
  bool supports(VoiceActionType type);

  Future<VoiceActionExecutionResult> execute(
    VoiceActionDraft action, {
    required bool isFeatureEnabled,
    required bool isAppLocked,
    bool authenticationSucceeded = false,
    bool authenticationAttempted = false,
    bool additionalConfirmationSucceeded = false,
    String? currentBaseFingerprint,
  });
}
