import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';

final customerShipmentApiProvider = Provider<CustomerShipmentApi>((ref) {
  return CustomerShipmentApi(dio: ref.watch(dioClientProvider));
});

class CustomerShipmentApi {
  const CustomerShipmentApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ShipmentCategory>> listCategories() async {
    final data = await _get('/shipment-categories');
    final rows = data is List ? data : const [];

    return rows
        .whereType<Map>()
        .map((row) => ShipmentCategory.fromJson(_asMap(row)))
        .toList(growable: false);
  }

  Future<CreateShipmentResult> createShipment(
    ShipmentCreateRequest request,
  ) async {
    final data = await _post('/customer/shipments', body: request.toJson());
    return CreateShipmentResult.fromJson(_asMap(data));
  }

  Future<PriceEstimate> calculatePriceEstimate(
    ShipmentEstimateRequest request,
  ) async {
    final data = await _post(
      '/customer/shipments/estimate',
      body: request.toJson(),
    );
    return PriceEstimate.fromJson(_asMap(data));
  }

  Future<ShipmentSummaryData> getShipmentSummary(int shipmentId) async {
    final data = await _get('/customer/shipments/$shipmentId/summary');
    return ShipmentSummaryData.fromJson(_asMap(data));
  }

  Future<CheckoutData> getCheckout(int shipmentId) async {
    final data = await _get('/customer/shipments/$shipmentId/checkout');
    return CheckoutData.fromJson(_asMap(data));
  }

  Future<PaymentConfirmationData> confirmMockPayment({
    required int shipmentId,
    required String paymentMethod,
    required bool acceptTerms,
    String? couponCode,
  }) async {
    final body = <String, dynamic>{
      'paymentMethod': paymentMethod,
      'acceptTerms': acceptTerms,
    };

    final coupon = couponCode?.trim();
    if (coupon != null && coupon.isNotEmpty) {
      body['couponCode'] = coupon;
    }

    final data = await _post(
      '/customer/shipments/$shipmentId/checkout/mock-payment',
      body: body,
    );
    return PaymentConfirmationData.fromJson(_asMap(data));
  }

  Future<InvoicePreviewData> getInvoicePreview(int invoiceId) async {
    final data = await _get('/customer/invoices/$invoiceId');
    return InvoicePreviewData.fromJson(_asMap(data));
  }

  Future<InvoiceDownload> downloadInvoicePdf(int invoiceId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/customer/invoices/$invoiceId/download',
        options: Options(responseType: ResponseType.bytes),
      );

      return InvoiceDownload(
        bytes: response.data ?? const [],
        filename: _filenameFromDisposition(
          response.headers.value('content-disposition'),
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<ShipmentHistoryData> listShipmentHistory({
    String? search,
    String? status,
    String? paymentStatus,
    String? categoryCode,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 10,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};

    void addIfPresent(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        query[key] = normalized;
      }
    }

    addIfPresent('search', search);
    addIfPresent('status', status);
    addIfPresent('paymentStatus', paymentStatus);
    addIfPresent('categoryCode', categoryCode);
    addIfPresent('dateFrom', dateFrom);
    addIfPresent('dateTo', dateTo);

    final data = await _get('/customer/shipments', queryParameters: query);
    return ShipmentHistoryData.fromJson(_asMap(data));
  }

  Future<ShipmentDetailsData> getShipmentDetails(int shipmentId) async {
    final data = await _get('/customer/shipments/$shipmentId');
    return ShipmentDetailsData.fromJson(_asMap(data));
  }

  Future<ShipmentTimelineData> getShipmentTimeline(int shipmentId) async {
    final data = await _get('/customer/shipments/$shipmentId/timeline');
    return ShipmentTimelineData.fromJson(_asMap(data));
  }

  Future<ShipmentTrackingData> getShipmentTracking(int shipmentId) async {
    final data = await _get('/customer/shipments/$shipmentId/tracking');
    return ShipmentTrackingData.fromJson(_asMap(data));
  }

  Future<ShipmentProofListData> listShipmentProofs({
    required int shipmentId,
    String? proofType,
  }) async {
    final query = <String, dynamic>{};
    final normalizedType = proofType?.trim();
    if (normalizedType != null && normalizedType.isNotEmpty) {
      query['proofType'] = normalizedType;
    }

    final data = await _get(
      '/customer/shipments/$shipmentId/proofs',
      queryParameters: query.isEmpty ? null : query,
    );
    return ShipmentProofListData.fromJson(_asMap(data));
  }

  Future<ShipmentProofDetailData> getShipmentProof({
    required int shipmentId,
    required int proofId,
  }) async {
    final data = await _get('/customer/shipments/$shipmentId/proofs/$proofId');
    return ShipmentProofDetailData.fromJson(_asMap(data));
  }

  Future<int> resolveShipmentId(String value) async {
    final parsedId = int.tryParse(value);
    if (parsedId != null && parsedId > 0) {
      return parsedId;
    }

    final searched = await listShipmentHistory(search: value, limit: 1);
    if (searched.shipments.isNotEmpty) {
      return searched.shipments.first.id;
    }

    final latest = await listShipmentHistory(limit: 1);
    if (latest.shipments.isNotEmpty) {
      return latest.shipments.first.id;
    }

    throw const ApiException(
      message: 'No customer shipments are available yet.',
    );
  }

  Future<Object?> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return _readEnvelopeData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Future<Object?> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _readEnvelopeData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    } on FormatException catch (error) {
      throw ApiException(message: error.message);
    }
  }

  Object? _readEnvelopeData(Object? responseData) {
    final envelope = _asMap(responseData);
    if (envelope.isEmpty) {
      throw const FormatException('Empty API response.');
    }

    if (envelope['success'] == false) {
      throw ApiException.fromResponseData(envelope);
    }

    return envelope['data'];
  }

  String _filenameFromDisposition(String? value) {
    if (value == null || value.isEmpty) {
      return 'CargoConnect-invoice.pdf';
    }

    final match = RegExp(r'filename="?([^"]+)"?').firstMatch(value);
    return match?.group(1) ?? 'CargoConnect-invoice.pdf';
  }
}

