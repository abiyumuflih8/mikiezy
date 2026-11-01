import '../../domain/models/product_price.dart';
import '../../domain/models/voice_action.dart';
import '../../domain/models/voice_action_execution.dart';
import '../../domain/models/voice_action_payload.dart';
import '../../domain/services/voice_action_audit_store.dart';
import '../../models/mikiezy_models.dart';
import '../diagnostics/safe_diagnostics.dart';
import 'voice_action_confirmation_parser.dart';
import 'voice_command.dart';

class VoiceMutationFeatureFlags {
  const VoiceMutationFeatureFlags({
    this.enableVoiceCreateProduct = false,
    this.enableVoiceStockIncrement = false,
    this.enableVoicePriceUpdate = false,
  });

  final bool enableVoiceCreateProduct;
  final bool enableVoiceStockIncrement;
  final bool enableVoicePriceUpdate;

  bool isEnabled(VoiceActionType type) {
    return switch (type) {
      VoiceActionType.createProduct => enableVoiceCreateProduct,
      VoiceActionType.incrementProductStock => enableVoiceStockIncrement,
      VoiceActionType.updateProductPrice => enableVoicePriceUpdate,
      _ => false,
    };
  }
}

class VoiceActionCoordinator {
  VoiceActionCoordinator(
    this._auditStore, {
    this.confirmationParser = const VoiceActionConfirmationParser(),
    this.featureFlags = const VoiceMutationFeatureFlags(),
    List<VoiceActionExecutor> executors = const [],
    DateTime Function()? now,
  }) : _executors = List.unmodifiable(executors),
       _now = now ?? DateTime.now;

  final VoiceActionAuditStore _auditStore;
  final VoiceActionConfirmationParser confirmationParser;
  final VoiceMutationFeatureFlags featureFlags;
  final List<VoiceActionExecutor> _executors;
  final DateTime Function() _now;
  final Set<String> _finalizedActionIds = {};
  final Set<String> _awaitingAdditionalConfirmationActionIds = {};
  final Set<String> _inFlightActionIds = {};

  VoiceActionDraft? pendingAction;

  bool get hasPendingAction => pendingAction != null;

  Future<void> cancelPending({String errorCode = 'session_closed'}) async {
    final action = pendingAction;
    if (action == null) return;
    _inFlightActionIds.remove(action.actionId);
    await _record(action, VoiceActionStatus.cancelled, errorCode: errorCode);
    pendingAction = null;
    _awaitingAdditionalConfirmationActionIds.remove(action.actionId);
    _finalizedActionIds.add(action.actionId);
  }

  Future<VoiceCommandResponse> rejectDuplicate(
    VoiceActionDraft draft, {
    required VoiceCommandResponse response,
    required bool isAppLocked,
  }) async {
    if (isAppLocked) {
      await _record(
        draft,
        VoiceActionStatus.blockedLocked,
        errorCode: 'app_locked',
      );
      return const VoiceCommandResponse(
        displayText:
            'Aplikasi masih terkunci. Buka kunci lalu ulangi perintah perubahan.',
        kind: VoiceResponseKind.error,
        title: 'Perubahan diblokir',
      );
    }
    await _record(
      draft,
      VoiceActionStatus.duplicateRejected,
      errorCode: 'duplicate_product_name',
    );
    _finalizedActionIds.add(draft.actionId);
    return response;
  }

