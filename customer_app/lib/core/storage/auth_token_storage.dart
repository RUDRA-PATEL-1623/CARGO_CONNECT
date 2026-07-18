import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_session.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

class AuthTokenStorage {
  static const String _tokenKey = 'customer_auth_token';
  static const String _tokenTypeKey = 'customer_auth_token_type';
  static const String _roleKey = 'customer_auth_role';
  static const String _expiresAtKey = 'customer_auth_expires_at';
  static const String _expiresInKey = 'customer_auth_expires_in';
  static const String _userNameKey = 'customer_auth_user_name';
  static const String _userEmailKey = 'customer_auth_user_email';
  static const String _userPhoneKey = 'customer_auth_user_phone';
  static const String _customerCodeKey = 'customer_auth_customer_code';
  static const String _accountStatusKey = 'customer_auth_account_status';
  static const String _addressLine1Key = 'customer_auth_address_line1';
  static const String _addressLine2Key = 'customer_auth_address_line2';
  static const String _cityKey = 'customer_auth_city';
  static const String _stateKey = 'customer_auth_state';
  static const String _postalCodeKey = 'customer_auth_postal_code';
  static const String _countryKey = 'customer_auth_country';
  static const String _totalShipmentsKey = 'customer_auth_total_shipments';
  static const String _rememberMeKey = 'customer_auth_remember_me';

  AuthSession? _memorySession;

  Future<void> saveSession(
    AuthSession session, {
    required bool rememberMe,
  }) async {
    _memorySession = session;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberMeKey, rememberMe);

    if (!rememberMe) {
      await _clearPersistentSession(preferences);
      return;
    }

    await preferences.setString(_tokenKey, session.token);
    await preferences.setString(_tokenTypeKey, session.tokenType);
    await preferences.setString(_roleKey, session.role);

    await _setOptionalString(preferences, _expiresAtKey, session.expiresAt);
    await _setOptionalString(preferences, _expiresInKey, session.expiresIn);
    await _setOptionalString(preferences, _userNameKey, session.userName);
    await _setOptionalString(preferences, _userEmailKey, session.userEmail);
    await _setOptionalString(preferences, _userPhoneKey, session.userPhone);
    await _setOptionalString(
      preferences,
      _customerCodeKey,
      session.customerCode,
    );
    await _setOptionalString(
      preferences,
      _accountStatusKey,
      session.accountStatus,
    );
    await _setOptionalString(
      preferences,
      _addressLine1Key,
      session.addressLine1,
    );
    await _setOptionalString(
      preferences,
      _addressLine2Key,
      session.addressLine2,
    );
    await _setOptionalString(preferences, _cityKey, session.city);
    await _setOptionalString(preferences, _stateKey, session.state);
    await _setOptionalString(preferences, _postalCodeKey, session.postalCode);
    await _setOptionalString(preferences, _countryKey, session.country);

    if (session.totalShipments == null) {
      await preferences.remove(_totalShipmentsKey);
    } else {
      await preferences.setInt(_totalShipmentsKey, session.totalShipments!);
    }
  }

  Future<String?> readToken() async {
    final session = await readSession();
    return session?.token;
  }

  Future<String> readTokenType() async {
    final session = await readSession();
    return session?.tokenType ?? 'Bearer';
  }

  Future<AuthSession?> readSession() async {
    if (_memorySession != null) {
      if (_memorySession!.isExpired || _memorySession!.role != 'customer') {
        await clear();
        return null;
      }
      return _memorySession;
    }

    final preferences = await SharedPreferences.getInstance();
    final shouldRemember = preferences.getBool(_rememberMeKey) ?? true;
    if (!shouldRemember) {
      return null;
    }

    final token = preferences.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }

    final session = AuthSession(
      token: token,
      tokenType: preferences.getString(_tokenTypeKey) ?? 'Bearer',
      role: preferences.getString(_roleKey) ?? 'customer',
      expiresAt: preferences.getString(_expiresAtKey),
      expiresIn: preferences.getString(_expiresInKey),
      userName: preferences.getString(_userNameKey),
      userEmail: preferences.getString(_userEmailKey),
      userPhone: preferences.getString(_userPhoneKey),
      customerCode: preferences.getString(_customerCodeKey),
      accountStatus: preferences.getString(_accountStatusKey),
      addressLine1: preferences.getString(_addressLine1Key),
      addressLine2: preferences.getString(_addressLine2Key),
      city: preferences.getString(_cityKey),
      state: preferences.getString(_stateKey),
      postalCode: preferences.getString(_postalCodeKey),
      country: preferences.getString(_countryKey),
      totalShipments: preferences.getInt(_totalShipmentsKey),
    );

    if (session.isExpired || session.role != 'customer') {
      await clear();
      return null;
    }

    _memorySession = session;
    return _memorySession;
  }

  Future<void> saveLocalProfile({
    required String name,
    required String phone,
    required String addressLine1,
  }) async {
    await updateSession((session) {
      return session.copyWith(
        userName: name.trim(),
        userPhone: phone.trim(),
        addressLine1: addressLine1.trim(),
      );
    });
  }

  Future<void> updateSession(
    AuthSession Function(AuthSession session) update,
  ) async {
    final session = await readSession();
    if (session == null) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final shouldRemember = preferences.getBool(_rememberMeKey) ?? true;
    await saveSession(update(session), rememberMe: shouldRemember);
  }

  Future<void> clear() async {
    _memorySession = null;

    final preferences = await SharedPreferences.getInstance();
    await _clearPersistentSession(preferences);
    await preferences.remove(_rememberMeKey);
  }

  Future<void> _clearPersistentSession(SharedPreferences preferences) async {
    await preferences.remove(_tokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_roleKey);
    await preferences.remove(_expiresAtKey);
    await preferences.remove(_expiresInKey);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    await preferences.remove(_userPhoneKey);
    await preferences.remove(_customerCodeKey);
    await preferences.remove(_accountStatusKey);
    await preferences.remove(_addressLine1Key);
    await preferences.remove(_addressLine2Key);
    await preferences.remove(_cityKey);
    await preferences.remove(_stateKey);
    await preferences.remove(_postalCodeKey);
    await preferences.remove(_countryKey);
    await preferences.remove(_totalShipmentsKey);
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
