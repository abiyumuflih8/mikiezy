import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../domain/models/app_lock_models.dart';
import '../models/mikiezy_models.dart';
import '../services/report_action_service.dart';
import '../services/navigation/app_navigation_service.dart';
import '../services/security/app_lock_controller.dart';
import '../services/security/app_lock_scope.dart';
import '../services/voice/voice_assistant_manager.dart';
import '../services/voice/voice_command.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/mikiezy_card.dart';
import 'finance_screen.dart';
import 'products_screen.dart';
import 'app_lock_settings_dialog.dart';
import '../services/security/diagnostics_security_gate.dart';
import 'audit_diagnostics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AppShell(
      title: 'Setelan',
      currentIndex: 3,
      showAppBar: false,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final en = state.language == AppLanguage.en;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _SettingsHeader(en: en),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _ProfileCard(state: state, en: en),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _UsageStats(state: state, en: en),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _AiSettingsCard(state: state, en: en),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _MenuSection(
                  title: en ? 'Business Data' : 'Data Usaha',
                  items: [
                    _SettingsMenuItem(
                      icon: Icons.inventory_2_outlined,
                      label: en ? 'Items' : 'Barang',
                      sub: en
                          ? 'Products, prices, stock, packs'
                          : 'Produk, harga, stok, pack',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: RouteSettings(
                            name: AppRouteNames.forTarget(
                              VoiceNavigationTarget.products,
                            ),
                          ),
                          builder: (_) => const ProductsScreen(),
                        ),
                      ),
                    ),
                    _SettingsMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: en ? 'Wallets & Categories' : 'Dompet & Kategori',
                      sub: en
                          ? 'Cash, bank, income and expense categories'
                          : 'Kas, bank, kategori pemasukan dan pengeluaran',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: RouteSettings(
                            name: AppRouteNames.forTarget(
                              VoiceNavigationTarget.wallets,
                            ),
                          ),
                          builder: (_) => const FinanceScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _MenuSection(
                  title: en ? 'Account' : 'Akun',
                  items: [
                    _SettingsMenuItem(
                      icon: Icons.edit_outlined,
                      label: en ? 'Edit Profile' : 'Edit Profil',
                      sub: en
                          ? 'Name, business info, photo'
                          : 'Nama, info usaha, foto',
                      onTap: () => _openProfileSheet(context, state, en),
                    ),
                    _SettingsMenuItem(
                      icon: Icons.notifications_none_rounded,
                      label: en ? 'Notifications' : 'Notifikasi',
                      sub: en
                          ? 'Coming soon: sale alerts and daily reports'
                          : 'Segera hadir: peringatan dan laporan harian',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.shield_outlined,
                      label: en ? 'Security' : 'Keamanan',
                      sub: en
                          ? 'Prototype only: PIN, biometric, sessions'
                          : 'Prototype lokal: PIN, biometrik, sesi login',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _SecurityAndSyncCard(state: state, en: en),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _MenuSection(
                  title: en ? 'App' : 'Aplikasi',
                  items: [
                    _SettingsMenuItem(
                      icon: Icons.file_download_outlined,
                      label: en ? 'Export Data' : 'Export Data',
                      sub: en
                          ? 'Copies CSV now; PDF/files coming soon'
                          : 'CSV disalin; PDF/file segera hadir',
                      onTap: () => ReportActionService.exportDataToClipboard(
                        context,
                        state,
                        en,
                      ),
                    ),
                    _SettingsMenuItem(
                      icon: Icons.star_outline_rounded,
                      label: en ? 'Rate Mikiezy' : 'Beri Rating Mikiezy',
                      sub: en
                          ? 'Coming soon: store listing'
                          : 'Segera hadir: halaman store',
                      color: AppColors.warning,
                    ),
                    _SettingsMenuItem(
                      icon: Icons.help_outline_rounded,
                      label: en ? 'Help & FAQ' : 'Bantuan & FAQ',
                      sub: en
                          ? 'Coming soon: how to use Miki AI'
                          : 'Segera hadir: cara memakai Miki AI',
                    ),
                    _SettingsMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: en ? 'Terms & Privacy' : 'Syarat & Privasi',
                      sub: en
                          ? 'Coming soon: legal information'
                          : 'Segera hadir: informasi legal',
                      color: AppColors.faint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: _InternalDiagnosticsEntry(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _SignOutButton(en: en),
              ),
              const SizedBox(height: 18),
              Text(
                'MIKIEZY v1.0.0 - Built with AI for UMKM',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.faint, fontSize: 10),
              ),
              const SizedBox(height: 92),
            ],
          );
        },
      ),
    );
  }

  void _openProfileSheet(BuildContext context, MikiezyState state, bool en) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProfileEditor(state: state, en: en),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 44),
      decoration: BoxDecoration(
        gradient: context.premiumGradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            en ? 'Settings' : 'Setelan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            en ? 'Account & preferences' : 'Akun dan preferensi',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: .18),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Free Plan',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: context.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  en ? 'BUSINESS INFO' : 'INFO USAHA',
                  style: const TextStyle(
                    color: AppColors.faint,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BusinessInfo(
                        label: en ? 'Business Name' : 'Nama Usaha',
                        value: state.businessName,
                      ),
                    ),
                    Expanded(
                      child: _BusinessInfo(
                        label: en ? 'Category' : 'Kategori',
                        value: state.businessCategory,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BusinessInfo(
                        label: en ? 'Location' : 'Lokasi',
                        value: state.businessLocation,
                      ),
                    ),
                    Expanded(
                      child: _BusinessInfo(
                        label: en ? 'Member Since' : 'Bergabung',
                        value: state.memberSince,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessInfo extends StatelessWidget {
  const _BusinessInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.faint, fontSize: 9),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _UsageStats extends StatelessWidget {
  const _UsageStats({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final items = [
      (en ? 'Voice Recordings' : 'Rekaman Suara', state.voiceRecordings),
      (en ? 'Monthly Tx' : 'Transaksi Bulan Ini', state.monthlyTransactions),
      (en ? 'Days Active' : 'Hari Aktif', state.daysActive),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1117), Color(0xFF1C1E2E)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${items[i].$2}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    items[i].$1.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.07),
              ),
          ],
        ],
      ),
    );
  }
}

