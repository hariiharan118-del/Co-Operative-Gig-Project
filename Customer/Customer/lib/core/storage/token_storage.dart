import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: _accessKey);
    } catch (e) {
      debugPrint('TokenStorage readAccessToken error: $e');
      try {
        await _storage.delete(key: _accessKey);
      } catch (_) {}
      return null;
    }
  }

  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _refreshKey);
    } catch (e) {
      debugPrint('TokenStorage readRefreshToken error: $e');
      try {
        await _storage.delete(key: _refreshKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (e) {
      debugPrint('TokenStorage saveTokens error: $e');
    }
  }

  Future<void> saveAccessToken(String accessToken) async {
    try {
      await _storage.write(key: _accessKey, value: accessToken);
    } catch (e) {
      debugPrint('TokenStorage saveAccessToken error: $e');
    }
  }

  Future<void> saveUserJson(String json) async {
    try {
      await _storage.write(key: _userKey, value: json);
    } catch (e) {
      debugPrint('TokenStorage saveUserJson error: $e');
    }
  }

  Future<String?> readUserJson() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (e) {
      debugPrint('TokenStorage readUserJson error: $e');
      try {
        await _storage.delete(key: _userKey);
      } catch (_) {}
      return null;
    }
  }

  Future<void> clearUser() async {
    try {
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('TokenStorage clearUser error: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('TokenStorage clear error: $e');
    }
  }
}
