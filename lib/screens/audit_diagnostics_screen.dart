import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../data/repositories/mikiezy_repository.dart';
import '../domain/models/voice_action.dart';
import '../services/security/app_lock_controller.dart';
import '../services/security/app_lock_scope.dart';
import '../services/security/diagnostics_security_gate.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mikiezy_card.dart';

/// Privacy-safe, sanitized view model for a single audit event.
/// Strictly excludes raw transcripts, command fingerprints, entity IDs,
/// beforeSummary, afterSummary, PINs, and sensitive business payloads.
@immutable
class SanitizedAuditItem {
  const SanitizedAuditItem({
    required this.sequenceNumber,
    required this.actionType,
    required this.status,
    required this.createdAt,
    required this.isConfirmed,
  });

  final int sequenceNumber;
  final String actionType;
  final String status;
  final DateTime createdAt;
  final bool isConfirmed;

  factory SanitizedAuditItem.fromEvent(VoiceActionAuditEvent event, int sequence) {
    return SanitizedAuditItem(
      sequenceNumber: sequence,
      actionType: event.actionType.name,
      status: event.status.name,
      createdAt: event.createdAt,
      isConfirmed: event.confirmed,
    );
  }
}

/// Aggregated, sanitized summary metrics for internal diagnostics.
@immutable
class SanitizedAuditSummary {
  const SanitizedAuditSummary({
    required this.totalEvents,
    required this.distinctActionCount,
    required this.succeededCount,
    required this.failedCount,
    required this.items,
  });

  final int totalEvents;
  final int distinctActionCount;
  final int succeededCount;
  final int failedCount;
  final List<SanitizedAuditItem> items;

  factory SanitizedAuditSummary.fromEvents(List<VoiceActionAuditEvent> events) {
    final distinctActions = <String>{};
    var succeeded = 0;
    var failed = 0;
    final items = <SanitizedAuditItem>[];

    for (var i = 0; i < events.length; i++) {
      final ev = events[i];
      distinctActions.add(ev.actionId);
      if (ev.status == VoiceActionStatus.succeeded) {
        succeeded++;
      } else if (ev.status == VoiceActionStatus.authenticationFailed ||
          ev.status == VoiceActionStatus.unitRejected ||
          ev.status == VoiceActionStatus.duplicateRejected ||
          ev.status == VoiceActionStatus.stale ||
          ev.status == VoiceActionStatus.blockedLocked) {
        failed++;
      }
      items.add(SanitizedAuditItem.fromEvent(ev, i + 1));
    }

    return SanitizedAuditSummary(
      totalEvents: events.length,
      distinctActionCount: distinctActions.length,
      succeededCount: succeeded,
      failedCount: failed,
      items: List.unmodifiable(items),
    );
  }
}

/// Internal-only, read-only diagnostics screen for inspecting VoiceActionAudits.
/// Enforces three-layer security gate at runtime and fails closed if unauthorized or locked.
class AuditDiagnosticsScreen extends StatefulWidget {
  const AuditDiagnosticsScreen({
    super.key,
    this.appLockController,
    this.repository,
    this.securityGate,
  });

  final AppLockController? appLockController;
  final MikiezyRepository? repository;
  final DiagnosticsSecurityGate? securityGate;

  @override
  State<AuditDiagnosticsScreen> createState() => _AuditDiagnosticsScreenState();
}

