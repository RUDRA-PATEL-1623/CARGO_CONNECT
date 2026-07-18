class AdminSession {
  const AdminSession({
    required this.token,
    required this.tokenType,
    required this.role,
    this.expiresIn,
    this.expiresAt,
    this.publicId,
    this.name,
    this.username,
    this.email,
    this.phone,
    this.status,
    this.lastLoginAt,
  });

  final String token;
  final String tokenType;
  final String role;
  final String? expiresIn;
  final String? expiresAt;
  final String? publicId;
  final String? name;
  final String? username;
  final String? email;
  final String? phone;
  final String? status;
  final String? lastLoginAt;

  factory AdminSession.fromLoginData(Map<String, dynamic> data) {
    final auth = _asMap(data['auth']);
    final user = _asMap(data['user']);
    final profile = _asMap(data['profile']);
    final token = (auth['token'] ?? data['token'] ?? '').toString();

    if (token.isEmpty) {
      throw const FormatException('Auth token was missing from API response.');
    }

    return AdminSession(
      token: token,
      tokenType: (auth['tokenType'] ?? 'Bearer').toString(),
      role: (data['role'] ?? user['role'] ?? 'admin').toString(),
      expiresIn: auth['expiresIn']?.toString(),
      expiresAt: auth['expiresAt']?.toString(),
      publicId: user['publicId']?.toString(),
      name: (profile['name'] ?? user['name'])?.toString(),
      username: (profile['username'] ?? user['username'])?.toString(),
      email: (profile['email'] ?? user['email'])?.toString(),
      phone: user['phone']?.toString(),
      status: user['status']?.toString(),
      lastLoginAt: user['lastLoginAt']?.toString(),
    );
  }

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

  bool get isAuthorizedAdminRole => role == 'admin' || role == 'dispatcher';

  String get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? 'CargoConnect Admin' : value;
  }

  String get displayEmail {
    final value = email?.trim();
    return value == null || value.isEmpty ? 'admin@cargoconnect.local' : value;
  }

  String get displayPhone {
    final value = phone?.trim();
    return value == null || value.isEmpty ? 'Not provided' : value;
  }

  String get displayRole {
    return switch (role) {
      'admin' => 'Admin',
      'dispatcher' => 'Dispatcher',
      _ => role.isEmpty ? 'Admin' : _titleCase(role),
    };
  }

  String get roleDescription {
    return switch (role) {
      'admin' => 'Operations and finance administrator',
      'dispatcher' => 'Shipment dispatch operator',
      _ => '$displayRole account',
    };
  }

  String get displayLastLogin {
    final formatted = _formatDateTime(lastLoginAt);
    return formatted ?? 'Session active';
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'AD';
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
}

String _titleCase(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String? _formatDateTime(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return null;
  }

  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year, $hour:$minute $period';
}
