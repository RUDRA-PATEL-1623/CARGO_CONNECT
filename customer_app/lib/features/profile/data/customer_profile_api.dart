import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/auth_token_storage.dart';

final customerProfileApiProvider = Provider<CustomerProfileApi>((ref) {
  return CustomerProfileApi(
    dio: ref.watch(dioClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  );
});

class CustomerProfileApi {
  const CustomerProfileApi({
    required Dio dio,
    required AuthTokenStorage tokenStorage,
  }) : _dio = dio,
       _tokenStorage = tokenStorage;

  final Dio _dio;
  final AuthTokenStorage _tokenStorage;

  Future<CustomerProfile> getProfile() async {
    final data = await _request(() => _dio.get<Object?>('/customer/profile'));
    final profile = CustomerProfile.fromJson(_asMap(_asMap(data)['profile']));
    await _syncStoredSession(profile);
    return profile;
  }

  Future<CustomerProfile> updateProfile(
    CustomerProfileUpdateRequest request,
  ) async {
    final data = await _request(
      () => _dio.patch<Object?>('/customer/profile', data: request.toJson()),
    );
    final profile = CustomerProfile.fromJson(_asMap(_asMap(data)['profile']));
    await _syncStoredSession(profile);
    return profile;
  }

  Future<void> _syncStoredSession(CustomerProfile profile) async {
    await _tokenStorage.updateSession((session) {
      return session.copyWith(
        userName: profile.name,
        userEmail: profile.email,
        userPhone: profile.phone,
        customerCode: profile.customerCode,
        accountStatus: profile.accountStatus,
        addressLine1: profile.address.addressLine1,
        addressLine2: profile.address.addressLine2,
        city: profile.address.city,
        state: profile.address.state,
        postalCode: profile.address.postalCode,
        country: profile.address.country,
        totalShipments: profile.stats.totalShipments,
      );
    });
  }

  Future<Object?> _request(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      return ApiResponse.fromJson(response.data).data;
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }
}

class CustomerProfileUpdateRequest {
  const CustomerProfileUpdateRequest({
    required this.name,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  final String name;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'phone': phone.trim(),
    'addressLine1': addressLine1.trim(),
    if (addressLine2?.trim().isNotEmpty == true)
      'addressLine2': addressLine2!.trim(),
    if (city?.trim().isNotEmpty == true) 'city': city!.trim(),
    if (state?.trim().isNotEmpty == true) 'state': state!.trim(),
    if (postalCode?.trim().isNotEmpty == true) 'postalCode': postalCode!.trim(),
    if (country?.trim().isNotEmpty == true) 'country': country!.trim(),
  };
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountStatus,
    required this.address,
    required this.stats,
    this.avatarUrl,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });

  final int id;
  final String customerCode;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String accountStatus;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;
  final CustomerAddress address;
  final CustomerProfileStats stats;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _asInt(json['id']),
      customerCode: json['customerCode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'CargoConnect Customer',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      accountStatus: json['accountStatus']?.toString() ?? 'pending',
      emailVerifiedAt: json['emailVerifiedAt']?.toString(),
      phoneVerifiedAt: json['phoneVerifiedAt']?.toString(),
      address: CustomerAddress.fromJson(_asMap(json['address'])),
      stats: CustomerProfileStats.fromJson(_asMap(json['stats'])),
    );
  }

  String get displayName =>
      name.trim().isEmpty ? 'CargoConnect Customer' : name.trim();

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
}

class CustomerAddress {
  const CustomerAddress({
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      addressLine1: json['addressLine1']?.toString(),
      addressLine2: json['addressLine2']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      country: json['country']?.toString(),
    );
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
}

class CustomerProfileStats {
  const CustomerProfileStats({required this.totalShipments});

  final int totalShipments;

  factory CustomerProfileStats.fromJson(Map<String, dynamic> json) {
    return CustomerProfileStats(totalShipments: _asInt(json['totalShipments']));
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
