class DriverSession {
  const DriverSession({
    required this.token,
    required this.tokenType,
    required this.role,
    this.expiresIn,
    this.expiresAt,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.driverCode,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.availabilityStatus,
    this.driverStatus,
    this.rating,
    this.completedTrips,
  });

  final String token;
  final String tokenType;
  final String role;
  final String? expiresIn;
  final String? expiresAt;
  final String? name;
  final String? username;
  final String? email;
  final String? phone;
  final String? driverCode;
  final String? licenseNumber;
  final String? licenseExpiryDate;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? availabilityStatus;
  final String? driverStatus;
  final double? rating;
  final int? completedTrips;

  factory DriverSession.fromLoginData(Map<String, dynamic> data) {
    final auth = _asMap(data['auth']);
    final user = _asMap(data['user']);
    final profile = _asMap(data['profile']);
    final token = (auth['token'] ?? data['token'] ?? '').toString();

    if (token.isEmpty) {
      throw const FormatException('Auth token was missing from API response.');
    }

    return DriverSession(
      token: token,
      tokenType: (auth['tokenType'] ?? 'Bearer').toString(),
      role: (data['role'] ?? user['role'] ?? 'driver').toString(),
      expiresIn: auth['expiresIn']?.toString(),
      expiresAt: auth['expiresAt']?.toString(),
      name: user['name']?.toString(),
      username: user['username']?.toString(),
      email: user['email']?.toString(),
      phone: user['phone']?.toString(),
      driverCode: profile['driverCode']?.toString(),
      licenseNumber: profile['licenseNumber']?.toString(),
      licenseExpiryDate: profile['licenseExpiryDate']?.toString(),
      addressLine1: profile['addressLine1']?.toString(),
      addressLine2: profile['addressLine2']?.toString(),
      city: profile['city']?.toString(),
      state: profile['state']?.toString(),
      postalCode: profile['postalCode']?.toString(),
      availabilityStatus: profile['availabilityStatus']?.toString(),
      driverStatus: profile['driverStatus']?.toString(),
      rating: _asNullableDouble(profile['rating']),
      completedTrips: _asNullableInt(profile['completedTrips']),
    );
  }

  String get displayName => name == null || name!.trim().isEmpty
      ? 'CargoConnect Driver'
      : name!.trim();

  String get displayUsername => username == null || username!.trim().isEmpty
      ? 'driver'
      : username!.trim();

  bool get isExpired {
    final value = expiresAt;
    if (value == null || value.isEmpty) {
      return false;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return false;
    }

    return parsed.isBefore(DateTime.now().toUtc());
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'CD';
    }
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  static double? _asNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}
