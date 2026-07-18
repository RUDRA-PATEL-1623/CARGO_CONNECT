const bcrypt = require('bcrypt');

const { closePool, getPool } = require('../config/database');

const parseNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const adminPassword = process.env.SEED_ADMIN_PASSWORD || 'Password123!';
const defaultPassword = process.env.SEED_DEFAULT_PASSWORD || 'Password123!';
const bcryptRounds = parseNumber(process.env.SEED_BCRYPT_ROUNDS, 10);

const categories = [
  ['small_parcel', 'Small Parcel', 'Documents, boxes, and lightweight parcels.', 'bike', 'package-small', 149.0, 18.0, 10.0, 1, 1],
  ['medium_goods', 'Medium Goods', 'Retail goods, cartons, and appliance-sized loads.', 'mini_truck', 'boxes', 499.0, 32.0, 250.0, 1, 2],
  ['heavy_cargo', 'Heavy Cargo', 'Industrial and bulk cargo needing higher capacity.', 'heavy_truck', 'container', 1499.0, 58.0, 5000.0, 0, 3],
  ['refrigerated', 'Refrigerated', 'Temperature-sensitive goods and cold-chain loads.', 'refrigerated_truck', 'snowflake', 1299.0, 52.0, 1500.0, 0, 4],
  ['fragile', 'Fragile', 'Glassware, electronics, and careful-handle cargo.', 'van', 'shield-alert', 699.0, 38.0, 500.0, 1, 5],
  ['urgent', 'Urgent', 'Priority pickup and expedited delivery.', 'mini_truck', 'zap', 899.0, 48.0, 300.0, 1, 6],
];

const users = [
  {
    publicId: '00000000-0000-4000-8000-000000000001',
    role: 'admin',
    name: 'CargoConnect Admin',
    username: 'admin',
    email: 'admin@cargoconnect.local',
    phone: '+919900000001',
    passwordType: 'admin',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000002',
    role: 'dispatcher',
    name: 'CargoConnect Dispatcher',
    username: 'dispatcher',
    email: 'dispatcher@cargoconnect.local',
    phone: '+919900000002',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000100',
    role: 'customer',
    name: 'CargoConnect Customer',
    username: 'customer',
    email: 'customer@cargoconnect.local',
    phone: '+919900000100',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000101',
    role: 'customer',
    name: 'Aarav Mehta',
    username: 'aarav.customer',
    email: 'aarav.mehta@example.com',
    phone: '+919900000101',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000102',
    role: 'customer',
    name: 'Priya Nair',
    username: 'priya.customer',
    email: 'priya.nair@example.com',
    phone: '+919900000102',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000103',
    role: 'customer',
    name: 'Rohan Kapoor',
    username: 'rohan.customer',
    email: 'rohan.kapoor@example.com',
    phone: '+919900000103',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000200',
    role: 'driver',
    name: 'CargoConnect Driver',
    username: 'driver',
    email: 'driver@cargoconnect.local',
    phone: '+919900000200',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000201',
    role: 'driver',
    name: 'Vikram Singh',
    username: 'vikram.driver',
    email: 'vikram.singh@example.com',
    phone: '+919900000201',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000202',
    role: 'driver',
    name: 'Imran Khan',
    username: 'imran.driver',
    email: 'imran.khan@example.com',
    phone: '+919900000202',
    passwordType: 'default',
  },
  {
    publicId: '00000000-0000-4000-8000-000000000203',
    role: 'driver',
    name: 'Neha Sharma',
    username: 'neha.driver',
    email: 'neha.sharma@example.com',
    phone: '+919900000203',
    passwordType: 'default',
  },
];

const customers = [
  ['customer', 'CUST-TEST', 'CargoConnect Test Customer Address', 'Local Test Area', 'Mumbai', 'Maharashtra', '400001', 'active', 1],
  ['aarav.customer', 'CUST-0001', 'Bandra Kurla Complex', 'Bandra East', 'Mumbai', 'Maharashtra', '400051', 'active', 2],
  ['priya.customer', 'CUST-0002', 'Indiranagar 100 Feet Road', 'Stage 2', 'Bengaluru', 'Karnataka', '560038', 'active', 2],
  ['rohan.customer', 'CUST-0003', 'Connaught Place', 'Block A', 'New Delhi', 'Delhi', '110001', 'active', 1],
];

