import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mikiezy_card.dart';
import 'receipt_screen.dart';

class PreviewTransactionScreen extends StatefulWidget {
  const PreviewTransactionScreen({super.key, required this.initialDraft});

  final TransactionDraft initialDraft;

  @override
  State<PreviewTransactionScreen> createState() =>
      _PreviewTransactionScreenState();
}

class _PreviewTransactionScreenState extends State<PreviewTransactionScreen> {
  final formKey = GlobalKey<FormState>();
  late TransactionKind kind;
  late final TextEditingController discountController;
  late final TextEditingController noteController;
  late List<_DraftLineEditor> lineEditors;
  late String selectedCategoryName;
  late String selectedWalletName;
  String? evidencePath;
  String? ocrSource;
  bool saving = false;
  bool requestedInputRefresh = false;
  int nextLineSeed = 1;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    kind = draft.kind;
    lineEditors = _editorsFromDraft(draft);
    discountController = TextEditingController(text: draft.discount.toString());
    selectedCategoryName = draft.categoryName;
    selectedWalletName = draft.walletName;
    noteController = TextEditingController(text: draft.note);
    evidencePath = draft.evidencePath;
    ocrSource = draft.ocrSource;
  }

  @override
  void didUpdateWidget(covariant PreviewTransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDraft == widget.initialDraft) return;
    _applyDraft(widget.initialDraft);
  }

  @override
  void dispose() {
    for (final editor in lineEditors) {
      editor.dispose();
    }
    discountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedInputRefresh) return;
    requestedInputRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(MikiezyScope.of(context).refreshTransactionInputs());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    final amount = _currentAmount();
    final categoryName = _activeCategoryName(state);
    final walletName = _activeWalletName(state);
    final lineWarning = _lineValidationWarning();
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Transaksi')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              MikiezyCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MikiezyStatusPill(
                      label: 'AI PREVIEW',
                      icon: Icons.auto_awesome_rounded,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Miki menangkap:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.initialDraft.rawText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.transactionInputsLoading) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (state.transactionInputsError != null) ...[
                _InlineFeedback(
                  icon: Icons.warning_amber_rounded,
                  message:
                      'Pilihan kategori/dompet belum bisa dimuat. Data lokal akan memakai pilihan terakhir.',
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SegmentedButton<TransactionKind>(
                segments: const [
                  ButtonSegment(
                    value: TransactionKind.sale,
                    label: Text('Jual'),
                  ),
                  ButtonSegment(
                    value: TransactionKind.expense,
                    label: Text('Keluar'),
                  ),
                  ButtonSegment(
                    value: TransactionKind.income,
                    label: Text('Masuk'),
                  ),
                ],
                selected: {kind},
                onSelectionChanged: (value) => _setKind(value.first, state),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppDurations.normal,
                switchInCurve: Curves.easeOutCubic,
                child: _buildLinesSection(),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (kind == TransactionKind.sale)
                TextFormField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Diskon opsional',
                    helperText: 'Biarkan 0 jika tidak ada diskon.',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final parsed = int.tryParse((value ?? '0').trim());
                    if (parsed == null || parsed < 0) {
                      return 'Diskon tidak boleh negatif.';
                    }
                    return null;
                  },
                ),
              if (kind == TransactionKind.sale)
                const SizedBox(height: AppSpacing.sm),
              if (lineWarning != null) ...[
                _InlineFeedback(
                  icon: Icons.error_outline_rounded,
                  message: lineWarning,
                  color: AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              _ChoiceField(
                label: 'Kategori',
                value: categoryName,
                icon: Icons.label_outline_rounded,
                onTap: () => _pickCategory(state),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceField(
                label: 'Dompet',
                value: walletName,
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => _pickWallet(state),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  helperText: 'Opsional, misalnya pelanggan atau nomor faktur.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _attachEvidence,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        evidencePath == null ? 'Upload bukti' : 'Bukti ada',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scanReceipt,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(ocrSource == null ? 'Scan struk' : 'OCR ada'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              MikiezyCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate_outlined,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Total transaksi',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      rupiah(amount),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: saving || lineWarning != null ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(saving ? 'Menyimpan...' : 'Simpan transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_DraftLineEditor> _editorsFromDraft(TransactionDraft draft) {
    nextLineSeed = 1;
    final lines = draft.effectiveLines;
    return [
      for (var index = 0; index < lines.length; index++)
        _DraftLineEditor.fromDraftLine(lines[index], fallbackId: _nextLineId()),
    ];
  }

  String _nextLineId() {
    return 'line-${nextLineSeed++}';
  }

  Widget _buildLinesSection() {
    return Column(
      key: ValueKey('line-section-${lineEditors.length}-$kind'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                kind == TransactionKind.sale
                    ? 'Daftar Barang'
                    : 'Detail Transaksi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('preview-add-line'),
              onPressed: _addLine,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah item'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedSwitcher(
          duration: AppDurations.fast,
          child: Container(
            key: ValueKey('line-total-${_currentAmount()}'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_outlined, size: 18),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: Text(
                    'Total sementara',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  rupiah(_currentAmount()),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (lineEditors.isEmpty)
          MikiezyCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: MikiezyEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Belum ada item',
              message:
                  'Tambahkan minimal satu item sebelum transaksi disimpan.',
              action: FilledButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah item'),
              ),
            ),
          )
        else
          ...lineEditors.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == lineEditors.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: _LineEditorCard(
                key: ValueKey('preview-line-card-${line.id}'),
                index: index,
                line: line,
                showPriceSegment: kind == TransactionKind.sale,
                canDelete: lineEditors.length > 1,
                onChanged: () => setState(() {}),
                onToggle: () => setState(() => line.expanded = !line.expanded),
                onDelete: () => _removeLine(line),
              ),
            );
          }),
      ],
    );
  }

  void _addLine() {
    setState(() {
      lineEditors.add(_DraftLineEditor.empty(_nextLineId()));
    });
  }

  void _removeLine(_DraftLineEditor line) {
    setState(() {
      lineEditors.remove(line);
      line.dispose();
    });
  }

  String? _lineValidationWarning() {
    if (lineEditors.isEmpty) return 'Minimal satu item transaksi wajib diisi.';
    for (var index = 0; index < lineEditors.length; index++) {
      final line = lineEditors[index];
      final label = 'Item ${index + 1}';
      if (line.productController.text.trim().isEmpty) {
        return '$label belum punya nama barang.';
      }
      if (intFromController(line.quantityController) <= 0) {
        return '$label harus punya jumlah lebih dari 0.';
      }
      if (intFromController(line.priceController) <= 0) {
        return '$label harus punya harga satuan lebih dari 0.';
      }
      if (intFromController(line.discountController) < 0) {
        return '$label punya diskon tidak valid.';
      }
    }
    return null;
  }

  int _currentAmount() {
    final subtotal = lineEditors.fold(0, (sum, line) => sum + line.total);
    if (kind != TransactionKind.sale) return subtotal;
    final discount = intFromController(discountController).clamp(0, 999999999);
    return (subtotal - discount).clamp(0, 1 << 31);
  }

  TransactionDraft _draft() {
    final lines = lineEditors.map((line) => line.toDraftLine()).toList();
    final firstLine = lines.isNotEmpty
        ? lines.first
        : const TransactionDraftLine(
            tempId: 'fallback-line-1',
            productName: '',
            quantity: 1,
            unit: SaleUnit.pcs,
            unitPrice: 0,
            segment: PriceSegment.retail,
          );
    return TransactionDraft(
      kind: kind,
      productName: firstLine.productName,
      quantity: firstLine.quantity,
      unit: firstLine.unit,
      unitPrice: firstLine.unitPrice,
      discount: kind == TransactionKind.sale
          ? intFromController(discountController).clamp(0, 999999999)
          : 0,
      categoryName: _activeCategoryName(MikiezyScope.of(context)),
      walletName: _activeWalletName(MikiezyScope.of(context)),
      segment: firstLine.segment,
      note: noteController.text.trim(),
      rawText: widget.initialDraft.rawText,
      lines: lines,
      evidencePath: evidencePath,
      ocrSource: ocrSource,
    );
  }

  void _applyDraft(TransactionDraft draft) {
    kind = draft.kind;
    for (final editor in lineEditors) {
      editor.dispose();
    }
    lineEditors = _editorsFromDraft(draft);
    discountController.text = draft.discount.toString();
    selectedCategoryName = draft.categoryName;
    selectedWalletName = draft.walletName;
    noteController.text = draft.note;
    evidencePath = draft.evidencePath;
    ocrSource = draft.ocrSource;
  }

  void _setKind(TransactionKind value, MikiezyState state) {
    setState(() {
      kind = value;
      final categories = _categoriesFor(state, value);
      if (categories.isNotEmpty &&
          !categories.any((item) => item.name == selectedCategoryName)) {
        selectedCategoryName = categories.first.name;
      }
    });
  }

  List<LedgerCategory> _categoriesFor(
    MikiezyState state, [
    TransactionKind? targetKind,
  ]) {
    final direction = (targetKind ?? kind) == TransactionKind.expense
        ? MoneyDirection.expense
        : MoneyDirection.income;
    return state.categories
        .where((category) => category.direction == direction)
        .toList();
  }

  String _activeCategoryName(MikiezyState state) {
    final categories = _categoriesFor(state);
    if (categories.any((category) => category.name == selectedCategoryName)) {
      return selectedCategoryName;
    }
    if (categories.isNotEmpty) return categories.first.name;
    return kind == TransactionKind.expense ? 'Lain-lain' : 'Penjualan';
  }

  String _activeWalletName(MikiezyState state) {
    if (state.wallets.any((wallet) => wallet.name == selectedWalletName)) {
      return selectedWalletName;
    }
    if (state.wallets.isNotEmpty) return state.wallets.first.name;
    return 'Dompet Utama';
  }

  void _pickCategory(MikiezyState state) {
    final categories = _categoriesFor(state);
    _showChoiceSheet<LedgerCategory>(
      title: 'Pilih kategori',
      items: categories,
      itemLabel: (item) => item.name,
      itemSubtitle: (item) => item.isSystem ? 'Kategori sistem' : 'Custom',
      itemIcon: (item) =>
          item.isSystem ? Icons.label_rounded : Icons.sell_outlined,
      onSelected: (item) => setState(() => selectedCategoryName = item.name),
    );
  }

  void _pickWallet(MikiezyState state) {
    _showChoiceSheet<Wallet>(
      title: 'Pilih dompet',
      items: state.wallets,
      itemLabel: (item) => item.name,
      itemSubtitle: (item) =>
          item.isPrimary ? 'Dompet utama' : rupiah(item.balance),
      itemIcon: (item) =>
          item.isPrimary ? Icons.account_balance_wallet : Icons.wallet_outlined,
      onSelected: (item) => setState(() => selectedWalletName = item.name),
    );
  }

  void _showChoiceSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T item) itemLabel,
    required String Function(T item) itemSubtitle,
    required IconData Function(T item) itemIcon,
    required ValueChanged<T> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada pilihan. Tambahkan dari Setelan.'),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentSoft,
                          child: Icon(
                            itemIcon(item),
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          itemLabel(item),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(itemSubtitle(item)),
                        onTap: () {
                          onSelected(item);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _attachEvidence() {
    setState(
      () => evidencePath =
          'bukti://upload-simulasi-${DateTime.now().millisecondsSinceEpoch}',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload foto bukti masih simulasi untuk MVP.'),
      ),
    );
  }

  void _scanReceipt() {
    setState(() {
      ocrSource =
          'Hasil OCR simulasi: supplier, total, dan item siap dicek ulang.';
      noteController.text = '${noteController.text}\n$ocrSource'.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan struk/faktur akan disambungkan ke OCR kamera.'),
      ),
    );
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa kembali field yang wajib diisi.'),
        ),
      );
      return;
    }
    if (saving) return;
    setState(() => saving = true);
    final state = MikiezyScope.of(context);
    try {
      final tx = await state.saveDraft(_draft());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transaction: tx, transactionId: tx.id),
        ),
        (route) => route.isFirst,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi belum tersimpan. Coba lagi sebentar.'),
        ),
      );
    }
  }
}

