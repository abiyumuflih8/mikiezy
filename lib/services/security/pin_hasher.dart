import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../domain/models/app_lock_models.dart';

abstract interface class PinHasher {
  Future<PinVerifierData> createVerifier(String pin);

  Future<bool> verify(String pin, PinVerifierData verifier);
}

class Argon2PinHasher implements PinHasher {
  Argon2PinHasher({
    this.memory = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const algorithmName = 'argon2id-v19';

  final int memory;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final Random _random;

  @override
  Future<PinVerifierData> createVerifier(String pin) async {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final verifier = await _derive(
      pin,
      salt,
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
    return PinVerifierData(
      algorithm: algorithmName,
      saltBase64: base64Encode(salt),
      verifierBase64: base64Encode(verifier),
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
  }

  @override
  Future<bool> verify(String pin, PinVerifierData verifier) async {
    if (verifier.algorithm != algorithmName) return false;
    final expected = base64Decode(verifier.verifierBase64);
    final actual = await _derive(
      pin,
      base64Decode(verifier.saltBase64),
      memory: verifier.memory,
      iterations: verifier.iterations,
      parallelism: verifier.parallelism,
      hashLength: verifier.hashLength,
    );
    return _constantTimeEquals(actual, expected);
  }

  Future<List<int>> _derive(
    String pin,
    List<int> salt, {
    required int memory,
    required int iterations,
    required int parallelism,
    required int hashLength,
  }) async {
    final algorithm = Argon2id(
      parallelism: parallelism,
      memory: memory,
      iterations: iterations,
      hashLength: hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return key.extractBytes();
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    var difference = left.length ^ right.length;
    final length = min(left.length, right.length);
    for (var index = 0; index < length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