const drivers = [
  ['driver', 'DRV-TEST', 'MH12CC2026999', '2028-12-31', 'CargoConnect Driver Address', 'Mumbai', 'Maharashtra', '400001', 'busy', 'active', 4.7, 42],
  ['vikram.driver', 'DRV-0001', 'MH12CC2026001', '2028-07-15', 'Andheri East', 'Mumbai', 'Maharashtra', '400069', 'available', 'active', 4.8, 124],
  ['imran.driver', 'DRV-0002', 'KA05CC2026002', '2027-11-20', 'Whitefield', 'Bengaluru', 'Karnataka', '560066', 'busy', 'active', 4.6, 98],
  ['neha.driver', 'DRV-0003', 'DL08CC2026003', '2029-02-10', 'Dwarka Sector 10', 'New Delhi', 'Delhi', '110075', 'available', 'active', 4.9, 142],
];

const vehicles = [
  ['CC-TEST-0001', 'MH12CC9999', 'mini_truck', 'Tata Ace EV', 750.0, 'electric', '2028-12-31', '2026-10-01', 'assigned', 'DRV-TEST'],
  ['CC-MH-1001', 'MH12AB1234', 'mini_truck', 'Tata Ace Gold', 750.0, 'diesel', '2027-04-30', '2026-08-15', 'available', 'DRV-0001'],
  ['CC-KA-2001', 'KA05CD5678', 'truck', 'Ashok Leyland Dost', 1500.0, 'diesel', '2027-06-12', '2026-07-01', 'assigned', 'DRV-0002'],
  ['CC-DL-3001', 'DL08EF9012', 'refrigerated_truck', 'Mahindra Supro Reefer', 1200.0, 'diesel', '2028-01-10', '2026-09-20', 'available', 'DRV-0003'],
];