  Future<VoiceCommandResponse> preview(
    VoiceActionDraft draft, {
    required bool isAppLocked,
  }) async {
    if (isAppLocked) {
      await _record(
        draft,
        VoiceActionStatus.blockedLocked,
        errorCode: 'app_locked',
      );
      return const VoiceCommandResponse(
        displayText:
            'Aplikasi masih terkunci. Buka kunci lalu ulangi perintah perubahan.',
        kind: VoiceResponseKind.error,
        title: 'Perubahan diblokir',
      );
    }
    if (!draft.isValid) {
      await _record(
        draft,
        VoiceActionStatus.validationFailed,
        errorCode: 'validation_failed',
      );
      return VoiceCommandResponse(
        displayText: draft.validationErrors.join(' '),
        kind: VoiceResponseKind.error,
        title: 'Preview belum valid',
      );
    }

    final current = pendingAction;
    if (current != null &&
        current.commandFingerprint == draft.commandFingerprint &&
        !current.isExpiredAt(_now())) {
      return _previewResponse(current);
    }

    pendingAction = draft.copyWith(status: VoiceActionStatus.previewed);
    await _recordPreviewEvents(pendingAction!);
    return _previewResponse(pendingAction!);
  }

  Future<VoiceCommandResponse> handleAnswer(
    String answer, {
    required bool isAppLocked,
    Future<String?> Function(VoiceActionDraft action)? currentBaseFingerprint,
    Future<VoiceActionDraft?> Function(VoiceActionDraft action)?
    refreshDraftOnStale,
    Future<VoiceActionDraft?> Function(
      VoiceActionDraft action,
      Product latestProduct,
    )?
    refreshDraftFromProduct,
    bool authenticationSucceeded = false,
    bool authenticationAttempted = false,
  }) async {
    final action = pendingAction;
    if (action == null) {
      return const VoiceCommandResponse(
        displayText: 'Tidak ada perubahan yang sedang menunggu konfirmasi.',
        kind: VoiceResponseKind.error,
      );
    }
    if (isAppLocked) {
      await _record(
        action,
        VoiceActionStatus.blockedLocked,
        errorCode: 'app_locked',
      );
      _finish(action);
      return const VoiceCommandResponse(
        displayText:
            'Aplikasi terkunci. Perubahan dibatalkan dan harus dibuat ulang setelah unlock.',
        kind: VoiceResponseKind.error,
      );
    }
    if (action.isExpiredAt(_now())) {
      await _record(
        action,
        VoiceActionStatus.expired,
        errorCode: 'confirmation_expired',
      );
      _finish(action);
      return const VoiceCommandResponse(
        displayText: 'Preview perubahan sudah kedaluwarsa. Ulangi perintah.',
        kind: VoiceResponseKind.error,
      );
    }

    final decision = confirmationParser.parse(answer);
    switch (decision) {
      case VoiceActionConfirmationDecision.cancel:
        await _record(action, VoiceActionStatus.cancelled);
        _finish(action);
        return const VoiceCommandResponse(
          displayText: 'Perubahan dibatalkan. Tidak ada data yang diubah.',
        );
      case VoiceActionConfirmationDecision.details:
        return VoiceCommandResponse(
          displayText: _details(action),
          kind: VoiceResponseKind.confirmation,
          title: 'Detail perubahan',
        );
      case VoiceActionConfirmationDecision.edit:
        await _record(
          action,
          VoiceActionStatus.cancelled,
          errorCode: 'edit_requested',
        );
        _finish(action);
        return const VoiceCommandResponse(
          displayText:
              'Preview lama dibatalkan. Ulangi perintah dengan nilai yang benar.',
          kind: VoiceResponseKind.question,
        );
      case VoiceActionConfirmationDecision.repeat:
        return _previewResponse(action);
      case VoiceActionConfirmationDecision.unknown:
        return const VoiceCommandResponse(
          displayText:
              'Jawab ya, konfirmasi, lanjutkan, batal, ubah, ulangi, atau lihat detail.',
          kind: VoiceResponseKind.question,
        );
      case VoiceActionConfirmationDecision.confirm:
        break;
    }

    if (_finalizedActionIds.contains(action.actionId)) {
      pendingAction = null;
      return const VoiceCommandResponse(
        displayText: 'Perintah ini sudah pernah dijalankan.',
        kind: VoiceResponseKind.information,
      );
    }

    if (_inFlightActionIds.contains(action.actionId)) {
      return const VoiceCommandResponse(
        displayText: 'Perintah ini sedang diproses. Mohon tunggu.',
        kind: VoiceResponseKind.information,
      );
    }
    _inFlightActionIds.add(action.actionId);
    try {

    String? currentFingerprint;
    if (currentBaseFingerprint != null) {
      currentFingerprint = await currentBaseFingerprint(action);
      if (currentFingerprint == null ||
          currentFingerprint != action.baseFingerprint) {
        await _record(
          action,
          VoiceActionStatus.staleRejected,
          errorCode: 'stale_entity',
        );
        final refreshed = refreshDraftOnStale == null
            ? null
            : await refreshDraftOnStale(action);
        if (refreshed != null) {
          return _replaceWithStalePreview(action, refreshed);
        }
        _finish(action);
        return const VoiceCommandResponse(
          displayText:
              'Data produk sudah berubah sejak perintah dibuat. Silakan ulangi perintah.',
          kind: VoiceResponseKind.error,
        );
      }
    }

    final pricePayload = action.payload;
    final requiresAdditionalConfirmation =
        pricePayload is UpdateProductPriceVoiceActionPayload &&
        pricePayload.requiresAdditionalConfirmation;
    final wasAwaitingAdditionalConfirmation =
        _awaitingAdditionalConfirmationActionIds.contains(action.actionId);
    final confirmedAction = action.copyWith(
      status: VoiceActionStatus.confirmed,
    );
    if (!wasAwaitingAdditionalConfirmation) {
      await _record(
        confirmedAction,
        VoiceActionStatus.confirmed,
        confirmed: true,
        authenticationSucceeded: authenticationSucceeded,
      );
      if (requiresAdditionalConfirmation) {
        _awaitingAdditionalConfirmationActionIds.add(action.actionId);
        await _record(
          confirmedAction,
          VoiceActionStatus.additionalConfirmationRequired,
          confirmed: true,
          authenticationSucceeded: authenticationSucceeded,
          errorCode: 'business_warning_requires_confirmation',
        );
        return _additionalConfirmationResponse(pricePayload);
      }
    } else {
      _awaitingAdditionalConfirmationActionIds.remove(action.actionId);
      await _record(
        confirmedAction,
        VoiceActionStatus.additionalConfirmationConfirmed,
        confirmed: true,
        authenticationSucceeded: authenticationSucceeded,
      );
    }

    if (confirmedAction.requiresAuthentication && !authenticationSucceeded) {
      final auditStatus = authenticationAttempted
          ? VoiceActionStatus.authenticationFailed
          : VoiceActionStatus.authenticationRequired;
      await _record(
        confirmedAction,
        auditStatus,
        confirmed: true,
        errorCode: authenticationAttempted
            ? 'authentication_failed'
            : 'authentication_required',
      );
      _finish(confirmedAction);
      return VoiceCommandResponse(
        displayText: authenticationAttempted
            ? 'Autentikasi gagal atau dibatalkan. Tidak ada data yang diubah.'
            : 'Autentikasi aman diperlukan melalui layar aplikasi. Tidak ada data yang diubah.',
        kind: VoiceResponseKind.error,
      );
    }

    final enabled = featureFlags.isEnabled(confirmedAction.type);
    final executor = _executorFor(confirmedAction.type);
    if (!enabled || executor == null) {
      await _record(
        confirmedAction,
        VoiceActionStatus.executionDisabled,
        confirmed: true,
        authenticationSucceeded: authenticationSucceeded,
        errorCode: enabled ? 'executor_not_available' : 'feature_flag_disabled',
      );
      _finish(confirmedAction);
      return const VoiceCommandResponse(
        displayText:
            'Perubahan ini belum diaktifkan. Tidak ada data yang diubah.',
        kind: VoiceResponseKind.information,
        title: 'Eksekusi dinonaktifkan',
      );
    }

    try {
      final result = await executor.execute(
        confirmedAction,
        isFeatureEnabled: enabled,
        isAppLocked: isAppLocked,
        authenticationSucceeded: authenticationSucceeded,
        authenticationAttempted: authenticationAttempted,
        additionalConfirmationSucceeded:
            !requiresAdditionalConfirmation ||
            wasAwaitingAdditionalConfirmation,
        currentBaseFingerprint: currentFingerprint,
      );
      SafeDiagnostics.voiceEvent(
        'voice_action_execution_result',
        intent: confirmedAction.type.name,
        status: result.status.name,
        actionFingerprint: confirmedAction.commandFingerprint,
      );
      if (result.status == VoiceActionExecutionStatus.stale &&
          result.product != null &&
          refreshDraftFromProduct != null) {
        final refreshed = await refreshDraftFromProduct(
          confirmedAction,
          result.product!,
        );
        if (refreshed != null) {
          return _replaceWithStalePreview(confirmedAction, refreshed);
        }
      }
      _finish(confirmedAction);
      return _executionResponse(result, confirmedAction.type);
    } catch (error, stackTrace) {
      SafeDiagnostics.failure(
        'voice_action_executor_unexpected_failure',
        error,
        stackTrace,
      );
      await _record(
        confirmedAction,
        VoiceActionStatus.failed,
        confirmed: true,
        authenticationSucceeded: authenticationSucceeded,
        errorCode: 'executor_unexpected_failure',
      );
      _finish(confirmedAction);
      return const VoiceCommandResponse(
        displayText:
            'Perubahan belum berhasil disimpan dan tidak ada data yang berubah.',
        kind: VoiceResponseKind.error,
      );
    }
    } finally {
      _inFlightActionIds.remove(action.actionId);
    }
  }