class _DraftLineEditor {
  _DraftLineEditor({
    required this.id,
    this.productId,
    required String productName,
    required int quantity,
    required this.unit,
    required int unitPrice,
    required int discount,
    required this.segment,
    this.categoryId,
    this.categoryName,
    this.note = '',
    this.warnings = const [],
    this.needsReview = false,
    this.expanded = false,
  }) : productController = TextEditingController(text: productName),
       quantityController = TextEditingController(text: quantity.toString()),
       priceController = TextEditingController(text: unitPrice.toString()),
       discountController = TextEditingController(text: discount.toString());

  factory _DraftLineEditor.fromDraftLine(
    TransactionDraftLine line, {
    required String fallbackId,
  }) {
    return _DraftLineEditor(
      id: line.tempId.trim().isEmpty ? fallbackId : line.tempId,
      productId: line.productId,
      productName: line.productName,
      quantity: line.quantity,
      unit: line.unit,
      unitPrice: line.unitPrice,
      discount: line.discount,
      segment: line.segment,
      categoryId: line.categoryId,
      categoryName: line.categoryName,
      note: line.note,
      warnings: line.warnings,
      needsReview: line.needsReview,
      expanded: false,
    );
  }

  factory _DraftLineEditor.empty(String id) {
    return _DraftLineEditor(
      id: id,
      productName: '',
      quantity: 1,
      unit: SaleUnit.pcs,
      unitPrice: 0,
      discount: 0,
      segment: PriceSegment.retail,
      needsReview: true,
      expanded: true,
      warnings: const ['Item baru perlu dilengkapi.'],
    );
  }