class ShipmentCreateRequest {
  const ShipmentCreateRequest({
    required this.categoryCode,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.packageType,
    required this.packageWeightKg,
    required this.vehiclePreference,
    required this.pickupDateTime,
    required this.receiverName,
    required this.receiverPhone,
    required this.isFragile,
    this.dimensions,
    this.deliveryNotes,
    this.estimatedDistanceKm,
  });

  final String categoryCode;
  final String pickupAddress;
  final String deliveryAddress;
  final String packageType;
  final double packageWeightKg;
  final String vehiclePreference;
  final DateTime pickupDateTime;
  final String receiverName;
  final String receiverPhone;
  final bool isFragile;
  final ShipmentDimensions? dimensions;
  final String? deliveryNotes;
  final double? estimatedDistanceKm;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'categoryCode': categoryCode,
      'pickupAddress': pickupAddress.trim(),
      'deliveryAddress': deliveryAddress.trim(),
      'packageType': packageType.trim(),
      'packageWeightKg': packageWeightKg,
      'vehiclePreference': vehiclePreference,
      'pickupDateTime': pickupDateTime.toIso8601String(),
      'receiverName': receiverName.trim(),
      'receiverPhone': receiverPhone.trim(),
      'isFragile': isFragile,
    };

    if (estimatedDistanceKm != null) {
      body['estimatedDistanceKm'] = estimatedDistanceKm;
    }

    final notes = deliveryNotes?.trim();
    if (notes != null && notes.isNotEmpty) {
      body['deliveryNotes'] = notes;
    }

    if (dimensions != null) {
      body['dimensions'] = dimensions!.toJson();
    }

    return body;
  }
}

class ShipmentEstimateRequest {
  const ShipmentEstimateRequest({
    required this.categoryCode,
    required this.packageWeightKg,
    this.isFragile = false,
    this.estimatedDistanceKm,
  });

  final String categoryCode;
  final double packageWeightKg;
  final bool isFragile;
  final double? estimatedDistanceKm;

  Map<String, dynamic> toJson() => {
    'categoryCode': categoryCode,
    'packageWeightKg': packageWeightKg,
    'isFragile': isFragile,
    if (estimatedDistanceKm != null) 'estimatedDistanceKm': estimatedDistanceKm,
  };
}

class ShipmentDimensions {
  const ShipmentDimensions({
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
  });

  final double lengthCm;
  final double widthCm;
  final double heightCm;

  Map<String, dynamic> toJson() => {
    'lengthCm': lengthCm,
    'widthCm': widthCm,
    'heightCm': heightCm,
  };
}

