import '../../models/mikiezy_models.dart';

String normalizeProductName(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

enum ProductValidationCode {
  emptyName,
  invalidName,
  duplicateName,
  emptyCategory,
  invalidCostPrice,
  invalidRetailPrice,
  invalidWholesalePrice,
  invalidStock,
  invalidMinimumStock,
  inconsistentStockTracking,
  invalidPackSize,
  invalidCartonSize,
}

class ProductValidationIssue {
  const ProductValidationIssue(this.code, this.message);

  final ProductValidationCode code;
  final String message;
}

class ProductValidationResult {
  ProductValidationResult(List<ProductValidationIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<ProductValidationIssue> issues;

  bool get isValid => issues.isEmpty;
  String get userMessage => issues.map((issue) => issue.message).join(' ');
}

class ProductValidationException implements Exception {
  const ProductValidationException(this.result);

  final ProductValidationResult result;

  @override
  String toString() => result.userMessage;
}

class ProductValidator {
  const ProductValidator();

  ProductValidationResult validate(
    Product product, {
    List<Product> existingProducts = const [],
    String? excludingProductId,
  }) {
    final issues = <ProductValidationIssue>[];
    final name = product.name.trim();
    if (name.isEmpty) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.emptyName,
          'Nama produk wajib diisi.',
        ),
      );
    } else if (!RegExp(r'[a-zA-Z0-9]').hasMatch(name)) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidName,
          'Nama produk harus memuat huruf atau angka.',
        ),
      );
    }

    final normalizedName = normalizeName(name);
    final hasDuplicate =
        normalizedName.isNotEmpty &&
        existingProducts.any(
          (candidate) =>
              candidate.id != excludingProductId &&
              normalizeName(candidate.name) == normalizedName,
        );
    if (hasDuplicate) {
      issues.add(
        ProductValidationIssue(
          ProductValidationCode.duplicateName,
          'Produk $name sudah ada di katalog.',
        ),
      );
    }

    if (product.category.trim().isEmpty) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.emptyCategory,
          'Kategori produk wajib diisi.',
        ),
      );
    }
    if (product.costPrice < 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidCostPrice,
          'Harga modal tidak boleh negatif.',
        ),
      );
    }
    if (product.retailPrice <= 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidRetailPrice,
          'Harga jual harus lebih dari nol.',
        ),
      );
    }
    if (product.wholesalePrice < 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidWholesalePrice,
          'Harga grosir tidak boleh negatif.',
        ),
      );
    }
    if (product.stockPcs < 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidStock,
          'Stok tidak boleh negatif.',
        ),
      );
    }
    if (product.minStock < 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidMinimumStock,
          'Batas stok minimum tidak boleh negatif.',
        ),
      );
    }
    if (!product.trackStock &&
        (product.stockPcs.abs() > 0.000001 ||
            product.minStock.abs() > 0.000001)) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.inconsistentStockTracking,
          'Produk tanpa pelacakan stok harus memiliki stok dan batas minimum nol.',
        ),
      );
    }
    if (product.packSize <= 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidPackSize,
          'Isi pack harus lebih dari nol.',
        ),
      );
    }
    if (product.cartonSize <= 0) {
      issues.add(
        const ProductValidationIssue(
          ProductValidationCode.invalidCartonSize,
          'Isi karton harus lebih dari nol.',
        ),
      );
    }
    return ProductValidationResult(issues);
  }

  void validateOrThrow(
    Product product, {
    List<Product> existingProducts = const [],
    String? excludingProductId,
  }) {
    final result = validate(
      product,
      existingProducts: existingProducts,
      excludingProductId: excludingProductId,
    );
    if (!result.isValid) throw ProductValidationException(result);
  }

  String normalizeName(String value) {
    return normalizeProductName(value);
  }
}