  VoiceActionExecutor? _executorFor(VoiceActionType type) {
    for (final executor in _executors) {
      if (executor.supports(type)) return executor;
    }
    return null;
  }

  VoiceCommandResponse _executionResponse(
    VoiceActionExecutionResult result,
    VoiceActionType actionType,
  ) {
    final success =
        result.status == VoiceActionExecutionStatus.succeeded ||
        result.status == VoiceActionExecutionStatus.alreadyExecuted;
    final refreshFailed =
        result.status == VoiceActionExecutionStatus.stateRefreshFailed;
    final stockAction = actionType == VoiceActionType.incrementProductStock;
    final priceAction = actionType == VoiceActionType.updateProductPrice;
    return VoiceCommandResponse(
      displayText: result.message,
      spokenText: result.message,
      kind: success || refreshFailed
          ? VoiceResponseKind.information
          : VoiceResponseKind.error,
      title: success
          ? priceAction
                ? 'Harga diperbarui'
                : stockAction
                ? 'Stok diperbarui'
                : 'Produk tersimpan'
          : refreshFailed && priceAction
          ? 'Harga tersimpan, muat ulang'
          : priceAction
          ? 'Harga belum diperbarui'
          : stockAction
          ? 'Stok belum diperbarui'
          : 'Produk belum tersimpan',
    );
  }

