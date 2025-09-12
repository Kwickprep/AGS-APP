import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // Token methods
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // User methods
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Remember Me methods
  Future<void> saveRememberMe(
    bool rememberMe,
    String email,
    String password,
  ) async {
    await _storage.write(key: _rememberMeKey, value: rememberMe.toString());
    if (rememberMe) {
      await _storage.write(key: _savedEmailKey, value: email);
      await _storage.write(key: _savedPasswordKey, value: password);
    } else {
      await _storage.delete(key: _savedEmailKey);
    }
  }

  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _savedEmailKey);
  }

  Future<String?> getSavedPassword() async {
    return await _storage.read(key: _savedPasswordKey);
  }

  // Session methods
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    final user = await getUser();
    return token != null && user != null;
  }

  Future<void> clearSession() async {
    // Keep remember me settings when clearing session
    final rememberMe = await getRememberMe();
    final savedEmail = await getSavedEmail();
    final savedPassword = await getSavedPassword();

    await _storage.deleteAll();

    // Restore remember me settings
    if (savedEmail != null && savedPassword != null) {
      await saveRememberMe(rememberMe, savedEmail, savedPassword);
    }
  }
}
