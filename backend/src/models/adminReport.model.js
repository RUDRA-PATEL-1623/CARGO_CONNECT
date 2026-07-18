const { getPool } = require('../config/database');

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const toNumber = (value) => (value === null || value === undefined ? 0 : Number(value));

const ACTIVE_ASSIGNMENT_STATUSES = [
  'assigned',
  'accepted',
  'started',
  'pickup_completed',
  'in_transit',
  'delivered',
];
const DRIVER_RECORD_STATUSES = ['active', 'inactive', 'suspended'];
const INVOICE_RECORD_STATUSES = ['draft', 'generated', 'void'];

const addDateFilter = (where, values, column, filters = {}) => {
  if (filters.dateFrom) {
    where.push(`DATE(${column}) >= DATE(?)`);
    values.push(filters.dateFrom);
  }

  if (filters.dateTo) {
    where.push(`DATE(${column}) <= DATE(?)`);
    values.push(filters.dateTo);
  }
};

const addShipmentCategoryFilter = (
  where,
  values,
  { categoryIdColumn = 's.category_id', categoryCodeColumn = 'sc.code' } = {},
  filters = {},
) => {
  if (filters.categoryId) {
    where.push(`${categoryIdColumn} = ?`);
    values.push(filters.categoryId);
  }

  if (filters.categoryCode) {
    where.push(`${categoryCodeColumn} = ?`);
    values.push(filters.categoryCode);
  }
};

const buildAssignmentFilterParts = (filters = {}, assignmentAlias = 'a') => {
  const where = [`${assignmentAlias}.deleted_at IS NULL`];
  const values = [];

  addDateFilter(where, values, `${assignmentAlias}.assigned_at`, filters);
  addShipmentCategoryFilter(
    where,
    values,
    {
      categoryIdColumn: 'sx.category_id',
      categoryCodeColumn: 'scx.code',
    },
    filters,
  );

  return {
    sql: where.join(' AND '),
    values,
  };
};

const buildAssignmentJoinParts = (filters = {}, assignmentAlias = 'a') => {
  const where = [`${assignmentAlias}.deleted_at IS NULL`];
  const values = [];

  addDateFilter(where, values, `${assignmentAlias}.assigned_at`, filters);

  if (filters.categoryId || filters.categoryCode) {
    const categoryWhere = [
      `sx.id = ${assignmentAlias}.shipment_id`,
      'sx.deleted_at IS NULL',
      'scx.deleted_at IS NULL',
    ];
    const categoryValues = [];

    addShipmentCategoryFilter(
      categoryWhere,
      categoryValues,
      {
        categoryIdColumn: 'sx.category_id',
        categoryCodeColumn: 'scx.code',
      },
      filters,
    );

    where.push(`
      EXISTS (
        SELECT 1
        FROM shipments sx
        INNER JOIN shipment_categories scx ON scx.id = sx.category_id
        WHERE ${categoryWhere.join(' AND ')}
      )
    `);
    values.push(...categoryValues);
  }

  return {
    sql: where.join(' AND '),
    values,
  };
};

const addAssignmentExistsFilter = (
  where,
  values,
  { entityAlias, entityIdColumn, assignmentColumn },
  filters = {},
) => {
  if (!filters.dateFrom && !filters.dateTo && !filters.categoryId && !filters.categoryCode) {
    return;
  }

  const assignmentFilters = buildAssignmentFilterParts(filters, 'ax');

  where.push(`
    EXISTS (
      SELECT 1
      FROM assignments ax
      INNER JOIN shipments sx ON sx.id = ax.shipment_id AND sx.deleted_at IS NULL
      INNER JOIN shipment_categories scx ON scx.id = sx.category_id AND scx.deleted_at IS NULL
      WHERE ax.${assignmentColumn} = ${entityAlias}.${entityIdColumn}
        AND ${assignmentFilters.sql}
    )
  `);
  values.push(...assignmentFilters.values);
};

