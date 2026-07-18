# Driver Reports and Fuel Request API

These APIs support driver emergency reports, breakdown reports, fuel requests, fuel bill uploads, and admin review/status actions. Driver routes require the `driver` role. Admin routes require the `admin` role.

## Driver Endpoints

### POST `/api/v1/driver/reports/emergency`

Submit an emergency report. Use `multipart/form-data` when sending an optional attachment.

Fields:

- `reportType`: `accident`, `route_blocked`, `medical`, `security`, `other`
- `severity`: optional `low`, `medium`, `high`, `critical`; defaults to `medium`
- `description`: required
- `assignmentId`: optional driver-owned assignment
- `vehicleId`: optional driver-assigned vehicle
- `attachment`: optional file, JPG/PNG/WEBP/PDF
- `locationText`, `latitude`, `longitude`: optional location metadata

### POST `/api/v1/driver/reports/breakdown`

Submit a vehicle breakdown report. Stored in `emergency_reports` with `report_type = breakdown`.

Fields:

- `vehicleId`: required driver-assigned vehicle
- `issueType`: `engine`, `tyre`, `battery`, `fuel`, `electrical`, `cooling`, `accident_damage`, `other`
- `severity`, `description`, `assignmentId`, `attachment`, and location fields as above

Sample response:

```json
{
  "success": true,
  "message": "Breakdown report submitted successfully.",
  "data": {
    "report": {
      "id": 9,
      "reportCode": "RPT-20260430-1234560001",
      "reportType": "breakdown",
      "issueType": "engine",
      "severity": "high",
      "reportStatus": "open",
      "attachmentUrl": "/uploads/reports/breakdown-1714460000000-123456789.jpg"
    }
  }
}
```

### GET `/api/v1/driver/reports`

List reports submitted by the authenticated driver. Optional query: `status`, `reportType`, `page`, `limit`.

### POST `/api/v1/driver/fuel-requests`

Submit a fuel request.

Sample request:

```json
{
  "assignmentId": 7,
  "vehicleId": 3,
  "fuelAmountLiters": 35.5,
  "billAmount": 3820,
  "fuelStation": "HP Fuel Station, BKC",
  "notes": "Refuel before expressway route"
}
```

### GET `/api/v1/driver/fuel-requests`

List driver-owned fuel requests. Optional query: `status`, `page`, `limit`.

### POST `/api/v1/driver/fuel-requests/:fuelRequestId/bill`

Upload a fuel bill for a pending driver-owned fuel request.

Multipart fields:

- `bill`: required JPG/PNG/WEBP/PDF
- `notes`: optional

## Admin Endpoints

### GET `/api/v1/admin/reports`

List emergency and breakdown reports. Optional query: `search`, `reportType`, `severity`, `status`, `driverId`, `page`, `limit`.

### GET `/api/v1/admin/reports/:reportId`

Fetch one report.

### PATCH `/api/v1/admin/reports/:reportId/status`

Update report status.

Sample request:

```json
{
  "reportStatus": "resolved",
  "resolutionNotes": "Driver contacted, replacement vehicle dispatched."
}
```

Allowed statuses: `open`, `in_review`, `resolved`, `closed`. `resolutionNotes` is required for `resolved` and `closed`.

### GET `/api/v1/admin/fuel-requests`

List fuel requests. Optional query: `search`, `status`, `driverId`, `page`, `limit`.

### GET `/api/v1/admin/fuel-requests/:fuelRequestId`

Fetch one fuel request.

### PATCH `/api/v1/admin/fuel-requests/:fuelRequestId/approve`

Approve a pending fuel request. Fuel bill upload is required before approval.

### PATCH `/api/v1/admin/fuel-requests/:fuelRequestId/reject`

Reject a pending fuel request. `reviewNotes` is required.

### PATCH `/api/v1/admin/fuel-requests/:fuelRequestId/mark-paid`

Mark an approved fuel request as paid.

Sample fuel approval response:

```json
{
  "success": true,
  "message": "Fuel request approved successfully.",
  "data": {
    "fuelRequest": {
      "id": 12,
      "requestCode": "FUEL-20260430-1234560001",
      "requestStatus": "approved",
      "billFileUrl": "/uploads/fuel-bills/bill-1714460000000-123456789.pdf"
    }
  }
}
```

## Postman Steps

1. Login as a driver with `POST /api/v1/auth/driver/login` and save `data.auth.token` as `driverToken`.
2. Submit an emergency report with `POST /api/v1/driver/reports/emergency`.
3. Submit a breakdown report with `POST /api/v1/driver/reports/breakdown`.
4. Submit a fuel request with `POST /api/v1/driver/fuel-requests`.
5. Upload bill with `POST /api/v1/driver/fuel-requests/{{fuelRequestId}}/bill` using form-data field `bill`.
6. Login as admin with `POST /api/v1/auth/admin/login` and save `data.auth.token` as `adminToken`.
7. Review reports with `GET /api/v1/admin/reports` and update status with `PATCH /api/v1/admin/reports/{{reportId}}/status`.
8. Review fuel requests with `GET /api/v1/admin/fuel-requests`.
9. Approve with `PATCH /api/v1/admin/fuel-requests/{{fuelRequestId}}/approve`.
10. Mark paid with `PATCH /api/v1/admin/fuel-requests/{{fuelRequestId}}/mark-paid`.
11. Try approving a request without a bill to verify the `422` guard.
