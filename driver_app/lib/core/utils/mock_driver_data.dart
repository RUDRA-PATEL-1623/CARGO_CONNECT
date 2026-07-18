class DriverTripMock {
  const DriverTripMock({
    required this.id,
    required this.status,
    required this.pickup,
    required this.delivery,
    required this.package,
    required this.vehicle,
    required this.distance,
    required this.eta,
    required this.payout,
    required this.window,
    this.assignmentId,
    this.shipmentId,
    this.vehicleId,
  });

  final String id;
  final String status;
  final String pickup;
  final String delivery;
  final String package;
  final String vehicle;
  final String distance;
  final String eta;
  final String payout;
  final String window;
  final int? assignmentId;
  final int? shipmentId;
  final int? vehicleId;
}

class DriverTimelineMock {
  const DriverTimelineMock({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.state,
  });

  final String title;
  final String subtitle;
  final String time;
  final DriverTimelineState state;
}

enum DriverTimelineState { completed, current, pending }

const activeDriverTrip = DriverTripMock(
  id: 'CC-24031',
  status: 'In Transit',
  pickup: 'BKC Logistics Park, Mumbai',
  delivery: 'Whitefield Distribution Hub, Bengaluru',
  package: '24 kg appliance cartons',
  vehicle: '14 ft closed truck',
  distance: '984 km',
  eta: 'Today, 8:45 PM',
  payout: 'INR 6,850',
  window: 'Pickup completed at 10:42 AM',
);

const assignedDriverTrips = [
  activeDriverTrip,
  DriverTripMock(
    id: 'CC-24044',
    status: 'Assigned',
    pickup: 'Navi Mumbai Cold Storage',
    delivery: 'Pune Fresh Hub',
    package: 'Refrigerated dairy crates',
    vehicle: 'Reefer mini truck',
    distance: '152 km',
    eta: 'Tomorrow, 7:30 AM',
    payout: 'INR 2,950',
    window: 'Pickup window 6:00 AM - 7:00 AM',
  ),
  DriverTripMock(
    id: 'CC-24052',
    status: 'Accepted',
    pickup: 'Andheri Electronics Market',
    delivery: 'Surat Retail Depot',
    package: 'Fragile electronics',
    vehicle: 'Covered pickup',
    distance: '284 km',
    eta: 'Apr 30, 5:15 PM',
    payout: 'INR 4,120',
    window: 'Receiver verification required',
  ),
];

const completedDriverTrips = [
  DriverTripMock(
    id: 'CC-24018',
    status: 'Completed',
    pickup: 'Chennai Port Warehouse',
    delivery: 'Coimbatore Textile Park',
    package: 'Medium goods',
    vehicle: '17 ft truck',
    distance: '508 km',
    eta: 'Delivered Apr 27, 2026',
    payout: 'INR 5,780',
    window: 'Proof verified by admin',
  ),
  DriverTripMock(
    id: 'CC-24009',
    status: 'Delivered',
    pickup: 'Hyderabad Pharma Hub',
    delivery: 'Vijayawada Medical Stores',
    package: 'Urgent medical cartons',
    vehicle: 'Insulated van',
    distance: '276 km',
    eta: 'Delivered Apr 25, 2026',
    payout: 'INR 3,640',
    window: 'Invoice pending review',
  ),
];

const activeTripTimeline = [
  DriverTimelineMock(
    title: 'Assigned',
    subtitle: 'Fleet desk assigned CC-24031 to you.',
    time: '08:20 AM',
    state: DriverTimelineState.completed,
  ),
  DriverTimelineMock(
    title: 'Accepted',
    subtitle: 'You accepted the trip and confirmed vehicle readiness.',
    time: '08:27 AM',
    state: DriverTimelineState.completed,
  ),
  DriverTimelineMock(
    title: 'Pickup completed',
    subtitle: 'Pickup proof placeholder is ready for upload review.',
    time: '10:42 AM',
    state: DriverTimelineState.completed,
  ),
  DriverTimelineMock(
    title: 'In transit',
    subtitle: 'Live location integration will be connected later.',
    time: 'Now',
    state: DriverTimelineState.current,
  ),
  DriverTimelineMock(
    title: 'Delivered',
    subtitle: 'Delivery proof and customer verification will appear here.',
    time: 'Pending',
    state: DriverTimelineState.pending,
  ),
];