class ShipmentCategory {
  const ShipmentCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.vehicleSuggestion,
    required this.iconKey,
    required this.basePrice,
    required this.pricePerKm,
    this.maxWeightKg,
  });

  final int id;
  final String code;
  final String name;
  final String description;
  final String vehicleSuggestion;
  final String iconKey;
  final double basePrice;
  final double pricePerKm;
  final double? maxWeightKg;

  factory ShipmentCategory.fromJson(Map<String, dynamic> json) {
    return ShipmentCategory(
      id: _asInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Shipment',
      description: json['description']?.toString() ?? '',
      vehicleSuggestion: json['vehicleSuggestion']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? '',
      basePrice: _asDouble(json['basePrice']),
      pricePerKm: _asDouble(json['pricePerKm']),
      maxWeightKg: _asNullableDouble(json['maxWeightKg']),
    );
  }
}

class CreateShipmentResult {
  const CreateShipmentResult({
    required this.shipment,
    required this.priceEstimate,
  });

  final CustomerShipment shipment;
  final PriceEstimate priceEstimate;

  factory CreateShipmentResult.fromJson(Map<String, dynamic> json) {
    return CreateShipmentResult(
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      priceEstimate: PriceEstimate.fromJson(_asMap(json['priceEstimate'])),
    );
  }
}

class ShipmentSummaryData {
  const ShipmentSummaryData({
    required this.shipment,
    required this.priceEstimate,
    this.payment,
    this.nextAction,
  });

  final CustomerShipment shipment;
  final PriceEstimate priceEstimate;
  final PaymentRecord? payment;
  final String? nextAction;

  factory ShipmentSummaryData.fromJson(Map<String, dynamic> json) {
    return ShipmentSummaryData(
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      priceEstimate: PriceEstimate.fromJson(_asMap(json['priceEstimate'])),
      payment: _nullableMap(json['payment']) == null
          ? null
          : PaymentRecord.fromJson(_asMap(json['payment'])),
      nextAction: json['nextAction']?.toString(),
    );
  }
}

class CheckoutData {
  const CheckoutData({
    required this.shipment,
    required this.priceEstimate,
    required this.paymentMethods,
    required this.termsRequired,
    this.payment,
    this.invoice,
  });

  final CustomerShipment shipment;
  final PriceEstimate priceEstimate;
  final List<String> paymentMethods;
  final bool termsRequired;
  final PaymentRecord? payment;
  final InvoiceRecord? invoice;

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    final methods = json['paymentMethods'] is List
        ? (json['paymentMethods'] as List)
              .map((value) => value.toString())
              .toList(growable: false)
        : const <String>[];

    return CheckoutData(
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      priceEstimate: PriceEstimate.fromJson(_asMap(json['priceEstimate'])),
      paymentMethods: methods,
      termsRequired: json['termsRequired'] != false,
      payment: _nullableMap(json['payment']) == null
          ? null
          : PaymentRecord.fromJson(_asMap(json['payment'])),
      invoice: _nullableMap(json['invoice']) == null
          ? null
          : InvoiceRecord.fromJson(_asMap(json['invoice'])),
    );
  }
}

class PaymentConfirmationData {
  const PaymentConfirmationData({
    required this.bookingId,
    required this.shipment,
    required this.payment,
    required this.invoice,
    required this.status,
    required this.message,
  });

  final String bookingId;
  final CustomerShipment shipment;
  final PaymentRecord payment;
  final InvoiceRecord invoice;
  final String status;
  final String message;

  factory PaymentConfirmationData.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmationData(
      bookingId: json['bookingId']?.toString() ?? '',
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      payment: PaymentRecord.fromJson(_asMap(json['payment'])),
      invoice: InvoiceRecord.fromJson(_asMap(json['invoice'])),
      status: json['status']?.toString() ?? 'pending',
      message: json['message']?.toString() ?? '',
    );
  }
}

class InvoicePreviewData {
  const InvoicePreviewData({
    required this.company,
    required this.invoice,
    required this.shipment,
    this.payment,
  });

  final CompanyInfo company;
  final InvoiceRecord invoice;
  final CustomerShipment shipment;
  final PaymentRecord? payment;

  factory InvoicePreviewData.fromJson(Map<String, dynamic> json) {
    return InvoicePreviewData(
      company: CompanyInfo.fromJson(_asMap(json['company'])),
      invoice: InvoiceRecord.fromJson(_asMap(json['invoice'])),
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      payment: _nullableMap(json['payment']) == null
          ? null
          : PaymentRecord.fromJson(_asMap(json['payment'])),
    );
  }
}

class CompanyInfo {
  const CompanyInfo({
    required this.name,
    required this.email,
    required this.address,
  });

