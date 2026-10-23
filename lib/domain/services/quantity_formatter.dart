import 'dart:math' as math;

class QuantityFormatter {
  const QuantityFormatter._();

  static const int precision = 9;
  static const double epsilon = 0.000000001;

  static double normalize(num value) {
    if (!value.isFinite) return 0;
    final factor = math.pow(10, precision).toDouble();
    final normalized = (value.toDouble() * factor).round() / factor;
    final nearestInteger = normalized.roundToDouble();
    if ((normalized - nearestInteger).abs() <= epsilon) {
      return nearestInteger;
    }
    return normalized == -0.0 ? 0 : normalized;
  }

  static String label(num value) {
    final normalized = normalize(value);
    if (normalized == normalized.roundToDouble()) {
      return normalized.round().toString();
    }
    return normalized
        .toStringAsFixed(precision)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
