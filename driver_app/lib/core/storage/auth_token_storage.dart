import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/driver_session.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

class AuthTokenStorage {
  static const String _tokenKey = 'driver_auth_token';
  static const String _tokenTypeKey = 'driver_auth_token_type';
  static const String _roleKey = 'driver_auth_role';
  static const String _expiresAtKey = 'driver_auth_expires_at';
  static const String _expiresInKey = 'driver_auth_expires_in';
  static const String _nameKey = 'driver_auth_name';
  static const String _usernameKey = 'driver_auth_username';
  static const String _emailKey = 'driver_auth_email';
  static const String _phoneKey = 'driver_auth_phone';
  static const String _driverCodeKey = 'driver_auth_driver_code';
  static const String _licenseNumberKey = 'driver_auth_license_number';
  static const String _licenseExpiryKey = 'driver_auth_license_expiry';
  static const String _addressLine1Key = 'driver_auth_address_line1';
  static const String _addressLine2Key = 'driver_auth_address_line2';
  static const String _cityKey = 'driver_auth_city';
  static const String _stateKey = 'driver_auth_state';
  static const String _postalCodeKey = 'driver_auth_postal_code';
  static const String _availabilityStatusKey =
      'driver_auth_availability_status';
  static const String _driverStatusKey = 'driver_auth_driver_status';
  static const String _ratingKey = 'driver_auth_rating';
  static const String _completedTripsKey = 'driver_auth_completed_trips';

  DriverSession? _memorySession;

  Future<void> saveSession(DriverSession session) async {
    _memorySession = session;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, session.token);
    await preferences.setString(_tokenTypeKey, session.tokenType);
    await preferences.setString(_roleKey, session.role);
    await _setOptionalString(preferences, _expiresAtKey, session.expiresAt);
    await _setOptionalString(preferences, _expiresInKey, session.expiresIn);
    await _setOptionalString(preferences, _nameKey, session.name);
    await _setOptionalString(preferences, _usernameKey, session.username);
    await _setOptionalString(preferences, _emailKey, session.email);
    await _setOptionalString(preferences, _phoneKey, session.phone);
    await _setOptionalString(preferences, _driverCodeKey, session.driverCode);
    await _setOptionalString(
      preferences,
      _licenseNumberKey,
      session.licenseNumber,
    );
    await _setOptionalString(
      preferences,
      _licenseExpiryKey,
      session.licenseExpiryDate,
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
    await _setOptionalString(
      preferences,
      _availabilityStatusKey,
      session.availabilityStatus,
    );
    await _setOptionalString(
      preferences,
      _driverStatusKey,
      session.driverStatus,
    );

    if (session.rating == null) {
      await preferences.remove(_ratingKey);
    } else {
      await preferences.setDouble(_ratingKey, session.rating!);
    }

    if (session.completedTrips == null) {
      await preferences.remove(_completedTripsKey);
    } else {
      await preferences.setInt(_completedTripsKey, session.completedTrips!);
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

  Future<DriverSession?> readSession() async {
    if (_memorySession != null) {
      if (_memorySession!.isExpired || _memorySession!.role != 'driver') {
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

    final session = DriverSession(
      token: token,
      tokenType: preferences.getString(_tokenTypeKey) ?? 'Bearer',
      role: preferences.getString(_roleKey) ?? 'driver',
      expiresAt: preferences.getString(_expiresAtKey),
      expiresIn: preferences.getString(_expiresInKey),
      name: preferences.getString(_nameKey),
      username: preferences.getString(_usernameKey),
      email: preferences.getString(_emailKey),
      phone: preferences.getString(_phoneKey),
      driverCode: preferences.getString(_driverCodeKey),
      licenseNumber: preferences.getString(_licenseNumberKey),
      licenseExpiryDate: preferences.getString(_licenseExpiryKey),
      addressLine1: preferences.getString(_addressLine1Key),
      addressLine2: preferences.getString(_addressLine2Key),
      city: preferences.getString(_cityKey),
      state: preferences.getString(_stateKey),
      postalCode: preferences.getString(_postalCodeKey),
      availabilityStatus: preferences.getString(_availabilityStatusKey),
      driverStatus: preferences.getString(_driverStatusKey),
      rating: preferences.getDouble(_ratingKey),
      completedTrips: preferences.getInt(_completedTripsKey),
    );

    if (session.isExpired || session.role != 'driver') {
      await clear();
      return null;
    }

    _memorySession = session;
    return _memorySession;
  }

  Future<void> clear() async {
    _memorySession = null;

    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_tokenTypeKey);
    await preferences.remove(_roleKey);
    await preferences.remove(_expiresAtKey);
    await preferences.remove(_expiresInKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_usernameKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_phoneKey);
    await preferences.remove(_driverCodeKey);
    await preferences.remove(_licenseNumberKey);
    await preferences.remove(_licenseExpiryKey);
    await preferences.remove(_addressLine1Key);
    await preferences.remove(_addressLine2Key);
    await preferences.remove(_cityKey);
    await preferences.remove(_stateKey);
    await preferences.remove(_postalCodeKey);
    await preferences.remove(_availabilityStatusKey);
    await preferences.remove(_driverStatusKey);
    await preferences.remove(_ratingKey);
    await preferences.remove(_completedTripsKey);
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