  final String name;
  final String email;
  final String address;

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name']?.toString() ?? 'CargoConnect',
      email: json['email']?.toString() ?? 'billing@cargoconnect.local',
      address: json['address']?.toString() ?? 'CargoConnect Logistics HQ',
    );
  }
}

class CustomerShipment {
  const CustomerShipment({
    required this.id,
    required this.shipmentCode,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.packageType,
    required this.packageWeightKg,
    required this.vehiclePreference,
    required this.isFragile,
    required this.pickupDateTime,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.estimatedPrice,
    required this.shipmentStatus,
    required this.paymentStatus,
    this.packageLengthCm,
    this.packageWidthCm,
    this.packageHeightCm,
    this.deliveryNotes,
    this.categoryCode,
    this.categoryName,
    this.latestPaymentCode,
    this.invoiceNumber,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  final int id;
  final String shipmentCode;
  final String pickupAddress;
  final String deliveryAddress;
  final String receiverName;
  final String receiverPhone;
  final String packageType;
  final double packageWeightKg;
  final double? packageLengthCm;
  final double? packageWidthCm;
  final double? packageHeightCm;
  final String vehiclePreference;
  final bool isFragile;
  final String? deliveryNotes;
  final String pickupDateTime;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final double estimatedPrice;
  final String shipmentStatus;
  final String paymentStatus;
  final String? categoryCode;
  final String? categoryName;
  final String? latestPaymentCode;
  final String? invoiceNumber;
  final String? createdAt;
  final String? updatedAt;
  final String? completedAt;

  factory CustomerShipment.fromJson(Map<String, dynamic> json) {
    return CustomerShipment(
      id: _asInt(json['id']),
      shipmentCode: json['shipmentCode']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString() ?? '',
      packageType: json['packageType']?.toString() ?? '',
      packageWeightKg: _asDouble(json['packageWeightKg']),
      packageLengthCm: _asNullableDouble(json['packageLengthCm']),
      packageWidthCm: _asNullableDouble(json['packageWidthCm']),
      packageHeightCm: _asNullableDouble(json['packageHeightCm']),
      vehiclePreference: json['vehiclePreference']?.toString() ?? '',
      isFragile: json['isFragile'] == true,
      deliveryNotes: json['deliveryNotes']?.toString(),
      pickupDateTime: json['pickupDateTime']?.toString() ?? '',
      estimatedDistanceKm: _asDouble(json['estimatedDistanceKm']),
      estimatedDurationMinutes: _asInt(json['estimatedDurationMinutes']),
      estimatedPrice: _asDouble(json['estimatedPrice']),
      shipmentStatus: json['shipmentStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      categoryCode: json['categoryCode']?.toString(),
      categoryName: json['categoryName']?.toString(),
      latestPaymentCode: json['latestPaymentCode']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
    );
  }
}

class PriceEstimate {
  const PriceEstimate({
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.currency,
    required this.breakdown,
  });

  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;
  final String currency;
  final PriceBreakdownData breakdown;

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    return PriceEstimate(
      estimatedDistanceKm: _asDouble(json['estimatedDistanceKm']),
      estimatedDurationMinutes: _asInt(json['estimatedDurationMinutes']),
      currency: json['currency']?.toString() ?? 'INR',
      breakdown: PriceBreakdownData.fromJson(_asMap(json['breakdown'])),
    );
  }
}

class PriceBreakdownData {
  const PriceBreakdownData({
    required this.basePrice,
    required this.distanceCharge,
    required this.weightSurcharge,
    required this.fragileCharge,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.feeAmount,
    required this.taxAmount,
    required this.totalAmount,
  });

  final double basePrice;
  final double distanceCharge;
  final double weightSurcharge;
  final double fragileCharge;
  final double subtotalAmount;
  final double discountAmount;
  final double feeAmount;
  final double taxAmount;
  final double totalAmount;

  double get handlingAmount => weightSurcharge + fragileCharge;

  factory PriceBreakdownData.fromJson(Map<String, dynamic> json) {
    return PriceBreakdownData(
      basePrice: _asDouble(json['basePrice']),
      distanceCharge: _asDouble(json['distanceCharge']),
      weightSurcharge: _asDouble(json['weightSurcharge']),
      fragileCharge: _asDouble(json['fragileCharge']),
      subtotalAmount: _asDouble(json['subtotalAmount']),
      discountAmount: _asDouble(json['discountAmount']),
      feeAmount: _asDouble(json['feeAmount']),
      taxAmount: _asDouble(json['taxAmount']),
      totalAmount: _asDouble(json['totalAmount']),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.paymentCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.feeAmount,
    required this.totalAmount,
    this.transactionReference,
    this.paidAt,
  });

  final int id;
  final String paymentCode;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotalAmount;
  final double discountAmount;
  final double taxAmount;
  final double feeAmount;
  final double totalAmount;
  final String? transactionReference;
  final String? paidAt;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: _asInt(json['id']),
      paymentCode: json['paymentCode']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      subtotalAmount: _asDouble(json['subtotalAmount']),
      discountAmount: _asDouble(json['discountAmount']),
      taxAmount: _asDouble(json['taxAmount']),
      feeAmount: _asDouble(json['feeAmount']),
      totalAmount: _asDouble(json['totalAmount']),
      transactionReference: json['transactionReference']?.toString(),
      paidAt: json['paidAt']?.toString(),
    );
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    required this.shipmentId,
    required this.paymentStatus,
    required this.billingName,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    this.paymentId,
    this.billingEmail,
    this.billingPhone,
    this.billingAddress,
    this.issuedAt,
    this.downloadUrl,
  });

  final int id;
  final String invoiceNumber;
  final int shipmentId;
  final int? paymentId;
  final String paymentStatus;
  final String billingName;
  final String? billingEmail;
  final String? billingPhone;
  final String? billingAddress;
  final double subtotalAmount;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final String? issuedAt;
  final String? downloadUrl;

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      id: _asInt(json['id']),
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      shipmentId: _asInt(json['shipmentId']),
      paymentId: _asNullableInt(json['paymentId']),
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      billingName: json['billingName']?.toString() ?? '',
      billingEmail: json['billingEmail']?.toString(),
      billingPhone: json['billingPhone']?.toString(),
      billingAddress: json['billingAddress']?.toString(),
      subtotalAmount: _asDouble(json['subtotalAmount']),
      discountAmount: _asDouble(json['discountAmount']),
      taxAmount: _asDouble(json['taxAmount']),
      totalAmount: _asDouble(json['totalAmount']),
      issuedAt: json['issuedAt']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
    );
  }
}

