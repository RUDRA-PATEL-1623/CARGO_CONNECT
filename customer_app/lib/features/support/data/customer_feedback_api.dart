import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../shipment/data/customer_shipment_api.dart';

final customerFeedbackApiProvider = Provider<CustomerFeedbackApi>((ref) {
  return CustomerFeedbackApi(dio: ref.watch(dioClientProvider));
});

class CustomerFeedbackApi {
  const CustomerFeedbackApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<CustomerFeedbackList> listFeedback({
    int page = 1,
    int limit = 10,
    int? shipmentId,
    int? rating,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (shipmentId != null) {
      query['shipmentId'] = shipmentId;
    }
    if (rating != null) {
      query['rating'] = rating;
    }

    final data = await _request(
      () => _dio.get<Object?>('/customer/feedback', queryParameters: query),
    );
    return CustomerFeedbackList.fromJson(_asMap(data));
  }

  Future<CustomerFeedbackSubmitResult> submitFeedback(
    CustomerFeedbackRequest request,
  ) async {
    final data = await _request(
      () => _dio.post<Object?>('/customer/feedback', data: request.toJson()),
    );
    return CustomerFeedbackSubmitResult.fromJson(_asMap(data));
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

class CustomerFeedbackRequest {
  const CustomerFeedbackRequest({
    required this.shipmentId,
    required this.rating,
    required this.experienceTags,
    required this.comments,
    required this.wouldRecommend,
  });

  final int shipmentId;
  final int rating;
  final List<String> experienceTags;
  final String comments;
  final bool wouldRecommend;

  Map<String, dynamic> toJson() => {
    'shipmentId': shipmentId,
    'rating': rating,
    'experienceTags': experienceTags,
    'comments': comments.trim(),
    'wouldRecommend': wouldRecommend,
  };
}

class CustomerFeedbackSubmitResult {
  const CustomerFeedbackSubmitResult({
    required this.feedback,
    required this.thankYouTitle,
    required this.thankYouMessage,
  });

  final CustomerFeedback feedback;
  final String thankYouTitle;
  final String thankYouMessage;

  factory CustomerFeedbackSubmitResult.fromJson(Map<String, dynamic> json) {
    final thankYou = _asMap(json['thankYou']);
    return CustomerFeedbackSubmitResult(
      feedback: CustomerFeedback.fromJson(_asMap(json['feedback'])),
      thankYouTitle:
          thankYou['title']?.toString() ?? 'Thank you for your feedback',
      thankYouMessage:
          thankYou['message']?.toString() ??
          'Your delivery experience has been recorded.',
    );
  }
}

class CustomerFeedbackList {
  const CustomerFeedbackList({
    required this.feedback,
    required this.meta,
    this.emptyState,
  });

  final List<CustomerFeedback> feedback;
  final ApiPaginationMeta meta;
  final ApiEmptyState? emptyState;

  factory CustomerFeedbackList.fromJson(Map<String, dynamic> json) {
    final rows = json['feedback'] is List ? json['feedback'] as List : const [];
    return CustomerFeedbackList(
      feedback: rows
          .whereType<Map>()
          .map((row) => CustomerFeedback.fromJson(_asMap(row)))
          .toList(growable: false),
      meta: ApiPaginationMeta.fromJson(_asMap(json['meta'])),
      emptyState: _nullableMap(json['emptyState']) == null
          ? null
          : ApiEmptyState.fromJson(_asMap(json['emptyState'])),
    );
  }
}

class CustomerFeedback {
  const CustomerFeedback({
    required this.id,
    required this.feedbackCode,
    required this.shipmentId,
    required this.rating,
    required this.experienceTags,
    required this.wouldRecommend,
    this.shipmentCode,
    this.comments,
    this.createdAt,
  });

  final int id;
  final String feedbackCode;
  final int shipmentId;
  final String? shipmentCode;
  final int rating;
  final List<String> experienceTags;
  final String? comments;
  final bool wouldRecommend;
  final String? createdAt;

  factory CustomerFeedback.fromJson(Map<String, dynamic> json) {
    final tags = json['experienceTags'] is List
        ? (json['experienceTags'] as List)
              .map((value) => value.toString())
              .toList(growable: false)
        : const <String>[];

    return CustomerFeedback(
      id: _asInt(json['id']),
      feedbackCode: json['feedbackCode']?.toString() ?? '',
      shipmentId: _asInt(json['shipmentId']),
      shipmentCode: json['shipmentCode']?.toString(),
      rating: _asInt(json['rating']),
      experienceTags: tags,
      comments: json['comments']?.toString(),
      wouldRecommend: json['wouldRecommend'] != false,
      createdAt: json['createdAt']?.toString(),
    );
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

Map<String, dynamic>? _nullableMap(Object? value) {
  if (value == null) {
    return null;
  }
  final map = _asMap(value);
  return map.isEmpty ? null : map;
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
