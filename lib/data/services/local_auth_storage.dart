import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final localAuthStorageProvider = Provider<LocalAuthStorage>(
  (ref) => const LocalAuthStorage(FlutterSecureStorage()),
);

/// Handles secure storage of authentication secrets.
class LocalAuthStorage {
  const LocalAuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> setPassword(String userId, String password) async {
    await _storage.write(key: _passwordKey(userId), value: password);
  }

  Future<String?> getPassword(String userId) async {
    return _storage.read(key: _passwordKey(userId));
  }

  Future<void> removePassword(String userId) async {
    await _storage.delete(key: _passwordKey(userId));
  }

  String _passwordKey(String userId) => 'password_$userId';
}
