import '../../../core/utils/mock_driver_data.dart';

class DriverTripListResult {
  const DriverTripListResult({
    required this.trips,
    required this.meta,
    this.driver,
    this.emptyTitle,
    this.emptyMessage,
  });

  factory DriverTripListResult.fromJson(Map<String, dynamic> json) {
    final emptyState = _asMap(json['emptyState']);
    return DriverTripListResult(
      driver: _asMap(json['driver']).isEmpty
          ? null
          : DriverSummary.fromJson(_asMap(json['driver'])),
      trips: _asList(json['trips'])
          .map((item) => DriverTripSummary.fromJson(_asMap(item)))
          .toList(growable: false),
      meta: PaginationMeta.fromJson(_asMap(json['meta'])),
      emptyTitle: emptyState['title']?.toString(),
      emptyMessage: emptyState['message']?.toString(),
    );
  }

  final DriverSummary? driver;
  final List<DriverTripSummary> trips;
  final PaginationMeta meta;
  final String? emptyTitle;
  final String? emptyMessage;
}

class DriverSummary {
  const DriverSummary({
    required this.id,
    required this.driverCode,
    required this.availabilityStatus,
  });

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    return DriverSummary(
      id: _toInt(json['id']),
      driverCode: json['driverCode']?.toString() ?? '',
      availabilityStatus: json['availabilityStatus']?.toString() ?? '',
    );
  }

  final int id;
  final String driverCode;
  final String availabilityStatus;
}

class PaginationMeta {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasMore,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: _toInt(json['total']),
      page: _toInt(json['page'], fallback: 1),
      limit: _toInt(json['limit'], fallback: 10),
      totalPages: _toInt(json['totalPages'], fallback: 1),
      hasMore: json['hasMore'] == true,
    );
  }

  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;
}

class DriverTripDetail {
  const DriverTripDetail({
    required this.trip,
    required this.timeline,
    required this.proofs,
  });