  final String id;
  final String? productId;
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final TextEditingController discountController;
  SaleUnit unit;
  PriceSegment segment;
  final String? categoryId;
  final String? categoryName;
  final String note;
  final List<String> warnings;
  final bool needsReview;
  bool expanded;

  int get quantity => intFromController(quantityController).clamp(1, 999999);
  int get unitPrice => intFromController(priceController);
  int get discount => intFromController(discountController).clamp(0, 999999999);
  int get total => (quantity * unitPrice - discount).clamp(0, 1 << 31);

  TransactionDraftLine toDraftLine() {
    return TransactionDraftLine(
      tempId: id,
      productId: productId,
      productName: productController.text.trim(),
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      discount: discount,
      segment: segment,
      categoryId: categoryId,
      categoryName: categoryName,
      note: note,
      warnings: warnings,
      needsReview: needsReview,
    );
  }

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    priceController.dispose();
    discountController.dispose();
  }
}

class _LineEditorCard extends StatelessWidget {
  const _LineEditorCard({
    super.key,
    required this.index,
    required this.line,
    required this.showPriceSegment,
    required this.canDelete,
    required this.onChanged,
    required this.onToggle,
    required this.onDelete,
  });

  final int index;
  final _DraftLineEditor line;
  final bool showPriceSegment;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final productName = line.productController.text.trim().isEmpty
        ? 'Item baru'
        : line.productController.text.trim();

