import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/services/voice/silence_detector.dart';
import 'package:mikiezy/services/voice/wake_word_detector.dart';

void main() {
  test('wake word detector recognizes Miki variants', () {
    const detector = WakeWordDetector();

    expect(detector.containsWakeWord('miki'), isTrue);
    expect(detector.containsWakeWord('hey miki'), isTrue);
    expect(detector.containsWakeWord('oke miki'), isTrue);
    expect(detector.containsWakeWord('tolong miki catat penjualan'), isTrue);
    expect(detector.containsWakeWord('catat penjualan ayam'), isFalse);
  });

  test('wake word detector strips only the wake phrase', () {
    const detector = WakeWordDetector();

    expect(
      detector.stripWakeWord('Miki catat penjualan ayam bakar'),
      'catat penjualan ayam bakar',
    );
    expect(
      detector.stripWakeWord('hey miki, jual nasi goreng'),
      'jual nasi goreng',
    );
  });

  test('silence detector fires after timeout and can be stopped', () async {
    var fired = false;
    final detector = SilenceDetector(timeout: const Duration(milliseconds: 15));
    detector.start(() => fired = true);

    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(fired, isTrue);

    fired = false;
    detector.start(() => fired = true);
    detector.stop();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(fired, isFalse);
  });
}