  Future<VoiceCommandResponse> _replaceWithStalePreview(
    VoiceActionDraft oldAction,
    VoiceActionDraft refreshed,
  ) async {
    pendingAction = null;
    _awaitingAdditionalConfirmationActionIds.remove(oldAction.actionId);
    _finalizedActionIds.add(oldAction.actionId);
    if (!refreshed.isValid) {
      await _record(
        refreshed,
        VoiceActionStatus.validationFailed,
        errorCode: 'stale_preview_invalid',
      );
      _finalizedActionIds.add(refreshed.actionId);
      return VoiceCommandResponse(
        displayText:
            'Data produk berubah dan preview baru belum valid. ${refreshed.validationErrors.join(' ')}',
        kind: VoiceResponseKind.error,
        title: 'Preview perlu diperbaiki',
      );
    }
    pendingAction = refreshed.copyWith(status: VoiceActionStatus.previewed);
    await _recordPreviewEvents(pendingAction!);
    final preview = _previewResponse(pendingAction!);
    final priceAction = refreshed.type == VoiceActionType.updateProductPrice;
    final subject = priceAction ? 'Harga produk' : 'Stok produk';
    return VoiceCommandResponse(
      displayText:
          '$subject sudah berubah. Preview baru telah dibuat dan memerlukan konfirmasi ulang.\n\n${preview.displayText}',
      spokenText:
          '$subject sudah berubah. Preview baru memerlukan konfirmasi ulang. ${pendingAction!.summary}',
      kind: VoiceResponseKind.confirmation,
      title: priceAction
          ? 'Preview harga diperbarui'
          : 'Preview stok diperbarui',
      suggestedAction: 'Konfirmasi ulang atau batal',
    );
  }

