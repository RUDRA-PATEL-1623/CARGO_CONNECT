import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';

final driverProfileApiProvider = Provider<DriverProfileApi>((ref) {
  return DriverProfileApi(dio: ref.watch(dioClientProvider));
});

class DriverProfileApi {
  const DriverProfileApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<DriverProfileData> getProfile() async {
    final data = await _get('/driver/profile');
    return DriverProfileData.fromJson(data);
  }

  Future<DriverProfileData> updateAvailability(
    String availabilityStatus,
  ) async {
    final data = await _patch(
      '/driver/availability',
      body: {'availabilityStatus': availabilityStatus},
    );
    return DriverProfileData.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final response = await _dio.get<Object?>(path);
      return ApiResponse.fromJson(response.data).dataAsMap();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.patch<Object?>(path, data: body);
      return ApiResponse.fromJson(response.data).dataAsMap();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }
}

class DriverProfileData {
  const DriverProfileData({required this.user, required this.profile});

  factory DriverProfileData.fromJson(Map<String, dynamic> json) {
    return DriverProfileData(
      user: DriverProfileUser.fromJson(_asMap(json['user'])),
      profile: DriverProfile.fromJson(_asMap(json['profile'])),
    );
  }

  final DriverProfileUser user;
  final DriverProfile profile;
}

class DriverProfileUser {
  const DriverProfileUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.status,
  });

  factory DriverProfileUser.fromJson(Map<String, dynamic> json) {
    return DriverProfileUser(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'CargoConnect Driver',
      username: json['username']?.toString() ?? 'driver',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
    );
  }

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String status;

  String get initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
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
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.driverCode,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.availabilityStatus,
    required this.driverStatus,
    required this.rating,
    required this.completedTrips,
    required this.activeAssignments,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: _toInt(json['id']),
      driverCode: json['driverCode']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? 'Not added',
      licenseExpiryDate: json['licenseExpiryDate']?.toString() ?? '',
      addressLine1: json['addressLine1']?.toString() ?? '',
      addressLine2: json['addressLine2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      availabilityStatus: json['availabilityStatus']?.toString() ?? 'offline',
      driverStatus: json['driverStatus']?.toString() ?? 'active',
      rating: _toDouble(json['rating']) ?? 0,
      completedTrips: _toInt(json['completedTrips']),
      activeAssignments: _toInt(json['activeAssignments']),
    );
  }

  final int id;
  final String driverCode;
  final String licenseNumber;
  final String licenseExpiryDate;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String availabilityStatus;
  final String driverStatus;
  final double rating;
  final int completedTrips;
  final int activeAssignments;

  bool get isAvailable => availabilityStatus == 'available';

  String get statusLabel => _titleCase(driverStatus);

  String get availabilityLabel => _titleCase(availabilityStatus);

  String get addressLabel {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      postalCode,
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Address not added' : parts.join(', ');
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

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

String _titleCase(String value) {
  if (value.trim().isEmpty) {
    return 'Unknown';
  }
  return value
      .split('_')
      .map((word) {
        if (word.isEmpty) {
          return word;
        }
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}