const shipments = [
  {
    code: 'SHP-2026-0006',
    customerCode: 'CUST-TEST',
    categoryCode: 'medium_goods',
    pickup: 'CargoConnect Test Warehouse, Mumbai, Maharashtra 400001',
    pickupCity: 'Mumbai',
    pickupState: 'Maharashtra',
    pickupPostalCode: '400001',
    delivery: 'CargoConnect Test Receiver, Thane, Maharashtra 400601',
    deliveryCity: 'Thane',
    deliveryState: 'Maharashtra',
    deliveryPostalCode: '400601',
    receiverName: 'CargoConnect Test Receiver',
    receiverPhone: '+919811119999',
    packageType: 'Test cartons',
    weight: 45.0,
    vehiclePreference: 'mini_truck',
    isFragile: 0,
    notes: 'Seeded assigned shipment for driver flow testing.',
    scheduledPickupAt: '2026-05-06 11:00:00',
    distance: 24.5,
    duration: 70,
    price: 1283.0,
    status: 'assigned',
    paymentStatus: 'paid',
  },
  {
    code: 'SHP-2026-0001',
    customerCode: 'CUST-0001',
    categoryCode: 'small_parcel',
    pickup: 'Bandra Kurla Complex, Mumbai, Maharashtra 400051',
    pickupCity: 'Mumbai',
    pickupState: 'Maharashtra',
    pickupPostalCode: '400051',
    delivery: 'Lower Parel, Mumbai, Maharashtra 400013',
    deliveryCity: 'Mumbai',
    deliveryState: 'Maharashtra',
    deliveryPostalCode: '400013',
    receiverName: 'Meera Joshi',
    receiverPhone: '+919811110001',
    packageType: 'Documents',
    weight: 2.5,
    vehiclePreference: 'bike',
    isFragile: 0,
    notes: 'Call receiver before arrival.',
    scheduledPickupAt: '2026-05-02 10:30:00',
    distance: 14.2,
    duration: 45,
    price: 405.0,
    status: 'pending',
    paymentStatus: 'unpaid',
  },
  {
    code: 'SHP-2026-0002',
    customerCode: 'CUST-0002',
    categoryCode: 'refrigerated',
    pickup: 'Indiranagar, Bengaluru, Karnataka 560038',
    pickupCity: 'Bengaluru',
    pickupState: 'Karnataka',
    pickupPostalCode: '560038',
    delivery: 'Koramangala, Bengaluru, Karnataka 560095',
    deliveryCity: 'Bengaluru',
    deliveryState: 'Karnataka',
    deliveryPostalCode: '560095',
    receiverName: 'FreshMart Receiving',
    receiverPhone: '+919811110002',
    packageType: 'Cold-chain cartons',
    weight: 420.0,
    vehiclePreference: 'refrigerated_truck',
    isFragile: 0,
    notes: 'Maintain chilled handling.',
    scheduledPickupAt: '2026-05-03 08:00:00',
    distance: 11.8,
    duration: 40,
    price: 1912.6,
    status: 'approved',
    paymentStatus: 'pending',
  },
  {
    code: 'SHP-2026-0003',
    customerCode: 'CUST-0003',
    categoryCode: 'fragile',
    pickup: 'Connaught Place, New Delhi, Delhi 110001',
    pickupCity: 'New Delhi',
    pickupState: 'Delhi',
    pickupPostalCode: '110001',
    delivery: 'Gurugram Sector 44, Haryana 122003',
    deliveryCity: 'Gurugram',
    deliveryState: 'Haryana',
    deliveryPostalCode: '122003',
    receiverName: 'Aditi Rao',
    receiverPhone: '+919811110003',
    packageType: 'Electronics',
    weight: 35.0,
    vehiclePreference: 'van',
    isFragile: 1,
    notes: 'Use protective handling.',
    scheduledPickupAt: '2026-05-04 14:00:00',
    distance: 31.5,
    duration: 75,
    price: 1896.0,
    status: 'assigned',
    paymentStatus: 'paid',
  },
  {
    code: 'SHP-2026-0004',
    customerCode: 'CUST-0001',
    categoryCode: 'heavy_cargo',
    pickup: 'Navi Mumbai MIDC, Maharashtra 400710',
    pickupCity: 'Navi Mumbai',
    pickupState: 'Maharashtra',
    pickupPostalCode: '400710',
    delivery: 'Pune Chakan Industrial Area, Maharashtra 410501',
    deliveryCity: 'Pune',
    deliveryState: 'Maharashtra',
    deliveryPostalCode: '410501',
    receiverName: 'Warehouse Dock 4',
    receiverPhone: '+919811110004',
    packageType: 'Machine parts',
    weight: 1800.0,
    vehiclePreference: 'heavy_truck',
    isFragile: 0,
    notes: 'Forklift required at destination.',
    scheduledPickupAt: '2026-05-05 06:30:00',
    distance: 145.0,
    duration: 230,
    price: 9909.0,
    status: 'in_transit',
    paymentStatus: 'paid',
  },
  {
    code: 'SHP-2026-0005',
    customerCode: 'CUST-0002',
    categoryCode: 'urgent',
    pickup: 'MG Road, Bengaluru, Karnataka 560001',
    pickupCity: 'Bengaluru',
    pickupState: 'Karnataka',
    pickupPostalCode: '560001',
    delivery: 'Electronic City, Bengaluru, Karnataka 560100',
    deliveryCity: 'Bengaluru',
    deliveryState: 'Karnataka',
    deliveryPostalCode: '560100',
    receiverName: 'Ops Control Desk',
    receiverPhone: '+919811110005',
    packageType: 'Priority equipment',
    weight: 68.0,
    vehiclePreference: 'mini_truck',
    isFragile: 1,
    notes: 'Priority delivery window.',
    scheduledPickupAt: '2026-05-01 09:15:00',
    distance: 22.7,
    duration: 60,
    price: 1988.6,
    status: 'completed',
    paymentStatus: 'paid',
  },
];

const assignments = [
  {
    code: 'ASN-2026-TEST',
    shipmentCode: 'SHP-2026-0006',
    driverCode: 'DRV-TEST',
    vehicleNumber: 'CC-TEST-0001',
    status: 'assigned',
  },
];

const supportIssues = [
  {
    code: 'SUP-2026-TEST',
    customerCode: 'CUST-TEST',
    shipmentCode: 'SHP-2026-0006',
    issueType: 'delay',
    priority: 'medium',
    subject: 'Need pickup timing confirmation',
    description: 'Please confirm the final pickup window for this assigned test shipment.',
    status: 'open',
  },
];

const feedback = [
  {
    code: 'FDB-2026-TEST',
    customerCode: 'CUST-TEST',
    shipmentCode: 'SHP-2026-0006',
    rating: 5,
    experienceTags: ['professional', 'clear_updates'],
    comments: 'Seeded feedback for customer API testing.',
    wouldRecommend: 1,
  },
];

