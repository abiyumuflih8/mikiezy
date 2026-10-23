import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../core/formatters.dart';
import '../domain/services/product_validator.dart';
import '../models/mikiezy_models.dart';
import '../shared/widgets/mikiezy_components.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/mikiezy_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool showDistributorDetails = false;
  String? selectedCategory;
  bool requestedRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (requestedRefresh) return;
    requestedRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(MikiezyScope.of(context).refreshProducts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    return AppShell(
      title: 'Barang',
      currentIndex: 3,
      actions: [
        IconButton(
          tooltip: 'Tambah barang',
          onPressed: () => _showProductSheet(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final categories = state.productCategories;
          final filteredProducts = selectedCategory == null
              ? state.products
              : state.products
                    .where((product) => product.category == selectedCategory)
                    .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              MikiezySectionHeader(
                title: 'Daftar barang',
                subtitle:
                    'Kelompokkan produk berdasarkan kategori agar transaksi lebih cepat.',
                action: TextButton.icon(
                  onPressed: () => _showCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Kategori'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProductCategoryFilter(
                categories: categories,
                selected: selectedCategory,
                onSelected: (value) => setState(() => selectedCategory = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ProductModeCard(
                value: showDistributorDetails,
                onChanged: (value) =>
                    setState(() => showDistributorDetails = value),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.productsLoading && state.products.isEmpty)
                const _ProductsLoadingState()
              else if (state.productsError != null)
                _ProductsNotice(
                  icon: Icons.warning_amber_rounded,
                  title: 'Data barang belum termuat',
                  message: 'Menampilkan cache produk lokal terakhir.',
                  color: AppColors.danger,
                ),
              if (state.productsError != null) const SizedBox(height: 12),
              if (!state.productsLoading &&
                  state.products.isEmpty &&
                  state.productsError == null)
                const _AllProductsEmptyState()
              else if (selectedCategory == null)
                ...categories.expand((category) {
                  final products = state.products
                      .where((product) => product.category == category)
                      .toList();
                  if (products.isEmpty) return <Widget>[];
                  return [
                    _CategoryHeader(category: category, count: products.length),
                    const SizedBox(height: 8),
                    ...products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductTile(
                          product: product,
                          showDistributorDetails: showDistributorDetails,
                          onEdit: () => _showProductSheet(context, product),
                          onDelete: () =>
                              _confirmDeleteProduct(context, product),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ];
                })
              else if (filteredProducts.isEmpty)
                _EmptyCategory(category: selectedCategory!)
              else
                ...filteredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProductTile(
                      product: product,
                      showDistributorDetails: showDistributorDetails,
                      onEdit: () => _showProductSheet(context, product),
                      onDelete: () => _confirmDeleteProduct(context, product),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showProductSheet(BuildContext context, [Product? product]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductForm(product: product),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah kategori barang'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            hintText: 'Contoh: Frozen food',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              final state = MikiezyScope.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              if (name.isNotEmpty) {
                try {
                  await state.addProductCategory(name);
                  if (!mounted) return;
                  setState(() => selectedCategory = name);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Kategori barang berhasil ditambahkan.'),
                    ),
                  );
                } catch (error, stackTrace) {
                  debugPrint(
                    'Gagal menyimpan kategori barang: $error\n$stackTrace',
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Kategori belum tersimpan. Coba lagi.'),
                    ),
                  );
                  return;
                }
              }
              if (!mounted) return;
              navigator.pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
    BuildContext context,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus barang?'),
        content: Text(
          '${product.name} akan disembunyikan dari daftar barang. Riwayat transaksi lama tetap aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await MikiezyScope.of(context).deleteProduct(product.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Barang berhasil dihapus.')));
    } catch (error, stackTrace) {
      debugPrint('Gagal menghapus barang: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang belum bisa dihapus.')),
      );
    }
  }
}

class _ProductCategoryFilter extends StatelessWidget {
  const _ProductCategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});

  final String category;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          category.toUpperCase(),
          style: const TextStyle(
            color: AppColors.faint,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.border)),
        const SizedBox(width: 8),
        Text(
          '$count barang',
          style: const TextStyle(color: AppColors.faint, fontSize: 10),
        ),
      ],
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return MikiezyEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Kategori masih kosong',
      message:
          'Belum ada barang di kategori $category. Tambahkan produk baru dari tombol plus.',
    );
  }
}

class _AllProductsEmptyState extends StatelessWidget {
  const _AllProductsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const MikiezyEmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Belum ada barang',
      message:
          'Tambahkan barang pertama agar input transaksi bisa memilih produk dari database lokal.',
    );
  }
}