class _AuditDiagnosticsScreenState extends State<AuditDiagnosticsScreen> {
  late DiagnosticsSecurityGate _gate;
  DiagnosticsGateStatus? _gateStatus;
  bool _isLoading = true;
  String? _errorMessage;
  SanitizedAuditSummary? _summary;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _gate = widget.securityGate ?? const DiagnosticsSecurityGate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _evaluateAndLoad();
    }
  }

  @override
  void didUpdateWidget(covariant AuditDiagnosticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.appLockController != widget.appLockController ||
        oldWidget.securityGate != widget.securityGate) {
      _gate = widget.securityGate ?? const DiagnosticsSecurityGate();
      _evaluateAndLoad();
    }
  }

  AppLockController? _resolveAppLock(BuildContext context) {
    return widget.appLockController ?? AppLockScope.maybeOf(context);
  }

  MikiezyRepository? _resolveRepository(BuildContext context) {
    if (widget.repository != null) return widget.repository;
    try {
      return MikiezyScope.of(context).repository;
    } catch (_) {
      return null;
    }
  }

  Future<void> _evaluateAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appLock = _resolveAppLock(context);
    final status = await _gate.checkAuthorization(appLockController: appLock);

    if (!mounted) return;

    if (status != DiagnosticsGateStatus.authorized) {
      setState(() {
        _gateStatus = status;
        _summary = null;
        _isLoading = false;
      });
      return;
    }

    final repo = _resolveRepository(context);
    if (repo == null) {
      setState(() {
        _gateStatus = DiagnosticsGateStatus.authorized;
        _errorMessage = 'Repository tidak tersedia.';
        _isLoading = false;
      });
      return;
    }

    try {
      final events = await repo.loadRecentVoiceActionAudits(limit: 50);
      if (!mounted) return;

      // Recheck authorization post-await to ensure no relock or revocation occurred during IO
      final postStatus = await _gate.checkAuthorization(appLockController: appLock);
      if (postStatus != DiagnosticsGateStatus.authorized) {
        setState(() {
          _gateStatus = postStatus;
          _summary = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _gateStatus = postStatus;
        _summary = SanitizedAuditSummary.fromEvents(events);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gateStatus = status;
        _errorMessage = 'Gagal memuat log audit (Akses dibatasi).';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLock = _resolveAppLock(context);

    // If AppLock controller is active, listen to lock state changes to fail closed immediately.
    if (appLock != null) {
      return AnimatedBuilder(
        animation: appLock,
        builder: (context, _) {
          if (!appLock.initialized) {
            return _buildAccessDenied(DiagnosticsGateStatus.uninitializedAppLock);
          }
          if (!appLock.isPinConfigured) {
            return _buildAccessDenied(DiagnosticsGateStatus.pinNotConfigured);
          }
          if (appLock.isLocked) {
            return _buildAccessDenied(DiagnosticsGateStatus.appLocked);
          }
          if (!appLock.hasAuthenticatedSession) {
            return _buildAccessDenied(DiagnosticsGateStatus.unauthenticatedSession);
          }
          return _buildScaffoldContent(context);
        },
      );
    }

    return _buildScaffoldContent(context);
  }

  Widget _buildScaffoldContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Audit QA Diagnostics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _evaluateAndLoad,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildAccessDenied(DiagnosticsGateStatus status) {
    final reason = switch (status) {
      DiagnosticsGateStatus.disabledByCompileTimeFlag =>
        'Fitur diagnostik dinonaktifkan pada build ini (ENABLE_QA_AUDIT_DIAGNOSTICS = false).',
      DiagnosticsGateStatus.unauthorizedPackage =>
        'Akses ditolak: Aplikasi terpasang bukan paket diagnostik khusus internal.',
      DiagnosticsGateStatus.uninitializedAppLock =>
        'Akses ditolak: Sistem keamanan AppLock belum terinisialisasi.',
      DiagnosticsGateStatus.pinNotConfigured =>
        'Akses ditolak: PIN aplikasi belum dikonfigurasi. Harap aktifkan PIN keamanan terlebih dahulu.',
      DiagnosticsGateStatus.appLocked =>
        'Akses ditolak: Aplikasi terkunci. Harap autentikasi PIN sebelum mengakses diagnostik.',
      DiagnosticsGateStatus.unauthenticatedSession =>
        'Akses ditolak: Sesi belum terautentikasi. Harap buka kunci aplikasi dengan PIN terlebih dahulu.',
      DiagnosticsGateStatus.detectionFailed =>
        'Akses ditolak: Gagal mendeteksi identitas paket sistem.',
      DiagnosticsGateStatus.authorized => 'Akses ditolak.',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: MikiezyCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gpp_bad_outlined,
                  size: 48,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Akses Diagnostik Tidak Diizinkan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.faint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gateStatus != DiagnosticsGateStatus.authorized) {
      return _buildAccessDenied(_gateStatus!);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      );
    }

    final summary = _summary;
    if (summary == null || summary.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Belum ada rekaman audit aksi suara di database lokal ini.',
            style: TextStyle(color: AppColors.faint),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildSummaryHeader(summary),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Daftar Baris Audit (Sanitasi / Privasi Terjaga)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final item in summary.items) _buildAuditItemTile(item),
      ],
    );
  }

  Widget _buildSummaryHeader(SanitizedAuditSummary summary) {
    return MikiezyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Metrik Durabilitas Audit (Local DB)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricColumn('Total Event', summary.totalEvents.toString()),
              _metricColumn('Aksi Unik', summary.distinctActionCount.toString()),
              _metricColumn(
                'Berhasil',
                summary.succeededCount.toString(),
                color: AppColors.success,
              ),
              _metricColumn(
                'Gagal',
                summary.failedCount.toString(),
                color: summary.failedCount > 0 ? AppColors.danger : AppColors.faint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.faint),
        ),
      ],
    );
  }

  Widget _buildAuditItemTile(SanitizedAuditItem item) {
    final isSuccess = item.status == 'succeeded';
    final isFailure = item.status == 'authenticationFailed' ||
        item.status == 'unitRejected' ||
        item.status == 'duplicateRejected' ||
        item.status == 'stale' ||
        item.status == 'blockedLocked';
    final statusColor = isSuccess
        ? AppColors.success
        : isFailure
            ? AppColors.danger
            : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: MikiezyCard(
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '#${item.sequenceNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.actionType,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}:${item.createdAt.second.toString().padLeft(2, '0')} • '
                    'Confirmed: ${item.isConfirmed}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.faint,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