const appSettings = [
  [
    'status_master',
    'shipment_status_flow',
    JSON.stringify([
      'pending',
      'approved',
      'assigned',
      'accepted',
      'pickup_completed',
      'in_transit',
      'delivered',
      'completed',
    ]),
    'json',
    'Canonical shipment status flow enforced by the backend.',
    0,
    1,
  ],
  [
    'notification_settings',
    'notify_customer_on_status_change',
    JSON.stringify(true),
    'boolean',
    'Send in-app customer notification on shipment status changes.',
    0,
    1,
  ],
  [
    'app_settings',
    'support_email',
    JSON.stringify('support@cargoconnect.local'),
    'string',
    'Admin support mailbox shown in local testing flows.',
    1,
    1,
  ],
  [
    'business_rules',
    'tax_percent',
    JSON.stringify(18),
    'number',
    'Default tax percentage for local price estimates.',
    0,
    1,
  ],
];

const getId = async (connection, sql, params) => {
  const [rows] = await connection.execute(sql, params);
  if (!rows.length) {
    throw new Error(`Seed lookup failed for query: ${sql}`);
  }

  return rows[0].id;
};

const seedCategories = async (connection) => {
  for (const category of categories) {
    await connection.execute(
      `
        INSERT INTO shipment_categories (
          code, name, description, suggested_vehicle_type, icon_key,
          base_price, price_per_km, max_weight_kg, is_fragile_allowed, sort_order
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          name = VALUES(name),
          description = VALUES(description),
          suggested_vehicle_type = VALUES(suggested_vehicle_type),
          icon_key = VALUES(icon_key),
          base_price = VALUES(base_price),
          price_per_km = VALUES(price_per_km),
          max_weight_kg = VALUES(max_weight_kg),
          is_fragile_allowed = VALUES(is_fragile_allowed),
          sort_order = VALUES(sort_order),
          is_active = 1,
          deleted_at = NULL
      `,
      category,
    );
  }
};

const seedUsers = async (connection, passwordHashes) => {
  for (const user of users) {
    const passwordHash = passwordHashes[user.passwordType];
    await connection.execute(
      `
        INSERT INTO users (
          public_id, role, name, username, email, phone, password_hash,
          status, email_verified_at, phone_verified_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        ON DUPLICATE KEY UPDATE
          role = VALUES(role),
          name = VALUES(name),
          email = VALUES(email),
          phone = VALUES(phone),
          password_hash = VALUES(password_hash),
          status = 'active',
          email_verified_at = COALESCE(email_verified_at, CURRENT_TIMESTAMP),
          phone_verified_at = COALESCE(phone_verified_at, CURRENT_TIMESTAMP),
          deleted_at = NULL
      `,
      [
        user.publicId,
        user.role,
        user.name,
        user.username,
        user.email,
        user.phone,
        passwordHash,
      ],
    );
  }
};

const seedCustomers = async (connection) => {
  for (const customer of customers) {
    const userId = await getId(
      connection,
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [customer[0]],
    );

    await connection.execute(
      `
        INSERT INTO customers (
          user_id, customer_code, address_line1, address_line2, city,
          state, postal_code, account_status, total_shipments
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          address_line1 = VALUES(address_line1),
          address_line2 = VALUES(address_line2),
          city = VALUES(city),
          state = VALUES(state),
          postal_code = VALUES(postal_code),
          account_status = VALUES(account_status),
          total_shipments = VALUES(total_shipments),
          deleted_at = NULL
      `,
      [userId, ...customer.slice(1)],
    );
  }
};

const seedDrivers = async (connection) => {
  for (const driver of drivers) {
    const userId = await getId(
      connection,
      'SELECT id FROM users WHERE username = ? LIMIT 1',
      [driver[0]],
    );

    await connection.execute(
      `
        INSERT INTO drivers (
          user_id, driver_code, license_number, license_expiry_date,
          address_line1, city, state, postal_code, availability_status,
          driver_status, rating, completed_trips
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          license_number = VALUES(license_number),
          license_expiry_date = VALUES(license_expiry_date),
          address_line1 = VALUES(address_line1),
          city = VALUES(city),
          state = VALUES(state),
          postal_code = VALUES(postal_code),
          availability_status = VALUES(availability_status),
          driver_status = VALUES(driver_status),
          rating = VALUES(rating),
          completed_trips = VALUES(completed_trips),
          deleted_at = NULL
      `,
      [userId, ...driver.slice(1)],
    );
  }
};