  factory DriverTripDetail.fromJson(Map<String, dynamic> json) {
    return DriverTripDetail(
      trip: DriverTripSummary.fromJson(_asMap(json['trip'])),
      timeline: DriverTripTimeline.fromJson(_asMap(json['timeline'])),
      proofs: _asList(json['proofs'])
          .map((item) => DriverProof.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }

  final DriverTripSummary trip;
  final DriverTripTimeline timeline;
  final List<DriverProof> proofs;
}

class DriverTripTimeline {
  const DriverTripTimeline({
    required this.currentStatus,
    required this.steps,
    required this.events,
  });

  factory DriverTripTimeline.fromJson(Map<String, dynamic> json) {
    return DriverTripTimeline(
      currentStatus: json['currentStatus']?.toString() ?? '',
      steps: _asList(json['steps'])
          .map((item) => DriverTimelineStep.fromJson(_asMap(item)))
          .toList(growable: false),
      events: _asList(json['events'])
          .map((item) => DriverTimelineEvent.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }

  final String currentStatus;
  final List<DriverTimelineStep> steps;
  final List<DriverTimelineEvent> events;

  List<DriverTimelineMock> toTimelineMocks() {
    return steps
        .map(
          (step) => DriverTimelineMock(
            title: step.label,
            subtitle: step.description ?? _timelineSubtitle(step.status),
            time: _formatDateTime(step.timestamp) ?? 'Pending',
            state: switch (step.state) {
              'completed' => DriverTimelineState.completed,
              'current' => DriverTimelineState.current,
              _ => DriverTimelineState.pending,
            },
          ),
        )
        .toList(growable: false);
  }
}

class DriverTimelineStep {
  const DriverTimelineStep({
    required this.status,
    required this.label,
    required this.state,
    this.timestamp,
    this.description,
  });

  factory DriverTimelineStep.fromJson(Map<String, dynamic> json) {
    return DriverTimelineStep(
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? _statusLabel(json['status']),
      state: json['state']?.toString() ?? 'pending',
      timestamp: json['timestamp']?.toString(),
      description: json['description']?.toString(),
    );
  }

  final String status;
  final String label;
  final String state;
  final String? timestamp;
  final String? description;
}

class DriverTimelineEvent {
  const DriverTimelineEvent({
    required this.id,
    required this.status,
    required this.title,
    this.description,
    this.locationText,
    this.eventTime,
  });

  factory DriverTimelineEvent.fromJson(Map<String, dynamic> json) {
    return DriverTimelineEvent(
      id: _toInt(json['id']),
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? _statusLabel(json['status']),
      description: json['description']?.toString(),
      locationText: json['locationText']?.toString(),
      eventTime: json['eventTime']?.toString(),
    );
  }

  final int id;
  final String status;
  final String title;
  final String? description;
  final String? locationText;
  final String? eventTime;
}

class DriverTripSummary {
  const DriverTripSummary({
    required this.id,
    required this.assignmentCode,
    required this.assignmentStatus,
    required this.shipment,
    required this.customer,
    required this.receiver,
    required this.packageInfo,
    required this.vehicle,
    required this.routeSummary,
    required this.actions,
    this.assignedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.startedAt,
    this.completedAt,
  });

  factory DriverTripSummary.fromJson(Map<String, dynamic> json) {
    return DriverTripSummary(
      id: _toInt(json['id']),
      assignmentCode: json['assignmentCode']?.toString() ?? '',
      assignmentStatus: json['assignmentStatus']?.toString() ?? '',
      assignedAt: json['assignedAt']?.toString(),
      acceptedAt: json['acceptedAt']?.toString(),
      rejectedAt: json['rejectedAt']?.toString(),
      rejectionReason: json['rejectionReason']?.toString(),
      startedAt: json['startedAt']?.toString(),
      completedAt: json['completedAt']?.toString(),
      shipment: DriverShipmentSummary.fromJson(_asMap(json['shipment'])),
      customer: DriverTripCustomer.fromJson(_asMap(json['customer'])),
      receiver: DriverTripReceiver.fromJson(_asMap(json['receiver'])),
      packageInfo: DriverPackageInfo.fromJson(_asMap(json['package'])),
      vehicle: DriverVehicleInfo.fromJson(_asMap(json['vehicle'])),
      routeSummary: DriverRouteSummary.fromJson(_asMap(json['routeSummary'])),
      actions: DriverTripActions.fromJson(_asMap(json['actions'])),
    );
  }

  final int id;
  final String assignmentCode;
  final String assignmentStatus;
  final String? assignedAt;
  final String? acceptedAt;
  final String? rejectedAt;
  final String? rejectionReason;
  final String? startedAt;
  final String? completedAt;
  final DriverShipmentSummary shipment;
  final DriverTripCustomer customer;
  final DriverTripReceiver receiver;
  final DriverPackageInfo packageInfo;
  final DriverVehicleInfo vehicle;
  final DriverRouteSummary routeSummary;
  final DriverTripActions actions;

  String get displayId =>
      shipment.shipmentCode.isNotEmpty ? shipment.shipmentCode : assignmentCode;

  String get statusLabel => _statusLabel(assignmentStatus);

  String get pickupAddress => shipment.pickup.fullAddress;

  String get deliveryAddress => shipment.delivery.fullAddress;

  String get vehicleLabel {
    final type = vehicle.type.isNotEmpty ? vehicle.type : 'Assigned vehicle';
    if (vehicle.vehicleNumber.isNotEmpty) {
      return '$type (${vehicle.vehicleNumber})';
    }
    return type;
  }

  String get distanceLabel {
    final value = routeSummary.estimatedDistanceKm;
    return value == null ? 'Distance pending' : '${_formatNumber(value)} km';
  }

  String get durationLabel {
    final minutes = routeSummary.estimatedDurationMinutes;
    if (minutes == null || minutes <= 0) {
      return _formatDateTime(shipment.pickup.scheduledAt) ?? 'ETA pending';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) {
      return '$remainingMinutes min';
    }
    if (remainingMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remainingMinutes min';
  }

  String get payoutLabel {
    final price = routeSummary.estimatedPrice;
    return price == null ? 'INR 0' : _formatInr(price);
  }

  String get scheduledWindow =>
      _formatDateTime(shipment.pickup.scheduledAt) ?? 'Pickup pending';

  DriverTripMock toTripCardModel() {
    return DriverTripMock(
      id: displayId,
      status: statusLabel,
      pickup: pickupAddress,
      delivery: deliveryAddress,
      package: packageInfo.type.isEmpty
          ? shipment.category.name
          : packageInfo.type,
      vehicle: vehicleLabel,
      distance: distanceLabel,
      eta: durationLabel,
      payout: payoutLabel,
      window: scheduledWindow,
      assignmentId: id,
      shipmentId: shipment.id,
      vehicleId: vehicle.id,
    );
  }
}

class DriverShipmentSummary {
  const DriverShipmentSummary({
    required this.id,
    required this.shipmentCode,
    required this.shipmentStatus,
    required this.paymentStatus,
    required this.category,
    required this.pickup,
    required this.delivery,
  });

  factory DriverShipmentSummary.fromJson(Map<String, dynamic> json) {
    return DriverShipmentSummary(
      id: _toInt(json['id']),
      shipmentCode: json['shipmentCode']?.toString() ?? '',
      shipmentStatus: json['shipmentStatus']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      category: DriverCategoryInfo.fromJson(_asMap(json['category'])),
      pickup: DriverAddressInfo.fromJson(_asMap(json['pickup'])),
      delivery: DriverAddressInfo.fromJson(_asMap(json['delivery'])),
    );
  }

  final int id;
  final String shipmentCode;
  final String shipmentStatus;
  final String paymentStatus;
  final DriverCategoryInfo category;
  final DriverAddressInfo pickup;
  final DriverAddressInfo delivery;
}

class DriverCategoryInfo {
  const DriverCategoryInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.iconKey,
  });

  factory DriverCategoryInfo.fromJson(Map<String, dynamic> json) {
    return DriverCategoryInfo(
      id: _toInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General cargo',
      iconKey: json['iconKey']?.toString() ?? '',
    );
  }

  final int id;
  final String code;
  final String name;
  final String iconKey;
}

class DriverAddressInfo {
  const DriverAddressInfo({
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    this.scheduledAt,
  });

  factory DriverAddressInfo.fromJson(Map<String, dynamic> json) {
    return DriverAddressInfo(
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      scheduledAt: json['scheduledAt']?.toString(),
    );
  }

  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String? scheduledAt;

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      postalCode,
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    return parts.isEmpty ? 'Address pending' : parts.join(', ');
  }
}

class DriverTripCustomer {
  const DriverTripCustomer({
    required this.id,
    required this.customerCode,
    required this.name,
    required this.phoneMasked,
    required this.emailMasked,
  });

  factory DriverTripCustomer.fromJson(Map<String, dynamic> json) {
    return DriverTripCustomer(
      id: _toInt(json['id']),
      customerCode: json['customerCode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Customer',
      phoneMasked: json['phoneMasked']?.toString() ?? 'Masked',
      emailMasked: json['emailMasked']?.toString() ?? 'Masked',
    );
  }

  final int id;
  final String customerCode;
  final String name;
  final String phoneMasked;
  final String emailMasked;
}

class DriverTripReceiver {
  const DriverTripReceiver({required this.name, required this.phone});

  factory DriverTripReceiver.fromJson(Map<String, dynamic> json) {
    return DriverTripReceiver(
      name: json['name']?.toString() ?? 'Receiver',
      phone: json['phone']?.toString() ?? 'Phone pending',
    );
  }

  final String name;
  final String phone;
}

class DriverPackageInfo {
  const DriverPackageInfo({
    required this.type,
    required this.weightKg,
    required this.dimensions,
    required this.vehiclePreference,
    required this.isFragile,
    required this.deliveryNotes,
  });

  factory DriverPackageInfo.fromJson(Map<String, dynamic> json) {
    return DriverPackageInfo(
      type: json['type']?.toString() ?? '',
      weightKg: _toDouble(json['weightKg']),
      dimensions: DriverPackageDimensions.fromJson(
        _asMap(json['dimensionsCm']),
      ),
      vehiclePreference: json['vehiclePreference']?.toString() ?? '',
      isFragile: json['isFragile'] == true,
      deliveryNotes: json['deliveryNotes']?.toString() ?? '',
    );
  }

  final String type;
  final double? weightKg;
  final DriverPackageDimensions dimensions;
  final String vehiclePreference;
  final bool isFragile;
  final String deliveryNotes;

  String get weightLabel =>
      weightKg == null ? 'Weight pending' : '${_formatNumber(weightKg!)} kg';

  String get dimensionsLabel {
    if (dimensions.length == null &&
        dimensions.width == null &&
        dimensions.height == null) {
      return 'Dimensions optional';
    }
    return [
      dimensions.length == null ? '-' : _formatNumber(dimensions.length!),
      dimensions.width == null ? '-' : _formatNumber(dimensions.width!),
      dimensions.height == null ? '-' : _formatNumber(dimensions.height!),
    ].join(' x ');
  }

  String get handlingLabel {
    if (isFragile) {
      return 'Fragile handling';
    }
    return deliveryNotes.isEmpty ? 'Standard handling' : deliveryNotes;
  }
}

class DriverPackageDimensions {
  const DriverPackageDimensions({this.length, this.width, this.height});

  factory DriverPackageDimensions.fromJson(Map<String, dynamic> json) {
    return DriverPackageDimensions(
      length: _toDouble(json['length']),
      width: _toDouble(json['width']),
      height: _toDouble(json['height']),
    );
  }

  final double? length;
  final double? width;
  final double? height;
}

class DriverVehicleInfo {
  const DriverVehicleInfo({
    required this.id,
    required this.vehicleNumber,
    required this.registrationNumber,
    required this.type,
    required this.model,
    required this.fuelType,
    required this.availabilityStatus,
    this.capacityKg,
  });

  factory DriverVehicleInfo.fromJson(Map<String, dynamic> json) {
    return DriverVehicleInfo(
      id: _toInt(json['id']),
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      fuelType: json['fuelType']?.toString() ?? '',
      capacityKg: _toDouble(json['capacityKg']),
      availabilityStatus: json['availabilityStatus']?.toString() ?? '',
    );
  }

  final int id;
  final String vehicleNumber;
  final String registrationNumber;
  final String type;
  final String model;
  final String fuelType;
  final double? capacityKg;
  final String availabilityStatus;
}

class DriverRouteSummary {
  const DriverRouteSummary({
    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,
    this.estimatedPrice,
  });

  factory DriverRouteSummary.fromJson(Map<String, dynamic> json) {
    return DriverRouteSummary(
      estimatedDistanceKm: _toDouble(json['estimatedDistanceKm']),
      estimatedDurationMinutes: _toIntOrNull(json['estimatedDurationMinutes']),
      estimatedPrice: _toDouble(json['estimatedPrice']),
    );
  }

  final double? estimatedDistanceKm;
  final int? estimatedDurationMinutes;
  final double? estimatedPrice;
}

class DriverTripActions {
  const DriverTripActions({
    required this.canAccept,
    required this.canReject,
    required this.canStart,
    required this.canMarkPickupCompleted,
    required this.canMarkInTransit,
    required this.canMarkDeliveryCompleted,
    required this.canComplete,
    required this.canUploadPickupProof,
    required this.canUploadDeliveryProof,
  });

  factory DriverTripActions.fromJson(Map<String, dynamic> json) {
    return DriverTripActions(
      canAccept: json['canAccept'] == true,
      canReject: json['canReject'] == true,
      canStart: json['canStart'] == true,
      canMarkPickupCompleted: json['canMarkPickupCompleted'] == true,
      canMarkInTransit: json['canMarkInTransit'] == true,
      canMarkDeliveryCompleted: json['canMarkDeliveryCompleted'] == true,
      canComplete: json['canComplete'] == true,
      canUploadPickupProof: json['canUploadPickupProof'] == true,
      canUploadDeliveryProof: json['canUploadDeliveryProof'] == true,
    );
  }

  final bool canAccept;
  final bool canReject;
  final bool canStart;
  final bool canMarkPickupCompleted;
  final bool canMarkInTransit;
  final bool canMarkDeliveryCompleted;
  final bool canComplete;
  final bool canUploadPickupProof;
  final bool canUploadDeliveryProof;
}

class DriverProof {
  const DriverProof({
    required this.id,
    required this.proofCode,
    required this.proofType,
    required this.fileUrl,
    required this.fileName,
    required this.verificationStatus,
    this.notes,
    this.locationText,
    this.capturedAt,
    this.createdAt,
  });

  factory DriverProof.fromJson(Map<String, dynamic> json) {
    return DriverProof(
      id: _toInt(json['id']),
      proofCode: json['proofCode']?.toString() ?? '',
      proofType: json['proofType']?.toString() ?? '',
      fileUrl: json['fileUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      locationText: json['locationText']?.toString(),
      capturedAt: json['capturedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  final int id;
  final String proofCode;
  final String proofType;
  final String fileUrl;
  final String fileName;
  final String verificationStatus;
  final String? notes;
  final String? locationText;
  final String? capturedAt;
  final String? createdAt;

  String get timestampLabel =>
      _formatDateTime(capturedAt) ??
      _formatDateTime(createdAt) ??
      'Time pending';
}

String _timelineSubtitle(String status) {
  return switch (status) {
    'assigned' => 'Fleet desk assigned this shipment to your driver profile.',
    'accepted' => 'Driver accepted the assigned shipment.',
    'started' => 'Trip has started from the driver app.',
    'pickup_completed' => 'Pickup proof and handover are recorded.',
    'in_transit' => 'Shipment is moving toward the destination.',
    'delivered' => 'Delivery handoff is recorded.',
    'completed' => 'Trip workflow is completed.',
    _ => 'Trip status update.',
  };
}

String _statusLabel(Object? value) {
  final status = value?.toString() ?? '';
  if (status.isEmpty) {
    return 'Pending';
  }
  return status
      .split('_')
      .map((word) {
        if (word.isEmpty) {
          return word;
        }
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

String? _formatDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  final month = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][local.month - 1];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$month ${local.day}, ${local.year}, $hour12:$minute $suffix';
}

String _formatNumber(num value) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _formatInr(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final fromRight = raw.length - index;
    buffer.write(raw[index]);
    if (fromRight > 1 && fromRight % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'INR $buffer';
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

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const [];
}

int _toInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _toIntOrNull(Object? value) {
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

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