    return MikiezyCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('preview-line-toggle-${line.id}'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (line.needsReview || line.warnings.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: AppSpacing.xs),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${line.quantity} ${line.unit.label} x ${rupiah(line.unitPrice)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 112),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      rupiah(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: line.expanded ? 'Tutup detail' : 'Buka detail',
                  onPressed: onToggle,
                  icon: AnimatedRotation(
                    turns: line.expanded ? 0.5 : 0,
                    duration: AppDurations.fast,
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: line.expanded
                ? _LineEditorDetails(
                    key: ValueKey('preview-line-details-${line.id}'),
                    line: line,
                    showPriceSegment: showPriceSegment,
                    canDelete: canDelete,
                    onChanged: onChanged,
                    onDelete: onDelete,
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed-details')),
          ),
        ],
      ),
    );
  }
}

class _LineEditorDetails extends StatelessWidget {
  const _LineEditorDetails({
    super.key,
    required this.line,
    required this.showPriceSegment,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final _DraftLineEditor line;
  final bool showPriceSegment;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (line.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _InlineFeedback(
            icon: Icons.info_outline_rounded,
            message: line.warnings.join(' '),
            color: AppColors.warning,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('preview-line-name-${line.id}'),
          controller: line.productController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nama barang',
            helperText: 'Boleh dikoreksi sebelum disimpan.',
          ),
          onChanged: (_) => onChanged(),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Nama barang wajib diisi.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('preview-line-quantity-${line.id}'),
          controller: line.quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah'),
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse((value ?? '').trim());
            if (parsed == null || parsed <= 0) return 'Minimal 1.';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<SaleUnit>(
          key: ValueKey('preview-line-unit-${line.id}'),
          initialValue: line.unit,
          decoration: const InputDecoration(labelText: 'Satuan'),
          items: SaleUnit.values
              .map(
                (unit) =>
                    DropdownMenuItem(value: unit, child: Text(unit.label)),
              )
              .toList(),
          onChanged: (value) {
            line.unit = value ?? line.unit;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('preview-line-price-${line.id}'),
          controller: line.priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Harga satuan'),
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse((value ?? '').trim());
            if (parsed == null || parsed <= 0) {
              return 'Harga harus lebih dari 0.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('preview-line-discount-${line.id}'),
          controller: line.discountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Diskon item',
            helperText: 'Isi 0 jika tidak ada.',
          ),
          onChanged: (_) => onChanged(),
          validator: (value) {
            final parsed = int.tryParse((value ?? '0').trim());
            if (parsed == null || parsed < 0) return 'Tidak boleh negatif.';
            return null;
          },
        ),
        if (showPriceSegment) ...[
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<PriceSegment>(
            key: ValueKey('preview-line-segment-${line.id}'),
            initialValue: line.segment,
            decoration: const InputDecoration(labelText: 'Kategori harga'),
            items: PriceSegment.values
                .map(
                  (segment) => DropdownMenuItem(
                    value: segment,
                    child: Text(segment.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              line.segment = value ?? line.segment;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    const Expanded(
                      child: Text(
                        'Subtotal',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      rupiah(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              key: ValueKey('preview-line-delete-${line.id}'),
              tooltip: 'Hapus item',
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
