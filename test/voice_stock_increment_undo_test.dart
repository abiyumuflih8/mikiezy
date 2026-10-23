import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/data/repositories/mikiezy_repository.dart';
import 'package:mikiezy/domain/models/voice_action.dart';
import 'package:mikiezy/domain/models/voice_action_execution.dart';
import 'package:mikiezy/domain/services/voice_action_undo.dart';
import 'package:mikiezy/services/voice/increment_stock_voice_action_executor.dart';

import 'support/phase6a_fixtures.dart';
import 'support/phase6b_fixtures.dart';

void main() {
  test('stock increment draft never advertises unsafe undo', () async {
    final action = await phase6bIncrementAction();

    expect(action.isReversible, isFalse);
    expect(action.type, VoiceActionType.incrementProductStock);
  });

  test(
    'typed undo result remains unavailable without a movement ledger',
    () async {
      const service = PreviewOnlyVoiceActionUndoService();
      final result = await service.reverse(
        const VoiceUndoRequest(
          actionId: 'stock-action',
          actionType: VoiceActionType.incrementProductStock,
          entityFingerprint: 'stock-fingerprint',
        ),
      );

      expect(result.status, VoiceUndoStatus.notAvailable);
      expect(result.message, contains('belum tersedia'));
    },
  );

  test('successful stock audit records undo as unavailable', () async {
    final product = phase6bProduct();
    final repository = MemoryMikiezyRepository();
    await repository.loadOrSeed(phase6aSnapshot(products: [product]));
    final action = await phase6bIncrementAction(product: product);
    final executor = IncrementStockVoiceActionExecutor(
      repository,
      now: () => DateTime(2030, 1, 1, 10, 1),
    );

    final result = await executor.execute(
      action,
      isFeatureEnabled: true,
      isAppLocked: false,
      currentBaseFingerprint: action.baseFingerprint,
    );
    final audits = await repository.loadVoiceActionAudits(action.actionId);

    expect(result.status, VoiceActionExecutionStatus.succeeded);
    expect(audits, isNotEmpty);
    expect(
      audits.every((event) => event.undoStatus == VoiceUndoStatus.notAvailable),
      isTrue,
    );
  });
}
