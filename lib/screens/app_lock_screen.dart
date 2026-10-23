import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/security/app_lock_controller.dart';
import '../domain/models/app_lock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.controller});

  final AppLockController controller;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _cooldownTicker;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.controller.isInCooldown) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _pinController
      ..clear()
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPin() async {
    if (_submitting || widget.controller.isInCooldown) return;
    setState(() => _submitting = true);
    final result = await widget.controller.verifyPin(_pinController.text);
    _pinController.clear();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      _focusNode.requestFocus();
    }
  }

  Future<void> _useBiometric() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final result = await widget.controller.unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isSuccess &&
        result.status != AppLockOperationStatus.cancelled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final cooldownSeconds = controller.cooldownRemaining.inSeconds + 1;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MikiezyBrandMark(size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'Mikiezy terkunci',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan PIN untuk membuka data bisnis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      focusNode: _focusNode,
                      enabled: !_submitting && !controller.isInCooldown,
                      obscureText: true,
                      obscuringCharacter: '•',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onChanged: (_) => controller.clearMessage(),
                      onSubmitted: (_) => _submitPin(),
                      decoration: InputDecoration(
                        labelText: 'PIN aplikasi',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        errorText: controller.message,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submitting || controller.isInCooldown
                            ? null
                            : _submitPin,
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: Text(
                          controller.isInCooldown
                              ? 'Coba lagi dalam $cooldownSeconds detik'
                              : 'Buka aplikasi',
                        ),
                      ),
                    ),
                    if (controller.biometricEnabled &&
                        controller.biometricCapability.isAvailable) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _submitting ? null : _useBiometric,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: Text(
                            'Gunakan ${controller.biometricCapability.label}',
                          ),
                        ),
                      ),
                    ],
                    if (controller.initializationError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        controller.initializationError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