class InvoiceDownload {
  const InvoiceDownload({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

class ShipmentHistoryData {
  const ShipmentHistoryData({
    required this.shipments,
    required this.meta,
    this.emptyState,
  });

  final List<CustomerShipment> shipments;
  final ApiPaginationMeta meta;
  final ApiEmptyState? emptyState;

  factory ShipmentHistoryData.fromJson(Map<String, dynamic> json) {
    final rows = json['shipments'] is List
        ? json['shipments'] as List
        : const [];

    return ShipmentHistoryData(
      shipments: rows
          .whereType<Map>()
          .map((row) => CustomerShipment.fromJson(_asMap(row)))
          .toList(growable: false),
      meta: ApiPaginationMeta.fromJson(_asMap(json['meta'])),
      emptyState: _nullableMap(json['emptyState']) == null
          ? null
          : ApiEmptyState.fromJson(_asMap(json['emptyState'])),
    );
  }
}

class ShipmentDetailsData {
  const ShipmentDetailsData({
    required this.shipment,
    required this.proofs,
    required this.timelinePreview,
    this.payment,
    this.invoice,
    this.assignment,
  });

  final CustomerShipment shipment;
  final PaymentRecord? payment;
  final InvoiceRecord? invoice;
  final ShipmentAssignment? assignment;
  final List<ShipmentProofRecord> proofs;
  final List<ShipmentTimelineStep> timelinePreview;

  factory ShipmentDetailsData.fromJson(Map<String, dynamic> json) {
    final proofs = json['proofs'] is List ? json['proofs'] as List : const [];
    final timeline = json['timelinePreview'] is List
        ? json['timelinePreview'] as List
        : const [];

    return ShipmentDetailsData(
      shipment: CustomerShipment.fromJson(_asMap(json['shipment'])),
      payment: _nullableMap(json['payment']) == null
          ? null
          : PaymentRecord.fromJson(_asMap(json['payment'])),
      invoice: _nullableMap(json['invoice']) == null
          ? null
          : InvoiceRecord.fromJson(_asMap(json['invoice'])),
      assignment: _nullableMap(json['assignment']) == null
          ? null
          : ShipmentAssignment.fromJson(_asMap(json['assignment'])),
      proofs: proofs
          .whereType<Map>()
          .map((row) => ShipmentProofRecord.fromJson(_asMap(row)))
          .toList(growable: false),
      timelinePreview: timeline
          .whereType<Map>()
          .map((row) => ShipmentTimelineStep.fromJson(_asMap(row)))
          .toList(growable: false),
    );
  }
}

class ShipmentTimelineData {
  const ShipmentTimelineData({
    required this.currentStatus,
    required this.steps,
    required this.events,
  });

  final String currentStatus;
  final List<ShipmentTimelineStep> steps;
  final List<TripLogRecord> events;

  factory ShipmentTimelineData.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] is List ? json['steps'] as List : const [];
    final events = json['events'] is List ? json['events'] as List : const [];

    return ShipmentTimelineData(
      currentStatus: json['currentStatus']?.toString() ?? '',
      steps: steps
          .whereType<Map>()
          .map((row) => ShipmentTimelineStep.fromJson(_asMap(row)))
          .toList(growable: false),
      events: events
          .whereType<Map>()
          .map((row) => TripLogRecord.fromJson(_asMap(row)))
          .toList(growable: false),
    );
  }
}

class ShipmentTrackingData {
  const ShipmentTrackingData({
    required this.currentStatus,
    required this.map,
    required this.eta,
    required this.routeSummary,
    required this.actions,
    required this.timelinePreview,
    this.assignment,
  });

