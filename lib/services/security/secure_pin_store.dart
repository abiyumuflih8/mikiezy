import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/app_lock_models.dart';

abstract interface class SecurePinStore {
  Future<SecureAppLockRecord?> read();

  Future<void> write(SecureAppLockRecord record);

  Future<void> clear();
}

class MemorySecurePinStore implements SecurePinStore {
  SecureAppLockRecord? record;

  @override
  Future<SecureAppLockRecord?> read() async => record;

  @override
  Future<void> write(SecureAppLockRecord value) async {
    record = value;
  }

  @override
  Future<void> clear() async {
    record = null;
  }
}

class FlutterSecurePinStore implements SecurePinStore {
  FlutterSecurePinStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _recordKey = 'mikiezy.app_lock.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<SecureAppLockRecord?> read() async {
    final raw = await _storage.read(key: _recordKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Data app lock tidak valid.');
    }
    return SecureAppLockRecord.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> write(SecureAppLockRecord record) {
    return _storage.write(key: _recordKey, value: jsonEncode(record.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _recordKey);
}