class _ProductsLoadingState extends StatelessWidget {
  const _ProductsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const MikiezyCard(
      child: Column(
        children: [
          SizedBox(height: 4),
          CircularProgressIndicator(strokeWidth: 2.4),
          SizedBox(height: 14),
          Text(
            'Memuat barang lokal...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsNotice extends StatelessWidget {
  const _ProductsNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.all(14),
      radius: AppRadius.sm,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.10),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductModeCard extends StatelessWidget {
  const _ProductModeCard({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (checked) => onChanged(checked ?? false),
        title: const Text(
          'Barang distributor',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Aktifkan untuk menampilkan modal, retail, grosir, stok, pack, dan karton.',
          style: TextStyle(color: context.mutedText, fontSize: 12),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.showDistributorDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final bool showDistributorDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Harga',
                    style: TextStyle(color: AppColors.faint, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rupiah(product.retailPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<_ProductAction>(
                tooltip: 'Aksi barang',
                icon: const Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case _ProductAction.edit:
                      onEdit();
                    case _ProductAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ProductAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: _ProductAction.delete,
                    child: Text('Hapus'),
                  ),
                ],
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: AppDurations.normal,
            switchInCurve: Curves.easeOutCubic,
            child: showDistributorDetails
                ? Padding(
                    key: const ValueKey('details'),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MiniStat(
                          label: 'Modal',
                          value: rupiah(product.costPrice),
                        ),
                        _MiniStat(
                          label: 'Retail',
                          value: rupiah(product.retailPrice),
                        ),
                        _MiniStat(
                          label: 'Grosir',
                          value: rupiah(product.wholesalePrice),
                        ),
                        _MiniStat(
                          label: 'Stok',
                          value: product.trackStock
                              ? '${quantityLabel(product.stockPcs)} ${product.baseUnit.label}'
                              : 'Tidak dilacak',
                        ),
                        _MiniStat(
                          label: 'Pack',
                          value: '${product.packSize} pcs',
                        ),
                        _MiniStat(
                          label: 'Karton',
                          value: '${product.cartonSize} pcs',
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('simple')),
          ),
        ],
      ),
    );
  }
}

enum _ProductAction { edit, delete }

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: context.mutedText, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.product});

  final Product? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  static const _productValidator = ProductValidator();
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final cost = TextEditingController(text: '8000');
  final retail = TextEditingController(text: '12000');
  final wholesale = TextEditingController(text: '10000');
  final stock = TextEditingController(text: '24');
  final minStock = TextEditingController(text: '5');
  final pack = TextEditingController(text: '12');
  final carton = TextEditingController(text: '48');
  String selectedCategory = 'Makanan';
  SaleUnit selectedBaseUnit = SaleUnit.pcs;
  bool trackStock = true;
  bool distributor = false;
  bool saving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) return;

