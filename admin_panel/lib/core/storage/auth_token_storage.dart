import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/admin_session.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

class AuthTokenStorage {
  static const String _tokenKey = 'admin_auth_token';
  static const String _tokenTypeKey = 'admin_auth_token_type';
  static const String _roleKey = 'admin_auth_role';
  static const String _expiresAtKey = 'admin_auth_expires_at';
  static const String _expiresInKey = 'admin_auth_expires_in';
  static const String _publicIdKey = 'admin_auth_public_id';
  static const String _nameKey = 'admin_auth_name';
  static const String _usernameKey = 'admin_auth_username';
  static const String _emailKey = 'admin_auth_email';
  static const String _phoneKey = 'admin_auth_phone';
  static const String _statusKey = 'admin_auth_status';
  static const String _lastLoginAtKey = 'admin_auth_last_login_at';

  String? _memoryToken;
  String? _memoryTokenType;
  AdminSession? _memorySession;

  Future<void> saveSession(
    AdminSession session, {
    required bool rememberMe,
  }) async {
    _memoryToken = session.token;
    _memoryTokenType = session.tokenType;
    _memorySession = session;

    final preferences = await SharedPreferences.getInstance();
    if (!rememberMe) {
      await _removePersistedSession(preferences);
      return;
    }

    await preferences.setString(_tokenKey, session.token);
    await preferences.setString(_tokenTypeKey, session.tokenType);
    await preferences.setString(_roleKey, session.role);
    await _setOptionalString(preferences, _expiresAtKey, session.expiresAt);
    await _setOptionalString(preferences, _expiresInKey, session.expiresIn);
    await _setOptionalString(preferences, _publicIdKey, session.publicId);
    await _setOptionalString(preferences, _nameKey, session.name);
    await _setOptionalString(preferences, _usernameKey, session.username);
    await _setOptionalString(preferences, _emailKey, session.email);
    await _setOptionalString(preferences, _phoneKey, session.phone);
    await _setOptionalString(preferences, _statusKey, session.status);
    await _setOptionalString(preferences, _lastLoginAtKey, session.lastLoginAt);
  }

  Future<String?> readToken() async {
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      return _memoryToken;
    }

    final session = await readSession();
    return session?.token;
  }

  Future<String> readTokenType() async {
    if (_memoryTokenType != null && _memoryTokenType!.isNotEmpty) {
      return _memoryTokenType!;
    }

    final session = await readSession();
    return session?.tokenType ?? 'Bearer';
  }

  Future<AdminSession?> readSession() async {
    if (_memorySession != null) {
      if (_memorySession!.isExpired || !_memorySession!.isAuthorizedAdminRole) {
        await clear();
        return null;
      }
      return _memorySession;
    }

    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    final session = AdminSession(
      token: token,
      tokenType: preferences.getString(_tokenTypeKey) ?? 'Bearer',
      role: preferences.getString(_roleKey) ?? 'admin',
      expiresAt: preferences.getString(_expiresAtKey),
      expiresIn: preferences.getString(_expiresInKey),
      publicId: preferences.getString(_publicIdKey),
      name: preferences.getString(_nameKey),
      username: preferences.getString(_usernameKey),
      email: preferences.getString(_emailKey),
      phone: preferences.getString(_phoneKey),
      status: preferences.getString(_statusKey),
      lastLoginAt: preferences.getString(_lastLoginAtKey),
    );

    if (session.isExpired || !session.isAuthorizedAdminRole) {
      await clear();
      return null;
    }

    _memoryToken = session.token;
    _memoryTokenType = session.tokenType;
    _memorySession = session;
    return session;
  }

  Future<void> clear() async {
    _memoryToken = null;
    _memoryTokenType = null;
    _memorySession = null;

    final preferences = await SharedPreferences.getInstance();
    await _removePersistedSession(preferences);
  }

  Future<void> _removePersistedSession(SharedPreferences preferences) async {
    await preferences.remove(_tokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_roleKey);
    await preferences.remove(_expiresAtKey);
    await preferences.remove(_expiresInKey);
    await preferences.remove(_publicIdKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_usernameKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_phoneKey);
    await preferences.remove(_statusKey);
    await preferences.remove(_lastLoginAtKey);
  }

  Future<void> _setOptionalString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      await preferences.remove(key);
      return;
    }

    await preferences.setString(key, value);
  }
}