const buildShipmentWhere = (filters = {}) => {
  const where = [
    's.deleted_at IS NULL',
    'c.deleted_at IS NULL',
    'cu.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
  ];
  const values = [];

  if (filters.search) {
    where.push(`(
      s.shipment_code LIKE ?
      OR cu.name LIKE ?
      OR cu.email LIKE ?
      OR cu.phone LIKE ?
      OR s.pickup_address LIKE ?
      OR s.delivery_address LIKE ?
      OR s.receiver_name LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search, search);
  }

  if (filters.status) {
    where.push('s.shipment_status = ?');
    values.push(filters.status);
  }

  if (filters.paymentStatus) {
    where.push('s.payment_status = ?');
    values.push(filters.paymentStatus);
  }

  addDateFilter(where, values, 's.created_at', filters);
  addShipmentCategoryFilter(where, values, {}, filters);

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const buildPaymentWhere = (filters = {}) => {
  const where = [
    'p.deleted_at IS NULL',
    's.deleted_at IS NULL',
    'c.deleted_at IS NULL',
    'cu.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
  ];
  const values = [];

  if (filters.search) {
    where.push(`(
      p.payment_code LIKE ?
      OR p.transaction_reference LIKE ?
      OR s.shipment_code LIKE ?
      OR cu.name LIKE ?
      OR cu.email LIKE ?
      OR cu.phone LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search, search);
  }

  if (filters.status || filters.paymentStatus) {
    where.push('p.payment_status = ?');
    values.push(filters.status || filters.paymentStatus);
  }

  if (filters.paymentMethod) {
    where.push('p.payment_method = ?');
    values.push(filters.paymentMethod);
  }

  addDateFilter(where, values, 'p.created_at', filters);
  addShipmentCategoryFilter(where, values, {}, filters);

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const buildInvoiceWhere = (filters = {}) => {
  const where = [
    'i.deleted_at IS NULL',
    's.deleted_at IS NULL',
    'c.deleted_at IS NULL',
    'cu.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
  ];
  const values = [];

  if (filters.search) {
    where.push(`(
      i.invoice_number LIKE ?
      OR s.shipment_code LIKE ?
      OR i.billing_name LIKE ?
      OR i.billing_email LIKE ?
      OR i.billing_phone LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
  }

  if (filters.invoiceStatus || filters.status) {
    const requestedStatus = filters.invoiceStatus || filters.status;
    const statusColumn =
      filters.invoiceStatus || INVOICE_RECORD_STATUSES.includes(requestedStatus)
        ? 'i.invoice_status'
        : 'i.payment_status';
    where.push(`${statusColumn} = ?`);
    values.push(requestedStatus);
  }

  if (filters.paymentStatus) {
    where.push('i.payment_status = ?');
    values.push(filters.paymentStatus);
  }

  addDateFilter(where, values, 'i.issued_at', filters);
  addShipmentCategoryFilter(where, values, {}, filters);

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const buildDriverWhere = (filters = {}) => {
  const where = ['d.deleted_at IS NULL', 'du.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      d.driver_code LIKE ?
      OR du.name LIKE ?
      OR du.email LIKE ?
      OR du.phone LIKE ?
      OR d.license_number LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
  }

  if (filters.driverStatus || filters.status) {
    const requestedStatus = filters.driverStatus || filters.status;
    const statusColumn =
      filters.driverStatus || DRIVER_RECORD_STATUSES.includes(requestedStatus)
        ? 'd.driver_status'
        : 'd.availability_status';
    where.push(`${statusColumn} = ?`);
    values.push(requestedStatus);
  }

  if (filters.availabilityStatus) {
    where.push('d.availability_status = ?');
    values.push(filters.availabilityStatus);
  }

  addAssignmentExistsFilter(
    where,
    values,
    {
      entityAlias: 'd',
      entityIdColumn: 'id',
      assignmentColumn: 'driver_id',
    },
    filters,
  );

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const buildVehicleWhere = (filters = {}) => {
  const where = ['v.deleted_at IS NULL'];
  const values = [];

  if (filters.search) {
    where.push(`(
      v.vehicle_number LIKE ?
      OR v.registration_number LIKE ?
      OR v.model LIKE ?
      OR du.name LIKE ?
      OR d.driver_code LIKE ?
    )`);
    const search = `%${filters.search}%`;
    values.push(search, search, search, search, search);
  }

  if (filters.status || filters.availabilityStatus) {
    where.push('v.availability_status = ?');
    values.push(filters.status || filters.availabilityStatus);
  }

  if (filters.vehicleType) {
    where.push('v.vehicle_type = ?');
    values.push(filters.vehicleType);
  }

  addAssignmentExistsFilter(
    where,
    values,
    {
      entityAlias: 'v',
      entityIdColumn: 'id',
      assignmentColumn: 'vehicle_id',
    },
    filters,
  );

  return {
    whereSql: where.join(' AND '),
    values,
  };
};

const shipmentJoins = `
  FROM shipments s
  INNER JOIN customers c ON c.id = s.customer_id
  INNER JOIN users cu ON cu.id = c.user_id
  INNER JOIN shipment_categories sc ON sc.id = s.category_id
`;

const paymentJoins = `
  FROM payments p
  INNER JOIN shipments s ON s.id = p.shipment_id
  INNER JOIN customers c ON c.id = p.customer_id
  INNER JOIN users cu ON cu.id = c.user_id
  INNER JOIN shipment_categories sc ON sc.id = s.category_id
`;

const invoiceJoins = `
  FROM invoices i
  INNER JOIN shipments s ON s.id = i.shipment_id
  INNER JOIN customers c ON c.id = i.customer_id
  INNER JOIN users cu ON cu.id = c.user_id
  INNER JOIN shipment_categories sc ON sc.id = s.category_id
`;

const mapShipmentRow = (row) => ({
  ...row,
  packageWeightKg: toNumber(row.packageWeightKg),
  estimatedDistanceKm: toNumber(row.estimatedDistanceKm),
  estimatedPrice: toNumber(row.estimatedPrice),
});

const mapDriverRow = (row) => ({
  ...row,
  rating: toNumber(row.rating),
  completedTrips: toNumber(row.completedTrips),
  assignedTripsInRange: toNumber(row.assignedTripsInRange),
  completedAssignmentsInRange: toNumber(row.completedAssignmentsInRange),
  activeTripsInRange: toNumber(row.activeTripsInRange),
  emergencyReportsInRange: toNumber(row.emergencyReportsInRange),
});

const mapVehicleRow = (row) => ({
  ...row,
  capacityKg: toNumber(row.capacityKg),
  assignedTripsInRange: toNumber(row.assignedTripsInRange),
  completedTripsInRange: toNumber(row.completedTripsInRange),
  activeTripsInRange: toNumber(row.activeTripsInRange),
});

const mapPaymentRow = (row) => ({
  ...row,
  subtotalAmount: toNumber(row.subtotalAmount),
  discountAmount: toNumber(row.discountAmount),
  taxAmount: toNumber(row.taxAmount),
  feeAmount: toNumber(row.feeAmount),
  totalAmount: toNumber(row.totalAmount),
});

const mapInvoiceRow = (row) => ({
  ...row,
  subtotalAmount: toNumber(row.subtotalAmount),
  discountAmount: toNumber(row.discountAmount),
  taxAmount: toNumber(row.taxAmount),
  totalAmount: toNumber(row.totalAmount),
});

const mapCountAmountRows = (rows, countKey, amountKey) => rows.map((row) => ({
  ...row,
  [countKey]: toNumber(row[countKey]),
  [amountKey]: toNumber(row[amountKey]),
}));

const getShipmentReport = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildShipmentWhere(filters);

  const [countRows] = await executor.execute(
    `SELECT COUNT(*) AS total ${shipmentJoins} WHERE ${whereSql}`,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        s.id,
        s.shipment_code AS shipmentCode,
        cu.name AS customerName,
        cu.email AS customerEmail,
        sc.name AS categoryName,
        sc.code AS categoryCode,
        s.pickup_city AS pickupCity,
        s.delivery_city AS deliveryCity,
        s.package_type AS packageType,
        s.package_weight_kg AS packageWeightKg,
        s.shipment_status AS shipmentStatus,
        s.payment_status AS paymentStatus,
        s.estimated_distance_km AS estimatedDistanceKm,
        s.estimated_price AS estimatedPrice,
        s.scheduled_pickup_at AS scheduledPickupAt,
        s.completed_at AS completedAt,
        s.created_at AS createdAt
      ${shipmentJoins}
      WHERE ${whereSql}
      ORDER BY s.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  const [dateRows] = await executor.execute(
    `
      SELECT
        DATE(s.created_at) AS reportDate,
        COUNT(*) AS shipmentCount,
        COALESCE(SUM(s.estimated_price), 0) AS estimatedAmount
      ${shipmentJoins}
      WHERE ${whereSql}
      GROUP BY DATE(s.created_at)
      ORDER BY reportDate ASC
    `,
    values,
  );

  const [statusRows] = await executor.execute(
    `
      SELECT
        s.shipment_status AS status,
        COUNT(*) AS shipmentCount,
        COALESCE(SUM(s.estimated_price), 0) AS estimatedAmount
      ${shipmentJoins}
      WHERE ${whereSql}
      GROUP BY s.shipment_status
      ORDER BY shipmentCount DESC
    `,
    values,
  );

  const [categoryRows] = await executor.execute(
    `
      SELECT
        sc.id AS categoryId,
        sc.code AS categoryCode,
        sc.name AS categoryName,
        COUNT(*) AS shipmentCount,
        COALESCE(SUM(s.estimated_price), 0) AS estimatedAmount
      ${shipmentJoins}
      WHERE ${whereSql}
      GROUP BY sc.id, sc.code, sc.name
      ORDER BY shipmentCount DESC, estimatedAmount DESC
    `,
    values,
  );

  return {
    rows: rows.map(mapShipmentRow),
    total: toNumber(firstRow(countRows)?.total),
    dateWise: mapCountAmountRows(dateRows, 'shipmentCount', 'estimatedAmount'),
    statusWise: mapCountAmountRows(statusRows, 'shipmentCount', 'estimatedAmount'),
    categoryWise: mapCountAmountRows(categoryRows, 'shipmentCount', 'estimatedAmount'),
  };
};

const getPaymentReport = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildPaymentWhere(filters);

  const [countRows] = await executor.execute(
    `SELECT COUNT(*) AS total ${paymentJoins} WHERE ${whereSql}`,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        p.id,
        p.payment_code AS paymentCode,
        s.shipment_code AS shipmentCode,
        cu.name AS customerName,
        sc.name AS categoryName,
        sc.code AS categoryCode,
        p.payment_method AS paymentMethod,
        p.payment_status AS paymentStatus,
        p.currency,
        p.subtotal_amount AS subtotalAmount,
        p.discount_amount AS discountAmount,
        p.tax_amount AS taxAmount,
        p.fee_amount AS feeAmount,
        p.total_amount AS totalAmount,
        p.transaction_reference AS transactionReference,
        p.paid_at AS paidAt,
        p.created_at AS createdAt
      ${paymentJoins}
      WHERE ${whereSql}
      ORDER BY p.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  const [dateRows] = await executor.execute(
    `
      SELECT
        DATE(p.created_at) AS reportDate,
        COUNT(*) AS paymentCount,
        COALESCE(SUM(p.total_amount), 0) AS totalAmount
      ${paymentJoins}
      WHERE ${whereSql}
      GROUP BY DATE(p.created_at)
      ORDER BY reportDate ASC
    `,
    values,
  );

  const [statusRows] = await executor.execute(
    `
      SELECT
        p.payment_status AS status,
        COUNT(*) AS paymentCount,
        COALESCE(SUM(p.total_amount), 0) AS totalAmount
      ${paymentJoins}
      WHERE ${whereSql}
      GROUP BY p.payment_status
      ORDER BY totalAmount DESC, paymentCount DESC
    `,
    values,
  );

  const [categoryRows] = await executor.execute(
    `
      SELECT
        sc.id AS categoryId,
        sc.code AS categoryCode,
        sc.name AS categoryName,
        COUNT(*) AS paymentCount,
        COALESCE(SUM(p.total_amount), 0) AS totalAmount
      ${paymentJoins}
      WHERE ${whereSql}
      GROUP BY sc.id, sc.code, sc.name
      ORDER BY totalAmount DESC, paymentCount DESC
    `,
    values,
  );

  const [methodRows] = await executor.execute(
    `
      SELECT
        p.payment_method AS paymentMethod,
        COUNT(*) AS paymentCount,
        COALESCE(SUM(p.total_amount), 0) AS totalAmount
      ${paymentJoins}
      WHERE ${whereSql}
      GROUP BY p.payment_method
      ORDER BY totalAmount DESC, paymentCount DESC
    `,
    values,
  );

  return {
    rows: rows.map(mapPaymentRow),
    total: toNumber(firstRow(countRows)?.total),
    dateWise: mapCountAmountRows(dateRows, 'paymentCount', 'totalAmount'),
    statusWise: mapCountAmountRows(statusRows, 'paymentCount', 'totalAmount'),
    categoryWise: mapCountAmountRows(categoryRows, 'paymentCount', 'totalAmount'),
    methodWise: mapCountAmountRows(methodRows, 'paymentCount', 'totalAmount'),
  };
};

const getInvoiceReport = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildInvoiceWhere(filters);

  const [countRows] = await executor.execute(
    `SELECT COUNT(*) AS total ${invoiceJoins} WHERE ${whereSql}`,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        i.id,
        i.invoice_number AS invoiceNumber,
        s.shipment_code AS shipmentCode,
        i.billing_name AS customerName,
        i.billing_email AS customerEmail,
        sc.name AS categoryName,
        sc.code AS categoryCode,
        i.invoice_status AS invoiceStatus,
        i.payment_status AS paymentStatus,
        i.subtotal_amount AS subtotalAmount,
        i.discount_amount AS discountAmount,
        i.tax_amount AS taxAmount,
        i.total_amount AS totalAmount,
        i.issued_at AS issuedAt,
        i.due_at AS dueAt,
        i.created_at AS createdAt
      ${invoiceJoins}
      WHERE ${whereSql}
      ORDER BY i.issued_at DESC, i.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [...values, limit, offset],
  );

  const [dateRows] = await executor.execute(
    `
      SELECT
        DATE(i.issued_at) AS reportDate,
        COUNT(*) AS invoiceCount,
        COALESCE(SUM(i.total_amount), 0) AS totalAmount
      ${invoiceJoins}
      WHERE ${whereSql}
      GROUP BY DATE(i.issued_at)
      ORDER BY reportDate ASC
    `,
    values,
  );

  const [statusRows] = await executor.execute(
    `
      SELECT
        i.invoice_status AS status,
        i.payment_status AS paymentStatus,
        COUNT(*) AS invoiceCount,
        COALESCE(SUM(i.total_amount), 0) AS totalAmount
      ${invoiceJoins}
      WHERE ${whereSql}
      GROUP BY i.invoice_status, i.payment_status
      ORDER BY totalAmount DESC, invoiceCount DESC
    `,
    values,
  );

  const [categoryRows] = await executor.execute(
    `
      SELECT
        sc.id AS categoryId,
        sc.code AS categoryCode,
        sc.name AS categoryName,
        COUNT(*) AS invoiceCount,
        COALESCE(SUM(i.total_amount), 0) AS totalAmount
      ${invoiceJoins}
      WHERE ${whereSql}
      GROUP BY sc.id, sc.code, sc.name
      ORDER BY totalAmount DESC, invoiceCount DESC
    `,
    values,
  );

  return {
    rows: rows.map(mapInvoiceRow),
    total: toNumber(firstRow(countRows)?.total),
    dateWise: mapCountAmountRows(dateRows, 'invoiceCount', 'totalAmount'),
    statusWise: mapCountAmountRows(statusRows, 'invoiceCount', 'totalAmount'),
    categoryWise: mapCountAmountRows(categoryRows, 'invoiceCount', 'totalAmount'),
  };
};

const getDriverReport = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildDriverWhere(filters);
  const assignmentFilters = buildAssignmentJoinParts(filters, 'a');
  const activePlaceholders = ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ');

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(DISTINCT d.id) AS total
      FROM drivers d
      INNER JOIN users du ON du.id = d.user_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        d.id,
        d.driver_code AS driverCode,
        du.name AS driverName,
        du.email AS driverEmail,
        du.phone AS driverPhone,
        d.license_number AS licenseNumber,
        d.license_expiry_date AS licenseExpiryDate,
        d.driver_status AS driverStatus,
        d.availability_status AS availabilityStatus,
        d.rating,
        d.completed_trips AS completedTrips,
        COUNT(DISTINCT a.id) AS assignedTripsInRange,
        SUM(CASE WHEN a.assignment_status = 'completed' THEN 1 ELSE 0 END) AS completedAssignmentsInRange,
        SUM(CASE WHEN a.assignment_status IN (${activePlaceholders}) THEN 1 ELSE 0 END) AS activeTripsInRange,
        COUNT(DISTINCT er.id) AS emergencyReportsInRange,
        d.created_at AS createdAt
      FROM drivers d
      INNER JOIN users du ON du.id = d.user_id
      LEFT JOIN assignments a ON a.driver_id = d.id
        AND ${assignmentFilters.sql}
      LEFT JOIN shipments s ON s.id = a.shipment_id AND s.deleted_at IS NULL
      LEFT JOIN shipment_categories sc ON sc.id = s.category_id AND sc.deleted_at IS NULL
      LEFT JOIN emergency_reports er ON er.driver_id = d.id
        AND er.deleted_at IS NULL
      WHERE ${whereSql}
      GROUP BY
        d.id, d.driver_code, du.name, du.email, du.phone, d.license_number,
        d.license_expiry_date, d.driver_status, d.availability_status,
        d.rating, d.completed_trips, d.created_at
      ORDER BY assignedTripsInRange DESC, d.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [
      ...ACTIVE_ASSIGNMENT_STATUSES,
      ...assignmentFilters.values,
      ...values,
      limit,
      offset,
    ],
  );

  const driverAssignmentWhere = [
    'a.deleted_at IS NULL',
    'd.deleted_at IS NULL',
    'du.deleted_at IS NULL',
    's.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
  ];
  const driverAssignmentValues = [];
  addDateFilter(driverAssignmentWhere, driverAssignmentValues, 'a.assigned_at', filters);
  addShipmentCategoryFilter(
    driverAssignmentWhere,
    driverAssignmentValues,
    {
      categoryIdColumn: 's.category_id',
      categoryCodeColumn: 'sc.code',
    },
    filters,
  );

  if (filters.driverStatus || filters.status) {
    const requestedStatus = filters.driverStatus || filters.status;
    const statusColumn =
      filters.driverStatus || DRIVER_RECORD_STATUSES.includes(requestedStatus)
        ? 'd.driver_status'
        : 'd.availability_status';
    driverAssignmentWhere.push(`${statusColumn} = ?`);
    driverAssignmentValues.push(requestedStatus);
  }

  if (filters.availabilityStatus) {
    driverAssignmentWhere.push('d.availability_status = ?');
    driverAssignmentValues.push(filters.availabilityStatus);
  }

  const driverAssignmentWhereSql = driverAssignmentWhere.join(' AND ');

  const [dateRows] = await executor.execute(
    `
      SELECT
        DATE(a.assigned_at) AS reportDate,
        COUNT(DISTINCT a.id) AS assignmentCount,
        COUNT(DISTINCT a.driver_id) AS driverCount
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${driverAssignmentWhereSql}
      GROUP BY DATE(a.assigned_at)
      ORDER BY reportDate ASC
    `,
    driverAssignmentValues,
  );

  const [statusRows] = await executor.execute(
    `
      SELECT
        d.driver_status AS status,
        d.availability_status AS availabilityStatus,
        COUNT(DISTINCT d.id) AS driverCount
      FROM drivers d
      INNER JOIN users du ON du.id = d.user_id
      WHERE ${whereSql}
      GROUP BY d.driver_status, d.availability_status
      ORDER BY driverCount DESC
    `,
    values,
  );

  const [categoryRows] = await executor.execute(
    `
      SELECT
        sc.id AS categoryId,
        sc.code AS categoryCode,
        sc.name AS categoryName,
        COUNT(DISTINCT a.id) AS assignmentCount,
        COUNT(DISTINCT a.driver_id) AS driverCount
      FROM assignments a
      INNER JOIN drivers d ON d.id = a.driver_id
      INNER JOIN users du ON du.id = d.user_id
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${driverAssignmentWhereSql}
      GROUP BY sc.id, sc.code, sc.name
      ORDER BY assignmentCount DESC
    `,
    driverAssignmentValues,
  );

  return {
    rows: rows.map(mapDriverRow),
    total: toNumber(firstRow(countRows)?.total),
    dateWise: dateRows.map((row) => ({
      ...row,
      assignmentCount: toNumber(row.assignmentCount),
      driverCount: toNumber(row.driverCount),
    })),
    statusWise: statusRows.map((row) => ({
      ...row,
      driverCount: toNumber(row.driverCount),
    })),
    categoryWise: categoryRows.map((row) => ({
      ...row,
      assignmentCount: toNumber(row.assignmentCount),
      driverCount: toNumber(row.driverCount),
    })),
  };
};

const getVehicleReport = async ({ filters = {}, pagination = {} }, connection = null) => {
  const executor = getExecutor(connection);
  const limit = Number(pagination.limit || 10);
  const offset = Number(pagination.offset || 0);
  const { whereSql, values } = buildVehicleWhere(filters);
  const assignmentFilters = buildAssignmentJoinParts(filters, 'a');
  const activePlaceholders = ACTIVE_ASSIGNMENT_STATUSES.map(() => '?').join(', ');

  const [countRows] = await executor.execute(
    `
      SELECT COUNT(DISTINCT v.id) AS total
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id
      LEFT JOIN users du ON du.id = d.user_id
      WHERE ${whereSql}
    `,
    values,
  );

  const [rows] = await executor.execute(
    `
      SELECT
        v.id,
        v.vehicle_number AS vehicleNumber,
        v.registration_number AS registrationNumber,
        v.vehicle_type AS vehicleType,
        v.model,
        v.capacity_kg AS capacityKg,
        v.fuel_type AS fuelType,
        v.insurance_expiry_date AS insuranceExpiryDate,
        v.service_due_date AS serviceDueDate,
        v.availability_status AS availabilityStatus,
        d.id AS assignedDriverId,
        d.driver_code AS assignedDriverCode,
        du.name AS assignedDriverName,
        COUNT(DISTINCT a.id) AS assignedTripsInRange,
        SUM(CASE WHEN a.assignment_status = 'completed' THEN 1 ELSE 0 END) AS completedTripsInRange,
        SUM(CASE WHEN a.assignment_status IN (${activePlaceholders}) THEN 1 ELSE 0 END) AS activeTripsInRange,
        v.created_at AS createdAt
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id
      LEFT JOIN users du ON du.id = d.user_id
      LEFT JOIN assignments a ON a.vehicle_id = v.id
        AND ${assignmentFilters.sql}
      LEFT JOIN shipments s ON s.id = a.shipment_id AND s.deleted_at IS NULL
      LEFT JOIN shipment_categories sc ON sc.id = s.category_id AND sc.deleted_at IS NULL
      WHERE ${whereSql}
      GROUP BY
        v.id, v.vehicle_number, v.registration_number, v.vehicle_type,
        v.model, v.capacity_kg, v.fuel_type, v.insurance_expiry_date,
        v.service_due_date, v.availability_status, d.id, d.driver_code,
        du.name, v.created_at
      ORDER BY assignedTripsInRange DESC, v.created_at DESC
      LIMIT ? OFFSET ?
    `,
    [
      ...ACTIVE_ASSIGNMENT_STATUSES,
      ...assignmentFilters.values,
      ...values,
      limit,
      offset,
    ],
  );

  const vehicleAssignmentWhere = [
    'a.deleted_at IS NULL',
    'v.deleted_at IS NULL',
    's.deleted_at IS NULL',
    'sc.deleted_at IS NULL',
  ];
  const vehicleAssignmentValues = [];
  addDateFilter(vehicleAssignmentWhere, vehicleAssignmentValues, 'a.assigned_at', filters);
  addShipmentCategoryFilter(
    vehicleAssignmentWhere,
    vehicleAssignmentValues,
    {
      categoryIdColumn: 's.category_id',
      categoryCodeColumn: 'sc.code',
    },
    filters,
  );

  if (filters.status || filters.availabilityStatus) {
    vehicleAssignmentWhere.push('v.availability_status = ?');
    vehicleAssignmentValues.push(filters.status || filters.availabilityStatus);
  }

  if (filters.vehicleType) {
    vehicleAssignmentWhere.push('v.vehicle_type = ?');
    vehicleAssignmentValues.push(filters.vehicleType);
  }

  const vehicleAssignmentWhereSql = vehicleAssignmentWhere.join(' AND ');

  const [dateRows] = await executor.execute(
    `
      SELECT
        DATE(a.assigned_at) AS reportDate,
        COUNT(DISTINCT a.id) AS assignmentCount,
        COUNT(DISTINCT a.vehicle_id) AS vehicleCount
      FROM assignments a
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${vehicleAssignmentWhereSql}
      GROUP BY DATE(a.assigned_at)
      ORDER BY reportDate ASC
    `,
    vehicleAssignmentValues,
  );

  const [statusRows] = await executor.execute(
    `
      SELECT
        v.availability_status AS status,
        COUNT(DISTINCT v.id) AS vehicleCount
      FROM vehicles v
      LEFT JOIN drivers d ON d.id = v.assigned_driver_id
      LEFT JOIN users du ON du.id = d.user_id
      WHERE ${whereSql}
      GROUP BY v.availability_status
      ORDER BY vehicleCount DESC
    `,
    values,
  );

  const [categoryRows] = await executor.execute(
    `
      SELECT
        sc.id AS categoryId,
        sc.code AS categoryCode,
        sc.name AS categoryName,
        COUNT(DISTINCT a.id) AS assignmentCount,
        COUNT(DISTINCT a.vehicle_id) AS vehicleCount
      FROM assignments a
      INNER JOIN vehicles v ON v.id = a.vehicle_id
      INNER JOIN shipments s ON s.id = a.shipment_id
      INNER JOIN shipment_categories sc ON sc.id = s.category_id
      WHERE ${vehicleAssignmentWhereSql}
      GROUP BY sc.id, sc.code, sc.name
      ORDER BY assignmentCount DESC
    `,
    vehicleAssignmentValues,
  );

  return {
    rows: rows.map(mapVehicleRow),
    total: toNumber(firstRow(countRows)?.total),
    dateWise: dateRows.map((row) => ({
      ...row,
      assignmentCount: toNumber(row.assignmentCount),
      vehicleCount: toNumber(row.vehicleCount),
    })),
    statusWise: statusRows.map((row) => ({
      ...row,
      vehicleCount: toNumber(row.vehicleCount),
    })),
    categoryWise: categoryRows.map((row) => ({
      ...row,
      assignmentCount: toNumber(row.assignmentCount),
      vehicleCount: toNumber(row.vehicleCount),
    })),
  };
};

module.exports = {
  getDriverReport,
  getInvoiceReport,
  getPaymentReport,
  getShipmentReport,
  getVehicleReport,
};
