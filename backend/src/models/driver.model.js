const { getPool } = require('../config/database');

const selectDriverColumns = `
  id,
  user_id AS userId,
  driver_code AS driverCode,
  license_number AS licenseNumber,
  license_expiry_date AS licenseExpiryDate,
  address_line1 AS addressLine1,
  address_line2 AS addressLine2,
  city,
  state,
  postal_code AS postalCode,
  availability_status AS availabilityStatus,
  driver_status AS driverStatus,
  rating,
  completed_trips AS completedTrips,
  emergency_contact_name AS emergencyContactName,
  emergency_contact_phone AS emergencyContactPhone,
  created_at AS createdAt,
  updated_at AS updatedAt,
  deleted_at AS deletedAt
`;

const getExecutor = (connection) => connection || getPool();

const firstRow = (rows) => rows[0] || null;

const findByUserId = async (userId, connection = null) => {
  const executor = getExecutor(connection);

  const [rows] = await executor.execute(
    `
      SELECT ${selectDriverColumns}
      FROM drivers
      WHERE user_id = ? AND deleted_at IS NULL
      LIMIT 1
    `,
    [userId],
  );

  return firstRow(rows);
};

module.exports = {
  findByUserId,
};
