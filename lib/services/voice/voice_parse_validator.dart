import 'voice_parse_result.dart';

class VoiceParseValidator {
  const VoiceParseValidator();

  VoiceParseResult validate(VoiceParseResult result) {
    final warnings = <String>[...result.warnings];
    var confidence = 0.55;

    if (result.items.isEmpty) {
      warnings.add('Transcript belum menghasilkan item transaksi.');
      confidence -= 0.2;
    }

    var subtotal = 0;
    var subtotalComplete = true;
    for (final item in result.items) {
      if (item.needsReview) {
        confidence -= 0.08;
        for (final warning in item.warnings) {
          warnings.add('${item.rawText}: $warning');
        }
      }
      final lineTotal = item.computedLineTotal;
      if (lineTotal == null) {
        subtotalComplete = false;
      } else {
        subtotal += lineTotal;
      }
    }

    if (result.totalAmount != null && subtotalComplete && subtotal > 0) {
      final adjustedSubtotal =
          (subtotal - result.discount).clamp(0, 1 << 31).toInt();
      if ((adjustedSubtotal - result.totalAmount!).abs() > 1) {
        warnings.add(
          'Total transcript tidak sama dengan subtotal item (${result.totalAmount} vs $adjustedSubtotal).',
        );
        confidence -= 0.12;
      }
    }

    if (result.walletName == null || result.walletName!.trim().isEmpty) {
      warnings.add(
        'Dompet belum disebutkan atau belum cocok dengan data lokal.',
      );
      confidence -= 0.04;
    }
    if (result.categoryName == null || result.categoryName!.trim().isEmpty) {
      warnings.add('Kategori belum terbaca jelas.');
      confidence -= 0.04;
    }

    final itemAverage = result.items.isEmpty
        ? 0.0
        : result.items
                  .map((item) => item.confidence)
                  .fold<double>(0, (sum, value) => sum + value) /
              result.items.length;
    confidence = ((confidence + itemAverage) / 2).clamp(0, 1).toDouble();

    final needsReview =
        warnings.isNotEmpty || result.items.any((item) => item.needsReview);

    return result.copyWith(
      confidence: confidence,
      warnings: warnings,
      needsReview: needsReview,
      fieldConfidences: {
        ...result.fieldConfidences,
        'items': itemAverage,
        'overall': confidence,
      },
    );
  }
}