  Future<void> _recordPreviewEvents(VoiceActionDraft action) async {
    if (action.type == VoiceActionType.incrementProductStock ||
        action.type == VoiceActionType.updateProductPrice) {
      await _record(action, VoiceActionStatus.draft);
      final payload = action.payload;
      final wasClarified =
          payload is IncrementStockVoiceActionPayload && payload.wasClarified ||
          payload is UpdateProductPriceVoiceActionPayload &&
              payload.wasClarified;
      if (wasClarified) {
        await _record(action, VoiceActionStatus.clarificationRequested);
      }
      if (payload is UpdateProductPriceVoiceActionPayload &&
          payload.warnings.isNotEmpty) {
        await _record(action, VoiceActionStatus.warningShown);
      }
    }
    await _record(action, VoiceActionStatus.previewed);
  }

  VoiceCommandResponse _previewResponse(VoiceActionDraft action) {
    final authNote = action.requiresAuthentication
        ? ' Aksi ini memerlukan autentikasi aman melalui layar aplikasi.'
        : '';
    final undoNote = action.isReversible
        ? ''
        : ' Undo belum tersedia untuk aksi ini.';
    return VoiceCommandResponse(
      displayText:
          '${action.summary}\n\n${_details(action)}\n\nPerubahan belum diterapkan.$authNote$undoNote Konfirmasi untuk menyimpan, atau batal.',
      spokenText:
          '${action.summary}$authNote Konfirmasi untuk menyimpan, atau katakan batal.',
      kind: VoiceResponseKind.confirmation,
      title: 'Preview perubahan',
      suggestedAction: 'Konfirmasi atau batal',
    );
  }

  VoiceCommandResponse _additionalConfirmationResponse(
    UpdateProductPriceVoiceActionPayload payload,
  ) {
    final warnings = payload.warnings
        .map((warning) => warning.message(payload.productName))
        .join(' ');
    return VoiceCommandResponse(
      displayText:
          '$warnings\n\nKonfirmasi tambahan diperlukan. Harga belum diubah. Katakan ya atau konfirmasi sekali lagi untuk melanjutkan, atau batal.',
      spokenText:
          '$warnings Konfirmasi tambahan diperlukan. Katakan ya sekali lagi untuk melanjutkan, atau batal.',
      kind: VoiceResponseKind.confirmation,
      title: 'Konfirmasi tambahan',
      suggestedAction: 'Konfirmasi lagi atau batal',
    );
  }

  String _details(VoiceActionDraft action) {
    if (action.proposed.fields.isEmpty) return action.summary;
    return action.proposed.fields.entries
        .map(
          (entry) =>
              '${_fieldLabel(entry.key)}: ${_displayFieldValue(entry.key, entry.value)}',
        )
        .join('\n');
  }

