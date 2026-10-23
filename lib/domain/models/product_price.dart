import '../../models/mikiezy_models.dart';

enum ProductPriceType { retail, wholesale, cost }

extension ProductPriceTypeX on ProductPriceType {
  String get fieldName => switch (this) {
    ProductPriceType.retail => 'retailPrice',
    ProductPriceType.wholesale => 'wholesalePrice',
    ProductPriceType.cost => 'costPrice',
  };

  String get label => switch (this) {
    ProductPriceType.retail => 'harga jual',
    ProductPriceType.wholesale => 'harga grosir',
    ProductPriceType.cost => 'harga modal',
  };

  int valueOf(Product product) => switch (this) {
    ProductPriceType.retail => product.retailPrice,
    ProductPriceType.wholesale => product.wholesalePrice,
    ProductPriceType.cost => product.costPrice,
  };

  Product applyTo(Product product, int value) => switch (this) {
    ProductPriceType.retail => product.copyWith(retailPrice: value),
    ProductPriceType.wholesale => product.copyWith(wholesalePrice: value),
    ProductPriceType.cost => product.copyWith(costPrice: value),
  };
}

enum ProductPriceWarning {
  extremeIncrease,
  extremeDecrease,
  zeroPrice,
  largeNominal,
  costAboveRetail,
  wholesaleAboveRetail,
}

extension ProductPriceWarningX on ProductPriceWarning {
  String message(String productName) => switch (this) {
    ProductPriceWarning.extremeIncrease =>
      'Harga baru naik sangat besar dibanding harga sebelumnya.',
    ProductPriceWarning.extremeDecrease =>
      'Harga baru turun sangat besar dibanding harga sebelumnya.',
    ProductPriceWarning.zeroPrice =>
      'Harga modal $productName akan menjadi nol dan laba berikutnya dapat menjadi estimasi.',
    ProductPriceWarning.largeNominal =>
      'Nominal harga baru sangat besar dan perlu diperiksa kembali.',
    ProductPriceWarning.costAboveRetail =>
      'Harga modal baru lebih tinggi daripada harga jual. Perubahan ini dapat menghasilkan laba negatif.',
    ProductPriceWarning.wholesaleAboveRetail =>
      'Harga grosir baru lebih tinggi daripada harga jual.',
  };
}

enum ProductPriceUpdateRisk { medium, high }
