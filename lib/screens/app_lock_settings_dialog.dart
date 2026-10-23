import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models/app_lock_models.dart';
import '../services/security/app_lock_controller.dart';

enum AppLockPinDialogMode { create, change, disable }

Future<AppLockOperationResult?> showAppLockPinDialog({
  required BuildContext context,
  required AppLockController controller,
  required AppLockPinDialogMode mode,
}) {
  return showDialog<AppLockOperationResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AppLockPinDialog(controller: controller, mode: mode),
  );
}

class _AppLockPinDialog extends StatefulWidget {
  const _AppLockPinDialog({required this.controller, required this.mode});

  final AppLockController controller;
  final AppLockPinDialogMode mode;

  @override
  State<_AppLockPinDialog> createState() => _AppLockPinDialogState();
}

class _AppLockPinDialogState extends State<_AppLockPinDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _submitting = false;
  String? _error;

  bool get _needsCurrent => widget.mode != AppLockPinDialogMode.create;
  bool get _needsNew => widget.mode != AppLockPinDialogMode.disable;

  @override
  void dispose() {
    for (final controller in [
      _currentController,
      _newController,
      _confirmationController,
    ]) {
      controller
        ..clear()
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = switch (widget.mode) {
      AppLockPinDialogMode.create => await widget.controller.configurePin(
        _newController.text,
        _confirmationController.text,
      ),
      AppLockPinDialogMode.change => await widget.controller.changePin(
        currentPin: _currentController.text,
        newPin: _newController.text,
        confirmation: _confirmationController.text,
      ),
      AppLockPinDialogMode.disable => await widget.controller.disablePin(
        _currentController.text,
      ),
    };
    _currentController.clear();
    _newController.clear();
    _confirmationController.clear();
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      AppLockPinDialogMode.create => 'Aktifkan PIN aplikasi',
      AppLockPinDialogMode.change => 'Ganti PIN aplikasi',
      AppLockPinDialogMode.disable => 'Nonaktifkan PIN aplikasi',
    };
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_needsCurrent)
                _PinField(
                  controller: _currentController,
                  label: 'PIN saat ini',
                  enabled: !_submitting,
                  onChanged: _clearError,
                ),
              if (_needsCurrent && _needsNew) const SizedBox(height: 12),
              if (_needsNew) ...[
                _PinField(
                  controller: _newController,
                  label: 'PIN baru (4-6 digit)',
                  enabled: !_submitting,
                  onChanged: _clearError,
                ),
                const SizedBox(height: 12),
                _PinField(
                  controller: _confirmationController,
                  label: 'Ulangi PIN baru',
                  enabled: !_submitting,
                  onChanged: _clearError,
                  onSubmitted: (_) => _submit(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.mode == AppLockPinDialogMode.disable
                        ? 'Nonaktifkan'
                        : 'Simpan',
                  ),
          ),
        ],
      ),
    );
  }

  void _clearError(String _) {
    if (_error != null) setState(() => _error = null);
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: true,
      obscuringCharacter: '•',
      keyboardType: TextInputType.number,
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(labelText: label),
    );
  }
}