  final TrackingStatus currentStatus;
  final TrackingMapData map;
  final TrackingEta eta;
  final TrackingRouteSummary routeSummary;
  final TrackingActions actions;
  final ShipmentAssignment? assignment;
  final List<ShipmentTimelineStep> timelinePreview;

  factory ShipmentTrackingData.fromJson(Map<String, dynamic> json) {
    final timeline = json['timelinePreview'] is List
        ? json['timelinePreview'] as List
        : const [];

    return ShipmentTrackingData(
      currentStatus: TrackingStatus.fromJson(_asMap(json['currentStatus'])),
      map: TrackingMapData.fromJson(_asMap(json['map'])),
      eta: TrackingEta.fromJson(_asMap(json['eta'])),
      routeSummary: TrackingRouteSummary.fromJson(_asMap(json['routeSummary'])),
      actions: TrackingActions.fromJson(_asMap(json['actions'])),
      assignment: _nullableMap(json['assignment']) == null
          ? null
          : ShipmentAssignment.fromJson(_asMap(json['assignment'])),
      timelinePreview: timeline
          .whereType<Map>()
          .map((row) => ShipmentTimelineStep.fromJson(_asMap(row)))
          .toList(growable: false),
    );
  }
}

class ShipmentProofListData {
  const ShipmentProofListData({
    required this.shipment,
    required this.proofs,
    this.emptyState,
  });

  final ProofShipmentReference shipment;
  final List<ShipmentProofRecord> proofs;
  final ApiEmptyState? emptyState;

  factory ShipmentProofListData.fromJson(Map<String, dynamic> json) {
    final rows = json['proofs'] is List ? json['proofs'] as List : const [];

    return ShipmentProofListData(
      shipment: ProofShipmentReference.fromJson(_asMap(json['shipment'])),
      proofs: rows
          .whereType<Map>()
          .map((row) => ShipmentProofRecord.fromJson(_asMap(row)))
          .toList(growable: false),
      emptyState: _nullableMap(json['emptyState']) == null
          ? null
          : ApiEmptyState.fromJson(_asMap(json['emptyState'])),
    );
  }
}

class ShipmentProofDetailData {
  const ShipmentProofDetailData({
    required this.shipment,
    required this.proof,
    required this.actions,
  });

  final ProofShipmentReference shipment;
  final ShipmentProofRecord proof;
  final ProofActions actions;

  factory ShipmentProofDetailData.fromJson(Map<String, dynamic> json) {
    return ShipmentProofDetailData(
      shipment: ProofShipmentReference.fromJson(_asMap(json['shipment'])),
      proof: ShipmentProofRecord.fromJson(_asMap(json['proof'])),
      actions: ProofActions.fromJson(_asMap(json['actions'])),
    );
  }
}

class ShipmentAssignment {
  const ShipmentAssignment({
    required this.id,
    required this.assignmentCode,
    required this.assignmentStatus,
    this.assignedAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.driver,
    this.vehicle,
  });

  final int id;
  final String assignmentCode;
  final String assignmentStatus;
  final String? assignedAt;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final AssignedDriver? driver;
  final AssignedVehicle? vehicle;