const seedVehicles = async (connection) => {
  for (const vehicle of vehicles) {
    const assignedDriverId = await getId(
      connection,
      'SELECT id FROM drivers WHERE driver_code = ? LIMIT 1',
      [vehicle[9]],
    );

    await connection.execute(
      `
        INSERT INTO vehicles (
          vehicle_number, registration_number, vehicle_type, model,
          capacity_kg, fuel_type, insurance_expiry_date, service_due_date,
          availability_status, assigned_driver_id
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          registration_number = VALUES(registration_number),
          vehicle_type = VALUES(vehicle_type),
          model = VALUES(model),
          capacity_kg = VALUES(capacity_kg),
          fuel_type = VALUES(fuel_type),
          insurance_expiry_date = VALUES(insurance_expiry_date),
          service_due_date = VALUES(service_due_date),
          availability_status = VALUES(availability_status),
          assigned_driver_id = VALUES(assigned_driver_id),
          deleted_at = NULL
      `,
      [...vehicle.slice(0, 9), assignedDriverId],
    );
  }
};

const seedShipments = async (connection) => {
  const adminId = await getId(
    connection,
    'SELECT id FROM users WHERE username = ? LIMIT 1',
    ['admin'],
  );

  for (const shipment of shipments) {
    const customerId = await getId(
      connection,
      'SELECT id FROM customers WHERE customer_code = ? LIMIT 1',
      [shipment.customerCode],
    );
    const categoryId = await getId(
      connection,
      'SELECT id FROM shipment_categories WHERE code = ? LIMIT 1',
      [shipment.categoryCode],
    );
    const approvedBy = ['approved', 'assigned', 'in_transit', 'completed'].includes(
      shipment.status,
    )
      ? adminId
      : null;

    await connection.execute(
      `
        INSERT INTO shipments (
          shipment_code, customer_id, category_id, pickup_address, pickup_city,
          pickup_state, pickup_postal_code, delivery_address, delivery_city,
          delivery_state, delivery_postal_code, receiver_name, receiver_phone,
          package_type, package_weight_kg, vehicle_preference, is_fragile,
          delivery_notes, scheduled_pickup_at, estimated_distance_km,
          estimated_duration_minutes, estimated_price, shipment_status,
          payment_status, approved_by_user_id, approved_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          customer_id = VALUES(customer_id),
          category_id = VALUES(category_id),
          pickup_address = VALUES(pickup_address),
          delivery_address = VALUES(delivery_address),
          receiver_name = VALUES(receiver_name),
          receiver_phone = VALUES(receiver_phone),
          package_type = VALUES(package_type),
          package_weight_kg = VALUES(package_weight_kg),
          vehicle_preference = VALUES(vehicle_preference),
          is_fragile = VALUES(is_fragile),
          delivery_notes = VALUES(delivery_notes),
          scheduled_pickup_at = VALUES(scheduled_pickup_at),
          estimated_distance_km = VALUES(estimated_distance_km),
          estimated_duration_minutes = VALUES(estimated_duration_minutes),
          estimated_price = VALUES(estimated_price),
          shipment_status = VALUES(shipment_status),
          payment_status = VALUES(payment_status),
          approved_by_user_id = VALUES(approved_by_user_id),
          approved_at = VALUES(approved_at),
          deleted_at = NULL
      `,
      [
        shipment.code,
        customerId,
        categoryId,
        shipment.pickup,
        shipment.pickupCity,
        shipment.pickupState,
        shipment.pickupPostalCode,
        shipment.delivery,
        shipment.deliveryCity,
        shipment.deliveryState,
        shipment.deliveryPostalCode,
        shipment.receiverName,
        shipment.receiverPhone,
        shipment.packageType,
        shipment.weight,
        shipment.vehiclePreference,
        shipment.isFragile,
        shipment.notes,
        shipment.scheduledPickupAt,
        shipment.distance,
        shipment.duration,
        shipment.price,
        shipment.status,
        shipment.paymentStatus,
        approvedBy,
        approvedBy ? new Date() : null,
      ],
    );
  }
};

const seedAssignments = async (connection) => {
  const adminId = await getId(
    connection,
    'SELECT id FROM users WHERE username = ? LIMIT 1',
    ['admin'],
  );

  for (const assignment of assignments) {
    const shipmentId = await getId(
      connection,
      'SELECT id FROM shipments WHERE shipment_code = ? LIMIT 1',
      [assignment.shipmentCode],
    );
    const driverId = await getId(
      connection,
      'SELECT id FROM drivers WHERE driver_code = ? LIMIT 1',
      [assignment.driverCode],
    );
    const vehicleId = await getId(
      connection,
      'SELECT id FROM vehicles WHERE vehicle_number = ? LIMIT 1',
      [assignment.vehicleNumber],
    );

    await connection.execute(
      `
        INSERT INTO assignments (
          assignment_code, shipment_id, driver_id, vehicle_id,
          assigned_by_user_id, assignment_status
        )
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          shipment_id = VALUES(shipment_id),
          driver_id = VALUES(driver_id),
          vehicle_id = VALUES(vehicle_id),
          assigned_by_user_id = VALUES(assigned_by_user_id),
          assignment_status = VALUES(assignment_status),
          deleted_at = NULL
      `,
      [
        assignment.code,
        shipmentId,
        driverId,
        vehicleId,
        adminId,
        assignment.status,
      ],
    );
  }
};