  String _displayFieldValue(String field, String value) {
    const priceFields = {
      'hargaJual',
      'hargaModal',
      'hargaGrosir',
      'hargaLama',
      'hargaBaru',
    };
    if (priceFields.contains(field)) {
      final amount = int.tryParse(value);
      if (amount != null) return _rupiah(amount);
    }
    if (field == 'selisihHarga') {
      final amount = int.tryParse(value);
      if (amount != null) {
        final sign = amount >= 0 ? '+' : '-';
        return '$sign${_rupiah(amount.abs())}';
      }
    }
    return value;
  }

  String _fieldLabel(String field) {
    return switch (field) {
      'nama' => 'Nama',
      'hargaJual' => 'Harga jual',
      'hargaModal' => 'Harga modal',
      'hargaGrosir' => 'Harga grosir',
      'jenisHarga' => 'Jenis harga',
      'hargaLama' => 'Harga lama',
      'hargaBaru' => 'Harga baru',
      'selisihHarga' => 'Selisih',
      'persentaseHarga' => 'Perubahan',
      'peringatanHarga' => 'Peringatan bisnis',
      'dampakHarga' => 'Dampak',
      'riwayatHarga' => 'Data historis',
      'kategori' => 'Kategori',
      'lacakStok' => 'Lacak stok',
      'stok' => 'Stok awal',
      'stokSebelum' => 'Stok sebelum',
      'jumlahDiminta' => 'Jumlah diucapkan',
      'hasilKonversi' => 'Hasil konversi',
      'stokSesudah' => 'Stok setelah',
      'lacakStokSebelum' => 'Lacak stok sebelum',
      'lacakStokSesudah' => 'Lacak stok setelah',
      'multiplierKemasan' => 'Konversi kemasan',
      'statusStok' => 'Status stok',
      'peringatan' => 'Peringatan',
      'autentikasi' => 'Autentikasi',
      'kedaluwarsa' => 'Berlaku sampai',
      'satuanDasar' => 'Satuan dasar',
      'stokMinimum' => 'Stok minimum',
      'isiPack' => 'Isi pack',
      'isiKarton' => 'Isi karton',
      'produkMirip' => 'Produk mirip',
      _ => field,
    };
  }

  void _finish(VoiceActionDraft action) {
    pendingAction = null;
    _awaitingAdditionalConfirmationActionIds.remove(action.actionId);
    _finalizedActionIds.add(action.actionId);
  }

  Future<void> _record(
    VoiceActionDraft action,
    VoiceActionStatus status, {
    bool confirmed = false,
    bool authenticationSucceeded = false,
    String? errorCode,
  }) async {
    final event = VoiceActionAuditEvent(
      id: '${action.actionId}-${status.name}',
      actionId: action.actionId,
      actionType: action.type,
      source: VoiceActionSource.voice,
      status: status,
      targetEntityType: action.proposed.entityType,
      targetEntityId: action.proposed.entityId,
      beforeSummary: _truncate(action.before?.redactedSummary ?? ''),
      afterSummary: _truncate(action.proposed.redactedSummary),
      confirmed: confirmed,
      authenticationRequired: action.requiresAuthentication,
      authenticationSucceeded: authenticationSucceeded,
      errorCode: errorCode,
      undoStatus: action.isReversible
          ? VoiceUndoStatus.available
          : VoiceUndoStatus.notAvailable,
      commandFingerprint: action.commandFingerprint,
      createdAt: _now(),
    );
    try {
      await _auditStore.record(event);
      SafeDiagnostics.voiceEvent(
        'voice_action_audit_recorded',
        intent: action.type.name,
        status: status.name,
        actionFingerprint: action.commandFingerprint,
      );
    } catch (error, stackTrace) {
      SafeDiagnostics.failure('voice_action_audit_failed', error, stackTrace);
      rethrow;
    }
  }

  String _truncate(String value) {
    const maxLength = 500;
    return value.length <= maxLength ? value : value.substring(0, maxLength);
  }

  String _rupiah(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final remaining = raw.length - index;
      buffer.write(raw[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
}