  factory ShipmentAssignment.fromJson(Map<String, dynamic> json) {
    return ShipmentAssignment(
      id: _asInt(json['id']),
      assignmentCode: json['assignmentCode']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? '',
      assignedAt: json['assignedAt']?.toString(),
      acceptedAt: json['acceptedAt']?.toString(),
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      driver: _nullableMap(json['driver']) == null
          ? null
          : AssignedDriver.fromJson(_asMap(json['driver'])),
      vehicle: _nullableMap(json['vehicle']) == null
          ? null
          : AssignedVehicle.fromJson(_asMap(json['vehicle'])),
    );
  }
}

class AssignedDriver {
  const AssignedDriver({
    required this.id,
    required this.driverCode,
    required this.name,
    this.phoneMasked,
    this.rating,
    this.completedTrips,
  });

  final int id;
  final String driverCode;
  final String name;
  final String? phoneMasked;
  final double? rating;
  final int? completedTrips;

  factory AssignedDriver.fromJson(Map<String, dynamic> json) {
    return AssignedDriver(
      id: _asInt(json['id']),
      driverCode: json['driverCode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Assigned driver',
      phoneMasked: json['phoneMasked']?.toString(),
      rating: _asNullableDouble(json['rating']),
      completedTrips: _asNullableInt(json['completedTrips']),
    );
  }
}

class AssignedVehicle {
  const AssignedVehicle({
    required this.id,
    required this.vehicleNumber,
    required this.registrationNumber,
    required this.vehicleType,
    this.model,
    this.capacityKg,
  });

  final int id;
  final String vehicleNumber;
  final String registrationNumber;
  final String vehicleType;
  final String? model;
  final double? capacityKg;

  factory AssignedVehicle.fromJson(Map<String, dynamic> json) {
    return AssignedVehicle(
      id: _asInt(json['id']),
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString() ?? '',
      model: json['model']?.toString(),
      capacityKg: _asNullableDouble(json['capacityKg']),
    );
  }
}

class ShipmentTimelineStep {
  const ShipmentTimelineStep({
    required this.status,
    required this.label,
    required this.state,
    this.timestamp,
    this.description,
  });

  final String status;
  final String label;
  final String state;
  final String? timestamp;
  final String? description;