class _AiSettingsCard extends StatelessWidget {
  const _AiSettingsCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: en ? 'AI SETTINGS' : 'PENGATURAN AI'),
        MikiezyCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsLine(
                icon: Icons.mic_rounded,
                title: en ? 'Wake Word' : 'Kata Pemanggil',
                sub: en
                    ? 'Say this to activate Miki'
                    : 'Ucapkan untuk mengaktifkan Miki',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Text(
                    '"Miki"',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const _IconBox(icon: Icons.hearing_rounded),
                title: Text(
                  en ? 'Handsfree Wake Word' : 'Wake Word Handsfree',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  en
                      ? 'Listen for "Miki" while the app is open'
                      : 'Dengarkan "Miki" saat aplikasi terbuka',
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
                value: state.handsfreeWakeWordEnabled,
                onChanged: (value) => _toggleHandsfree(context, value),
              ),
              const Divider(height: 1, color: AppColors.border),
              _SilentTimeoutControl(state: state, en: en),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                secondary: const _IconBox(icon: Icons.auto_awesome_rounded),
                title: Text(
                  en ? 'Adaptive Voice Learning' : 'Pembelajaran Voice',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  en
                      ? 'Learn local product and unit names from saved voice transactions'
                      : 'Belajar nama produk dan satuan lokal dari transaksi voice',
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
                value: state.enableVoiceLearning,
                onChanged: state.toggleVoiceLearning,
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _IconBox(icon: Icons.language_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                en ? 'Language' : 'Bahasa',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                en
                                    ? 'App and voice recognition language'
                                    : 'Bahasa aplikasi dan pengenalan suara',
                                style: const TextStyle(
                                  color: AppColors.faint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          en ? 'EN' : 'ID',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LanguageButton(
                            label: 'Indonesia',
                            selected: state.language == AppLanguage.id,
                            onTap: () => state.setLanguage(AppLanguage.id),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LanguageButton(
                            label: 'English',
                            selected: state.language == AppLanguage.en,
                            onTap: () => state.setLanguage(AppLanguage.en),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _IconBox(icon: Icons.tune_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                en ? 'Voice Sensitivity' : 'Sensitivitas Suara',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                en
                                    ? 'Microphone input level'
                                    : 'Level input mikrofon',
                                style: const TextStyle(
                                  color: AppColors.faint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${state.voiceSensitivity}%',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: state.voiceSensitivity.toDouble(),
                      min: 0,
                      max: 100,
                      activeColor: AppColors.accent,
                      onChanged: (value) =>
                          state.setVoiceSensitivity(value.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleHandsfree(BuildContext context, bool value) {
    state.toggleHandsfreeWakeWord(value);
    final manager = VoiceAssistantScope.maybeOf(context);
    if (value) {
      manager?.startForeground();
    } else {
      manager?.stopHandsfree();
    }
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.accentSoft : AppColors.bg,
        foregroundColor: selected ? AppColors.accent : AppColors.muted,
        side: BorderSide(
          color: selected ? const Color(0xFFC7D2FE) : AppColors.border,
        ),
        minimumSize: const Size(0, 40),
      ),
      child: Text(label),
    );
  }
}

class _SecurityAndSyncCard extends StatelessWidget {
  const _SecurityAndSyncCard({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final appLock = AppLockScope.maybeOf(context);
    if (appLock == null) return _buildContent(context, null);
    return AnimatedBuilder(
      animation: appLock,
      builder: (context, _) => _buildContent(context, appLock),
    );
  }

  Widget _buildContent(BuildContext context, AppLockController? appLock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: en ? 'SECURITY & SYNC' : 'KEAMANAN & SINKRONISASI'),
        MikiezyCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  en
                      ? 'Protect sensitive voice data'
                      : 'Lindungi data keuangan dari voice',
                ),
                subtitle: Text(
                  en
                      ? 'Wallet balances stay visible, but are not read aloud'
                      : 'Saldo tetap tampil, tetapi nominal tidak dibacakan',
                ),
                value: state.voiceFinancialPrivacyEnabled,
                onChanged: state.toggleVoiceFinancialPrivacy,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  en ? 'Mask balance on screen' : 'Samarkan saldo di layar',
                ),
                subtitle: Text(
                  en
                      ? 'Applies to wallet balance answers from voice'
                      : 'Berlaku pada jawaban saldo dari perintah voice',
                ),
                value: state.maskVoiceFinancialValues,
                onChanged: state.voiceFinancialPrivacyEnabled
                    ? state.toggleMaskVoiceFinancialValues
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  en
                      ? 'Voice protection while locked'
                      : 'Perlindungan voice saat terkunci',
                ),
                subtitle: Text(
                  en
                      ? 'Sensitive business data is blocked until the app is unlocked'
                      : 'Data bisnis sensitif diblokir sampai aplikasi dibuka',
                ),
                trailing: Icon(
                  appLock?.isPinConfigured == true
                      ? Icons.verified_user_outlined
                      : Icons.lock_open_outlined,
                ),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(en ? 'App PIN' : 'PIN aplikasi'),
                subtitle: Text(
                  appLock?.isPinConfigured == true
                      ? (en
                            ? 'Secure PIN verifier is active'
                            : 'Verifier PIN aman sudah aktif')
                      : (en
                            ? 'Protect the app with a 4-6 digit PIN'
                            : 'Lindungi aplikasi dengan PIN 4-6 digit'),
                ),
                value: appLock?.isPinConfigured ?? false,
                onChanged: appLock == null
                    ? null
                    : (value) => _changePinEnabled(context, appLock, value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  en ? 'Fingerprint / Face Unlock' : 'Sidik jari / scan wajah',
                ),
                subtitle: Text(
                  appLock?.biometricCapability.isAvailable == true
                      ? (en
                            ? 'Uses the device native authentication prompt'
                            : 'Menggunakan autentikasi native perangkat')
                      : (en
                            ? 'Unavailable or not enrolled on this device'
                            : 'Tidak tersedia atau belum didaftarkan di perangkat'),
                ),
                value: appLock?.biometricEnabled ?? false,
                onChanged:
                    appLock != null &&
                        appLock.isPinConfigured &&
                        appLock.biometricCapability.isAvailable
                    ? (value) => _changeBiometric(context, appLock, value)
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: appLock?.isPinConfigured == true,
                title: Text(en ? 'Auto-lock' : 'Kunci otomatis'),
                subtitle: Text(
                  en
                      ? 'After the app stays in background'
                      : 'Setelah aplikasi berada di latar belakang',
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppLockTimeoutOption>(
                    value: appLock?.timeout ?? AppLockTimeoutOption.minute1,
                    onChanged: appLock?.isPinConfigured == true
                        ? (value) {
                            if (value != null) {
                              _changeTimeout(context, appLock!, value);
                            }
                          }
                        : null,
                    items: AppLockTimeoutOption.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: appLock?.isPinConfigured == true,
                title: Text(en ? 'Change PIN' : 'Ganti PIN'),
                trailing: const Icon(Icons.password_rounded),
                onTap: appLock?.isPinConfigured == true
                    ? () => _changePin(context, appLock!)
                    : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: appLock?.isPinConfigured == true,
                title: Text(en ? 'Lock now' : 'Kunci sekarang'),
                trailing: const Icon(Icons.lock_outline_rounded),
                onTap: appLock?.isPinConfigured == true ? appLock!.lock : null,
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(en ? 'Cloud sync' : 'Sinkronisasi cloud'),
                subtitle: Text(
                  en
                      ? 'Sync engine inactive; ${state.queuedSyncCount} local changes queued'
                      : 'Sync engine belum aktif; ${state.queuedSyncCount} perubahan lokal antre',
                ),
                value: state.cloudSyncEnabled,
                onChanged: (value) {
                  state.toggleCloudSync(value);
                  _showPrototypeNotice(context, en);
                },
              ),
              const Divider(),
              _SettingRow(
                label: en ? 'Server' : 'Server',
                value: state.supabaseUrl,
              ),
              const _SettingRow(
                label: 'Web dashboard',
                value: 'Belum dikonfigurasi',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePinEnabled(
    BuildContext context,
    AppLockController controller,
    bool enabled,
  ) async {
    final result = await showAppLockPinDialog(
      context: context,
      controller: controller,
      mode: enabled
          ? AppLockPinDialogMode.create
          : AppLockPinDialogMode.disable,
    );
    if (!context.mounted || result == null) return;
    if (result.isSuccess) {
      state.togglePin(controller.isPinConfigured);
      state.toggleBiometric(controller.biometricEnabled);
    }
    _showResult(context, result);
  }

  Future<void> _changePin(
    BuildContext context,
    AppLockController controller,
  ) async {
    final result = await showAppLockPinDialog(
      context: context,
      controller: controller,
      mode: AppLockPinDialogMode.change,
    );
    if (!context.mounted || result == null) return;
    _showResult(context, result);
  }

  Future<void> _changeBiometric(
    BuildContext context,
    AppLockController controller,
    bool value,
  ) async {
    final result = await controller.setBiometricEnabled(value);
    if (!context.mounted) return;
    if (result.isSuccess) state.toggleBiometric(controller.biometricEnabled);
    _showResult(context, result);
  }

  Future<void> _changeTimeout(
    BuildContext context,
    AppLockController controller,
    AppLockTimeoutOption value,
  ) async {
    final result = await controller.setTimeout(value);
    if (context.mounted) _showResult(context, result);
  }

  void _showResult(BuildContext context, AppLockOperationResult result) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  void _showPrototypeNotice(BuildContext context, bool en) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          en
              ? 'This feature is still in development for the local prototype.'
              : 'Fitur ini masih dalam tahap pengembangan untuk prototype lokal.',
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: title.toUpperCase()),
        MikiezyCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.sub,
    this.onTap,
    this.color = AppColors.accent,
  });

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final action =
        onTap ??
        () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label belum aktif di prototype lokal Mikiezy.'),
          ),
        );
    return InkWell(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.faint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine({
    required this.icon,
    required this.title,
    required this.sub,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: const TextStyle(color: AppColors.faint, fontSize: 11),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SilentTimeoutControl extends StatelessWidget {
  const _SilentTimeoutControl({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  Widget build(BuildContext context) {
    const options = [3, 5, 10, 15];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.timer_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      en ? 'Voice silence pause' : 'Jeda diam voice',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      en
                          ? 'Wait after you stop speaking before review'
                          : 'Tunggu setelah kamu berhenti bicara sebelum review',
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${state.silentTimeoutSeconds}s',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < options.length; index++) ...[
                Expanded(
                  child: _TimeoutButton(
                    seconds: options[index],
                    selected: state.silentTimeoutSeconds == options[index],
                    onTap: () => state.setSilentTimeoutSeconds(options[index]),
                  ),
                ),
                if (index < options.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeoutButton extends StatelessWidget {
  const _TimeoutButton({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          '${seconds}s',
          style: TextStyle(
            color: selected ? Colors.white : AppColors.accent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, this.color = AppColors.accent});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color == AppColors.warning
            ? AppColors.warningSoft
            : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.faint,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.en});

  final bool en;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            en
                ? 'Sign out is not active in the local prototype.'
                : 'Keluar akun belum aktif di prototype lokal.',
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.dangerSoft,
        foregroundColor: AppColors.danger,
        side: const BorderSide(color: Color(0xFFFCA5A5)),
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
      ),
      icon: const Icon(Icons.logout_rounded),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(en ? 'Sign Out' : 'Keluar'),
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    final en = state.language == AppLanguage.en;
    return AppShell(
      title: en ? 'Edit Profile' : 'Edit Profil',
      currentIndex: 3,
      child: _ProfileEditor(state: state, en: en),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor({required this.state, required this.en});

  final MikiezyState state;
  final bool en;

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController owner;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController business;
  late final TextEditingController category;
  late final TextEditingController location;

  @override
  void initState() {
    super.initState();
    owner = TextEditingController(text: widget.state.ownerName);
    email = TextEditingController(text: widget.state.email);
    phone = TextEditingController(text: widget.state.phone);
    business = TextEditingController(text: widget.state.businessName);
    category = TextEditingController(text: widget.state.businessCategory);
    location = TextEditingController(text: widget.state.businessLocation);
  }

  @override
  void dispose() {
    owner.dispose();
    email.dispose();
    phone.dispose();
    business.dispose();
    category.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.en;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              en ? 'Edit Profile' : 'Edit Profil',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: owner,
              decoration: InputDecoration(
                labelText: en ? 'Owner name' : 'Nama pemilik',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              decoration: InputDecoration(labelText: en ? 'Phone' : 'Nomor HP'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: business,
              decoration: InputDecoration(
                labelText: en ? 'Business name' : 'Nama usaha',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: category,
              decoration: InputDecoration(
                labelText: en ? 'Business category' : 'Kategori usaha',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: location,
              decoration: InputDecoration(
                labelText: en ? 'Location' : 'Lokasi',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(en ? 'Save profile' : 'Simpan profil'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    widget.state.updateProfile(
      ownerName: owner.text.trim(),
      email: email.text.trim(),
      phone: phone.text.trim(),
      businessName: business.text.trim(),
      businessCategory: category.text.trim(),
      businessLocation: location.text.trim(),
    );
    Navigator.of(context).pop();
  }
}

class _InternalDiagnosticsEntry extends StatelessWidget {
  const _InternalDiagnosticsEntry();

  @override
  Widget build(BuildContext context) {
    if (!DiagnosticsSecurityGate.kEnableQaAuditDiagnostics) {
      return const SizedBox.shrink();
    }
    final appLock = AppLockScope.maybeOf(context);
    return FutureBuilder<bool>(
      future: const DiagnosticsSecurityGate().isAuthorized(appLockController: appLock),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return _SettingsMenuItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Internal Audit QA Diagnostics',
          sub: 'Inspeksi durabilitas baris VoiceActionAudits',
          color: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(
                name: AppRouteNames.auditDiagnostics,
              ),
              builder: (_) => const AuditDiagnosticsScreen(),
            ),
          ),
        );
      },
    );
  }
}