    name.text = product.name;
    cost.text = product.costPrice.toString();
    retail.text = product.retailPrice.toString();
    wholesale.text = product.wholesalePrice.toString();
    stock.text = quantityLabel(product.stockPcs);
    minStock.text = quantityLabel(product.minStock);
    pack.text = product.packSize.toString();
    carton.text = product.cartonSize.toString();
    selectedCategory = product.category;
    selectedBaseUnit = product.baseUnit;
    trackStock = product.trackStock;
    distributor =
        product.costPrice > 0 ||
        product.wholesalePrice != product.retailPrice ||
        product.stockPcs > 0 ||
        product.packSize > 1 ||
        product.cartonSize > 1;
  }

  @override
  void dispose() {
    name.dispose();
    cost.dispose();
    retail.dispose();
    wholesale.dispose();
    stock.dispose();
    minStock.dispose();
    pack.dispose();
    carton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    final categories = state.productCategories.isEmpty
        ? const ['Makanan', 'Minuman', 'Lain-lain']
        : state.productCategories;
    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }
    if (!_stockBaseUnits.contains(selectedBaseUnit)) {
      selectedBaseUnit = SaleUnit.pcs;
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit barang' : 'Tambah barang',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama barang',
                  helperText: 'Nama yang akan muncul saat input transaksi.',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Nama barang wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori barang'),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(
                  () => selectedCategory = value ?? selectedCategory,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: retail,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga jual',
                  helperText: 'Harga satu pcs untuk transaksi cepat.',
                ),
                validator: (value) {
                  if (int.tryParse((value ?? '').trim()) == null) {
                    return 'Masukkan angka harga jual.';
                  }
                  if (intFromController(retail) <= 0) {
                    return 'Harga jual harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: distributor,
                onChanged: (value) =>
                    setState(() => distributor = value ?? false),
                title: const Text(
                  'Barang distributor',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (distributor) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: cost,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga modal',
                        ),
                        validator: (value) => _validateWholeNumber(
                          value,
                          label: 'Harga modal',
                          allowZero: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: wholesale,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Harga grosir',
                        ),
                        validator: (value) =>
                            _validateWholeNumber(value, label: 'Harga grosir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: pack,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Isi pack',
                        ),
                        validator: (value) =>
                            _validateWholeNumber(value, label: 'Isi pack'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: carton,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Isi karton',
                        ),
                        validator: (value) =>
                            _validateWholeNumber(value, label: 'Isi karton'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: trackStock,
                onChanged: (value) => setState(() => trackStock = value),
                title: const Text(
                  'Lacak stok produk',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text(
                  'Aktifkan agar stok berkurang otomatis saat produk terjual.',
                ),
              ),
              if (trackStock) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<SaleUnit>(
                  initialValue: selectedBaseUnit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan dasar stok',
                  ),
                  items: _stockBaseUnits
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => selectedBaseUnit = value ?? selectedBaseUnit,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Stok ${selectedBaseUnit.label}',
                        ),
                        validator: _validateStock,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: minStock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Batas stok minimum',
                          helperText:
                              'Ditandai menipis saat stok mencapai batas ini.',
                        ),
                        validator: _validateMinStock,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(saving ? 'Menyimpan...' : 'Simpan barang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (name.text.trim().isEmpty) return;
    final state = MikiezyScope.of(context);
    final product = Product(
      id: widget.product?.id ?? 'new',
      name: name.text.trim(),
      category: selectedCategory,
      costPrice: distributor ? intFromController(cost) : 0,
      retailPrice: intFromController(retail),
      wholesalePrice: distributor
          ? intFromController(wholesale)
          : intFromController(retail),
      packSize: distributor
          ? intFromController(pack).clamp(1, 9999).toInt()
          : 1,
      cartonSize: distributor
          ? intFromController(carton).clamp(1, 9999).toInt()
          : 1,
      stockPcs: trackStock
          ? quantityFromController(stock).clamp(0, 999999).toDouble()
          : 0,
      trackStock: trackStock,
      baseUnit: trackStock ? selectedBaseUnit : SaleUnit.pcs,
      minStock: trackStock
          ? quantityFromController(minStock).clamp(0, 999999).toDouble()
          : 0,
    );
    final validation = _productValidator.validate(
      product,
      existingProducts: state.products,
      excludingProductId: widget.product?.id,
    );
    if (!validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation.userMessage)));
      return;
    }
    setState(() => saving = true);

    try {
      if (isEditing) {
        await state.updateProduct(product);
      } else {
        await state.addProduct(product);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Barang berhasil diperbarui.'
                : 'Barang berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan barang: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang belum tersimpan. Coba lagi.')),
      );
    }
  }

  String? _validateWholeNumber(
    String? value, {
    required String label,
    bool allowZero = false,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label wajib diisi.';
    final parsed = int.tryParse(text);
    if (parsed == null) return '$label harus berupa angka bulat.';
    if (allowZero ? parsed < 0 : parsed <= 0) {
      return allowZero
          ? '$label tidak boleh negatif.'
          : '$label harus lebih dari 0.';
    }
    return null;
  }

  String? _validateStock(String? value) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Stok wajib diisi.';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Stok harus berupa angka.';
    if (parsed < 0) return 'Stok tidak boleh negatif.';
    return null;
  }

  String? _validateMinStock(String? value) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Batas stok minimum wajib diisi.';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Batas stok minimum harus berupa angka.';
    if (parsed < 0) return 'Batas stok minimum tidak boleh negatif.';
    return null;
  }
}

const _stockBaseUnits = <SaleUnit>[
  SaleUnit.pcs,
  SaleUnit.buah,
  SaleUnit.biji,
  SaleUnit.bungkus,
  SaleUnit.potong,
  SaleUnit.porsi,
  SaleUnit.gelas,
  SaleUnit.botol,
  SaleUnit.cup,
  SaleUnit.tusuk,
  SaleUnit.kotak,
  SaleUnit.sachet,
  SaleUnit.kilo,
  SaleUnit.gram,
  SaleUnit.ons,
  SaleUnit.liter,
  SaleUnit.ml,
  SaleUnit.meter,
  SaleUnit.renteng,
  SaleUnit.ikat,
  SaleUnit.ekor,
  SaleUnit.lembar,
  SaleUnit.plastik,
  SaleUnit.mangkok,
  SaleUnit.piring,
];
