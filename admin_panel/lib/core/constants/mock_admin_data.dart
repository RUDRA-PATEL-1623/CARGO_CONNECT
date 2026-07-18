import 'package:flutter/material.dart';

import 'app_colors.dart';

class AdminStatMock {
  const AdminStatMock({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.isPositive,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final bool isPositive;
  final Color accentColor;
}

class AdminChartPointMock {
  const AdminChartPointMock({required this.label, required this.value});

  final String label;
  final double value;
}

class AdminReportCardMock {
  const AdminReportCardMock({
    required this.title,
    required this.metric,
    required this.delta,
    required this.description,
    required this.status,
    required this.icon,
    required this.accentColor,
    required this.isPositive,
  });

  final String title;
  final String metric;
  final String delta;
  final String description;
  final String status;
  final IconData icon;
  final Color accentColor;
  final bool isPositive;
}

class AdminShipmentDateReportMock {
  const AdminShipmentDateReportMock({
    required this.date,
    required this.bookings,
    required this.approved,
    required this.inTransit,
    required this.delivered,
    required this.cancelled,
    required this.revenue,
  });

  final String date;
  final int bookings;
  final int approved;
  final int inTransit;
  final int delivered;
  final int cancelled;
  final String revenue;
}

class AdminShipmentStatusReportMock {
  const AdminShipmentStatusReportMock({
    required this.status,
    required this.count,
    required this.share,
    required this.revenue,
    required this.sla,
  });

  final String status;
  final int count;
  final String share;
  final String revenue;
  final String sla;
}

class AdminShipmentCategoryReportMock {
  const AdminShipmentCategoryReportMock({
    required this.category,
    required this.shipments,
    required this.averageWeight,
    required this.revenue,
    required this.topVehicle,
  });

  final String category;
  final int shipments;
  final String averageWeight;
  final String revenue;
  final String topVehicle;
}

class AdminDriverReportMock {
  const AdminDriverReportMock({
    required this.id,
    required this.name,
    required this.zone,
    required this.status,
    required this.completedTrips,
    required this.acceptanceRate,
    required this.delays,
    required this.performanceScore,
    required this.emergencyCount,
    required this.onTimeRate,
    required this.rating,
  });

  final String id;
  final String name;
  final String zone;
  final String status;
  final int completedTrips;
  final double acceptanceRate;
  final int delays;
  final int performanceScore;
  final int emergencyCount;
  final double onTimeRate;
  final double rating;
}

class AdminPaymentRevenueReportMock {
  const AdminPaymentRevenueReportMock({
    required this.date,
    required this.paidRevenue,
    required this.pendingAmount,
    required this.refundedAmount,
    required this.transactions,
  });

  final String date;
  final String paidRevenue;
  final String pendingAmount;
  final String refundedAmount;
  final int transactions;
}

class AdminPaymentMethodReportMock {
  const AdminPaymentMethodReportMock({
    required this.method,
    required this.transactions,
    required this.revenue,
    required this.pendingAmount,
    required this.successRate,
    required this.settlementNote,
  });

  final String method;
  final int transactions;
  final String revenue;
  final String pendingAmount;
  final String successRate;
  final String settlementNote;
}

class AdminPaymentStatusReportMock {
  const AdminPaymentStatusReportMock({
    required this.status,
    required this.count,
    required this.amount,
    required this.share,
    required this.action,
  });

  final String status;
  final int count;
  final String amount;
  final String share;
  final String action;
}

class AdminVehicleReportMock {
  const AdminVehicleReportMock({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    required this.availability,
    required this.utilization,
    required this.serviceDue,
    required this.assignmentCount,
    required this.breakdownCount,
    required this.assignedDriver,
    required this.assignedTrip,
    required this.hub,
  });

  final String id;
  final String vehicleNumber;
  final String type;
  final String availability;
  final int utilization;
  final DateTime serviceDue;
  final int assignmentCount;
  final int breakdownCount;
  final String assignedDriver;
  final String? assignedTrip;
  final String hub;
}

class AdminVehicleAssignmentHistoryReportMock {
  const AdminVehicleAssignmentHistoryReportMock({
    required this.date,
    required this.vehicleNumber,
    required this.tripId,
    required this.driver,
    required this.route,
    required this.status,
    required this.duration,
  });

  final String date;
  final String vehicleNumber;
  final String tripId;
  final String driver;
  final String route;
  final String status;
  final String duration;
}

class AdminVehicleBreakdownReportMock {
  const AdminVehicleBreakdownReportMock({
    required this.date,
    required this.vehicleNumber,
    required this.issue,
    required this.severity,
    required this.downtime,
    required this.status,
  });

  final String date;
  final String vehicleNumber;
  final String issue;
  final String severity;
  final String downtime;
  final String status;
}

class AdminRecentActivityMock {
  const AdminRecentActivityMock({
    required this.time,
    required this.activity,
    required this.reference,
    required this.owner,
    required this.status,
    required this.amount,
  });

  final String time;
  final String activity;
  final String reference;
  final String owner;
  final String status;
  final String amount;
}

class AdminShipmentManagementMock {
  const AdminShipmentManagementMock({
    required this.id,
    required this.customer,
    required this.category,
    required this.route,
    required this.pickupDate,
    required this.dateFilter,
    required this.driver,
    required this.status,
    required this.vehicle,
    required this.amount,
    this.backendId,
    this.assignmentBackendId,
  });

  final String id;
  final String customer;
  final String category;
  final String route;
  final String pickupDate;
  final String dateFilter;
  final String driver;
  final String status;
  final String vehicle;
  final String amount;
  final int? backendId;
  final int? assignmentBackendId;
}

class AdminShipmentDetailMock {
  const AdminShipmentDetailMock({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.packageType,
    required this.weight,
    required this.dimensions,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.invoiceNumber,
    required this.invoiceStatus,
    required this.adminNotes,
    this.backendId,
  });

  final String id;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String receiverName;
  final String receiverPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String packageType;
  final String weight;
  final String dimensions;
  final String paymentMethod;
  final String paymentStatus;
  final String invoiceNumber;
  final String invoiceStatus;
  final String adminNotes;
  final int? backendId;
}

class AdminDriverAssignmentMock {
  const AdminDriverAssignmentMock({
    required this.id,
    required this.name,
    required this.phone,
    required this.zone,
    required this.rating,
    required this.status,
    required this.currentShipmentId,
    this.backendId,
  });

  final String id;
  final String name;
  final String phone;
  final String zone;
  final String rating;
  final String status;
  final String? currentShipmentId;
  final int? backendId;
}

class AdminVehicleAssignmentMock {
  const AdminVehicleAssignmentMock({
    required this.id,
    required this.label,
    required this.type,
    required this.registration,
    required this.capacity,
    required this.status,
    required this.currentShipmentId,
    this.backendId,
  });

  final String id;
  final String label;
  final String type;
  final String registration;
  final String capacity;
  final String status;
  final String? currentShipmentId;
  final int? backendId;
}

class AdminVehicleManagementMock {
  const AdminVehicleManagementMock({
    required this.id,
    required this.vehicleNumber,
    required this.type,
    required this.capacity,
    required this.model,
    required this.fuelType,
    required this.registration,
    required this.insuranceExpiry,
    required this.serviceDue,
    required this.availability,
    required this.assignedDriver,
    required this.assignedTrip,
    required this.hub,
    required this.odometer,
    required this.lastInspection,
    required this.notes,
    this.backendId,
  });

  final String id;
  final String vehicleNumber;
  final String type;
  final String capacity;
  final String model;
  final String fuelType;
  final String registration;
  final DateTime insuranceExpiry;
  final DateTime serviceDue;
  final String availability;
  final String assignedDriver;
  final String? assignedTrip;
  final String hub;
  final String odometer;
  final String lastInspection;
  final String notes;
  final int? backendId;

  AdminVehicleManagementMock copyWith({
    String? id,
    String? vehicleNumber,
    String? type,
    String? capacity,
    String? model,
    String? fuelType,
    String? registration,
    DateTime? insuranceExpiry,
    DateTime? serviceDue,
    String? availability,
    String? assignedDriver,
    String? assignedTrip,
    String? hub,
    String? odometer,
    String? lastInspection,
    String? notes,
    int? backendId,
  }) {
    return AdminVehicleManagementMock(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      model: model ?? this.model,
      fuelType: fuelType ?? this.fuelType,
      registration: registration ?? this.registration,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      serviceDue: serviceDue ?? this.serviceDue,
      availability: availability ?? this.availability,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      assignedTrip: assignedTrip ?? this.assignedTrip,
      hub: hub ?? this.hub,
      odometer: odometer ?? this.odometer,
      lastInspection: lastInspection ?? this.lastInspection,
      notes: notes ?? this.notes,
      backendId: backendId ?? this.backendId,
    );
  }
}

class AdminCustomerManagementMock {
  const AdminCustomerManagementMock({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.totalShipments,
    required this.status,
    required this.registeredDate,
    required this.address,
    required this.lastShipmentId,
    required this.preferredCategory,
    required this.lifetimeValue,
    required this.openIssues,
    required this.lastActivity,
    this.backendId,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final int totalShipments;
  final String status;
  final DateTime registeredDate;
  final String address;
  final String? lastShipmentId;
  final String preferredCategory;
  final String lifetimeValue;
  final int openIssues;
  final String lastActivity;
  final int? backendId;

  AdminCustomerManagementMock copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    int? totalShipments,
    String? status,
    DateTime? registeredDate,
    String? address,
    String? lastShipmentId,
    String? preferredCategory,
    String? lifetimeValue,
    int? openIssues,
    String? lastActivity,
    int? backendId,
  }) {
    return AdminCustomerManagementMock(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      totalShipments: totalShipments ?? this.totalShipments,
      status: status ?? this.status,
      registeredDate: registeredDate ?? this.registeredDate,
      address: address ?? this.address,
      lastShipmentId: lastShipmentId ?? this.lastShipmentId,
      preferredCategory: preferredCategory ?? this.preferredCategory,
      lifetimeValue: lifetimeValue ?? this.lifetimeValue,
      openIssues: openIssues ?? this.openIssues,
      lastActivity: lastActivity ?? this.lastActivity,
      backendId: backendId ?? this.backendId,
    );
  }
}

class AdminPaymentManagementMock {
  const AdminPaymentManagementMock({
    required this.id,
    required this.shipmentId,
    required this.customer,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
    required this.dateFilter,
    required this.transactionReference,
    required this.invoiceNumber,
    required this.gateway,
    required this.fee,
    required this.netAmount,
    required this.notes,
    this.backendId,
  });

  final String id;
  final String shipmentId;
  final String customer;
  final String amount;
  final String method;
  final String status;
  final DateTime date;
  final String dateFilter;
  final String transactionReference;
  final String invoiceNumber;
  final String gateway;
  final String fee;
  final String netAmount;
  final String notes;
  final int? backendId;
}

class AdminInvoiceManagementMock {
  const AdminInvoiceManagementMock({
    required this.invoiceNumber,
    required this.shipmentId,
    required this.customer,
    required this.total,
    required this.paymentStatus,
    required this.generatedDate,
    required this.dateFilter,
    required this.invoiceStatus,
    required this.billingAddress,
    required this.route,
    required this.packageSummary,
    required this.baseCharge,
    required this.handlingFee,
    required this.tax,
    required this.discount,
    required this.paymentMethod,
    required this.notes,
    this.backendId,
  });

  final String invoiceNumber;
  final String shipmentId;
  final String customer;
  final String total;
  final String paymentStatus;
  final DateTime generatedDate;
  final String dateFilter;
  final String invoiceStatus;
  final String billingAddress;
  final String route;
  final String packageSummary;
  final String baseCharge;
  final String handlingFee;
  final String tax;
  final String discount;
  final String paymentMethod;
  final String notes;
  final int? backendId;
}

class AdminDriverManagementMock {
  AdminDriverManagementMock({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.temporaryPassword,
    required this.zone,
    required this.assignedVehicle,
    required this.status,
    required this.availability,
    required this.licenseNumber,
    required this.licenseClass,
    required this.licenseExpiry,
    required this.completedTrips,
    required this.onTimePercentage,
    required this.safetyScore,
    required this.rating,
    required this.lastCheckIn,
    this.backendId,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String address;
  final String temporaryPassword;
  final String zone;
  final String assignedVehicle;
  final String status;
  final String availability;
  final String licenseNumber;
  final String licenseClass;
  final DateTime licenseExpiry;
  final int completedTrips;
  final int onTimePercentage;
  final int safetyScore;
  final double rating;
  final String lastCheckIn;
  final int? backendId;

  AdminDriverManagementMock copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phone,
    String? address,
    String? temporaryPassword,
    String? zone,
    String? assignedVehicle,
    String? status,
    String? availability,
    String? licenseNumber,
    String? licenseClass,
    DateTime? licenseExpiry,
    int? completedTrips,
    int? onTimePercentage,
    int? safetyScore,
    double? rating,
    String? lastCheckIn,
    int? backendId,
  }) {
    return AdminDriverManagementMock(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      temporaryPassword: temporaryPassword ?? this.temporaryPassword,
      zone: zone ?? this.zone,
      assignedVehicle: assignedVehicle ?? this.assignedVehicle,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseClass: licenseClass ?? this.licenseClass,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      completedTrips: completedTrips ?? this.completedTrips,
      onTimePercentage: onTimePercentage ?? this.onTimePercentage,
      safetyScore: safetyScore ?? this.safetyScore,
      rating: rating ?? this.rating,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      backendId: backendId ?? this.backendId,
    );
  }
}

const adminStats = [
  AdminStatMock(
    label: 'Total shipments',
    value: '1,284',
    delta: '+86 this month',
    icon: Icons.inventory_2_outlined,
    isPositive: true,
    accentColor: AppColors.primaryBlue,
  ),
  AdminStatMock(
    label: 'Pending',
    value: '37',
    delta: '12 need approval',
    icon: Icons.pending_actions_outlined,
    isPositive: false,
    accentColor: AppColors.warning,
  ),
  AdminStatMock(
    label: 'Active deliveries',
    value: '128',
    delta: '+14 today',
    icon: Icons.local_shipping_outlined,
    isPositive: true,
    accentColor: AppColors.info,
  ),
  AdminStatMock(
    label: 'Delivered',
    value: '912',
    delta: '+42 this week',
    icon: Icons.task_alt_rounded,
    isPositive: true,
    accentColor: AppColors.success,
  ),
  AdminStatMock(
    label: 'Cancelled',
    value: '18',
    delta: '2 fewer today',
    icon: Icons.cancel_outlined,
    isPositive: true,
    accentColor: AppColors.danger,
  ),
  AdminStatMock(
    label: 'Available drivers',
    value: '42',
    delta: '+5 online',
    icon: Icons.badge_outlined,
    isPositive: true,
    accentColor: AppColors.success,
  ),
  AdminStatMock(
    label: 'Busy drivers',
    value: '73',
    delta: '64% assigned',
    icon: Icons.route_outlined,
    isPositive: true,
    accentColor: AppColors.primaryNavy,
  ),
  AdminStatMock(
    label: 'Vehicle utilization',
    value: '78%',
    delta: '+6.2%',
    icon: Icons.fire_truck_outlined,
    isPositive: true,
    accentColor: AppColors.accentOrange,
  ),
  AdminStatMock(
    label: 'Revenue summary',
    value: 'INR 12.8L',
    delta: '+9.8% MTD',
    icon: Icons.payments_outlined,
    isPositive: true,
    accentColor: AppColors.primaryBlue,
  ),
];

final adminDriverManagementRows = [
  AdminDriverManagementMock(
    id: 'DRV-104',
    name: 'Amit Verma',
    username: 'amit.verma',
    email: 'amit.verma@cargoconnect.example',
    phone: '+91 98881 22440',
    address: 'Flat 12, Baner Road, Pune, Maharashtra',
    temporaryPassword: 'Cargo@240104',
    zone: 'Pune Corridor',
    assignedVehicle: '14 ft Truck T19',
    status: 'Active',
    availability: 'Available',
    licenseNumber: 'MH14TR8821',
    licenseClass: 'HMV',
    licenseExpiry: DateTime(2027, 3, 18),
    completedTrips: 248,
    onTimePercentage: 96,
    safetyScore: 98,
    rating: 4.8,
    lastCheckIn: 'Checked in 12 min ago',
  ),
  AdminDriverManagementMock(
    id: 'DRV-118',
    name: 'Farhan Ali',
    username: 'farhan.ali',
    email: 'farhan.ali@cargoconnect.example',
    phone: '+91 98110 88421',
    address: 'Bhiwandi Logistics Colony, Thane, Maharashtra',
    temporaryPassword: 'Cargo@240118',
    zone: 'Bhiwandi Hub',
    assignedVehicle: 'Open Truck R08',
    status: 'Active',
    availability: 'On Trip',
    licenseNumber: 'MH12CV1047',
    licenseClass: 'Transport',
    licenseExpiry: DateTime(2026, 5, 16),
    completedTrips: 194,
    onTimePercentage: 92,
    safetyScore: 94,
    rating: 4.7,
    lastCheckIn: 'Assigned to CC-24052',
  ),
  AdminDriverManagementMock(
    id: 'DRV-121',
    name: 'Kiran Pawar',
    username: 'kiran.pawar',
    email: 'kiran.pawar@cargoconnect.example',
    phone: '+91 97662 11890',
    address: 'Sector 17, Vashi, Navi Mumbai, Maharashtra',
    temporaryPassword: 'Cargo@240121',
    zone: 'Navi Mumbai',
    assignedVehicle: 'Pickup Van A12',
    status: 'Active',
    availability: 'Available',
    licenseNumber: 'MH04LM7720',
    licenseClass: 'LMV',
    licenseExpiry: DateTime(2026, 5, 3),
    completedTrips: 173,
    onTimePercentage: 94,
    safetyScore: 96,
    rating: 4.6,
    lastCheckIn: 'Ready for next dispatch',
  ),
  AdminDriverManagementMock(
    id: 'DRV-132',
    name: 'Sana Sheikh',
    username: 'sana.sheikh',
    email: 'sana.sheikh@cargoconnect.example',
    phone: '+91 97022 44108',
    address: 'Azadpur Staff Housing, Delhi North, Delhi',
    temporaryPassword: 'Cargo@240132',
    zone: 'Delhi North',
    assignedVehicle: 'Reefer Van C04',
    status: 'Inactive',
    availability: 'Offline',
    licenseNumber: 'DL01RF8812',
    licenseClass: 'Transport',
    licenseExpiry: DateTime(2026, 12, 11),
    completedTrips: 88,
    onTimePercentage: 91,
    safetyScore: 95,
    rating: 4.5,
    lastCheckIn: 'Roster hold for medical leave',
  ),
  AdminDriverManagementMock(
    id: 'DRV-147',
    name: 'Ravi Naik',
    username: 'ravi.naik',
    email: 'ravi.naik@cargoconnect.example',
    phone: '+91 98220 77144',
    address: 'Fleet Quarters, Andheri East, Mumbai, Maharashtra',
    temporaryPassword: 'Cargo@240147',
    zone: 'Mumbai to Bengaluru',
    assignedVehicle: 'Container Truck C16',
    status: 'Active',
    availability: 'On Leave',
    licenseNumber: 'KA51GT6630',
    licenseClass: 'HMV',
    licenseExpiry: DateTime(2026, 9, 28),
    completedTrips: 321,
    onTimePercentage: 97,
    safetyScore: 99,
    rating: 4.9,
    lastCheckIn: 'Planned leave until Apr 30',
  ),
  AdminDriverManagementMock(
    id: 'DRV-151',
    name: 'Nikhil Jain',
    username: 'nikhil.jain',
    email: 'nikhil.jain@cargoconnect.example',
    phone: '+91 94440 12678',
    address: 'Chromepet Transport Nagar, Chennai, Tamil Nadu',
    temporaryPassword: 'Cargo@240151',
    zone: 'Chennai South',
    assignedVehicle: 'Mini Truck B07',
    status: 'Suspended',
    availability: 'Offline',
    licenseNumber: 'TN09LG3314',
    licenseClass: 'Transport',
    licenseExpiry: DateTime(2026, 4, 12),
    completedTrips: 134,
    onTimePercentage: 86,
    safetyScore: 82,
    rating: 4.1,
    lastCheckIn: 'Awaiting compliance renewal',
  ),
  AdminDriverManagementMock(
    id: 'DRV-163',
    name: 'Mehul Dutta',
    username: 'mehul.dutta',
    email: 'mehul.dutta@cargoconnect.example',
    phone: '+91 90990 33011',
    address: 'Naroda Ring Road, Ahmedabad, Gujarat',
    temporaryPassword: 'Cargo@240163',
    zone: 'Ahmedabad Ring Road',
    assignedVehicle: 'Mini Truck G11',
    status: 'Active',
    availability: 'Available',
    licenseNumber: 'GJ01MC4542',
    licenseClass: 'LMV',
    licenseExpiry: DateTime(2027, 1, 20),
    completedTrips: 67,
    onTimePercentage: 89,
    safetyScore: 93,
    rating: 4.4,
    lastCheckIn: 'Waiting in yard lane 3',
  ),
  AdminDriverManagementMock(
    id: 'DRV-176',
    name: 'Pooja Soman',
    username: 'pooja.soman',
    email: 'pooja.soman@cargoconnect.example',
    phone: '+91 91161 22770',
    address: 'VKI Driver Housing, Jaipur, Rajasthan',
    temporaryPassword: 'Cargo@240176',
    zone: 'Jaipur Retail Belt',
    assignedVehicle: 'Reefer Van J21',
    status: 'Active',
    availability: 'On Trip',
    licenseNumber: 'RJ14HZ9904',
    licenseClass: 'Hazmat',
    licenseExpiry: DateTime(2026, 5, 28),
    completedTrips: 212,
    onTimePercentage: 95,
    safetyScore: 97,
    rating: 4.8,
    lastCheckIn: 'Cold-chain delivery in progress',
  ),
];

final adminVehicleManagementRows = [
  AdminVehicleManagementMock(
    id: 'VEH-220',
    vehicleNumber: 'CC-PV-A12',
    type: 'Pickup Van',
    capacity: '1 ton',
    model: 'Tata Ace Gold',
    fuelType: 'Diesel',
    registration: 'MH 04 HX 2210',
    insuranceExpiry: DateTime(2027, 2, 18),
    serviceDue: DateTime(2026, 5, 20),
    availability: 'Available',
    assignedDriver: 'Unassigned',
    assignedTrip: null,
    hub: 'Navi Mumbai Yard',
    odometer: '42,810 km',
    lastInspection: 'Apr 12, 2026',
    notes: 'Clean cargo bay. Keep available for parcel and light goods.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-231',
    vehicleNumber: 'CC-TR-T19',
    type: '14 ft Truck',
    capacity: '4 tons',
    model: 'Ashok Leyland Dost Plus',
    fuelType: 'Diesel',
    registration: 'MH 14 GT 7712',
    insuranceExpiry: DateTime(2026, 11, 24),
    serviceDue: DateTime(2026, 5, 8),
    availability: 'Busy',
    assignedDriver: 'Amit Verma',
    assignedTrip: 'CC-24052',
    hub: 'Pune Corridor',
    odometer: '88,420 km',
    lastInspection: 'Apr 02, 2026',
    notes: 'Hydraulic lift checked. Assigned to active heavy cargo route.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-238',
    vehicleNumber: 'CC-MT-B07',
    type: 'Mini Truck',
    capacity: '2 tons',
    model: 'Mahindra Supro Maxitruck',
    fuelType: 'Diesel',
    registration: 'MH 12 CT 0934',
    insuranceExpiry: DateTime(2027, 1, 9),
    serviceDue: DateTime(2026, 6, 4),
    availability: 'Available',
    assignedDriver: 'Mehul Dutta',
    assignedTrip: null,
    hub: 'Ahmedabad Ring Road',
    odometer: '35,120 km',
    lastInspection: 'Apr 18, 2026',
    notes: 'Tyres replaced this month. Ready for city distribution.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-244',
    vehicleNumber: 'CC-RF-C04',
    type: 'Reefer Van',
    capacity: '1.5 tons',
    model: 'Eicher Pro 2049 Reefer',
    fuelType: 'Diesel',
    registration: 'DL 01 RF 4480',
    insuranceExpiry: DateTime(2026, 8, 16),
    serviceDue: DateTime(2026, 4, 30),
    availability: 'Maintenance',
    assignedDriver: 'Unassigned',
    assignedTrip: null,
    hub: 'Delhi North Cold Hub',
    odometer: '51,880 km',
    lastInspection: 'Mar 28, 2026',
    notes: 'Temperature unit calibration due before next refrigerated trip.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-252',
    vehicleNumber: 'CC-OT-R08',
    type: 'Open Truck',
    capacity: '5 tons',
    model: 'BharatBenz 1015R',
    fuelType: 'Diesel',
    registration: 'MH 12 CV 1047',
    insuranceExpiry: DateTime(2026, 10, 5),
    serviceDue: DateTime(2026, 5, 14),
    availability: 'Busy',
    assignedDriver: 'Farhan Ali',
    assignedTrip: 'CC-24061',
    hub: 'Bhiwandi Hub',
    odometer: '73,460 km',
    lastInspection: 'Apr 08, 2026',
    notes: 'Open bed inspected. Tarpaulin kit stored behind cabin.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-266',
    vehicleNumber: 'CC-CT-C16',
    type: 'Container Truck',
    capacity: '8 tons',
    model: 'Tata Signa 2823.T',
    fuelType: 'Diesel',
    registration: 'KA 51 GT 6630',
    insuranceExpiry: DateTime(2027, 3, 12),
    serviceDue: DateTime(2026, 7, 2),
    availability: 'On Leave',
    assignedDriver: 'Ravi Naik',
    assignedTrip: null,
    hub: 'Mumbai Long Haul',
    odometer: '118,900 km',
    lastInspection: 'Apr 01, 2026',
    notes: 'Long-haul unit on planned driver leave hold.',
  ),
  AdminVehicleManagementMock(
    id: 'VEH-271',
    vehicleNumber: 'CC-RF-J21',
    type: 'Reefer Van',
    capacity: '1.8 tons',
    model: 'Force Traveller Reefer',
    fuelType: 'CNG',
    registration: 'RJ 14 HZ 9904',
    insuranceExpiry: DateTime(2026, 12, 28),
    serviceDue: DateTime(2026, 5, 28),
    availability: 'Busy',
    assignedDriver: 'Pooja Soman',
    assignedTrip: 'CC-24077',
    hub: 'Jaipur Retail Belt',
    odometer: '29,640 km',
    lastInspection: 'Apr 20, 2026',
    notes: 'Cold-chain vehicle currently assigned to dairy delivery.',
  ),
];

final adminCustomerManagementRows = [
  AdminCustomerManagementMock(
    id: 'CUS-1024',
    name: 'Priya Menon',
    email: 'priya.menon@example.com',
    phone: '+91 98765 41021',
    totalShipments: 18,
    status: 'Active',
    registeredDate: DateTime(2025, 8, 14),
    address: 'Nerul Sector 19, Navi Mumbai, Maharashtra',
    lastShipmentId: 'CC-24061',
    preferredCategory: 'Medium Goods',
    lifetimeValue: 'INR 68,420',
    openIssues: 0,
    lastActivity: 'Booked shipment CC-24061 today',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1048',
    name: 'Dev Logistics',
    email: 'ops@devlogistics.example',
    phone: '+91 99880 66331',
    totalShipments: 86,
    status: 'Active',
    registeredDate: DateTime(2024, 11, 5),
    address: 'Bhiwandi Logistics Hub, Gate 3, Maharashtra',
    lastShipmentId: 'CC-24052',
    preferredCategory: 'Heavy Cargo',
    lifetimeValue: 'INR 8.4L',
    openIssues: 1,
    lastActivity: 'Driver accepted active trip',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1082',
    name: 'Kavya Srinivasan',
    email: 'kavya.s@example.com',
    phone: '+91 98451 77320',
    totalShipments: 27,
    status: 'Active',
    registeredDate: DateTime(2025, 2, 20),
    address: 'Andheri East, Mumbai, Maharashtra',
    lastShipmentId: 'CC-24031',
    preferredCategory: 'Urgent',
    lifetimeValue: 'INR 1.8L',
    openIssues: 0,
    lastActivity: 'Tracking in-transit shipment',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1120',
    name: 'Meera Kapoor',
    email: 'meera.k@example.com',
    phone: '+91 97001 88342',
    totalShipments: 9,
    status: 'Inactive',
    registeredDate: DateTime(2025, 12, 2),
    address: 'Kukatpally, Hyderabad, Telangana',
    lastShipmentId: 'CC-24044',
    preferredCategory: 'Fragile',
    lifetimeValue: 'INR 34,860',
    openIssues: 2,
    lastActivity: 'Support request pending review',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1177',
    name: 'North Fresh Foods',
    email: 'dispatch@northfresh.example',
    phone: '+91 90110 55012',
    totalShipments: 142,
    status: 'Active',
    registeredDate: DateTime(2024, 6, 11),
    address: 'Azadpur Cold Storage, Delhi',
    lastShipmentId: 'CC-24077',
    preferredCategory: 'Refrigerated',
    lifetimeValue: 'INR 15.6L',
    openIssues: 0,
    lastActivity: 'Approved refrigerated shipment',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1213',
    name: 'Ankit Rao',
    email: 'ankit.rao@example.com',
    phone: '+91 94440 12678',
    totalShipments: 11,
    status: 'Blocked',
    registeredDate: DateTime(2025, 9, 18),
    address: 'T Nagar, Chennai, Tamil Nadu',
    lastShipmentId: 'CC-24018',
    preferredCategory: 'Small Parcel',
    lifetimeValue: 'INR 21,780',
    openIssues: 3,
    lastActivity: 'Payment dispute flagged by admin',
  ),
  AdminCustomerManagementMock(
    id: 'CUS-1264',
    name: 'Urban Furnishings',
    email: 'orders@urbanfurnish.example',
    phone: '+91 90990 33011',
    totalShipments: 54,
    status: 'Inactive',
    registeredDate: DateTime(2024, 3, 29),
    address: 'Narol Industrial Area, Ahmedabad, Gujarat',
    lastShipmentId: 'CC-24009',
    preferredCategory: 'Heavy Cargo',
    lifetimeValue: 'INR 4.2L',
    openIssues: 1,
    lastActivity: 'Cancelled shipment before dispatch',
  ),
];

final adminPaymentManagementRows = [
  AdminPaymentManagementMock(
    id: 'PAY-24061',
    shipmentId: 'CC-24061',
    customer: 'Priya Menon',
    amount: 'INR 2,950',
    method: 'UPI',
    status: 'Pending',
    date: DateTime(2026, 4, 29, 10, 45),
    dateFilter: 'Today',
    transactionReference: 'UPI-CC24061-1045',
    invoiceNumber: 'INV-24061',
    gateway: 'Razorpay mock',
    fee: 'INR 18',
    netAmount: 'INR 2,932',
    notes: 'Awaiting customer payment confirmation before dispatch.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24052',
    shipmentId: 'CC-24052',
    customer: 'Dev Logistics',
    amount: 'INR 4,120',
    method: 'Corporate Wallet',
    status: 'Paid',
    date: DateTime(2026, 4, 29, 10, 12),
    dateFilter: 'Today',
    transactionReference: 'WALLET-DEV-24052',
    invoiceNumber: 'INV-24052',
    gateway: 'CargoConnect Wallet',
    fee: 'INR 0',
    netAmount: 'INR 4,120',
    notes: 'Corporate Wallet balance debited successfully.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24031',
    shipmentId: 'CC-24031',
    customer: 'Kavya Srinivasan',
    amount: 'INR 6,850',
    method: 'Card',
    status: 'Paid',
    date: DateTime(2026, 4, 28, 16, 30),
    dateFilter: 'This Week',
    transactionReference: 'CARD-7713-24031',
    invoiceNumber: 'INV-24031',
    gateway: 'Stripe mock',
    fee: 'INR 126',
    netAmount: 'INR 6,724',
    notes: 'Priority shipment card payment captured.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24044',
    shipmentId: 'CC-24044',
    customer: 'Meera Kapoor',
    amount: 'INR 3,640',
    method: 'Cash on Delivery',
    status: 'Processing',
    date: DateTime(2026, 4, 28, 11, 5),
    dateFilter: 'This Week',
    transactionReference: 'COD-LOCK-24044',
    invoiceNumber: 'INV-24044',
    gateway: 'Manual COD',
    fee: 'INR 0',
    netAmount: 'INR 3,640',
    notes: 'COD collection will reconcile after delivery proof.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24077',
    shipmentId: 'CC-24077',
    customer: 'North Fresh Foods',
    amount: 'INR 8,420',
    method: 'Bank Transfer',
    status: 'Paid',
    date: DateTime(2026, 4, 27, 13, 20),
    dateFilter: 'This Week',
    transactionReference: 'NEFT-NFF-24077',
    invoiceNumber: 'INV-24077',
    gateway: 'Bank reconciliation',
    fee: 'INR 12',
    netAmount: 'INR 8,408',
    notes: 'Bank Transfer matched to invoice reference.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24018',
    shipmentId: 'CC-24018',
    customer: 'Ankit Rao',
    amount: 'INR 1,780',
    method: 'Wallet',
    status: 'Failed',
    date: DateTime(2026, 4, 26, 9, 45),
    dateFilter: 'This Week',
    transactionReference: 'WALLET-ERR-24018',
    invoiceNumber: 'INV-24018',
    gateway: 'CargoConnect Wallet',
    fee: 'INR 0',
    netAmount: 'INR 0',
    notes: 'Wallet authorization failed. Customer notified for retry.',
  ),
  AdminPaymentManagementMock(
    id: 'PAY-24009',
    shipmentId: 'CC-24009',
    customer: 'Urban Furnishings',
    amount: 'INR 0',
    method: 'Refund',
    status: 'Refunded',
    date: DateTime(2026, 4, 24, 18, 10),
    dateFilter: 'This Month',
    transactionReference: 'REF-URB-24009',
    invoiceNumber: 'INV-24009',
    gateway: 'Manual refund',
    fee: 'INR 0',
    netAmount: 'INR 0',
    notes: 'Cancelled before dispatch. Invoice voided and refund closed.',
  ),
];

final adminInvoiceManagementRows = [
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24061',
    shipmentId: 'CC-24061',
    customer: 'Priya Menon',
    total: 'INR 2,950',
    paymentStatus: 'Pending',
    generatedDate: DateTime(2026, 4, 29, 10, 50),
    dateFilter: 'Today',
    invoiceStatus: 'Draft',
    billingAddress: 'Nerul Sector 19, Navi Mumbai, Maharashtra',
    route: 'Navi Mumbai to Pune',
    packageSummary: 'Medium goods, 180 kg',
    baseCharge: 'INR 2,500',
    handlingFee: 'INR 200',
    tax: 'INR 250',
    discount: 'INR 0',
    paymentMethod: 'UPI',
    notes: 'Draft invoice generated while payment confirmation is pending.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24052',
    shipmentId: 'CC-24052',
    customer: 'Dev Logistics',
    total: 'INR 4,120',
    paymentStatus: 'Paid',
    generatedDate: DateTime(2026, 4, 29, 10, 18),
    dateFilter: 'Today',
    invoiceStatus: 'Issued',
    billingAddress: 'Bhiwandi Logistics Hub, Gate 3, Maharashtra',
    route: 'Bhiwandi to Thane',
    packageSummary: 'Heavy cargo, 1.4 tons',
    baseCharge: 'INR 3,500',
    handlingFee: 'INR 270',
    tax: 'INR 350',
    discount: 'INR 0',
    paymentMethod: 'Corporate Wallet',
    notes: 'Issued to corporate account after wallet payment capture.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24031',
    shipmentId: 'CC-24031',
    customer: 'Kavya Srinivasan',
    total: 'INR 6,850',
    paymentStatus: 'Paid',
    generatedDate: DateTime(2026, 4, 28, 16, 36),
    dateFilter: 'This Week',
    invoiceStatus: 'Issued',
    billingAddress: 'Andheri East, Mumbai, Maharashtra',
    route: 'Mumbai to Bengaluru',
    packageSummary: 'Urgent cartons, 420 kg',
    baseCharge: 'INR 5,900',
    handlingFee: 'INR 360',
    tax: 'INR 590',
    discount: 'INR 0',
    paymentMethod: 'Card',
    notes: 'Priority-lane invoice with card transaction reference attached.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24044',
    shipmentId: 'CC-24044',
    customer: 'Meera Kapoor',
    total: 'INR 3,640',
    paymentStatus: 'Processing',
    generatedDate: DateTime(2026, 4, 28, 11, 12),
    dateFilter: 'This Week',
    invoiceStatus: 'Draft',
    billingAddress: 'Kukatpally, Hyderabad, Telangana',
    route: 'Hyderabad to Vijayawada',
    packageSummary: 'Fragile fixtures, 95 kg',
    baseCharge: 'INR 2,950',
    handlingFee: 'INR 340',
    tax: 'INR 350',
    discount: 'INR 0',
    paymentMethod: 'Cash on Delivery',
    notes: 'COD invoice will be issued after delivery proof reconciliation.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24077',
    shipmentId: 'CC-24077',
    customer: 'North Fresh Foods',
    total: 'INR 8,420',
    paymentStatus: 'Paid',
    generatedDate: DateTime(2026, 4, 27, 13, 28),
    dateFilter: 'This Week',
    invoiceStatus: 'Issued',
    billingAddress: 'Azadpur Cold Storage, Delhi',
    route: 'Delhi to Jaipur',
    packageSummary: 'Refrigerated dairy crates, 760 kg',
    baseCharge: 'INR 7,200',
    handlingFee: 'INR 520',
    tax: 'INR 700',
    discount: 'INR 0',
    paymentMethod: 'Bank Transfer',
    notes: 'Cold-chain invoice includes refrigerated vehicle surcharge.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24018',
    shipmentId: 'CC-24018',
    customer: 'Ankit Rao',
    total: 'INR 1,780',
    paymentStatus: 'Failed',
    generatedDate: DateTime(2026, 4, 26, 9, 52),
    dateFilter: 'This Week',
    invoiceStatus: 'Draft',
    billingAddress: 'T Nagar, Chennai, Tamil Nadu',
    route: 'Chennai to Coimbatore',
    packageSummary: 'Small parcel documents, 8 kg',
    baseCharge: 'INR 1,450',
    handlingFee: 'INR 160',
    tax: 'INR 170',
    discount: 'INR 0',
    paymentMethod: 'Wallet',
    notes: 'Invoice held because wallet authorization failed.',
  ),
  AdminInvoiceManagementMock(
    invoiceNumber: 'INV-24009',
    shipmentId: 'CC-24009',
    customer: 'Urban Furnishings',
    total: 'INR 0',
    paymentStatus: 'Refunded',
    generatedDate: DateTime(2026, 4, 24, 18, 18),
    dateFilter: 'This Month',
    invoiceStatus: 'Voided',
    billingAddress: 'Narol Industrial Area, Ahmedabad, Gujarat',
    route: 'Ahmedabad to Surat',
    packageSummary: 'Furniture components, 1.1 tons',
    baseCharge: 'INR 0',
    handlingFee: 'INR 0',
    tax: 'INR 0',
    discount: 'INR 0',
    paymentMethod: 'Refund',
    notes: 'Invoice voided after cancellation before vehicle dispatch.',
  ),
];

const shipmentVolumePoints = [
  AdminChartPointMock(label: 'Mon', value: 42),
  AdminChartPointMock(label: 'Tue', value: 56),
  AdminChartPointMock(label: 'Wed', value: 48),
  AdminChartPointMock(label: 'Thu', value: 64),
  AdminChartPointMock(label: 'Fri', value: 72),
  AdminChartPointMock(label: 'Sat', value: 38),
  AdminChartPointMock(label: 'Sun', value: 44),
];

const revenueSummaryPoints = [
  AdminChartPointMock(label: 'Parcel', value: 2.8),
  AdminChartPointMock(label: 'Goods', value: 4.6),
  AdminChartPointMock(label: 'Cargo', value: 6.4),
  AdminChartPointMock(label: 'Cold', value: 3.6),
  AdminChartPointMock(label: 'Urgent', value: 2.2),
];

const adminReportCards = [
  AdminReportCardMock(
    title: 'Shipment report',
    metric: '1,284',
    delta: '+86 this month',
    description: 'Bookings, status movement, cancellations, and SLA outcomes.',
    status: 'Operational',
    icon: Icons.inventory_2_outlined,
    accentColor: AppColors.primaryBlue,
    isPositive: true,
  ),
  AdminReportCardMock(
    title: 'Driver report',
    metric: '115',
    delta: '96% on-time',
    description: 'Availability, trip acceptance, safety, and productivity.',
    status: 'Healthy',
    icon: Icons.badge_outlined,
    accentColor: AppColors.success,
    isPositive: true,
  ),
  AdminReportCardMock(
    title: 'Vehicle report',
    metric: '78%',
    delta: '+6.2% utilization',
    description: 'Fleet capacity, service due exposure, and assignment mix.',
    status: 'Watch service',
    icon: Icons.local_shipping_outlined,
    accentColor: AppColors.accentOrange,
    isPositive: true,
  ),
  AdminReportCardMock(
    title: 'Payment report',
    metric: 'INR 12.8L',
    delta: '+9.8% MTD',
    description: 'Collections, pending capture, failed payments, and refunds.',
    status: 'Finance',
    icon: Icons.payments_outlined,
    accentColor: AppColors.info,
    isPositive: true,
  ),
];

const reportPaymentStatusPoints = [
  AdminChartPointMock(label: 'Paid', value: 4.1),
  AdminChartPointMock(label: 'COD', value: 1.8),
  AdminChartPointMock(label: 'Pending', value: 0.9),
  AdminChartPointMock(label: 'Failed', value: 0.3),
  AdminChartPointMock(label: 'Refund', value: 0.2),
];

const paymentRevenueReportRows = [
  AdminPaymentRevenueReportMock(
    date: 'Apr 23',
    paidRevenue: 'INR 1.42L',
    pendingAmount: 'INR 0.22L',
    refundedAmount: 'INR 0.04L',
    transactions: 34,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 24',
    paidRevenue: 'INR 1.68L',
    pendingAmount: 'INR 0.31L',
    refundedAmount: 'INR 0.02L',
    transactions: 39,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 25',
    paidRevenue: 'INR 2.05L',
    pendingAmount: 'INR 0.28L',
    refundedAmount: 'INR 0.06L',
    transactions: 46,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 26',
    paidRevenue: 'INR 1.86L',
    pendingAmount: 'INR 0.44L',
    refundedAmount: 'INR 0.03L',
    transactions: 41,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 27',
    paidRevenue: 'INR 2.34L',
    pendingAmount: 'INR 0.36L',
    refundedAmount: 'INR 0.07L',
    transactions: 52,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 28',
    paidRevenue: 'INR 2.72L',
    pendingAmount: 'INR 0.49L',
    refundedAmount: 'INR 0.08L',
    transactions: 59,
  ),
  AdminPaymentRevenueReportMock(
    date: 'Apr 29',
    paidRevenue: 'INR 2.91L',
    pendingAmount: 'INR 0.38L',
    refundedAmount: 'INR 0.05L',
    transactions: 63,
  ),
];

const paymentMethodReportRows = [
  AdminPaymentMethodReportMock(
    method: 'UPI',
    transactions: 146,
    revenue: 'INR 4.10L',
    pendingAmount: 'INR 0.18L',
    successRate: '98%',
    settlementNote: 'T+1 settlement',
  ),
  AdminPaymentMethodReportMock(
    method: 'Card',
    transactions: 88,
    revenue: 'INR 3.72L',
    pendingAmount: 'INR 0.24L',
    successRate: '96%',
    settlementNote: 'Gateway captured',
  ),
  AdminPaymentMethodReportMock(
    method: 'Corporate Wallet',
    transactions: 52,
    revenue: 'INR 2.46L',
    pendingAmount: 'INR 0.12L',
    successRate: '99%',
    settlementNote: 'Monthly invoice linked',
  ),
  AdminPaymentMethodReportMock(
    method: 'Cash on Delivery',
    transactions: 47,
    revenue: 'INR 1.80L',
    pendingAmount: 'INR 0.64L',
    successRate: '91%',
    settlementNote: 'Driver remittance pending',
  ),
  AdminPaymentMethodReportMock(
    method: 'Bank Transfer',
    transactions: 26,
    revenue: 'INR 1.35L',
    pendingAmount: 'INR 0.18L',
    successRate: '94%',
    settlementNote: 'Manual reconciliation',
  ),
  AdminPaymentMethodReportMock(
    method: 'Wallet',
    transactions: 31,
    revenue: 'INR 0.92L',
    pendingAmount: 'INR 0.09L',
    successRate: '97%',
    settlementNote: 'Balance deducted',
  ),
];

const paymentStatusReportRows = [
  AdminPaymentStatusReportMock(
    status: 'Paid',
    count: 302,
    amount: 'INR 12.89L',
    share: '78%',
    action: 'Settled and invoice-ready',
  ),
  AdminPaymentStatusReportMock(
    status: 'Pending',
    count: 48,
    amount: 'INR 1.54L',
    share: '12%',
    action: 'Follow customer or COD remittance',
  ),
  AdminPaymentStatusReportMock(
    status: 'Processing',
    count: 21,
    amount: 'INR 0.72L',
    share: '5%',
    action: 'Await gateway callback',
  ),
  AdminPaymentStatusReportMock(
    status: 'Failed',
    count: 11,
    amount: 'INR 0.31L',
    share: '3%',
    action: 'Retry or customer notification',
  ),
  AdminPaymentStatusReportMock(
    status: 'Refunded',
    count: 8,
    amount: 'INR 0.35L',
    share: '2%',
    action: 'Refund confirmation logged',
  ),
];

const reportShipmentStatusPoints = [
  AdminChartPointMock(label: 'Pending', value: 37),
  AdminChartPointMock(label: 'Active', value: 128),
  AdminChartPointMock(label: 'Delivered', value: 912),
  AdminChartPointMock(label: 'Cancelled', value: 18),
];

const shipmentDateReportRows = [
  AdminShipmentDateReportMock(
    date: 'Apr 23',
    bookings: 38,
    approved: 32,
    inTransit: 18,
    delivered: 29,
    cancelled: 1,
    revenue: 'INR 1.8L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 24',
    bookings: 44,
    approved: 39,
    inTransit: 22,
    delivered: 31,
    cancelled: 2,
    revenue: 'INR 2.1L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 25',
    bookings: 51,
    approved: 43,
    inTransit: 25,
    delivered: 36,
    cancelled: 1,
    revenue: 'INR 2.6L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 26',
    bookings: 47,
    approved: 40,
    inTransit: 20,
    delivered: 35,
    cancelled: 3,
    revenue: 'INR 2.3L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 27',
    bookings: 56,
    approved: 49,
    inTransit: 28,
    delivered: 41,
    cancelled: 2,
    revenue: 'INR 3.0L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 28',
    bookings: 64,
    approved: 55,
    inTransit: 31,
    delivered: 47,
    cancelled: 4,
    revenue: 'INR 3.5L',
  ),
  AdminShipmentDateReportMock(
    date: 'Apr 29',
    bookings: 72,
    approved: 61,
    inTransit: 34,
    delivered: 52,
    cancelled: 2,
    revenue: 'INR 4.0L',
  ),
];

const shipmentStatusReportRows = [
  AdminShipmentStatusReportMock(
    status: 'Pending',
    count: 37,
    share: '3%',
    revenue: 'INR 1.1L',
    sla: 'Approval due',
  ),
  AdminShipmentStatusReportMock(
    status: 'Approved',
    count: 96,
    share: '7%',
    revenue: 'INR 4.8L',
    sla: 'Ready to assign',
  ),
  AdminShipmentStatusReportMock(
    status: 'Assigned',
    count: 58,
    share: '5%',
    revenue: 'INR 2.9L',
    sla: 'Driver pending',
  ),
  AdminShipmentStatusReportMock(
    status: 'In Transit',
    count: 128,
    share: '10%',
    revenue: 'INR 6.6L',
    sla: 'On route',
  ),
  AdminShipmentStatusReportMock(
    status: 'Delivered',
    count: 912,
    share: '71%',
    revenue: 'INR 42.4L',
    sla: 'Proof verified',
  ),
  AdminShipmentStatusReportMock(
    status: 'Cancelled',
    count: 18,
    share: '1%',
    revenue: 'INR 0',
    sla: 'Closed',
  ),
];

const shipmentCategoryReportRows = [
  AdminShipmentCategoryReportMock(
    category: 'Small Parcel',
    shipments: 248,
    averageWeight: '8 kg',
    revenue: 'INR 4.8L',
    topVehicle: 'Bike Courier',
  ),
  AdminShipmentCategoryReportMock(
    category: 'Medium Goods',
    shipments: 318,
    averageWeight: '165 kg',
    revenue: 'INR 9.4L',
    topVehicle: 'Pickup Van',
  ),
  AdminShipmentCategoryReportMock(
    category: 'Heavy Cargo',
    shipments: 186,
    averageWeight: '1.2 tons',
    revenue: 'INR 13.6L',
    topVehicle: '14 ft Truck',
  ),
  AdminShipmentCategoryReportMock(
    category: 'Refrigerated',
    shipments: 92,
    averageWeight: '640 kg',
    revenue: 'INR 7.8L',
    topVehicle: 'Reefer Van',
  ),
  AdminShipmentCategoryReportMock(
    category: 'Fragile',
    shipments: 126,
    averageWeight: '78 kg',
    revenue: 'INR 5.2L',
    topVehicle: 'Mini Truck',
  ),
  AdminShipmentCategoryReportMock(
    category: 'Urgent',
    shipments: 144,
    averageWeight: '240 kg',
    revenue: 'INR 6.9L',
    topVehicle: 'Container Truck',
  ),
];

const driverReportRows = [
  AdminDriverReportMock(
    id: 'DRV-104',
    name: 'Amit Verma',
    zone: 'Pune Corridor',
    status: 'Available',
    completedTrips: 42,
    acceptanceRate: 96,
    delays: 2,
    performanceScore: 98,
    emergencyCount: 0,
    onTimeRate: 96,
    rating: 4.8,
  ),
  AdminDriverReportMock(
    id: 'DRV-118',
    name: 'Farhan Ali',
    zone: 'Bhiwandi Hub',
    status: 'On Trip',
    completedTrips: 36,
    acceptanceRate: 93,
    delays: 4,
    performanceScore: 92,
    emergencyCount: 1,
    onTimeRate: 92,
    rating: 4.7,
  ),
  AdminDriverReportMock(
    id: 'DRV-121',
    name: 'Kiran Pawar',
    zone: 'Navi Mumbai',
    status: 'Available',
    completedTrips: 31,
    acceptanceRate: 91,
    delays: 3,
    performanceScore: 94,
    emergencyCount: 0,
    onTimeRate: 94,
    rating: 4.6,
  ),
  AdminDriverReportMock(
    id: 'DRV-132',
    name: 'Sana Sheikh',
    zone: 'Delhi North',
    status: 'Offline',
    completedTrips: 18,
    acceptanceRate: 88,
    delays: 2,
    performanceScore: 90,
    emergencyCount: 1,
    onTimeRate: 91,
    rating: 4.5,
  ),
  AdminDriverReportMock(
    id: 'DRV-147',
    name: 'Ravi Naik',
    zone: 'Mumbai to Bengaluru',
    status: 'On Leave',
    completedTrips: 49,
    acceptanceRate: 97,
    delays: 1,
    performanceScore: 99,
    emergencyCount: 0,
    onTimeRate: 97,
    rating: 4.9,
  ),
  AdminDriverReportMock(
    id: 'DRV-151',
    name: 'Nikhil Jain',
    zone: 'Chennai South',
    status: 'Offline',
    completedTrips: 16,
    acceptanceRate: 81,
    delays: 7,
    performanceScore: 82,
    emergencyCount: 2,
    onTimeRate: 86,
    rating: 4.1,
  ),
  AdminDriverReportMock(
    id: 'DRV-163',
    name: 'Mehul Dutta',
    zone: 'Ahmedabad Ring Road',
    status: 'Available',
    completedTrips: 24,
    acceptanceRate: 89,
    delays: 5,
    performanceScore: 88,
    emergencyCount: 1,
    onTimeRate: 89,
    rating: 4.4,
  ),
  AdminDriverReportMock(
    id: 'DRV-176',
    name: 'Pooja Soman',
    zone: 'Jaipur Retail Belt',
    status: 'On Trip',
    completedTrips: 39,
    acceptanceRate: 95,
    delays: 2,
    performanceScore: 96,
    emergencyCount: 0,
    onTimeRate: 95,
    rating: 4.8,
  ),
];

final vehicleReportRows = [
  AdminVehicleReportMock(
    id: 'VEH-220',
    vehicleNumber: 'CC-PV-A12',
    type: 'Pickup Van',
    availability: 'Available',
    utilization: 68,
    serviceDue: DateTime(2026, 5, 20),
    assignmentCount: 22,
    breakdownCount: 1,
    assignedDriver: 'Unassigned',
    assignedTrip: null,
    hub: 'Navi Mumbai Yard',
  ),
  AdminVehicleReportMock(
    id: 'VEH-231',
    vehicleNumber: 'CC-TR-T19',
    type: '14 ft Truck',
    availability: 'Busy',
    utilization: 86,
    serviceDue: DateTime(2026, 5, 8),
    assignmentCount: 34,
    breakdownCount: 2,
    assignedDriver: 'Amit Verma',
    assignedTrip: 'CC-24052',
    hub: 'Pune Corridor',
  ),
  AdminVehicleReportMock(
    id: 'VEH-238',
    vehicleNumber: 'CC-MT-B07',
    type: 'Mini Truck',
    availability: 'Available',
    utilization: 74,
    serviceDue: DateTime(2026, 6, 4),
    assignmentCount: 27,
    breakdownCount: 0,
    assignedDriver: 'Mehul Dutta',
    assignedTrip: null,
    hub: 'Ahmedabad Ring Road',
  ),
  AdminVehicleReportMock(
    id: 'VEH-244',
    vehicleNumber: 'CC-RF-C04',
    type: 'Reefer Van',
    availability: 'Maintenance',
    utilization: 62,
    serviceDue: DateTime(2026, 5, 3),
    assignmentCount: 18,
    breakdownCount: 3,
    assignedDriver: 'Sana Sheikh',
    assignedTrip: null,
    hub: 'Delhi North',
  ),
  AdminVehicleReportMock(
    id: 'VEH-252',
    vehicleNumber: 'CC-OT-R08',
    type: 'Open Truck',
    availability: 'Busy',
    utilization: 82,
    serviceDue: DateTime(2026, 5, 14),
    assignmentCount: 31,
    breakdownCount: 1,
    assignedDriver: 'Farhan Ali',
    assignedTrip: 'CC-24061',
    hub: 'Bhiwandi Hub',
  ),
  AdminVehicleReportMock(
    id: 'VEH-266',
    vehicleNumber: 'CC-CT-C16',
    type: 'Container Truck',
    availability: 'On Leave',
    utilization: 79,
    serviceDue: DateTime(2026, 7, 2),
    assignmentCount: 29,
    breakdownCount: 0,
    assignedDriver: 'Ravi Naik',
    assignedTrip: null,
    hub: 'Mumbai Long Haul',
  ),
  AdminVehicleReportMock(
    id: 'VEH-271',
    vehicleNumber: 'CC-RF-J21',
    type: 'Reefer Van',
    availability: 'Busy',
    utilization: 71,
    serviceDue: DateTime(2026, 5, 28),
    assignmentCount: 24,
    breakdownCount: 1,
    assignedDriver: 'Pooja Soman',
    assignedTrip: 'CC-24077',
    hub: 'Jaipur Retail Belt',
  ),
];

const vehicleAssignmentHistoryRows = [
  AdminVehicleAssignmentHistoryReportMock(
    date: 'Apr 29',
    vehicleNumber: 'CC-TR-T19',
    tripId: 'CC-24052',
    driver: 'Amit Verma',
    route: 'Bhiwandi to Thane',
    status: 'In Transit',
    duration: '4h 20m',
  ),
  AdminVehicleAssignmentHistoryReportMock(
    date: 'Apr 29',
    vehicleNumber: 'CC-OT-R08',
    tripId: 'CC-24061',
    driver: 'Farhan Ali',
    route: 'Navi Mumbai to Pune',
    status: 'Assigned',
    duration: '3h 45m',
  ),
  AdminVehicleAssignmentHistoryReportMock(
    date: 'Apr 28',
    vehicleNumber: 'CC-CT-C16',
    tripId: 'CC-24031',
    driver: 'Ravi Naik',
    route: 'Mumbai to Bengaluru',
    status: 'Delivered',
    duration: '18h 10m',
  ),
  AdminVehicleAssignmentHistoryReportMock(
    date: 'Apr 28',
    vehicleNumber: 'CC-MT-B07',
    tripId: 'CC-24044',
    driver: 'Mehul Dutta',
    route: 'Hyderabad to Vijayawada',
    status: 'Completed',
    duration: '6h 05m',
  ),
  AdminVehicleAssignmentHistoryReportMock(
    date: 'Apr 27',
    vehicleNumber: 'CC-RF-J21',
    tripId: 'CC-24077',
    driver: 'Pooja Soman',
    route: 'Delhi to Jaipur',
    status: 'In Transit',
    duration: '7h 40m',
  ),
];

const vehicleBreakdownReportRows = [
  AdminVehicleBreakdownReportMock(
    date: 'Apr 28',
    vehicleNumber: 'CC-RF-C04',
    issue: 'Cooling unit inspection',
    severity: 'High',
    downtime: '9h',
    status: 'Maintenance',
  ),
  AdminVehicleBreakdownReportMock(
    date: 'Apr 26',
    vehicleNumber: 'CC-TR-T19',
    issue: 'Hydraulic lift calibration',
    severity: 'Medium',
    downtime: '3h',
    status: 'Resolved',
  ),
  AdminVehicleBreakdownReportMock(
    date: 'Apr 25',
    vehicleNumber: 'CC-OT-R08',
    issue: 'Brake pad replacement',
    severity: 'Medium',
    downtime: '4h',
    status: 'Resolved',
  ),
  AdminVehicleBreakdownReportMock(
    date: 'Apr 24',
    vehicleNumber: 'CC-PV-A12',
    issue: 'Cargo bay latch repair',
    severity: 'Low',
    downtime: '1h',
    status: 'Resolved',
  ),
  AdminVehicleBreakdownReportMock(
    date: 'Apr 22',
    vehicleNumber: 'CC-RF-J21',
    issue: 'Temperature sensor check',
    severity: 'Low',
    downtime: '2h',
    status: 'Resolved',
  ),
];

const driverUtilizationPoints = [
  AdminChartPointMock(label: 'Avail', value: 42),
  AdminChartPointMock(label: 'Busy', value: 73),
  AdminChartPointMock(label: 'Break', value: 9),
  AdminChartPointMock(label: 'Offline', value: 16),
];

const vehicleUtilizationPoints = [
  AdminChartPointMock(label: 'Mini', value: 68),
  AdminChartPointMock(label: 'Pickup', value: 74),
  AdminChartPointMock(label: 'Truck', value: 86),
  AdminChartPointMock(label: 'Reefer', value: 62),
  AdminChartPointMock(label: 'Trailer', value: 79),
];

const adminRecentActivities = [
  AdminRecentActivityMock(
    time: '10:45 AM',
    activity: 'Shipment assigned',
    reference: 'CC-24061',
    owner: 'Amit Verma',
    status: 'Assigned',
    amount: 'INR 2,950',
  ),
  AdminRecentActivityMock(
    time: '10:28 AM',
    activity: 'Driver accepted trip',
    reference: 'CC-24052',
    owner: 'Arjun Sharma',
    status: 'Accepted',
    amount: 'INR 4,120',
  ),
  AdminRecentActivityMock(
    time: '09:56 AM',
    activity: 'Pickup completed',
    reference: 'CC-24031',
    owner: 'Kavya S.',
    status: 'In Transit',
    amount: 'INR 6,850',
  ),
  AdminRecentActivityMock(
    time: '09:12 AM',
    activity: 'Invoice paid',
    reference: 'INV-1048',
    owner: 'Dev Logistics',
    status: 'Paid',
    amount: 'INR 18,200',
  ),
  AdminRecentActivityMock(
    time: '08:40 AM',
    activity: 'Shipment cancelled',
    reference: 'CC-24044',
    owner: 'Meera K.',
    status: 'Cancelled',
    amount: 'INR 0',
  ),
  AdminRecentActivityMock(
    time: '08:05 AM',
    activity: 'Delivery confirmed',
    reference: 'CC-24009',
    owner: 'Ravi Naik',
    status: 'Delivered',
    amount: 'INR 3,640',
  ),
];

const adminShipmentManagementRows = [
  AdminShipmentManagementMock(
    id: 'CC-24061',
    customer: 'Priya Menon',
    category: 'Medium Goods',
    route: 'Navi Mumbai to Pune',
    pickupDate: 'Apr 28, 2026',
    dateFilter: 'Today',
    driver: 'Amit Verma',
    status: 'Pending',
    vehicle: 'Pickup Van',
    amount: 'INR 2,950',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24052',
    customer: 'Dev Logistics',
    category: 'Heavy Cargo',
    route: 'Bhiwandi to Thane',
    pickupDate: 'Apr 28, 2026',
    dateFilter: 'Today',
    driver: 'Arjun Sharma',
    status: 'Accepted',
    vehicle: '14 ft Truck',
    amount: 'INR 4,120',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24031',
    customer: 'Kavya Srinivasan',
    category: 'Urgent',
    route: 'Mumbai to Bengaluru',
    pickupDate: 'Apr 29, 2026',
    dateFilter: 'This Week',
    driver: 'Ravi Naik',
    status: 'In Transit',
    vehicle: 'Container Truck',
    amount: 'INR 6,850',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24044',
    customer: 'Meera Kapoor',
    category: 'Fragile',
    route: 'Hyderabad to Vijayawada',
    pickupDate: 'Apr 30, 2026',
    dateFilter: 'This Week',
    driver: 'Unassigned',
    status: 'Pending',
    vehicle: 'Mini Truck',
    amount: 'INR 3,640',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24077',
    customer: 'North Fresh Foods',
    category: 'Refrigerated',
    route: 'Delhi to Jaipur',
    pickupDate: 'May 02, 2026',
    dateFilter: 'This Month',
    driver: 'Suresh Kumar',
    status: 'Approved',
    vehicle: 'Reefer Van',
    amount: 'INR 8,420',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24018',
    customer: 'Ankit Rao',
    category: 'Small Parcel',
    route: 'Chennai to Coimbatore',
    pickupDate: 'Apr 26, 2026',
    dateFilter: 'Past',
    driver: 'Nikhil Jain',
    status: 'Delivered',
    vehicle: 'Bike Courier',
    amount: 'INR 1,780',
  ),
  AdminShipmentManagementMock(
    id: 'CC-24009',
    customer: 'Urban Furnishings',
    category: 'Heavy Cargo',
    route: 'Ahmedabad to Surat',
    pickupDate: 'Apr 24, 2026',
    dateFilter: 'Past',
    driver: 'Mahesh Patil',
    status: 'Cancelled',
    vehicle: 'Open Truck',
    amount: 'INR 0',
  ),
];

const adminShipmentDetails = [
  AdminShipmentDetailMock(
    id: 'CC-24061',
    customerName: 'Priya Menon',
    customerEmail: 'priya.menon@example.com',
    customerPhone: '+91 98765 41021',
    receiverName: 'Rahul Deshmukh',
    receiverPhone: '+91 98220 77144',
    pickupAddress: 'Warehouse 7, MIDC Road, Navi Mumbai, Maharashtra',
    deliveryAddress: 'Baner Business Park, Pune, Maharashtra',
    packageType: 'Boxed industrial components',
    weight: '180 kg',
    dimensions: '5 ft x 4 ft x 3 ft',
    paymentMethod: 'UPI',
    paymentStatus: 'Pending',
    invoiceNumber: 'INV-24061',
    invoiceStatus: 'Draft',
    adminNotes: 'Customer requested morning pickup and covered loading bay.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24052',
    customerName: 'Dev Logistics',
    customerEmail: 'ops@devlogistics.example',
    customerPhone: '+91 99880 66331',
    receiverName: 'Aarav Mehta',
    receiverPhone: '+91 97654 12008',
    pickupAddress: 'Bhiwandi Logistics Hub, Gate 3, Maharashtra',
    deliveryAddress: 'Wagle Estate, Thane West, Maharashtra',
    packageType: 'Palletized manufacturing goods',
    weight: '1.4 tons',
    dimensions: '8 ft x 5 ft x 5 ft',
    paymentMethod: 'Corporate Wallet',
    paymentStatus: 'Paid',
    invoiceNumber: 'INV-24052',
    invoiceStatus: 'Issued',
    adminNotes: 'Forklift required at pickup. Receiver has dock access.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24031',
    customerName: 'Kavya Srinivasan',
    customerEmail: 'kavya.s@example.com',
    customerPhone: '+91 98451 77320',
    receiverName: 'Nandan Rao',
    receiverPhone: '+91 98860 43117',
    pickupAddress: 'Andheri East, Mumbai, Maharashtra',
    deliveryAddress: 'Electronic City Phase 2, Bengaluru, Karnataka',
    packageType: 'Urgent sealed cartons',
    weight: '420 kg',
    dimensions: '6 ft x 4 ft x 4 ft',
    paymentMethod: 'Card',
    paymentStatus: 'Paid',
    invoiceNumber: 'INV-24031',
    invoiceStatus: 'Issued',
    adminNotes: 'Priority lane. Driver to call receiver 30 minutes before ETA.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24044',
    customerName: 'Meera Kapoor',
    customerEmail: 'meera.k@example.com',
    customerPhone: '+91 97001 88342',
    receiverName: 'Sanjay Nair',
    receiverPhone: '+91 97002 44389',
    pickupAddress: 'Kukatpally, Hyderabad, Telangana',
    deliveryAddress: 'Auto Nagar, Vijayawada, Andhra Pradesh',
    packageType: 'Fragile glass fixtures',
    weight: '95 kg',
    dimensions: '4 ft x 3 ft x 3 ft',
    paymentMethod: 'Cash on Delivery',
    paymentStatus: 'Pending',
    invoiceNumber: 'INV-24044',
    invoiceStatus: 'Draft',
    adminNotes: 'Requires careful handling and additional packing check.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24077',
    customerName: 'North Fresh Foods',
    customerEmail: 'dispatch@northfresh.example',
    customerPhone: '+91 90110 55012',
    receiverName: 'Jaipur Retail Depot',
    receiverPhone: '+91 91161 22770',
    pickupAddress: 'Azadpur Cold Storage, Delhi',
    deliveryAddress: 'VKI Area, Jaipur, Rajasthan',
    packageType: 'Refrigerated dairy crates',
    weight: '760 kg',
    dimensions: '7 ft x 5 ft x 4 ft',
    paymentMethod: 'Bank Transfer',
    paymentStatus: 'Paid',
    invoiceNumber: 'INV-24077',
    invoiceStatus: 'Issued',
    adminNotes: 'Maintain 2-6 C temperature range during transit.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24018',
    customerName: 'Ankit Rao',
    customerEmail: 'ankit.rao@example.com',
    customerPhone: '+91 94440 12678',
    receiverName: 'S. Balaji',
    receiverPhone: '+91 94441 33990',
    pickupAddress: 'T Nagar, Chennai, Tamil Nadu',
    deliveryAddress: 'RS Puram, Coimbatore, Tamil Nadu',
    packageType: 'Small parcel documents',
    weight: '8 kg',
    dimensions: '18 in x 12 in x 8 in',
    paymentMethod: 'Wallet',
    paymentStatus: 'Paid',
    invoiceNumber: 'INV-24018',
    invoiceStatus: 'Issued',
    adminNotes: 'Delivered and proof verified by operations.',
  ),
  AdminShipmentDetailMock(
    id: 'CC-24009',
    customerName: 'Urban Furnishings',
    customerEmail: 'orders@urbanfurnish.example',
    customerPhone: '+91 90990 33011',
    receiverName: 'Surat Retail Unit',
    receiverPhone: '+91 90991 44022',
    pickupAddress: 'Narol Industrial Area, Ahmedabad, Gujarat',
    deliveryAddress: 'Ring Road Market, Surat, Gujarat',
    packageType: 'Furniture components',
    weight: '1.1 tons',
    dimensions: '9 ft x 6 ft x 5 ft',
    paymentMethod: 'Refund Pending',
    paymentStatus: 'Cancelled',
    invoiceNumber: 'INV-24009',
    invoiceStatus: 'Voided',
    adminNotes: 'Cancelled by customer before vehicle dispatch.',
  ),
];

const adminDriverAssignmentOptions = [
  AdminDriverAssignmentMock(
    id: 'DRV-102',
    name: 'Rohit Kulkarni',
    phone: '+91 98112 44029',
    zone: 'Mumbai West',
    rating: '4.8',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminDriverAssignmentMock(
    id: 'DRV-118',
    name: 'Farhan Ali',
    phone: '+91 98110 88421',
    zone: 'Pune Expressway',
    rating: '4.7',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminDriverAssignmentMock(
    id: 'DRV-121',
    name: 'Kiran Pawar',
    phone: '+91 97662 11890',
    zone: 'Navi Mumbai',
    rating: '4.6',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminDriverAssignmentMock(
    id: 'DRV-104',
    name: 'Amit Verma',
    phone: '+91 98881 22440',
    zone: 'Pune',
    rating: '4.5',
    status: 'Busy',
    currentShipmentId: 'CC-24061',
  ),
];

const adminVehicleAssignmentOptions = [
  AdminVehicleAssignmentMock(
    id: 'VEH-220',
    label: 'Pickup Van A12',
    type: 'Pickup Van',
    registration: 'MH 04 HX 2210',
    capacity: '1 ton',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminVehicleAssignmentMock(
    id: 'VEH-238',
    label: 'Mini Truck B07',
    type: 'Mini Truck',
    registration: 'MH 12 CT 0934',
    capacity: '2 tons',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminVehicleAssignmentMock(
    id: 'VEH-244',
    label: 'Reefer Van C04',
    type: 'Reefer Van',
    registration: 'DL 01 RF 4480',
    capacity: '1.5 tons',
    status: 'Available',
    currentShipmentId: null,
  ),
  AdminVehicleAssignmentMock(
    id: 'VEH-231',
    label: '14 ft Truck T19',
    type: '14 ft Truck',
    registration: 'MH 14 GT 7712',
    capacity: '4 tons',
    status: 'Busy',
    currentShipmentId: 'CC-24052',
  ),
];