  factory ShipmentTimelineStep.fromJson(Map<String, dynamic> json) {
    return ShipmentTimelineStep(
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      state: json['state']?.toString() ?? 'pending',
      timestamp: json['timestamp']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class TripLogRecord {
  const TripLogRecord({
    required this.id,
    required this.status,
    required this.title,
    this.description,
    this.locationText,
    this.eventTime,
  });

  final int id;
  final String status;
  final String title;
  final String? description;
  final String? locationText;
  final String? eventTime;

  factory TripLogRecord.fromJson(Map<String, dynamic> json) {
    return TripLogRecord(
      id: _asInt(json['id']),
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      locationText: json['locationText']?.toString(),
      eventTime: json['eventTime']?.toString(),
    );
  }
}

class ShipmentProofRecord {
  const ShipmentProofRecord({
    required this.id,
    required this.proofCode,
    required this.proofType,
    required this.fileUrl,
    required this.verificationStatus,
    this.fileName,
    this.fileMimeType,
    this.fileSizeBytes,
    this.notes,
    this.locationText,
    this.capturedAt,
    this.createdAt,
    this.driverCode,
    this.uploadedByDriverName,
  });

  final int id;
  final String proofCode;
  final String proofType;
  final String fileUrl;
  final String verificationStatus;
  final String? fileName;
  final String? fileMimeType;
  final int? fileSizeBytes;
  final String? notes;
  final String? locationText;
  final String? capturedAt;
  final String? createdAt;
  final String? driverCode;
  final String? uploadedByDriverName;

  factory ShipmentProofRecord.fromJson(Map<String, dynamic> json) {
    return ShipmentProofRecord(
      id: _asInt(json['id']),
      proofCode: json['proofCode']?.toString() ?? '',
      proofType: json['proofType']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      fileName: json['fileName']?.toString(),
      fileMimeType: json['fileMimeType']?.toString(),
      fileSizeBytes: _asNullableInt(json['fileSizeBytes']),
      notes: json['notes']?.toString(),
      locationText: json['locationText']?.toString(),
      capturedAt: json['capturedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      driverCode: json['driverCode']?.toString(),
      uploadedByDriverName: json['uploadedByDriverName']?.toString(),
    );
  }
}

class TrackingStatus {
  const TrackingStatus({
    required this.status,
    required this.label,
    this.updatedAt,
    this.locationText,
  });

  final String status;
  final String label;
  final String? updatedAt;
  final String? locationText;

  factory TrackingStatus.fromJson(Map<String, dynamic> json) {
    return TrackingStatus(
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      locationText: json['locationText']?.toString(),
    );
  }
}

class TrackingMapData {
  const TrackingMapData({
    required this.pickup,
    required this.delivery,
    this.currentLocation,
  });

  final TrackingPoint pickup;
  final TrackingPoint delivery;
  final TrackingPoint? currentLocation;

  factory TrackingMapData.fromJson(Map<String, dynamic> json) {
    return TrackingMapData(
      pickup: TrackingPoint.fromJson(_asMap(json['pickup'])),
      delivery: TrackingPoint.fromJson(_asMap(json['delivery'])),
      currentLocation: _nullableMap(json['currentLocation']) == null
          ? null
          : TrackingPoint.fromJson(_asMap(json['currentLocation'])),
    );
  }
}

class TrackingPoint {
  const TrackingPoint({this.address, this.locationText});

  final String? address;
  final String? locationText;

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      address: json['address']?.toString(),
      locationText: json['locationText']?.toString(),
    );
  }
}

class TrackingEta {
  const TrackingEta({
    this.scheduledPickupAt,
    this.estimatedDurationMinutes,
    this.estimatedDeliveryAt,
  });

  final String? scheduledPickupAt;
  final int? estimatedDurationMinutes;
  final String? estimatedDeliveryAt;

  factory TrackingEta.fromJson(Map<String, dynamic> json) {
    return TrackingEta(
      scheduledPickupAt: json['scheduledPickupAt']?.toString(),
      estimatedDurationMinutes: _asNullableInt(
        json['estimatedDurationMinutes'],
      ),
      estimatedDeliveryAt: json['estimatedDeliveryAt']?.toString(),
    );
  }
}

class TrackingRouteSummary {
  const TrackingRouteSummary({
    required this.estimatedDistanceKm,
    required this.pickupAddress,
    required this.deliveryAddress,
  });

  final double estimatedDistanceKm;
  final String pickupAddress;
  final String deliveryAddress;

  factory TrackingRouteSummary.fromJson(Map<String, dynamic> json) {
    return TrackingRouteSummary(
      estimatedDistanceKm: _asDouble(json['estimatedDistanceKm']),
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      deliveryAddress: json['deliveryAddress']?.toString() ?? '',
    );
  }
}

class TrackingActions {
  const TrackingActions({required this.callDriverEnabled});

  final bool callDriverEnabled;

  factory TrackingActions.fromJson(Map<String, dynamic> json) {
    final callDriver = _asMap(json['callDriver']);
    return TrackingActions(callDriverEnabled: callDriver['enabled'] == true);
  }
}

class ProofShipmentReference {
  const ProofShipmentReference({required this.id, required this.shipmentCode});

  final int id;
  final String shipmentCode;

  factory ProofShipmentReference.fromJson(Map<String, dynamic> json) {
    return ProofShipmentReference(
      id: _asInt(json['id']),
      shipmentCode: json['shipmentCode']?.toString() ?? '',
    );
  }
}

class ProofActions {
  const ProofActions({required this.downloadUrl, required this.fullScreenUrl});

  final String? downloadUrl;
  final String? fullScreenUrl;

  factory ProofActions.fromJson(Map<String, dynamic> json) {
    final download = _asMap(json['download']);
    final fullScreen = _asMap(json['viewFullScreen']);
    return ProofActions(
      downloadUrl: download['url']?.toString(),
      fullScreenUrl: fullScreen['url']?.toString(),
    );
  }
}

class ApiPaginationMeta {
  const ApiPaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasMore,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  factory ApiPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ApiPaginationMeta(
      total: _asInt(json['total']),
      page: _asInt(json['page']),
      limit: _asInt(json['limit']),
      totalPages: _asInt(json['totalPages']),
      hasMore: json['hasMore'] == true,
    );
  }
}

class ApiEmptyState {
  const ApiEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  factory ApiEmptyState.fromJson(Map<String, dynamic> json) {
    return ApiEmptyState(
      title: json['title']?.toString() ?? 'No records found',
      message: json['message']?.toString() ?? '',
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

int? _asNullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  return _asInt(value);
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _asDouble(value);
}
