import 'package:flutter/material.dart';

String rupiah(num value) {
  final sign = value < 0 ? '-' : '';
  final raw = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${sign}Rp ${buffer.toString()}';
}

String compactRupiah(num value) {
  final abs = value.abs();
  if (abs >= 1000000) {
    return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
  }
  if (abs >= 1000) {
    return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
  }
  return rupiah(value);
}

String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String timeLabel(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

int intFromController(TextEditingController controller) {
  final text = controller.text.replaceAll(RegExp(r'[^0-9-]'), '');
  return int.tryParse(text) ?? 0;
}