const seedSupportIssues = async (connection) => {
  for (const issue of supportIssues) {
    const customerId = await getId(
      connection,
      'SELECT id FROM customers WHERE customer_code = ? LIMIT 1',
      [issue.customerCode],
    );
    const shipmentId = await getId(
      connection,
      'SELECT id FROM shipments WHERE shipment_code = ? LIMIT 1',
      [issue.shipmentCode],
    );

    await connection.execute(
      `
        INSERT INTO support_issues (
          issue_code, customer_id, shipment_id, issue_type, priority,
          subject, description, issue_status
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          customer_id = VALUES(customer_id),
          shipment_id = VALUES(shipment_id),
          issue_type = VALUES(issue_type),
          priority = VALUES(priority),
          subject = VALUES(subject),
          description = VALUES(description),
          issue_status = VALUES(issue_status),
          deleted_at = NULL
      `,
      [
        issue.code,
        customerId,
        shipmentId,
        issue.issueType,
        issue.priority,
        issue.subject,
        issue.description,
        issue.status,
      ],
    );
  }
};

const seedFeedback = async (connection) => {
  for (const item of feedback) {
    const customerId = await getId(
      connection,
      'SELECT id FROM customers WHERE customer_code = ? LIMIT 1',
      [item.customerCode],
    );
    const shipmentId = await getId(
      connection,
      'SELECT id FROM shipments WHERE shipment_code = ? LIMIT 1',
      [item.shipmentCode],
    );

    await connection.execute(
      `
        INSERT INTO feedback (
          feedback_code, customer_id, shipment_id, rating,
          experience_tags, comments, would_recommend
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          rating = VALUES(rating),
          experience_tags = VALUES(experience_tags),
          comments = VALUES(comments),
          would_recommend = VALUES(would_recommend),
          deleted_at = NULL
      `,
      [
        item.code,
        customerId,
        shipmentId,
        item.rating,
        JSON.stringify(item.experienceTags),
        item.comments,
        item.wouldRecommend,
      ],
    );
  }
};

const seedAppSettings = async (connection) => {
  const adminId = await getId(
    connection,
    'SELECT id FROM users WHERE username = ? LIMIT 1',
    ['admin'],
  );

  for (const setting of appSettings) {
    await connection.execute(
      `
        INSERT INTO app_settings (
          setting_group, setting_key, setting_value, value_type,
          description, is_public, is_active, updated_by_user_id
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          setting_value = VALUES(setting_value),
          value_type = VALUES(value_type),
          description = VALUES(description),
          is_public = VALUES(is_public),
          is_active = VALUES(is_active),
          updated_by_user_id = VALUES(updated_by_user_id),
          deleted_at = NULL
      `,
      [...setting, adminId],
    );
  }
};

const seedDatabase = async () => {
  const connection = await getPool().getConnection();

  try {
    const passwordHashes = {
      admin: await bcrypt.hash(adminPassword, bcryptRounds),
      default: await bcrypt.hash(defaultPassword, bcryptRounds),
    };

    await connection.beginTransaction();
    await seedCategories(connection);
    await seedUsers(connection, passwordHashes);
    await seedCustomers(connection);
    await seedDrivers(connection);
    await seedVehicles(connection);
    await seedShipments(connection);
    await seedAssignments(connection);
    await seedSupportIssues(connection);
    await seedFeedback(connection);
    await seedAppSettings(connection);
    await connection.commit();

    console.log('CargoConnect seed data inserted successfully.');
    console.log(`Admin login: admin@cargoconnect.local / ${adminPassword}`);
    console.log(`Customer login: customer@cargoconnect.local / ${defaultPassword}`);
    console.log(`Driver login: driver@cargoconnect.local / ${defaultPassword}`);
    console.log(`Dispatcher login: dispatcher@cargoconnect.local / ${defaultPassword}`);
  } catch (error) {
    await connection.rollback();
    console.error('CargoConnect seed failed:', error.message);
    process.exitCode = 1;
  } finally {
    connection.release();
    await closePool();
  }
};

seedDatabase();
