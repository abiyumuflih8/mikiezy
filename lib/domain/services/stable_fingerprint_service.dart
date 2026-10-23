import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class StableFingerprintService {
  const StableFingerprintService();

  Future<String> create(String value) async {
    final hash = await Sha256().hash(utf8.encode(value));
    return hash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
