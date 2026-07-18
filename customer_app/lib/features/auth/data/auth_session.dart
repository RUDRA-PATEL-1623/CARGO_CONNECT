class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.role,
    this.expiresIn,
    this.expiresAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.customerCode,
    this.accountStatus,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.totalShipments,
  });

  final String token;
  final String tokenType;
  final String role;
  final String? expiresIn;
  final String? expiresAt;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? customerCode;
  final String? accountStatus;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final int? totalShipments;

  factory AuthSession.fromLoginData(Map<String, dynamic> data) {
    final auth = _asMap(data['auth']);
    final user = _asMap(data['user']);
    final profile = _asMap(data['profile']);
    final token = (auth['token'] ?? data['token'] ?? '').toString();

    if (token.isEmpty) {
      throw const FormatException('Auth token was missing from API response.');
    }

    return AuthSession(
      token: token,
      tokenType: (auth['tokenType'] ?? 'Bearer').toString(),
      role: (data['role'] ?? user['role'] ?? 'customer').toString(),
      expiresIn: auth['expiresIn']?.toString(),
      expiresAt: auth['expiresAt']?.toString(),
      userName: user['name']?.toString(),
      userEmail: user['email']?.toString(),
      userPhone: user['phone']?.toString(),
      customerCode: profile['customerCode']?.toString(),
      accountStatus: profile['accountStatus']?.toString(),
      addressLine1: profile['addressLine1']?.toString(),
      addressLine2: profile['addressLine2']?.toString(),
      city: profile['city']?.toString(),
      state: profile['state']?.toString(),
      postalCode: profile['postalCode']?.toString(),
      country: profile['country']?.toString(),
      totalShipments: _asInt(profile['totalShipments']),
    );
  }

  factory AuthSession.fromVerificationData(Map<String, dynamic> data) {
    final user = _asMap(data['user']);
    final profile = _asMap(data['profile']);
    final token = (data['token'] ?? '').toString();

    if (token.isEmpty) {
      throw const FormatException('Auth token was missing from API response.');
    }

    return AuthSession(
      token: token,
      tokenType: 'Bearer',
      role: (user['role'] ?? 'customer').toString(),
      userName: user['name']?.toString(),
      userEmail: user['email']?.toString(),
      userPhone: user['phone']?.toString(),
      customerCode: profile['customerCode']?.toString(),
      accountStatus: profile['accountStatus']?.toString(),
      addressLine1: profile['addressLine1']?.toString(),
      addressLine2: profile['addressLine2']?.toString(),
      city: profile['city']?.toString(),
      state: profile['state']?.toString(),
      postalCode: profile['postalCode']?.toString(),
      country: profile['country']?.toString(),
      totalShipments: _asInt(profile['totalShipments']),
    );
  }

  AuthSession copyWith({
    String? token,
    String? tokenType,
    String? role,
    String? expiresIn,
    String? expiresAt,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? customerCode,
    String? accountStatus,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    int? totalShipments,
  }) {
    return AuthSession(
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
      role: role ?? this.role,
      expiresIn: expiresIn ?? this.expiresIn,
      expiresAt: expiresAt ?? this.expiresAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      customerCode: customerCode ?? this.customerCode,
      accountStatus: accountStatus ?? this.accountStatus,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      totalShipments: totalShipments ?? this.totalShipments,
    );
  }

  String get displayName => userName == null || userName!.trim().isEmpty
      ? 'CargoConnect Customer'
      : userName!.trim();

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
      return 'CC';
    }
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
      country,
    ].where((value) => value != null && value.trim().isNotEmpty);

    return parts.isEmpty ? 'Address not added yet' : parts.join(', ');
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

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
