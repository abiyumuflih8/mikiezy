import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mikiezy/services/diagnostics/safe_diagnostics.dart';

void main() {
  test('transcript diagnostic contains metadata without raw speech', () {
    const privateTranscript =
        'jual kopi susu dua gelas dua belas ribu dari dompet utama';

    final diagnostic = SafeTranscriptDiagnostic.fromBuffers(
      finalText: privateTranscript,
      partialText: 'lanjutan',
      combinedText: '$privateTranscript lanjutan',
    );
    final rendered = [
      diagnostic.finalCharacters,
      diagnostic.partialCharacters,
      diagnostic.combinedCharacters,
      diagnostic.combinedWords,
      diagnostic.fingerprint,
    ].join(' ');

    expect(diagnostic.finalCharacters, privateTranscript.length);
    expect(diagnostic.partialCharacters, 8);
    expect(diagnostic.combinedWords, greaterThan(5));
    expect(diagnostic.fingerprint, hasLength(8));
    expect(rendered, isNot(contains('kopi')));
    expect(rendered, isNot(contains('dompet')));
    expect(rendered, isNot(contains('dua belas ribu')));
  });

  test('short transcript fingerprint is deterministic and input-sensitive', () {
    final first = SafeDiagnostics.shortFingerprint('transcript a');
    final repeated = SafeDiagnostics.shortFingerprint('transcript a');
    final different = SafeDiagnostics.shortFingerprint('transcript b');

    expect(first, repeated);
    expect(first, isNot(different));
    expect(first, matches(RegExp(r'^[0-9a-f]{8}$')));
  });

  test('debug transcript output never prints raw text', () {
    final messages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = originalDebugPrint);

    SafeDiagnostics.voiceTranscript(
      event: 'test',
      finalText: 'jual kopi rahasia dua belas ribu',
      partialText: 'dompet pribadi',
      combinedText: 'jual kopi rahasia dua belas ribu dompet pribadi',
    );

    final output = messages.join('\n');
    expect(output, contains('transcriptFp='));
    expect(output, isNot(contains('kopi')));
    expect(output, isNot(contains('dua belas ribu')));
    expect(output, isNot(contains('dompet pribadi')));
  });
}
