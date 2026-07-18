# CargoConnect Backend Security Review

This review covers the current backend validation, authorization, ownership,
status-flow, upload, SQL, error, and API documentation posture.

## Validation

- Request validation is handled with `express-validator` and `validateRequest`.
- Validation errors are returned without echoing submitted values, so passwords,
  OTPs, reset tokens, and large free-text payloads are not reflected in API
  error responses.
- Report filters use report-specific allow lists:
  - shipment statuses for shipment reports
  - driver status and driver availability for driver reports
  - vehicle availability and vehicle type for vehicle reports
  - payment status and method for payment reports
  - invoice status and payment status for invoice reports

## SQL Injection Protection

- Database writes and reads use `mysql2/promise` `execute()` placeholders.
- Search strings are bound as values with `LIKE ?`.
- Dynamic SQL fragments are limited to internal allow-listed clauses such as
  known status placeholders, validated column names, and fixed SELECT column
  lists. User input is not concatenated into SQL values.

## Role And Ownership Checks

- Admin modules use `requireAuth` and `requireAdmin`.
- Customer modules use `requireAuth` and `requireRoles(customer)`.
- Driver modules use `requireAuth` and `requireRoles(driver)`.
- Customer shipment, invoice, proof, tracking, and notification reads resolve the
  authenticated customer profile before querying customer-owned records.
- Driver trip, proof, emergency, breakdown, and fuel-request APIs resolve the
  authenticated driver profile and only query driver-owned assignments or
  vehicles.

## Status Flow Checks

- Admin shipment approval, rejection, cancellation, and reassignment services
  enforce allowed source statuses before mutation.
- Assignment APIs prevent double-booking active drivers or vehicles.
- Driver trip APIs enforce the sequence:
  `assigned -> accepted -> started -> pickup_completed -> in_transit -> delivered -> completed`.
- Pickup proof is required before `in_transit`.
- Delivery proof is required before `delivered` and `completed`.
- Fuel and emergency admin review flows block invalid terminal transitions.

## File Upload Limits

- Uploads use Multer with `MAX_FILE_SIZE_MB`.
- Proof uploads allow one `proof` file only.
- Report uploads allow one `attachment` file only.
- Fuel bill uploads allow one `bill` file only.
- Accepted file types require matching MIME and extension:
  - proof: JPG, PNG, WEBP
  - report attachment: JPG, PNG, WEBP, PDF
  - fuel bill: JPG, PNG, WEBP, PDF
- Failed validation or service errors clean up uploaded files where a file was
  already written.

## Error Messages

- Production hides internal 500 stacks.
- Validation errors include only `field`, `location`, and `message`.
- CORS rejections return a 403 `CORS origin is not allowed` error.
- Upload limit errors return user-safe messages such as file size exceeded or
  unexpected form field.

## API Documentation

Feature docs live under `backend/src/docs`.
Relevant security-sensitive docs:

- `authorization-middleware.md`
- `auth-layer.md`
- `customer-registration-api.md`
- `password-auth-api.md`
- `role-aware-login-api.md`
- `driver-trip-api.md`
- `driver-admin-request-api.md`
- `admin-report-api.md`
- `notification-api.md`
